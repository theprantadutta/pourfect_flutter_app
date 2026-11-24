/// Deciding when to ask for a Play rating.
///
/// The rules are the whole feature. Calling the API is one line; asking at the
/// wrong moment is how an app earns the one-star reviews it was fishing for.
///
/// **Only after something went well.** `WinProfile.full` already marks the wins
/// worth celebrating — three stars, a personal best, or the last level of a
/// band — so that is the signal. A player who has just failed level 96 four
/// times is not the player to ask, and asking them is worse than not asking
/// anybody.
///
/// **Never mid-anything.** Not on launch, not over the board, not inside the
/// win sequence, which is choreographed to the millisecond and is the moment
/// the game earns its pitch. The ask happens on the frame after the player
/// leaves a level and lands back on the hub — a genuine pause, with nothing
/// they were in the middle of.
///
/// **Not to somebody who has barely played.** Play gives an app very few
/// chances to show the card, and spending one on a player five minutes in buys
/// a rating from somebody who does not know yet whether they like it.
///
/// **Google forbids asking a question first**, so there is no "Enjoying
/// Pourfect?" dialog routing happy players to the store and unhappy ones to a
/// feedback form. It is against the In-App Review guidelines and it is rating
/// manipulation. Pick the moment, call the API, accept the answer.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/analytics/analytics_service.dart';
import 'progress_repository.dart';
import 'providers.dart';

/// Levels that must be solved before the card is ever requested.
///
/// Was five. Lowered 2026-11-24: in the first month the card was asked for
/// twice in total and the listing had one rating, so search results showed
/// no stars at all beside games with thousands. Three good clears is still
/// somebody who has chosen to keep playing.
const int kMinSolvedBeforeReview = 3;

/// How long to leave it after asking, whether or not a card appeared.
///
/// Was 120 days. Play keeps its own, stricter quota on how often the card
/// really appears, so this only stops OUR side from asking on consecutive
/// sessions; a month is plenty for that.
const Duration kReviewCooldown = Duration(days: 30);

/// How many times to ask across the whole life of the install.
///
/// Somebody who has not rated after three good moments has decided, and the
/// fourth ask is pestering.
const int kMaxReviewAsks = 3;

@immutable
class ReviewState {
  const ReviewState({
    this.delighted = false,
    this.askCount = 0,
    this.lastAskedAt,
  });

  /// Something worth celebrating happened THIS SESSION.
  ///
  /// Session-scoped on purpose: it is a claim about the player's mood right
  /// now, and a mood does not survive the app being closed.
  final bool delighted;

  final int askCount;
  final DateTime? lastAskedAt;

  ReviewState copyWith({
    bool? delighted,
    int? askCount,
    DateTime? lastAskedAt,
  }) => ReviewState(
    delighted: delighted ?? this.delighted,
    askCount: askCount ?? this.askCount,
    lastAskedAt: lastAskedAt ?? this.lastAskedAt,
  );
}

class ReviewPrompter extends Notifier<ReviewState> {
  static const _countKey = 'pourfect.review.ask_count';
  static const _lastKey = 'pourfect.review.last_asked';

  /// AWAITED BEFORE ANY DECISION.
  ///
  /// The same shape as the free-hint counter that handed out a fresh set every
  /// launch: this provider is lazy, so `build()` and the first question can
  /// happen in the same breath, and a decision taken against a freshly-zeroed
  /// count is a decision to ask somebody who was asked yesterday.
  late final Future<void> _restored;

  @override
  ReviewState build() {
    _restored = _restore();
    return const ReviewState();
  }

  Future<void> _restore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString(_lastKey);

      state = state.copyWith(
        askCount: prefs.getInt(_countKey) ?? 0,
        lastAskedAt: stored == null ? null : DateTime.tryParse(stored),
      );
    } catch (error) {
      // Unreadable preferences mean the caps cannot be honoured, and the safe
      // failure is to ask NOBODY rather than to ask everybody. Left at a count
      // that will be treated as unknown by `maybeAsk`.
      debugPrint('[review] could not restore: $error');
    }
  }

  /// Records that something went well.
  ///
  /// Called from the win sequence, where the profile is already decided — not
  /// re-derived here, because two places computing "was that a good win" is
  /// two places to disagree.
  void noteDelight() {
    if (state.delighted) return;
    state = state.copyWith(delighted: true);
  }

  /// Asks, if every rule allows it.
  ///
  /// Safe to call on every return to the hub: almost every call is a handful
  /// of comparisons that decide not to. **Never throws** — it is called
  /// fire-and-forget, right after the best moment the player has had all
  /// session, and it must not be able to spoil it.
  ///
  /// Returns whether it asked, so a caller at a break can skip anything else
  /// it would have shown there (one interruption per break).
  Future<bool> maybeAsk({DateTime? now, String placement = 'hub'}) async {
    if (!state.delighted) return false;

    await _restored;

    final at = now ?? DateTime.now();
    if (!_isAllowed(at)) return false;

    final service = ref.read(reviewServiceProvider);
    if (!await service.isAvailable()) return false;

    // RECORDED BEFORE THE REQUEST, not after.
    //
    // Play deliberately never reports whether a card appeared, so there is no
    // success to wait for. Recording afterwards means anything that interrupts
    // the flow — the process being killed while a system overlay is up — loses
    // the record and asks again next time, which is the one failure mode worth
    // avoiding. Losing an ask costs nothing; nagging costs a rating.
    await _recordAsk(at);

    // GUARDED HERE TOO, not only inside PlayReviewService.
    //
    // Not belt-and-braces for its own sake: `maybeAsk` is called
    // fire-and-forget from the route callback, so anything that escapes it
    // becomes an unhandled async error rather than something a caller can
    // catch. The prompter promises never to throw, so the prompter has to be
    // the one that keeps the promise — a ReviewService is an interface, and
    // the next implementation of it has made no such promise.
    // The one line of diagnostics this feature gets. Play never reports whether
    // a card appeared, so on the internal testing track — the only place the
    // card can appear at all, since a sideloaded build is not "from Play" —
    // this is the only way to tell the ask was reached rather than declined by
    // one of the rules above.
    debugPrint('[review] asking (ask ${state.askCount} of $kMaxReviewAsks)');
    ref
        .read(analyticsServiceProvider)
        .log(
          ReviewPromptShown(
            levelsSolved: ref.read(progressProvider).length,
            placement: placement,
          ),
        );

    try {
      await service.request();
    } catch (error) {
      debugPrint('[review] request failed: $error');
    }
    return true;
  }

  bool _isAllowed(DateTime at) {
    if (state.askCount >= kMaxReviewAsks) return false;

    final last = state.lastAskedAt;
    if (last != null && at.difference(last) < kReviewCooldown) return false;

    // Read at the point of decision rather than watched, so this provider does
    // not rebuild every time a level is cleared.
    final solved = ref.read(progressProvider).length;
    return solved >= kMinSolvedBeforeReview;
  }

  Future<void> _recordAsk(DateTime at) async {
    // Cleared whatever happens next: one good moment earns at most one ask,
    // and without this a player who bounces in and out of the hub after a
    // three-star clear is asked on every return.
    state = state.copyWith(
      delighted: false,
      askCount: state.askCount + 1,
      lastAskedAt: at,
    );

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_countKey, state.askCount);
      await prefs.setString(_lastKey, at.toIso8601String());
    } catch (error) {
      debugPrint('[review] could not record the ask: $error');
    }
  }
}

final reviewPrompterProvider = NotifierProvider<ReviewPrompter, ReviewState>(
  ReviewPrompter.new,
);

/// First-run teaching: the guided first level, and tips that each appear once,
/// at the moment they first matter.
///
/// Teaching by doing, not by slides. Level 1 is the tutorial: a bouncing hand
/// points at the tube to tap and one short caption says why, so the first
/// thing a new player does is play. Everything else — the par meter, undo,
/// hints, the hub — is explained the first time it becomes relevant and never
/// again. Day one is won or lost in the first minute, and a wall of cards in
/// front of the game is the most reliable way to lose it.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../engine/board.dart';
import '../engine/move.dart';
import '../engine/solver.dart';

/// The one-time tips. Stored by name, so reordering never re-shows one.
enum Tip {
  /// Level 2: what the par meter means.
  par,

  /// The first time a player goes past par: undo is free.
  undo,

  /// Level 4 onward, after a while without a pour landing a finish: hints.
  hint,

  /// The hub after the first win: Journey and the daily.
  hub,

  /// The first level with five-ball tubes.
  tallTubes,
}

@immutable
class OnboardingState {
  /// False until the stored flags have been read. Nothing is decided before
  /// then — a tip judged against defaults would re-show on every launch.
  final bool loaded;
  final bool tutorialDone;
  final Set<Tip> seen;

  const OnboardingState({
    this.loaded = false,
    this.tutorialDone = false,
    this.seen = const {},
  });

  bool hasSeen(Tip tip) => seen.contains(tip);

  OnboardingState copyWith({
    bool? loaded,
    bool? tutorialDone,
    Set<Tip>? seen,
  }) => OnboardingState(
    loaded: loaded ?? this.loaded,
    tutorialDone: tutorialDone ?? this.tutorialDone,
    seen: seen ?? this.seen,
  );
}

class OnboardingController extends Notifier<OnboardingState> {
  static const _doneKey = 'pourfect.onboarding.tutorial_done.v1';
  static const _seenKey = 'pourfect.onboarding.tips_seen.v1';

  late final Future<void> _restored;

  @override
  OnboardingState build() {
    _restored = _restore();
    return const OnboardingState();
  }

  /// Completes once the stored flags are in [state].
  Future<void> get ready => _restored;

  Future<void> _restore() async {
    var done = false;
    var seen = <Tip>{};
    try {
      final prefs = await SharedPreferences.getInstance();
      done = prefs.getBool(_doneKey) ?? false;
      final names = prefs.getStringList(_seenKey) ?? const [];
      final byName = Tip.values.asNameMap();
      seen = {for (final n in names) ?byName[n]};
    } catch (_) {
      // Unreadable flags mean a tip may show twice. Not worth blocking on.
    }
    // Monotonic: anything marked while the read was in flight survives it.
    state = OnboardingState(
      loaded: true,
      tutorialDone: done || state.tutorialDone,
      seen: {...seen, ...state.seen},
    );
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_doneKey, state.tutorialDone);
      await prefs.setStringList(_seenKey, [
        for (final t in state.seen) t.name,
      ]);
    } catch (_) {}
  }

  /// The guided level was finished, or skipped. Either way it is over.
  Future<void> finishTutorial() async {
    await _restored;
    if (state.tutorialDone) return;
    state = state.copyWith(tutorialDone: true);
    await _persist();
  }

  /// Marks [tip] shown. Returns false if it had already been, so a caller can
  /// use this as "show it now?" without a race between two frames.
  Future<bool> claim(Tip tip) async {
    await _restored;
    if (state.seen.contains(tip)) return false;
    state = state.copyWith(seen: {...state.seen, tip});
    await _persist();
    return true;
  }

  /// "How to play" in Settings: the guided level and every tip, from scratch.
  Future<void> reset() async {
    await _restored;
    state = state.copyWith(tutorialDone: false, seen: const {});
    await _persist();
  }
}

final onboardingProvider =
    NotifierProvider<OnboardingController, OnboardingState>(
      OnboardingController.new,
    );

/// The move the guided level points at next: the first step of an optimal
/// solution from wherever the player actually is.
///
/// Recomputed from the live board after every pour, so a player who wanders
/// off the script is simply guided from where they are — never told they did
/// it wrong. Level 1 is small enough to solve on the spot; null when the board
/// is won or (impossibly, on a campaign level) cannot be solved.
Move? guidedMove(Board board) {
  if (board.isWon) return null;
  final outcome = const Solver().solve(board);
  return outcome is Solved && outcome.moves.isNotEmpty
      ? outcome.moves.first
      : null;
}

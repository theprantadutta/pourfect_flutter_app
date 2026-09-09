/// Hints: solved off the UI isolate, never blocking the board.
///
/// Three rules this file exists to hold:
///
/// 1. **The board stays interactive.** The solve runs on a background isolate
///    and nothing is disabled while it works. A modal spinner over the board
///    would be the worst possible treatment — the player asked for help, not to
///    be locked out of their own game for a second and a half.
/// 2. **The reward is granted only if the hint RESOLVES.** A hint is paid for
///    with a rewarded video, and "no hint available" after watching an ad is a
///    refund request and a one-star review. Check first, then grant.
/// 3. **A hint for a position the player has left is discarded.** If they keep
///    playing while the solver works — which they can, see rule 1 — the answer
///    is about a board that no longer exists.
library;

import 'dart:isolate';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../engine/board.dart';
import '../engine/move.dart';
import '../engine/solver.dart';
import '../services/analytics/analytics_service.dart';
import 'providers.dart';

/// What came of a hint request.
enum HintOutcome {
  /// A move is now shown. The ONLY outcome that may consume a reward.
  resolved,

  /// The solver could not decide within `kHintNodeCap`. Should be rare — the
  /// budget is measured at ~1.6x the worst observed real request — but if it
  /// stops being rare, raise the cap rather than papering over it.
  unavailable,

  /// The player cancelled, or asked again before the first answer arrived.
  cancelled,

  /// The player moved on while the solver worked, so the answer is about a
  /// board they have left.
  stale,

  /// Nothing to hint: no level open, or it is already finished.
  notApplicable,
}

/// Solves [board] on a background isolate.
///
/// Top-level so the closure captures only the board. Worst measured cost is
/// ~350ms on desktop, so budget 1-2s on a low-end phone — which is exactly why
/// this is not allowed to run on the UI isolate.
Future<Move?> solveHintOffThread(Board board) =>
    Isolate.run(() => const Solver.forHints().hint(board));

class HintService {
  final Ref _ref;

  /// Bumped on every request and on cancel. A result whose id no longer matches
  /// is dropped, which is what makes cancellation work without needing to kill
  /// an isolate mid-solve.
  int _requestId = 0;

  HintService(this._ref);

  bool get isPending => _ref.read(gameControllerProvider)?.hintPending ?? false;

  /// Asks for a hint.
  ///
  /// Returns [HintOutcome.resolved] only when a move is actually on screen.
  /// Callers gating on a rewarded ad must debit the reward on that value and
  /// nothing else.
  Future<HintOutcome> request({bool wasRewarded = false}) async {
    final controller = _ref.read(gameControllerProvider.notifier);
    final before = _ref.read(gameControllerProvider);

    if (before == null || before.isWon) return HintOutcome.notApplicable;

    final id = ++_requestId;
    final session = controller.sessionId;
    final boardAtRequest = before.board;
    final movesAtRequest = before.movesUsed;
    controller.setHintPending(true);

    Move? move;
    try {
      move = await solveHintOffThread(boardAtRequest);
    } catch (_) {
      // An isolate failure is not worth crashing a game over; it reads to the
      // player as "no hint this time".
      move = null;
    }

    // Superseded or cancelled while we were working.
    if (id != _requestId) return HintOutcome.cancelled;

    // THE SESSION IS CHECKED, NOT JUST THE BOARD.
    //
    // The controller outlives the screen, so a player who leaves mid-solve
    // leaves behind a live state holding the exact position they abandoned.
    // The board therefore still matches, the answer applies cleanly, and this
    // returned `resolved` for a hint that was shown to nobody — which the
    // caller then charged for. Reopening a level starts a fresh board, so that
    // hint was never seen by anyone.
    //
    // An answer belongs to the spell of play it was asked in. If that ended,
    // nothing was delivered, and nothing may be charged.
    if (!controller.isCurrentSession(session)) return HintOutcome.cancelled;

    final after = _ref.read(gameControllerProvider);
    if (after == null) return HintOutcome.cancelled;

    if (after.board != boardAtRequest) {
      controller.setHintPending(false);
      return HintOutcome.stale;
    }

    final resolved = move != null;
    _ref
        .read(analyticsServiceProvider)
        .log(
          HintUsed(
            levelId: after.level.id,
            movesBefore: movesAtRequest,
            resolved: resolved,
            wasRewarded: wasRewarded,
          ),
        );

    if (!resolved) {
      controller.setHintPending(false);
      return HintOutcome.unavailable;
    }

    controller.showHint(move);
    return HintOutcome.resolved;
  }

  /// Abandons an in-flight request. The isolate finishes on its own; its answer
  /// is simply ignored.
  void cancel() {
    _requestId++;
    _ref.read(gameControllerProvider.notifier).setHintPending(false);
  }
}

final hintServiceProvider = Provider<HintService>(HintService.new);

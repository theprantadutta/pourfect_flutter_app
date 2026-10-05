/// Hints: solved off the UI isolate, never blocking the board.
///
/// Four rules this file exists to hold:
///
/// 1. **The board stays interactive.** Solving runs on a background isolate
///    and nothing is disabled while it works. A modal spinner over the board
///    would be the worst possible treatment — the player asked for help, not to
///    be locked out of their own game for a second and a half.
/// 2. **The answer is known BEFORE anything is charged.** [PositionAnalyst]
///    solves every position the player reaches, in the background, while they
///    look at it. So by the time they reach for Hint the game already knows
///    whether there is a hint to give, and a position with no way forward is
///    answered in words, for free, rather than with a video that buys nothing.
///    It used to be the other way round: the video played, the solver ran, and
///    a dead end was discovered afterwards.
/// 3. **The reward is granted only if the hint RESOLVES.** "No hint available"
///    after watching an ad is a refund request and a one-star review.
/// 4. **A hint for a position the player has left is discarded.** If they keep
///    playing while the solver works — which they can, see rule 1 — the answer
///    is about a board that no longer exists.
library;

import 'dart:async';
import 'dart:collection';
import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../engine/board.dart';
import '../engine/move.dart';
import '../engine/rules.dart';
import '../engine/solver.dart';
import '../services/analytics/analytics_service.dart';
import 'game_state.dart';
import 'providers.dart';

/// What came of a hint request.
enum HintOutcome {
  /// A move is now shown. The ONLY outcome that may consume a reward.
  resolved,

  /// The solver could not decide within `kHintNodeCap`, or the position has
  /// no way forward. [HintService.check] answers both before anything is
  /// charged; this is the late safety net.
  unavailable,

  /// The player cancelled, or asked again before the first answer arrived.
  cancelled,

  /// The player moved on while the solver worked, so the answer is about a
  /// board they have left.
  stale,

  /// Nothing to hint: no level open, or it is already finished.
  notApplicable,
}

/// What the solver knows about one position.
sealed class PositionVerdict {
  const PositionVerdict();
}

/// The position can be finished; [next] is the first move of an optimal
/// finish, [movesLeft] its length.
final class SolvablePosition extends PositionVerdict {
  final Move next;
  final int movesLeft;

  const SolvablePosition(this.next, this.movesLeft);
}

/// PROVEN: no sequence of moves finishes the board from here.
final class DeadEndPosition extends PositionVerdict {
  const DeadEndPosition();
}

/// The solver ran out of budget before it could say. Never treated as either
/// solvable or dead: "I gave up" is not "impossible".
final class UndecidedPosition extends PositionVerdict {
  const UndecidedPosition();
}

/// Solves [board] on a background isolate.
///
/// Top-level so the closure captures only the board. Worst measured cost is
/// ~350ms on desktop, so budget 1-2s on a low-end phone — which is exactly why
/// this is not allowed to run on the UI isolate.
Future<SolveOutcome> solveOffThread(Board board) =>
    Isolate.run(() => const Solver.forHints().solve(board));

/// Solves the positions the player reaches, in the background, one at a time.
///
/// Watching the board rather than waiting to be asked is what lets the Hint
/// button know the answer before it charges for it, and makes the hint itself
/// instant. The cost is small: a typical position needs a few dozen nodes, and
/// one solve also settles every position along its optimal finish, so a player
/// following the solution never triggers another.
///
/// Verdicts are cached by board. A board's verdict is a fact about the board,
/// so the cache survives restarts and level changes; it is only trimmed.
class PositionAnalyst {
  final Future<SolveOutcome> Function(Board board) _solve;

  PositionAnalyst({Future<SolveOutcome> Function(Board board)? solve})
    : _solve = solve ?? solveOffThread;

  static const _maxKnown = 4000;

  final Map<Board, PositionVerdict> _known = {};

  /// Boards waiting for a solve, oldest first. The one the player is looking
  /// at goes last; one nobody is waiting on is dropped when a newer arrives.
  final LinkedHashSet<Board> _queue = LinkedHashSet<Board>();
  final Map<Board, List<Completer<PositionVerdict>>> _waiters = {};
  bool _running = false;

  /// The verdict for [board], if it is already known.
  PositionVerdict? known(Board board) => _known[board];

  /// The player is now looking at [board]: solve it if it is not known.
  void watch(Board board) {
    if (board.isWon || _known.containsKey(board)) return;
    // A board the player has already left, with nobody asking about it, is
    // not worth a solve.
    _queue.removeWhere((b) => !_waiters.containsKey(b));
    _queue.add(board);
    unawaited(_pump());
  }

  /// The verdict for [board], solving it if need be.
  Future<PositionVerdict> verdictFor(Board board) {
    final known = _known[board];
    if (known != null) return SynchronousFuture(known);
    final completer = Completer<PositionVerdict>();
    (_waiters[board] ??= []).add(completer);
    _queue.add(board);
    unawaited(_pump());
    return completer.future;
  }

  Future<void> _pump() async {
    if (_running) return;
    _running = true;
    try {
      while (_queue.isNotEmpty) {
        // Newest first: it is the one on screen.
        final board = _queue.last;
        _queue.remove(board);
        if (_known.containsKey(board)) {
          _settle(board, _known[board]!);
          continue;
        }

        PositionVerdict verdict;
        try {
          verdict = _record(board, await _solve(board));
        } catch (error) {
          // An isolate failure is not worth crashing a game over; it reads to
          // the player as "no hint this time".
          debugPrint('[hint] solve failed: $error');
          verdict = const UndecidedPosition();
        }
        _settle(board, verdict);
      }
    } finally {
      _running = false;
    }
  }

  void _settle(Board board, PositionVerdict verdict) {
    for (final waiter in _waiters.remove(board) ?? const []) {
      waiter.complete(verdict);
    }
  }

  /// Stores [outcome] for [board] and, for a solved board, every position
  /// along its optimal finish: each of those is one move closer, with the next
  /// move already known.
  PositionVerdict _record(Board board, SolveOutcome outcome) {
    if (_known.length > _maxKnown) _known.clear();
    switch (outcome) {
      case Solved(:final moves) when moves.isNotEmpty:
        var position = board;
        for (var i = 0; i < moves.length; i++) {
          _known[position] = SolvablePosition(moves[i], moves.length - i);
          final next = tryApplyMove(position, moves[i]);
          if (next == null) break;
          position = next.board;
        }
        return _known[board]!;
      case Solved():
        // Already won; nothing to hint, and never asked for.
        return const UndecidedPosition();
      case Unsolvable():
        return _known[board] = const DeadEndPosition();
      case SolveUnknown():
        return _known[board] = const UndecidedPosition();
    }
  }

  /// How many undos take [state] back to a position that can still be
  /// finished, or null if none can be found.
  ///
  /// Every board in the history was on screen once, so their verdicts are
  /// almost always known already; any that are not are solved here.
  Future<int?> stepsBackToSolvable(GameState state) async {
    final history = state.undoStack;
    for (var back = 1; back <= history.length; back++) {
      final verdict = await verdictFor(history[history.length - back]);
      if (verdict is SolvablePosition) return back;
    }
    return null;
  }
}

final positionAnalystProvider = Provider<PositionAnalyst>((ref) {
  final analyst = PositionAnalyst();
  // Every position the player reaches is solved while they look at it.
  ref.listen<Board?>(gameControllerProvider.select((state) => state?.board), (
    _,
    board,
  ) {
    if (board != null) analyst.watch(board);
  }, fireImmediately: true);
  return analyst;
});

/// What a hint would find on the board in play, settled before anything is
/// charged for it.
enum HintAvailability {
  /// There is a hint to give.
  available,

  /// No way to finish from here. [HintCheck.stepsBack] says how far to undo.
  deadEnd,

  /// The solver could not decide in its budget.
  unavailable,

  /// The player cancelled, or the board moved on while it was checked.
  cancelled,

  /// Nothing to hint: no level open, or it is already finished.
  notApplicable,
}

@immutable
class HintCheck {
  final HintAvailability availability;

  /// Undos back to a position that can still be finished, for a dead end.
  final int? stepsBack;

  const HintCheck(this.availability, {this.stepsBack});
}

class HintService {
  final Ref _ref;

  /// Bumped on every request and on cancel. A result whose id no longer matches
  /// is dropped, which is what makes cancellation work without needing to kill
  /// an isolate mid-solve.
  int _requestId = 0;

  HintService(this._ref);

  PositionAnalyst get _analyst => _ref.read(positionAnalystProvider);

  bool get isPending => _ref.read(gameControllerProvider)?.hintPending ?? false;

  /// Whether there is a hint to give, asked BEFORE anything is spent.
  ///
  /// Usually instant: the position was solved while the player looked at it.
  /// When it was not, the Hint button shows its progress ring until it is,
  /// and the board stays live.
  Future<HintCheck> check() async {
    final controller = _ref.read(gameControllerProvider.notifier);
    final before = _ref.read(gameControllerProvider);
    if (before == null || before.isWon) {
      return const HintCheck(HintAvailability.notApplicable);
    }

    final id = ++_requestId;
    final session = controller.sessionId;
    final board = before.board;

    final known = _analyst.known(board);
    if (known == null) controller.setHintPending(true);
    final verdict = known ?? await _analyst.verdictFor(board);

    if (id != _requestId || !controller.isCurrentSession(session)) {
      return const HintCheck(HintAvailability.cancelled);
    }
    final after = _ref.read(gameControllerProvider);
    if (known == null) controller.setHintPending(false);
    if (after == null || after.board != board) {
      return const HintCheck(HintAvailability.cancelled);
    }

    switch (verdict) {
      case SolvablePosition():
        return const HintCheck(HintAvailability.available);
      case DeadEndPosition():
        _logUnresolved(after);
        return HintCheck(
          HintAvailability.deadEnd,
          stepsBack: await _analyst.stepsBackToSolvable(after),
        );
      case UndecidedPosition():
        _logUnresolved(after);
        return const HintCheck(HintAvailability.unavailable);
    }
  }

  void _logUnresolved(GameState state) => _ref
      .read(analyticsServiceProvider)
      .log(
        HintUsed(
          levelId: state.level.id,
          movesBefore: state.movesUsed,
          resolved: false,
          wasRewarded: false,
        ),
      );

  /// Shows the hint.
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

    final known = _analyst.known(boardAtRequest);
    if (known == null) controller.setHintPending(true);
    final verdict = known ?? await _analyst.verdictFor(boardAtRequest);
    final move = verdict is SolvablePosition ? verdict.next : null;

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

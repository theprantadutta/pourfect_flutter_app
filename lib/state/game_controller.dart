/// The game's decision layer. All rules reach the UI through here.
///
/// Widgets call [tapTube], [undo], [restart]; they never touch `rules.dart` or
/// the solver. That is the layering rule `tool/check_layering.dart` enforces,
/// and it is why every interaction below is testable without pumping a widget.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../engine/level.dart';
import '../engine/move.dart';
import '../engine/rules.dart';
import '../services/analytics/analytics_service.dart';
import '../services/haptics/haptics_service.dart';
import 'game_state.dart';
import 'providers.dart';

/// Outcome of a tap, so callers know what actually happened without diffing
/// state. The screen uses it to fire haptics and analytics.
enum TapOutcome {
  /// Nothing happened — an empty tube, or the level is already finished.
  ignored,

  /// A tube's top run was lifted.
  selected,

  /// The lifted run was put back down.
  deselected,

  /// Selection moved to a different tube.
  reselected,

  /// A pour happened.
  poured,

  /// The pour finished the destination tube.
  pouredAndCompleted,
}

class GameController extends Notifier<GameState?> {
  int _pourSequence = 0;

  /// Levels opened this session, so `is_retry` on `level_start` is honest.
  final Set<int> _seenLevels = {};

  /// True once the current level's terminal event (complete or abandon) has
  /// been logged. Guards against double-counting when a level ends and the app
  /// is then backgrounded.
  bool _terminalLogged = false;

  @override
  GameState? build() => null;

  AnalyticsService get _analytics => ref.read(analyticsServiceProvider);

  HapticsService get _haptics => ref.read(hapticsServiceProvider);

  /// Opens [level] for play.
  void startLevel(Level level, {required int levelSetVersion}) {
    final isRetry = !_seenLevels.add(level.id);
    _terminalLogged = false;
    state = GameState.fresh(
      level: level,
      levelSetVersion: levelSetVersion,
      now: DateTime.now(),
      isRetry: isRetry,
    );

    _analytics.log(
      LevelStart(
        levelId: level.id,
        levelSetVersion: levelSetVersion,
        colorCount: level.colorCount,
        minMoves: level.minMoves,
        isRetry: isRetry,
      ),
    );
  }

  /// The single board interaction.
  ///
  /// Tap an unselected tube to lift its top run; tap a legal destination to
  /// pour. TAPPING THE SELECTED TUBE PUTS IT BACK DOWN — without that, a player
  /// who changes their mind has to either waste a move or reach for undo, which
  /// is the most common miss in this genre.
  ///
  /// Tapping an ILLEGAL destination that holds balls moves the selection there
  /// rather than just cancelling. Someone tapping a full tube almost always
  /// means "pick that one up instead", and making them tap twice for it is
  /// friction with no upside.
  TapOutcome tapTube(int index) {
    final current = state;
    if (current == null || current.isWon) return TapOutcome.ignored;
    if (index < 0 || index >= current.board.tubeCount) {
      return TapOutcome.ignored;
    }

    final selected = current.selectedTube;

    if (selected == null) {
      if (current.board[index].isEmpty) return TapOutcome.ignored;
      state = current.copyWith(selectedTube: () => index, hintMove: () => null);
      _haptics.selection();
      return TapOutcome.selected;
    }

    if (selected == index) {
      state = current.copyWith(selectedTube: () => null);
      _haptics.selection();
      return TapOutcome.deselected;
    }

    if (!canMove(current.board, selected, index)) {
      if (current.board[index].isEmpty) {
        state = current.copyWith(selectedTube: () => null);
        return TapOutcome.deselected;
      }
      state = current.copyWith(selectedTube: () => index);
      _haptics.selection();
      return TapOutcome.reselected;
    }

    return _pour(current, Move(selected, index));
  }

  TapOutcome _pour(GameState current, Move move) {
    final sourceBefore = current.board[move.from];
    final destBefore = current.board[move.to];
    final result = applyMove(current.board, move);

    _pourSequence++;
    state = current.copyWith(
      board: result.board,
      undoStack: [...current.undoStack, current.board],
      movesUsed: current.movesUsed + 1,
      selectedTube: () => null,
      hintMove: () => null,
      pour: () => PourEvent(
        sequence: _pourSequence,
        move: move,
        ballsMoved: result.ballsMoved,
        color: result.color,
        sourceTopSlot: sourceBefore.length - 1,
        destBaseSlot: destBefore.length,
        completedDestination: result.completedDestination,
      ),
    );

    // No haptic here on purpose: the board view fires one per BALL as it
    // touches down, so the feedback lands with the ball rather than at the
    // moment the move was decided.
    if (state!.isWon) {
      // Stop the clock on the winning move itself, not when the win card
      // finishes animating in — otherwise the score depends on how long the
      // flourish takes to play.
      pauseClock();
      _logComplete();
    }

    return result.completedDestination
        ? TapOutcome.pouredAndCompleted
        : TapOutcome.poured;
  }

  /// Takes back the last move. Free, unlimited, and never gated behind an ad.
  bool undo() {
    final current = state;
    if (current == null || !current.canUndo) return false;

    final wasStuck = current.isStuck;
    final stack = [...current.undoStack];
    final previous = stack.removeLast();

    state = current.copyWith(
      board: previous,
      undoStack: stack,
      movesUsed: current.movesUsed - 1,
      undosUsed: current.undosUsed + 1,
      selectedTube: () => null,
      hintMove: () => null,
      pour: () => null,
    );
    _haptics.selection();

    _analytics.log(
      UndoUsed(
        levelId: current.level.id,
        movesBefore: current.movesUsed,
        fromDeadEnd: wasStuck,
      ),
    );
    return true;
  }

  /// Restarts the current level from its shipped position.
  void restart() {
    final current = state;
    if (current == null) return;

    if (!current.isWon && current.movesUsed > 0) {
      _logAbandon(current, AbandonReason.restarted);
    }

    _terminalLogged = false;
    state = GameState.fresh(
      level: current.level,
      levelSetVersion: current.levelSetVersion,
      now: DateTime.now(),
      isRetry: true,
    );

    _analytics.log(
      LevelStart(
        levelId: current.level.id,
        levelSetVersion: current.levelSetVersion,
        colorCount: current.level.colorCount,
        minMoves: current.level.minMoves,
        isRetry: true,
      ),
    );
  }

  // ---- the clock -----------------------------------------------------------

  /// Stops the clock and banks the time run so far.
  ///
  /// Idempotent, so the lifecycle observer and an ad callback can both call it
  /// without the second one losing a stretch.
  void pauseClock() {
    final current = state;
    if (current == null || !current.isClockRunning) return;
    state = current.copyWith(
      elapsedBefore: current.elapsedAt(DateTime.now()),
      runningSince: () => null,
    );
  }

  /// Restarts the clock. Never restarts it on a finished level — the time on
  /// a solved board is settled, and resuming it would let a player's score
  /// drift while the win card sits on screen.
  void resumeClock() {
    final current = state;
    if (current == null || current.isClockRunning || current.isWon) return;
    state = current.copyWith(runningSince: () => DateTime.now());
  }

  /// Hands back the seconds played since the last call, and marks them as
  /// handed over.
  ///
  /// The caller writes them to the play history. Marking here rather than
  /// there is what makes double counting impossible: two exit paths firing on
  /// the same departure (backgrounding while leaving, say) means the second
  /// one gets zero.
  int takeUnbankedSeconds() {
    final current = state;
    if (current == null) return 0;

    final now = DateTime.now();
    final seconds = current.unbankedSecondsAt(now);
    if (seconds <= 0) return 0;

    state = current.copyWith(bankedSeconds: current.bankedSeconds + seconds);
    return seconds;
  }

  // ---- hint plumbing -------------------------------------------------------

  /// Marks the solver as running. The board stays interactive throughout.
  void setHintPending(bool pending) {
    final current = state;
    if (current == null) return;
    state = current.copyWith(hintPending: pending);
  }

  /// Shows a resolved hint.
  ///
  /// Only called once the solver has actually produced a move. The reward for a
  /// hint is granted by the caller AFTER this succeeds — see the hint
  /// controller for why that ordering is not negotiable.
  void showHint(Move move) {
    final current = state;
    if (current == null) return;
    state = current.copyWith(
      hintMove: () => move,
      hintPending: false,
      hintsUsed: current.hintsUsed + 1,
      selectedTube: () => move.from,
    );
    _haptics.selection();
  }

  void clearHint() {
    final current = state;
    if (current == null) return;
    state = current.copyWith(hintMove: () => null, hintPending: false);
  }

  // ---- funnel --------------------------------------------------------------

  /// Records that the player left this level unfinished.
  ///
  /// [AbandonReason.backgrounded] is the important caller: most people who give
  /// up never press back, they close the app or take a call. A funnel that only
  /// counts clean exits undercounts abandonment on precisely the hard levels it
  /// exists to find.
  void reportAbandon(AbandonReason reason) {
    final current = state;
    if (current == null || current.isWon || _terminalLogged) return;

    if (current.movesUsed == 0 && reason == AbandonReason.backgrounded) {
      // Opened and immediately backgrounded with no move made. That is a
      // session event, not a level abandonment, and counting it would smear
      // noise across every level's funnel.
      return;
    }
    _logAbandon(current, reason);
  }

  /// The player came back to a level they had backgrounded.
  ///
  /// Backgrounding logs an abandonment and latches the terminal flag, which is
  /// right up to the moment they return and finish the board: the flag then
  /// suppressed `level_complete` for the rest of that run, so a level that WAS
  /// completed produced no completion event at all. The per-level funnel
  /// exists to find levels that lose players, and silently dropping the
  /// successes makes every backgrounded level look worse than it is.
  ///
  /// Clearing the latch means such a run reports both an abandon and a
  /// complete. That is the truthful record of what happened — they did leave,
  /// and they did come back — and it is far better than losing half of it.
  void reportResumed() {
    final current = state;
    if (current == null || current.isWon) return;
    _terminalLogged = false;
  }

  void _logAbandon(GameState state, AbandonReason reason) {
    _terminalLogged = true;
    _analytics.log(
      LevelAbandon(
        levelId: state.level.id,
        levelSetVersion: state.levelSetVersion,
        moves: state.movesUsed,
        minMoves: state.level.minMoves,
        durationSeconds: state.elapsedSecondsAt(DateTime.now()),
        reason: reason,
        progress: state.progress,
      ),
    );
  }

  void _logComplete() {
    final current = state;
    if (current == null || _terminalLogged) return;
    _terminalLogged = true;

    _analytics.log(
      LevelComplete(
        levelId: current.level.id,
        levelSetVersion: current.levelSetVersion,
        moves: current.movesUsed,
        minMoves: current.level.minMoves,
        stars: current.stars,
        durationSeconds: current.elapsedSecondsAt(DateTime.now()),
        hintsUsed: current.hintsUsed,
        undosUsed: current.undosUsed,
      ),
    );
  }
}

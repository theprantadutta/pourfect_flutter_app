// The position analyst: what lets the Hint button know the answer before it
// charges for it.
//
// The flow it replaced played the rewarded video first and solved afterwards,
// so a player on a board with no way forward watched a video to be told "no
// hint" (and, with the toast broken, not even that). These pin the three
// things the new flow depends on: a dead end is PROVEN and told apart from a
// solvable board, the way back is counted in undos, and one solve settles the
// whole optimal line so following a hint never waits.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pourfect_flutter_app/engine/board.dart';
import 'package:pourfect_flutter_app/engine/level.dart';
import 'package:pourfect_flutter_app/engine/move.dart';
import 'package:pourfect_flutter_app/engine/rules.dart';
import 'package:pourfect_flutter_app/engine/solver.dart';
import 'package:pourfect_flutter_app/state/game_state.dart';
import 'package:pourfect_flutter_app/state/hint_controller.dart';
import 'package:pourfect_flutter_app/state/providers.dart';

/// Solvable, three colors, one spare tube.
final start = Board.fromLists([
  [2, 0, 0],
  [2, 1, 2],
  [1, 0, 1],
  [],
], capacity: 3);

/// [start] after pouring tube 1 into the spare: moves remain, but no line
/// of them finishes the board. Found by search, confirmed by the solver.
final deadEnd = tryApplyMove(start, const Move(1, 3))!.board;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// The real solver, run inline, counting how often it is asked.
  int solves = 0;
  PositionAnalyst analyst() {
    solves = 0;
    return PositionAnalyst(
      solve: (board) async {
        solves++;
        return const Solver.forHints().solve(board);
      },
    );
  }

  test('the fixture really is a dead end with moves left', () {
    expect(const Solver().solve(start), isA<Solved>());
    expect(const Solver().solve(deadEnd), isA<Unsolvable>());
    expect(legalMoves(deadEnd), isNotEmpty);
  });

  test('a solvable position knows its next move and how far is left', () async {
    final verdict = await analyst().verdictFor(start);
    final solved = const Solver().solve(start) as Solved;

    expect(verdict, isA<SolvablePosition>());
    verdict as SolvablePosition;
    expect(verdict.next, solved.moves.first);
    expect(verdict.movesLeft, solved.moveCount);
  });

  test('a dead end is PROVEN, not merely unanswered', () async {
    expect(await analyst().verdictFor(deadEnd), isA<DeadEndPosition>());
  });

  test('one solve settles every position along the optimal finish', () async {
    final a = analyst();
    final first = await a.verdictFor(start) as SolvablePosition;
    expect(solves, 1);

    // Follow the solution: every step is already known, so a hint there is
    // instant and costs no isolate.
    var board = start;
    var move = first.next;
    for (var left = first.movesLeft; left > 0; left--) {
      final known = a.known(board);
      expect(known, isA<SolvablePosition>());
      known as SolvablePosition;
      expect(known.movesLeft, left);
      move = known.next;
      board = applyMove(board, move).board;
    }
    expect(board.isWon, isTrue);
    expect(solves, 1, reason: 'the line was re-solved step by step');
  });

  test('a dead end counts the undos back to a winnable position', () async {
    final level = Level(
      id: 9,
      board: start,
      minMoves: (const Solver().solve(start) as Solved).moveCount,
      difficultyScore: 20,
      forcedMoveRatio: 0.1,
    );
    final state = GameState.fresh(
      level: level,
      levelSetVersion: 1,
      now: DateTime(2026),
    ).copyWith(board: deadEnd, undoStack: [start], movesUsed: 1);

    expect(await analyst().stepsBackToSolvable(state), 1);
  });

  test('the provider solves each position the game reaches', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final a = container.read(positionAnalystProvider);

    container
        .read(gameControllerProvider.notifier)
        .startLevel(
          Level(
            id: 9,
            board: start,
            minMoves: 1,
            difficultyScore: 20,
            forcedMoveRatio: 0.1,
          ),
          levelSetVersion: 1,
        );

    // Solved on an isolate in the background; wait for it.
    for (var i = 0; i < 200 && a.known(start) == null; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    expect(a.known(start), isA<SolvablePosition>());
  });
}

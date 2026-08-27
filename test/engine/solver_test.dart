import 'dart:collection';
import 'dart:math';

import 'package:pourfect_flutter_app/engine/board.dart';
import 'package:pourfect_flutter_app/engine/canonical.dart';
import 'package:pourfect_flutter_app/engine/rules.dart';
import 'package:pourfect_flutter_app/engine/solver.dart';
import 'package:test/test.dart';

void main() {
  const solver = Solver();

  group('goal handling', () {
    test('an already-won board solves in zero moves', () {
      final board = Board.fromLists([
        [0, 0, 0, 0],
        [1, 1, 1, 1],
        [],
      ], capacity: 4);
      final outcome = solver.solve(board);

      expect(outcome, isA<Solved>());
      expect((outcome as Solved).moves, isEmpty);
    });

    test('a one-move board solves in one move', () {
      final board = Board.fromLists([
        [0, 0, 0],
        [1, 1, 1, 1],
        [0],
      ], capacity: 4);
      final outcome = solver.solve(board);

      expect(outcome, isA<Solved>());
      expect((outcome as Solved).moveCount, 1);
    });
  });

  group('unsolvable boards', () {
    test('proves a dead board impossible rather than guessing', () {
      final board = Board.fromLists([
        [0, 1, 0, 1],
        [1, 0, 1, 0],
      ], capacity: 4);
      expect(solver.solve(board), isA<Unsolvable>());
    });

    test('proves a board impossible when no empty tube can be freed', () {
      final board = Board.fromLists([
        [0, 1, 1, 0],
        [1, 0, 0, 1],
      ], capacity: 4);
      final outcome = solver.solve(board);

      expect(outcome, isA<Unsolvable>());
      expect(
        _bruteForceOptimal(board),
        isNull,
        reason: 'the independent oracle agrees',
      );
    });
  });

  group('solutions are valid', () {
    test('replaying the path actually wins, on many random boards', () {
      final random = Random(21);
      var solvedCount = 0;

      for (var i = 0; i < 250; i++) {
        final board = _randomBoard(random, colours: 5, capacity: 4, empties: 2);
        final outcome = solver.solve(board);
        if (outcome is! Solved) continue;
        solvedCount++;

        var current = board;
        for (final move in outcome.moves) {
          final result = tryApplyMove(current, move);
          expect(
            result,
            isNotNull,
            reason: 'solver emitted an illegal move $move on $current',
          );
          current = result!.board;
        }
        expect(current.isWon, isTrue, reason: 'path did not reach a win');
      }

      expect(solvedCount, greaterThan(100));
    });
  });

  group('solutions are OPTIMAL', () {
    test('minMoves matches an independent breadth-first search', () {
      // BFS over canonical states with the UNPRUNED move set is a slow but
      // unarguable oracle. If IDA*'s heuristic were inadmissible, or if the
      // move pruning cut a shorter path, this is where it shows up — and
      // minMoves feeds both the star rating and the server anti-cheat floor,
      // so "close enough" is not good enough.
      final random = Random(5);
      var compared = 0;

      for (var i = 0; i < 120; i++) {
        final board = _randomBoard(random, colours: 4, capacity: 3, empties: 2);
        final expected = _bruteForceOptimal(board);
        final outcome = solver.solve(board);

        if (expected == null) {
          expect(
            outcome,
            isA<Unsolvable>(),
            reason: 'BFS found no solution but the solver claimed one',
          );
          continue;
        }

        expect(outcome, isA<Solved>());
        expect(
          (outcome as Solved).moveCount,
          expected,
          reason: 'suboptimal path found for $board',
        );
        compared++;
      }

      expect(compared, greaterThan(40));
    });

    test('stays optimal on wider boards', () {
      final random = Random(99);
      var compared = 0;

      for (var i = 0; i < 40; i++) {
        final board = _randomBoard(random, colours: 5, capacity: 4, empties: 2);
        final expected = _bruteForceOptimal(board);
        final outcome = solver.solve(board);

        if (expected == null) {
          expect(outcome, isA<Unsolvable>());
          continue;
        }
        expect((outcome as Solved).moveCount, expected);
        compared++;
      }

      expect(compared, greaterThan(20));
    });
  });

  group('node cap', () {
    test('gives up with SolveUnknown rather than hanging', () {
      final board = Board.fromLists([
        [0, 1, 2, 3],
        [4, 5, 6, 7],
        [7, 6, 5, 4],
        [3, 2, 1, 0],
        [0, 2, 4, 6],
        [1, 3, 5, 7],
        [6, 4, 2, 0],
        [7, 5, 3, 1],
        [],
        [],
      ], capacity: 4);
      const stingy = Solver(nodeCap: 50);
      final outcome = stingy.solve(board);

      expect(outcome, isA<SolveUnknown>());
      expect((outcome as SolveUnknown).nodesExplored, lessThanOrEqualTo(50));
    });

    test('SolveUnknown is never reported as Unsolvable', () {
      // The distinction is the whole safety property: the generator discards
      // "undecided" boards, and conflating the two is precisely how an
      // unsolvable level would ship.
      final random = Random(64);
      for (var i = 0; i < 60; i++) {
        final board = _randomBoard(random, colours: 8, capacity: 4, empties: 2);
        const stingy = Solver(nodeCap: 30);
        final outcome = stingy.solve(board);
        if (outcome is Unsolvable) {
          fail('a 30-node budget cannot prove $board impossible');
        }
      }
    });

    test('a generous cap decides what a stingy one could not', () {
      final random = Random(77);
      var upgraded = 0;

      for (var i = 0; i < 40; i++) {
        final board = _randomBoard(random, colours: 6, capacity: 4, empties: 2);
        if (const Solver(nodeCap: 20).solve(board) is! SolveUnknown) continue;
        if (const Solver().solve(board) is! SolveUnknown) upgraded++;
      }

      expect(upgraded, greaterThan(0));
    });
  });

  group('hint', () {
    test('returns a move that wins a one-move board', () {
      // Both 0→2 and 2→0 finish this board, and neither is more correct than
      // the other. Pinning one would only pin the tie-break order, so assert
      // what a player would actually notice: the hint ends the level.
      final board = Board.fromLists([
        [0, 0, 0],
        [1, 1, 1, 1],
        [0],
      ], capacity: 4);
      final hint = solver.hint(board);

      expect(hint, isNotNull);
      expect(applyMove(board, hint!).board.isWon, isTrue);
    });

    test('a hint always shortens the remaining solution by exactly one', () {
      final random = Random(31);
      var checked = 0;

      for (var i = 0; i < 60; i++) {
        final board = _randomBoard(random, colours: 5, capacity: 4, empties: 2);
        final outcome = solver.solve(board);
        if (outcome is! Solved || outcome.moves.isEmpty) continue;

        final hint = solver.hint(board)!;
        final after = applyMove(board, hint).board;
        final rest = solver.solve(after);

        expect(rest, isA<Solved>());
        expect((rest as Solved).moveCount, outcome.moveCount - 1);
        checked++;
      }

      expect(checked, greaterThan(20));
    });

    test('returns null on a won board', () {
      final board = Board.fromLists([
        [0, 0],
        [1, 1],
      ], capacity: 2);
      expect(solver.hint(board), isNull);
    });

    test('returns null on an unsolvable board', () {
      final board = Board.fromLists([
        [0, 1, 0, 1],
        [1, 0, 1, 0],
      ], capacity: 4);
      expect(solver.hint(board), isNull);
    });
  });

  group('add-tube power-up', () {
    test('an extra empty tube can rescue an unsolvable board', () {
      final board = Board.fromLists([
        [0, 1, 0, 1],
        [1, 0, 1, 0],
      ], capacity: 4);
      expect(solver.solve(board), isA<Unsolvable>());
      expect(
        solver.solve(board.withExtraEmptyTube()),
        isA<Solved>(),
        reason:
            'solvability changes when a tube is added — re-solve, never '
            'reuse a cached answer',
      );
    });
  });

  group('input validation', () {
    test('rejects a board whose colour counts break the invariant', () {
      final board = Board.fromLists([
        [0, 0, 0],
        [1],
      ], capacity: 4);
      expect(() => solver.solve(board), throwsArgumentError);
    });
  });

  group('search move generation', () {
    test('agrees with usefulMoves in rules.dart', () {
      // Two implementations of the same three reductions over different
      // representations; a drift between them would silently change what the
      // solver explores while every rules test still passed.
      final random = Random(8);
      for (var i = 0; i < 400; i++) {
        final board = _randomBoard(random, colours: 5, capacity: 4, empties: 2);
        expect(
          debugGenerateMoves(board),
          usefulMoves(board),
          reason: 'move generation drifted on $board',
        );
      }
    });
  });
}

/// Breadth-first optimal move count over canonical states, using the UNPRUNED
/// move set. Returns null when the board cannot be won.
///
/// Deliberately naive — it is the oracle, so it must not share any reasoning
/// with the thing it is checking.
int? _bruteForceOptimal(Board start) {
  if (start.isWon) return 0;

  final seen = <String>{canonicalKey(start)};
  final queue = Queue<(Board, int)>()..add((start, 0));

  while (queue.isNotEmpty) {
    final (board, depth) = queue.removeFirst();
    for (final move in legalMoves(board)) {
      final next = applyMove(board, move).board;
      if (next.isWon) return depth + 1;
      if (seen.add(canonicalKey(next))) queue.add((next, depth + 1));
    }
  }
  return null;
}

Board _randomBoard(
  Random random, {
  required int colours,
  required int capacity,
  required int empties,
}) {
  final balls = <ColorId>[
    for (var c = 0; c < colours; c++) ...List<ColorId>.filled(capacity, c),
  ]..shuffle(random);

  return Board([
    for (var i = 0; i < colours; i++)
      Tube(balls.sublist(i * capacity, (i + 1) * capacity), capacity),
    for (var i = 0; i < empties; i++) Tube.empty(capacity),
  ]);
}

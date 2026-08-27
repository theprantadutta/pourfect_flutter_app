import 'dart:math';

import 'package:pourfect_flutter_app/engine/board.dart';
import 'package:pourfect_flutter_app/engine/canonical.dart';
import 'package:pourfect_flutter_app/engine/move.dart';
import 'package:pourfect_flutter_app/engine/rules.dart';
import 'package:test/test.dart';

void main() {
  group('canMove', () {
    test('rejects a move onto itself', () {
      final board = Board.fromLists([
        [0, 1],
        [1, 0],
        [],
      ], capacity: 2);
      expect(canMove(board, 0, 0), isFalse);
    });

    test('rejects an empty source', () {
      final board = Board.fromLists([
        [],
        [0, 0],
      ], capacity: 2);
      expect(canMove(board, 0, 1), isFalse);
    });

    test('rejects a full destination', () {
      final board = Board.fromLists([
        [0],
        [0, 0],
      ], capacity: 2);
      expect(canMove(board, 0, 1), isFalse);
    });

    test('rejects a colour mismatch', () {
      final board = Board.fromLists([
        [0],
        [1],
      ], capacity: 2);
      expect(canMove(board, 0, 1), isFalse);
    });

    test('allows any colour into an empty tube', () {
      final board = Board.fromLists([
        [3],
        [],
      ], capacity: 2);
      expect(canMove(board, 0, 1), isTrue);
    });

    test('allows a matching top colour', () {
      final board = Board.fromLists([
        [1, 2],
        [0, 2],
      ], capacity: 3);
      expect(canMove(board, 0, 1), isTrue);
    });

    test('rejects out-of-range indices instead of throwing', () {
      final board = Board.fromLists([
        [0],
        [],
      ], capacity: 2);
      expect(canMove(board, 0, 5), isFalse);
      expect(canMove(board, -1, 0), isFalse);
    });
  });

  group('applyMove moves the whole contiguous run', () {
    test('carries every same-coloured ball from the top', () {
      final board = Board.fromLists([
        [1, 2, 2, 2],
        [],
      ], capacity: 4);
      final result = applyMove(board, const Move(0, 1));

      expect(result.ballsMoved, 3, reason: 'the run of three 2s moves at once');
      expect(result.colour, 2);
      expect(result.board[0].balls, [1]);
      expect(result.board[1].balls, [2, 2, 2]);
    });

    test('stops at the run boundary, not the tube bottom', () {
      final board = Board.fromLists([
        [2, 1, 1],
        [],
      ], capacity: 3);
      final result = applyMove(board, const Move(0, 1));

      expect(result.ballsMoved, 2);
      expect(result.board[0].balls, [2], reason: 'the buried 2 stays put');
    });

    test('clamps the run to the destination free space', () {
      final board = Board.fromLists([
        [2, 2, 2, 2],
        [2, 2, 2],
      ], capacity: 4);
      final result = applyMove(board, const Move(0, 1));

      expect(result.ballsMoved, 1, reason: 'only one slot was free');
      expect(result.board[0].balls, [2, 2, 2]);
      expect(result.board[1].balls, [2, 2, 2, 2]);
    });

    test('reports a completed destination', () {
      final board = Board.fromLists([
        [1, 3],
        [3, 3, 3],
      ], capacity: 4);
      final result = applyMove(board, const Move(0, 1));

      expect(result.completedDestination, isTrue);
      expect(result.board[1].isComplete, isTrue);
    });

    test('does not report completion when the tube merely fills', () {
      final board = Board.fromLists([
        [0, 3],
        [1, 3, 3],
      ], capacity: 4);
      final result = applyMove(board, const Move(0, 1));

      expect(result.board[1].isFull, isTrue);
      expect(
        result.completedDestination,
        isFalse,
        reason: 'full but not single-coloured is not a finished tube',
      );
    });

    test('leaves the original board untouched', () {
      final board = Board.fromLists([
        [1, 2, 2],
        [],
      ], capacity: 3);
      final before = board.toLists();
      applyMove(board, const Move(0, 1));

      expect(board.toLists(), before);
    });

    test('throws on an illegal move', () {
      final board = Board.fromLists([
        [0],
        [1],
      ], capacity: 2);
      expect(() => applyMove(board, const Move(0, 1)), throwsArgumentError);
    });

    test('tryApplyMove returns null rather than throwing', () {
      final board = Board.fromLists([
        [0],
        [1],
      ], capacity: 2);
      expect(tryApplyMove(board, const Move(0, 1)), isNull);
    });

    test('ballsThatWouldMove agrees with what applyMove does', () {
      final random = Random(7);
      for (var i = 0; i < 300; i++) {
        final board = _randomBoard(random, colours: 4, capacity: 4, empties: 2);
        for (final move in legalMoves(board)) {
          final predicted = ballsThatWouldMove(board, move.from, move.to);
          expect(applyMove(board, move).ballsMoved, predicted);
        }
      }
    });
  });

  group('win detection', () {
    test('accepts complete tubes plus empties', () {
      final board = Board.fromLists([
        [0, 0, 0, 0],
        [],
        [1, 1, 1, 1],
      ], capacity: 4);
      expect(board.isWon, isTrue);
    });

    test('rejects a uniform but unfilled tube', () {
      final board = Board.fromLists([
        [0, 0, 0],
        [1, 1, 1, 1],
        [0],
      ], capacity: 4);
      expect(
        board.isWon,
        isFalse,
        reason: 'a colour split across two tubes is not sorted',
      );
    });

    test('rejects a full but mixed tube', () {
      final board = Board.fromLists([
        [0, 0, 0, 1],
        [1, 1, 1, 0],
      ], capacity: 4);
      expect(board.isWon, isFalse);
    });

    test('an all-empty board is trivially won', () {
      final board = Board.fromLists([[], []], capacity: 4);
      expect(board.isWon, isTrue);
    });
  });

  group('dead states', () {
    test('detects a board with no legal move left', () {
      final board = Board.fromLists([
        [0, 1, 0, 1],
        [1, 0, 1, 0],
      ], capacity: 4);

      expect(legalMoves(board), isEmpty);
      expect(board.isWon, isFalse);
      expect(isDead(board), isTrue);
    });

    test('a won board is never dead', () {
      final board = Board.fromLists([
        [0, 0],
        [1, 1],
        [],
      ], capacity: 2);
      expect(board.isWon, isTrue);
      expect(isDead(board), isFalse);
    });

    test('a playable board is not dead', () {
      final board = Board.fromLists([
        [0, 1],
        [1, 0],
        [],
      ], capacity: 2);
      expect(isDead(board), isFalse);
    });
  });

  group('legalDestinationsFrom', () {
    test('lists exactly the pourable tubes', () {
      final board = Board.fromLists([
        [0, 2],
        [2, 1],
        [],
        [2, 2, 2, 2],
      ], capacity: 4);
      // From tube 0 (top = 2): tube 1 tops with 1 (no), tube 2 is empty (yes),
      // tube 3 is full (no).
      expect(legalDestinationsFrom(board, 0), [2]);
    });

    test('is empty for an empty source', () {
      final board = Board.fromLists([
        [],
        [0, 0],
      ], capacity: 2);
      expect(legalDestinationsFrom(board, 0), isEmpty);
    });
  });

  group('usefulMoves', () {
    test('is always a subset of legalMoves', () {
      final random = Random(11);
      for (var i = 0; i < 400; i++) {
        final board = _randomBoard(random, colours: 5, capacity: 4, empties: 2);
        final legal = legalMoves(board).toSet();
        for (final move in usefulMoves(board)) {
          expect(
            legal.contains(move),
            isTrue,
            reason: '$move was offered but is not legal on $board',
          );
        }
      }
    });

    test('never breaks up a finished tube', () {
      final board = Board.fromLists([
        [0, 0, 0, 0],
        [1, 2],
        [],
      ], capacity: 4);
      expect(
        usefulMoves(board).where((m) => m.from == 0),
        isEmpty,
        reason: 'tube 0 holds every 0 there is; taking it apart cannot help',
      );
      expect(
        legalMoves(board).where((m) => m.from == 0),
        isNotEmpty,
        reason: 'the move is legal — it is just never useful',
      );
    });

    test('never pours a uniform tube into an empty one', () {
      final board = Board.fromLists([
        [0, 0],
        [1, 2],
        [],
      ], capacity: 4);
      expect(
        usefulMoves(board).where((m) => m.from == 0 && m.to == 2),
        isEmpty,
        reason: 'that just swaps two tubes — the same canonical position',
      );
    });

    test('collapses interchangeable empty destinations to one', () {
      final board = Board.fromLists([
        [0, 1],
        [1, 0],
        [],
        [],
      ], capacity: 2);
      final intoEmpties = usefulMoves(board)
          .where((m) => board[m.to].isEmpty)
          .toList();

      expect(
        intoEmpties.map((m) => m.from).toSet().length,
        intoEmpties.length,
        reason: 'each source should offer at most one empty destination',
      );
    });

    test('orders tube-completing moves first', () {
      final board = Board.fromLists([
        [1, 0],
        [0, 0, 0],
        [],
      ], capacity: 4);
      final moves = usefulMoves(board);

      expect(moves.first, const Move(0, 1));
      expect(applyMove(board, moves.first).completedDestination, isTrue);
    });

    test('preserves solvability — never prunes the only way through', () {
      // A board whose solution requires using the empty tube as scratch space.
      final board = Board.fromLists([
        [0, 1, 1, 0],
        [1, 0, 0, 1],
        [],
      ], capacity: 4);
      expect(usefulMoves(board), isNotEmpty);
      expect(_reachableWin(board, useful: true), isTrue);
      expect(
        _reachableWin(board, useful: true),
        _reachableWin(board, useful: false),
        reason: 'pruning must not change whether the board is winnable',
      );
    });
  });

  group('branchingFactor', () {
    test('counts distinct outcomes, not raw moves', () {
      final board = Board.fromLists([
        [0, 1],
        [1, 0],
        [],
        [],
      ], capacity: 2);
      // Pouring into either empty tube gives the same canonical position.
      expect(
        branchingFactor(board),
        lessThan(legalMoves(board).length),
        reason: 'two empty tubes are one choice',
      );
    });

    test('is 0 on a dead board', () {
      final board = Board.fromLists([
        [0, 1, 0, 1],
        [1, 0, 1, 0],
      ], capacity: 4);
      expect(branchingFactor(board), 0);
    });
  });
}

/// Deals a random legal board — the same shape the generator produces, without
/// the solvability filter, so tests see messy positions too.
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

/// Exhaustive reachability over canonical states, using either the pruned or
/// the raw move set. Only for tiny boards — it is the independent oracle the
/// pruning is checked against.
bool _reachableWin(Board start, {required bool useful}) {
  final seen = <String>{canonicalKey(start)};
  final queue = <Board>[start];

  while (queue.isNotEmpty) {
    final board = queue.removeLast();
    if (board.isWon) return true;
    for (final move in useful ? usefulMoves(board) : legalMoves(board)) {
      final next = applyMove(board, move).board;
      if (seen.add(canonicalKey(next))) queue.add(next);
    }
  }
  return false;
}

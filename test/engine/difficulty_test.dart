import 'dart:math';

import 'package:pourfect_flutter_app/engine/board.dart';
import 'package:pourfect_flutter_app/engine/difficulty.dart';
import 'package:pourfect_flutter_app/engine/generator.dart';
import 'package:pourfect_flutter_app/engine/level.dart';
import 'package:pourfect_flutter_app/engine/solver.dart';
import 'package:test/test.dart';

void main() {
  const solver = Solver();

  DifficultyMetrics measure(Board board) {
    final outcome = solver.solve(board);
    return measureDifficulty(board, (outcome as Solved).moves);
  }

  group('forcedMoveRatio', () {
    test('is 1.0 when every step along the path is forced', () {
      // One ball out of place and a single empty tube: the player has exactly
      // one meaningful move at each step.
      final board = Board.fromLists([
        [0, 0, 0],
        [1, 1, 1, 1],
        [0],
      ], capacity: 4);
      expect(measure(board).forcedMoveRatio, 1.0);
    });

    test('drops below 1.0 when the player has real choices', () {
      final board = Board.fromLists([
        [0, 1, 2, 0],
        [1, 2, 0, 1],
        [2, 0, 1, 2],
        [],
        [],
      ], capacity: 4);
      expect(measure(board).forcedMoveRatio, lessThan(1.0));
    });

    test('counts distinct outcomes, so spare empty tubes are one choice', () {
      // Same position, one extra empty tube. Raw legal-move counting would call
      // the second board more branchy; measuring canonical outcomes must not.
      final tight = Board.fromLists([
        [0, 0, 0],
        [1, 1, 1, 1],
        [0],
      ], capacity: 4);
      expect(measure(tight).forcedMoveRatio, 1.0);
      expect(measure(tight.withExtraEmptyTube()).forcedMoveRatio, 1.0);
    });

    test('is always a proper ratio', () {
      final generator = LevelGenerator(random: Random(17));
      for (var i = 0; i < 30; i++) {
        final level = generator.generate(const LevelSpec(colorCount: 5));
        expect(level.metrics.forcedMoveRatio, inInclusiveRange(0.0, 1.0));
      }
    });
  });

  group('scatter', () {
    test('is 1.0 per colour when each colour sits in one tube', () {
      final board = Board.fromLists([
        [0, 0, 0],
        [1, 1, 1, 1],
        [0],
      ], capacity: 4);
      // Colour 0 is split across two tubes, colour 1 is in one.
      final metrics = measure(board);
      expect(metrics.maxScatter, 2);
      expect(metrics.meanScatter, closeTo(1.5, 1e-9));
    });

    test('never exceeds capacity', () {
      final generator = LevelGenerator(random: Random(18));
      for (var i = 0; i < 30; i++) {
        final level = generator.generate(const LevelSpec(colorCount: 6));
        expect(level.metrics.maxScatter, lessThanOrEqualTo(4));
      }
    });
  });

  group('difficultyScore', () {
    test('stays inside 0-100 across every shipping band', () {
      final generator = LevelGenerator(random: Random(19));
      for (final spec in const [
        LevelSpec(colorCount: 3, emptyTubeCount: 2),
        LevelSpec(colorCount: 6, emptyTubeCount: 2),
        LevelSpec(colorCount: 10, emptyTubeCount: 2),
        LevelSpec(colorCount: 8, emptyTubeCount: 1),
      ]) {
        for (var i = 0; i < 5; i++) {
          expect(
            generator.generate(spec, maxAttempts: 20000).score,
            inInclusiveRange(0.0, 100.0),
          );
        }
      }
    });

    test('fewer empty tubes scores harder, all else equal', () {
      final base = DifficultyMetrics(
        minMoves: 24,
        colorCount: 8,
        capacity: 4,
        emptyTubeCount: 2,
        forcedMoveRatio: 0.4,
        meanScatter: 2.5,
        maxScatter: 3,
      );
      final tighter = DifficultyMetrics(
        minMoves: base.minMoves,
        colorCount: base.colorCount,
        capacity: base.capacity,
        emptyTubeCount: 1,
        forcedMoveRatio: base.forcedMoveRatio,
        meanScatter: base.meanScatter,
        maxScatter: base.maxScatter,
      );
      expect(difficultyScore(tighter), greaterThan(difficultyScore(base)));
    });

    test('more branching scores harder than a board that plays itself', () {
      DifficultyMetrics withForced(double forced) => DifficultyMetrics(
        minMoves: 24,
        colorCount: 8,
        capacity: 4,
        emptyTubeCount: 2,
        forcedMoveRatio: forced,
        meanScatter: 2.5,
        maxScatter: 3,
      );

      expect(
        difficultyScore(withForced(0.1)),
        greaterThan(difficultyScore(withForced(0.9))),
      );
    });

    test('branching outweighs colour count — the whole design claim', () {
      // A 10-colour board that plays itself must score BELOW a 6-colour board
      // full of real decisions. If this ever inverts, the curve is being driven
      // by board size instead of by difficulty and the bands will feel wrong.
      final bigButForced = DifficultyMetrics(
        minMoves: 30,
        colorCount: 10,
        capacity: 4,
        emptyTubeCount: 2,
        forcedMoveRatio: 0.95,
        meanScatter: 2.0,
        maxScatter: 3,
      );
      final smallButBranchy = DifficultyMetrics(
        minMoves: 18,
        colorCount: 6,
        capacity: 4,
        emptyTubeCount: 2,
        forcedMoveRatio: 0.05,
        meanScatter: 2.8,
        maxScatter: 4,
      );

      expect(
        difficultyScore(smallButBranchy),
        greaterThan(difficultyScore(bigButForced)),
      );
    });
  });

  group('star rating', () {
    test('awards 3 stars for an optimal solve', () {
      expect(starsFor(minMoves: 20, movesUsed: 20), 3);
      expect(starsFor(minMoves: 20, movesUsed: 19), 3);
    });

    test('awards 2 stars up to 1.5x optimal', () {
      expect(starsFor(minMoves: 20, movesUsed: 21), 2);
      expect(starsFor(minMoves: 20, movesUsed: 30), 2);
    });

    test('awards 1 star beyond that — finishing always counts', () {
      expect(starsFor(minMoves: 20, movesUsed: 31), 1);
      expect(starsFor(minMoves: 20, movesUsed: 500), 1);
    });

    test('rounds the 2-star threshold up, never against the player', () {
      // 1.5 x 7 = 10.5. A player finishing in 10 should not be punished by
      // floor().
      expect(starsFor(minMoves: 7, movesUsed: 10), 2);
      expect(starsFor(minMoves: 7, movesUsed: 11), 2);
      expect(starsFor(minMoves: 7, movesUsed: 12), 1);
    });

    test('an unfinished level earns nothing', () {
      expect(starsFor(minMoves: 20, movesUsed: 0), 0);
    });

    test('Level.stars agrees with the free function', () {
      final level = LevelGenerator(random: Random(23))
          .generate(const LevelSpec(colorCount: 5))
          .toLevel(1);

      expect(level.stars(level.minMoves), 3);
      expect(level.stars(level.minMoves * 3), 1);
    });
  });

  group('kMaxColours', () {
    test('is the accessibility cap, not a search limit', () {
      // Ten colours plus ten distinguishable glyphs is the ceiling at which a
      // ball stays readable at ~28px. Raising this is a design decision that
      // needs the CVD harness re-run, not a constant edit.
      expect(kMaxColours, 10);
    });
  });
}

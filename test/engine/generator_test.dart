import 'dart:math';

import 'package:pourfect_flutter_app/engine/generator.dart';
import 'package:pourfect_flutter_app/engine/level.dart';
import 'package:pourfect_flutter_app/engine/rules.dart';
import 'package:pourfect_flutter_app/engine/solver.dart';
import 'package:test/test.dart';

/// The generator's contract, checked on every board it hands back.
///
/// This is the product promise — "no unsolvable levels, ever" — expressed as
/// code. It re-derives everything from the board rather than trusting the
/// generator's own bookkeeping: a generator that recorded the wrong `minMoves`
/// would otherwise sail through.
void _assertShippable(GeneratedLevel level) {
  final board = level.board;

  expect(board.isWon, isFalse, reason: 'a pre-solved board is not a level');
  for (final tube in board.tubes) {
    expect(tube.isComplete, isFalse, reason: 'a tube was born finished');
  }
  expect(isDead(board), isFalse, reason: 'the board starts stuck');

  // Independently re-solve, rather than trusting the recorded solution.
  final outcome = const Solver().solve(board);
  expect(outcome, isA<Solved>(), reason: 'shipped an unsolvable board');
  expect(
    (outcome as Solved).moveCount,
    level.minMoves,
    reason: 'recorded minMoves disagrees with a fresh solve',
  );

  // Replay the stored path and confirm it really finishes the board.
  var current = board;
  for (final move in level.solution) {
    final result = tryApplyMove(current, move);
    expect(
      result,
      isNotNull,
      reason: 'stored solution contains $move, illegal',
    );
    current = result!.board;
  }
  expect(current.isWon, isTrue, reason: 'stored solution does not win');

  expect(level.metrics.forcedMoveRatio, inInclusiveRange(0.0, 1.0));
  expect(level.score, inInclusiveRange(0.0, 100.0));
}

/// Generates [count] levels for [spec] and asserts every one is shippable.
void _sweep(String label, LevelSpec spec, int count, int seed) {
  final generator = LevelGenerator(random: Random(seed));
  final stats = GenerationStats();
  final keys = <String>{};

  for (var i = 0; i < count; i++) {
    final level = generator.generate(spec, maxAttempts: 20000, stats: stats);
    _assertShippable(level);
    keys.add(canonicalKeyOf(level.board));
  }

  expect(stats.accepted, count);
  expect(
    stats.count(RejectionReason.undecided),
    0,
    reason: 'the node cap was hit — raise it or the bake will be lossy',
  );
  // Not a strict requirement of the sweep, but a collapse here would mean the
  // deal is far less random than intended.
  expect(keys.length, greaterThan((count * 0.9).floor()), reason: label);
}

void main() {
  group('every generated board is solvable', () {
    // 1,000 boards across the shipping bands. Split per band so a failure
    // localises and no single test outruns the default timeout.
    test(
      'tutorial band — 4 colours, 2 empty (250 boards)',
      () => _sweep(
        'tutorial',
        const LevelSpec(colorCount: 4, emptyTubeCount: 2),
        250,
        1001,
      ),
      timeout: const Timeout(Duration(minutes: 5)),
    );

    test(
      'early band — 6 colours, 2 empty (250 boards)',
      () => _sweep(
        'early',
        const LevelSpec(colorCount: 6, emptyTubeCount: 2),
        250,
        1002,
      ),
      timeout: const Timeout(Duration(minutes: 5)),
    );

    test(
      'mid band — 8 colours, 2 empty (250 boards)',
      () => _sweep(
        'mid',
        const LevelSpec(colorCount: 8, emptyTubeCount: 2),
        250,
        1003,
      ),
      timeout: const Timeout(Duration(minutes: 10)),
    );

    test(
      'late band — 10 colours, 2 empty (150 boards)',
      () => _sweep(
        'late',
        const LevelSpec(colorCount: 10, emptyTubeCount: 2),
        150,
        1004,
      ),
      timeout: const Timeout(Duration(minutes: 15)),
    );

    test(
      'hardest band — 10 colours, 1 empty (100 boards)',
      () => _sweep(
        'hardest',
        const LevelSpec(colorCount: 10, emptyTubeCount: 1),
        100,
        1005,
      ),
      timeout: const Timeout(Duration(minutes: 20)),
    );
  });

  group('rejection behaviour', () {
    test('discards undecided boards instead of shipping them', () {
      // With a two-node budget almost nothing can be decided, so the generator
      // must starve rather than accept anything. Accepting here would mean an
      // unverified board could reach a player.
      final generator = LevelGenerator(
        random: Random(4),
        solver: const Solver(nodeCap: 2),
      );
      final stats = GenerationStats();

      expect(
        () => generator.generate(
          const LevelSpec(colorCount: 8, emptyTubeCount: 2),
          maxAttempts: 40,
          stats: stats,
        ),
        throwsStateError,
      );
      expect(stats.accepted, 0);
      expect(stats.count(RejectionReason.undecided), greaterThan(0));
    });

    test('rejects unsolvable deals — and most 1-empty deals are', () {
      // ~99% of random single-empty-tube deals are impossible. This is the
      // clearest argument for verify-don't-trust generation: a reverse-shuffle
      // generator would have emitted every one of these as "fine" and the
      // player would have found out.
      //
      // Measured over 10 levels, not 1 — `generate` stops at its first
      // acceptance, so a single call's rejection count is just seed luck.
      final generator = LevelGenerator(random: Random(9));
      final stats = GenerationStats();

      for (var i = 0; i < 10; i++) {
        generator.generate(
          const LevelSpec(colorCount: 8, emptyTubeCount: 1),
          maxAttempts: 20000,
          stats: stats,
        );
      }

      final unsolvable = stats.count(RejectionReason.unsolvable);
      expect(unsolvable, greaterThan(100));
      expect(
        unsolvable / stats.attempts,
        greaterThan(0.9),
        reason: 'single-empty-tube deals should be overwhelmingly impossible',
      );
    });

    test('honours a difficulty window', () {
      final generator = LevelGenerator(random: Random(12));
      for (var i = 0; i < 12; i++) {
        final level = generator.generate(
          const LevelSpec(colorCount: 6, emptyTubeCount: 2),
          minScore: 45,
          maxScore: 70,
          maxAttempts: 20000,
        );
        expect(level.score, inInclusiveRange(45, 70));
      }
    });

    test('fails loudly when a window cannot be met', () {
      final generator = LevelGenerator(random: Random(13));
      expect(
        () => generator.generate(
          const LevelSpec(colorCount: 4, emptyTubeCount: 2),
          minScore: 99.9,
          maxAttempts: 200,
        ),
        throwsStateError,
        reason: 'a short campaign must break the build, not ship quietly',
      );
    });
  });

  group('reproducibility', () {
    test('the same seed produces the same levels', () {
      List<String> run() =>
          LevelGenerator(random: Random(2024))
              .generateBatch(const LevelSpec(colorCount: 5), 10)
              .map((l) => canonicalKeyOf(l.board))
              .toList();

      expect(run(), run());
    });

    test('different seeds produce different levels', () {
      String first(int seed) => canonicalKeyOf(
        LevelGenerator(random: Random(seed))
            .generate(const LevelSpec(colorCount: 6))
            .board,
      );

      expect(first(1), isNot(first(2)));
    });
  });

  group('batch de-duplication', () {
    test('never repeats a board within a batch', () {
      final levels = LevelGenerator(random: Random(55))
          .generateBatch(const LevelSpec(colorCount: 5), 40);

      final keys = levels.map((l) => canonicalKeyOf(l.board)).toSet();
      expect(keys, hasLength(40));
    });

    test('respects a shared seen-set across batches', () {
      final generator = LevelGenerator(random: Random(56));
      final seen = <String>{};

      final a = generator.generateBatch(
        const LevelSpec(colorCount: 5),
        20,
        seenKeys: seen,
      );
      final b = generator.generateBatch(
        const LevelSpec(colorCount: 5),
        20,
        seenKeys: seen,
      );

      final keys = [...a, ...b].map((l) => canonicalKeyOf(l.board)).toSet();
      expect(keys, hasLength(40));
    });
  });

  group('Level serialization round-trips', () {
    test('survives toJson/fromJson unchanged', () {
      final generated = LevelGenerator(random: Random(71))
          .generate(const LevelSpec(colorCount: 6));
      final level = generated.toLevel(42);

      final restored = Level.fromJson(level.toJson());

      expect(restored.id, 42);
      expect(restored.board, level.board);
      expect(restored.minMoves, level.minMoves);
      expect(restored.colorCount, level.colorCount);
      expect(restored.emptyTubeCount, level.emptyTubeCount);
      expect(restored.difficultyScore, closeTo(level.difficultyScore, 1e-9));
      expect(restored.forcedMoveRatio, closeTo(level.forcedMoveRatio, 1e-9));
    });

    test('carries minMoves — the backend anti-cheat floor depends on it', () {
      final level = LevelGenerator(random: Random(72))
          .generate(const LevelSpec(colorCount: 7))
          .toLevel(1);

      final json = level.toJson();
      expect(json['min_moves'], level.minMoves);
      expect(json['min_moves'], greaterThan(0));
      expect(json['tubes'], isA<List<List<int>>>());
    });
  });
}

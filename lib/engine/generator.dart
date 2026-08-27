/// Level generation: random fill, then solver verification.
///
/// ENGINE LOGIC — `ui/` must not import this file. It never runs on a player's
/// device either: levels are baked at build time by `tool/generate_levels.dart`
/// and shipped as an asset. Nobody waits on a generator.
///
/// WHY NOT REVERSE-SHUFFLE. The usual trick is to start from a solved board and
/// apply random legal moves backwards. It is much faster and it is wrong for
/// us, twice over: the boards drift back toward trivial as the walk length
/// grows (a random walk on this graph has no pressure to move AWAY from the
/// goal), and the walk length tells you nothing about the true optimum, so
/// there is no honest `minMoves` and therefore no honest star rating. Random
/// fill plus verification costs more CPU once, at build time, and buys a real
/// difficulty measurement for every shipped level.
library;

import 'dart:math';

import 'board.dart';
import 'canonical.dart';
import 'difficulty.dart';
import 'level.dart';
import 'move.dart';
import 'solver.dart';

/// The shape of a level to generate.
final class LevelSpec {
  /// Distinct colours; also the number of filled tubes, since each colour
  /// contributes exactly [capacity] balls.
  final int colorCount;

  /// Balls per tube.
  final int capacity;

  /// Extra empty tubes. Two is standard; one is dramatically harder.
  final int emptyTubeCount;

  const LevelSpec({
    required this.colorCount,
    this.capacity = 4,
    this.emptyTubeCount = 2,
  });

  /// Total tubes on the board.
  int get tubeCount => colorCount + emptyTubeCount;

  @override
  String toString() =>
      'LevelSpec(colours: $colorCount, capacity: $capacity, '
      'empty: $emptyTubeCount)';
}

/// A generated, solver-verified board with its optimal solution and metrics.
final class GeneratedLevel {
  final Board board;

  /// The OPTIMAL solution found by the solver.
  final List<Move> solution;

  final DifficultyMetrics metrics;

  /// Blended 0-100 score from [difficultyScore].
  final double score;

  /// Nodes the solver expanded. Kept for the CLI's report — a spec whose boards
  /// routinely cost near the node cap is a spec that will produce [SolveUnknown]
  /// discards and slow the bake down.
  final int nodesExplored;

  const GeneratedLevel({
    required this.board,
    required this.solution,
    required this.metrics,
    required this.score,
    required this.nodesExplored,
  });

  /// Proven minimum move count.
  int get minMoves => solution.length;

  /// Stamps this board with a campaign position.
  Level toLevel(int id) => Level(
    id: id,
    board: board,
    minMoves: minMoves,
    difficultyScore: score,
    forcedMoveRatio: metrics.forcedMoveRatio,
  );
}

/// Why a candidate board was thrown away. Counted by the CLI so a spec that
/// generates badly is visible rather than just slow.
enum RejectionReason {
  /// A tube came out already full and single-coloured.
  bornComplete,

  /// The deal happened to be already sorted.
  bornSolved,

  /// The solver proved it impossible.
  unsolvable,

  /// The solver hit its node cap — NOT treated as solvable.
  undecided,

  /// Solvable, but outside the requested difficulty window.
  outsideDifficultyWindow,
}

/// Tally of discards from a generation run.
final class GenerationStats {
  final Map<RejectionReason, int> rejections = {};
  int attempts = 0;
  int accepted = 0;

  void reject(RejectionReason reason) {
    rejections[reason] = (rejections[reason] ?? 0) + 1;
  }

  int count(RejectionReason reason) => rejections[reason] ?? 0;

  @override
  String toString() {
    final parts = RejectionReason.values
        .where((r) => count(r) > 0)
        .map((r) => '${r.name}: ${count(r)}')
        .join(', ');
    return 'attempts: $attempts, accepted: $accepted'
        '${parts.isEmpty ? "" : ", $parts"}';
  }
}

class LevelGenerator {
  final Random random;
  final Solver solver;

  /// [random] is injected so a bake is REPRODUCIBLE: the same seed yields the
  /// same 150 levels, which is what makes the shipped asset reviewable in a
  /// diff and a reported bad level reproducible on demand.
  LevelGenerator({Random? random, Solver? solver})
    : random = random ?? Random(),
      solver = solver ?? const Solver();

  /// Deals one random board and verifies it. Returns `null` if rejected.
  ///
  /// [onReject] receives the reason, for the CLI's tally.
  GeneratedLevel? attempt(
    LevelSpec spec, {
    double? minScore,
    double? maxScore,
    void Function(RejectionReason)? onReject,
  }) {
    final board = _deal(spec);

    for (final tube in board.tubes) {
      if (tube.isComplete) {
        onReject?.call(RejectionReason.bornComplete);
        return null;
      }
    }
    if (board.isWon) {
      onReject?.call(RejectionReason.bornSolved);
      return null;
    }

    final outcome = solver.solve(board);
    switch (outcome) {
      case Unsolvable():
        onReject?.call(RejectionReason.unsolvable);
        return null;
      case SolveUnknown():
        // "I gave up" is not "possible". Shipping this board on the chance it
        // is fine is exactly how unsolvable levels reach players.
        onReject?.call(RejectionReason.undecided);
        return null;
      case Solved(:final moves, :final nodesExplored):
        final metrics = measureDifficulty(board, moves);
        final score = difficultyScore(metrics);
        if ((minScore != null && score < minScore) ||
            (maxScore != null && score > maxScore)) {
          onReject?.call(RejectionReason.outsideDifficultyWindow);
          return null;
        }
        return GeneratedLevel(
          board: board,
          solution: moves,
          metrics: metrics,
          score: score,
          nodesExplored: nodesExplored,
        );
    }
  }

  /// Generates one accepted level, retrying up to [maxAttempts] times.
  ///
  /// Throws [StateError] if the budget runs out — a spec that cannot produce a
  /// level should fail the build loudly rather than quietly ship a short
  /// campaign.
  GeneratedLevel generate(
    LevelSpec spec, {
    double? minScore,
    double? maxScore,
    int maxAttempts = 2000,
    GenerationStats? stats,
  }) {
    for (var i = 0; i < maxAttempts; i++) {
      stats?.attempts++;
      final level = attempt(
        spec,
        minScore: minScore,
        maxScore: maxScore,
        onReject: stats?.reject,
      );
      if (level != null) {
        stats?.accepted++;
        return level;
      }
    }
    throw StateError(
      'No level matched $spec within $maxAttempts attempts'
      '${minScore != null || maxScore != null ? " and difficulty window "
                "[${minScore ?? "-"}, ${maxScore ?? "-"}]" : ""}'
      '${stats == null ? "" : " ($stats)"}',
    );
  }

  /// Generates [count] levels, rejecting boards duplicating one already kept.
  ///
  /// De-duplication is CANONICAL, so two deals that differ only by tube order
  /// count as the same level — they would play identically and a player would
  /// notice.
  List<GeneratedLevel> generateBatch(
    LevelSpec spec,
    int count, {
    double? minScore,
    double? maxScore,
    int maxAttemptsPerLevel = 2000,
    Set<String>? seenKeys,
    GenerationStats? stats,
  }) {
    final seen = seenKeys ?? <String>{};
    final levels = <GeneratedLevel>[];
    while (levels.length < count) {
      final level = generate(
        spec,
        minScore: minScore,
        maxScore: maxScore,
        maxAttempts: maxAttemptsPerLevel,
        stats: stats,
      );
      if (seen.add(canonicalKeyOf(level.board))) levels.add(level);
    }
    return levels;
  }

  /// Deals `colorCount * capacity` balls into filled tubes, then appends the
  /// empties.
  Board _deal(LevelSpec spec) {
    final balls = <ColorId>[
      for (var colour = 0; colour < spec.colorCount; colour++)
        ...List<ColorId>.filled(spec.capacity, colour),
    ]..shuffle(random);

    final tubes = <Tube>[
      for (var i = 0; i < spec.colorCount; i++)
        Tube(
          balls.sublist(i * spec.capacity, (i + 1) * spec.capacity),
          spec.capacity,
        ),
      for (var i = 0; i < spec.emptyTubeCount; i++) Tube.empty(spec.capacity),
    ];

    return Board(tubes);
  }
}

/// Canonical key for a board, re-exported so callers de-duplicating generated
/// levels do not have to reach into `canonical.dart` themselves.
String canonicalKeyOf(Board board) => canonicalKey(board);

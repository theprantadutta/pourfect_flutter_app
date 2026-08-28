/// Difficulty measurement.
///
/// ENGINE LOGIC — `ui/` must not import this file.
///
/// No single number describes how hard a ball-sort board FEELS, so this blends
/// five, and deliberately weights the one that correlates best with perceived
/// difficulty rather than the one that is easiest to compute.
///
/// The thing most clones get wrong: they treat `minMoves` as difficulty. It
/// isn't. A long board with one legal move at every step is tedious, not hard —
/// the player is just typing. A short board with six plausible-looking moves at
/// every step is genuinely hard.
///
/// MEASURED CAVEAT, worth knowing before trusting the weights. On randomly
/// dealt 2-empty-tube boards, [DifficultyMetrics.forcedMoveRatio] sits near 0.1
/// almost everywhere (p10 0.0, p50 0.1, p90 0.2 across 3-10 colors). It is a
/// rare-event indicator, so despite carrying the largest weight it does little
/// discriminating there; what actually separates two boards of the SAME shape
/// is move load and scatter. It comes alive on the 1-empty-tube band, where it
/// jumps to ~0.4 — which is exactly the band where being boxed in is the point.
/// [DifficultyMetrics.meanBranching] is reported alongside it as the continuous
/// view of the same idea, for the curve report.
library;

import 'board.dart';
import 'move.dart';
import 'rules.dart';

/// Raw measurements taken from a solved board and its optimal path.
final class DifficultyMetrics {
  /// Optimal solution length.
  final int minMoves;

  /// Distinct colors in play.
  final int colorCount;

  /// Balls per tube.
  final int capacity;

  /// Tubes that start empty. The strongest single lever: going from 2 to 1
  /// removes most of the player's room to manoeuvre and is a much bigger jump
  /// than adding a color.
  final int emptyTubeCount;

  /// Fraction of states along the optimal path offering at most ONE meaningful
  /// choice, measured as distinct canonical outcomes rather than raw legal
  /// moves — two empty tubes are one choice, not two.
  ///
  /// HIGH means the board plays itself. LOW means the player is choosing
  /// constantly. See the measured caveat at the top of this file.
  final double forcedMoveRatio;

  /// Mean number of distinct canonical outcomes available along the path.
  ///
  /// The continuous form of [forcedMoveRatio], and far better behaved: it has
  /// real variance on every band. Reported in the curve report so the shape of
  /// the campaign can be judged on evidence rather than on a rare-event
  /// indicator. Not currently an input to [difficultyScore] — it correlates
  /// strongly with tube count, so folding it in naively would quietly turn the
  /// score into a proxy for board SIZE, which is the exact failure this whole
  /// file exists to avoid.
  final double meanBranching;

  /// Mean number of distinct tubes each color is spread across at the start.
  final double meanScatter;

  /// Worst-case scatter for any single color at the start.
  final int maxScatter;

  const DifficultyMetrics({
    required this.minMoves,
    required this.colorCount,
    required this.capacity,
    required this.emptyTubeCount,
    required this.forcedMoveRatio,
    required this.meanBranching,
    required this.meanScatter,
    required this.maxScatter,
  });

  @override
  String toString() =>
      'DifficultyMetrics(minMoves: $minMoves, colors: $colorCount, '
      'empty: $emptyTubeCount, forced: ${forcedMoveRatio.toStringAsFixed(2)}, '
      'branching: ${meanBranching.toStringAsFixed(1)}, '
      'scatter: ${meanScatter.toStringAsFixed(2)}/$maxScatter)';
}

/// Measures [board] against its [solution], which must be the OPTIMAL path from
/// the solver — the branching statistics are meaningless along a wandering one.
DifficultyMetrics measureDifficulty(Board board, List<Move> solution) {
  final scatter = _scatterPerColor(board);
  final meanScatter = scatter.isEmpty
      ? 0.0
      : scatter.values.reduce((a, b) => a + b) / scatter.length;
  final maxScatter = scatter.isEmpty
      ? 0
      : scatter.values.reduce((a, b) => a > b ? a : b);

  final (forcedRatio, meanBranching) = _walkPath(board, solution);

  return DifficultyMetrics(
    minMoves: solution.length,
    colorCount: board.colors.length,
    capacity: board.capacity,
    emptyTubeCount: board.emptyTubeCount,
    forcedMoveRatio: forcedRatio,
    meanBranching: meanBranching,
    meanScatter: meanScatter,
    maxScatter: maxScatter,
  );
}

/// Walks the optimal path once, collecting both branching statistics.
///
/// The final (won) state is excluded — there is nothing to decide once the
/// board is finished, and counting it would bias every level by the same amount
/// while compressing the range the bands are cut from.
(double forcedRatio, double meanBranching) _walkPath(
  Board board,
  List<Move> solution,
) {
  if (solution.isEmpty) return (1, 0);

  var current = board;
  var forced = 0;
  var branchingTotal = 0;

  for (final move in solution) {
    final branching = branchingFactor(current);
    if (branching <= 1) forced++;
    branchingTotal += branching;
    current = applyMove(current, move).board;
  }

  return (forced / solution.length, branchingTotal / solution.length);
}

/// How many distinct tubes each color occupies at the start.
Map<ColorId, int> _scatterPerColor(Board board) {
  final counts = <ColorId, int>{};
  for (final tube in board.tubes) {
    for (final color in tube.balls.toSet()) {
      counts[color] = (counts[color] ?? 0) + 1;
    }
  }
  return counts;
}

/// Weighted blend of [metrics], BEFORE calibration. Range is roughly 45-90 in
/// practice, not 0-100 — see [difficultyScore], which is the number to use.
///
/// Weights, in order of intended contribution:
///  * **0.32 branching** — `1 - forcedMoveRatio`.
///  * **0.22 empty-tube pressure** — `1 / emptyTubeCount`. One empty tube is
///    the hardest constraint in the game.
///  * **0.18 move load** — `minMoves` per color, which grows as the solution
///    needs more shuffling than a straight sort.
///  * **0.16 scatter** — how far each color is spread at the start.
///  * **0.12 color load** — the crudest signal, and weighted last on purpose:
///    more colors mostly means a bigger board, not a harder one.
double rawDifficultyScore(DifficultyMetrics m) {
  final branching = (1 - m.forcedMoveRatio).clamp(0.0, 1.0);

  final emptyPressure = m.emptyTubeCount <= 0
      ? 1.0
      : (1.0 / m.emptyTubeCount).clamp(0.0, 1.0);

  // Moves per color runs about 1.0 on a near-sorted board up to about 3.0 on a
  // thoroughly shuffled one; normalise that window to 0-1.
  final movesPerColor = m.colorCount == 0 ? 0.0 : m.minMoves / m.colorCount;
  final moveLoad = ((movesPerColor - 1.0) / 2.0).clamp(0.0, 1.0);

  // A color sits in at least 1 tube and at most `capacity` of them.
  final scatterSpan = (m.capacity - 1).clamp(1, 1 << 30);
  final scatter = ((m.meanScatter - 1.0) / scatterSpan).clamp(0.0, 1.0);

  final colorLoad = (m.colorCount / kMaxColors).clamp(0.0, 1.0);

  final blended =
      0.32 * branching +
      0.22 * emptyPressure +
      0.18 * moveLoad +
      0.16 * scatter +
      0.12 * colorLoad;

  return blended * 100;
}

/// Lowest raw blend observed across every shipping spec, with margin.
///
/// Measured over 3-10 colors at both 1 and 2 empty tubes: the floor was 46.9
/// (3 colors) and the ceiling 88.1 (10 colors, 1 empty). These bounds are
/// deliberately a little wider than the observation so a slightly unusual board
/// lands inside the scale rather than clamping.
const double kRawScoreFloor = 45;

/// Highest raw blend observed across every shipping spec, with margin.
const double kRawScoreCeiling = 90;

/// Blends [metrics] into a CALIBRATED 0-100 score used to order and band levels.
///
/// Never shown to the player — it exists so `tool/generate_levels.dart` can sort
/// a candidate pool into a curve, and so a band can be re-tuned after launch by
/// re-sorting rather than regenerating.
///
/// WHY CALIBRATION. The raw blend cannot reach 0 or 100: no real board scores
/// below ~47 or above ~88, because several terms never bottom out together. So
/// the raw number is an interval scale, not a ratio scale, and arithmetic like
/// "25% easier" on it is badly misleading — 25% below a raw 82 lands at 61,
/// which only a 3-color board can reach, which would make every breather level
/// a jarring board-size collapse.
///
/// Mapping the measured range onto 0-100 makes the scale mean what it looks
/// like it means: 0 is about as easy as a generated board gets, 100 about as
/// hard. Ratios become interpretable, which is what the breather rule in
/// `level_curve.dart` depends on. The transform is affine and therefore order-
/// preserving — every relative comparison behaves exactly as before.
double difficultyScore(DifficultyMetrics m) {
  final raw = rawDifficultyScore(m);
  final calibrated =
      (raw - kRawScoreFloor) / (kRawScoreCeiling - kRawScoreFloor) * 100;
  return calibrated.clamp(0.0, 100.0);
}

/// Ceiling on simultaneous colors, set by ACCESSIBILITY rather than by search.
///
/// Every ball carries a color AND a distinct shape glyph, always both. Past
/// ten, the glyphs stop being tellable apart at ball size and the muted palette
/// runs out of separable hues — and a board you have to squint at is not
/// relaxing, which is the product. Difficulty past this point comes from fewer
/// empty tubes, higher scatter and lower forced-move ratio instead.
const int kMaxColors = 10;

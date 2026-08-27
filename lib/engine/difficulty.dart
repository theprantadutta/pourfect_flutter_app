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
/// every step is genuinely hard. That is what [DifficultyMetrics.forcedMoveRatio]
/// captures, and why it carries the largest weight below.
library;

import 'board.dart';
import 'move.dart';
import 'rules.dart';

/// Raw measurements taken from a solved board and its optimal path.
final class DifficultyMetrics {
  /// Optimal solution length.
  final int minMoves;

  /// Distinct colours in play.
  final int colorCount;

  /// Balls per tube.
  final int capacity;

  /// Tubes that start empty. The strongest single lever: going from 2 to 1
  /// removes most of the player's room to manoeuvre and is a much bigger jump
  /// than adding a colour.
  final int emptyTubeCount;

  /// Fraction of states along the optimal path offering at most ONE meaningful
  /// choice, measured as distinct canonical outcomes rather than raw legal
  /// moves — two empty tubes are one choice, not two.
  ///
  /// HIGH means the board plays itself (easy, good for the tutorial band).
  /// LOW means the player is choosing constantly (hard).
  final double forcedMoveRatio;

  /// Mean number of distinct tubes each colour is spread across at the start.
  final double meanScatter;

  /// Worst-case scatter for any single colour at the start.
  final int maxScatter;

  const DifficultyMetrics({
    required this.minMoves,
    required this.colorCount,
    required this.capacity,
    required this.emptyTubeCount,
    required this.forcedMoveRatio,
    required this.meanScatter,
    required this.maxScatter,
  });

  @override
  String toString() =>
      'DifficultyMetrics(minMoves: $minMoves, colours: $colorCount, '
      'empty: $emptyTubeCount, forced: ${forcedMoveRatio.toStringAsFixed(2)}, '
      'scatter: ${meanScatter.toStringAsFixed(2)}/$maxScatter)';
}

/// Measures [board] against its [solution], which must be the OPTIMAL path from
/// the solver — the forced-move ratio is meaningless along a wandering one.
DifficultyMetrics measureDifficulty(Board board, List<Move> solution) {
  final scatter = _scatterPerColour(board);
  final meanScatter = scatter.isEmpty
      ? 0.0
      : scatter.values.reduce((a, b) => a + b) / scatter.length;
  final maxScatter = scatter.isEmpty
      ? 0
      : scatter.values.reduce((a, b) => a > b ? a : b);

  return DifficultyMetrics(
    minMoves: solution.length,
    colorCount: board.colours.length,
    capacity: board.capacity,
    emptyTubeCount: board.emptyTubeCount,
    forcedMoveRatio: _forcedMoveRatio(board, solution),
    meanScatter: meanScatter,
    maxScatter: maxScatter,
  );
}

/// Walks the optimal path and measures how often the player had a real choice.
///
/// The final (won) state is excluded — there is nothing to decide once the
/// board is finished, and counting it would bias every level's ratio upward by
/// the same amount, compressing the range we band on.
double _forcedMoveRatio(Board board, List<Move> solution) {
  if (solution.isEmpty) return 1;

  var current = board;
  var forced = 0;

  for (final move in solution) {
    if (branchingFactor(current) <= 1) forced++;
    current = applyMove(current, move).board;
  }

  return forced / solution.length;
}

/// How many distinct tubes each colour occupies at the start.
Map<ColorId, int> _scatterPerColour(Board board) {
  final counts = <ColorId, int>{};
  for (final tube in board.tubes) {
    for (final colour in tube.balls.toSet()) {
      counts[colour] = (counts[colour] ?? 0) + 1;
    }
  }
  return counts;
}

/// Blends [metrics] into a single 0-100 score used to order and band levels.
///
/// Never shown to the player — it exists so `tool/generate_levels.dart` can
/// sort a large candidate pool into a curve, and so a band can be re-tuned
/// after launch by re-sorting rather than regenerating.
///
/// Weights, in order of contribution:
///  * **0.32 branching** — `1 - forcedMoveRatio`. The best predictor of
///    perceived difficulty; see the note at the top of this file.
///  * **0.22 empty-tube pressure** — `1 / emptyTubeCount`. One empty tube is
///    the hardest constraint in the game.
///  * **0.18 move load** — `minMoves` per colour, which grows as the solution
///    needs more shuffling than a straight sort.
///  * **0.16 scatter** — how far each colour is spread at the start.
///  * **0.12 colour load** — the crudest signal, and weighted last on purpose:
///    more colours mostly means a bigger board, not a harder one, and the
///    palette caps at 10 colours for accessibility anyway.
double difficultyScore(DifficultyMetrics m) {
  final branching = (1 - m.forcedMoveRatio).clamp(0.0, 1.0);

  final emptyPressure = m.emptyTubeCount <= 0
      ? 1.0
      : (1.0 / m.emptyTubeCount).clamp(0.0, 1.0);

  // Moves per colour runs about 1.0 on a near-sorted board up to about 3.0 on a
  // thoroughly shuffled one; normalise that window to 0-1.
  final movesPerColour = m.colorCount == 0 ? 0.0 : m.minMoves / m.colorCount;
  final moveLoad = ((movesPerColour - 1.0) / 2.0).clamp(0.0, 1.0);

  // A colour sits in at least 1 tube and at most `capacity` of them.
  final scatterSpan = (m.capacity - 1).clamp(1, 1 << 30);
  final scatter = ((m.meanScatter - 1.0) / scatterSpan).clamp(0.0, 1.0);

  final colourLoad = (m.colorCount / kMaxColours).clamp(0.0, 1.0);

  final blended =
      0.32 * branching +
      0.22 * emptyPressure +
      0.18 * moveLoad +
      0.16 * scatter +
      0.12 * colourLoad;

  return blended * 100;
}

/// Ceiling on simultaneous colours, set by ACCESSIBILITY rather than by search.
///
/// Every ball carries a colour AND a distinct shape glyph, always both. Past
/// ten, the glyphs stop being tellable apart at ball size and the muted palette
/// runs out of separable hues — and a board you have to squint at is not
/// relaxing, which is the product. Difficulty past this point comes from fewer
/// empty tubes, higher scatter and lower forced-move ratio instead.
const int kMaxColours = 10;

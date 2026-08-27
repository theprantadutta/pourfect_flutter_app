/// Level value type and star rating.
///
/// UI-IMPORTABLE — see the layering note at the top of `board.dart`.
///
/// This is also the SHARED WIRE FORMAT. The generator CLI (`tool/`) emits it,
/// the app reads it out of the baked asset, and the backend seeds its
/// daily-challenge pool from the same JSON — which is what lets the leaderboard
/// anti-cheat check compare a submitted move count against [minMoves] without
/// the server ever running a solver. Any change to [toJson] has to land in the
/// backend seeder in the same commit.
library;

import 'board.dart';

/// Star thresholds, as multiples of [Level.minMoves].
///
/// 3 stars for an optimal solve, 2 within 1.5x, 1 otherwise. A player who
/// finishes at all always earns at least one star: the floor is finishing, not
/// efficiency, because punishing a completed level reads as mean in a game
/// whose whole pitch is relaxing.
const double kTwoStarMoveMultiplier = 1.5;

/// Stars earned for solving a level with [minMoves] optimum in [movesUsed].
///
/// Returns 0 only for an unfinished level; call it after a win.
int starsFor({required int minMoves, required int movesUsed}) {
  if (movesUsed <= 0) return 0;
  if (movesUsed <= minMoves) return 3;
  if (movesUsed <= (minMoves * kTwoStarMoveMultiplier).ceil()) return 2;
  return 1;
}

/// A shipped, solver-verified level.
///
/// Every instance that reaches a player has been proven solvable by our own
/// solver, and [minMoves] is the length of the optimal solution the solver
/// found — not an estimate. Unsolvable levels are the top-rated complaint in
/// this genre, so the invariant is enforced at generation time and re-asserted
/// by `tool/validate_levels.dart` before the asset is baked.
final class Level {
  /// 1-based level number within the campaign. Also the asset's sort key.
  final int id;

  /// The starting position.
  final Board board;

  /// Optimal solution length, from the solver. Drives the star rating and the
  /// server-side anti-cheat floor.
  final int minMoves;

  /// Blended difficulty score — see `difficulty.dart`. Used to order and band
  /// levels at bake time; never shown to the player.
  final double difficultyScore;

  /// Fraction of states along the optimal path with only one meaningful move.
  ///
  /// Retained on the shipped level because it is the best single predictor of
  /// PERCEIVED difficulty, and re-tuning a band after launch means sorting on
  /// it rather than regenerating from scratch.
  final double forcedMoveRatio;

  const Level({
    required this.id,
    required this.board,
    required this.minMoves,
    required this.difficultyScore,
    required this.forcedMoveRatio,
  });

  /// Balls per tube.
  int get capacity => board.capacity;

  /// How many distinct colours the level uses.
  int get colorCount => board.colours.length;

  /// How many tubes start empty. The strongest difficulty lever we have:
  /// dropping from 2 to 1 is a far bigger jump than adding a colour.
  int get emptyTubeCount => board.emptyTubeCount;

  /// Total tubes, filled plus empty.
  int get tubeCount => board.tubeCount;

  /// Stars a player earns for finishing this level in [movesUsed].
  int stars(int movesUsed) =>
      starsFor(minMoves: minMoves, movesUsed: movesUsed);

  Map<String, Object?> toJson() => {
    'id': id,
    'capacity': capacity,
    'tubes': board.toLists(),
    'min_moves': minMoves,
    'color_count': colorCount,
    'empty_tube_count': emptyTubeCount,
    'difficulty_score': difficultyScore,
    'forced_move_ratio': forcedMoveRatio,
  };

  /// Rebuilds a level from [toJson] output.
  ///
  /// `color_count` and `empty_tube_count` are derived from the board rather
  /// than trusted from the payload — they are written for the backend seeder's
  /// convenience, and a mismatch would otherwise be silent.
  factory Level.fromJson(Map<String, Object?> json) {
    final capacity = (json['capacity']! as num).toInt();
    final rawTubes = (json['tubes']! as List)
        .map((t) => (t as List).map((c) => (c as num).toInt()).toList())
        .toList();
    return Level(
      id: (json['id']! as num).toInt(),
      board: Board.fromLists(rawTubes, capacity: capacity),
      minMoves: (json['min_moves']! as num).toInt(),
      difficultyScore: (json['difficulty_score']! as num).toDouble(),
      forcedMoveRatio: (json['forced_move_ratio']! as num).toDouble(),
    );
  }

  Level copyWith({int? id}) => Level(
    id: id ?? this.id,
    board: board,
    minMoves: minMoves,
    difficultyScore: difficultyScore,
    forcedMoveRatio: forcedMoveRatio,
  );

  @override
  String toString() =>
      'Level($id, colours: $colorCount, empty: $emptyTubeCount, '
      'minMoves: $minMoves, difficulty: ${difficultyScore.toStringAsFixed(1)})';
}

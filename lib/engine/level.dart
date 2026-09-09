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

/// Par time, in seconds, for a level whose optimal solution is [minMoves].
///
/// DERIVED, NEVER AUTHORED. Par is a pure function of the one number the
/// solver already proved, which means it costs nothing to ship: `levels.bin`
/// is untouched, no level needs regenerating, and the backend computes the
/// identical value from the `min_moves` it already stores. The alternative —
/// a `par_seconds` column in the asset — would bump the format version and
/// force the seeder and the reproducibility test to move with it, all to hand
/// tune 150 numbers nobody would ever revisit.
///
/// The allowance is deliberately generous. This is a game people play in bed:
/// par is the pace of somebody who knows what they are doing and is not
/// hurrying, not a speedrun target. Beating it is a bonus, missing it costs a
/// fraction of the points, and neither affects stars.
const double kParBaseSeconds = 30;
const double kParSecondsPerMove = 5;

int parSecondsFor(int minMoves) =>
    (kParBaseSeconds + minMoves * kParSecondsPerMove).round();

/// Points scale with the level's optimal length, so a hard level is worth more
/// than an easy one solved just as cleanly.
const int kPointsPerOptimalMove = 100;

/// How far the clock can move the score, as a multiple.
///
/// Bounded on BOTH sides on purpose. The ceiling means a forged elapsed time
/// of one second is worth no more than an honest fast solve, which is most of
/// what stops the clock being a cheat vector. The floor means a player who
/// wandered off mid-level and came back an hour later still banks half —
/// finishing is always worth something, the same rule the star floor follows.
const double kMaxTimeMultiplier = 1.25;
const double kMinTimeMultiplier = 0.5;

/// The score multiplier earned by finishing in [elapsedSeconds] against
/// [parSeconds]. Exactly 1.0 at par.
double timeMultiplierFor({
  required int parSeconds,
  required int elapsedSeconds,
}) {
  if (parSeconds <= 0) return 1;
  if (elapsedSeconds <= 0) return kMaxTimeMultiplier;
  return (parSeconds / elapsedSeconds).clamp(
    kMinTimeMultiplier,
    kMaxTimeMultiplier,
  );
}

/// Points for finishing a level with [minMoves] optimum in [movesUsed] moves
/// and [elapsedSeconds] of play.
///
/// Two independent factors over a difficulty-scaled base: how close to optimal
/// the solution was, and how the clock went. Stars are NOT part of this and
/// are not affected by it — a player who takes their time still earns every
/// star their moves deserve, and only the score reflects the clock.
int pointsFor({
  required int minMoves,
  required int movesUsed,
  required int elapsedSeconds,
}) {
  if (movesUsed <= 0 || minMoves <= 0) return 0;
  final base = kPointsPerOptimalMove * minMoves;
  final efficiency = (minMoves / movesUsed).clamp(0.0, 1.0);
  final time = timeMultiplierFor(
    parSeconds: parSecondsFor(minMoves),
    elapsedSeconds: elapsedSeconds,
  );
  return (base * efficiency * time).round();
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

  /// How many distinct colors the level uses.
  int get colorCount => board.colors.length;

  /// How many tubes start empty. The strongest difficulty lever we have:
  /// dropping from 2 to 1 is a far bigger jump than adding a color.
  int get emptyTubeCount => board.emptyTubeCount;

  /// Total tubes, filled plus empty.
  int get tubeCount => board.tubeCount;

  /// Stars a player earns for finishing this level in [movesUsed].
  int stars(int movesUsed) =>
      starsFor(minMoves: minMoves, movesUsed: movesUsed);

  /// The pace this level is scored against. Derived, not stored — see
  /// [parSecondsFor].
  int get parSeconds => parSecondsFor(minMoves);

  /// Points for finishing this level in [movesUsed] and [elapsedSeconds].
  int points({required int movesUsed, required int elapsedSeconds}) =>
      pointsFor(
        minMoves: minMoves,
        movesUsed: movesUsed,
        elapsedSeconds: elapsedSeconds,
      );

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
      'Level($id, colors: $colorCount, empty: $emptyTubeCount, '
      'minMoves: $minMoves, difficulty: ${difficultyScore.toStringAsFixed(1)})';
}

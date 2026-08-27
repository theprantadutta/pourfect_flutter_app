/// Move value types for the ball-sort engine.
///
/// UI-IMPORTABLE — see the layering note at the top of `board.dart`. Data only;
/// legality and application live in `rules.dart`.
library;

import 'board.dart';

/// A single move: pour the top run of [from] into [to].
///
/// A move carries no ball count. How many balls actually travel depends on the
/// board it is applied to (the top run's length, clamped by the destination's
/// free space), so it is resolved by `applyMove` rather than stored here. That
/// keeps a [Move] replayable against any board — which is what lets the undo
/// stack and the solution path stay plain lists of moves.
final class Move {
  /// Index of the source tube.
  final int from;

  /// Index of the destination tube.
  final int to;

  const Move(this.from, this.to);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Move && other.from == from && other.to == to);

  @override
  int get hashCode => Object.hash(from, to);

  @override
  String toString() => 'Move($from→$to)';
}

/// The outcome of applying a [Move] to a [Board].
///
/// [ballsMoved] is what the UI animates: it drives how many balls arc across,
/// and the landing squash-and-stretch fires once per ball rather than once per
/// move.
final class MoveResult {
  /// The board after the move.
  final Board board;

  /// The move that produced it.
  final Move move;

  /// How many balls actually travelled — always at least 1.
  final int ballsMoved;

  /// The colour that travelled.
  final ColorId colour;

  /// True when the destination tube became complete as a result.
  ///
  /// The trigger for the settle-and-glow flourish and the stronger haptic.
  final bool completedDestination;

  const MoveResult({
    required this.board,
    required this.move,
    required this.ballsMoved,
    required this.colour,
    required this.completedDestination,
  });

  @override
  String toString() =>
      'MoveResult($move, balls: $ballsMoved, colour: $colour, '
      'completed: $completedDestination)';
}

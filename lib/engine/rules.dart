/// The rules of ball sort: legality, application, dead-state detection.
///
/// ENGINE LOGIC — `ui/` must not import this file. The UI reaches these results
/// through `state/`, which is where the undo stack and selection live.
library;

import 'board.dart';
import 'canonical.dart';
import 'move.dart';

/// True when pouring [from] into [to] is legal on [board].
///
/// Legal iff the tubes differ, the source has a ball, the destination has room,
/// and the destination is either empty or topped with the source's color.
bool canMove(Board board, int from, int to) {
  if (from == to) return false;
  if (from < 0 || to < 0 || from >= board.tubeCount || to >= board.tubeCount) {
    return false;
  }
  final source = board[from];
  final dest = board[to];
  if (source.isEmpty) return false;
  if (dest.isFull) return false;
  return dest.isEmpty || dest.top == source.top;
}

/// How many balls would actually travel for a legal move, or 0 if illegal.
///
/// The WHOLE contiguous top run moves, clamped by the destination's free space.
/// Moving the run rather than a single ball is the difference between a game
/// that feels satisfying and one that feels like paperwork — it is a rule, not
/// an optimisation.
int ballsThatWouldMove(Board board, int from, int to) {
  if (!canMove(board, from, to)) return 0;
  final run = board[from].topRunLength;
  final space = board[to].freeSpace;
  return run < space ? run : space;
}

/// Applies [move] to [board], returning the new board and what travelled.
///
/// Throws [ArgumentError] when the move is illegal — callers that may hold a
/// stale move should use [tryApplyMove].
MoveResult applyMove(Board board, Move move) {
  final result = tryApplyMove(board, move);
  if (result == null) {
    throw ArgumentError.value(move, 'move', 'illegal on this board');
  }
  return result;
}

/// Applies [move], or returns `null` when it is illegal.
MoveResult? tryApplyMove(Board board, Move move) {
  final count = ballsThatWouldMove(board, move.from, move.to);
  if (count == 0) return null;

  final source = board[move.from];
  final dest = board[move.to];
  final color = source.top!;

  final nextSource = Tube(
    source.balls.sublist(0, source.length - count),
    board.capacity,
  );
  final nextDest = Tube([
    ...dest.balls,
    ...List<ColorId>.filled(count, color),
  ], board.capacity);

  final next = board
      .replaceTube(move.from, nextSource)
      .replaceTube(move.to, nextDest);

  return MoveResult(
    board: next,
    move: move,
    ballsMoved: count,
    color: color,
    completedDestination: nextDest.isComplete,
  );
}

/// Every legal move on [board], unfiltered.
///
/// This is the honest rules-level answer — used for dead-state detection and
/// for the UI's "which tubes can I pour into". For SEARCH, use [usefulMoves],
/// which strips moves that cannot lead anywhere new.
List<Move> legalMoves(Board board) {
  final moves = <Move>[];
  for (var from = 0; from < board.tubeCount; from++) {
    if (board[from].isEmpty) continue;
    for (var to = 0; to < board.tubeCount; to++) {
      if (canMove(board, from, to)) moves.add(Move(from, to));
    }
  }
  return moves;
}

/// The destinations a player may pour tube [from] into.
///
/// Drives the board's selection affordance: destinations NOT in this list dim
/// to 40% while a run is held.
List<int> legalDestinationsFrom(Board board, int from) {
  final destinations = <int>[];
  for (var to = 0; to < board.tubeCount; to++) {
    if (canMove(board, from, to)) destinations.add(to);
  }
  return destinations;
}

/// Legal moves worth searching: no dead ends, no duplicates, best-first.
///
/// Three reductions, all of which preserve optimality:
///
/// 1. **Never disturb a finished tube.** Each color has exactly `capacity`
///    balls, so once a tube is full and single-colored it holds ALL of that
///    color — no other tube can be topped with it, leaving only empty tubes as
///    destinations, which reduction 2 already rejects. Taking it apart can
///    never help.
/// 2. **Never pour a uniform tube into an empty one.** The source empties and
///    the destination gains exactly what the source held: the same position
///    with two tubes swapped, which is the SAME canonical state. A pure cycle.
/// 3. **Collapse interchangeable tubes.** Two tubes with identical contents
///    produce identical outcomes, so only the first of each distinct content is
///    considered as a source, and likewise per destination.
///
/// Ordering is best-first — moves that COMPLETE a tube, then moves onto a
/// matching color, then moves into an empty tube. Pouring into an empty tube
/// is usually wasteful (it spends the scarcest resource on the board), so it is
/// tried last and prunes hardest.
List<Move> usefulMoves(Board board) {
  final completing = <Move>[];
  final ontoMatching = <Move>[];
  final intoEmpty = <Move>[];

  final base = baseForMaxColor(board.maxColor);
  final codes = [for (final t in board.tubes) tubeCode(t.balls, base)];

  final seenSource = <int>{};
  for (var from = 0; from < board.tubeCount; from++) {
    final source = board[from];
    if (source.isEmpty) continue;
    if (source.isComplete) continue; // reduction 1
    if (!seenSource.add(codes[from])) continue; // reduction 3

    final run = source.topRunLength;
    final sourceIsUniform = source.isUniform;

    final seenDest = <int>{};
    for (var to = 0; to < board.tubeCount; to++) {
      if (to == from) continue;
      final dest = board[to];
      if (dest.isFull) continue;

      if (dest.isEmpty) {
        if (sourceIsUniform) continue; // reduction 2
        if (!seenDest.add(codes[to])) continue; // reduction 3
        intoEmpty.add(Move(from, to));
        continue;
      }

      if (dest.top != source.top) continue;
      if (!seenDest.add(codes[to])) continue; // reduction 3

      final moved = run < dest.freeSpace ? run : dest.freeSpace;
      final completes = dest.length + moved == board.capacity && dest.isUniform;
      if (completes) {
        completing.add(Move(from, to));
      } else {
        ontoMatching.add(Move(from, to));
      }
    }
  }

  return [...completing, ...ontoMatching, ...intoEmpty];
}

/// True when the board is stuck: not won, and no legal move remains.
///
/// The UI must surface this the moment it happens and offer undo or restart.
/// Letting a player sit on a dead board wondering what they missed is how a
/// relaxing game earns a one-star review.
bool isDead(Board board) => !board.isWon && legalMoves(board).isEmpty;

/// Number of MEANINGFUL choices available — distinct canonical outcomes.
///
/// Not the same as `legalMoves(board).length`: pouring into either of two empty
/// tubes counts once, because the resulting positions are identical. This is
/// the branching factor a player actually perceives, and it is what
/// `difficulty.dart` samples along the solution path.
int branchingFactor(Board board) {
  final outcomes = <String>{};
  for (final move in usefulMoves(board)) {
    final result = tryApplyMove(board, move);
    if (result != null) outcomes.add(canonicalKey(result.board));
  }
  return outcomes.length;
}

/// IDA* solver for ball sort.
///
/// ENGINE LOGIC — `ui/` must not import this file.
///
/// Used for three jobs, and it is the same code in all three:
///  * **Generation.** A board is only shipped if this solver proves it solvable.
///    "No unsolvable levels, ever" is the single biggest rating-killer in this
///    genre, and this is where that promise is kept.
///  * **`minMoves`.** The returned path is OPTIMAL, so its length is the true
///    minimum. That number drives the star rating and the server-side
///    anti-cheat floor, so an approximation would not do.
///  * **Hints.** Re-solved from the player's live position, on an isolate.
///
/// Runtime cost is bounded by [Solver.nodeCap] rather than by time, so the
/// result is deterministic across devices — the same board yields the same
/// answer on a flagship and on a budget phone. Exceeding the cap returns
/// [SolveUnknown], never a hang and never a wrong answer.
library;

import 'board.dart';
import 'canonical.dart';
import 'move.dart';

/// Result of a solve attempt.
sealed class SolveOutcome {
  const SolveOutcome();
}

/// The board is solvable, in [moves] — an OPTIMAL sequence.
final class Solved extends SolveOutcome {
  /// The optimal move sequence. Empty when the board was already won.
  final List<Move> moves;

  /// Nodes expanded before the solution was found.
  final int nodesExplored;

  const Solved(this.moves, this.nodesExplored);

  /// Optimal move count — the level's `minMoves`.
  int get moveCount => moves.length;
}

/// The board is provably unsolvable: the search space was exhausted.
final class Unsolvable extends SolveOutcome {
  final int nodesExplored;

  const Unsolvable(this.nodesExplored);
}

/// The node cap was hit before the search concluded.
///
/// Distinct from [Unsolvable] on purpose. Treating "I gave up" as "impossible"
/// is how an unsolvable level ships: the generator DISCARDS this outcome rather
/// than trusting it either way.
final class SolveUnknown extends SolveOutcome {
  final int nodesExplored;

  const SolveUnknown(this.nodesExplored);
}

/// Test-only view of the move list the search would try from [board], in order.
///
/// Exists so a test can pin the search's private generator against
/// `usefulMoves` in `rules.dart`. The two implement the same three reductions
/// against different representations and must never drift apart; without this
/// hook that claim would be untested.
List<Move> debugGenerateMoves(Board board) =>
    _Search(board, 1)._generateMoves();

/// Sentinel returned by the recursive search when a solution was found.
const int _found = -1;

/// Stands in for "no solution reachable down this branch".
const int _infinity = 1 << 30;

/// Entries kept in the per-iteration transposition table before it is dropped.
///
/// Clearing loses pruning but never correctness, so this is a memory ceiling
/// rather than a search parameter — it stops a pathological board from taking
/// the process down on a low-end phone.
const int _maxTranspositionEntries = 1 << 21;

/// Node budget for BUILD-TIME work: level generation and validation.
///
/// Set from measurement, not taste. The hardest shipping band (10 colours, 2
/// empty tubes) peaks at ~602k nodes, so this is roughly 2.5x the observed
/// worst case. At 400k about 3% of otherwise-good boards came back
/// [SolveUnknown] and were discarded — and because a discard costs a whole
/// wasted solve plus a fresh deal, the tighter cap was measurably SLOWER
/// end-to-end as well as lossier.
const int kGenerationNodeCap = 1500000;

/// Node budget for RUNTIME hints, which run on a background isolate.
///
/// Deliberately far below [kGenerationNodeCap]. A hint is a convenience: the
/// player's board is mid-play and therefore much easier than the position the
/// level shipped in, so this decides virtually every real request, and when it
/// does not, "no hint available" beats a phone chewing for two seconds. Worth
/// re-tuning against a real low-end device in stage 7.
const int kHintNodeCap = 300000;

class Solver {
  /// Hard ceiling on nodes expanded, across all IDA* iterations.
  final int nodeCap;

  const Solver({this.nodeCap = kGenerationNodeCap});

  /// A solver budgeted for interactive hints rather than for the bake.
  const Solver.forHints() : nodeCap = kHintNodeCap;

  /// Solves [board], returning an optimal path, a proof of impossibility, or
  /// [SolveUnknown] if [nodeCap] was reached first.
  ///
  /// Throws [ArgumentError] if the board violates the colour-count invariant
  /// (see [_assertBallCounts]).
  SolveOutcome solve(Board board) {
    _assertBallCounts(board);
    return _Search(board, nodeCap).run();
  }

  /// The next optimal move from [board], or `null` when the board is won,
  /// unsolvable, or the search gave up.
  ///
  /// Callers should run this off the UI isolate: on a 10-colour board it can
  /// take long enough to drop frames.
  Move? hint(Board board) {
    final outcome = solve(board);
    if (outcome is Solved && outcome.moves.isNotEmpty) {
      return outcome.moves.first;
    }
    return null;
  }

  /// Whether [board] can be finished at all. [SolveUnknown] counts as "not
  /// proven", which is what the generator needs.
  bool isSolvable(Board board) => solve(board) is Solved;

  /// The solver's goal test is `heuristic == 0`, which is equivalent to "won"
  /// ONLY when every colour has exactly `capacity` balls on the board. That
  /// holds for every generated level and is preserved by play and by the
  /// add-tube power-up, so a violation means a caller built a board by hand and
  /// would otherwise get a confidently wrong answer.
  static void _assertBallCounts(Board board) {
    final counts = <ColorId, int>{};
    for (final tube in board.tubes) {
      for (final c in tube.balls) {
        counts[c] = (counts[c] ?? 0) + 1;
      }
    }
    for (final entry in counts.entries) {
      if (entry.value != board.capacity) {
        throw ArgumentError.value(
          board,
          'board',
          'colour ${entry.key} has ${entry.value} balls, expected exactly '
              '${board.capacity} — the solver requires one full tube of every '
              'colour',
        );
      }
    }
  }
}

/// One solve, over a mutable copy of the board.
///
/// The search applies and UNDOES moves in place rather than allocating a new
/// board per node. At millions of nodes that difference is the whole budget.
class _Search {
  final int capacity;
  final int tubeCount;
  final int maxColour;
  final int base;
  final int nodeCap;

  /// Mutable bottom-first tube contents.
  final List<List<ColorId>> tubes;

  /// Scratch for the heuristic — reused rather than reallocated per node.
  final List<int> _colourTubeCount;

  final List<Move> _path = [];

  /// Canonical key -> lowest g at which it was reached this iteration.
  Map<String, int> _seen = {};

  int _nodes = 0;
  bool _exhausted = false;

  _Search(Board board, this.nodeCap)
    : capacity = board.capacity,
      tubeCount = board.tubeCount,
      maxColour = board.maxColour,
      base = baseForMaxColour(board.maxColour),
      tubes = [for (final t in board.tubes) List<ColorId>.of(t.balls)],
      _colourTubeCount = List<int>.filled(board.maxColour + 2, 0);

  SolveOutcome run() {
    var threshold = _heuristic();
    if (threshold == 0) return Solved(const [], 0);

    while (true) {
      _seen = {};
      final t = _dfs(0, threshold);

      if (t == _found) return Solved(List<Move>.of(_path), _nodes);
      if (_exhausted) return SolveUnknown(_nodes);
      if (t >= _infinity) return Unsolvable(_nodes);

      // t is the smallest f that overshot; raising the bar to exactly that
      // keeps the next iteration admissible, so the first solution found is
      // still optimal.
      threshold = t;
    }
  }

  /// Depth-first search bounded by [threshold] on f = g + h.
  ///
  /// Returns [_found] when a solution is on [_path], otherwise the smallest f
  /// that exceeded [threshold] in this subtree (used as the next threshold).
  int _dfs(int g, int threshold) {
    if (_exhausted) return _infinity;

    final h = _heuristic();
    if (h == 0) return _found; // goal — see Solver._assertBallCounts

    final f = g + h;
    if (f > threshold) return f;

    if (_nodes >= nodeCap) {
      _exhausted = true;
      return _infinity;
    }
    _nodes++;

    // Transposition pruning. Reaching this position again at no lower cost
    // cannot yield anything the earlier visit did not already explore — and
    // because g strictly increases down the path, this doubles as the
    // cycle check.
    final key = canonicalKeyOfLists(tubes, base: base);
    final previousG = _seen[key];
    if (previousG != null && previousG <= g) return _infinity;
    if (_seen.length >= _maxTranspositionEntries) _seen = {};
    _seen[key] = g;

    var min = _infinity;
    for (final move in _generateMoves()) {
      final moved = _apply(move.from, move.to);
      _path.add(move);

      final t = _dfs(g + 1, threshold);
      if (t == _found) return _found;

      _path.removeLast();
      _undo(move.from, move.to, moved);

      if (_exhausted) return _infinity;
      if (t < min) min = t;
    }
    return min;
  }

  /// Admissible heuristic: for each colour, the number of distinct tubes
  /// holding it, minus one, summed.
  ///
  /// Read as "how many merges remain". It is admissible because a single move
  /// pours one colour from one tube into one other, so it can reduce the count
  /// for at most one colour, by at most one — no move can ever make more than
  /// one unit of progress against this measure.
  int _heuristic() {
    for (var c = 0; c <= maxColour; c++) {
      _colourTubeCount[c] = 0;
    }
    for (var i = 0; i < tubeCount; i++) {
      final tube = tubes[i];
      var mask = 0;
      for (var j = 0; j < tube.length; j++) {
        final bit = 1 << tube[j];
        if (mask & bit == 0) {
          mask |= bit;
          _colourTubeCount[tube[j]]++;
        }
      }
    }
    var h = 0;
    for (var c = 0; c <= maxColour; c++) {
      if (_colourTubeCount[c] > 0) h += _colourTubeCount[c] - 1;
    }
    return h;
  }

  /// Moves worth trying from the current position, best-first.
  ///
  /// Mirrors `usefulMoves` in `rules.dart` — same three reductions, same
  /// ordering — but reads the mutable representation directly. The duplication
  /// is deliberate: `rules.dart` is the readable statement of the rule and is
  /// what the tests pin, this is the hot loop, and a cross-check test asserts
  /// the two agree.
  List<Move> _generateMoves() {
    final completing = <Move>[];
    final ontoMatching = <Move>[];
    final intoEmpty = <Move>[];

    final codes = List<int>.generate(
      tubeCount,
      (i) => tubeCode(tubes[i], base),
      growable: false,
    );

    final seenSource = <int>{};
    for (var from = 0; from < tubeCount; from++) {
      final source = tubes[from];
      if (source.isEmpty) continue;
      if (_isComplete(from)) continue;
      if (!seenSource.add(codes[from])) continue;

      final colour = source.last;
      final run = _topRun(from);
      final sourceUniform = _isUniform(from);

      final seenDest = <int>{};
      for (var to = 0; to < tubeCount; to++) {
        if (to == from) continue;
        final dest = tubes[to];
        final free = capacity - dest.length;
        if (free == 0) continue;

        if (dest.isEmpty) {
          if (sourceUniform) continue;
          if (!seenDest.add(codes[to])) continue;
          intoEmpty.add(Move(from, to));
          continue;
        }

        if (dest.last != colour) continue;
        if (!seenDest.add(codes[to])) continue;

        final moved = run < free ? run : free;
        if (dest.length + moved == capacity && _isUniform(to)) {
          completing.add(Move(from, to));
        } else {
          ontoMatching.add(Move(from, to));
        }
      }
    }

    return [...completing, ...ontoMatching, ...intoEmpty];
  }

  int _topRun(int index) {
    final tube = tubes[index];
    if (tube.isEmpty) return 0;
    final colour = tube.last;
    var n = 0;
    for (var i = tube.length - 1; i >= 0 && tube[i] == colour; i--) {
      n++;
    }
    return n;
  }

  bool _isUniform(int index) {
    final tube = tubes[index];
    if (tube.isEmpty) return true;
    final first = tube[0];
    for (var i = 1; i < tube.length; i++) {
      if (tube[i] != first) return false;
    }
    return true;
  }

  bool _isComplete(int index) =>
      tubes[index].length == capacity && _isUniform(index);

  /// Pours the top run of [from] into [to], returning how many balls moved.
  int _apply(int from, int to) {
    final source = tubes[from];
    final dest = tubes[to];
    final colour = source.last;
    final run = _topRun(from);
    final free = capacity - dest.length;
    final count = run < free ? run : free;
    for (var i = 0; i < count; i++) {
      source.removeLast();
      dest.add(colour);
    }
    return count;
  }

  /// Exact inverse of [_apply]; [count] is what [_apply] returned.
  void _undo(int from, int to, int count) {
    final source = tubes[from];
    final dest = tubes[to];
    final colour = dest.last;
    for (var i = 0; i < count; i++) {
      dest.removeLast();
      source.add(colour);
    }
  }
}

/// Board value types for the ball-sort engine.
///
/// UI-IMPORTABLE. This file holds data and invariant accessors only — no move
/// generation, no solving, no generation. Those live in `rules.dart`,
/// `solver.dart`, `generator.dart` and `difficulty.dart`, which `ui/` must
/// never import. See CLAUDE.md for the full layering rule.
///
/// Nothing in `engine/` may import Flutter or Riverpod.
library;

/// A ball color, as an opaque integer.
///
/// The engine never knows what a color looks like. `ui/theme` is the only
/// place that maps a [ColorId] onto a palette entry and its accessibility
/// glyph — keeping it an int here is what lets the solver treat colors as
/// interchangeable symbols, and lets the palette change without touching a
/// line of game logic.
typedef ColorId = int;

/// One tube: an ordered stack of balls with a fixed capacity.
///
/// Index 0 is the BOTTOM of the tube; the last element is the top, which is
/// the only ball a player can ever touch. Immutable — every move produces a
/// new [Tube] rather than mutating one in place, so the undo stack can simply
/// hold previous boards.
final class Tube {
  /// Bottom-to-top ball colors. Always unmodifiable.
  final List<ColorId> balls;

  /// How many balls this tube can hold. Uniform across a [Board].
  final int capacity;

  const Tube._(this.balls, this.capacity);

  /// Creates a tube from [balls] (bottom-first), copying defensively.
  factory Tube(List<ColorId> balls, int capacity) {
    if (capacity <= 0) {
      throw ArgumentError.value(capacity, 'capacity', 'must be positive');
    }
    if (balls.length > capacity) {
      throw ArgumentError.value(
        balls.length,
        'balls',
        'holds more than capacity ($capacity)',
      );
    }
    for (final c in balls) {
      if (c < 0) {
        throw ArgumentError.value(c, 'balls', 'color ids must be non-negative');
      }
    }
    return Tube._(List<ColorId>.unmodifiable(balls), capacity);
  }

  /// An empty tube of the given [capacity].
  factory Tube.empty(int capacity) => Tube(const <ColorId>[], capacity);

  /// Number of balls currently in the tube.
  int get length => balls.length;

  bool get isEmpty => balls.isEmpty;

  bool get isNotEmpty => balls.isNotEmpty;

  bool get isFull => balls.length == capacity;

  /// Room left, in balls.
  int get freeSpace => capacity - balls.length;

  /// The topmost ball, or `null` when empty. The only ball a move can ever
  /// originate from.
  ColorId? get top => balls.isEmpty ? null : balls.last;

  /// How many same-colored balls sit contiguously at the top.
  ///
  /// This is the size of the run a move would carry — the game moves the whole
  /// run, not one ball, which is what makes it feel good to play.
  int get topRunLength {
    if (balls.isEmpty) return 0;
    final color = balls.last;
    var n = 0;
    for (var i = balls.length - 1; i >= 0 && balls[i] == color; i--) {
      n++;
    }
    return n;
  }

  /// True when the tube is empty, or holds exactly one color.
  ///
  /// A uniform-but-not-full tube is "clean but unfinished"; see [isComplete].
  bool get isUniform {
    if (balls.isEmpty) return true;
    final first = balls.first;
    for (final c in balls) {
      if (c != first) return false;
    }
    return true;
  }

  /// True when the tube is full AND single-colored — a finished tube.
  ///
  /// The win condition is every tube being empty or complete, and the UI uses
  /// this to trigger the settle-and-glow flourish on the tube that just closed.
  bool get isComplete => isFull && isUniform;

  /// Distinct colors present, as a bitmask (`1 << colorId`).
  ///
  /// The solver's heuristic needs "how many tubes hold color c" far more often
  /// than it needs the balls themselves; a mask makes that a popcount.
  int get colorMask {
    var mask = 0;
    for (final c in balls) {
      mask |= 1 << c;
    }
    return mask;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Tube) return false;
    if (other.capacity != capacity || other.balls.length != balls.length) {
      return false;
    }
    for (var i = 0; i < balls.length; i++) {
      if (balls[i] != other.balls[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(capacity, Object.hashAll(balls));

  @override
  String toString() => 'Tube(${balls.join(",")}/$capacity)';
}

/// A full board: an ordered list of tubes sharing one capacity.
///
/// Immutable. Tube ORDER is significant to equality here — two boards differing
/// only by a swap of two tubes are `!=` — because the UI needs stable tube
/// positions across a move. The solver deliberately erases that ordering via
/// `canonicalKey`; see `canonical.dart` for why that collapse is the single
/// biggest speedup available.
final class Board {
  /// Left-to-right tubes. Always unmodifiable.
  final List<Tube> tubes;

  /// Capacity shared by every tube.
  final int capacity;

  const Board._(this.tubes, this.capacity);

  /// Creates a board, verifying every tube shares one capacity.
  factory Board(List<Tube> tubes) {
    if (tubes.isEmpty) {
      throw ArgumentError.value(tubes, 'tubes', 'board must have a tube');
    }
    final capacity = tubes.first.capacity;
    for (final t in tubes) {
      if (t.capacity != capacity) {
        throw ArgumentError.value(
          t.capacity,
          'tubes',
          'mixed capacities on one board (expected $capacity)',
        );
      }
    }
    return Board._(List<Tube>.unmodifiable(tubes), capacity);
  }

  /// Convenience constructor from raw bottom-first color lists.
  ///
  /// `Board.fromLists([[0, 0, 1], [1, 1, 0], []], capacity: 3)`
  factory Board.fromLists(List<List<ColorId>> tubes, {required int capacity}) =>
      Board([for (final t in tubes) Tube(t, capacity)]);

  int get tubeCount => tubes.length;

  Tube operator [](int index) => tubes[index];

  /// Number of tubes holding no balls.
  int get emptyTubeCount {
    var n = 0;
    for (final t in tubes) {
      if (t.isEmpty) n++;
    }
    return n;
  }

  /// The distinct colors on the board.
  Set<ColorId> get colors => {for (final t in tubes) ...t.balls};

  /// Highest color id present, or -1 on an empty board. Sizes the solver's
  /// per-color scratch buffers.
  int get maxColor {
    var max = -1;
    for (final t in tubes) {
      for (final c in t.balls) {
        if (c > max) max = c;
      }
    }
    return max;
  }

  /// Total balls on the board.
  int get ballCount {
    var n = 0;
    for (final t in tubes) {
      n += t.length;
    }
    return n;
  }

  /// THE WIN CONDITION: every tube is either empty, or full and single-colored.
  ///
  /// This is an invariant of the board value rather than a rule that needs
  /// applying — which is why it lives here and stays reachable from the UI.
  bool get isWon {
    for (final t in tubes) {
      if (t.isNotEmpty && !t.isComplete) return false;
    }
    return true;
  }

  /// Returns a copy with tube [index] replaced by [tube].
  Board replaceTube(int index, Tube tube) {
    final next = List<Tube>.of(tubes);
    next[index] = tube;
    return Board._(List<Tube>.unmodifiable(next), capacity);
  }

  /// Returns a copy with one extra empty tube appended.
  ///
  /// Backs the add-tube power-up. Solvability CHANGES when a tube is added, so
  /// callers must re-run the solver against the result rather than reusing any
  /// cached solution.
  Board withExtraEmptyTube() => Board([...tubes, Tube.empty(capacity)]);

  /// Deep bottom-first color lists — the serialization form shared by the
  /// baked level asset and the backend daily-challenge seed.
  List<List<ColorId>> toLists() => [
    for (final t in tubes) List<ColorId>.of(t.balls),
  ];

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Board) return false;
    if (other.capacity != capacity || other.tubes.length != tubes.length) {
      return false;
    }
    for (var i = 0; i < tubes.length; i++) {
      if (tubes[i] != other.tubes[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(capacity, Object.hashAll(tubes));

  @override
  String toString() =>
      'Board(${tubes.map((t) => t.balls.join(",")).join(" | ")})';
}

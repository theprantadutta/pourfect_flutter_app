/// Canonical state hashing.
///
/// ENGINE LOGIC — `ui/` must not import this file.
///
/// Two boards are equivalent for solving purposes if their tube CONTENTS match
/// regardless of tube ORDER: nothing about the puzzle changes if you slide two
/// tubes past each other on the shelf. A board with n interchangeable tubes
/// therefore appears in the raw search space up to n! times over.
///
/// Collapsing that permutation space is the single biggest speedup in the
/// solver — far larger than the heuristic or the move ordering. On a 10-colour,
/// 12-tube board the raw space is ~479 million orderings of every position;
/// canonicalising cuts the visited set to the positions that actually differ.
/// Do not "optimise" this away.
library;

import 'board.dart';

/// Encodes one tube's bottom-first contents as a single integer.
///
/// Digits are `colour + 1` in base [base], so 0 is never a digit and a shorter
/// tube can never collide with a longer one that shares its suffix — the length
/// is carried implicitly by the magnitude. An empty tube encodes to 0.
///
/// [base] must be at least `maxColour + 2`.
int tubeCode(List<ColorId> balls, int base) {
  var code = 0;
  for (final c in balls) {
    code = code * base + (c + 1);
  }
  return code;
}

/// The base required to encode colours up to [maxColour] with [tubeCode].
int baseForMaxColour(int maxColour) => maxColour + 2;

/// Canonical key for [board]: order-independent, collision-free.
///
/// Suitable for a visited set, a transposition table, or de-duplicating
/// generated levels. Keys are only comparable between boards of the same shape;
/// the capacity/base prefix makes a cross-shape comparison fail loudly rather
/// than collide silently.
String canonicalKey(Board board) {
  final base = baseForMaxColour(board.maxColour);
  final codes = [for (final t in board.tubes) tubeCode(t.balls, base)]..sort();
  return '${board.capacity}:$base:${_packCodes(codes)}';
}

/// Packs sorted tube codes into a compact string.
///
/// Fast path: when every code fits in a single UTF-16 code unit, the codes
/// become the string's code units directly — one allocation, no formatting.
/// Slow path: a marker plus a delimited join, so an unusually large
/// capacity/colour combination stays correct rather than silently truncating.
/// The two paths cannot collide because '#' is not a valid fast-path prefix
/// (code 35 would require a tube encoding to 35, which the marker precedes).
String _packCodes(List<int> sortedCodes) {
  for (final code in sortedCodes) {
    if (code > 0xFFFF) {
      return '#${sortedCodes.join(",")}';
    }
  }
  return String.fromCharCodes(sortedCodes);
}

/// Canonical key over raw bottom-first colour lists, for the solver's inner
/// loop and for the generator's duplicate check.
///
/// [base] is fixed for the duration of a single solve, so the prefix that
/// [canonicalKey] adds is redundant here and is omitted — this runs once per
/// expanded node, and the concatenation showed up in profiling.
String canonicalKeyOfLists(List<List<ColorId>> tubes, {required int base}) {
  final codes = [for (final t in tubes) tubeCode(t, base)]..sort();
  return _packCodes(codes);
}

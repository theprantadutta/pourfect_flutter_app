// Zen boards: made on the phone, proven solvable, never the same twice.

import 'package:flutter_test/flutter_test.dart';
import 'package:pourfect_flutter_app/engine/canonical.dart';
import 'package:pourfect_flutter_app/engine/solver.dart';
import 'package:pourfect_flutter_app/state/zen.dart';

void main() {
  test(
    'a calm session never repeats a board, and every one is solvable',
    () async {
      final keys = <String>{};
      for (var seed = 1; seed <= 12; seed++) {
        final level = await makeZenBoard(ZenPace.calm, seed);
        expect(level.board.colors.length, ZenPace.calm.colors);
        expect(const Solver().solve(level.board), isA<Solved>());
        expect(level.minMoves, greaterThan(0));
        keys.add(canonicalKey(level.board));
      }
      expect(keys, hasLength(12));
    },
  );

  test('a deep board has its eight colors', () async {
    final level = await makeZenBoard(ZenPace.deep, 99);
    expect(level.board.colors.length, ZenPace.deep.colors);
    // Never mistaken for a campaign level.
    expect(level.id, 0);
  }, timeout: const Timeout(Duration(minutes: 2)));
}

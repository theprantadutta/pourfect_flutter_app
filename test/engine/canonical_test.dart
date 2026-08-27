import 'dart:math';

import 'package:pourfect_flutter_app/engine/board.dart';
import 'package:pourfect_flutter_app/engine/canonical.dart';
import 'package:test/test.dart';

void main() {
  group('tubeCode', () {
    test('distinguishes an empty tube from any filled one', () {
      expect(tubeCode([], 4), 0);
      expect(tubeCode([0], 4), isNot(0));
    });

    test('is order-sensitive within a tube', () {
      expect(tubeCode([0, 1], 4), isNot(tubeCode([1, 0], 4)));
    });

    test(
      'never confuses a short tube with a longer one sharing its suffix',
      () {
        // The classic encoding bug: [0] and [0,0] both "end in 0". Digits are
        // colour+1 so 0 is never a digit and length rides in the magnitude.
        expect(tubeCode([0], 4), isNot(tubeCode([0, 0], 4)));
        expect(tubeCode([1], 4), isNot(tubeCode([0, 1], 4)));
        expect(tubeCode([], 4), isNot(tubeCode([0], 4)));
      },
    );

    test('is injective across every tube up to capacity 4', () {
      const colours = 5;
      const capacity = 4;
      final base = baseForMaxColour(colours - 1);
      final seen = <int, List<ColorId>>{};

      void walk(List<ColorId> prefix) {
        final code = tubeCode(prefix, base);
        final clash = seen[code];
        expect(
          clash,
          anyOf(isNull, equals(prefix)),
          reason: '$prefix and $clash both encode to $code',
        );
        seen[code] = List.of(prefix);
        if (prefix.length == capacity) return;
        for (var c = 0; c < colours; c++) {
          walk([...prefix, c]);
        }
      }

      walk([]);
      expect(seen.length, greaterThan(700));
    });
  });

  group('canonicalKey', () {
    test('ignores tube order — the whole point', () {
      final a = Board.fromLists([
        [0, 1],
        [1, 0],
        [],
      ], capacity: 2);
      final b = Board.fromLists([
        [],
        [1, 0],
        [0, 1],
      ], capacity: 2);

      expect(canonicalKey(a), canonicalKey(b));
      expect(a, isNot(b), reason: 'Board equality stays order-sensitive');
    });

    test('treats empty tubes as interchangeable', () {
      final a = Board.fromLists([
        [0, 0, 0, 0],
        [],
        [],
        [1, 1, 1, 1],
      ], capacity: 4);
      final b = Board.fromLists([
        [],
        [1, 1, 1, 1],
        [0, 0, 0, 0],
        [],
      ], capacity: 4);
      expect(canonicalKey(a), canonicalKey(b));
    });

    test('separates boards that differ in contents', () {
      final a = Board.fromLists([
        [0, 1],
        [1, 0],
      ], capacity: 2);
      final b = Board.fromLists([
        [0, 0],
        [1, 1],
      ], capacity: 2);
      expect(canonicalKey(a), isNot(canonicalKey(b)));
    });

    test('separates boards differing only in how balls are stacked', () {
      final a = Board.fromLists([
        [0, 0, 1],
        [1, 1, 0],
      ], capacity: 3);
      final b = Board.fromLists([
        [0, 1, 0],
        [1, 0, 1],
      ], capacity: 3);
      expect(canonicalKey(a), isNot(canonicalKey(b)));
    });

    test('is stable across separately-built equal boards', () {
      List<List<ColorId>> lists() => [
        [0, 1, 2],
        [2, 1, 0],
        [],
      ];
      expect(
        canonicalKey(Board.fromLists(lists(), capacity: 3)),
        canonicalKey(Board.fromLists(lists(), capacity: 3)),
      );
    });

    test('collapses permutations exactly — no over- and no under-merging', () {
      // Three distinct tube contents in every order: 3! = 6 boards, all of
      // which must land on ONE key. Under-merging would leave up to 6 keys and
      // gut the solver; over-merging would fuse genuinely different positions
      // and could make it claim an unsolvable board is solvable.
      final contents = [
        <ColorId>[0, 1],
        <ColorId>[1, 2],
        <ColorId>[2, 0],
      ];
      final keys = <String>{};
      for (final permutation in _permutations(contents)) {
        keys.add(canonicalKey(Board.fromLists(permutation, capacity: 2)));
      }
      expect(keys, hasLength(1));
    });

    test('distinct positions keep distinct keys under random sampling', () {
      final random = Random(3);
      final byKey = <String, List<List<ColorId>>>{};

      for (var i = 0; i < 3000; i++) {
        final board = _randomBoard(random, colours: 4, capacity: 4, empties: 2);
        final key = canonicalKey(board);
        final sorted = board.toLists()
          ..sort((a, b) => a.join(',').compareTo(b.join(',')));
        final existing = byKey[key];
        if (existing != null) {
          expect(
            sorted,
            existing,
            reason: 'two different positions collided on $key',
          );
        } else {
          byKey[key] = sorted;
        }
      }
      expect(byKey.length, greaterThan(100));
    });
  });

  group('canonicalKeyOfLists', () {
    test('agrees with canonicalKey on ordering behaviour', () {
      const base = 6;
      final a = canonicalKeyOfLists([
        [0, 1],
        [],
        [1, 0],
      ], base: base);
      final b = canonicalKeyOfLists([
        [1, 0],
        [0, 1],
        [],
      ], base: base);
      expect(a, b);
    });

    test('stays correct when tube codes exceed the fast-path width', () {
      // capacity 8 with 10 colours pushes codes past 0xFFFF, which is where a
      // naive code-unit packing would start truncating.
      final base = baseForMaxColour(9);
      final wide = List<ColorId>.generate(8, (i) => i % 10);
      expect(tubeCode(wide, base), greaterThan(0xFFFF));

      final a = canonicalKeyOfLists([wide, []], base: base);
      final b = canonicalKeyOfLists([[], wide], base: base);
      final c = canonicalKeyOfLists([wide.reversed.toList(), []], base: base);

      expect(a, b, reason: 'order still ignored on the wide path');
      expect(a, isNot(c), reason: 'contents still distinguished');
    });
  });
}

Iterable<List<T>> _permutations<T>(List<T> items) sync* {
  if (items.length <= 1) {
    yield List.of(items);
    return;
  }
  for (var i = 0; i < items.length; i++) {
    final rest = [...items]..removeAt(i);
    for (final tail in _permutations(rest)) {
      yield [items[i], ...tail];
    }
  }
}

Board _randomBoard(
  Random random, {
  required int colours,
  required int capacity,
  required int empties,
}) {
  final balls = <ColorId>[
    for (var c = 0; c < colours; c++) ...List<ColorId>.filled(capacity, c),
  ]..shuffle(random);

  return Board([
    for (var i = 0; i < colours; i++)
      Tube(balls.sublist(i * capacity, (i + 1) * capacity), capacity),
    for (var i = 0; i < empties; i++) Tube.empty(capacity),
  ]);
}

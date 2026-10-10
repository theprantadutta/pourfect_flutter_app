// Hard levels: the same levels on the phone and on the server, or the two
// disagree about points. The API's HardLevelTests pins this same list.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pourfect_flutter_app/engine/board.dart';
import 'package:pourfect_flutter_app/engine/hard_levels.dart';
import 'package:pourfect_flutter_app/engine/level.dart';
import 'package:pourfect_flutter_app/engine/level_set.dart';

/// Pinned identically in the API's tests/HardLevelTests.cs.
const _bundledHard = [
  10,
  19,
  29,
  39,
  49,
  60,
  69,
  79,
  89,
  99,
  109,
  120,
  129,
  139,
  150,
];

Level _level(int id, double difficulty) => Level(
  id: id,
  board: Board.fromLists([
    [0, 1],
    [1, 0],
    [],
  ], capacity: 2),
  minMoves: 3,
  difficultyScore: difficulty,
  forcedMoveRatio: 0,
);

void main() {
  test('the bundled campaign has the pinned hard levels', () {
    final set = LevelSetCodec.decode(
      File('assets/levels/levels.bin').readAsBytesSync(),
    );

    final hard = [
      for (final c in set.levels)
        if (c.level.isHard) c.id,
    ];

    expect(hard, _bundledHard);
  });

  test('ties go to the later level', () {
    expect(pickHardLevels([for (var id = 1; id <= 10; id++) _level(id, 20)]), {
      10,
    });
  });

  test('an unfinished block has no hard level', () {
    expect(
      pickHardLevels([
        for (var id = 151; id <= 157; id++) _level(id, id * 1.0),
      ]),
      isEmpty,
    );
  });

  test('a hard clear is worth half as much again', () {
    final normal = pointsFor(minMoves: 10, movesUsed: 10, elapsedSeconds: 80);
    final hard = pointsFor(
      minMoves: 10,
      movesUsed: 10,
      elapsedSeconds: 80,
      hard: true,
    );
    expect(hard, (normal * kHardPointsMultiplier).round());
  });

  test('a level scores with its own flag', () {
    final level = _level(10, 50);
    expect(
      level.copyWith(isHard: true).points(movesUsed: 3, elapsedSeconds: 10),
      greaterThan(level.points(movesUsed: 3, elapsedSeconds: 10)),
    );
  });

  test('the flag survives quantising, which generated levels go through', () {
    final level = _level(160, 50.123).copyWith(isHard: true);
    expect(LevelSetCodec.quantiseLevel(level).isHard, isTrue);
  });
}

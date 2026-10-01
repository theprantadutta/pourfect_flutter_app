// Tall tubes: five balls a tube, from the server's tall-tube worlds.
//
// The fixture is a whole world (levels 301-350) built by the backend's
// WorldBuilder, carrying the minMoves the C# solver proved and the nodes it
// needed. Two things have to hold on the PHONE's solver, and this is the only
// place both engines meet on these boards:
//
//  * it agrees on every optimum, or stars and the server's anti-cheat floor
//    disagree with what the player sees; and
//  * it resolves every board from the opening position inside kHintNodeCap,
//    or a player stuck on move one is told no hint is available. The server
//    rejects boards past half that cap, which this proves is enough margin.

import 'dart:convert';
import 'dart:io';

import 'package:pourfect_flutter_app/engine/board.dart';
import 'package:pourfect_flutter_app/engine/solver.dart';
import 'package:test/test.dart';

void main() {
  final fixture = jsonDecode(
    File('test/engine/fixtures/tall_world.json').readAsStringSync(),
  ) as Map<String, Object?>;
  final levels = (fixture['levels'] as List).cast<Map<String, Object?>>();

  Board boardOf(Map<String, Object?> level) => Board.fromLists([
    for (final tube in level['tubes'] as List)
      [for (final ball in tube as List) ball as int],
  ], capacity: level['capacity'] as int);

  test('the fixture is a whole tall-tube world', () {
    expect(levels, hasLength(50));
    expect(levels.first['id'], 301);
    expect(levels.every((l) => l['capacity'] == 5), isTrue);
  });

  test(
    'every level resolves for a hint from move one, at the server optimum',
    () {
      const solver = Solver.forHints();
      var worst = 0;
      for (final level in levels) {
        final outcome = solver.solve(boardOf(level));
        expect(
          outcome,
          isA<Solved>(),
          reason: 'level ${level['id']} gave up inside kHintNodeCap',
        );
        final solved = outcome as Solved;
        expect(
          solved.moveCount,
          level['min_moves'],
          reason: 'level ${level['id']}: the two solvers disagree on par',
        );
        if (solved.nodesExplored > worst) worst = solved.nodesExplored;
      }
      // Recorded rather than asserted tighter: the margin is the point.
      expect(worst, lessThan(kHintNodeCap));
      printOnFailure('worst opening solve: $worst nodes');
    },
  );
}

/// Prints the optimal solution for a campaign level, as tube indices.
///
/// Written to drive the real app over `adb` during on-device verification:
/// solving a board by hand through simulated taps is slow and error-prone, and
/// the events that matter most (`level_complete` above all) only fire when a
/// level is actually finished. This makes that repeatable.
///
///     dart run tool/solve_level.dart 1
///     dart run tool/solve_level.dart 1 --taps
///
/// `--taps` emits the move list as `from,to` pairs on one line, which is the
/// form the adb driver consumes.
library;

import 'dart:io';

import 'package:pourfect_flutter_app/engine/level_set.dart';
import 'package:pourfect_flutter_app/engine/solver.dart';

Future<void> main(List<String> args) async {
  if (args.isEmpty) {
    stderr.writeln('usage: dart run tool/solve_level.dart <levelId> [--taps]');
    exit(64);
  }

  final levelId = int.parse(args.first);
  final tapsOnly = args.contains('--taps');

  final bytes = await File('assets/levels/levels.bin').readAsBytes();
  final levelSet = LevelSetCodec.decode(bytes);

  final level = levelSet.byId(levelId);
  if (level == null) {
    stderr.writeln('no level $levelId in the campaign');
    exit(1);
  }

  const solver = Solver();
  final outcome = solver.solve(level.level.board);

  switch (outcome) {
    case Solved(:final moves):
      if (tapsOnly) {
        stdout.writeln(moves.map((m) => '${m.from},${m.to}').join(' '));
        return;
      }

      stdout.writeln('level $levelId — ${moves.length} moves '
          '(minMoves says ${level.level.minMoves})');
      for (var i = 0; i < moves.length; i++) {
        stdout.writeln('  ${i + 1}. tube ${moves[i].from} -> ${moves[i].to}');
      }

      // The solver is the source of both numbers, so a mismatch means the
      // asset and the engine have drifted apart — which would also mean the
      // star scale is being applied against the wrong optimum.
      if (moves.length != level.level.minMoves) {
        stderr.writeln('WARNING: solution length disagrees with minMoves');
        exit(2);
      }

    case Unsolvable():
      stderr.writeln('level $levelId is UNSOLVABLE — this should be impossible');
      exit(3);

    case SolveUnknown():
      stderr.writeln('level $levelId undecided within the node cap');
      exit(4);
  }
}

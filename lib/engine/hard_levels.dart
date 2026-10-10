/// Hard levels: the toughest level in every block of ten, worth 1.5× points.
///
/// Owner's call (2026-10-10): a LABEL on levels that already exist, never a
/// regenerated board. The rule mirrors the API's `HardLevels` exactly, because
/// the two must agree or the score on the phone and on the leaderboard differ:
///
///  * difficulty is compared in whole hundredths — the precision both the
///    level asset and the server's seed data hold it at;
///  * ties go to the higher level id;
///  * only a COMPLETE block of ten has a hard level, so a label never moves
///    onto a level somebody already cleared at normal points.
///
/// Generated levels arrive with the server's own `is_hard` flag; this rule is
/// for the bundled campaign. `test/engine/hard_levels_test.dart` pins its
/// answer, and the API pins the same list.
library;

import 'level.dart';

const int kHardBlockSize = 10;

/// What a hard level's points are multiplied by.
const double kHardPointsMultiplier = 1.5;

int difficultyHundredths(double difficulty) => (difficulty * 100).round();

/// The ids of the hard levels among [levels].
Set<int> pickHardLevels(Iterable<Level> levels) {
  final blocks = <int, List<Level>>{};
  for (final level in levels) {
    (blocks[(level.id - 1) ~/ kHardBlockSize] ??= []).add(level);
  }
  return {
    for (final block in blocks.values)
      if (block.length == kHardBlockSize)
        block.reduce((best, l) {
          final a = difficultyHundredths(best.difficultyScore);
          final b = difficultyHundredths(l.difficultyScore);
          return b > a || (b == a && l.id > best.id) ? l : best;
        }).id,
  };
}

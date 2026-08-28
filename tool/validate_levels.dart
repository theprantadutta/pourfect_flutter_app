// Validates the baked level content. Run in CI and before any release:
//
//   dart run tool/validate_levels.dart
//
// This is the last gate before content reaches a player, and it deliberately
// TRUSTS NOTHING the generator recorded. Every board is re-solved from scratch
// with a fresh solver and every stored number is re-derived. A generator bug
// that wrote a wrong `minMoves` would sail past any check that read the
// generator's own bookkeeping — and a wrong `minMoves` silently corrupts both
// the star rating and the server's leaderboard anti-cheat floor.
//
// Exits non-zero on any failure.

import 'dart:io';

import 'package:pourfect_flutter_app/engine/canonical.dart';
import 'package:pourfect_flutter_app/engine/level.dart';
import 'package:pourfect_flutter_app/engine/level_curve.dart';
import 'package:pourfect_flutter_app/engine/level_set.dart';
import 'package:pourfect_flutter_app/engine/rules.dart';
import 'package:pourfect_flutter_app/engine/solver.dart';

const _campaignAssetPath = 'assets/levels/levels.bin';

void main(List<String> args) {
  final report = _Report();
  const solver = Solver();

  // ---- campaign -----------------------------------------------------------
  final campaignFile = File(_campaignAssetPath);
  if (!campaignFile.existsSync()) {
    stderr.writeln(
      'missing $_campaignAssetPath — run tool/generate_levels.dart',
    );
    exit(1);
  }

  final bytes = campaignFile.readAsBytesSync();
  final levelSet = LevelSetCodec.decode(bytes);
  stdout.writeln(
    'Campaign: ${levelSet.length} levels, set version '
    '${levelSet.levelSetVersion}, ${bytes.length} bytes',
  );

  _checkCodecRoundTrip(bytes, levelSet, report);
  _checkIdsAreContiguous(levelSet, report);
  _checkBandShapes(levelSet, report);

  final campaignKeys = <String, int>{};
  for (final campaignLevel in levelSet.levels) {
    _checkLevelIsPlayable(campaignLevel.level, 'campaign', solver, report);

    final key = canonicalKey(campaignLevel.level.board);
    final clash = campaignKeys[key];
    if (clash != null) {
      report.fail(
        'levels $clash and ${campaignLevel.id} are the SAME board '
        '(canonically identical — a player would notice)',
      );
    }
    campaignKeys[key] = campaignLevel.id;
  }
  stdout.writeln('  re-solved all ${levelSet.length} campaign levels');

  _checkMonotonicWithinBands(levelSet, report);
  _checkBreathers(levelSet, report);
  _checkOnboardingRamp(levelSet, report);

  // ---- verdict ------------------------------------------------------------
  if (report.failures.isEmpty) {
    stdout.writeln('\nAll checks passed.');
    return;
  }

  stderr.writeln('\n${report.failures.length} validation failure(s):\n');
  for (final failure in report.failures) {
    stderr.writeln('  - $failure');
  }
  exit(1);
}

/// Re-solves [level] and confirms it is winnable, not pre-solved, not stuck,
/// and that its recorded `minMoves` is exactly right.
void _checkLevelIsPlayable(
  Level level,
  String kind,
  Solver solver,
  _Report report,
) {
  final board = level.board;

  if (board.isWon) {
    report.fail('$kind ${level.id} ships already solved');
    return;
  }
  if (isDead(board)) {
    report.fail('$kind ${level.id} starts with no legal move');
    return;
  }
  for (final tube in board.tubes) {
    if (tube.isComplete) {
      report.fail('$kind ${level.id} has a tube that starts finished');
      return;
    }
  }

  final outcome = solver.solve(board);
  switch (outcome) {
    case Unsolvable():
      report.fail(
        '$kind ${level.id} is UNSOLVABLE — this is the failure that must '
        'never reach a player',
      );
    case SolveUnknown():
      report.fail(
        '$kind ${level.id} could not be decided within the node cap; it is '
        'not proven solvable and must not ship',
      );
    case Solved(:final moves):
      if (moves.length != level.minMoves) {
        report.fail(
          '$kind ${level.id} records minMoves ${level.minMoves} but the '
          'optimal solution is ${moves.length} — star ratings and the server '
          'anti-cheat floor would both be wrong',
        );
      }
  }
}

/// The asset must survive a decode/encode cycle unchanged, or a rebuild from
/// the same seed could produce different bytes and break reproducibility.
void _checkCodecRoundTrip(List<int> bytes, LevelSet set, _Report report) {
  final reEncoded = LevelSetCodec.encode(set);
  if (reEncoded.length != bytes.length) {
    report.fail(
      'codec round-trip changed length: ${bytes.length} -> ${reEncoded.length}',
    );
    return;
  }
  for (var i = 0; i < bytes.length; i++) {
    if (bytes[i] != reEncoded[i]) {
      report.fail('codec round-trip differs at byte $i');
      return;
    }
  }
}

void _checkIdsAreContiguous(LevelSet set, _Report report) {
  if (set.length != kCampaignLength) {
    report.fail(
      'campaign holds ${set.length} levels, expected $kCampaignLength',
    );
  }
  for (var i = 0; i < set.length; i++) {
    if (set[i].id != i + 1) {
      report.fail('level at index $i has id ${set[i].id}, expected ${i + 1}');
      return;
    }
  }
}

/// Every level must match a shape its band actually declares — otherwise the
/// curve definition and the shipped content have quietly diverged.
void _checkBandShapes(LevelSet set, _Report report) {
  for (final campaignLevel in set.levels) {
    final level = campaignLevel.level;
    final expectedBand = bandIndexForLevel(level.id);

    if (campaignLevel.bandIndex != expectedBand) {
      report.fail(
        'level ${level.id} is tagged band ${campaignLevel.bandIndex} but falls '
        'in band $expectedBand',
      );
      continue;
    }
    if (campaignLevel.isBreather != isBreatherLevel(level.id)) {
      report.fail(
        'level ${level.id} breather flag disagrees with the curve definition',
      );
    }

    final band = kCampaignBands[expectedBand];
    final allowedShapes = campaignLevel.isBreather
        ? [(band.breatherSpec.colorCount, band.breatherSpec.emptyTubeCount)]
        : [for (final t in band.tiers) (t.colorCount, t.emptyTubeCount)];
    final matches = allowedShapes.any(
      (shape) =>
          shape.$1 == level.colorCount && shape.$2 == level.emptyTubeCount,
    );
    if (!matches) {
      report.fail(
        'level ${level.id} is ${level.colorCount}c/${level.emptyTubeCount}e, '
        'which band "${band.name}" does not declare',
      );
    }

    if (level.colorCount > kMaxColorsAllowed) {
      report.fail(
        'level ${level.id} uses ${level.colorCount} colors, above the '
        'accessibility cap of $kMaxColorsAllowed',
      );
    }
  }
}

/// Difficulty must never fall as a player advances, ignoring breathers — which
/// are the deliberate exception and are checked separately.
void _checkMonotonicWithinBands(LevelSet set, _Report report) {
  var previousId = 0;
  var previousScore = -1.0;

  for (final campaignLevel in set.levels) {
    if (campaignLevel.isBreather) continue;
    final score = campaignLevel.level.difficultyScore;
    if (score < previousScore) {
      report.fail(
        'difficulty falls from ${previousScore.toStringAsFixed(1)} at level '
        '$previousId to ${score.toStringAsFixed(1)} at level '
        '${campaignLevel.id}',
      );
    }
    previousScore = score;
    previousId = campaignLevel.id;
  }
}

/// Breathers must deliver real, bounded relief.
void _checkBreathers(LevelSet set, _Report report) {
  final assigned = {for (final l in set.levels) l.id: l};
  var found = 0;

  for (final campaignLevel in set.levels) {
    if (!campaignLevel.isBreather) continue;
    found++;

    final (floor, ceiling) = breatherWindowFor(campaignLevel.id, assigned);
    final score = campaignLevel.level.difficultyScore;

    if (score > ceiling) {
      report.fail(
        'breather ${campaignLevel.id} scores ${score.toStringAsFixed(1)}, above '
        'its ceiling of ${ceiling.toStringAsFixed(1)} — it is not actually a '
        'breather',
      );
    }
    if (score < floor) {
      report.fail(
        'breather ${campaignLevel.id} scores ${score.toStringAsFixed(1)}, below '
        'its floor of ${floor.toStringAsFixed(1)} — that is a hole in the '
        'curve, not relief',
      );
    }
  }

  if (found == 0) {
    report.fail('no breather levels found; the curve has no relief points');
  } else {
    stdout.writeln('  $found breather levels, all within their windows');
  }
}

/// The onboarding zone must not contain a difficulty cliff.
///
/// This is the rail on the failure the first bake shipped: levels 1-15 climbing
/// at 2.8 points/level while the rest of the game climbed at 0.17-0.4. Levels
/// 1-15 are where D1 retention is decided, and a player who bounces at level 9
/// never reaches the part of the curve built for them.
void _checkOnboardingRamp(LevelSet set, _Report report) {
  final worst = worstOnboardingJump(set.levels);
  if (worst != null) {
    report.fail(
      'onboarding difficulty jumps ${worst.jump.toStringAsFixed(1)} points '
      'from level ${worst.fromLevel} to ${worst.toLevel}, over the '
      '$kOnboardingMaxJump limit — this is the cliff that costs D1',
    );
    return;
  }

  final opening = set.levels.take(8).map((l) => l.level.difficultyScore);
  stdout.writeln(
    '  onboarding ramp clean (levels 1-8: '
    '${opening.first.toStringAsFixed(1)} - ${opening.last.toStringAsFixed(1)})',
  );
}

/// Mirror of `kMaxColors`, restated here so the validator fails loudly if the
/// engine constant is raised without re-running the color-blindness harness.
const int kMaxColorsAllowed = 10;

final class _Report {
  final List<String> failures = [];

  void fail(String message) => failures.add(message);
}

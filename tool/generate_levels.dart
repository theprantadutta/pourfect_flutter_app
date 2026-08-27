// Bakes the shipped level content. BUILD TIME ONLY — nothing here runs on a
// device, and a player never waits on a generator.
//
//   dart run tool/generate_levels.dart
//   dart run tool/generate_levels.dart --seed 123 --campaign-only
//
// Outputs:
//   assets/levels/levels.bin        the campaign, bundled into the APK
//   generated/daily_pool.json       365 dailies, seeds the BACKEND pool
//   generated/level_curve.md        human-readable curve, for eyeballing
//   generated/level_curve.csv       same data, for plotting
//
// DETERMINISM IS THE POINT. With default flags this reproduces `levels.bin`
// byte-for-byte, every time, on any machine. `levels.bin` is committed, and
// `test/engine/level_asset_test.dart` fails if a rebuild would change it.
// Player progress is keyed on level id and `minMoves` feeds the server's
// anti-cheat floor, so a silent reshuffle would repoint every saved star at a
// board the player never saw.
//
// The daily pool is emitted here but CONSUMED BY THE BACKEND: copy
// generated/daily_pool.json into the API repo's seed data. It carries
// `min_moves` per level, which is what the leaderboard's anti-cheat check
// compares a submitted move count against.

import 'dart:convert';
import 'dart:io';

import 'package:pourfect_flutter_app/engine/generator.dart';
import 'package:pourfect_flutter_app/engine/level.dart';
import 'package:pourfect_flutter_app/engine/level_curve.dart';
import 'package:pourfect_flutter_app/engine/level_set.dart';

const _campaignAssetPath = 'assets/levels/levels.bin';
const _dailyPoolPath = 'generated/daily_pool.json';
const _curveMarkdownPath = 'generated/level_curve.md';
const _curveCsvPath = 'generated/level_curve.csv';

void main(List<String> args) {
  final options = _Options.parse(args);
  if (options.help) {
    stdout.writeln(_usage);
    return;
  }

  final stopwatch = Stopwatch()..start();

  stdout.writeln('Building campaign (seed ${options.seed})...');
  final campaign = buildCampaign(
    seed: options.seed,
    onProgress: options.verbose ? (m) => stdout.writeln('  $m') : null,
  );
  stdout.writeln('  ${campaign.levelSet.length} levels, ${campaign.stats}');

  _writeBytes(_campaignAssetPath, LevelSetCodec.encode(campaign.levelSet));
  _writeString(_curveMarkdownPath, _curveMarkdown(campaign));
  _writeString(_curveCsvPath, _curveCsv(campaign));

  if (!options.campaignOnly) {
    stdout.writeln('Building daily pool (seed ${options.dailySeed})...');
    final dailyStats = GenerationStats();
    final daily = buildDailyPool(
      seed: options.dailySeed,
      excludeKeys: campaign.canonicalKeys,
      stats: dailyStats,
      onProgress: (m) => stdout.writeln('  $m'),
    );
    stdout.writeln('  ${daily.length} dailies, $dailyStats');
    _writeString(_dailyPoolPath, _dailyJson(daily, options.dailySeed));
  }

  stopwatch.stop();
  stdout.writeln(
    'Done in ${(stopwatch.elapsedMilliseconds / 1000).toStringAsFixed(1)}s',
  );
}

/// The daily pool, shaped for the backend seeder.
///
/// `min_moves` on every entry is load-bearing: it is the floor the leaderboard
/// rejects impossible submissions against, and the server must never run a
/// solver at request time to recover it.
String _dailyJson(List<Level> levels, int seed) {
  final payload = {
    'schema_version': 1,
    'seed': seed,
    'generated_level_count': levels.length,
    'levels': [for (final level in levels) level.toJson()],
  };
  return '${const JsonEncoder.withIndent('  ').convert(payload)}\n';
}

String _curveMarkdown(CampaignBuildResult campaign) {
  final buffer = StringBuffer()
    ..writeln('# Pourfect level curve')
    ..writeln()
    ..writeln(
      'Level set version ${campaign.levelSet.levelSetVersion}, '
      '${campaign.levelSet.length} levels.',
    )
    ..writeln()
    ..writeln('`difficulty` is the calibrated 0-100 score. `forced` is the')
    ..writeln('fraction of states on the optimal path with only one meaningful')
    ..writeln('move; `branch` is the mean number of distinct options. Breather')
    ..writeln('levels are marked and must sit at least 25% below the running')
    ..writeln('average of the five levels before them.')
    ..writeln();

  for (var b = 0; b < kCampaignBands.length; b++) {
    final band = kCampaignBands[b];
    final levels = campaign.levelSet.levels
        .where((l) => l.bandIndex == b)
        .toList();
    final scores = levels.map((l) => l.level.difficultyScore).toList();

    buffer
      ..writeln(
        '## Band $b — ${band.name} '
        '(levels ${band.firstLevel}-${band.lastLevel})',
      )
      ..writeln()
      ..writeln(
        'Difficulty ${scores.first.toStringAsFixed(1)} → '
        '${scores.last.toStringAsFixed(1)}. Tiers: '
        '${band.tiers.map((t) => "${t.colorCount}c/${t.emptyTubeCount}e").join(", ")}.',
      )
      ..writeln()
      ..writeln(
        '| level | colours | empty | minMoves | forced | branch | difficulty | |',
      )
      ..writeln(
        '|------:|--------:|------:|---------:|-------:|-------:|-----------:|:--|',
      );

    for (final campaignLevel in levels) {
      final level = campaignLevel.level;
      final m = campaign.metrics[level.id]!;
      buffer.writeln(
        '| ${level.id} '
        '| ${level.colorCount} '
        '| ${level.emptyTubeCount} '
        '| ${level.minMoves} '
        '| ${level.forcedMoveRatio.toStringAsFixed(2)} '
        '| ${m.meanBranching.toStringAsFixed(1)} '
        '| ${level.difficultyScore.toStringAsFixed(1)} '
        '| ${campaignLevel.isBreather ? "breather" : ""} |',
      );
    }
    buffer.writeln();
  }

  return buffer.toString();
}

String _curveCsv(CampaignBuildResult campaign) {
  final buffer = StringBuffer()
    ..writeln(
      'level,band,band_name,colors,empty_tubes,min_moves,'
      'forced_move_ratio,mean_branching,mean_scatter,difficulty_score,'
      'is_breather',
    );

  for (final campaignLevel in campaign.levelSet.levels) {
    final level = campaignLevel.level;
    final m = campaign.metrics[level.id]!;
    buffer.writeln(
      '${level.id},'
      '${campaignLevel.bandIndex},'
      '${kCampaignBands[campaignLevel.bandIndex].name},'
      '${level.colorCount},'
      '${level.emptyTubeCount},'
      '${level.minMoves},'
      '${level.forcedMoveRatio.toStringAsFixed(4)},'
      '${m.meanBranching.toStringAsFixed(3)},'
      '${m.meanScatter.toStringAsFixed(3)},'
      '${level.difficultyScore.toStringAsFixed(2)},'
      '${campaignLevel.isBreather}',
    );
  }

  return buffer.toString();
}

void _writeBytes(String path, List<int> bytes) {
  final file = File(path);
  file.parent.createSync(recursive: true);
  file.writeAsBytesSync(bytes);
  stdout.writeln('  wrote $path (${bytes.length} bytes)');
}

void _writeString(String path, String contents) {
  final file = File(path);
  file.parent.createSync(recursive: true);
  // Explicit LF: the asset and the reports must be identical on every platform,
  // and Windows line endings would make the reports churn in diffs.
  file.writeAsStringSync(contents.replaceAll('\r\n', '\n'));
  stdout.writeln('  wrote $path');
}

const _usage =
    '''
Bakes Pourfect's level content.

  --seed <int>       campaign seed (default $kDefaultCampaignSeed)
  --daily-seed <int> daily pool seed (default $kDefaultDailySeed)
  --campaign-only    skip the daily pool
  --verbose          log every tier and breather as it is built
  --help

Default flags reproduce the committed assets/levels/levels.bin byte-for-byte.
''';

final class _Options {
  final int seed;
  final int dailySeed;
  final bool campaignOnly;
  final bool verbose;
  final bool help;

  const _Options({
    required this.seed,
    required this.dailySeed,
    required this.campaignOnly,
    required this.verbose,
    required this.help,
  });

  static _Options parse(List<String> args) {
    var seed = kDefaultCampaignSeed;
    var dailySeed = kDefaultDailySeed;
    var campaignOnly = false;
    var verbose = false;
    var help = false;

    for (var i = 0; i < args.length; i++) {
      switch (args[i]) {
        case '--seed':
          seed = int.parse(args[++i]);
        case '--daily-seed':
          dailySeed = int.parse(args[++i]);
        case '--campaign-only':
          campaignOnly = true;
        case '--verbose':
          verbose = true;
        case '--help' || '-h':
          help = true;
        default:
          throw ArgumentError('unknown flag: ${args[i]}');
      }
    }

    return _Options(
      seed: seed,
      dailySeed: dailySeed,
      campaignOnly: campaignOnly,
      verbose: verbose,
      help: help,
    );
  }
}

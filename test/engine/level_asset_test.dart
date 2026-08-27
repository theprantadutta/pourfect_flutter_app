import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:pourfect_flutter_app/engine/board.dart';
import 'package:pourfect_flutter_app/engine/canonical.dart';
import 'package:pourfect_flutter_app/engine/level.dart';
import 'package:pourfect_flutter_app/engine/level_curve.dart';
import 'package:pourfect_flutter_app/engine/level_set.dart';
import 'package:test/test.dart';

const _campaignAssetPath = 'assets/levels/levels.bin';
const _dailyPoolPath = 'generated/daily_pool.json';

LevelSet _loadCampaign() =>
    LevelSetCodec.decode(File(_campaignAssetPath).readAsBytesSync());

void main() {
  group('binary codec', () {
    LevelSet sampleSet() => LevelSet(
      levelSetVersion: 7,
      levels: [
        CampaignLevel(
          level: Level(
            id: 1,
            board: Board.fromLists([
              [0, 1, 1, 0],
              [1, 0, 0, 1],
              [],
            ], capacity: 4),
            minMoves: 12,
            difficultyScore: 43.21,
            forcedMoveRatio: 0.3333,
          ),
          bandIndex: 2,
          isBreather: true,
        ),
        CampaignLevel(
          level: Level(
            id: 2,
            board: Board.fromLists([
              [3, 3, 2],
              [2, 2, 3],
              [],
            ], capacity: 3),
            minMoves: 5,
            difficultyScore: 90.0,
            forcedMoveRatio: 1.0,
          ),
          bandIndex: 0,
          isBreather: false,
        ),
      ],
    );

    test('round-trips a level set', () {
      final original = sampleSet();
      final restored = LevelSetCodec.decode(LevelSetCodec.encode(original));

      expect(restored.levelSetVersion, 7);
      expect(restored.length, 2);

      for (var i = 0; i < original.length; i++) {
        expect(restored[i].id, original[i].id);
        expect(restored[i].bandIndex, original[i].bandIndex);
        expect(restored[i].isBreather, original[i].isBreather);
        expect(restored[i].level.board, original[i].level.board);
        expect(restored[i].level.minMoves, original[i].level.minMoves);
        expect(
          restored[i].level.difficultyScore,
          closeTo(original[i].level.difficultyScore, 0.01),
        );
        expect(
          restored[i].level.forcedMoveRatio,
          closeTo(original[i].level.forcedMoveRatio, 0.0001),
        );
      }
    });

    test('re-encoding a decoded set is byte-identical', () {
      // The property the reproducibility guarantee rests on: if this drifted,
      // a rebuild could differ from the committed asset in the last bit.
      final once = LevelSetCodec.encode(sampleSet());
      final twice = LevelSetCodec.encode(LevelSetCodec.decode(once));
      expect(twice, once);
    });

    test('quantiseLevel makes encoding lossless', () {
      final level = LevelSetCodec.quantiseLevel(
        Level(
          id: 1,
          board: Board.fromLists([
            [0, 0],
            [0, 0],
          ], capacity: 2),
          minMoves: 3,
          difficultyScore: 12.3456789,
          forcedMoveRatio: 0.987654321,
        ),
      );

      final set = LevelSet(
        levelSetVersion: 1,
        levels: [CampaignLevel(level: level, bandIndex: 0, isBreather: false)],
      );
      final restored = LevelSetCodec.decode(LevelSetCodec.encode(set));

      expect(restored[0].level.difficultyScore, level.difficultyScore);
      expect(restored[0].level.forcedMoveRatio, level.forcedMoveRatio);
    });

    test('rejects a file that is not a level set', () {
      final junk = Uint8List.fromList([1, 2, 3, 4, 5, 6, 7, 8, 9]);
      expect(() => LevelSetCodec.decode(junk), throwsFormatException);
    });

    test('rejects an unknown format version', () {
      final bytes = LevelSetCodec.encode(sampleSet());
      bytes[4] = 99;
      expect(() => LevelSetCodec.decode(bytes), throwsFormatException);
    });
  });

  group('shipped campaign asset', () {
    test('exists and is committed', () {
      expect(
        File(_campaignAssetPath).existsSync(),
        isTrue,
        reason: 'run `dart run tool/generate_levels.dart`',
      );
    });

    test('holds the full campaign at the expected version', () {
      final set = _loadCampaign();
      expect(set.length, kCampaignLength);
      expect(set.levelSetVersion, kLevelSetVersion);
    });

    test('carries a level set version at all', () {
      // Without this field a level can never be safely changed after launch:
      // saved progress is keyed on level id, so a content edit would repoint
      // every stored star at a board the player never saw. It cannot be
      // retrofitted, which is why it ships in v1 despite having no consumer
      // yet.
      expect(_loadCampaign().levelSetVersion, greaterThan(0));
    });

    test('level ids are 1..150 with no gaps', () {
      final set = _loadCampaign();
      expect(
        set.levels.map((l) => l.id).toList(),
        List.generate(kCampaignLength, (i) => i + 1),
      );
    });

    test('never exceeds the accessibility colour cap', () {
      for (final campaignLevel in _loadCampaign().levels) {
        expect(
          campaignLevel.level.colorCount,
          lessThanOrEqualTo(10),
          reason: 'level ${campaignLevel.id} breaks the 10-colour cap',
        );
      }
    });

    test('no two levels are the same board', () {
      final seen = <String, int>{};
      for (final campaignLevel in _loadCampaign().levels) {
        final key = canonicalKey(campaignLevel.level.board);
        expect(
          seen[key],
          isNull,
          reason:
              'levels ${seen[key]} and ${campaignLevel.id} are canonically '
              'identical',
        );
        seen[key] = campaignLevel.id;
      }
    });

    test('difficulty never falls, ignoring breathers', () {
      var previous = -1.0;
      for (final campaignLevel in _loadCampaign().levels) {
        if (campaignLevel.isBreather) continue;
        expect(
          campaignLevel.level.difficultyScore,
          greaterThanOrEqualTo(previous),
          reason: 'difficulty dips at level ${campaignLevel.id}',
        );
        previous = campaignLevel.level.difficultyScore;
      }
    });

    test('every breather delivers real, bounded relief', () {
      final set = _loadCampaign();
      final assigned = {for (final l in set.levels) l.id: l};
      var checked = 0;

      for (final campaignLevel in set.levels) {
        if (!campaignLevel.isBreather) continue;
        checked++;

        final (floor, ceiling) = breatherWindowFor(campaignLevel.id, assigned);
        final score = campaignLevel.level.difficultyScore;

        expect(
          score,
          lessThanOrEqualTo(ceiling),
          reason: 'breather ${campaignLevel.id} is not actually easier',
        );
        expect(
          score,
          greaterThanOrEqualTo(floor),
          reason:
              'breather ${campaignLevel.id} is a hole in the curve, not relief',
        );
      }

      expect(checked, greaterThan(5));
    });

    test('the onboarding ramp has no cliff', () {
      // The rail on the failure the first bake shipped: levels 1-15 climbing at
      // 2.8 points/level while the rest of the game climbed at 0.17-0.4. The
      // tutorial was the harshest gradient in the entire campaign, which is
      // exactly backwards — levels 1-15 are where D1 is won or lost.
      final worst = worstOnboardingJump(_loadCampaign().levels);
      expect(
        worst,
        isNull,
        reason: worst == null
            ? ''
            : 'difficulty jumps ${worst.jump.toStringAsFixed(1)} points from '
                  'level ${worst.fromLevel} to ${worst.toLevel}',
      );
    });

    test('the first eight levels are near-flat and gentle', () {
      // A player here is learning that a tap pours, that the whole run travels,
      // and that undo is free. They are not being tested, and should find it
      // very hard to fail.
      final opening = _loadCampaign().levels.take(8).toList();
      for (final level in opening) {
        expect(
          level.level.difficultyScore,
          inInclusiveRange(15, 32),
          reason: 'level ${level.id} is outside the tutorial window',
        );
        expect(level.level.colorCount, lessThanOrEqualTo(4));
      }
      expect(
        opening.last.level.difficultyScore -
            opening.first.level.difficultyScore,
        lessThan(15),
        reason: 'levels 1-8 should be near-flat, not a ramp',
      );
    });

    test('bands hand off without a step', () {
      // Band two should continue band one's line rather than stepping over it.
      final set = _loadCampaign();
      for (final band in kCampaignBands.skip(1)) {
        final last = set.byId(band.firstLevel - 1)!;
        final first = set.byId(band.firstLevel)!;
        if (last.isBreather) continue;
        expect(
          first.level.difficultyScore - last.level.difficultyScore,
          lessThan(10),
          reason:
              'band "${band.name}" opens ${(first.level.difficultyScore - last.level.difficultyScore).toStringAsFixed(1)} '
              'points above the level before it',
        );
      }
    });

    test('breather flags match the curve definition', () {
      for (final campaignLevel in _loadCampaign().levels) {
        expect(
          campaignLevel.isBreather,
          isBreatherLevel(campaignLevel.id),
          reason: 'level ${campaignLevel.id} breather flag is stale',
        );
      }
    });
  });

  group('daily pool asset', () {
    List<Level> loadDaily() {
      final payload = jsonDecode(
        File(_dailyPoolPath).readAsStringSync(),
      ) as Map<String, Object?>;
      return [
        for (final raw in payload['levels']! as List)
          Level.fromJson(raw as Map<String, Object?>),
      ];
    }

    test('holds a full year', () {
      expect(loadDaily().length, kDailyPoolSize);
    });

    test('every entry carries min_moves for the anti-cheat floor', () {
      // The server rejects submissions below this. A zero or missing value
      // would disable the check silently rather than loudly.
      for (final level in loadDaily()) {
        expect(level.minMoves, greaterThan(0));
      }
    });

    test('is disjoint from the campaign', () {
      // Otherwise a player is handed a daily they already solved, which reads
      // as a bug and wastes the one shot a daily gets.
      final campaignKeys = {
        for (final l in _loadCampaign().levels) canonicalKey(l.level.board),
      };
      for (final level in loadDaily()) {
        expect(
          campaignKeys.contains(canonicalKey(level.board)),
          isFalse,
          reason: 'daily ${level.id} duplicates a campaign level',
        );
      }
    });

    test('has no internal duplicates', () {
      final keys = loadDaily().map((l) => canonicalKey(l.board)).toSet();
      expect(keys, hasLength(kDailyPoolSize));
    });
  });

  group('reproducibility', () {
    test('rebuilding from the default seed reproduces levels.bin byte-for-byte', () {
      // The guarantee that makes the committed asset trustworthy. Player
      // progress is keyed on level id and `minMoves` feeds the server's
      // anti-cheat floor, so a rebuild that silently reshuffled levels would
      // repoint every saved star at a different board and start rejecting
      // legitimate leaderboard submissions.
      //
      // Slow (it regenerates all 150 levels) and worth every second: this is
      // the only check that would catch an accidental change to a seed, a
      // band definition, a difficulty weight, or the codec.
      final committed = File(_campaignAssetPath).readAsBytesSync();
      final rebuilt = LevelSetCodec.encode(
        buildCampaign(seed: kDefaultCampaignSeed).levelSet,
      );

      expect(
        rebuilt.length,
        committed.length,
        reason:
            'rebuild produced ${rebuilt.length} bytes vs ${committed.length} '
            'committed — regenerate with tool/generate_levels.dart and commit '
            'the result, or revert whatever changed the curve',
      );

      for (var i = 0; i < committed.length; i++) {
        if (rebuilt[i] != committed[i]) {
          fail(
            'rebuild differs from the committed asset at byte $i. Something '
            'that feeds generation changed (seed, band definition, '
            'difficulty weights, solver ordering, or the codec). If the '
            'change was intended, bump kLevelSetVersion, regenerate, and '
            'commit.',
          );
        }
      }
    }, timeout: const Timeout(Duration(minutes: 20)));
  });
}

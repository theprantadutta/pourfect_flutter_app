import 'package:pourfect_flutter_app/engine/difficulty.dart';
import 'package:pourfect_flutter_app/engine/level_curve.dart';
import 'package:test/test.dart';

void main() {
  group('band coverage', () {
    test('bands tile levels 1..150 with no gaps or overlaps', () {
      var expected = 1;
      for (final band in kCampaignBands) {
        expect(
          band.firstLevel,
          expected,
          reason: 'band "${band.name}" does not start where the last ended',
        );
        expect(band.lastLevel, greaterThanOrEqualTo(band.firstLevel));
        expected = band.lastLevel + 1;
      }
      expect(expected - 1, kCampaignLength);
    });

    test('every level resolves to exactly one band', () {
      for (var id = 1; id <= kCampaignLength; id++) {
        expect(bandForLevel(id), isNotNull, reason: 'level $id has no band');
        expect(
          bandIndexForLevel(id),
          inInclusiveRange(0, kCampaignBands.length - 1),
        );
      }
    });

    test('levels outside the campaign have no band', () {
      expect(bandForLevel(0), isNull);
      expect(bandForLevel(kCampaignLength + 1), isNull);
      expect(() => bandIndexForLevel(0), throwsArgumentError);
    });

    test('no band or breather spec exceeds the colour cap', () {
      for (final band in kCampaignBands) {
        for (final tier in band.tiers) {
          expect(
            tier.colorCount,
            lessThanOrEqualTo(kMaxColours),
            reason: 'band "${band.name}" declares ${tier.colorCount} colours',
          );
        }
        expect(band.breatherSpec.colorCount, lessThanOrEqualTo(kMaxColours));
      }
    });

    test('colour counts never decrease from band to band', () {
      var previousMax = 0;
      for (final band in kCampaignBands) {
        final counts = band.tiers.map((t) => t.colorCount).toList();
        expect(
          counts,
          orderedEquals(counts.toList()..sort()),
          reason: 'band "${band.name}" tiers are not in ascending colour order',
        );
        expect(counts.first, greaterThanOrEqualTo(previousMax));
        previousMax = counts.last;
      }
    });

    test('a breather is always a smaller board than its band', () {
      // Relief has to be visible, not just a lower score.
      for (final band in kCampaignBands.skip(1)) {
        expect(
          band.breatherSpec.colorCount,
          lessThan(band.tiers.last.colorCount),
          reason: 'band "${band.name}" breather is not a smaller board',
        );
      }
    });
  });

  group('breather placement', () {
    test('falls on every tenth level', () {
      for (var id = 1; id <= kCampaignLength; id++) {
        if (id % 10 != 0) {
          expect(isBreatherLevel(id), isFalse, reason: 'level $id');
        }
      }
    });

    test('never lands in the tutorial band', () {
      // The opening band is already the gentlest stretch in the game; relieving
      // it would relieve nothing.
      final tutorial = kCampaignBands.first;
      for (var id = tutorial.firstLevel; id <= tutorial.lastLevel; id++) {
        expect(isBreatherLevel(id), isFalse, reason: 'level $id');
      }
    });

    test('never lands on the last level of a band', () {
      // A band should hand off at its peak. Ending easy and opening the next
      // band several colours higher is the exact cliff breathers exist to
      // prevent.
      for (final band in kCampaignBands) {
        expect(
          isBreatherLevel(band.lastLevel),
          isFalse,
          reason: 'band "${band.name}" ends on a breather',
        );
      }
    });

    test('never lands on the final level of the campaign', () {
      expect(isBreatherLevel(kCampaignLength), isFalse);
    });

    test('produces a usable number of breathers', () {
      final count = [
        for (var id = 1; id <= kCampaignLength; id++)
          if (isBreatherLevel(id)) id,
      ].length;
      expect(count, greaterThanOrEqualTo(8));
    });

    test('breathers are never adjacent', () {
      for (var id = 2; id <= kCampaignLength; id++) {
        if (isBreatherLevel(id) && isBreatherLevel(id - 1)) {
          fail('levels ${id - 1} and $id are both breathers');
        }
      }
    });
  });

  group('breather window', () {
    test('is empty-safe at the very start of the campaign', () {
      final (floor, ceiling) = breatherWindowFor(1, {});
      expect(floor, 0);
      expect(ceiling, double.infinity);
    });

    test('demands at least the configured relief', () {
      expect(kBreatherReliefFactor, lessThanOrEqualTo(0.75));
      expect(
        kBreatherFloorFactor,
        lessThan(kBreatherReliefFactor),
        reason: 'the floor must sit below the ceiling or no level can qualify',
      );
    });
  });

  group('daily pool configuration', () {
    test('draws from mid-campaign shapes, not the campaign peak', () {
      // A daily is one-shot; abandoning it costs more engagement than
      // abandoning a campaign level the player can return to.
      final hardestCampaignTier = kCampaignBands.last.tiers.last;
      for (final spec in kDailySpecs) {
        expect(
          spec.colorCount,
          lessThan(hardestCampaignTier.colorCount),
          reason: 'daily spec $spec is as hard as the campaign peak',
        );
        expect(
          spec.emptyTubeCount,
          greaterThanOrEqualTo(2),
          reason: 'dailies should not use the punishing single-empty layout',
        );
      }
    });

    test('has a sane difficulty window', () {
      expect(kDailyMinScore, lessThan(kDailyMaxScore));
      expect(kDailyMinScore, greaterThanOrEqualTo(0));
      expect(kDailyMaxScore, lessThanOrEqualTo(100));
    });

    test('covers a full year', () {
      expect(kDailyPoolSize, greaterThanOrEqualTo(365));
    });
  });

  group('calibration', () {
    test('maps the measured raw range onto 0-100', () {
      expect(kRawScoreFloor, lessThan(kRawScoreCeiling));

      DifficultyMetrics metrics(double forced, int colours, int empty) =>
          DifficultyMetrics(
            minMoves: colours * 3,
            colorCount: colours,
            capacity: 4,
            emptyTubeCount: empty,
            forcedMoveRatio: forced,
            meanBranching: 4,
            meanScatter: 2.5,
            maxScatter: 3,
          );

      // Calibration is affine and must therefore preserve every ordering the
      // raw blend produced.
      final a = metrics(0.1, 4, 2);
      final b = metrics(0.1, 8, 2);
      final c = metrics(0.1, 10, 1);

      expect(rawDifficultyScore(a), lessThan(rawDifficultyScore(b)));
      expect(difficultyScore(a), lessThan(difficultyScore(b)));
      expect(rawDifficultyScore(b), lessThan(rawDifficultyScore(c)));
      expect(difficultyScore(b), lessThan(difficultyScore(c)));
    });

    test('clamps rather than escaping 0-100', () {
      final absurd = DifficultyMetrics(
        minMoves: 1000,
        colorCount: 10,
        capacity: 4,
        emptyTubeCount: 1,
        forcedMoveRatio: 0,
        meanBranching: 40,
        meanScatter: 4,
        maxScatter: 4,
      );
      expect(difficultyScore(absurd), inInclusiveRange(0.0, 100.0));
    });
  });
}

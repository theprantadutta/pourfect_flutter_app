import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pourfect_flutter_app/engine/board.dart';
import 'package:pourfect_flutter_app/engine/level.dart';
import 'package:pourfect_flutter_app/state/level_repository.dart';
import 'package:pourfect_flutter_app/state/progress_repository.dart';
import 'package:pourfect_flutter_app/ui/widgets/win_profile.dart';

Level levelWith({required int id, required int minMoves}) => Level(
  id: id,
  board: Board.fromLists([
    [0, 0, 0],
    [1, 1, 1, 1],
    [0],
  ], capacity: 4),
  minMoves: minMoves,
  difficultyScore: 30,
  forcedMoveRatio: 1,
);

void main() {
  // Progress persists through SharedPreferences, which is a platform channel.
  // Mocking it keeps these tests on the real repository path rather than
  // stubbing the thing under test.
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('LevelProgress merge', () {
    const existing = LevelProgress(
      levelId: 4,
      levelSetVersion: 1,
      stars: 3,
      bestMoves: 9,
    );

    test('a worse replay never takes a star away', () {
      // The bug this rule prevents is "the game deleted my progress", which is
      // both a support burden and a one-star review.
      final merged = existing.mergedWith(stars: 1, moves: 20);
      expect(merged.stars, 3);
      expect(merged.bestMoves, 9);
    });

    test('a better replay improves both independently', () {
      final merged = existing.mergedWith(stars: 3, moves: 7);
      expect(merged.bestMoves, 7);
      expect(merged.stars, 3);
    });

    test('is order-independent', () {
      final a = existing
          .mergedWith(stars: 1, moves: 7)
          .mergedWith(stars: 2, moves: 12);
      final b = existing
          .mergedWith(stars: 2, moves: 12)
          .mergedWith(stars: 1, moves: 7);
      expect(a.stars, b.stars);
      expect(a.bestMoves, b.bestMoves);
    });
  });

  group('time and points merge like every other axis', () {
    const cleared = LevelProgress(
      levelId: 4,
      levelSetVersion: 1,
      stars: 3,
      bestMoves: 9,
      bestTimeSeconds: 120,
      bestPoints: 1500,
    );

    test('a slower replay never overwrites a faster time', () {
      final merged = cleared.mergedWith(
        stars: 3,
        moves: 9,
        timeSeconds: 400,
        points: 900,
      );
      expect(merged.bestTimeSeconds, 120);
      expect(merged.bestPoints, 1500);
    });

    test('a faster replay wins', () {
      final merged = cleared.mergedWith(
        stars: 3,
        moves: 9,
        timeSeconds: 60,
        points: 1800,
      );
      expect(merged.bestTimeSeconds, 60);
      expect(merged.bestPoints, 1800);
    });

    test('an UNKNOWN time is not the fastest time', () {
      // Zero means "cleared before the clock shipped", not "solved instantly".
      // Treating it as a number would hand every pre-clock level a 0:00
      // personal best that nothing could ever beat.
      final merged = cleared.mergedWith(stars: 3, moves: 9);
      expect(merged.bestTimeSeconds, 120);
    });

    test('a first real time replaces an unknown one', () {
      const preClock = LevelProgress(
        levelId: 4,
        levelSetVersion: 1,
        stars: 3,
        bestMoves: 9,
      );
      expect(preClock.hasTime, isFalse);

      final merged = preClock.mergedWith(
        stars: 3,
        moves: 9,
        timeSeconds: 200,
        points: 700,
      );
      expect(merged.bestTimeSeconds, 200);
      expect(merged.hasTime, isTrue);
    });

    test('is order-independent on both new axes', () {
      final a = cleared
          .mergedWith(stars: 3, moves: 9, timeSeconds: 300, points: 400)
          .mergedWith(stars: 3, moves: 9, timeSeconds: 90, points: 2000);
      final b = cleared
          .mergedWith(stars: 3, moves: 9, timeSeconds: 90, points: 2000)
          .mergedWith(stars: 3, moves: 9, timeSeconds: 300, points: 400);

      expect(a.bestTimeSeconds, b.bestTimeSeconds);
      expect(a.bestPoints, b.bestPoints);
    });
  });

  group('rows written before the clock shipped still load', () {
    test('a payload with no time or points is not a wipe', () {
      // The upgrade path. Every player who already has progress has rows in
      // the old shape, and a failed parse here is a deleted campaign.
      final restored = LevelProgress.fromJson(const {
        'id': 12,
        'v': 1,
        's': 3,
        'm': 8,
      });

      expect(restored.levelId, 12);
      expect(restored.stars, 3);
      expect(restored.bestMoves, 8);
      expect(restored.bestTimeSeconds, 0);
      expect(restored.hasTime, isFalse);
    });

    test('a new payload round-trips', () {
      const row = LevelProgress(
        levelId: 12,
        levelSetVersion: 2,
        stars: 2,
        bestMoves: 14,
        bestTimeSeconds: 91,
        bestPoints: 1234,
      );
      final back = LevelProgress.fromJson(row.toJson());

      expect(back.bestTimeSeconds, 91);
      expect(back.bestPoints, 1234);
      expect(back.levelSetVersion, 2);
    });
  });

  group('ProgressController', () {
    late ProviderContainer container;

    setUp(() => container = ProviderContainer());
    tearDown(() => container.dispose());

    ProgressController controller() =>
        container.read(progressProvider.notifier);

    test('a completion reports the clock and what it scored', () {
      final level = levelWith(id: 1, minMoves: 10);
      final result = controller().record(
        level: level,
        levelSetVersion: 1,
        movesUsed: 10,
        elapsedSeconds: level.parSeconds,
      );

      expect(result.elapsedSeconds, level.parSeconds);
      expect(result.parSeconds, level.parSeconds);
      expect(result.isUnderPar, isTrue);
      expect(result.points, greaterThan(0));
      expect(
        result.isNewFastest,
        isFalse,
        reason: 'a first clear has nothing to beat',
      );
      expect(result.previousFastest, isNull);
    });

    test('a faster replay is reported as a personal best time', () {
      final level = levelWith(id: 1, minMoves: 10);
      controller().record(
        level: level,
        levelSetVersion: 1,
        movesUsed: 10,
        elapsedSeconds: 200,
      );

      final result = controller().record(
        level: level,
        levelSetVersion: 1,
        movesUsed: 10,
        elapsedSeconds: 120,
      );

      expect(result.isNewFastest, isTrue);
      expect(result.previousFastest, 200);
      expect(controller().forLevel(1)!.bestTimeSeconds, 120);
    });

    test('a slower replay keeps the faster time on record', () {
      final level = levelWith(id: 1, minMoves: 10);
      controller().record(
        level: level,
        levelSetVersion: 1,
        movesUsed: 10,
        elapsedSeconds: 120,
      );
      final result = controller().record(
        level: level,
        levelSetVersion: 1,
        movesUsed: 10,
        elapsedSeconds: 400,
      );

      expect(result.isNewFastest, isFalse);
      expect(controller().forLevel(1)!.bestTimeSeconds, 120);
    });

    test('records a first clear with no previous best', () {
      final result = controller().record(
        level: levelWith(id: 1, minMoves: 5),
        levelSetVersion: 1,
        movesUsed: 5,
        elapsedSeconds: 60,
      );

      expect(result.stars, 3);
      expect(result.isNewBest, isFalse, reason: 'nothing to beat yet');
      expect(result.previousBest, isNull);
    });

    test('detects a personal best on a later run', () {
      final level = levelWith(id: 1, minMoves: 5);
      controller().record(
        level: level,
        levelSetVersion: 1,
        movesUsed: 9,
        elapsedSeconds: 60,
      );

      final result = controller().record(
        level: level,
        levelSetVersion: 1,
        movesUsed: 7,
        elapsedSeconds: 60,
      );

      expect(result.isNewBest, isTrue);
      expect(result.previousBest, 9);
    });

    test('an equal run is not a new best', () {
      final level = levelWith(id: 1, minMoves: 5);
      controller().record(
        level: level,
        levelSetVersion: 1,
        movesUsed: 7,
        elapsedSeconds: 60,
      );
      final result = controller().record(
        level: level,
        levelSetVersion: 1,
        movesUsed: 7,
        elapsedSeconds: 60,
      );
      expect(result.isNewBest, isFalse);
    });

    test('stores the level set version the stars were earned against', () {
      // Without this, changing a level post-launch would repoint saved
      // progress at a board the player has never seen.
      controller().record(
        level: levelWith(id: 3, minMoves: 5),
        levelSetVersion: 7,
        movesUsed: 6,
        elapsedSeconds: 60,
      );
      expect(controller().forLevel(3)!.levelSetVersion, 7);
    });

    test('clearing a level unlocks the next one, and no further', () {
      expect(controller().isUnlocked(1), isTrue);
      expect(controller().isUnlocked(2), isFalse);

      controller().record(
        level: levelWith(id: 1, minMoves: 5),
        levelSetVersion: 1,
        movesUsed: 5,
        elapsedSeconds: 60,
      );

      expect(controller().isUnlocked(2), isTrue);
      expect(controller().isUnlocked(3), isFalse);
      expect(controller().furthestUnlocked, 2);
    });

    test('counts clears within a band range', () {
      for (final id in [16, 17, 19]) {
        controller().record(
          level: levelWith(id: id, minMoves: 5),
          levelSetVersion: 1,
          movesUsed: 6,
          elapsedSeconds: 60,
        );
      }
      expect(controller().clearedIn(16, 30), 3);
      expect(controller().clearedIn(1, 15), 0);
    });
  });

  group('WinProfile', () {
    test('three stars earns the full sequence', () {
      final p = WinProfile.forOutcome(
        stars: 3,
        isNewBest: false,
        isBandFinal: false,
      );
      expect(p, WinProfile.full);
      expect(p.total, 1820);
    });

    test('a personal best earns the full sequence even at one star', () {
      expect(
        WinProfile.forOutcome(stars: 1, isNewBest: true, isBandFinal: false),
        WinProfile.full,
      );
    });

    test('finishing a band earns the full sequence', () {
      expect(
        WinProfile.forOutcome(stars: 2, isNewBest: false, isBandFinal: true),
        WinProfile.full,
      );
    });

    test('a routine two-star clear gets the brief sequence', () {
      // A player on level 60 has seen this sixty times. The beats are the same;
      // only the spacing tightens.
      final p = WinProfile.forOutcome(
        stars: 2,
        isNewBest: false,
        isBandFinal: false,
      );
      expect(p, WinProfile.brief);
      expect(p.total, 1150);
    });

    test('the brief profile keeps every beat, just tighter', () {
      expect(WinProfile.brief.starAt, hasLength(3));
      expect(WinProfile.brief.present, isNull, reason: 'flourish dropped');
      expect(
        WinProfile.brief.starAt[1] - WinProfile.brief.starAt[0],
        120,
        reason: 'star spacing tightens from 180ms to 120ms',
      );
      expect(WinProfile.brief.cta.at, lessThan(WinProfile.full.cta.at));
    });

    test('every beat finishes inside its profile', () {
      for (final p in [WinProfile.full, WinProfile.brief]) {
        expect(p.cta.end, lessThanOrEqualTo(p.total));
        expect(p.secondary.end, lessThanOrEqualTo(p.total));
        expect(p.band.end, lessThanOrEqualTo(p.total));
        expect(p.moves.end, lessThanOrEqualTo(p.total));
        for (final at in p.starAt) {
          expect(at + p.starLength, lessThanOrEqualTo(p.total));
        }
      }
    });

    test('the CTA is always last', () {
      // One gravitational centre: Next must not compete with anything still
      // arriving.
      for (final p in [WinProfile.full, WinProfile.brief]) {
        expect(p.cta.at, greaterThan(p.band.at));
        expect(p.cta.at, greaterThan(p.moves.at));
        expect(p.cta.at, greaterThan(p.starAt.last));
        expect(p.secondary.at, greaterThan(p.cta.at));
      }
    });
  });

  group('band metadata', () {
    test('every level belongs to exactly one band', () {
      final bands = campaignBands();
      for (var id = 1; id <= 150; id++) {
        expect(bands.where((b) => b.contains(id)), hasLength(1));
      }
    });

    test('band shape labels are populated', () {
      for (final band in campaignBands()) {
        expect(band.shape, contains('colors'));
        expect(band.shape, contains('spare'));
      }
    });

    test('band-final levels are detected', () {
      for (final band in campaignBands()) {
        expect(isBandFinalLevel(band.lastLevel), isTrue);
        expect(isBandFinalLevel(band.firstLevel), isFalse);
      }
    });
  });
}

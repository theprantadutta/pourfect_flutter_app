// Regressions for defects found in the 2026-09-08 audit.
//
// Both of these cost the player something real — progress, or a hint they paid
// attention for — and both were invisible to the existing suite because they
// only appear when an asynchronous load lands LATER than the thing it is
// racing. Each test forces that ordering rather than hoping for it.

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pourfect_flutter_app/engine/board.dart';
import 'package:pourfect_flutter_app/engine/level.dart';
import 'package:pourfect_flutter_app/services/ads/ad_service.dart';
import 'package:pourfect_flutter_app/services/analytics/analytics_service.dart';
import 'package:pourfect_flutter_app/services/iap/billing_service.dart';
import 'package:pourfect_flutter_app/state/monetization_controller.dart';
import 'package:pourfect_flutter_app/state/progress_repository.dart';
import 'package:pourfect_flutter_app/state/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A repository whose load can be held open, so the race is deterministic.
class SlowRepository extends ProgressRepository {
  final _gate = Completer<Map<int, LevelProgress>>();
  Map<int, LevelProgress> saved = const {};
  int saveCount = 0;

  void release(Map<int, LevelProgress> stored) => _gate.complete(stored);

  @override
  Future<Map<int, LevelProgress>> load() => _gate.future;

  @override
  Future<void> save(Map<int, LevelProgress> progress) async {
    saveCount++;
    saved = progress;
  }
}

Level _level(int id) => Level(
  id: id,
  board: Board.fromLists(const [
    [0, 0, 0, 1],
    [1, 1, 1, 0],
    [],
  ], capacity: 4),
  minMoves: 4,
  difficultyScore: 20,
  forcedMoveRatio: 0.1,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('what the restore recovers actually reaches the disk', () {
    // The follow-up audit's finding. The earlier fix repaired MEMORY and
    // stopped there, so the recovered result survived exactly as long as the
    // process did: the next launch loaded the worse row and restored the loss
    // as though it were the truth. These assert the SAVED payload, which is
    // the only thing a restart can see.

    test(
      'a bad replay of an already-stored level is not left on disk',
      () async {
        final repository = SlowRepository();
        final container = ProviderContainer(
          overrides: [progressRepositoryProvider.overrideWithValue(repository)],
        );
        addTearDown(container.dispose);

        final controller = container.read(progressProvider.notifier);

        // A 20-move replay of level 1, recorded before the stored snapshot
        // lands. Same level, so the maps end up the same SIZE — which is the
        // whole reason the old length check missed this.
        controller.record(
          level: _level(1),
          levelSetVersion: 1,
          movesUsed: 20,
          elapsedSeconds: 600,
        );

        repository.release({
          1: const LevelProgress(
            levelId: 1,
            levelSetVersion: 1,
            stars: 3,
            bestMoves: 5,
            bestTimeSeconds: 60,
            bestPoints: 1400,
          ),
        });
        await pumpEventQueue();

        final recovered = container.read(progressProvider)[1]!;
        expect(recovered.stars, 3, reason: 'memory lost the stored best');

        final onDisk = repository.saved[1];
        expect(onDisk, isNotNull, reason: 'nothing was ever written');
        expect(
          onDisk!.stars,
          3,
          reason:
              'the disk kept the 1-star replay; a restart would lose the best',
        );
        expect(onDisk.bestMoves, 5);
        expect(onDisk.bestTimeSeconds, 60);
        expect(onDisk.bestPoints, 1400);
      },
    );

    test('no write ever lands carrying only pre-restore state', () async {
      // The truncation. A completion recorded during startup used to be
      // persisted immediately, and what it wrote was the whole map as it stood
      // — one level — over a file holding the entire campaign.
      final repository = SlowRepository();
      final container = ProviderContainer(
        overrides: [progressRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);

      container
          .read(progressProvider.notifier)
          .record(
            level: _level(9),
            levelSetVersion: 1,
            movesUsed: 4,
            elapsedSeconds: 60,
          );
      await pumpEventQueue();

      expect(
        repository.saveCount,
        0,
        reason: 'a write ran before the stored campaign had been read',
      );

      repository.release({
        for (var id = 1; id <= 8; id++)
          id: LevelProgress(
            levelId: id,
            levelSetVersion: 1,
            stars: 3,
            bestMoves: 4,
          ),
      });
      await pumpEventQueue();

      expect(repository.saved.keys.toList()..sort(), [
        1,
        2,
        3,
        4,
        5,
        6,
        7,
        8,
        9,
      ], reason: 'the saved map lost levels that were already on disk');
    });

    test(
      'a full round trip through the real repository keeps the best',
      () async {
        // The same scenario against the SHIPPING repository and its real
        // encoding, so the assertion is about what a relaunch would load rather
        // than about a test double.
        SharedPreferences.setMockInitialValues({});
        final repository = ProgressRepository();

        await repository.save({
          1: const LevelProgress(
            levelId: 1,
            levelSetVersion: 1,
            stars: 3,
            bestMoves: 5,
            bestTimeSeconds: 60,
            bestPoints: 1400,
          ),
        });

        final container = ProviderContainer(
          overrides: [progressRepositoryProvider.overrideWithValue(repository)],
        );
        addTearDown(container.dispose);

        final controller = container.read(progressProvider.notifier);
        controller.record(
          level: _level(1),
          levelSetVersion: 1,
          movesUsed: 20,
          elapsedSeconds: 600,
        );
        await pumpEventQueue();

        final relaunched = await ProgressRepository().load();
        expect(relaunched[1]!.stars, 3);
        expect(relaunched[1]!.bestMoves, 5);
        expect(relaunched[1]!.bestTimeSeconds, 60);
      },
    );
  });

  group('a late load cannot delete progress made before it arrived', () {
    test('a level completed first survives the restore', () async {
      // The reported failure: build() starts the load, record() saves a
      // completion while it is still in flight, and _restore() then assigned
      // the old snapshot over the top — level 2 simply vanished, and the next
      // save persisted the loss.
      final repository = SlowRepository();
      final container = ProviderContainer(
        overrides: [progressRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);

      final controller = container.read(progressProvider.notifier);

      // Finish level 2 BEFORE the stored snapshot lands.
      controller.record(
        level: _level(2),
        levelSetVersion: 1,
        movesUsed: 4,
        elapsedSeconds: 60,
      );
      expect(container.read(progressProvider).containsKey(2), isTrue);

      // The stored snapshot knows only about level 1.
      repository.release({
        1: const LevelProgress(
          levelId: 1,
          levelSetVersion: 1,
          stars: 3,
          bestMoves: 4,
        ),
      });
      await Future<void>.delayed(Duration.zero);

      final state = container.read(progressProvider);
      expect(
        state.containsKey(2),
        isTrue,
        reason: 'the late restore erased a completed level',
      );
      expect(
        state.containsKey(1),
        isTrue,
        reason: 'the restore dropped what was on disk',
      );
    });

    test('the better of the two sides wins per level', () async {
      final repository = SlowRepository();
      final container = ProviderContainer(
        overrides: [progressRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);

      final controller = container.read(progressProvider.notifier);

      // In memory: a WORSE run of level 1 than the one already stored.
      controller.record(
        level: _level(1),
        levelSetVersion: 1,
        movesUsed: 9,
        elapsedSeconds: 60,
      );

      repository.release({
        1: const LevelProgress(
          levelId: 1,
          levelSetVersion: 1,
          stars: 3,
          bestMoves: 4,
        ),
      });
      await Future<void>.delayed(Duration.zero);

      final level1 = container.read(progressProvider)[1]!;
      expect(level1.stars, 3, reason: 'a worse in-memory run took a star away');
      expect(level1.bestMoves, 4);
    });
  });

  group('a hint that is never delivered is not charged for', () {
    ProviderContainer containerFor(NoopBillingService billing) {
      final container = ProviderContainer(
        overrides: [
          billingServiceProvider.overrideWithValue(billing),
          adServiceProvider.overrideWithValue(const NoopAdService()),
          analyticsServiceProvider.overrideWithValue(
            const NoopAnalyticsService(),
          ),
        ],
      );
      addTearDown(container.dispose);
      return container;
    }

    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('a refunded free hint goes back into the allowance', () async {
      // The screen spends a free hint BEFORE asking the solver, so a solver
      // that comes back empty used to take one of three free hints for
      // nothing.
      final container = containerFor(const NoopBillingService());
      final money = container.read(monetizationProvider.notifier);

      expect(await money.consumeFreeHint(), isTrue);
      expect(
        container.read(monetizationProvider).freeHintsRemaining,
        kFreeHints - 1,
      );

      await money.refundFreeHint();
      expect(
        container.read(monetizationProvider).freeHintsRemaining,
        kFreeHints,
      );
    });

    test('refunding never manufactures hints beyond the allowance', () async {
      final container = containerFor(const NoopBillingService());
      final money = container.read(monetizationProvider.notifier);

      await money.refundFreeHint();
      await money.refundFreeHint();

      expect(
        container.read(monetizationProvider).freeHintsRemaining,
        kFreeHints,
        reason: 'a refund with nothing spent invented a free hint',
      );
    });

    test('a watched video that produced nothing leaves a credit', () async {
      // This is what makes "your video is saved for the next one" true. Before
      // the fix the player watched a video, got no hint, and the next attempt
      // demanded another video.
      final container = containerFor(const NoopBillingService());
      final money = container.read(monetizationProvider.notifier);

      for (var i = 0; i < kFreeHints; i++) {
        await money.consumeFreeHint();
      }
      expect(container.read(monetizationProvider).hintNeedsAd, isTrue);

      // Watched a video, hint failed to resolve, credit retained.
      await money.grantHintCredit();

      expect(container.read(monetizationProvider).hasHintCredit, isTrue);
      expect(
        container.read(monetizationProvider).hintNeedsAd,
        isFalse,
        reason: 'a paid-for hint should not demand another video',
      );

      // The next request spends it, and only once.
      expect(await money.consumeHintCredit(), isTrue);
      expect(await money.consumeHintCredit(), isFalse);
      expect(container.read(monetizationProvider).hintNeedsAd, isTrue);
    });

    test('a credit survives a relaunch', () async {
      SharedPreferences.setMockInitialValues({
        'pourfect.hints.used': kFreeHints,
        'pourfect.hints.credits': 1,
      });

      final container = containerFor(const NoopBillingService());
      final money = container.read(monetizationProvider.notifier);

      expect(
        await money.consumeHintCredit(),
        isTrue,
        reason: 'closing the app pocketed a hint the player paid for',
      );
    });
  });
}

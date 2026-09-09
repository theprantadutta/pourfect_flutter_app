// The scored clock.
//
// Two things have to be true or the score is a lie, and neither is visible
// from looking at the screen:
//
//   1. The clock counts PLAY, not wall time. It stops when the app is
//      backgrounded and while a rewarded video is on screen. A clock that ran
//      through an ad break would charge the player score for watching an ad we
//      asked them to watch.
//   2. Each second reaches the play history exactly once. The score wants the
//      whole attempt; the history wants every second once, and an interrupted
//      attempt arrives in instalments.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pourfect_flutter_app/engine/board.dart';
import 'package:pourfect_flutter_app/engine/level.dart';
import 'package:pourfect_flutter_app/services/ads/ad_service.dart';
import 'package:pourfect_flutter_app/services/analytics/analytics_service.dart';
import 'package:pourfect_flutter_app/services/audio/audio_service.dart';
import 'package:pourfect_flutter_app/services/haptics/haptics_service.dart';
import 'package:pourfect_flutter_app/services/iap/billing_service.dart';
import 'package:pourfect_flutter_app/state/game_controller.dart';
import 'package:pourfect_flutter_app/state/game_state.dart';
import 'package:pourfect_flutter_app/state/providers.dart';

/// Solvable in one move: tube 0 holds three 0s, tube 2 holds the fourth.
Level oneMoveLevel() => Level(
  id: 1,
  board: Board.fromLists([
    [0, 0, 0],
    [1, 1, 1, 1],
    [0],
  ], capacity: 4),
  minMoves: 1,
  difficultyScore: 20,
  forcedMoveRatio: 1,
);

GameState freshAt(DateTime now) =>
    GameState.fresh(level: oneMoveLevel(), levelSetVersion: 1, now: now);

void main() {
  group('elapsed time counts play, not wall time', () {
    final start = DateTime(2026, 9, 8, 12);

    test('a running clock advances with the wall clock', () {
      final state = freshAt(start);
      expect(
        state.elapsedSecondsAt(start.add(const Duration(seconds: 45))),
        45,
      );
    });

    test('a stopped clock does not advance, however long it is stopped', () {
      // THE ONE THAT MATTERS. Take the pause away and a phone left face-down
      // overnight scores the player its floor multiplier on a level they
      // solved in ninety seconds.
      final state = freshAt(start).copyWith(
        elapsedBefore: const Duration(seconds: 45),
        runningSince: () => null,
      );

      expect(state.isClockRunning, isFalse);
      expect(state.elapsedSecondsAt(start.add(const Duration(hours: 9))), 45);
    });

    test('time banked before a pause survives the resume', () {
      final paused = freshAt(start).copyWith(
        elapsedBefore: const Duration(seconds: 45),
        runningSince: () => null,
      );

      final resumedAt = start.add(const Duration(hours: 9));
      final resumed = paused.copyWith(runningSince: () => resumedAt);

      expect(
        resumed.elapsedSecondsAt(resumedAt.add(const Duration(seconds: 10))),
        55,
        reason: 'the resume lost the 45 seconds already played',
      );
    });

    test('a device clock jumping backwards never eats banked time', () {
      // Timezone change, NTP correction, somebody setting the date by hand.
      final state = freshAt(start)
          .copyWith(elapsedBefore: const Duration(seconds: 45));

      expect(
        state.elapsedSecondsAt(start.subtract(const Duration(hours: 3))),
        45,
      );
    });
  });

  group('the play history is handed each second exactly once', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer(
        overrides: [
          analyticsServiceProvider.overrideWithValue(
            RecordingAnalyticsService(),
          ),
          hapticsServiceProvider.overrideWithValue(const NoopHapticsService()),
          audioServiceProvider.overrideWithValue(const NoopAudioService()),
          adServiceProvider.overrideWithValue(const NoopAdService()),
          billingServiceProvider.overrideWithValue(const NoopBillingService()),
        ],
      );
    });

    tearDown(() => container.dispose());

    GameController controller() =>
        container.read(gameControllerProvider.notifier);

    test('a second call hands over nothing', () {
      // Two exit paths can fire on the same departure — backgrounding while
      // navigating away. Without the high-water mark the stretch is counted
      // twice and "time played" drifts upwards forever.
      controller().startLevel(oneMoveLevel(), levelSetVersion: 1);
      controller().takeUnbankedSeconds();

      expect(controller().takeUnbankedSeconds(), 0);
    });

    test('with no level open there is nothing to hand over', () {
      expect(controller().takeUnbankedSeconds(), 0);
    });

    test('banking does not stop the clock or lose the score', () {
      controller().startLevel(oneMoveLevel(), levelSetVersion: 1);
      final before = container
          .read(gameControllerProvider)!
          .elapsedSecondsAt(DateTime.now());

      controller().takeUnbankedSeconds();
      final state = container.read(gameControllerProvider)!;

      expect(state.isClockRunning, isTrue);
      expect(
        state.elapsedSecondsAt(DateTime.now()),
        greaterThanOrEqualTo(before),
        reason: 'the score clock must keep the whole attempt',
      );
    });
  });

  group('pause and resume', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer(
        overrides: [
          analyticsServiceProvider.overrideWithValue(
            RecordingAnalyticsService(),
          ),
          hapticsServiceProvider.overrideWithValue(const NoopHapticsService()),
          audioServiceProvider.overrideWithValue(const NoopAudioService()),
          adServiceProvider.overrideWithValue(const NoopAdService()),
          billingServiceProvider.overrideWithValue(const NoopBillingService()),
        ],
      );
    });

    tearDown(() => container.dispose());

    GameController controller() =>
        container.read(gameControllerProvider.notifier);

    test('a level starts with the clock running', () {
      controller().startLevel(oneMoveLevel(), levelSetVersion: 1);
      expect(container.read(gameControllerProvider)!.isClockRunning, isTrue);
    });

    test('pausing twice does not lose the second stretch', () {
      controller().startLevel(oneMoveLevel(), levelSetVersion: 1);
      controller().pauseClock();
      final banked = container.read(gameControllerProvider)!.elapsedBefore;

      controller().pauseClock();

      expect(container.read(gameControllerProvider)!.elapsedBefore, banked);
      expect(container.read(gameControllerProvider)!.isClockRunning, isFalse);
    });

    test('resume restarts it', () {
      controller().startLevel(oneMoveLevel(), levelSetVersion: 1);
      controller().pauseClock();
      controller().resumeClock();
      expect(container.read(gameControllerProvider)!.isClockRunning, isTrue);
    });

    test('the winning move stops the clock', () {
      // The score must not depend on how long the win animation takes to play,
      // or on how long the card is left on screen afterwards.
      controller().startLevel(oneMoveLevel(), levelSetVersion: 1);
      controller().tapTube(0);
      controller().tapTube(2);

      final state = container.read(gameControllerProvider)!;
      expect(state.isWon, isTrue);
      expect(state.isClockRunning, isFalse);
    });

    test('a finished level never restarts its clock', () {
      // Coming back from an interstitial, or the app resuming behind the win
      // card, must not add seconds to a score that is already settled.
      controller().startLevel(oneMoveLevel(), levelSetVersion: 1);
      controller().tapTube(0);
      controller().tapTube(2);

      controller().resumeClock();

      expect(container.read(gameControllerProvider)!.isClockRunning, isFalse);
    });
  });
}

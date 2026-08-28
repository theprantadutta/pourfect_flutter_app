// State-layer tests. Run under `flutter test` (Riverpod pulls in Flutter);
// the pure-Dart engine suite still runs under the faster `dart test`.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pourfect_flutter_app/engine/board.dart';
import 'package:pourfect_flutter_app/engine/level.dart';
import 'package:pourfect_flutter_app/engine/move.dart';
import 'package:pourfect_flutter_app/services/analytics/analytics_service.dart';
import 'package:pourfect_flutter_app/services/ads/ad_service.dart';
import 'package:pourfect_flutter_app/services/audio/audio_service.dart';
import 'package:pourfect_flutter_app/services/iap/billing_service.dart';
import 'package:pourfect_flutter_app/services/haptics/haptics_service.dart';
import 'package:pourfect_flutter_app/state/game_controller.dart';
import 'package:pourfect_flutter_app/state/providers.dart';

/// A level solvable in one move: tube 0 holds three 0s, tube 2 holds the fourth.
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

/// Two colors interleaved with a spare tube — several legal moves available.
Level openLevel() => Level(
  id: 2,
  board: Board.fromLists([
    [0, 1, 0, 1],
    [1, 0, 1, 0],
    [],
  ], capacity: 4),
  minMoves: 6,
  difficultyScore: 40,
  forcedMoveRatio: 0.5,
);

void main() {
  late ProviderContainer container;
  late RecordingAnalyticsService analytics;

  setUp(() {
    analytics = RecordingAnalyticsService();
    container = ProviderContainer(
      overrides: [
        analyticsServiceProvider.overrideWithValue(analytics),
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
  dynamic state() => container.read(gameControllerProvider);

  void start([Level? level]) =>
      controller().startLevel(level ?? openLevel(), levelSetVersion: 1);

  group('selection', () {
    test('tapping a filled tube lifts its run', () {
      start();
      expect(controller().tapTube(0), TapOutcome.selected);
      expect(state().selectedTube, 0);
    });

    test('tapping an empty tube with nothing held does nothing', () {
      start();
      expect(controller().tapTube(2), TapOutcome.ignored);
      expect(state().selectedTube, isNull);
    });

    test('tapping the SELECTED tube puts it back down', () {
      // The most commonly missed interaction in this genre. Without it a player
      // who changes their mind must waste a move or reach for undo.
      start();
      controller().tapTube(0);
      expect(controller().tapTube(0), TapOutcome.deselected);
      expect(state().selectedTube, isNull);
      expect(state().movesUsed, 0);
    });

    test('tapping an illegal but filled tube moves the selection there', () {
      // Tube 0 tops with 1, tube 1 tops with 0 and is full — an illegal target.
      // Someone tapping it almost always means "pick that one up instead".
      start();
      controller().tapTube(0);
      expect(controller().tapTube(1), TapOutcome.reselected);
      expect(state().selectedTube, 1);
      expect(state().movesUsed, 0);
    });

    test('legal targets exclude tubes that cannot receive the run', () {
      start();
      controller().tapTube(0);
      expect(state().legalTargets, contains(2));
      expect(state().legalTargets, isNot(contains(1)));
    });
  });

  group('pouring', () {
    test('a legal tap pours and records the move', () {
      start();
      controller().tapTube(0);
      expect(controller().tapTube(2), TapOutcome.poured);

      expect(state().movesUsed, 1);
      expect(state().selectedTube, isNull);
      expect(state().board[2].balls, [1]);
    });

    test('completing a tube is reported distinctly', () {
      start(oneMoveLevel());
      controller().tapTube(2);
      expect(controller().tapTube(0), TapOutcome.pouredAndCompleted);
      expect(state().isWon, isTrue);
    });

    test('the pour event carries what the animation needs', () {
      start();
      controller().tapTube(0);
      controller().tapTube(2);

      final pour = state().pour;
      expect(pour.ballsMoved, 1);
      expect(pour.color, 1);
      expect(pour.sourceTopSlot, 3);
      expect(pour.destBaseSlot, 0);
    });

    test('pour sequence increments so repeats are distinguishable', () {
      start();
      controller().tapTube(0);
      controller().tapTube(2);
      final first = state().pour.sequence;

      // Board is now [0,1,0] / [1,0,1,0] / [1]. Tube 1 tops with 0 and tube 0
      // has one slot free topped with 0, so 1 -> 0 is the legal follow-up.
      controller().tapTube(1);
      controller().tapTube(0);
      expect(state().movesUsed, 2);
      expect(state().pour.sequence, greaterThan(first));
    });

    test('taps are ignored once the level is won', () {
      start(oneMoveLevel());
      controller().tapTube(2);
      controller().tapTube(0);
      expect(controller().tapTube(1), TapOutcome.ignored);
    });
  });

  group('undo', () {
    test('is free and unlimited', () {
      // Undo is a retention feature, never a monetisation one. If this ever
      // grows a counter or a gate, something has gone wrong upstream.
      start();
      for (var i = 0; i < 3; i++) {
        controller().tapTube(0);
        controller().tapTube(2);
        controller().tapTube(2);
        controller().tapTube(1);
      }
      final moves = state().movesUsed;
      expect(moves, greaterThan(0));

      for (var i = 0; i < moves; i++) {
        expect(controller().undo(), isTrue);
      }
      expect(state().movesUsed, 0);
      expect(controller().undo(), isFalse);
    });

    test('restores the exact previous board', () {
      start();
      final before = state().board;
      controller().tapTube(0);
      controller().tapTube(2);
      controller().undo();
      expect(state().board, before);
    });

    test('clears any selection and hint', () {
      start();
      controller().tapTube(0);
      controller().tapTube(2);
      controller().tapTube(1);
      controller().undo();
      expect(state().selectedTube, isNull);
      expect(state().hintMove, isNull);
    });
  });

  group('analytics funnel', () {
    test('opening a level logs level_start', () {
      start();
      final events = analytics.ofType<LevelStart>();
      expect(events, hasLength(1));
      expect(events.single.levelId, 2);
      expect(events.single.isRetry, isFalse);
    });

    test('re-opening the same level marks it as a retry', () {
      start();
      start();
      expect(analytics.ofType<LevelStart>().last.isRetry, isTrue);
    });

    test('winning logs level_complete with stars and counts', () {
      start(oneMoveLevel());
      controller().tapTube(2);
      controller().tapTube(0);

      final done = analytics.ofType<LevelComplete>().single;
      expect(done.levelId, 1);
      expect(done.moves, 1);
      expect(done.stars, 3);
      expect(done.undosUsed, 0);
    });

    test('level_complete is logged exactly once', () {
      start(oneMoveLevel());
      controller().tapTube(2);
      controller().tapTube(0);
      controller().reportAbandon(AbandonReason.backgrounded);
      expect(analytics.ofType<LevelComplete>(), hasLength(1));
      expect(analytics.ofType<LevelAbandon>(), isEmpty);
    });

    test('BACKGROUNDING logs level_abandon', () {
      // The dominant abandon path: most people who give up close the app rather
      // than pressing back. A funnel that only counts clean exits undercounts
      // abandonment on exactly the levels it exists to find.
      start();
      controller().tapTube(0);
      controller().tapTube(2);
      controller().reportAbandon(AbandonReason.backgrounded);

      final abandon = analytics.ofType<LevelAbandon>().single;
      expect(abandon.reason, AbandonReason.backgrounded);
      expect(abandon.moves, 1);
      expect(abandon.progress, closeTo(1 / 6, 1e-9));
    });

    test('backgrounding before any move is not an abandonment', () {
      // Opening and immediately backgrounding is a session event. Counting it
      // would smear noise across every level's funnel.
      start();
      controller().reportAbandon(AbandonReason.backgrounded);
      expect(analytics.ofType<LevelAbandon>(), isEmpty);
    });

    test('abandon is logged at most once per attempt', () {
      start();
      controller().tapTube(0);
      controller().tapTube(2);
      controller().reportAbandon(AbandonReason.backgrounded);
      controller().reportAbandon(AbandonReason.backgrounded);
      controller().reportAbandon(AbandonReason.exited);
      expect(analytics.ofType<LevelAbandon>(), hasLength(1));
    });

    test('restart logs an abandon and a fresh start', () {
      start();
      controller().tapTube(0);
      controller().tapTube(2);
      controller().restart();

      expect(
        analytics.ofType<LevelAbandon>().single.reason,
        AbandonReason.restarted,
      );
      expect(analytics.ofType<LevelStart>(), hasLength(2));
      expect(state().movesUsed, 0);
    });

    test('restarting an untouched board logs no abandonment', () {
      start();
      controller().restart();
      expect(analytics.ofType<LevelAbandon>(), isEmpty);
    });

    test('undo is recorded with the dead-end flag', () {
      start();
      controller().tapTube(0);
      controller().tapTube(2);
      controller().undo();

      final undo = analytics.ofType<UndoUsed>().single;
      expect(undo.levelId, 2);
      expect(undo.movesBefore, 1);
      expect(undo.fromDeadEnd, isFalse);
    });
  });

  group('stuck detection', () {
    test('a board with no legal move reports as stuck', () {
      final dead = Level(
        id: 9,
        board: Board.fromLists([
          [0, 1, 0, 1],
          [1, 0, 1, 0],
        ], capacity: 4),
        minMoves: 1,
        difficultyScore: 50,
        forcedMoveRatio: 1,
      );
      start(dead);
      expect(state().isStuck, isTrue);
      expect(state().isWon, isFalse);
    });

    test('a fresh playable board is not stuck', () {
      start();
      expect(state().isStuck, isFalse);
    });
  });

  group('hint state', () {
    test('showing a hint selects its source and counts it', () {
      start();
      controller().showHint(const Move(0, 2));
      expect(state().hintMove, const Move(0, 2));
      expect(state().selectedTube, 0);
      expect(state().hintsUsed, 1);
      expect(state().hintPending, isFalse);
    });

    test('a pour clears the hint', () {
      start();
      // showHint already lifts the run from the hint's source, so the player's
      // next tap is the destination — that is the whole point of pre-selecting.
      controller().showHint(const Move(0, 2));
      expect(controller().tapTube(2), TapOutcome.poured);
      expect(state().hintMove, isNull);
    });

    test('putting the run back down leaves the hint on screen', () {
      // Deselecting is "not yet", not "never mind" — the advice is still good,
      // and re-showing it would cost the player another hint.
      start();
      controller().showHint(const Move(0, 2));
      controller().tapTube(0);
      expect(state().selectedTube, isNull);
      expect(state().hintMove, const Move(0, 2));
    });
  });
}

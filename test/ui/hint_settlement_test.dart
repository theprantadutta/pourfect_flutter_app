// Leaving the board while a hint is still being paid for or solved.
//
// Two audits found two halves of the same rule, and the second half is the one
// that is easy to miss.
//
// The first: `_onHint` returned the moment the widget was gone, BEFORE any
// refund branch ran, so backing out during a solve cost a free hint or an
// already-watched video with nothing on screen saying so.
//
// The second: settling unconditionally is not enough, because the GAME
// CONTROLLER OUTLIVES THE SCREEN. A player who leaves mid-solve leaves behind
// a live controller still holding the position they abandoned, so the answer
// applies cleanly to it and reports `resolved` — a perfectly successful hint,
// shown to nobody, charged for in full. Reopening a level starts a fresh
// board, so it is never seen.
//
// The rule both halves serve: a hint is charged for DELIVERY into the spell of
// play that asked for it. Not for success, and not for whether a widget
// happened to still be mounted.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pourfect_flutter_app/services/ads/ad_service.dart';
import 'package:pourfect_flutter_app/services/analytics/analytics_service.dart';
import 'package:pourfect_flutter_app/services/audio/audio_service.dart';
import 'package:pourfect_flutter_app/services/haptics/haptics_service.dart';
import 'package:pourfect_flutter_app/services/iap/billing_service.dart';
import 'package:pourfect_flutter_app/state/hint_controller.dart';
import 'package:pourfect_flutter_app/state/monetization_controller.dart';
import 'package:pourfect_flutter_app/state/providers.dart';
import 'package:pourfect_flutter_app/ui/screens/game_screen.dart';
import 'package:pourfect_flutter_app/ui/theme/tokens.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A solver that never answers until the test says so.
class StalledHintService extends HintService {
  StalledHintService(super.ref);

  final Completer<HintOutcome> gate = Completer<HintOutcome>();
  int requests = 0;

  @override
  Future<HintOutcome> request({bool wasRewarded = false}) {
    requests++;
    return gate.future;
  }
}

/// The REAL service, delayed so the screen can be removed before it starts.
///
/// Worth keeping alongside the scripted one: it uses the actual solver on the
/// actual isolate, so it proves the rule against a hint that genuinely
/// resolves rather than against an outcome a fake handed over.
class DelayedRealHintService extends HintService {
  DelayedRealHintService(super.ref);

  final Completer<void> release = Completer<void>();
  final Completer<HintOutcome> done = Completer<HintOutcome>();
  int requests = 0;

  @override
  Future<HintOutcome> request({bool wasRewarded = false}) async {
    requests++;
    await release.future;
    final outcome = await super.request(wasRewarded: wasRewarded);
    done.complete(outcome);
    return outcome;
  }
}

/// A rewarded video that stays on screen until the test dismisses it.
class StalledAdService implements AdService {
  final Completer<RewardOutcome> gate = Completer<RewardOutcome>();

  @override
  Future<RewardOutcome> showRewarded(RewardedPlacement placement) =>
      gate.future;

  @override
  Future<void> init() async {}

  @override
  bool get isInterstitialReady => false;

  @override
  Future<bool> showInterstitial() async => false;

  @override
  void preload() {}

  @override
  bool get privacyOptionsRequired => false;

  @override
  Future<void> showPrivacyOptions() async {}

  @override
  Future<void> dispose() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ProviderContainer container;
  late StalledHintService hints;
  late StalledAdService ads;

  ProviderContainer containerWith(HintService Function(Ref ref) createHints) =>
      ProviderContainer(
        overrides: [
          billingServiceProvider.overrideWithValue(const NoopBillingService()),
          adServiceProvider.overrideWithValue(ads),
          analyticsServiceProvider.overrideWithValue(
            const NoopAnalyticsService(),
          ),
          audioServiceProvider.overrideWithValue(const NoopAudioService()),
          hapticsServiceProvider.overrideWithValue(const NoopHapticsService()),
          hintServiceProvider.overrideWith(createHints),
        ],
      );

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    ads = StalledAdService();
    container = containerWith((ref) {
      hints = StalledHintService(ref);
      return hints;
    });
    addTearDown(container.dispose);
  });

  Widget host(ProviderContainer scope, Widget child) =>
      UncontrolledProviderScope(
        container: scope,
        child: MaterialApp(
          theme: ThemeData.dark(useMaterial3: true)
              .copyWith(extensions: const [PourfectTokens.dark]),
          home: child,
        ),
      );

  Future<void> openBoard(WidgetTester tester, ProviderContainer scope) async {
    await tester.pumpWidget(host(scope, GameScreen(levelId: 1, onExit: () {})));
    // The campaign asset loads asynchronously, then the board settles.
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 400));
  }

  Future<void> tapHint(WidgetTester tester) async {
    await tester.tap(find.text('HINT'));
    await tester.pump();
    await tester.pump();
  }

  Future<void> leaveBoard(WidgetTester tester, ProviderContainer scope) async {
    // The container — and so the monetization state and the game controller —
    // survives, exactly as it does when a route is popped.
    await tester.pumpWidget(host(scope, const SizedBox.shrink()));
    await tester.pump();
  }

  group('settlement does not depend on the screen being alive', () {
    testWidgets('an undelivered hint refunds the free hint', (tester) async {
      await openBoard(tester, container);
      await tapHint(tester);
      expect(hints.requests, 1);
      await leaveBoard(tester, container);

      expect(
        container.read(monetizationProvider).freeHintsRemaining,
        kFreeHints - 1,
        reason: 'the hint should still be spent while the solver is working',
      );

      hints.gate.complete(HintOutcome.unavailable);
      await tester.pump();
      await tester.pump();

      expect(
        container.read(monetizationProvider).freeHintsRemaining,
        kFreeHints,
        reason: 'leaving the screen swallowed the refund',
      );
    });

    testWidgets('a stale answer after leaving still refunds', (tester) async {
      await openBoard(tester, container);
      await tapHint(tester);
      await leaveBoard(tester, container);

      hints.gate.complete(HintOutcome.stale);
      await tester.pump();
      await tester.pump();

      expect(
        container.read(monetizationProvider).freeHintsRemaining,
        kFreeHints,
      );
    });

    testWidgets('a rewarded credit is preserved when the screen has gone', (
      tester,
    ) async {
      final money = container.read(monetizationProvider.notifier);
      for (var i = 0; i < kFreeHints; i++) {
        await money.consumeFreeHint();
      }
      await money.grantHintCredit();

      await openBoard(tester, container);
      await tapHint(tester);
      await leaveBoard(tester, container);

      expect(
        container.read(monetizationProvider).hasHintCredit,
        isFalse,
        reason: 'the credit should be spent while the solver is working',
      );

      hints.gate.complete(HintOutcome.unavailable);
      await tester.pump();
      await tester.pump();

      expect(
        container.read(monetizationProvider).hasHintCredit,
        isTrue,
        reason: 'a watched video was thrown away because the screen was gone',
      );
    });
  });

  group('a hint is charged for delivery, not for success', () {
    testWidgets('a hint delivered to the board in play IS charged', (
      tester,
    ) async {
      // The other half of the rule, and the reason "refund whenever the screen
      // is gone" would be the wrong fix: a hint that actually reached the
      // player was paid for fairly.
      await openBoard(tester, container);
      await tapHint(tester);

      hints.gate.complete(HintOutcome.resolved);
      await tester.pump();
      await tester.pump();

      expect(
        container.read(monetizationProvider).freeHintsRemaining,
        kFreeHints - 1,
        reason: 'a delivered hint was refunded',
      );
    });

    testWidgets('a hint that resolves after the player left is NOT charged', (
      tester,
    ) async {
      // The controller outlives the screen and still holds the abandoned
      // position, so the answer applies cleanly and reports success. Nobody
      // saw it: reopening the level starts a fresh board.
      await openBoard(tester, container);
      await tapHint(tester);
      await leaveBoard(tester, container);

      hints.gate.complete(HintOutcome.resolved);
      await tester.pump();
      await tester.pump();

      expect(
        container.read(monetizationProvider).freeHintsRemaining,
        kFreeHints,
        reason: 'a hint delivered only to an abandoned board was charged for',
      );
    });

    testWidgets('the real solver, on a board the player has left', (
      tester,
    ) async {
      // Same rule with no scripted outcome anywhere: the actual HintService and
      // the actual isolate solver, delayed so the screen is removed before the
      // solve begins. This is the shape the defect was reported in.
      late DelayedRealHintService real;
      final scope = containerWith((ref) => real = DelayedRealHintService(ref));
      addTearDown(scope.dispose);

      await openBoard(tester, scope);
      await tapHint(tester);
      expect(real.requests, 1);

      await leaveBoard(tester, scope);
      real.release.complete();

      for (var i = 0; i < 100 && !real.done.isCompleted; i++) {
        await tester.pump();
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)),
        );
      }
      expect(
        real.done.isCompleted,
        isTrue,
        reason: 'the solver never finished',
      );
      await tester.pump();
      await tester.pump();

      expect(
        scope.read(monetizationProvider).freeHintsRemaining,
        kFreeHints,
        reason: 'a real hint solved for an abandoned board was charged for',
      );
    });
  });

  group('a video watched for a board the player then left', () {
    testWidgets('is kept as a credit rather than spent on nothing', (
      tester,
    ) async {
      // The expensive case, and the one where refunding is not the same as
      // never charging: the player really did watch fifteen seconds of video.
      // Spending it on a session that ended while it played buys a hint with
      // nowhere to deliver it, so it stays banked for the next one.
      final money = container.read(monetizationProvider.notifier);
      for (var i = 0; i < kFreeHints; i++) {
        await money.consumeFreeHint();
      }

      await openBoard(tester, container);
      await tapHint(tester);

      // The confirm dialog: never auto-play an ad.
      await tester.tap(find.text('Watch'));
      await tester.pump();
      await tester.pump();

      // The video is on screen. The player leaves the board behind it.
      await leaveBoard(tester, container);

      ads.gate.complete(RewardOutcome.earned);
      // The grant writes through SharedPreferences, so let the real event loop
      // turn rather than only flushing microtasks.
      for (var i = 0; i < 20; i++) {
        await tester.pump();
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 10)),
        );
      }

      expect(
        container.read(monetizationProvider).hasHintCredit,
        isTrue,
        reason: 'a watched video was spent on a session that had already ended',
      );
      expect(hints.requests, 0, reason: 'a hint was solved for nobody');
    });
  });
}

// Leaving the board while a hint is still being solved.
//
// The follow-up audit's finding: `_onHint` returned the moment the widget was
// gone, BEFORE any refund branch ran. Solving happens on an isolate and takes
// real time on a late board, so backing out during it is ordinary — and it
// cost the player either a free hint or a rewarded video they had already sat
// through, with nothing on screen ever saying so.
//
// The rule this pins: what a player is owed does not depend on which widgets
// are alive. `mounted` may guard a toast and nothing else.

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
///
/// The real one runs on an isolate; what matters here is only that the await
/// in `_onHint` is still outstanding when the screen goes away.
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ProviderContainer container;
  late StalledHintService hints;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    container = ProviderContainer(
      overrides: [
        billingServiceProvider.overrideWithValue(const NoopBillingService()),
        adServiceProvider.overrideWithValue(const NoopAdService()),
        analyticsServiceProvider.overrideWithValue(
          const NoopAnalyticsService(),
        ),
        audioServiceProvider.overrideWithValue(const NoopAudioService()),
        hapticsServiceProvider.overrideWithValue(const NoopHapticsService()),
        hintServiceProvider.overrideWith((ref) {
          hints = StalledHintService(ref);
          return hints;
        }),
      ],
    );
    addTearDown(container.dispose);
  });

  Widget host(Widget child) => UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      theme: ThemeData.dark(useMaterial3: true)
          .copyWith(extensions: const [PourfectTokens.dark]),
      home: child,
    ),
  );

  /// Opens the board, taps Hint, and leaves the solver hanging.
  Future<void> askForAHintThenLeave(WidgetTester tester) async {
    await tester.pumpWidget(host(GameScreen(levelId: 1, onExit: () {})));
    // The campaign asset loads asynchronously, then the board settles.
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 400));

    await tester.tap(find.text('HINT'));
    await tester.pump();
    await tester.pump();

    expect(hints.requests, 1, reason: 'the hint was never actually requested');

    // The player leaves. The container — and so the monetization state —
    // survives, exactly as it does when a route is popped.
    await tester.pumpWidget(host(const SizedBox.shrink()));
    await tester.pump();
  }

  testWidgets('a free hint spent on a solve nobody saw comes back', (
    tester,
  ) async {
    final money = container.read(monetizationProvider.notifier);
    await container.read(monetizationProvider.notifier).consumeFreeHint();
    await money.refundFreeHint();

    await askForAHintThenLeave(tester);

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
    // The board moved on, or the request was superseded. Nothing was
    // delivered, so nothing stays spent — and that has to hold when the
    // screen is gone too.
    await askForAHintThenLeave(tester);

    hints.gate.complete(HintOutcome.stale);
    await tester.pump();
    await tester.pump();

    expect(container.read(monetizationProvider).freeHintsRemaining, kFreeHints);
  });

  testWidgets('a rewarded credit is preserved when the screen has gone', (
    tester,
  ) async {
    // The expensive case. The player has used their free hints and watched a
    // video, so the spend being refunded is fifteen seconds of their attention
    // rather than one of three freebies.
    final money = container.read(monetizationProvider.notifier);
    for (var i = 0; i < kFreeHints; i++) {
      await money.consumeFreeHint();
    }
    await money.grantHintCredit();
    expect(container.read(monetizationProvider).hasHintCredit, isTrue);

    await askForAHintThenLeave(tester);

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

  testWidgets('a delivered hint is still charged for', (tester) async {
    // The other half of the rule. Settling unconditionally must not mean
    // refunding unconditionally — a hint that arrived was paid for fairly,
    // whether or not anybody was looking at the board when it landed.
    await askForAHintThenLeave(tester);

    hints.gate.complete(HintOutcome.resolved);
    await tester.pump();
    await tester.pump();

    expect(
      container.read(monetizationProvider).freeHintsRemaining,
      kFreeHints - 1,
      reason: 'a delivered hint was refunded',
    );
  });
}

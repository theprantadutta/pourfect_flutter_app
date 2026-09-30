// The one-time hub bubble after the first win: shown to a genuinely new
// player, once, and never to somebody with a campaign behind them.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pourfect_flutter_app/services/ads/ad_service.dart';
import 'package:pourfect_flutter_app/services/analytics/analytics_service.dart';
import 'package:pourfect_flutter_app/services/audio/audio_service.dart';
import 'package:pourfect_flutter_app/services/display/display_rate_service.dart';
import 'package:pourfect_flutter_app/services/haptics/haptics_service.dart';
import 'package:pourfect_flutter_app/services/iap/billing_service.dart';
import 'package:pourfect_flutter_app/state/providers.dart';
import 'package:pourfect_flutter_app/ui/screens/home_screen.dart';
import 'package:pourfect_flutter_app/ui/theme/tokens.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _bubble = 'Journey maps every level';

Map<String, Object> _progress(int cleared) => {
  'pourfect.progress.v1': jsonEncode([
    for (var id = 1; id <= cleared; id++)
      {'id': id, 'v': 1, 's': 3, 'm': 5, 't': 30, 'p': 500, 'c': 0},
  ]),
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<ProviderContainer> pumpHub(
    WidgetTester tester,
    Map<String, Object> prefs,
  ) async {
    SharedPreferences.setMockInitialValues(prefs);
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final c = ProviderContainer(
      overrides: [
        billingServiceProvider.overrideWithValue(const NoopBillingService()),
        adServiceProvider.overrideWithValue(const NoopAdService()),
        analyticsServiceProvider.overrideWithValue(
          const NoopAnalyticsService(),
        ),
        audioServiceProvider.overrideWithValue(const NoopAudioService()),
        hapticsServiceProvider.overrideWithValue(const NoopHapticsService()),
        displayRateServiceProvider.overrideWithValue(
          const NoopDisplayRateService(),
        ),
      ],
    );
    addTearDown(c.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: c,
        child: MaterialApp(
          theme: ThemeData.light().copyWith(
            extensions: const [PourfectTokens.toybox],
          ),
          home: HomeScreen(
            onOpenLevel: (_, _) {},
            onOpenSettings: () {},
            onOpenStatistics: () {},
            onOpenDaily: () {},
            onOpenLeaderboard: () {},
            onOpenAccount: () {},
            onOpenJourney: () {},
          ),
        ),
      ),
    );
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    return c;
  }

  double bubbleOpacity(WidgetTester tester) {
    final found = find.textContaining(_bubble);
    if (found.evaluate().isEmpty) return 0;
    return tester
        .widget<AnimatedOpacity>(
          find.ancestor(of: found, matching: find.byType(AnimatedOpacity)).first,
        )
        .opacity;
  }

  testWidgets('a player with their first win sees it', (tester) async {
    await pumpHub(tester, _progress(1));
    expect(bubbleOpacity(tester), 1);
  });

  testWidgets('it shows only once', (tester) async {
    await pumpHub(tester, {
      ..._progress(1),
      'pourfect.onboarding.tips_seen.v1': ['hub'],
    });
    expect(bubbleOpacity(tester), 0);
  });

  testWidgets('nobody who has not won anything yet', (tester) async {
    await pumpHub(tester, {});
    expect(bubbleOpacity(tester), 0);
  });

  testWidgets('never somebody updating with a campaign behind them', (
    tester,
  ) async {
    await pumpHub(tester, _progress(40));
    expect(bubbleOpacity(tester), 0);
  });

  testWidgets('tapping it dismisses it', (tester) async {
    await pumpHub(tester, _progress(2));
    await tester.tap(find.textContaining(_bubble));
    await tester.pump(const Duration(milliseconds: 400));
    expect(bubbleOpacity(tester), 0);
  });
}

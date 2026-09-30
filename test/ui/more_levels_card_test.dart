// The hub after level 150.
//
// It used to show nothing at all: the next-level card vanished once the
// bundled campaign was cleared, leaving a hole in the hub at exactly the
// moment a player had been most loyal. Now it either carries on into a
// downloaded world or says, in words, where more levels come from.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pourfect_flutter_app/engine/level_set.dart';
import 'package:pourfect_flutter_app/services/ads/ad_service.dart';
import 'package:pourfect_flutter_app/services/analytics/analytics_service.dart';
import 'package:pourfect_flutter_app/services/api/api_result.dart';
import 'package:pourfect_flutter_app/services/api/campaign_api.dart';
import 'package:pourfect_flutter_app/services/audio/audio_service.dart';
import 'package:pourfect_flutter_app/services/display/display_rate_service.dart';
import 'package:pourfect_flutter_app/services/haptics/haptics_service.dart';
import 'package:pourfect_flutter_app/services/iap/billing_service.dart';
import 'package:pourfect_flutter_app/state/providers.dart';
import 'package:pourfect_flutter_app/ui/screens/home_screen.dart';
import 'package:pourfect_flutter_app/ui/theme/tokens.dart';
import 'package:pourfect_flutter_app/ui/widgets/more_levels_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

Map<String, Object> _progress(int cleared) => {
  'pourfect.progress.v1': jsonEncode([
    for (var id = 1; id <= cleared; id++)
      {'id': id, 'v': 1, 's': 3, 'm': 5, 't': 30, 'p': 500, 'c': 0},
  ]),
};

/// World 4 (levels 151-200) as the app stores it after a download.
Map<String, Object> _storedWorld() {
  final parsed = CampaignApi.parse({
    'worlds': [
      {
        'index': 4,
        'name': 'Second Wind',
        'first_level': 151,
        'last_level': 200,
        'level_set_version': 1,
        'mechanics': <String>[],
        'levels': [
          for (var id = 151; id <= 200; id++)
            {
              'id': id,
              'capacity': 4,
              'tubes': [
                [0, 1, 2, 3],
                [1, 2, 3, 0],
                [2, 3, 0, 1],
                [3, 0, 1, 2],
                <int>[],
                <int>[],
              ],
              'min_moves': 12,
              'difficulty_score': 70,
              'forced_move_ratio': 0.1,
              'is_breather': false,
            },
        ],
      },
    ],
  });
  final world = (parsed as ApiOk<CampaignWorlds>).value.worlds.single;
  return {
    'pourfect.campaign.worlds.v1': jsonEncode({
      'update_required': false,
      'worlds': [
        {
          'index': world.index,
          'name': world.name,
          'first': world.firstLevel,
          'last': world.lastLevel,
          'version': world.levelSetVersion,
          'mechanics': world.mechanics,
          'levels': base64Encode(
            LevelSetCodec.encode(
              LevelSet(levelSetVersion: 1, levels: world.levels),
            ),
          ),
        },
      ],
    }),
  };
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpHub(WidgetTester tester, Map<String, Object> prefs) async {
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
  }

  testWidgets('a player who cleared everything is told where more comes from', (
    tester,
  ) async {
    await pumpHub(tester, _progress(150));

    expect(find.byType(MoreLevelsCard), findsOneWidget);
    expect(find.text('You poured them all!'), findsOneWidget);
    expect(find.textContaining('online'), findsOneWidget);
  });

  testWidgets('a downloaded world carries straight on from level 150', (
    tester,
  ) async {
    await pumpHub(tester, {..._progress(150), ..._storedWorld()});

    expect(find.byType(MoreLevelsCard), findsNothing);
    expect(find.text('Level 151'), findsOneWidget);
    expect(find.textContaining('World 5'), findsOneWidget);
    expect(find.textContaining('Second Wind'), findsOneWidget);
  });

  testWidgets('a player mid-campaign sees their next level, not the card', (
    tester,
  ) async {
    await pumpHub(tester, _progress(40));
    expect(find.byType(MoreLevelsCard), findsNothing);
    expect(find.text('Level 41'), findsOneWidget);
  });
}

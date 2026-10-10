// The streak dialog, drawn at phone and tablet widths with a known streak.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pourfect_flutter_app/services/ads/ad_service.dart';
import 'package:pourfect_flutter_app/services/api/daily_api.dart';
import 'package:pourfect_flutter_app/state/streak_controller.dart';
import 'package:pourfect_flutter_app/ui/widgets/streak_dialog.dart';

final _info = StreakInfo(
  current: 12,
  best: 30,
  freezes: 1,
  maxFreezes: 2,
  canEarnFreeze: true,
  nextWeeklyFreezeOn: DateTime.utc(2026, 10, 12),
  today: DateTime.utc(2026, 10, 10),
  played: {
    for (var d = 1; d <= 10; d++)
      if (d != 6) DateTime.utc(2026, 10, d),
  },
  frozen: {DateTime.utc(2026, 10, 6)},
);

class _FixedStreak extends StreakController {
  int earned = 0;

  @override
  StreakInfo? build() => _info;

  @override
  Future<void> refresh() async {}

  @override
  Future<StreakInfo?> month(DateTime month) async => _info;

  @override
  Future<bool> earnFreeze() async {
    earned++;
    return true;
  }
}

void main() {
  Future<_FixedStreak> open(
    WidgetTester tester, {
    Size size = const Size(360, 780),
    RewardOutcome outcome = RewardOutcome.earned,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final streak = _FixedStreak();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [streakProvider.overrideWith(() => streak)],
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () => showStreakDialog(
                    context,
                    watchVideo: () async => outcome,
                  ),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    return streak;
  }

  testWidgets('shows the streak, the best and the month', (tester) async {
    await open(tester);

    expect(find.text('12-day streak'), findsOneWidget);
    expect(find.text('Best: 30 days'), findsOneWidget);
    expect(find.text('October 2026'), findsOneWidget);
    expect(find.bySemanticsLabel('October 6, frozen'), findsOneWidget);
    expect(find.bySemanticsLabel('October 7, played'), findsOneWidget);
    expect(find.bySemanticsLabel('1 of 2 streak freezes'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('fits a tablet too', (tester) async {
    await open(tester, size: const Size(1200, 1920));
    expect(find.text('12-day streak'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a finished video claims a freeze', (tester) async {
    final streak = await open(tester);

    await tester.tap(find.text('Watch a video for a freeze'));
    await tester.pumpAndSettle();

    expect(streak.earned, 1);
  });

  testWidgets('an unfinished video claims nothing', (tester) async {
    final streak = await open(tester, outcome: RewardOutcome.dismissed);

    await tester.tap(find.text('Watch a video for a freeze'));
    await tester.pumpAndSettle();

    expect(streak.earned, 0);
  });

  testWidgets('the next month is closed until it comes', (tester) async {
    await open(tester);
    await tester.tap(find.bySemanticsLabel('Next month'));
    await tester.pumpAndSettle();
    expect(find.text('October 2026'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Previous month'));
    await tester.pumpAndSettle();
    expect(find.text('September 2026'), findsOneWidget);
  });
}

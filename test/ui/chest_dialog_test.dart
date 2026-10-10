// The star chest dialog: opens, shows what it held, offers the double.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pourfect_flutter_app/services/api/chest_api.dart';
import 'package:pourfect_flutter_app/state/chest_controller.dart';
import 'package:pourfect_flutter_app/ui/widgets/chest_dialog.dart';

class _FakeChests extends ChestController {
  _FakeChests(this.failure);

  final ChestFailure? failure;

  @override
  ChestState build() => const ChestState(
    server: ChestStatus(totalStars: 64, starsPerChest: 30, opened: {}),
  );

  @override
  Future<(ChestReward?, ChestFailure?)> open(int index) async => failure == null
      ? (
          ChestReward(
            index: index,
            hints: 2,
            extraTubes: 1,
            cosmetic: false,
            doubled: false,
          ),
          null,
        )
      : (null, failure);
}

void main() {
  Future<void> open(
    WidgetTester tester, {
    ChestFailure? failure,
    Size size = const Size(360, 780),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [chestProvider.overrideWith(() => _FakeChests(failure))],
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () => showChestDialog(context, index: 2),
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
  }

  testWidgets('shows what the chest held', (tester) async {
    await open(tester);

    expect(find.text('Star chest 2'), findsOneWidget);
    expect(find.text('+2'), findsOneWidget);
    expect(find.text('+1'), findsOneWidget);
    expect(find.text('Double it with a video'), findsOneWidget);
    expect(find.text('Collect'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('says when the server has not caught up', (tester) async {
    await open(tester, failure: ChestFailure.notYet);

    expect(find.text('Almost there'), findsOneWidget);
    expect(find.text('Close'), findsOneWidget);
  });

  testWidgets('fits a tablet', (tester) async {
    await open(tester, size: const Size(1200, 1920));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Collect closes it', (tester) async {
    await open(tester);
    await tester.tap(find.text('Collect'));
    await tester.pumpAndSettle();
    expect(find.text('Star chest 2'), findsNothing);
  });
}

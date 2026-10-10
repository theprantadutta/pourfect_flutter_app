// The Collection screen, and every skin painting cleanly.

import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pourfect_flutter_app/services/api/cosmetics_api.dart';
import 'package:pourfect_flutter_app/services/iap/billing_service.dart';
import 'package:pourfect_flutter_app/state/cosmetics_controller.dart';
import 'package:pourfect_flutter_app/state/providers.dart';
import 'package:pourfect_flutter_app/ui/screens/collection_screen.dart';
import 'package:pourfect_flutter_app/ui/theme/ball_palette.dart';
import 'package:pourfect_flutter_app/ui/theme/cosmetics.dart';
import 'package:pourfect_flutter_app/ui/widgets/ball.dart';

const _items = [
  CosmeticItem(
    id: 'classic',
    name: 'Classic',
    isBallSkin: true,
    owned: true,
    source: 'free',
    value: 0,
  ),
  CosmeticItem(
    id: 'glossy',
    name: 'Glossy',
    isBallSkin: true,
    owned: true,
    source: 'chest',
    value: 3,
  ),
  CosmeticItem(
    id: 'marble',
    name: 'Marble',
    isBallSkin: true,
    owned: false,
    source: 'pack',
    value: 0,
  ),
  CosmeticItem(
    id: 'speckled',
    name: 'Sprinkles',
    isBallSkin: true,
    owned: false,
    source: 'streak',
    value: 7,
  ),
  CosmeticItem(
    id: 'toy',
    name: 'Toy',
    isBallSkin: false,
    owned: true,
    source: 'free',
    value: 0,
  ),
  CosmeticItem(
    id: 'wood',
    name: 'Wood',
    isBallSkin: false,
    owned: false,
    source: 'pack',
    value: 0,
  ),
];

class _FixedCosmetics extends CosmeticsController {
  final equipped = <String>[];

  @override
  CosmeticsState build() =>
      const CosmeticsState(items: _items, ballSkin: 'glossy');

  @override
  Future<void> refresh() async {}

  @override
  Future<bool> equip({String? ballSkin, String? tubeTheme}) async {
    equipped.add(ballSkin ?? tubeTheme!);
    state = state.copyWith(ballSkin: ballSkin, tubeTheme: tubeTheme);
    return true;
  }
}

void main() {
  Future<_FixedCosmetics> pump(
    WidgetTester tester, {
    Size size = const Size(360, 780),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final cosmetics = _FixedCosmetics();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          cosmeticsProvider.overrideWith(() => cosmetics),
          billingServiceProvider.overrideWithValue(const NoopBillingService()),
        ],
        child: MaterialApp(home: CollectionScreen(onClose: () {})),
      ),
    );
    await tester.pump();
    return cosmetics;
  }

  testWidgets('shows what is worn, owned and locked', (tester) async {
    await pump(tester);

    expect(find.text('Glossy balls · Toy tubes'), findsOneWidget);
    expect(find.text('Wearing'), findsWidgets);
    await tester.scrollUntilVisible(find.text('7-day streak'), 200);
    expect(find.text('7-day streak'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tapping an owned skin wears it', (tester) async {
    final cosmetics = await pump(tester);

    await tester.scrollUntilVisible(find.text('Classic'), 200);
    await tester.tap(find.text('Classic'));
    await tester.pump();

    expect(cosmetics.equipped, ['classic']);
    expect(cosmetics.state.ballSkin, 'classic');
  });

  testWidgets('tapping a locked skin says how to unlock it', (tester) async {
    final cosmetics = await pump(tester);

    await tester.scrollUntilVisible(find.text('Marble'), 200);
    await tester.tap(find.text('Marble'));
    await tester.pump();

    expect(cosmetics.equipped, isEmpty);
  });

  testWidgets('fits a tablet', (tester) async {
    await pump(tester, size: const Size(1200, 1920));
    expect(tester.takeException(), isNull);
  });

  test('every skin paints every ball', () {
    for (final skin in BallSkin.values) {
      for (var c = 0; c < kBallPalette.length; c++) {
        final recorder = ui.PictureRecorder();
        paintToyBall(
          Canvas(recorder),
          const Rect.fromLTWH(0, 0, 40, 40),
          color: Color(0xFF000000 | kBallPalette[c].rgb),
          glyph: kBallPalette[c].glyph,
          skin: skin,
        );
        recorder.endRecording().dispose();
      }
    }
  });

  test('unknown ids fall back to the defaults', () {
    expect(BallSkin.byId('nope'), BallSkin.classic);
    expect(TubeTheme.byId(null), TubeTheme.toy);
  });
}

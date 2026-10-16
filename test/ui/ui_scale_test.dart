import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pourfect_flutter_app/ui/theme/toy.dart';
import 'package:pourfect_flutter_app/ui/ui_scale.dart';

/// The tablet scale must never reach a phone. The phone is the product; the
/// iPad is drawn from it, not the other way round.
void main() {
  group('uiScaleFor', () {
    test('is exactly 1 on every phone, large ones included', () {
      for (final phone in const [
        Size(375, 667), // iPhone SE
        Size(402, 874), // iPhone 17
        Size(440, 956), // iPhone 17 Pro Max
        Size(411, 914), // a big Android phone
        Size(874, 402), // a phone on its side
      ]) {
        expect(uiScaleFor(phone), 1, reason: '$phone');
      }
    });

    test('leaves a tablet already about the canvas size alone', () {
      // The Galaxy Tab A9 the tablet pass was checked on.
      expect(uiScaleFor(const Size(601, 1006)), 1);
    });

    test('scales an iPad up, fitting the canvas in both directions', () {
      expect(uiScaleFor(const Size(1032, 1376)), closeTo(1376 / 880, 1e-9));
      expect(uiScaleFor(const Size(744, 1133)), closeTo(744 / 600, 1e-9));
    });
  });

  Future<(Size, double, double)> pump(WidgetTester tester, Size screen) async {
    tester.view.physicalSize = screen * 2;
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);

    late Size seen;
    late double ratio;
    late double board;
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => UiScale(child: child!),
        home: Builder(
          builder: (context) {
            seen = MediaQuery.sizeOf(context);
            ratio = MediaQuery.devicePixelRatioOf(context);
            board = Toy.tabletScale(context);
            return const SizedBox();
          },
        ),
      ),
    );
    return (seen, ratio, board);
  }

  testWidgets('a phone sees its own screen, untransformed', (tester) async {
    final (size, ratio, board) = await pump(tester, const Size(402, 874));

    expect(size, const Size(402, 874));
    expect(ratio, 2);
    expect(board, 1);
    expect(find.byType(FittedBox), findsNothing);
    expect(UiScale.current, 1);
  });

  testWidgets('an iPad lays out on the canvas and draws it scaled', (
    tester,
  ) async {
    const screen = Size(1032, 1376);
    final s = 1376 / 880;
    final (size, ratio, board) = await pump(tester, screen);

    expect(size.width, closeTo(screen.width / s, 1e-6));
    expect(size.height, closeTo(880, 1e-6));
    expect(ratio, closeTo(2 * s, 1e-9));
    expect(find.byType(FittedBox), findsOneWidget);
    // The ball enlargement is not applied twice on top of the scale.
    expect(board * s, closeTo(1.6, 0.05));
  });
}

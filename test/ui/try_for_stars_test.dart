// "Try for 3★" on the win screen: offered on any clear short of three stars,
// honest about an assisted clear, and gone on a perfect one.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pourfect_flutter_app/engine/board.dart';
import 'package:pourfect_flutter_app/ui/widgets/win_overlay.dart';
import 'package:pourfect_flutter_app/ui/widgets/win_profile.dart';

void main() {
  Future<({int tried})> pump(
    WidgetTester tester, {
    required int stars,
    int moves = 9,
    int par = 7,
    bool assisted = false,
    Size size = const Size(360, 780),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    var tried = 0;
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: WinResult(
            profile: WinProfile.brief,
            // Long past the end of every beat: the card at rest.
            elapsedMs: 100000,
            levelId: 12,
            board: Board.fromLists([
              [0, 0, 0],
              [1, 1, 1],
              [],
            ], capacity: 3),
            stars: stars,
            movesUsed: moves,
            minMoves: par,
            previousBest: null,
            isNewBest: false,
            elapsedSeconds: 40,
            parSeconds: 60,
            points: 120,
            previousFastest: null,
            bandName: 'Warm Up',
            worldNumber: 1,
            bandClearedBefore: 3,
            bandClearedAfter: 4,
            bandTotal: 10,
            onNext: () {},
            onReplay: () {},
            onLevels: () {},
            onTryForStars: () => tried++,
            assisted: assisted,
            interactive: true,
          ),
        ),
      ),
    );
    await tester.pump();
    return (tried: tried);
  }

  testWidgets('a two-star clear says how far from three it was', (
    tester,
  ) async {
    await pump(tester, stars: 2, moves: 9, par: 7);

    expect(find.text('Par 7, you took 9. 2 moves from 3★.'), findsOneWidget);
    expect(find.text('TRY FOR 3★'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('one move short reads as one move', (tester) async {
    await pump(tester, stars: 2, moves: 8, par: 7);
    expect(find.text('Par 7, you took 8. One move from 3★.'), findsOneWidget);
  });

  testWidgets('an assisted clear is told what three stars need', (
    tester,
  ) async {
    await pump(tester, stars: 2, moves: 7, par: 7, assisted: true);
    expect(
      find.text('Three stars need a clear without the extra tube.'),
      findsOneWidget,
    );
  });

  testWidgets('a three-star clear has nothing to try for', (tester) async {
    await pump(tester, stars: 3, moves: 7, par: 7);
    expect(find.text('TRY FOR 3★'), findsNothing);
  });

  testWidgets('the button restarts for stars', (tester) async {
    var tried = 0;
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: WinResult(
            profile: WinProfile.brief,
            elapsedMs: 100000,
            levelId: 12,
            board: Board.fromLists([
              [0, 0, 0],
              [1, 1, 1],
              [],
            ], capacity: 3),
            stars: 1,
            movesUsed: 14,
            minMoves: 7,
            previousBest: null,
            isNewBest: false,
            elapsedSeconds: 40,
            parSeconds: 60,
            points: 40,
            previousFastest: null,
            bandName: 'Warm Up',
            worldNumber: 1,
            bandClearedBefore: 3,
            bandClearedAfter: 4,
            bandTotal: 10,
            onNext: () {},
            onReplay: () {},
            onLevels: () {},
            onTryForStars: () => tried++,
            interactive: true,
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('TRY FOR 3★'));
    expect(tried, 1);
  });

  testWidgets('fits a short phone without overflow', (tester) async {
    await pump(tester, stars: 2, size: const Size(320, 640));
    expect(tester.takeException(), isNull);
  });

  testWidgets('fits a tablet', (tester) async {
    await pump(tester, stars: 2, size: const Size(1200, 1920));
    expect(tester.takeException(), isNull);
  });
}

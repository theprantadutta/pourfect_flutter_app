import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pourfect_flutter_app/ui/widgets/hud.dart';
import 'package:pourfect_flutter_app/ui/widgets/level_clock.dart';

void main() {
  group('ParMeter.pace says what the attempt can still earn', () {
    String pace(int moves) => ParMeter.pace(movesUsed: moves, minMoves: 10);

    test('within par counts down to three stars', () {
      expect(pace(0), '10 moves left for 3 stars');
      expect(pace(9), '1 move left for 3 stars');
      expect(pace(10), 'Par spent · 2 stars from here');
    });

    test('the two-star band counts down to its ceiling (1.5x par)', () {
      expect(pace(11), '4 moves left for 2 stars');
      expect(pace(14), '1 move left for 2 stars');
      expect(pace(15), '1 star from here · any finish');
      expect(pace(30), 'Any finish earns 1 star');
    });
  });

  group('clockBonusPercent is the live time multiplier', () {
    int at(int s) => clockBonusPercent(elapsedSeconds: s, parSeconds: 100);

    test('capped at +25 well under par, 0 at par, floored at -50', () {
      expect(at(0), 25);
      expect(at(80), 25);
      expect(at(90), 11);
      expect(at(100), 0);
      expect(at(125), -20);
      expect(at(500), -50);
    });
  });

  testWidgets('the meter shows moves against par, the words and the clock', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ParMeter(
            movesUsed: 3,
            minMoves: 8,
            clock: LevelClock(
              elapsedSeconds: () => 42,
              parSeconds: 70,
              isRunning: false,
              detailed: true,
            ),
          ),
        ),
      ),
    );
    expect(find.textContaining('/ 8'), findsOneWidget);
    expect(find.text('5 moves left for 3 stars'), findsOneWidget);
    expect(find.text('0:42'), findsOneWidget);
    expect(find.text(' / 1:10'), findsOneWidget);
    expect(find.text('+25% pts'), findsOneWidget);
  });
}

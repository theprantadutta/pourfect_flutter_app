// Settings → Questions, asked for by the 1.0.0 testers.
//
// The FAQ copy states game rules as facts, so the tests that matter here hold
// it to the constants those rules come from. A help page that drifts from the
// game is worse than no help page.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pourfect_flutter_app/engine/level.dart';
import 'package:pourfect_flutter_app/state/monetization_controller.dart';
import 'package:pourfect_flutter_app/ui/screens/faq_screen.dart';
import 'package:pourfect_flutter_app/ui/screens/settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  String answerTo(String question) => kFaqSections
      .expand((section) => section.$2)
      .firstWhere((faq) => faq.question == question)
      .answer;

  group('the answers match the game', () {
    test('free hints are the number the game actually gives', () {
      expect(answerTo('How do hints work?'), contains('first $kFreeHints'));
    });

    test('stars are described by the thresholds starsFor uses', () {
      // Three at par, two within 1.5x, one for any finish.
      expect(kTwoStarMoveMultiplier, 1.5);
      expect(starsFor(minMoves: 10, movesUsed: 10), 3);
      expect(starsFor(minMoves: 10, movesUsed: 15), 2);
      expect(starsFor(minMoves: 10, movesUsed: 99), 1);
      expect(answerTo('What do the stars mean?'), contains('one and a half'));
    });
  });

  testWidgets('a question opens to its answer, and closes again', (
    tester,
  ) async {
    // Pressable reads settings (sound, haptics) through Riverpod.
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(home: FaqScreen(onClose: () {})),
      ),
    );

    final answer = answerTo('Is undo limited?');
    expect(find.text(answer), findsNothing);

    await tester.tap(find.text('Is undo limited?'));
    await tester.pumpAndSettle();
    expect(find.text(answer), findsOneWidget);

    await tester.tap(find.text('Is undo limited?'));
    await tester.pumpAndSettle();
    expect(find.text(answer), findsNothing);
  });
  testWidgets('Settings opens Questions', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(home: SettingsScreen(onClose: () {})),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    await tester.scrollUntilVisible(
      find.text('Questions'),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Questions'));
    await tester.pumpAndSettle();

    expect(find.byType(FaqScreen), findsOneWidget);
  });
}

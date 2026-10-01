// The app's own ask before Play's update screen.
//
// Not now must always be there, except for a build the game no longer
// supports, where there must be no way around it at all: no button, no tap
// outside, no back.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pourfect_flutter_app/ui/widgets/update_prompt.dart';

void main() {
  Future<List<bool>> open(
    WidgetTester tester, {
    required bool mandatory,
  }) async {
    final answers = <bool>[];
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () async => answers.add(
                  await showUpdatePrompt(context, mandatory: mandatory),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    return answers;
  }

  testWidgets('says what will happen, and offers both answers', (tester) async {
    final answers = await open(tester, mandatory: false);

    expect(find.text('A new Pourfect is ready'), findsOneWidget);
    expect(find.textContaining('open the game again'), findsOneWidget);
    expect(find.textContaining('stars are safe'), findsOneWidget);

    await tester.tap(find.text('Not now'));
    await tester.pumpAndSettle();
    expect(answers, [false]);
  });

  testWidgets('Update now answers yes', (tester) async {
    final answers = await open(tester, mandatory: false);
    await tester.tap(find.text('Update now'));
    await tester.pumpAndSettle();
    expect(answers, [true]);
  });

  testWidgets('an unsupported build has no way around it', (tester) async {
    final answers = await open(tester, mandatory: true);

    expect(find.text('Time to update'), findsOneWidget);
    expect(find.text('Not now'), findsNothing);

    // Tapping outside the card does nothing.
    await tester.tapAt(const Offset(4, 4));
    await tester.pumpAndSettle();
    expect(find.text('Time to update'), findsOneWidget);

    // Neither does back.
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Time to update'), findsOneWidget);
    expect(answers, isEmpty);
  });
}

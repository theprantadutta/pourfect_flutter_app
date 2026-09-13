// Cancelling the rename box must not throw.
//
// It did. `_renameHandle` built the TextEditingController at the call site and
// disposed it the moment `showDialog` returned — which reads as correct
// lifetime management and is not. That future completes when Navigator.pop is
// called, while the dialog and its TextField are still mounted playing the
// exit animation, so the field rebuilt against a dead controller:
//
//   A TextEditingController was used after being disposed.
//
// Reported from a device, on Cancel, every time. The dialog owns its
// controller now, so the lifetime is the widget's.
//
// This is worth a widget test rather than a second careful reading, because
// the failure needs a real animation frame between the pop and the disposal —
// no amount of looking at the function shows it.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pourfect_flutter_app/ui/screens/settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  /// Scrolls the row into existence, then opens the box.
  ///
  /// The list is lazy, so the row is not merely off-screen — it has not been
  /// built, and `ensureVisible` cannot reach what does not exist yet.
  Future<void> openRenameBox(WidgetTester tester) async {
    await tester.scrollUntilVisible(
      find.text('Change your name'),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Change your name'));
    await tester.pumpAndSettle();
  }

  Future<void> pumpSettings(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(home: SettingsScreen(onClose: () {})),
      ),
    );
    // Several providers restore from disk; let them settle before touching
    // anything, the way a real launch does.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  testWidgets('cancelling the rename box disposes nothing too early',
      (tester) async {
    await pumpSettings(tester);

    await openRenameBox(tester);

    expect(
      find.byType(TextField),
      findsOneWidget,
      reason: 'the rename box did not open',
    );

    await tester.tap(find.text('Cancel'));

    // NOT pumpAndSettle in one go — the crash happened DURING the exit
    // animation, so the frames in between are the ones that matter.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(TextField), findsNothing);
  });

  testWidgets('dismissing by tapping outside is the same path', (tester) async {
    // The barrier pops the route without going through Cancel, so it is a
    // second way into the same disposal window.
    await pumpSettings(tester);

    await openRenameBox(tester);

    await tester.tapAt(const Offset(10, 10));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('a name too short cannot be saved', (tester) async {
    await pumpSettings(tester);

    await openRenameBox(tester);

    await tester.enterText(find.byType(TextField), 'a');
    await tester.pump();

    expect(find.text('At least 2 characters.'), findsOneWidget);

    // Tapping Save must do nothing at all — not close, not send.
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(
      find.byType(TextField),
      findsOneWidget,
      reason: 'a refused name closed the box anyway',
    );
    expect(tester.takeException(), isNull);
  });
}

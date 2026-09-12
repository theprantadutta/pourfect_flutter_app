// The hub builds, and says only what is true.
//
// A screen this central needs a test that merely PUMPS it. A provider that
// throws inside a release build renders as a blank grey rectangle rather than
// a red error box, and the exception names only the provider — nothing points
// at the screen that vanished. That cost a whole settings screen once here,
// and this one is the first thing every player sees.
//
// The rest is copy discipline. An anonymous account already survives a crash;
// what it does not survive is a new phone, and that remains the only promise
// the app is allowed to make about signing in.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pourfect_flutter_app/state/progress_repository.dart';
import 'package:pourfect_flutter_app/state/providers.dart';
import 'package:pourfect_flutter_app/ui/screens/home_screen.dart';
import 'package:pourfect_flutter_app/ui/widgets/player_crest.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../state/account_controller_test.dart' show FakeIdentity;
import '../state/sync_controller_test.dart' show levelWith;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  late List<String> tapped;

  Future<ProviderContainer> pump(
    WidgetTester tester, {
    FakeIdentity? identity,
  }) async {
    tapped = [];
    final container = ProviderContainer(
      overrides: [
        identityProvider.overrideWithValue(identity ?? FakeIdentity()),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: HomeScreen(
            onContinue: (l) => tapped.add('continue:$l'),
            onOpenLevels: () => tapped.add('levels'),
            onOpenDaily: () => tapped.add('daily'),
            onOpenStatistics: () => tapped.add('stats'),
            onOpenLeaderboard: () => tapped.add('ranks'),
            onOpenSettings: () => tapped.add('settings'),
            onOpenAccount: () => tapped.add('account'),
          ),
        ),
      ),
    );
    await tester.pump();
    return container;
  }

  testWidgets('it builds, rather than vanishing', (tester) async {
    await pump(tester);

    expect(find.text('Continue'), findsOneWidget);
    expect(find.byType(PlayerCrest), findsOneWidget);
    expect(find.text('Levels'), findsOneWidget);
    expect(find.text('Stats'), findsOneWidget);
    expect(find.text('Ranks'), findsOneWidget);
  });

  testWidgets('a guest is invited, not warned', (tester) async {
    await pump(tester);

    expect(find.text('Playing as a guest'), findsOneWidget);
    // The honest claim and the whole of it. "Safe" and "backed up" would both
    // promise more than an account provides.
    expect(find.textContaining('change phones'), findsOneWidget);
    expect(find.textContaining('backed up'), findsNothing);
    expect(find.textContaining('safe'), findsNothing);
  });

  testWidgets('Continue names the level and goes straight to the board',
      (tester) async {
    final container = await pump(tester);
    final next = container.read(progressProvider.notifier).furthestUnlocked;

    expect(find.text('Level $next'), findsOneWidget);

    await tester.tap(find.text('Continue'));
    await tester.pump();

    // Straight to the board, not to the list. A returning player should not
    // have to navigate to the thing they opened the app to do.
    expect(tapped, ['continue:$next']);
  });

  testWidgets('the stat strip reports real progress', (tester) async {
    final container = await pump(tester);
    final progress = container.read(progressProvider.notifier);
    await progress.restored;

    progress.record(
      level: levelWith(id: 1),
      levelSetVersion: 1,
      movesUsed: 5,
      elapsedSeconds: 50,
    );
    await tester.pump();

    // Solved count, taken from the campaign rather than invented.
    expect(container.read(progressProvider).length, 1);
    expect(find.text('Solved'), findsOneWidget);
    expect(find.text('Stars'), findsOneWidget);
  });

  testWidgets('a guest tapping their crest is offered an account',
      (tester) async {
    await pump(tester);

    await tester.tap(find.byType(PlayerCrest));
    await tester.pump();

    expect(tapped, ['account']);
  });

  testWidgets('the crest is stable for a seed and differs between seeds',
      (tester) async {
    // It stands in for a player, so it has to be the same one tomorrow — and
    // not the same as the person sitting next to them.
    const a = PlayerCrest(seed: 'uid-alpha');
    const b = PlayerCrest(seed: 'uid-alpha');
    const c = PlayerCrest(seed: 'uid-beta');

    expect(a.debugColorsForTest(), b.debugColorsForTest());
    expect(a.debugColorsForTest(), isNot(c.debugColorsForTest()));
    // Three distinct balls, never a repeat.
    expect(a.debugColorsForTest().toSet(), hasLength(3));
  });
}

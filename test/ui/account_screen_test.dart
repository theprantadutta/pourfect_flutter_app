// The account screen renders, and says only what is true.
//
// A screen this new needs a test that merely BUILDS it. A provider that throws
// inside a release build renders as a blank grey rectangle rather than a red
// error box, and the exception names only the provider — nothing points at the
// screen that vanished. That cost a whole settings screen once here; the cheap
// defence is a widget test that pumps it.
//
// The other half is the copy. An anonymous account already survives a crash;
// what it does not survive is a new phone, and that is the only promise this
// screen is allowed to make.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pourfect_flutter_app/services/api/identity.dart';
import 'package:pourfect_flutter_app/state/account_controller.dart';
import 'package:pourfect_flutter_app/state/progress_repository.dart';
import 'package:pourfect_flutter_app/state/providers.dart';
import 'package:pourfect_flutter_app/ui/screens/account_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Records what was asked of it and never touches Firebase.
class StubIdentity implements Identity {
  StubIdentity({this.result = const IdentityResult.ok()});

  IdentityResult result;

  /// What the existing-account path returns, when it differs from [result].
  IdentityResult? existingAccountResult;

  final calls = <String>[];

  @override
  bool get isReady => true;

  @override
  IdentitySnapshot? get current =>
      const IdentitySnapshot(uid: 'u', isAnonymous: true);

  @override
  Stream<IdentitySnapshot?> get changes =>
      const Stream<IdentitySnapshot?>.empty();

  @override
  Future<IdentityResult> continueWithGoogle() async {
    calls.add('google');
    return result;
  }

  @override
  Future<IdentityResult> signInToExistingGoogleAccount() async {
    calls.add('existingGoogle');
    return existingAccountResult ?? result;
  }

  @override
  Future<IdentityResult> createWithEmail(String email, String password) async {
    calls.add('create:$email');
    return result;
  }

  @override
  Future<IdentityResult> signInWithEmail(String email, String password) async {
    calls.add('signIn:$email');
    return result;
  }

  @override
  Future<IdentityResult> sendPasswordReset(String email) async {
    calls.add('reset:$email');
    return result;
  }

  @override
  Future<void> signOut() async => calls.add('signOut');

  @override
  Future<IdentityResult> deleteAccount() async {
    calls.add('delete');
    return result;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<StubIdentity> pump(WidgetTester tester, {StubIdentity? identity}) async {
    final stub = identity ?? StubIdentity();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [identityProvider.overrideWithValue(stub)],
        // PourfectTokens.of falls back to the shipped dark theme when the
        // extension is absent, which is exactly what the real app installs.
        child: const MaterialApp(home: AccountScreen()),
      ),
    );
    await tester.pump();
    return stub;
  }

  testWidgets('a signed-in player is NOT asked to sign in again',
      (tester) async {
    // Reported from a device: Settings showed the email correctly, but tapping
    // the crest on the home screen opened this screen still offering "Continue
    // with Google". Settings only ever got it right because ITS entry point is
    // conditional — the row is hidden once signed in — while the crest opens
    // this screen unconditionally. So the screen itself has to know.
    final stub = StubIdentity();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          identityProvider.overrideWithValue(stub),
          accountProvider.overrideWith(() => _SignedInAccount()),
        ],
        child: const MaterialApp(home: AccountScreen()),
      ),
    );
    await tester.pump();

    expect(find.text('Your account'), findsOneWidget);
    expect(
      find.text('Continue with Google'),
      findsNothing,
      reason: 'offered a sign-in to somebody already signed in',
    );
    expect(find.text('player@example.com'), findsOneWidget);
    expect(find.text('Amber_Cascade_1284'), findsOneWidget);
  });

  testWidgets('it builds, rather than vanishing', (tester) async {
    await pump(tester);

    expect(find.text('Save your progress'), findsOneWidget);
    expect(find.text('Continue with Google'), findsOneWidget);
    expect(find.text('Create account'), findsOneWidget);
  });

  testWidgets('the promise is a new phone, never safety', (tester) async {
    await pump(tester);

    // An anonymous account already survives a crash. Claiming anything
    // stronger than device transfer would be a lie the audit called out.
    expect(find.textContaining('change phones'), findsNothing);
    expect(
      find.textContaining('new phone'),
      findsOneWidget,
      reason: 'the screen did not say the one thing an account actually buys',
    );
    expect(
      find.textContaining('backed up'),
      findsNothing,
      reason: 'promised more durability than an account provides',
    );
  });

  testWidgets('a short password is refused before Firebase sees it',
      (tester) async {
    final stub = await pump(tester);

    await tester.enterText(find.byType(TextFormField).first, 'a@b.com');
    await tester.enterText(find.byType(TextFormField).last, 'short');
    await tester.tap(find.text('Create account'));
    await tester.pump();

    expect(find.text('At least 8 characters.'), findsOneWidget);
    expect(stub.calls, isEmpty);
  });

  testWidgets('the length rule applies to CREATING a password, not using one',
      (tester) async {
    // Enforcing it at sign-in would lock out anybody whose existing password
    // is shorter than a rule invented after they chose it.
    final stub = await pump(tester);

    await tester.tap(find.text('Already have an account? Sign in'));
    await tester.pump();

    await tester.enterText(find.byType(TextFormField).first, 'a@b.com');
    await tester.enterText(find.byType(TextFormField).last, 'short');
    await tester.tap(find.text('Sign in'));
    await tester.pump();

    expect(find.text('At least 8 characters.'), findsNothing);
    expect(stub.calls, contains('signIn:a@b.com'));
  });

  testWidgets('a switched-off sign-in method is not reported as a network fault',
      (tester) async {
    // Email/Password is OFF by default on a new Firebase project, and Firebase
    // says `operation-not-allowed`. That used to fall through to the catch-all
    // and read "could not reach the server" — which is wrong twice over: the
    // network is fine, and retrying can never help. It also sends whoever is
    // debugging a fresh environment at the wrong layer entirely.
    final stub = StubIdentity(
      result: const IdentityResult(
        IdentityOutcome.methodNotEnabled,
        message: 'This operation is not allowed.',
      ),
    );
    await pump(tester, identity: stub);

    await tester.enterText(find.byType(TextFormField).first, 'a@b.com');
    await tester.enterText(find.byType(TextFormField).last, 'longenoughpw');
    await tester.tap(find.text('Create account'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Could not reach the server'),
      findsNothing,
      reason: 'blamed the network for a console setting',
    );
    expect(find.textContaining('not available right now'), findsOneWidget);
  });

  testWidgets('a wrong password is explained in the app\'s own words',
      (tester) async {
    final stub = StubIdentity(
      result: const IdentityResult(
        IdentityOutcome.wrongPassword,
        message: 'FIREBASE_INTERNAL: INVALID_LOGIN_CREDENTIALS',
      ),
    );
    await pump(tester, identity: stub);

    await tester.tap(find.text('Already have an account? Sign in'));
    await tester.pump();
    await tester.enterText(find.byType(TextFormField).first, 'a@b.com');
    await tester.enterText(find.byType(TextFormField).last, 'whatever');
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();

    expect(find.text('That email and password do not match.'), findsOneWidget);
    // Firebase's own wording is written for developers and names internals.
    expect(find.textContaining('FIREBASE_INTERNAL'), findsNothing);
  });

  testWidgets('a taken credential names the cost in the dialog', (tester) async {
    // There is no merge -- Firebase cannot combine two uids -- so continuing
    // abandons the progress on this device. The player has to be told, and the
    // three cleared levels seeded here are what make the warning apply.
    final stub = StubIdentity(
      result: const IdentityResult(
        IdentityOutcome.credentialBelongsToAnotherAccount,
      ),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          identityProvider.overrideWithValue(stub),
          progressProvider.overrideWith(_ThreeSolved.new),
        ],
        child: const MaterialApp(home: AccountScreen()),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('Continue with Google'));
    await tester.pumpAndSettle();

    expect(find.textContaining('cannot be combined'), findsOneWidget);
    expect(find.textContaining('3 solved levels'), findsOneWidget);
  });

  testWidgets('a reset says the same thing for any address', (tester) async {
    final stub = StubIdentity(
      result: const IdentityResult(IdentityOutcome.noSuchAccount),
    );
    await pump(tester, identity: stub);

    await tester.tap(find.text('Already have an account? Sign in'));
    await tester.pump();
    await tester.enterText(find.byType(TextFormField).first, 'nobody@example.com');
    await tester.tap(find.text('Forgot your password?'));
    await tester.pumpAndSettle();

    // "No account with that address" is what somebody probing for registered
    // emails is hoping to hear.
    expect(find.textContaining('If that email has an account'), findsOneWidget);
    expect(find.textContaining('do not match'), findsNothing);
  });

  group('the account that already exists', () {
    testWidgets('is offered straight away, without hunting for a button',
        (tester) async {
      // It used to raise a button further down the screen. With the error text
      // present that button fell below the fold on a phone, so the action
      // almost everybody wants was the one you had to scroll to find.
      final stub = StubIdentity(
        result: const IdentityResult(
          IdentityOutcome.credentialBelongsToAnotherAccount,
        ),
      );
      await pump(tester, identity: stub);

      await tester.tap(find.text('Continue with Google'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('You already have an account'), findsOneWidget);
      expect(find.text('Use that account'), findsOneWidget);
    });

    testWidgets('a fresh device is NOT warned about losing anything',
        (tester) async {
      // THE REINSTALL CASE. Nothing on this phone to lose -- that is the whole
      // reason they are here -- so a sentence about leaving progress behind
      // describes a loss that cannot happen, and talks somebody out of
      // claiming the account the cloud save exists for.
      final stub = StubIdentity(
        result: const IdentityResult(
          IdentityOutcome.credentialBelongsToAnotherAccount,
        ),
      );
      await pump(tester, identity: stub);

      await tester.tap(find.text('Continue with Google'));
      await tester.pumpAndSettle();

      expect(find.textContaining('load the stars'), findsOneWidget);
      expect(find.textContaining('cannot be combined'), findsNothing);
    });

    testWidgets('confirming joins the Google account', (tester) async {
      final stub = StubIdentity(
        result: const IdentityResult(
          IdentityOutcome.credentialBelongsToAnotherAccount,
        ),
      );
      stub.existingAccountResult = const IdentityResult.ok();
      await pump(tester, identity: stub);

      await tester.tap(find.text('Continue with Google'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Use that account'));
      await tester.pumpAndSettle();

      expect(stub.calls, contains('existingGoogle'));
    });

    testWidgets('declining leaves the reason on screen', (tester) async {
      // Saying no must not leave a form that refused somebody without
      // explaining itself.
      final stub = StubIdentity(
        result: const IdentityResult(
          IdentityOutcome.credentialBelongsToAnotherAccount,
        ),
      );
      await pump(tester, identity: stub);

      await tester.tap(find.text('Continue with Google'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Not now'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      expect(find.textContaining('already have an account'), findsOneWidget);
      expect(stub.calls, isNot(contains('existingGoogle')));
    });

    testWidgets('the EMAIL path reuses the password already typed',
        (tester) async {
      // They typed the password for the account they want before pressing the
      // wrong button. Making them type it again would be the whole point of
      // the dialog, missed.
      final stub = StubIdentity(
        result: const IdentityResult(
          IdentityOutcome.credentialBelongsToAnotherAccount,
        ),
      );
      await pump(tester, identity: stub);

      await tester.enterText(find.byType(TextFormField).first, 'a@b.com');
      await tester.enterText(find.byType(TextFormField).last, 'password123');
      await tester.tap(find.text('Create account'));
      await tester.pumpAndSettle();

      expect(find.text('Sign in'), findsWidgets);
      await tester.tap(find.widgetWithText(TextButton, 'Sign in'));
      await tester.pumpAndSettle();

      // Signed in with what was already in the form, not a Google chooser.
      expect(stub.calls, contains('signIn:a@b.com'));
      expect(stub.calls, isNot(contains('existingGoogle')));
    });
  });
}

/// An account that is already signed in.
class _SignedInAccount extends AccountController {
  @override
  AccountState build() => const AccountState(
    available: true,
    signedIn: true,
    email: 'player@example.com',
    handle: 'Amber_Cascade_1284',
    userId: 'uid-1',
  );
}

/// A device with three cleared levels, so the "you would lose this" branch has
/// something to be about.
class _ThreeSolved extends ProgressController {
  @override
  Map<int, LevelProgress> build() => {
    for (var i = 1; i <= 3; i++)
      i: LevelProgress(
        levelId: i,
        levelSetVersion: 1,
        stars: 3,
        bestMoves: 5,
      ),
  };
}

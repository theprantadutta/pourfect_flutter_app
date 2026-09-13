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

  testWidgets('a taken credential names the cost instead of retrying',
      (tester) async {
    // There is no merge — Firebase cannot combine two uids — so continuing
    // abandons the progress on this device. The player has to be told.
    final stub = StubIdentity(
      result: const IdentityResult(
        IdentityOutcome.credentialBelongsToAnotherAccount,
      ),
    );
    await pump(tester, identity: stub);

    await tester.tap(find.text('Continue with Google'));
    await tester.pumpAndSettle();

    expect(find.textContaining('cannot be merged'), findsOneWidget);
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
}

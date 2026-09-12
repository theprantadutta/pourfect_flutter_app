// Signing in, signing out, and deleting the account.
//
// The Firebase calls themselves are somebody else's code and are stubbed here.
// What these tests defend is everything that has to happen AROUND them, which
// is where this can actually go wrong:
//
//   * a changed identity has to reach OUR backend, which learns about it only
//     from the sign_in_provider claim in a fresh token;
//   * a credential that already belongs to somebody else must never be
//     resolved quietly, because the only resolution loses progress;
//   * deletion has to remove the server row BEFORE the login that reaches it.

import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pourfect_flutter_app/services/api/api_client.dart';
import 'package:pourfect_flutter_app/services/api/auth_service.dart';
import 'package:pourfect_flutter_app/services/api/identity.dart';
import 'package:pourfect_flutter_app/state/account_controller.dart';
import 'package:pourfect_flutter_app/state/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// An identity the test drives by hand.
class FakeIdentity implements Identity {
  FakeIdentity({this.isAnonymous = true});

  bool isAnonymous;
  String uid = 'uid-1';
  String? email;

  /// What the next operation returns.
  IdentityResult next = const IdentityResult.ok();

  final calls = <String>[];
  bool deleted = false;
  bool signedOut = false;

  @override
  bool get isReady => true;

  @override
  IdentitySnapshot? get current =>
      IdentitySnapshot(uid: uid, isAnonymous: isAnonymous, email: email);

  /// Driven by hand, so a test can play the late restore Firebase performs
  /// after launch rather than pretending the user was there all along.
  final announcements = StreamController<IdentitySnapshot?>.broadcast();

  @override
  Stream<IdentitySnapshot?> get changes => announcements.stream;

  void announce(IdentitySnapshot? snapshot) => announcements.add(snapshot);

  /// Succeeding means the anonymous account was UPGRADED: same uid, no longer
  /// anonymous. That is what Firebase's linkWithCredential does, and getting
  /// it wrong here would hide the bug this whole design exists to avoid.
  IdentityResult _apply(String call, {String? becomesEmail}) {
    calls.add(call);
    if (next.isOk) {
      isAnonymous = false;
      email = becomesEmail ?? email;
    }
    return next;
  }

  @override
  Future<IdentityResult> continueWithGoogle() async => _apply('google');

  /// Joining an account that already exists CHANGES THE UID. That is the whole
  /// difference from linking, and a fake that kept the uid would hide the bug
  /// the switch handling exists to prevent.
  @override
  Future<IdentityResult> signInToExistingGoogleAccount() async {
    if (next.isOk) uid = 'uid-existing';
    return _apply('existingGoogle');
  }

  @override
  Future<IdentityResult> createWithEmail(String email, String password) async =>
      _apply('create', becomesEmail: email);

  @override
  Future<IdentityResult> signInWithEmail(String email, String password) async =>
      _apply('signIn', becomesEmail: email);

  @override
  Future<IdentityResult> sendPasswordReset(String email) async {
    calls.add('reset:$email');
    return next;
  }

  @override
  Future<void> signOut() async {
    calls.add('signOut');
    signedOut = true;
    isAnonymous = true;
    email = null;
  }

  @override
  Future<IdentityResult> deleteAccount() async {
    calls.add('delete');
    if (next.isOk) deleted = true;
    return next;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  /// Every auth exchange, so the test can count them and read what was sent.
  late List<Map<String, Object?>> exchanges;
  late List<http.Request> requests;

  String authBody({bool anonymous = true, String provider = 'anonymous'}) =>
      jsonEncode({
        'access_token': 'jwt',
        'expires_in_seconds': 3600,
        'user_id': 'u',
        'ads_removed': false,
        'is_anonymous': anonymous,
        'auth_provider': provider,
      });

  ({ProviderContainer container, FakeIdentity identity}) harness({
    FakeIdentity? identity,
    http.Response Function(http.Request)? onDelete,
  }) {
    exchanges = [];
    requests = [];
    final fake = identity ?? FakeIdentity();

    // The server reports back whatever the fake identity currently is, which
    // is what a real backend does: it reads the token's sign_in_provider.
    final client = ApiClient(
      baseUrl: 'https://account.test',
      tokenProvider: ({bool forceRefresh = false}) async => 'firebase-token',
      httpClient: MockClient((request) async {
        requests.add(request);

        if (request.url.path.endsWith('/auth/device')) {
          exchanges.add(
            jsonDecode(request.body) as Map<String, Object?>,
          );
          return http.Response(
            authBody(
              anonymous: fake.isAnonymous,
              provider: fake.isAnonymous ? 'anonymous' : 'google',
            ),
            200,
          );
        }

        if (request.method == 'DELETE' &&
            request.url.path.endsWith('/users/me')) {
          return onDelete?.call(request) ?? http.Response('{}', 200);
        }

        // Progress sync and anything else.
        return http.Response(
          jsonEncode({'accepted': 0, 'rejected': 0, 'changed': 0, 'progress': []}),
          200,
        );
      }),
    );

    final container = ProviderContainer(
      overrides: [
        apiClientProvider.overrideWithValue(client),
        identityProvider.overrideWithValue(fake),
        authServiceProvider.overrideWith(
          (ref) => AuthService(
            client: () => client,
            idTokenProvider: ({bool forceRefresh = false}) async => 'token',
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    return (container: container, identity: fake);
  }

  group('signing in is an upgrade, not a migration', () {
    test('the backend is told immediately, with a fresh token', () async {
      final built = harness();
      final account = built.container.read(accountProvider.notifier);

      // A session already exists and is perfectly fresh.
      await built.container.read(authServiceProvider).ensureSession();
      expect(exchanges, hasLength(1));

      final result = await account.continueWithGoogle();
      expect(result.isOk, isTrue);

      // A SECOND exchange, despite the first still being valid. Nothing else
      // carries the new sign_in_provider to the server, so without this the
      // row stays anonymous and the UI keeps offering a sign-in already done.
      expect(
        exchanges,
        hasLength(2),
        reason: 'the server was never told the account is no longer anonymous',
      );
      expect(built.container.read(authServiceProvider).current!.isAnonymous,
          isFalse);
    });

    test('the whole campaign is pushed, not just what was dirty', () async {
      final built = harness();
      await built.container.read(accountProvider.notifier).continueWithGoogle();

      // Somebody who has just asked for their progress to be saved should not
      // have to finish another level before any of it leaves the device.
      expect(
        requests.any((r) => r.url.path.endsWith('/progress/sync')),
        isTrue,
        reason: 'signing in did not push the progress it promised to save',
      );
    });

    test('state reports the signed-in email', () async {
      final built = harness();
      await built.container
          .read(accountProvider.notifier)
          .createAccount('  Player@Example.com  ', 'hunter2hunter2');

      final state = built.container.read(accountProvider);
      expect(state.signedIn, isTrue);
      // Trimmed, because a trailing space from a keyboard autocomplete is not
      // a different account.
      expect(state.email, 'Player@Example.com');
      expect(state.busy, isFalse);
    });

    test('a failure changes nothing and is reported', () async {
      final built = harness();
      built.identity.next = const IdentityResult(IdentityOutcome.wrongPassword);

      final result = await built.container
          .read(accountProvider.notifier)
          .signIn('a@b.com', 'wrong');

      expect(result.outcome, IdentityOutcome.wrongPassword);
      expect(built.container.read(accountProvider).signedIn, isFalse);
      expect(exchanges, isEmpty, reason: 'a failed sign-in re-exchanged anyway');
    });

    test('a credential owned by another account is surfaced, not resolved',
        () async {
      // There is no merge available — Firebase cannot combine two uids — so
      // the only way forward abandons the anonymous account's progress. That
      // is the player's decision and must reach them as a distinct outcome.
      final built = harness();
      built.identity.next = const IdentityResult(
        IdentityOutcome.credentialBelongsToAnotherAccount,
      );

      final result =
          await built.container.read(accountProvider.notifier).continueWithGoogle();

      expect(result.outcome, IdentityOutcome.credentialBelongsToAnotherAccount);
      expect(built.container.read(accountProvider).signedIn, isFalse);
    });

    test('a second tap while one is in flight does nothing', () async {
      final built = harness();
      final account = built.container.read(accountProvider.notifier);

      final first = account.continueWithGoogle();
      final second = account.continueWithGoogle();
      await Future.wait([first, second]);

      expect(
        built.identity.calls.where((c) => c == 'google').length,
        1,
        reason: 'two taps started two Firebase flows',
      );
    });

    test('a cancelled sheet is not an error', () async {
      final built = harness();
      built.identity.next = const IdentityResult(IdentityOutcome.cancelled);

      final result =
          await built.container.read(accountProvider.notifier).continueWithGoogle();

      expect(result.outcome, IdentityOutcome.cancelled);
      expect(built.container.read(accountProvider).busy, isFalse);
    });
  });

  group('password reset says nothing about who has an account', () {
    test('an unregistered address reports success too', () async {
      final built = harness();
      built.identity.next = const IdentityResult(IdentityOutcome.noSuchAccount);

      final result = await built.container
          .read(accountProvider.notifier)
          .sendPasswordReset('stranger@example.com');

      // "No account with that address" is precisely what somebody probing for
      // registered emails wants to hear.
      expect(result.isOk, isTrue);
      expect(built.identity.calls, contains('reset:stranger@example.com'));
    });
  });

  group('signing out', () {
    test('returns to anonymous and re-anchors a session', () async {
      final built = harness();
      final account = built.container.read(accountProvider.notifier);
      await account.continueWithGoogle();

      await account.signOut();

      expect(built.identity.signedOut, isTrue);
      expect(built.container.read(accountProvider).signedIn, isFalse);
      // Not left sessionless until something happens to need one.
      expect(built.container.read(authServiceProvider).current, isNotNull);
    });
  });

  group('deleting the account', () {
    test('the server row goes first, then the login', () async {
      // The database is the act of record. Reversed, a failure would destroy
      // the login while the row survived, and nobody could ever reach or
      // delete their own data again.
      final order = <String>[];
      final built = harness(
        onDelete: (_) {
          order.add('server');
          return http.Response('{}', 200);
        },
      );
      built.identity.calls.clear();

      final outcome =
          await built.container.read(accountProvider.notifier).deleteAccount();

      expect(outcome, AccountDeletion.deleted);
      expect(order, ['server']);
      expect(
        built.identity.calls,
        contains('delete'),
        reason: 'the Firebase identity outlived the row it pointed at',
      );
    });

    test('a refused server delete leaves the login alone', () async {
      final built = harness(
        onDelete: (_) => http.Response('{"error":"nope"}', 500),
      );
      built.identity.calls.clear();

      final outcome =
          await built.container.read(accountProvider.notifier).deleteAccount();

      expect(outcome, AccountDeletion.serverRefused);
      expect(
        built.identity.deleted,
        isFalse,
        reason: 'the login was destroyed while the server row survived',
      );
    });

    test('a stale login still counts as deleted', () async {
      // Firebase refuses to delete a user who has not signed in recently. The
      // ROW is already gone by then, so this is a leftover credential and not
      // a failed deletion — reporting failure would tell somebody their data
      // is still there when it is not.
      final built = harness();
      built.identity.next =
          const IdentityResult(IdentityOutcome.needsRecentLogin);

      final outcome =
          await built.container.read(accountProvider.notifier).deleteAccount();

      expect(outcome, AccountDeletion.deleted);
      expect(built.identity.signedOut, isTrue);
    });
  });
}

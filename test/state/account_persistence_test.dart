// Coming back to the app and still being yourself.
//
// Reported from a device: "I logged in with google, and now my account is gone
// after the app restarted." Nothing was gone. `adb shell run-as` showed the
// stored session sitting on disk with `is_anonymous = False` and
// `auth_provider = google`, and the Firebase credential was intact — the SCREEN
// was wrong, and it was wrong for the whole session because nothing ever asked
// again.
//
// Two independent causes, either of which is enough on its own:
//
//   * `AccountController` sampled `identity.current` once during build, and
//     Firebase restores its user asynchronously after launch, so the sample is
//     null on a cold start;
//   * nothing called `AuthService.restore()`, so the session on disk was not
//     read until some later sync happened to need a token — and `AuthService`
//     sits behind a plain Provider, which cannot tell a widget it changed.
//
// So both halves are pinned here: the state has to arrive at signed-in without
// the network, and it has to keep up with an identity that shows up late.

import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pourfect_flutter_app/services/api/api_client.dart';
import 'package:pourfect_flutter_app/services/api/auth_service.dart';
import 'package:pourfect_flutter_app/services/api/identity.dart';
import 'package:pourfect_flutter_app/services/api/session.dart';
import 'package:pourfect_flutter_app/state/account_controller.dart';
import 'package:pourfect_flutter_app/state/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// An identity that starts EMPTY, the way Firebase does on a cold start.
///
/// The fake that reports a user the instant it is asked is the fake that hides
/// this bug: the whole failure lives in the gap between the first frame and
/// Firebase finishing its own restore.
class LateIdentity implements Identity {
  IdentitySnapshot? _current;
  final _announcements = StreamController<IdentitySnapshot?>.broadcast();

  @override
  bool get isReady => true;

  @override
  IdentitySnapshot? get current => _current;

  @override
  Stream<IdentitySnapshot?> get changes => _announcements.stream;

  /// Firebase finishing its restore, some frames after launch.
  void arrive(IdentitySnapshot? snapshot) {
    _current = snapshot;
    _announcements.add(snapshot);
  }

  @override
  Future<IdentityResult> continueWithGoogle() async =>
      const IdentityResult.ok();

  @override
  Future<IdentityResult> signInToExistingGoogleAccount() async =>
      const IdentityResult.ok();

  @override
  Future<IdentityResult> createWithEmail(String email, String password) async =>
      const IdentityResult.ok();

  @override
  Future<IdentityResult> signInWithEmail(String email, String password) async =>
      const IdentityResult.ok();

  @override
  Future<IdentityResult> sendPasswordReset(String email) async =>
      const IdentityResult.ok();

  @override
  Future<void> signOut() async {}

  @override
  Future<IdentityResult> deleteAccount() async => const IdentityResult.ok();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// The session a returning player already has on their phone.
  Session storedSession({bool anonymous = false}) => Session(
    accessToken: 'jwt-from-last-launch',
    expiresAt: DateTime.now().add(const Duration(days: 30)),
    userId: '01a08602-6531-7c14-a087-2ec92ec453c1',
    displayName: null,
    adsRemoved: false,
    isAnonymous: anonymous,
    authProvider: anonymous ? 'anonymous' : 'google',
  );

  /// A container with nothing but a disk, and a server that refuses to answer.
  ///
  /// The refusal is deliberate. A returning player opens the app on a train,
  /// and "signed in" must not be something the app can only work out by asking
  /// permission from a network it may not have.
  ({ProviderContainer container, LateIdentity identity, int Function() calls})
  harness({Session? onDisk}) {
    SharedPreferences.setMockInitialValues(
      onDisk == null
          ? {}
          : {'pourfect.session.v1': jsonEncode(onDisk.toJson())},
    );

    var calls = 0;
    final identity = LateIdentity();

    final client = ApiClient(
      baseUrl: 'https://account.test',
      tokenProvider: ({bool forceRefresh = false}) async => 'firebase-token',
      httpClient: MockClient((request) async {
        calls++;
        return http.Response('{}', 503);
      }),
    );

    final container = ProviderContainer(
      overrides: [
        apiClientProvider.overrideWithValue(client),
        identityProvider.overrideWithValue(identity),
        authServiceProvider.overrideWith(
          (ref) => AuthService(
            client: () => client,
            idTokenProvider: ({bool forceRefresh = false}) async => 'token',
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    return (container: container, identity: identity, calls: () => calls);
  }

  /// The first frame: the provider is built, and nothing has resolved yet.
  ///
  /// Reading it is what BUILDS it, and build is what starts the disk read and
  /// subscribes to the identity — so a test that awaits before its first read
  /// awaits nothing and then misses whatever it announced in between.
  AccountState firstFrame(ProviderContainer container) =>
      container.read(accountProvider);

  group('a returning player is still signed in', () {
    test('the session on disk is enough, with no network at all', () async {
      final built = harness(onDisk: storedSession());

      // The first frame. Firebase has not restored anybody yet, which is the
      // normal state of affairs a few hundred milliseconds into a launch.
      expect(firstFrame(built.container).signedIn, isFalse);

      // The disk read lands. This is a local file, not a round trip.
      await Future<void>.delayed(Duration.zero);

      expect(
        built.container.read(accountProvider).signedIn,
        isTrue,
        reason: 'the stored session says google, and the screen said guest',
      );
      expect(
        built.container.read(accountProvider).userId,
        '01a08602-6531-7c14-a087-2ec92ec453c1',
        reason: 'the crest has nothing to draw itself from',
      );
      expect(
        built.calls(),
        isZero,
        reason: 'being signed in must not depend on reaching the server',
      );
    });

    test('a late Firebase restore reaches the state', () async {
      final built = harness();
      expect(firstFrame(built.container).signedIn, isFalse);
      await Future<void>.delayed(Duration.zero);

      // Firebase finishes reading its own store and reports the user that was
      // there all along. The old code sampled `current` before this happened
      // and never looked again.
      built.identity.arrive(
        const IdentitySnapshot(
          uid: 'uid-google',
          isAnonymous: false,
          email: 'player@example.com',
        ),
      );
      await Future<void>.delayed(Duration.zero);

      final state = built.container.read(accountProvider);
      expect(state.signedIn, isTrue);
      expect(state.email, 'player@example.com');
    });

    test('an anonymous session does not claim a sign-in', () async {
      final built = harness(onDisk: storedSession(anonymous: true));
      firstFrame(built.container);
      await Future<void>.delayed(Duration.zero);

      final state = built.container.read(accountProvider);
      expect(state.signedIn, isFalse);
      // The account is still known — an anonymous player has a uid and a
      // crest, they simply have nothing protecting it.
      expect(state.userId, isNotNull);
    });

    test('a stale anonymous session cannot demote a live sign-in', () async {
      // The order that used to flicker: the identity is known first, and the
      // session read off disk is the one from BEFORE the sign-in, so it still
      // says anonymous. Believing it would put the screen back to guest.
      final built = harness(onDisk: storedSession(anonymous: true));
      firstFrame(built.container);

      built.identity.arrive(
        const IdentitySnapshot(uid: 'uid-google', isAnonymous: false),
      );
      await Future<void>.delayed(Duration.zero);

      expect(
        built.container.read(accountProvider).signedIn,
        isTrue,
        reason: 'a session that has not been re-exchanged yet signed them out',
      );
    });

    test('signing out is still believed', () async {
      final built = harness(onDisk: storedSession());
      firstFrame(built.container);
      await Future<void>.delayed(Duration.zero);
      expect(built.container.read(accountProvider).signedIn, isTrue);

      // Promote-only applies to the SESSION, not to the identity. A real
      // sign-out has to land, or the screen becomes a liar in the other
      // direction.
      built.identity.arrive(
        const IdentitySnapshot(uid: 'uid-anon', isAnonymous: true),
      );
      await Future<void>.delayed(Duration.zero);

      expect(built.container.read(accountProvider).signedIn, isFalse);
    });
  });
}

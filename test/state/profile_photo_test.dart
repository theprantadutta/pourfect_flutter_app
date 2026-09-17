// The profile picture: whose it is, where it is allowed to go, and what is
// drawn when there isn't one.
//
// The picture is the first piece of provider data this app shows back to the
// player, and the rule around it is narrow on purpose. It travels on the
// session, which belongs to this device, and it reaches this player's own
// crest. It is NOT on a leaderboard row — a picture shown to its owner is not
// a disclosure and the same picture on a public board is, which is the same
// line the server already draws for `ProfileName`.
//
// The other half is that null is ORDINARY. Anonymous and email accounts have
// no picture at all, so the generated ball has to be the normal case rather
// than a placeholder, and there must be no state in which the crest is a hole.

import 'dart:convert';

import 'package:flutter/material.dart';
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
import 'package:pourfect_flutter_app/ui/widgets/ball.dart';
import 'package:pourfect_flutter_app/ui/widgets/player_crest.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StubIdentity implements Identity {
  @override
  bool get isReady => true;

  @override
  IdentitySnapshot? get current =>
      const IdentitySnapshot(uid: 'uid-1', isAnonymous: false);

  @override
  Stream<IdentitySnapshot?> get changes =>
      const Stream<IdentitySnapshot?>.empty();

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

  const picture = 'https://lh3.googleusercontent.com/a/abc123=s96-c';

  String authBody({String? photo}) => jsonEncode({
    'access_token': 'jwt',
    'expires_in_seconds': 3600,
    'user_id': 'u',
    'display_name': 'Amber_Cascade_1284',
    'ads_removed': false,
    'is_anonymous': false,
    'auth_provider': 'google',
    'show_on_leaderboards': true,
    'photo_url': ?photo,
  });

  // What the stubbed server currently says. Mutable because the point of the
  // switching tests is that the answer CHANGES when the account does — a
  // fixed response would have made them pass without proving anything.
  String? served;

  ProviderContainer harness({String? photo}) {
    SharedPreferences.setMockInitialValues({});
    served = photo;

    final client = ApiClient(
      baseUrl: 'https://photos.test',
      tokenProvider: ({bool forceRefresh = false}) async => 'firebase-token',
      httpClient: MockClient((request) async {
        if (request.url.path.endsWith('/auth/device')) {
          return http.Response(authBody(photo: served), 200);
        }
        return http.Response('{}', 200);
      }),
    );

    final container = ProviderContainer(
      overrides: [
        apiClientProvider.overrideWithValue(client),
        identityProvider.overrideWithValue(StubIdentity()),
        authServiceProvider.overrideWith(
          (ref) => AuthService(
            client: () => client,
            idTokenProvider: ({bool forceRefresh = false}) async => 'token',
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  group('the picture reaches the player it belongs to', () {
    test('a Google account carries its picture into AccountState', () async {
      final container = harness(photo: picture);
      container.read(accountProvider);
      await container.read(authServiceProvider).ensureSession();
      await Future<void>.delayed(Duration.zero);

      expect(container.read(accountProvider).photoUrl, picture);
    });

    test('an account with no picture is null, not empty string', () async {
      // The ORDINARY case, and the one the crest is designed around. An empty
      // string would render as a broken image; null renders as the ball.
      final container = harness();
      container.read(accountProvider);
      await container.read(authServiceProvider).ensureSession();
      await Future<void>.delayed(Duration.zero);

      expect(container.read(accountProvider).photoUrl, isNull);
    });
  });

  group('it survives the round trip it has to survive', () {
    test('a session written to disk and read back keeps the picture', () {
      // The crest is drawn on the FIRST frame of a cold start, off the stored
      // session, before any network call has happened. A picture that only
      // arrived on a live auth response would mean the avatar visibly
      // changed a second after launch, every launch.
      final session = Session(
        accessToken: 'jwt',
        expiresAt: DateTime(2030),
        userId: 'u',
        displayName: 'Amber_Cascade_1284',
        adsRemoved: false,
        isAnonymous: false,
        authProvider: 'google',
        photoUrl: picture,
      );
      final restored = Session.fromJson(session.toJson());

      expect(restored!.photoUrl, picture);
    });

    test('a stored session from before this field is not rejected', () {
      // Every install that already has a session on disk wrote it without
      // `photo_url`. Reading one back must produce a working session with no
      // picture, not a null session that silently signs somebody out.
      final old = {
        'token': 'jwt',
        'expires_at': DateTime(2030).toIso8601String(),
        'user_id': 'u',
        'display_name': 'Amber_Cascade_1284',
        'show_on_leaderboards': true,
        'ads_removed': false,
        'is_anonymous': false,
        'auth_provider': 'google',
        'ads_revoked': false,
      };

      final restored = Session.fromJson(old);

      expect(restored, isNotNull);
      expect(restored!.photoUrl, isNull);
      expect(restored.displayName, 'Amber_Cascade_1284');
    });
  });

  group('it belongs to ONE account', () {
    test('signing out drops the picture', () async {
      // `copyWith` cannot write a null, so a partial reset would leave the
      // previous player's face on the crest of the anonymous account that
      // replaces them. Both exit paths replace the whole state; this is what
      // stops one of them quietly becoming a copyWith later.
      final container = harness(photo: picture);
      container.read(accountProvider);
      await container.read(authServiceProvider).ensureSession();
      await Future<void>.delayed(Duration.zero);
      expect(container.read(accountProvider).photoUrl, picture);

      // Signing out re-anchors on a FRESH anonymous account, which has no
      // picture — so this is what the server says from here on.
      served = null;
      await container.read(accountProvider.notifier).signOut();

      expect(container.read(accountProvider).photoUrl, isNull);
    });

    test("one account's picture never appears on another", () async {
      // THE CASE THAT MATTERS. `copyWith` cannot write a null, so adopting a
      // session with no picture leaves whatever was already there. The only
      // thing standing between that and account B wearing account A's face is
      // that both exit paths replace the entire state rather than patching it.
      final container = harness(photo: picture);
      container.read(accountProvider);
      await container.read(authServiceProvider).ensureSession();
      await Future<void>.delayed(Duration.zero);
      expect(container.read(accountProvider).photoUrl, picture);

      // Somebody else, on the same phone, with no picture of their own.
      served = null;
      await container.read(accountProvider.notifier).signOut();
      await container.read(authServiceProvider).ensureSession();
      await Future<void>.delayed(Duration.zero);

      expect(
        container.read(accountProvider).photoUrl,
        isNull,
        reason: "the previous account's picture survived the switch",
      );
    });
  });

  group('the crest is never a hole', () {
    testWidgets('no picture draws the generated ball', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: PlayerCrest(seed: 'u', signedIn: true)),
      );

      expect(find.byType(Ball), findsOneWidget);
      expect(find.byType(Image), findsNothing);
    });

    testWidgets('a picture that fails to load falls back to the ball', (
      tester,
    ) async {
      // Flutter's test binding answers every image request with a 400, so
      // this exercises the real error path: offline, a dead link, a rotated
      // CDN URL, a revoked Google picture. All of them have to end at the
      // player's ordinary crest rather than a broken-image glyph.
      await tester.pumpWidget(
        const MaterialApp(
          home: PlayerCrest(
            seed: 'u',
            signedIn: true,
            photoUrl: 'https://example.invalid/avatar.png',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(Ball), findsOneWidget);
    });

    testWidgets('an empty string is treated as no picture', (tester) async {
      // Defensive: a server that ever sends "" instead of omitting the field
      // would otherwise produce an Image with no src.
      await tester.pumpWidget(
        const MaterialApp(home: PlayerCrest(seed: 'u', photoUrl: '')),
      );

      expect(find.byType(Ball), findsOneWidget);
      expect(find.byType(Image), findsNothing);
    });
  });
}

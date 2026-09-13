// The leaderboard handle, and the switch that hides it.
//
// Every account is created with a generated handle server-side, so the client
// never invents one and never has to ask for one before a player can appear.
// What it does own is the two controls: renaming, and opting out.
//
// The opt-out is the part that needs tests rather than a reading. A privacy
// switch that moves in the UI on a request the server never accepted tells
// somebody they are hidden while they are still published — and it looks
// exactly like success while doing it.

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

/// An identity that is ready and anonymous — the ordinary state of a player
/// who has never signed in, which is exactly who a generated handle is for.
class StubIdentity implements Identity {
  @override
  bool get isReady => true;

  @override
  IdentitySnapshot? get current =>
      const IdentitySnapshot(uid: 'uid-1', isAnonymous: true);

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

  late List<http.Request> requests;

  String authBody({String? name = 'Amber_Cascade_1284', bool visible = true}) =>
      jsonEncode({
        'access_token': 'jwt',
        'expires_in_seconds': 3600,
        'user_id': 'u',
        'display_name': name,
        'ads_removed': false,
        'is_anonymous': true,
        'auth_provider': 'anonymous',
        'show_on_leaderboards': visible,
      });

  ProviderContainer harness({
    String? handle = 'Amber_Cascade_1284',
    bool visible = true,
    http.Response Function(http.Request)? onVisibility,
    http.Response Function(http.Request)? onRename,
  }) {
    SharedPreferences.setMockInitialValues({});
    requests = [];

    final client = ApiClient(
      baseUrl: 'https://handles.test',
      tokenProvider: ({bool forceRefresh = false}) async => 'firebase-token',
      httpClient: MockClient((request) async {
        requests.add(request);
        final path = request.url.path;

        if (path.endsWith('/auth/device')) {
          return http.Response(authBody(name: handle, visible: visible), 200);
        }
        if (path.endsWith('/users/leaderboard-visibility')) {
          return onVisibility?.call(request) ??
              http.Response(
                jsonEncode({
                  'show_on_leaderboards':
                      jsonDecode(request.body)['visible'] as bool,
                }),
                200,
              );
        }
        if (path.endsWith('/users/display-name')) {
          return onRename?.call(request) ??
              http.Response(
                jsonEncode({
                  'display_name':
                      (jsonDecode(request.body)['display_name'] as String),
                }),
                200,
              );
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

  group('every account arrives with a handle', () {
    test('the generated one reaches the state without anybody typing', () async {
      final container = harness();
      container.read(accountProvider);

      await container.read(authServiceProvider).ensureSession();
      await Future<void>.delayed(Duration.zero);

      expect(
        container.read(accountProvider).handle,
        'Amber_Cascade_1284',
        reason: 'the server named this account and the client ignored it',
      );
      expect(container.read(accountProvider).showOnLeaderboards, isTrue);
    });

    test('an opted-out account is not drawn as listed', () async {
      // The direction that matters. Defaulting to "listed" while the server
      // says otherwise shows somebody a switch that disagrees with reality.
      final container = harness(visible: false);
      container.read(accountProvider);

      await container.read(authServiceProvider).ensureSession();
      await Future<void>.delayed(Duration.zero);

      expect(container.read(accountProvider).showOnLeaderboards, isFalse);
    });
  });

  group('renaming', () {
    test('the state takes the name the SERVER stored, not the one typed',
        () async {
      // The server trims. If the client keeps its own copy the two disagree,
      // and the name on the board is not the name in Settings.
      final container = harness(
        onRename: (_) => http.Response(
          jsonEncode({'display_name': 'Tidied'}),
          200,
        ),
      );
      container.read(accountProvider);
      await container.read(authServiceProvider).ensureSession();

      final problem =
          await container.read(accountProvider.notifier).renameHandle('  Tidied  ');

      expect(problem, isNull);
      expect(container.read(accountProvider).handle, 'Tidied');
    });

    test('a refused name is reported and nothing changes', () async {
      final container = harness(
        onRename: (_) => http.Response(
          jsonEncode({'detail': 'Use letters, numbers and spaces only'}),
          400,
        ),
      );
      container.read(accountProvider);
      await container.read(authServiceProvider).ensureSession();
      await Future<void>.delayed(Duration.zero);

      final problem =
          await container.read(accountProvider.notifier).renameHandle(r'$$$$');

      expect(problem, isNotNull);
      expect(
        container.read(accountProvider).handle,
        'Amber_Cascade_1284',
        reason: 'a rejected name replaced the one that is actually stored',
      );
    });
  });

  group('hiding', () {
    test('the switch moves only once the server has agreed', () async {
      final container = harness();
      container.read(accountProvider);
      await container.read(authServiceProvider).ensureSession();
      await Future<void>.delayed(Duration.zero);

      final ok = await container
          .read(accountProvider.notifier)
          .setLeaderboardVisibility(false);

      expect(ok, isTrue);
      expect(container.read(accountProvider).showOnLeaderboards, isFalse);
    });

    test('a request that never landed leaves the player LISTED', () async {
      // The failure this whole test file exists for. Drawing the switch off on
      // a request the server refused tells somebody they are hidden while
      // their name is still on a public board — and it looks like success.
      final container = harness(
        onVisibility: (_) => http.Response('{}', 503),
      );
      container.read(accountProvider);
      await container.read(authServiceProvider).ensureSession();
      await Future<void>.delayed(Duration.zero);

      final ok = await container
          .read(accountProvider.notifier)
          .setLeaderboardVisibility(false);

      expect(ok, isFalse);
      expect(
        container.read(accountProvider).showOnLeaderboards,
        isTrue,
        reason: 'told the player they were hidden when they were not',
      );
    });

    test('the choice survives a restart', () async {
      // It is written through to the stored session, so the switch is drawn
      // correctly on the next cold start rather than flicking back to listed
      // until a sync happens to run.
      final container = harness();
      container.read(accountProvider);
      await container.read(authServiceProvider).ensureSession();
      await Future<void>.delayed(Duration.zero);

      await container
          .read(accountProvider.notifier)
          .setLeaderboardVisibility(false);

      final stored = await container.read(authServiceProvider).restore();
      expect(stored!.showOnLeaderboards, isFalse);
    });
  });
}

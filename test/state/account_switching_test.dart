// Changing WHICH account this device is, while things are already happening.
//
// The six reproductions kept next door cover the interleavings the audit
// found. These cover the ones it asked for and could not run: a Google
// credential that already belongs to somebody, a reset performed on another
// device, and account-scoped state that must not follow a player out of one
// account and into another.
//
// The distinction underneath all of them: LINKING keeps the uid and SWITCHING
// replaces it. Everything the app caches — the session, its token, the dirty
// set, a pending reset — is scoped to a uid, and treating a switch as a link
// is what let one player's write land on another player's row.

import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pourfect_flutter_app/services/api/api_client.dart';
import 'package:pourfect_flutter_app/services/api/auth_service.dart';
import 'package:pourfect_flutter_app/services/api/identity.dart';
import 'package:pourfect_flutter_app/state/account_controller.dart';
import 'package:pourfect_flutter_app/state/progress_repository.dart';
import 'package:pourfect_flutter_app/state/providers.dart';
import 'package:pourfect_flutter_app/state/sync_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'account_controller_test.dart' show FakeIdentity;
import 'sync_controller_test.dart' show levelWith, serverRow;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  late List<http.Request> requests;

  ({ProviderContainer container, FakeIdentity identity}) harness({
    FakeIdentity? identity,
    MockClientHandler? handler,
    int serverGeneration = 0,
  }) {
    requests = [];
    final fake = identity ?? FakeIdentity();
    late AuthService auth;

    final client = ApiClient(
      baseUrl: 'https://switch.test',
      tokenProvider: ({bool forceRefresh = false}) =>
          auth.bearerToken(forceRefresh: forceRefresh),
      httpClient: MockClient((request) async {
        requests.add(request);

        if (request.url.path.endsWith('/auth/device')) {
          return http.Response(
            jsonEncode({
              'access_token': 'jwt-${fake.uid}',
              'user_id': fake.uid,
              'expires_in_seconds': 3600,
              'is_anonymous': fake.isAnonymous,
              'ads_removed': false,
            }),
            200,
          );
        }

        if (handler != null) return handler(request);

        return http.Response(
          jsonEncode({
            'accepted': 0,
            'rejected': 0,
            'changed': 0,
            'progress': <Object?>[],
            'reset_generation': serverGeneration,
          }),
          200,
        );
      }),
    );

    auth = AuthService(
      client: () => client,
      idTokenProvider: ({bool forceRefresh = false}) async => 'firebase',
    );

    final container = ProviderContainer(
      overrides: [
        apiClientProvider.overrideWithValue(client),
        authServiceProvider.overrideWithValue(auth),
        identityProvider.overrideWithValue(fake),
      ],
    );
    addTearDown(container.dispose);
    addTearDown(client.close);
    return (container: container, identity: fake);
  }

  group('a credential that already belongs to somebody', () {
    test('the returning player has a path through, not just an explanation',
        () async {
      // The ordinary case: a new phone, a fresh anonymous account created in
      // the background, and a Google account that already exists. Linking
      // fails, and this used to be where it ended — the only method that could
      // finish the job was not on the interface and had no caller.
      final built = harness();
      final account = built.container.read(accountProvider.notifier);

      built.identity.next = const IdentityResult(
        IdentityOutcome.credentialBelongsToAnotherAccount,
      );
      final blocked = await account.continueWithGoogle();
      expect(
        blocked.outcome,
        IdentityOutcome.credentialBelongsToAnotherAccount,
      );

      built.identity.next = const IdentityResult.ok();
      final joined = await account.useExistingGoogleAccount();

      expect(joined.isOk, isTrue);
      expect(built.identity.calls, contains('existingGoogle'));
      expect(built.container.read(accountProvider).signedIn, isTrue);
    });

    test('joining it abandons this device\'s progress rather than merging',
        () async {
      // Firebase cannot merge two uids. Keeping the local campaign and pushing
      // it would write this device's stars into the other account, which is
      // the opposite of what the confirmation promised.
      final built = harness();
      final progress = built.container.read(progressProvider.notifier);
      await built.container.read(authServiceProvider).ensureSession();

      progress.record(
        level: levelWith(id: 1),
        levelSetVersion: 1,
        movesUsed: 5,
        elapsedSeconds: 50,
      );
      expect(built.container.read(progressProvider), isNotEmpty);

      await built.container
          .read(accountProvider.notifier)
          .useExistingGoogleAccount();

      expect(
        built.container.read(progressProvider),
        isEmpty,
        reason: 'the previous account\'s progress survived into a new account',
      );
    });

    test('the switch pulls the new account rather than pushing the old one',
        () async {
      final built = harness();
      await built.container.read(authServiceProvider).ensureSession();
      requests.clear();

      await built.container
          .read(accountProvider.notifier)
          .useExistingGoogleAccount();

      // A push would upload the abandoned campaign under the new identity.
      expect(
        requests.any((r) => r.url.path.endsWith('/progress/sync')),
        isFalse,
        reason: 'switching accounts pushed the previous account\'s campaign',
      );
      expect(requests.any((r) => r.url.path.endsWith('/progress')), isTrue);
    });

    test('every request after the switch carries the new token', () async {
      final built = harness();
      await built.container.read(authServiceProvider).ensureSession();
      requests.clear();

      await built.container
          .read(accountProvider.notifier)
          .useExistingGoogleAccount();

      final authorized = requests
          .where((r) => r.headers.containsKey('authorization'))
          .map((r) => r.headers['authorization'])
          .toList();

      expect(authorized, isNotEmpty);
      expect(
        authorized,
        everyElement(isNot('Bearer jwt-uid-1')),
        reason: 'a write after the switch still authenticated as uid-1',
      );
    });
  });

  group('a pending reset belongs to the account that asked for it', () {
    test('it does not follow the player into a different account', () async {
      // Reproduced shape: reset offline, sign into another account, and that
      // account's first sync delivered a reset nobody there requested.
      SharedPreferences.setMockInitialValues({
        'pourfect.sync.reset_pending': true,
      });

      final built = harness();
      final sync = built.container.read(syncControllerProvider.notifier);
      await built.container.read(authServiceProvider).ensureSession();

      await sync.syncNow();

      expect(
        requests.any((r) => r.url.path.endsWith('/progress/reset')),
        isFalse,
        reason: 'a global pending reset was delivered against another account',
      );
    });
  });

  group('a reset performed on another device', () {
    test('is adopted here instead of being overwritten', () async {
      // This device was offline across somebody's reset, so its campaign
      // predates the erase. Uploading it is exactly how erased stars come
      // back; the server says which generation the account is on and this
      // device takes it.
      final built = harness(serverGeneration: 3);
      final progress = built.container.read(progressProvider.notifier);
      final sync = built.container.read(syncControllerProvider.notifier);

      await built.container.read(authServiceProvider).ensureSession();
      progress.record(
        level: levelWith(id: 1),
        levelSetVersion: 1,
        movesUsed: 5,
        elapsedSeconds: 50,
      );
      sync.markDirty(1);

      await sync.syncNow();

      expect(
        built.container.read(progressProvider),
        isEmpty,
        reason: 'a device kept pre-reset progress after the server moved on',
      );
    });

    test('the generation it adopts is quoted on the next upload', () async {
      final built = harness(serverGeneration: 3);
      final sync = built.container.read(syncControllerProvider.notifier);
      await built.container.read(authServiceProvider).ensureSession();

      await sync.syncNow();
      requests.clear();

      sync.markDirty(1);
      await sync.syncNow();

      final push = requests.firstWhere(
        (r) => r.url.path.endsWith('/progress/sync'),
      );
      expect(
        (jsonDecode(push.body) as Map)['reset_generation'],
        3,
        reason: 'the device kept quoting a generation the account has left',
      );
    });
  });

  group('a same-level improvement during a push', () {
    test('the newer run is what eventually reaches the server', () async {
      // The acknowledgement side of this is covered next door. This is the
      // other half: the better result is not merely still dirty, it is
      // actually sent, and it is the better one.
      final payloads = <List<Object?>>[];
      final built = harness(
        handler: (request) async {
          if (request.url.path.endsWith('/progress/sync')) {
            payloads.add((jsonDecode(request.body) as Map)['items'] as List);
          }
          return http.Response(
            jsonEncode({
              'accepted': 1,
              'rejected': 0,
              'changed': 0,
              'progress': [serverRow(levelId: 1)],
              'reset_generation': 0,
            }),
            200,
          );
        },
      );

      final progress = built.container.read(progressProvider.notifier);
      final sync = built.container.read(syncControllerProvider.notifier);
      await built.container.read(authServiceProvider).ensureSession();

      progress.record(
        level: levelWith(id: 1),
        levelSetVersion: 1,
        movesUsed: 10,
        elapsedSeconds: 100,
      );
      sync.markDirty(1);
      await sync.syncNow();

      progress.record(
        level: levelWith(id: 1),
        levelSetVersion: 1,
        movesUsed: 5,
        elapsedSeconds: 50,
      );
      sync.markDirty(1);
      await sync.syncNow();

      expect(payloads.last, isNotEmpty);
      expect(
        (payloads.last.last as Map)['moves_used'],
        5,
        reason: 'the improved run was never sent',
      );
    });
  });
}

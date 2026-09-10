// Who owns an operation, when the answer is not simply "whoever is signed in".
//
// Two shapes, both of which the earlier account work got wrong:
//
//   * IDENTITY IS NOT AUTHORIZATION. An expired login still names its account
//     perfectly well; it just cannot authorize a request. Asking
//     `ensureSession` who we are answers the wrong question and returns null
//     offline, so a reset performed then belonged to nobody.
//
//   * AN OWNER CAPTURED BEFORE AN AWAIT IS NOT `_loadedAccount` AFTER IT.
//     Anything that persists across an await has to carry its owner with it,
//     because a switch rewrites the shared field underneath.

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pourfect_flutter_app/services/api/api_client.dart';
import 'package:pourfect_flutter_app/services/api/auth_service.dart';
import 'package:pourfect_flutter_app/state/account_controller.dart';
import 'package:pourfect_flutter_app/state/progress_repository.dart';
import 'package:pourfect_flutter_app/state/providers.dart';
import 'package:pourfect_flutter_app/state/sync_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'account_controller_test.dart' show FakeIdentity;
import 'sync_controller_test.dart' show serverRow;

/// Blocks the first empty save, which is the campaign being erased.
class GatedRepository extends ProgressRepository {
  final entered = Completer<void>();
  final release = Completer<void>();
  bool _armed = true;

  @override
  Future<void> save(Map<int, LevelProgress> value) async {
    if (_armed && value.isEmpty) {
      _armed = false;
      entered.complete();
      await release.future;
    }
    await super.save(value);
  }
}

http.Response _session(String uid) => http.Response(
  jsonEncode({
    'access_token': 'jwt-$uid',
    'user_id': uid,
    'expires_in_seconds': 3600,
    'is_anonymous': false,
    'ads_removed': false,
  }),
  200,
);

http.Response _snapshot({int generation = 0, bool populated = false}) =>
    http.Response(
      jsonEncode({
        'accepted': 0,
        'rejected': 0,
        'changed': 0,
        'reset_generation': generation,
        'progress': populated ? [serverRow(levelId: 1)] : <Object?>[],
      }),
      200,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  ({ProviderContainer container, AuthService auth}) harness(
    MockClientHandler handler, {
    FakeIdentity? identity,
    DateTime Function()? now,
    IdTokenProvider? idToken,
    ProgressRepository? repository,
  }) {
    final fake = identity ?? FakeIdentity();
    late AuthService auth;

    final client = ApiClient(
      baseUrl: 'https://own.test',
      tokenProvider: ({bool forceRefresh = false}) =>
          auth.bearerToken(forceRefresh: forceRefresh),
      httpClient: MockClient(
        (r) async => r.url.path.endsWith('/auth/device')
            ? _session(fake.uid)
            : await handler(r),
      ),
    );

    auth = AuthService(
      client: () => client,
      now: now,
      idTokenProvider:
          idToken ?? ({bool forceRefresh = false}) async => 'firebase',
    );

    final container = ProviderContainer(
      overrides: [
        apiClientProvider.overrideWithValue(client),
        authServiceProvider.overrideWithValue(auth),
        identityProvider.overrideWithValue(fake),
        if (repository != null)
          progressRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);
    addTearDown(client.close);
    return (container: container, auth: auth);
  }

  group('identity survives an unusable token', () {
    test('an expired session still names its account', () async {
      var now = DateTime.utc(2026, 9, 10);
      final built = harness(
        (_) async => _snapshot(),
        now: () => now,
        idToken: ({bool forceRefresh = false}) async => 'firebase',
      );

      await built.auth.ensureSession();
      now = now.add(const Duration(hours: 2));

      // Expired, so it cannot authorize anything — and still perfectly clear
      // about whose it is.
      expect(built.auth.accountId, 'uid-1');
      expect(await built.auth.knownAccountId(), 'uid-1');
    });

    test('a cold start reads its account from disk without a network call',
        () async {
      var calls = 0;
      final first = harness((_) async => _snapshot());
      await first.auth.ensureSession();

      final second = harness((r) async {
        calls++;
        return _snapshot();
      });

      expect(await second.auth.knownAccountId(), 'uid-1');
      expect(calls, 0, reason: 'knowing the account required a round trip');
    });

    test('the offline reset is filed under that account, not the fallback',
        () async {
      var online = true;
      var now = DateTime.utc(2026, 9, 10);
      final built = harness(
        (_) async => _snapshot(),
        now: () => now,
        idToken: ({bool forceRefresh = false}) async =>
            online ? 'firebase' : null,
      );

      await built.auth.ensureSession();
      now = now.add(const Duration(hours: 2));
      online = false;

      expect(
        await built.container.read(syncControllerProvider.notifier).reset(),
        isFalse,
      );

      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getBool('pourfect.sync.reset_pending.uid-1'),
        isTrue,
        reason: 'the reset was recorded against nobody',
      );
      expect(
        prefs.getBool('pourfect.sync.reset_pending'),
        isNull,
        reason: 'it fell back to the unscoped key and will be lost',
      );
    });

    test('it survives a relaunch and is delivered when the network returns',
        () async {
      var online = true;
      var now = DateTime.utc(2026, 9, 10);
      final first = harness(
        (_) async => _snapshot(),
        now: () => now,
        idToken: ({bool forceRefresh = false}) async =>
            online ? 'firebase' : null,
      );
      await first.auth.ensureSession();
      now = now.add(const Duration(hours: 2));
      online = false;
      await first.container.read(syncControllerProvider.notifier).reset();

      // A fresh process, same disk.
      final paths = <String>[];
      final second = harness((r) async {
        paths.add(r.url.path);
        return _snapshot(populated: !r.url.path.endsWith('/reset'));
      });

      await second.container.read(syncControllerProvider.notifier).syncNow();

      expect(paths, contains('/api/v1/progress/reset'));
      expect(second.container.read(progressProvider), isEmpty);
    });
  });

  group('an owner captured before an await is the owner after it', () {
    test('a switch during the erase leaves the generation under A, not B',
        () async {
      // The preference key used to be read from mutable shared state after
      // the await, so a switch mid-save stored A's generation against B.
      final repository = GatedRepository();
      final built = harness(
        (r) async => r.headers['authorization'] == 'Bearer jwt-uid-existing'
            ? _snapshot()
            : _snapshot(generation: 4, populated: true),
        repository: repository,
      );

      final sync = built.container.read(syncControllerProvider.notifier);
      final running = sync.syncNow();
      await repository.entered.future;

      final switching = built.container
          .read(accountProvider.notifier)
          .useExistingGoogleAccount();

      for (var i = 0; i < 100 && built.auth.current != null; i++) {
        await Future<void>.delayed(Duration.zero);
      }
      await Future<void>.delayed(Duration.zero);
      repository.release.complete();
      await running;
      await switching;

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('pourfect.sync.reset_generation.uid-1'), 4);
      expect(
        prefs.getInt('pourfect.sync.reset_generation.uid-existing'),
        isNull,
        reason: "A's generation was stored against B",
      );
    });

    test('nothing from A is left for B to upload', () async {
      final repository = GatedRepository();
      final uploads = <List<Object?>>[];

      final built = harness((r) async {
        if (r.headers['authorization'] == 'Bearer jwt-uid-existing') {
          if (r.url.path.endsWith('/sync')) {
            uploads.add((jsonDecode(r.body) as Map)['items'] as List);
          }
          return _snapshot();
        }
        return _snapshot(generation: 1, populated: true);
      }, repository: repository);

      final sync = built.container.read(syncControllerProvider.notifier);
      final running = sync.syncNow();
      await repository.entered.future;

      final switching = built.container
          .read(accountProvider.notifier)
          .useExistingGoogleAccount();
      for (var i = 0; i < 100 && built.auth.current != null; i++) {
        await Future<void>.delayed(Duration.zero);
      }
      await Future<void>.delayed(Duration.zero);
      repository.release.complete();
      await running;
      await switching;

      await sync.pushEverything();

      debugPrint('uploaded under B: $uploads');
      expect(built.container.read(progressProvider), isEmpty);
      expect(
        uploads.every((rows) => rows.isEmpty),
        isTrue,
        reason: "account A's campaign was uploaded under account B's token",
      );
    });
  });
}

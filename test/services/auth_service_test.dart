// Getting and keeping a session, without a Firebase project in sight.
//
// The Firebase call is a seam (`IdTokenProvider`) precisely so this whole path
// is testable: the interesting behaviour is not "does Firebase work", it is
// what happens when five callers want a token at once, when the stored one has
// expired, and when the server rejects it.

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pourfect_flutter_app/services/api/api_client.dart';
import 'package:pourfect_flutter_app/services/api/auth_service.dart';
import 'package:pourfect_flutter_app/services/api/session.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  /// The shape `POST /auth/device` really returns.
  String authBody({
    String token = 'server-jwt',
    int expiresIn = 3600,
    bool adsRemoved = false,
    String? displayName,
    bool isAnonymous = true,
  }) => jsonEncode({
    'access_token': token,
    'expires_in_seconds': expiresIn,
    'user_id': '11111111-2222-3333-4444-555555555555',
    'display_name': displayName,
    'ads_removed': adsRemoved,
    'is_new_user': true,
    'is_anonymous': isAnonymous,
    'auth_provider': 'anonymous',
  });

  ({AuthService auth, List<http.Request> calls}) build({
    required MockClientHandler handler,
    String baseUrl = 'https://api.test',
    IdTokenProvider? idToken,
    DateTime Function()? now,
  }) {
    final calls = <http.Request>[];
    final client = ApiClient(
      httpClient: MockClient((request) {
        calls.add(request);
        return handler(request);
      }),
      baseUrl: baseUrl,
    );

    return (
      auth: AuthService(
        client: () => client,
        idTokenProvider:
            idToken ?? ({bool forceRefresh = false}) async => 'firebase-id',
        appVersion: () => '1.2.3',
        now: now,
      ),
      calls: calls,
    );
  }

  group('exchanging a Firebase token', () {
    test('produces a session and remembers it', () async {
      final built = build(handler: (_) async => http.Response(authBody(), 200));

      final session = await built.auth.ensureSession();

      expect(session, isNotNull);
      expect(session!.accessToken, 'server-jwt');
      expect(session.isAnonymous, isTrue);
      expect(built.auth.current, isNotNull);

      // ...and it survives a relaunch, so the first sync of the next session
      // goes out immediately rather than after a Firebase round trip.
      expect((await SessionStore().load())?.accessToken, 'server-jwt');
    });

    test('sends what the handshake needs', () async {
      final built = build(handler: (_) async => http.Response(authBody(), 200));

      await built.auth.ensureSession();

      final body = jsonDecode(built.calls.single.body) as Map<String, Object?>;
      expect(body['id_token'], 'firebase-id');
      expect(body['platform'], anyOf('android', 'ios'));
      expect(body['app_version'], '1.2.3');
      // The evening reminder needs a local-time anchor, and a player who
      // declines notifications never reaches the code path that would supply
      // one — so it rides on every auth instead.
      expect(body['time_zone_offset_minutes'], isA<int>());
    });

    test('carries the entitlement the server knows about', () async {
      // Somebody who paid and then reinstalled is ad-free from the first level
      // rather than after their first purchase sync.
      final built = build(
        handler: (_) async => http.Response(authBody(adsRemoved: true), 200),
      );

      expect((await built.auth.ensureSession())!.adsRemoved, isTrue);
    });
  });

  group('a session is obtained once', () {
    test('a second call reuses it without a round trip', () async {
      final built = build(handler: (_) async => http.Response(authBody(), 200));

      await built.auth.ensureSession();
      await built.auth.ensureSession();

      expect(built.calls, hasLength(1));
    });

    test('concurrent callers share one exchange', () async {
      // Several services wake up at launch and all want a token. Without
      // single-flight that is five sign-ins and five server rows of work for
      // one player opening the app, four of which are thrown away.
      final built = build(
        handler: (_) async {
          await Future<void>.delayed(const Duration(milliseconds: 20));
          return http.Response(authBody(), 200);
        },
      );

      final sessions = await Future.wait([
        built.auth.ensureSession(),
        built.auth.ensureSession(),
        built.auth.ensureSession(),
        built.auth.ensureSession(),
        built.auth.ensureSession(),
      ]);

      expect(built.calls, hasLength(1));
      expect(sessions.map((s) => s?.accessToken).toSet(), {'server-jwt'});
    });

    test('an exchange that failed does not poison the next attempt', () async {
      var fail = true;
      final built = build(
        handler: (_) async {
          if (fail) return http.Response('down', 503);
          return http.Response(authBody(), 200);
        },
      );

      expect(await built.auth.ensureSession(), isNull);
      fail = false;
      expect(await built.auth.ensureSession(), isNotNull);
    });
  });

  group('expiry', () {
    test('a session near its expiry is re-exchanged', () async {
      // The margin matters: treating a token as good until the exact second it
      // expires turns every clock skew into a 401 the player sees as a failed
      // sync.
      var clock = DateTime.utc(2026, 9, 9, 12);
      final built = build(
        handler: (_) async => http.Response(authBody(expiresIn: 600), 200),
        now: () => clock,
      );

      await built.auth.ensureSession();
      clock = clock.add(const Duration(minutes: 9));

      await built.auth.ensureSession();

      expect(built.calls, hasLength(2));
    });

    test('a session still well within its life is not', () async {
      var clock = DateTime.utc(2026, 9, 9, 12);
      final built = build(
        handler: (_) async => http.Response(authBody(expiresIn: 3600), 200),
        now: () => clock,
      );

      await built.auth.ensureSession();
      clock = clock.add(const Duration(minutes: 5));

      await built.auth.ensureSession();

      expect(built.calls, hasLength(1));
    });

    test('a forced refresh re-exchanges a perfectly good session', () async {
      // This is what a 401 means: the server has rejected a token we believed
      // in, so our belief is what has to be discarded.
      final built = build(handler: (_) async => http.Response(authBody(), 200));

      await built.auth.ensureSession();
      await built.auth.ensureSession(forceRefresh: true);

      expect(built.calls, hasLength(2));
    });

    test(
      'a server that reports no lifetime is not assumed to be generous',
      () async {
        var clock = DateTime.utc(2026, 9, 9, 12);
        final built = build(
          handler: (_) async => http.Response(
            jsonEncode({
              'access_token': 'jwt',
              'user_id': 'u',
              'is_anonymous': true,
            }),
            200,
          ),
          now: () => clock,
        );

        final session = await built.auth.ensureSession();

        expect(session, isNotNull);
        expect(
          session!.expiresAt.difference(clock).inHours,
          lessThanOrEqualTo(1),
          reason: 'an unknown lifetime was treated as a long one',
        );
      },
    );
  });

  group('when a session cannot be had', () {
    test('no Firebase token means no request and no session', () async {
      // A device with no Play Services, a Firebase init that failed, an
      // offline first launch. All of them still reach level 1.
      final built = build(
        handler: (_) async => http.Response(authBody(), 200),
        idToken: ({bool forceRefresh = false}) async => null,
      );

      expect(await built.auth.ensureSession(), isNull);
      expect(built.calls, isEmpty);
    });

    test('no backend configured means no Firebase call either', () async {
      var asked = 0;
      final built = build(
        handler: (_) async => http.Response(authBody(), 200),
        baseUrl: '',
        idToken: ({bool forceRefresh = false}) async {
          asked++;
          return 'firebase-id';
        },
      );

      expect(await built.auth.ensureSession(), isNull);
      expect(asked, 0, reason: 'signed in for a server that does not exist');
    });

    test('a rejected ID token clears the stored session', () async {
      // The Firebase account is gone, or was never ours. Keeping the old
      // session would mean retrying a credential the server has refused.
      var reject = false;
      final built = build(
        handler: (_) async {
          return reject
              ? http.Response('{"error":"bad token"}', 401)
              : http.Response(authBody(), 200);
        },
      );

      await built.auth.ensureSession();
      expect(await SessionStore().load(), isNotNull);

      reject = true;
      await built.auth.ensureSession(forceRefresh: true);

      expect(built.auth.current, isNull);
      expect(await SessionStore().load(), isNull);
    });

    test('a transient failure KEEPS the stored session', () async {
      // The opposite rule, and the one that matters on a train: an outage must
      // not log somebody out of their own progress.
      var fail = false;
      final built = build(
        handler: (_) async {
          return fail
              ? http.Response('gateway', 502)
              : http.Response(authBody(), 200);
        },
      );

      await built.auth.ensureSession();
      fail = true;
      await built.auth.ensureSession(forceRefresh: true);

      expect(
        await SessionStore().load(),
        isNotNull,
        reason: 'an outage discarded a session that was probably still good',
      );
    });
  });

  group('restore', () {
    test('loads from disk with no network call at all', () async {
      SharedPreferences.setMockInitialValues({
        'pourfect.session.v1': jsonEncode({
          'token': 'stored',
          'expires_at': DateTime.utc(2030).toIso8601String(),
          'user_id': 'u',
          'ads_removed': true,
          'is_anonymous': true,
          'auth_provider': 'anonymous',
        }),
      });

      final built = build(handler: (_) async => http.Response(authBody(), 200));

      final session = await built.auth.restore();

      expect(session?.accessToken, 'stored');
      expect(session?.adsRemoved, isTrue);
      expect(built.calls, isEmpty);
    });

    test(
      'a corrupt stored session costs one silent re-auth, not a crash',
      () async {
        SharedPreferences.setMockInitialValues({
          'pourfect.session.v1': 'not json at all',
        });

        final built = build(
          handler: (_) async => http.Response(authBody(), 200),
        );

        expect(await built.auth.restore(), isNull);
        expect((await built.auth.ensureSession())?.accessToken, 'server-jwt');
      },
    );
  });

  group('keeping the cached session honest', () {
    test('a confirmed change is written through', () async {
      final built = build(handler: (_) async => http.Response(authBody(), 200));
      await built.auth.ensureSession();

      await built.auth.update(displayName: 'Pranta', adsRemoved: true);

      expect(built.auth.current!.displayName, 'Pranta');
      expect((await SessionStore().load())!.adsRemoved, isTrue);
    });

    test('forgetting drops it from memory and from disk', () async {
      final built = build(handler: (_) async => http.Response(authBody(), 200));
      await built.auth.ensureSession();

      await built.auth.forget();

      expect(built.auth.current, isNull);
      expect(await SessionStore().load(), isNull);
    });
  });
}

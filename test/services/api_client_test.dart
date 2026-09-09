// The HTTP client, and the ways a request does not succeed.
//
// The rule this file exists to pin: NOTHING IN THIS LAYER THROWS. A puzzle
// game that works on a plane cannot have a network stack whose failure mode is
// an exception reaching the UI, so every path below — no server configured, no
// network, a timeout, a rejected session, a 500, a body that is not JSON —
// comes back as a value the caller has to look at.

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pourfect_flutter_app/services/api/api_client.dart';
import 'package:pourfect_flutter_app/services/api/api_result.dart';

void main() {
  ApiClient clientFor(
    MockClientHandler handler, {
    String baseUrl = 'https://api.test',
    TokenProvider? token,
  }) => ApiClient(
    httpClient: MockClient(handler),
    baseUrl: baseUrl,
    tokenProvider: token ?? ({bool forceRefresh = false}) async => 'tok',
  );

  group('with no backend configured', () {
    test('nothing is sent and the caller is told why', () async {
      var sent = 0;
      final client = clientFor((_) async {
        sent++;
        return http.Response('{}', 200);
      }, baseUrl: '');

      final result = await client.get('/api/v1/progress');

      expect(sent, 0, reason: 'a request went out with nowhere to send it');
      expect(
        (result as ApiFailure).kind,
        ApiFailureKind.notConfigured,
        reason: 'an unconfigured build must be distinguishable from an outage',
      );
    });
  });

  group('a successful call', () {
    test('decodes the body and carries the bearer token', () async {
      late http.Request seen;
      final client = clientFor((request) async {
        seen = request;
        return http.Response('{"user_id":"abc"}', 200);
      });

      final result = await client.get('/api/v1/progress');

      expect(result.valueOrNull, {'user_id': 'abc'});
      expect(seen.headers['authorization'], 'Bearer tok');
      expect(seen.url.toString(), 'https://api.test/api/v1/progress');
    });

    test('an empty 200 body is success, not a parse failure', () async {
      // Commands that return nothing do this, and treating it as a broken
      // response would make every one of them look like a server fault.
      final client = clientFor((_) async => http.Response('', 200));

      expect((await client.post('/api/v1/notifications/token', {})).isOk, true);
    });

    test('query parameters are sent', () async {
      late Uri seen;
      final client = clientFor((request) async {
        seen = request.url;
        return http.Response('{}', 200);
      });

      await client.get('/api/v1/leaderboard/daily', query: {'limit': '10'});

      expect(seen.queryParameters['limit'], '10');
    });

    test('a trailing slash on the base URL does not double up', () async {
      late Uri seen;
      final client = clientFor((request) async {
        seen = request.url;
        return http.Response('{}', 200);
      }, baseUrl: 'https://api.test/');

      await client.get('/api/v1/progress');

      expect(seen.path, '/api/v1/progress');
    });
  });

  group('failures are values, never exceptions', () {
    test('a dead network is offline', () async {
      final client = clientFor((_) async => throw const SocketishError());

      final result = await client.get('/api/v1/progress') as ApiFailure;

      expect(result.kind, ApiFailureKind.offline);
      expect(result.isTransient, isTrue);
    });

    test('a slow server is a timeout', () async {
      final client = clientFor((_) async {
        // Longer than kApiTimeout, without making the test wait for it: the
        // timeout fires on the client side and the future is abandoned.
        await Future<void>.delayed(const Duration(minutes: 1));
        return http.Response('{}', 200);
      });

      final result = await client.get('/api/v1/progress') as ApiFailure;

      expect(result.kind, ApiFailureKind.timeout);
      expect(result.isTransient, isTrue);
    }, timeout: const Timeout(Duration(seconds: 30)));

    test('a 400 is a refusal, and refusals are not worth retrying', () async {
      final client = clientFor(
        (_) async => http.Response('{"error":"Unknown product"}', 400),
      );

      final result =
          await client.post('/api/v1/purchases/verify', {}) as ApiFailure;

      expect(result.kind, ApiFailureKind.refused);
      expect(result.detail, 'Unknown product');
      expect(
        result.isTransient,
        isFalse,
        reason: 'the identical request will be refused identically forever',
      );
    });

    test('a 500 is ours, and is worth retrying', () async {
      final client = clientFor((_) async => http.Response('boom', 500));

      final result = await client.get('/api/v1/progress') as ApiFailure;

      expect(result.kind, ApiFailureKind.server);
      expect(result.isTransient, isTrue);
    });

    test('an HTML error page from a proxy does not crash the decode', () async {
      final client = clientFor(
        (_) async => http.Response('<html>502 Bad Gateway</html>', 502),
      );

      final result = await client.get('/api/v1/progress') as ApiFailure;

      expect(result.kind, ApiFailureKind.server);
      expect(result.detail, contains('502'));
    });

    test('a 200 carrying nonsense is a server fault, not a crash', () async {
      final client = clientFor((_) async => http.Response('not json', 200));

      expect(
        ((await client.get('/api/v1/progress')) as ApiFailure).kind,
        ApiFailureKind.server,
      );
    });

    test('no session means the request is not sent at all', () async {
      var sent = 0;
      final client = clientFor((_) async {
        sent++;
        return http.Response('{}', 200);
      }, token: ({bool forceRefresh = false}) async => null);

      final result = await client.get('/api/v1/progress') as ApiFailure;

      expect(sent, 0);
      expect(result.kind, ApiFailureKind.unauthorized);
    });
  });

  group('a rejected session is retried exactly once', () {
    test('with a refreshed token, and the second answer is kept', () async {
      // The one automatic retry worth having: the token expired while the app
      // was closed. Re-exchanging turns that into something a player never
      // sees.
      final tokens = <String>[];
      var call = 0;

      final client = clientFor(
        (request) async {
          tokens.add(request.headers['authorization']!);
          return ++call == 1
              ? http.Response('{"error":"expired"}', 401)
              : http.Response('{"ok":true}', 200);
        },
        token: ({bool forceRefresh = false}) async =>
            forceRefresh ? 'fresh' : 'stale',
      );

      final result = await client.get('/api/v1/progress');

      expect(result.valueOrNull, {'ok': true});
      expect(tokens, ['Bearer stale', 'Bearer fresh']);
    });

    test('and not again when the fresh token is refused too', () async {
      // A genuinely dead credential must not become a client hammering an
      // endpoint that will never accept it.
      var call = 0;
      final client = clientFor((_) async {
        call++;
        return http.Response('{"error":"nope"}', 401);
      });

      final result = await client.get('/api/v1/progress') as ApiFailure;

      expect(call, 2, reason: 'retried more than once');
      expect(result.kind, ApiFailureKind.unauthorized);
    });

    test('an unauthenticated call is never retried', () async {
      // `auth/device` IS the way a session is obtained. Retrying it with a
      // "refreshed" session would be circular.
      var call = 0;
      final client = clientFor((_) async {
        call++;
        return http.Response('{"error":"bad token"}', 401);
      });

      await client.postAnonymous('/api/v1/auth/device', {});

      expect(call, 1);
    });
  });

  group('request bodies', () {
    test('are JSON with the right content type', () async {
      late http.Request seen;
      final client = clientFor((request) async {
        seen = request;
        return http.Response('{}', 200);
      });

      await client.post('/api/v1/daily/submit', {'moves_used': 7});

      expect(seen.headers['content-type'], contains('application/json'));
      expect(jsonDecode(seen.body), {'moves_used': 7});
    });

    test('a GET carries no content type', () async {
      late http.Request seen;
      final client = clientFor((request) async {
        seen = request;
        return http.Response('{}', 200);
      });

      await client.get('/api/v1/progress');

      expect(seen.headers.containsKey('content-type'), isFalse);
    });
  });
}

/// Stands in for the socket errors `dart:io` throws, which a test on the
/// Flutter test platform cannot raise for real.
class SocketishError implements Exception {
  const SocketishError();

  @override
  String toString() => 'Connection refused';
}

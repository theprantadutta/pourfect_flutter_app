// Today's challenge.
//
// The one feature that genuinely needs a server: boards are generated
// backend-side from a seed that never ships to a device, because this repo is
// public and generation is deterministic — shipping the pool would publish
// every board for the next year alongside its proven optimal solution, and the
// anti-cheat floor cannot tell an honest optimum from a looked-up one.
//
// So "no network, no daily" is correct rather than a gap. What these tests
// defend is that its absence never costs anything else, and that a board which
// WAS solved is never reported as if it had not been.

import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pourfect_flutter_app/services/api/api_client.dart';
import 'package:pourfect_flutter_app/services/api/api_result.dart';
import 'package:pourfect_flutter_app/services/api/daily_api.dart';
import 'package:pourfect_flutter_app/services/api/auth_service.dart';
import 'package:pourfect_flutter_app/state/daily_controller.dart';
import 'package:pourfect_flutter_app/state/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  String dailyBody({Map<String, Object?>? attempt, int capacity = 4}) =>
      jsonEncode({
        'date': '2026-09-09',
        'capacity': capacity,
        'tubes': [
          [0, 0, 0, 1],
          [1, 1, 1, 0],
          <int>[],
        ],
        'min_moves': 4,
        'color_count': 2,
        'empty_tube_count': 1,
        'your_attempt': attempt,
      });

  ({ProviderContainer container, List<http.Request> calls}) harness({
    required MockClientHandler handler,
    String baseUrl = 'https://api.test',
    bool signedIn = true,
  }) {
    final calls = <http.Request>[];
    final client = ApiClient(
      httpClient: MockClient((request) {
        calls.add(request);
        return handler(request);
      }),
      baseUrl: baseUrl,
      tokenProvider: ({bool forceRefresh = false}) async => 'tok',
    );

    final container = ProviderContainer(
      overrides: [
        apiClientProvider.overrideWithValue(client),
        authServiceProvider.overrideWith(
          (ref) => AuthService(
            client: () => client,
            idTokenProvider: ({bool forceRefresh = false}) async =>
                signedIn ? 'firebase-id' : null,
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    return (container: container, calls: calls);
  }

  MockClientHandler authThen(MockClientHandler rest) => (request) async {
    if (request.url.path.endsWith('/auth/device')) {
      return http.Response(
        jsonEncode({
          'access_token': 'jwt',
          'expires_in_seconds': 3600,
          'user_id': 'u',
          'ads_removed': false,
          'is_new_user': false,
          'is_anonymous': true,
          'auth_provider': 'anonymous',
        }),
        200,
      );
    }
    return rest(request);
  };

  group('fetching today', () {
    test('decodes the board into something the engine can play', () async {
      final built = harness(
        handler: authThen((_) async => http.Response(dailyBody(), 200)),
      );

      await built.container.read(dailyProvider.notifier).ensureLoaded();

      final challenge = built.container.read(dailyProvider).challenge!;
      expect(challenge.board.tubeCount, 3);
      expect(challenge.board.capacity, 4);
      expect(challenge.minMoves, 4);
      expect(challenge.isPlayed, isFalse);

      // Level zero: it is not part of the campaign and must never be mistaken
      // for a level id in progress or in analytics.
      expect(challenge.asLevel.id, 0);
    });

    test('reports an attempt already made today', () async {
      final built = harness(
        handler: authThen(
          (_) async => http.Response(
            dailyBody(
              attempt: {
                'moves': 6,
                'stars': 2,
                'duration_seconds': 90,
                'completed_at': '2026-09-09T10:00:00Z',
              },
            ),
            200,
          ),
        ),
      );

      await built.container.read(dailyProvider.notifier).ensureLoaded();

      final challenge = built.container.read(dailyProvider).challenge!;
      expect(challenge.isPlayed, isTrue);
      expect(challenge.yourAttempt!.stars, 2);
      expect(challenge.yourAttempt!.moves, 6);
    });

    test('a second call does not fetch again', () async {
      final built = harness(
        handler: authThen((_) async => http.Response(dailyBody(), 200)),
      );

      final daily = built.container.read(dailyProvider.notifier);
      await daily.ensureLoaded();
      await daily.ensureLoaded();

      expect(
        built.calls.where((c) => c.url.path.endsWith('/daily')),
        hasLength(1),
      );
    });

    test('a malformed board is a failure, not a crash', () async {
      // A board the engine refuses is a server-side content problem. It has to
      // leave the daily absent rather than take a screen down.
      final built = harness(
        handler: authThen(
          (_) async => http.Response(
            jsonEncode({'date': '2026-09-09', 'capacity': 4, 'tubes': 'nope'}),
            200,
          ),
        ),
      );

      await built.container.read(dailyProvider.notifier).ensureLoaded();

      final state = built.container.read(dailyProvider);
      expect(state.challenge, isNull);
      expect(state.failure, ApiFailureKind.server);
      expect(state.isUnavailable, isTrue);
    });
  });

  group('when there is no daily to be had', () {
    test('no backend is OFF, which is not a failure', () async {
      final built = harness(
        handler: (_) async => http.Response(dailyBody(), 200),
        baseUrl: '',
      );

      await built.container.read(dailyProvider.notifier).ensureLoaded();

      final state = built.container.read(dailyProvider);
      expect(state.isOff, isTrue);
      expect(
        state.isUnavailable,
        isFalse,
        reason: 'a build with no server must not report an outage',
      );
      expect(built.calls, isEmpty);
    });

    test('no session means nothing is attempted', () async {
      final built = harness(
        handler: (_) async => http.Response(dailyBody(), 200),
        signedIn: false,
      );

      await built.container.read(dailyProvider.notifier).ensureLoaded();

      expect(built.container.read(dailyProvider).isOff, isTrue);
      expect(built.calls, isEmpty);
    });

    test('an outage is unavailable, and says so', () async {
      final built = harness(
        handler: authThen((_) async => http.Response('down', 503)),
      );

      await built.container.read(dailyProvider.notifier).ensureLoaded();

      final state = built.container.read(dailyProvider);
      expect(state.isUnavailable, isTrue);
      expect(state.isOff, isFalse);
    });
  });

  group('submitting a solved board', () {
    test('sends the date, the moves and the clock', () async {
      final built = harness(
        handler: authThen((request) async {
          if (request.url.path.endsWith('/submit')) {
            return http.Response(
              jsonEncode({
                'stars': 3,
                'moves': 4,
                'is_personal_best': true,
                'daily_streak': 5,
                'rank': 2,
                'total_players': 40,
              }),
              200,
            );
          }
          return http.Response(dailyBody(), 200);
        }),
      );

      final daily = built.container.read(dailyProvider.notifier);
      await daily.ensureLoaded();
      final result = await daily.submit(movesUsed: 4, durationSeconds: 75);

      final submit = built.calls.firstWhere(
        (c) => c.url.path.endsWith('/submit'),
      );
      expect(jsonDecode(submit.body), {
        'date': '2026-09-09',
        'moves_used': 4,
        'duration_seconds': 75,
      });

      final value = (result as ApiOk).value;
      expect(value.stars, 3);
      expect(value.dailyStreak, 5);
      expect(value.rank, 2);
    });

    test(
      'an unranked player is reported as unranked, not as rank zero',
      () async {
        // Setting a display name is the leaderboard opt-in, so somebody without
        // one genuinely has no position. A number here would be contradicted by
        // the board a moment later.
        final built = harness(
          handler: authThen((request) async {
            if (request.url.path.endsWith('/submit')) {
              return http.Response(
                jsonEncode({
                  'stars': 2,
                  'moves': 6,
                  'is_personal_best': false,
                  'daily_streak': 1,
                  'rank': null,
                  'total_players': 12,
                }),
                200,
              );
            }
            return http.Response(dailyBody(), 200);
          }),
        );

        final daily = built.container.read(dailyProvider.notifier);
        await daily.ensureLoaded();
        final result = await daily.submit(movesUsed: 6, durationSeconds: 100);

        expect((result as ApiOk).value.rank, isNull);
      },
    );

    test('a successful submission updates what the home card shows', () async {
      final built = harness(
        handler: authThen((request) async {
          if (request.url.path.endsWith('/submit')) {
            return http.Response(
              jsonEncode({
                'stars': 3,
                'moves': 4,
                'is_personal_best': true,
                'daily_streak': 1,
                'rank': 1,
                'total_players': 1,
              }),
              200,
            );
          }
          return http.Response(dailyBody(), 200);
        }),
      );

      final daily = built.container.read(dailyProvider.notifier);
      await daily.ensureLoaded();
      expect(built.container.read(dailyProvider).challenge!.isPlayed, isFalse);

      await daily.submit(movesUsed: 4, durationSeconds: 60);

      final challenge = built.container.read(dailyProvider).challenge!;
      expect(challenge.isPlayed, isTrue);
      expect(challenge.yourAttempt!.stars, 3);
    });

    test('a refused submission leaves the board unplayed', () async {
      // Below the proven optimum, most likely. The board is not marked as done
      // on a result the server would not take.
      final built = harness(
        handler: authThen((request) async {
          if (request.url.path.endsWith('/submit')) {
            return http.Response('{"error":"below the optimum"}', 400);
          }
          return http.Response(dailyBody(), 200);
        }),
      );

      final daily = built.container.read(dailyProvider.notifier);
      await daily.ensureLoaded();
      final result = await daily.submit(movesUsed: 1, durationSeconds: 5);

      expect((result as ApiFailure).kind, ApiFailureKind.refused);
      expect(built.container.read(dailyProvider).challenge!.isPlayed, isFalse);
    });

    test('submitting with no board loaded is refused locally', () async {
      final built = harness(
        handler: authThen((_) async => http.Response(dailyBody(), 200)),
      );

      final result = await built.container
          .read(dailyProvider.notifier)
          .submit(movesUsed: 4, durationSeconds: 60);

      expect(result, isA<ApiFailure<DailyResult>>());
      expect(built.calls, isEmpty);
    });
  });
}

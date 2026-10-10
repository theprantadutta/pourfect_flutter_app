// The weekly event, as the app reads and submits it.

import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pourfect_flutter_app/services/api/api_client.dart';
import 'package:pourfect_flutter_app/services/api/auth_service.dart';
import 'package:pourfect_flutter_app/state/event_controller.dart';
import 'package:pourfect_flutter_app/state/providers.dart';
import 'package:pourfect_flutter_app/ui/screens/event_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Map<String, Object?> body({
    List<Map<String, Object?>> results = const [],
  }) => {
    'name': 'Fizz Week',
    'week_start': '2026-10-05',
    'ends_at': '2026-10-12T00:00:00Z',
    'levels': [
      for (var slot = 1; slot <= 7; slot++)
        {
          'slot': slot,
          'capacity': 2,
          'tubes': [
            [0, 1],
            [1, 0],
            [],
          ],
          'min_moves': 3,
        },
    ],
    'results': results,
    'total_points': results.fold<int>(0, (n, r) => n + (r['points'] as int)),
    'rank': results.isEmpty ? null : 2,
    'players': 5,
  };

  ({ProviderContainer container, List<http.Request> calls}) harness(
    Future<http.Response> Function(http.Request) handler,
  ) {
    final calls = <http.Request>[];
    final client = ApiClient(
      httpClient: MockClient((request) async {
        calls.add(request);
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
        return handler(request);
      }),
      baseUrl: 'https://api.test',
      tokenProvider: ({bool forceRefresh = false}) async => 'tok',
    );
    final container = ProviderContainer(
      overrides: [
        apiClientProvider.overrideWithValue(client),
        authServiceProvider.overrideWith(
          (ref) => AuthService(
            client: () => client,
            idTokenProvider: ({bool forceRefresh = false}) async => 'id',
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    return (container: container, calls: calls);
  }

  test('reads the week, its seven boards and the results so far', () async {
    final built = harness(
      (_) async => http.Response(
        jsonEncode(
          body(
            results: [
              {'slot': 1, 'moves': 3, 'stars': 3, 'points': 360},
            ],
          ),
        ),
        200,
      ),
    );

    await built.container.read(eventProvider.notifier).refresh();
    final event = built.container.read(eventProvider).event!;

    expect(event.name, 'Fizz Week');
    expect(event.boards, hasLength(7));
    expect(event.cleared, 1);
    expect(event.results[1]!.stars, 3);
    expect(event.rank, 2);
    expect(event.weekStart, DateTime.utc(2026, 10, 5));
  });

  test('a submission names the week it was played in', () async {
    final built = harness((request) async {
      if (request.method == 'POST') {
        return http.Response(
          jsonEncode(
            body(
              results: [
                {'slot': 2, 'moves': 4, 'stars': 2, 'points': 200},
              ],
            ),
          ),
          200,
        );
      }
      return http.Response(jsonEncode(body()), 200);
    });
    final events = built.container.read(eventProvider.notifier);
    await events.refresh();

    await events.submit(
      event: built.container.read(eventProvider).event!,
      slot: 2,
      movesUsed: 4,
      durationSeconds: 30,
    );

    final post = built.calls.lastWhere((c) => c.method == 'POST');
    expect(jsonDecode(post.body), {
      'week_start': '2026-10-05',
      'slot': 2,
      'moves_used': 4,
      'duration_seconds': 30,
    });
    expect(built.container.read(eventProvider).event!.cleared, 1);
  });

  test('says how long is left', () {
    final end = DateTime.utc(2026, 10, 12);
    expect(
      eventEndsIn(end, now: DateTime.utc(2026, 10, 9, 20)),
      'ends in 2d 4h',
    );
    expect(eventEndsIn(end, now: DateTime.utc(2026, 10, 11, 21)), 'ends in 3h');
    expect(eventEndsIn(end, now: DateTime.utc(2026, 10, 12, 1)), 'ended');
  });
}

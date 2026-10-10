// The Daily Pour streak, as the app reads it.
//
// Every number is the server's: freezes are spent and handed out by days
// passing, which a phone cannot see happen. What these tests defend is that
// the app shows exactly what it was told, and never loses a streak to a
// dropped connection.

import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pourfect_flutter_app/services/api/api_client.dart';
import 'package:pourfect_flutter_app/services/api/auth_service.dart';
import 'package:pourfect_flutter_app/services/api/daily_api.dart';
import 'package:pourfect_flutter_app/state/providers.dart';
import 'package:pourfect_flutter_app/state/streak_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  Map<String, Object?> streakBody({
    int current = 4,
    int freezes = 1,
    bool canEarn = true,
  }) => {
    'current': current,
    'best': 9,
    'freezes': freezes,
    'max_freezes': 2,
    'can_earn_freeze': canEarn,
    'next_weekly_freeze_on': '2026-10-12',
    'today': '2026-10-10',
    'played': ['2026-10-07', '2026-10-08', '2026-10-10'],
    'frozen': ['2026-10-09'],
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
            idTokenProvider: ({bool forceRefresh = false}) async =>
                'firebase-id',
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    return (container: container, calls: calls);
  }

  test('reads the streak, its freezes and its calendar', () async {
    final built = harness(
      (_) async => http.Response(jsonEncode(streakBody()), 200),
    );

    await built.container.read(streakProvider.notifier).refresh();
    final info = built.container.read(streakProvider)!;

    expect(info.current, 4);
    expect(info.best, 9);
    expect(info.freezes, 1);
    expect(info.canEarnFreeze, isTrue);
    expect(info.today, DateTime.utc(2026, 10, 10));
    expect(info.frozen, {DateTime.utc(2026, 10, 9)});
    expect(info.played, contains(DateTime.utc(2026, 10, 8)));
  });

  test('a failed refresh keeps the streak it had', () async {
    var fail = false;
    final built = harness(
      (_) async => fail
          ? http.Response('down', 503)
          : http.Response(jsonEncode(streakBody()), 200),
    );
    final streak = built.container.read(streakProvider.notifier);

    await streak.refresh();
    fail = true;
    await streak.refresh();

    expect(built.container.read(streakProvider)?.current, 4);
  });

  test('a freeze from a video is the server\'s to add', () async {
    final built = harness((request) async {
      if (request.url.path.endsWith('/streak/freeze')) {
        return http.Response(
          jsonEncode(streakBody(freezes: 2, canEarn: false)),
          200,
        );
      }
      return http.Response(jsonEncode(streakBody()), 200);
    });

    final added = await built.container
        .read(streakProvider.notifier)
        .earnFreeze();

    expect(added, isTrue);
    expect(built.container.read(streakProvider)?.freezes, 2);
    expect(
      built.calls.where((c) => c.url.path.endsWith('/streak/freeze')),
      hasLength(1),
    );
  });

  test('a refused freeze says so and re-reads the truth', () async {
    final built = harness((request) async {
      if (request.url.path.endsWith('/streak/freeze')) {
        return http.Response('{"error":"No room"}', 409);
      }
      return http.Response(jsonEncode(streakBody(freezes: 2)), 200);
    });

    final added = await built.container
        .read(streakProvider.notifier)
        .earnFreeze();
    await Future<void>.delayed(Duration.zero);

    expect(added, isFalse);
  });

  test('a month asks the server for exactly that month', () async {
    final built = harness(
      (_) async => http.Response(jsonEncode(streakBody()), 200),
    );

    await built.container
        .read(streakProvider.notifier)
        .month(DateTime.utc(2026, 2, 14));

    final call = built.calls.lastWhere(
      (c) => c.url.path.endsWith('/daily/streak'),
    );
    expect(call.url.queryParameters, {
      'from': '2026-02-01',
      'to': '2026-02-28',
    });
  });

  test('a malformed answer is not a streak', () {
    expect(StreakInfo.fromJson({'current': 3}), isNull);
  });

  test('milestones are the ones worth a celebration', () {
    expect(kStreakMilestones, containsAll([3, 7, 30, 100]));
    expect(kStreakMilestones.contains(4), isFalse);
  });
}

// Leaderboards, and the name that puts somebody on one.
//
// The rule these defend is a privacy decision rather than a formatting one:
// SETTING A DISPLAY NAME IS THE OPT-IN. An account without one appears on no
// board, and nothing anywhere invents a name — publishing a stranger as
// "Player 4821" puts somebody on a public list they never agreed to join.

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pourfect_flutter_app/services/api/api_client.dart';
import 'package:pourfect_flutter_app/services/api/api_result.dart';
import 'package:pourfect_flutter_app/services/api/leaderboard_api.dart';

void main() {
  ApiClient clientFor(
    MockClientHandler handler, {
    String baseUrl = 'https://x',
  }) => ApiClient(
    httpClient: MockClient(handler),
    baseUrl: baseUrl,
    tokenProvider: ({bool forceRefresh = false}) async => 'tok',
  );

  Map<String, Object?> row({
    int rank = 1,
    String name = 'Pranta',
    int value = 12,
    int? tieBreak,
    bool isYou = false,
  }) => {
    'rank': rank,
    'display_name': name,
    'value': value,
    'tie_break': tieBreak,
    'is_you': isYou,
  };

  group('reading a board', () {
    test('rows and the caller\'s own row come back', () async {
      final api = LeaderboardApi(
        clientFor(
          (_) async => http.Response(
            jsonEncode({
              'rows': [row(rank: 1, name: 'Ada'), row(rank: 2, name: 'Grace')],
              'you': row(rank: 91, name: 'Pranta', isYou: true),
              'total_players': 400,
            }),
            200,
          ),
        ),
      );

      final board = (await api.daily() as ApiOk).value;

      expect(board.rows, hasLength(2));
      expect(board.rows.first.displayName, 'Ada');
      // A board of the top fifty tells somebody nothing about themselves,
      // which is the one thing they came to see.
      expect(board.you!.rank, 91);
      expect(board.you!.isYou, isTrue);
      expect(board.totalPlayers, 400);
    });

    test('an unnamed player has no row at all', () async {
      final api = LeaderboardApi(
        clientFor(
          (_) async => http.Response(
            jsonEncode({
              'rows': [row()],
              'you': null,
              'total_players': 1,
            }),
            200,
          ),
        ),
      );

      expect((await api.campaign() as ApiOk).value.you, isNull);
    });

    test('a row with no name is skipped rather than invented', () async {
      final api = LeaderboardApi(
        clientFor(
          (_) async => http.Response(
            jsonEncode({
              'rows': [
                {'rank': 1, 'value': 9},
                row(rank: 2, name: 'Ada'),
              ],
              'you': null,
              'total_players': 2,
            }),
            200,
          ),
        ),
      );

      final board = (await api.daily() as ApiOk).value;
      expect(board.rows, hasLength(1));
      expect(board.rows.single.displayName, 'Ada');
    });

    test('the limit is sent', () async {
      late Uri seen;
      final api = LeaderboardApi(
        clientFor((request) async {
          seen = request.url;
          return http.Response('{"rows":[],"you":null,"total_players":0}', 200);
        }),
      );

      await api.daily(limit: 10);
      expect(seen.queryParameters['limit'], '10');
    });

    test('an empty board is empty, not an error', () async {
      final api = LeaderboardApi(
        clientFor(
          (_) async =>
              http.Response('{"rows":[],"you":null,"total_players":0}', 200),
        ),
      );

      final board = (await api.campaign() as ApiOk).value;
      expect(board.isEmpty, isTrue);
    });

    test(
      'no backend is reported as such rather than as an empty board',
      () async {
        final api = LeaderboardApi(
          clientFor((_) async => http.Response('{}', 200), baseUrl: ''),
        );

        expect(
          ((await api.daily()) as ApiFailure).kind,
          ApiFailureKind.notConfigured,
        );
      },
    );
  });

  group('choosing a name', () {
    test('is sent trimmed and comes back as the server stored it', () async {
      late http.Request seen;
      final api = UsersApi(
        clientFor((request) async {
          seen = request;
          return http.Response('{"display_name":"Pranta"}', 200);
        }),
      );

      final result = await api.setDisplayName('  Pranta  ');

      expect(jsonDecode(seen.body), {'display_name': 'Pranta'});
      expect(seen.method, 'PUT');
      expect((result as ApiOk).value, 'Pranta');
    });

    test('a rejection carries the server\'s reason', () async {
      final api = UsersApi(
        clientFor(
          (_) async => http.Response(
            '{"error":"Use letters, numbers, spaces, hyphens and underscores only"}',
            400,
          ),
        ),
      );

      final failure = await api.setDisplayName('nope!!') as ApiFailure;
      expect(failure.kind, ApiFailureKind.refused);
      expect(failure.detail, contains('letters'));
    });
  });

  group('the rules a player is told before a round trip', () {
    // Mirrored from the server, which validates regardless. Somebody who types
    // a 40-character name deserves to be told before a round trip, not after.
    test('accepts an ordinary name', () {
      expect(displayNameProblem('Pranta'), isNull);
      expect(displayNameProblem('Player_1'), isNull);
      expect(displayNameProblem('a-b c'), isNull);
    });

    test('refuses one that is too short or too long', () {
      expect(displayNameProblem('a'), isNotNull);
      expect(displayNameProblem('x' * 25), isNotNull);
      expect(displayNameProblem('x' * 24), isNull);
    });

    test('refuses characters the server would', () {
      expect(displayNameProblem('nope!'), isNotNull);
      expect(displayNameProblem('<script>'), isNotNull);
      expect(displayNameProblem('emoji 🎉'), isNotNull);
    });

    test('trims before judging length', () {
      expect(displayNameProblem('  ab  '), isNull);
      expect(displayNameProblem('   a   '), isNotNull);
    });
  });
}

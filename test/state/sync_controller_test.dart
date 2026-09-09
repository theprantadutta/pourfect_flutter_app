// Pushing progress, and reconciling what comes back.
//
// The rule this file exists to defend is the one that produces "the game
// deleted my progress" when it is broken: THE SERVER IS NOT AN AUTHORITY THAT
// OVERWRITES THE PHONE. It is another device's opinion, and the two are
// combined by taking the best of each — the same absorbing merge the backend
// applies, on this side too.
//
// Everything else here follows from sync being optional. No backend, no
// network, a server having a bad afternoon: all of them are ordinary states in
// which the game is fully playable, so none of them may throw, block, or lose
// anything.

import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pourfect_flutter_app/engine/board.dart';
import 'package:pourfect_flutter_app/engine/level.dart';
import 'package:pourfect_flutter_app/services/ads/ad_service.dart';
import 'package:pourfect_flutter_app/services/analytics/analytics_service.dart';
import 'package:pourfect_flutter_app/services/api/api_client.dart';
import 'package:pourfect_flutter_app/services/api/auth_service.dart';
import 'package:pourfect_flutter_app/services/iap/billing_service.dart';
import 'package:pourfect_flutter_app/state/monetization_controller.dart';
import 'package:pourfect_flutter_app/state/progress_repository.dart';
import 'package:pourfect_flutter_app/state/providers.dart';
import 'package:pourfect_flutter_app/state/sync_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

Level levelWith({required int id, int minMoves = 5}) => Level(
  id: id,
  board: Board.fromLists(const [
    [0, 0, 0],
    [1, 1, 1, 1],
    [0],
  ], capacity: 4),
  minMoves: minMoves,
  difficultyScore: 30,
  forcedMoveRatio: 1,
);

/// One row as the server sends it.
Map<String, Object?> serverRow({
  required int levelId,
  int stars = 3,
  int bestMoves = 5,
  int bestTimeSeconds = 0,
  int bestPoints = 0,
  String completedAt = '2026-01-01T00:00:00Z',
}) => {
  'level_id': levelId,
  'level_set_version': 1,
  'stars': stars,
  'best_moves': bestMoves,
  'completed_at': completedAt,
  'best_time_seconds': bestTimeSeconds,
  'best_points': bestPoints,
  'par_seconds': 80,
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  /// A container wired to a scripted server.
  ({ProviderContainer container, List<http.Request> calls}) harness({
    required MockClientHandler handler,
    String baseUrl = 'https://api.test',
    bool signedIn = true,
    bool adsRemoved = false,
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
        billingServiceProvider.overrideWithValue(const NoopBillingService()),
        adServiceProvider.overrideWithValue(const NoopAdService()),
        analyticsServiceProvider.overrideWithValue(
          const NoopAnalyticsService(),
        ),
      ],
    );
    addTearDown(container.dispose);

    return (container: container, calls: calls);
  }

  /// The `auth/device` answer, then whatever the test wants for the rest.
  MockClientHandler authThen(
    MockClientHandler rest, {
    bool adsRemoved = false,
  }) {
    return (request) async {
      if (request.url.path.endsWith('/auth/device')) {
        return http.Response(
          jsonEncode({
            'access_token': 'jwt',
            'expires_in_seconds': 3600,
            'user_id': 'u',
            'ads_removed': adsRemoved,
            'is_new_user': false,
            'is_anonymous': true,
            'auth_provider': 'anonymous',
          }),
          200,
        );
      }
      return rest(request);
    };
  }

  String syncBody(List<Map<String, Object?>> rows, {int changed = 0}) =>
      jsonEncode({
        'accepted': rows.length,
        'rejected': 0,
        'changed': changed,
        'progress': rows,
        'stats': {
          'total_stars': 0,
          'levels_completed': rows.length,
          'highest_level_cleared': 0,
          'daily_challenges_completed': 0,
          'daily_streak': 0,
          'total_points': 0,
          'total_best_time_seconds': 0,
        },
      });

  group('what gets pushed', () {
    test('the first sync of a session sends the whole campaign', () async {
      // A device that has been offline for a week has a dirty set that died
      // with the process. Sending everything is the only thing that recovers
      // it, and 150 rows of five integers is nothing.
      final built = harness(
        handler: authThen((_) async => http.Response(syncBody(const []), 200)),
      );

      final progress = built.container.read(progressProvider.notifier);
      for (final id in [1, 2, 3]) {
        progress.record(
          level: levelWith(id: id),
          levelSetVersion: 1,
          movesUsed: 5,
          elapsedSeconds: 60,
        );
      }

      await built.container.read(syncControllerProvider.notifier).syncNow();

      final sync = built.calls.firstWhere((c) => c.url.path.endsWith('/sync'));
      final items = (jsonDecode(sync.body) as Map)['items'] as List;
      expect(items.map((i) => (i as Map)['level_id']).toSet(), {1, 2, 3});
    });

    test('later syncs send only what changed', () async {
      final built = harness(
        handler: authThen((_) async => http.Response(syncBody(const []), 200)),
      );
      final sync = built.container.read(syncControllerProvider.notifier);
      final progress = built.container.read(progressProvider.notifier);

      progress.record(
        level: levelWith(id: 1),
        levelSetVersion: 1,
        movesUsed: 5,
        elapsedSeconds: 60,
      );
      await sync.syncNow();

      progress.record(
        level: levelWith(id: 2),
        levelSetVersion: 1,
        movesUsed: 5,
        elapsedSeconds: 60,
      );
      sync.markDirty(2);
      built.calls.clear();
      await sync.syncNow();

      final items =
          (jsonDecode(built.calls.single.body) as Map)['items'] as List;
      expect(items.map((i) => (i as Map)['level_id']), [2]);
    });

    test('stars and points are NOT sent', () async {
      // The server recomputes both from the move count and the clock against
      // the solver's proven optimum. Sending them would be sending numbers it
      // is obliged to ignore, and inviting a later reader to trust them.
      final built = harness(
        handler: authThen((_) async => http.Response(syncBody(const []), 200)),
      );

      built.container
          .read(progressProvider.notifier)
          .record(
            level: levelWith(id: 1),
            levelSetVersion: 1,
            movesUsed: 5,
            elapsedSeconds: 60,
          );
      await built.container.read(syncControllerProvider.notifier).syncNow();

      final sync = built.calls.firstWhere((c) => c.url.path.endsWith('/sync'));
      final item =
          ((jsonDecode(sync.body) as Map)['items'] as List).first as Map;

      expect(item.containsKey('stars'), isFalse);
      expect(item.containsKey('points'), isFalse);
      expect(item['moves_used'], 5);
      expect(item['elapsed_seconds'], 60);
    });

    test('a level cleared before the clock existed still syncs', () async {
      // Rows written before any of this shipped carry no time and no first
      // clear. They have to go up anyway; the server treats the zero as
      // unknown rather than as an instant solve.
      final built = harness(
        handler: authThen((_) async => http.Response(syncBody(const []), 200)),
      );

      built.container.read(progressProvider.notifier).debugSeed({
        7: const LevelProgress(
          levelId: 7,
          levelSetVersion: 1,
          stars: 2,
          bestMoves: 9,
        ),
      });

      await built.container.read(syncControllerProvider.notifier).syncNow();

      final sync = built.calls.firstWhere((c) => c.url.path.endsWith('/sync'));
      final item =
          ((jsonDecode(sync.body) as Map)['items'] as List).first as Map;

      expect(item['elapsed_seconds'], 0);
      expect(
        item['completed_at'],
        isA<String>(),
        reason:
            'the server requires an instant even when we never recorded one',
      );
    });
  });

  group('reconciling what comes back', () {
    test('a level only the server knows about appears locally', () async {
      // The reinstall case, and the reason any of this exists.
      final built = harness(
        handler: authThen(
          (_) async => http.Response(
            syncBody([serverRow(levelId: 4, stars: 3, bestMoves: 5)]),
            200,
          ),
        ),
      );

      await built.container.read(syncControllerProvider.notifier).syncNow();

      final row = built.container.read(progressProvider)[4];
      expect(row, isNotNull);
      expect(row!.stars, 3);
      expect(row.bestMoves, 5);
    });

    test('a WORSE server row never takes a local star away', () async {
      // Cleared on a tablet with three stars, replayed badly on a phone. The
      // phone's row is genuinely newer and genuinely worse; last-write-wins
      // would take the star and the player would be certain they had it.
      final built = harness(
        handler: authThen(
          (_) async => http.Response(
            syncBody([serverRow(levelId: 1, stars: 1, bestMoves: 30)]),
            200,
          ),
        ),
      );

      built.container.read(progressProvider.notifier).debugSeed({
        1: const LevelProgress(
          levelId: 1,
          levelSetVersion: 1,
          stars: 3,
          bestMoves: 5,
          bestTimeSeconds: 60,
          bestPoints: 1400,
        ),
      });

      await built.container.read(syncControllerProvider.notifier).syncNow();

      final row = built.container.read(progressProvider)[1]!;
      expect(row.stars, 3);
      expect(row.bestMoves, 5);
      expect(row.bestTimeSeconds, 60);
      expect(row.bestPoints, 1400);
    });

    test('a BETTER server row is taken, field by field', () async {
      final built = harness(
        handler: authThen(
          (_) async => http.Response(
            syncBody([
              serverRow(
                levelId: 1,
                stars: 3,
                bestMoves: 5,
                bestTimeSeconds: 45,
                bestPoints: 1800,
              ),
            ]),
            200,
          ),
        ),
      );

      built.container.read(progressProvider.notifier).debugSeed({
        1: const LevelProgress(
          levelId: 1,
          levelSetVersion: 1,
          stars: 2,
          bestMoves: 9,
          bestTimeSeconds: 300,
          bestPoints: 700,
        ),
      });

      await built.container.read(syncControllerProvider.notifier).syncNow();

      final row = built.container.read(progressProvider)[1]!;
      expect(row.stars, 3);
      expect(row.bestMoves, 5);
      expect(row.bestTimeSeconds, 45);
      expect(row.bestPoints, 1800);
    });

    test('each axis merges independently', () async {
      // The server can hold the better time while the phone holds the better
      // move count. Taking one side wholesale would discard half of a player's
      // own record.
      final built = harness(
        handler: authThen(
          (_) async => http.Response(
            syncBody([
              serverRow(
                levelId: 1,
                stars: 2,
                bestMoves: 12,
                bestTimeSeconds: 30,
              ),
            ]),
            200,
          ),
        ),
      );

      built.container.read(progressProvider.notifier).debugSeed({
        1: const LevelProgress(
          levelId: 1,
          levelSetVersion: 1,
          stars: 3,
          bestMoves: 5,
          bestTimeSeconds: 300,
        ),
      });

      await built.container.read(syncControllerProvider.notifier).syncNow();

      final row = built.container.read(progressProvider)[1]!;
      expect(row.bestMoves, 5, reason: 'the phone had the better moves');
      expect(row.bestTimeSeconds, 30, reason: 'the server had the better time');
      expect(row.stars, 3);
    });

    test('the first-clear instant only ever moves earlier', () async {
      final earlier = DateTime.utc(2026, 1, 1);
      final later = DateTime.utc(2026, 6, 1);

      final built = harness(
        handler: authThen(
          (_) async => http.Response(
            syncBody([
              serverRow(levelId: 1, completedAt: earlier.toIso8601String()),
            ]),
            200,
          ),
        ),
      );

      built.container.read(progressProvider.notifier).debugSeed({
        1: LevelProgress(
          levelId: 1,
          levelSetVersion: 1,
          stars: 3,
          bestMoves: 5,
          firstClearedAtMillis: later.millisecondsSinceEpoch,
        ),
      });

      await built.container.read(syncControllerProvider.notifier).syncNow();

      expect(
        built.container.read(progressProvider)[1]!.firstClearedAt,
        earlier,
      );
    });

    test('the merged result is written to disk, not just to memory', () async {
      // A reconciliation that only reaches memory is undone by the next
      // launch, which is the exact bug an earlier audit found in the local
      // restore path.
      final built = harness(
        handler: authThen(
          (_) async => http.Response(
            syncBody([serverRow(levelId: 9, stars: 3, bestMoves: 5)]),
            200,
          ),
        ),
      );

      await built.container.read(syncControllerProvider.notifier).syncNow();
      await Future<void>.delayed(Duration.zero);

      expect((await ProgressRepository().load())[9]?.stars, 3);
    });

    test('a malformed row is skipped, not fatal', () async {
      // A server that grows a field, or one bad row, must not cost the player
      // the other 149.
      final built = harness(
        handler: authThen(
          (_) async => http.Response(
            jsonEncode({
              'accepted': 0,
              'rejected': 0,
              'changed': 0,
              'progress': [
                {'nonsense': true},
                serverRow(levelId: 5, stars: 2, bestMoves: 8),
              ],
            }),
            200,
          ),
        ),
      );

      await built.container.read(syncControllerProvider.notifier).syncNow();

      expect(built.container.read(progressProvider)[5]?.stars, 2);
    });
  });

  group('when the server cannot be reached', () {
    test('nothing is lost and the level stays pending', () async {
      final built = harness(
        handler: authThen((_) async => http.Response('down', 503)),
      );

      final sync = built.container.read(syncControllerProvider.notifier);
      built.container
          .read(progressProvider.notifier)
          .record(
            level: levelWith(id: 1),
            levelSetVersion: 1,
            movesUsed: 5,
            elapsedSeconds: 60,
          );
      sync.markDirty(1);

      await sync.syncNow();

      expect(
        built.container.read(syncControllerProvider).status,
        SyncStatus.unreachable,
      );
      expect(built.container.read(progressProvider)[1], isNotNull);
      expect(built.container.read(syncControllerProvider).pending, 1);
    });

    test('the next attempt still carries the whole campaign', () async {
      // The full-push flag survives a failure. Otherwise the one sync that
      // was supposed to reconcile a week offline is also the one that is
      // allowed to fail and never be retried.
      var fail = true;
      final built = harness(
        handler: authThen((_) async {
          if (fail) return http.Response('down', 503);
          return http.Response(syncBody(const []), 200);
        }),
      );

      built.container
          .read(progressProvider.notifier)
          .record(
            level: levelWith(id: 1),
            levelSetVersion: 1,
            movesUsed: 5,
            elapsedSeconds: 60,
          );

      final sync = built.container.read(syncControllerProvider.notifier);
      await sync.syncNow();

      fail = false;
      built.calls.clear();
      await sync.syncNow();

      final items =
          (jsonDecode(built.calls.single.body) as Map)['items'] as List;
      expect(items, hasLength(1));
    });

    test('no backend configured is off, not an error', () async {
      final built = harness(
        handler: (_) async => http.Response('{}', 200),
        baseUrl: '',
      );

      await built.container.read(syncControllerProvider.notifier).syncNow();

      expect(
        built.container.read(syncControllerProvider).status,
        SyncStatus.off,
      );
      expect(built.calls, isEmpty);
    });

    test('no session means nothing is attempted', () async {
      final built = harness(
        handler: (_) async => http.Response('{}', 200),
        signedIn: false,
      );

      await built.container.read(syncControllerProvider.notifier).syncNow();

      expect(
        built.container.read(syncControllerProvider).status,
        SyncStatus.off,
      );
      expect(built.calls, isEmpty);
    });
  });

  group('concurrent syncs', () {
    test('collapse into one request', () async {
      // Level complete, app resume and a manual retry can all land together.
      final built = harness(
        handler: authThen((_) async {
          await Future<void>.delayed(const Duration(milliseconds: 20));
          return http.Response(syncBody(const []), 200);
        }),
      );

      final sync = built.container.read(syncControllerProvider.notifier);
      await Future.wait([sync.syncNow(), sync.syncNow(), sync.syncNow()]);

      expect(
        built.calls.where((c) => c.url.path.endsWith('/sync')),
        hasLength(1),
      );
    });
  });

  group('the entitlement the server knows about', () {
    test('is applied so a reinstall is ad-free immediately', () async {
      final built = harness(
        handler: authThen(
          (_) async => http.Response(syncBody(const []), 200),
          adsRemoved: true,
        ),
        adsRemoved: true,
      );

      await built.container.read(syncControllerProvider.notifier).syncNow();

      expect(built.container.read(monetizationProvider).adsRemoved, isTrue);
    });

    test('is never revoked by a sync', () async {
      // A sync during an outage, against a stale row, or before Play has
      // redelivered a token must not take away something somebody paid for
      // while they are using it.
      final built = harness(
        handler: authThen((_) async => http.Response(syncBody(const []), 200)),
      );

      built.container
          .read(monetizationProvider.notifier)
          .debugSet(adsRemoved: true);

      await built.container.read(syncControllerProvider.notifier).syncNow();

      expect(built.container.read(monetizationProvider).adsRemoved, isTrue);
    });
  });
}

// Regressions for the 2026-09-09 integration audit.
//
// Each of these is a way the client and the server disagreed about something
// the player owns — their purchase, their progress, their result, or their
// decision to erase it all. None of them was visible from either side alone,
// which is why they are here rather than spread across the handler tests: what
// they exercise is the ORDER things happen in and what survives the gaps.

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pourfect_flutter_app/engine/level.dart';
import 'package:pourfect_flutter_app/services/ads/ad_service.dart';
import 'package:pourfect_flutter_app/services/analytics/analytics_service.dart';
import 'package:pourfect_flutter_app/services/api/api_client.dart';
import 'package:pourfect_flutter_app/services/api/app_env.dart';
import 'package:pourfect_flutter_app/services/api/auth_service.dart';
import 'package:pourfect_flutter_app/services/api/progress_api.dart';
import 'package:pourfect_flutter_app/services/audio/audio_service.dart';
import 'package:pourfect_flutter_app/services/haptics/haptics_service.dart';
import 'package:pourfect_flutter_app/services/iap/billing_service.dart';
import 'package:pourfect_flutter_app/state/daily_controller.dart';
import 'package:pourfect_flutter_app/state/monetization_controller.dart';
import 'package:pourfect_flutter_app/state/progress_repository.dart';
import 'package:pourfect_flutter_app/state/providers.dart';
import 'package:pourfect_flutter_app/state/sync_controller.dart';
import 'package:pourfect_flutter_app/ui/screens/daily_challenge_screen.dart';
import 'package:pourfect_flutter_app/ui/theme/tokens.dart';
import 'package:pourfect_flutter_app/ui/widgets/board_view.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'purchase_verification_test.dart' show ReceiptBillingService;
import 'sync_controller_test.dart' show levelWith, serverRow;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  ({ProviderContainer container, List<http.Request> calls}) harness(
    MockClientHandler handler, {
    BillingService billing = const NoopBillingService(),
    bool adsRemoved = false,
    bool adsRevoked = false,
  }) {
    final calls = <http.Request>[];
    final client = ApiClient(
      baseUrl: 'https://audit.test',
      tokenProvider: ({bool forceRefresh = false}) async => 'test',
      httpClient: MockClient((request) async {
        calls.add(request);
        if (request.url.path.endsWith('/auth/device')) {
          return http.Response(
            jsonEncode({
              'access_token': 'jwt',
              'expires_in_seconds': 3600,
              'user_id': 'u',
              'ads_removed': adsRemoved,
              'ads_revoked': adsRevoked,
              'is_anonymous': true,
            }),
            200,
          );
        }
        return handler(request);
      }),
    );

    final container = ProviderContainer(
      overrides: [
        apiClientProvider.overrideWithValue(client),
        authServiceProvider.overrideWith(
          (ref) => AuthService(
            client: () => client,
            idTokenProvider: ({bool forceRefresh = false}) async => 'firebase',
          ),
        ),
        billingServiceProvider.overrideWithValue(billing),
        adServiceProvider.overrideWithValue(const NoopAdService()),
        analyticsServiceProvider.overrideWithValue(const NoopAnalyticsService()),
        audioServiceProvider.overrideWithValue(const NoopAudioService()),
        hapticsServiceProvider.overrideWithValue(const NoopHapticsService()),
      ],
    );
    addTearDown(container.dispose);
    addTearDown(client.close);
    return (container: container, calls: calls);
  }

  http.Response emptySync() => http.Response(
    jsonEncode({'accepted': 0, 'rejected': 0, 'changed': 0, 'progress': []}),
    200,
  );

  // ---- 1: a release build must not ship a placeholder backend -------------

  group('a release build refuses a backend URL that cannot be ours', () {
    test('the placeholder that ships in .env.example is refused', () {
      // The one this was written for. `.env.example` carries
      // PROD_API_BACKEND_URL=https://example.com, a real `.env` copied from it
      // inherits it, and a signed release then sends every player's progress
      // and Firebase token to a domain we do not own.
      expect(AppEnv.releaseUrlProblem('https://example.com'), isNotNull);
      expect(AppEnv.releaseUrlProblem('https://api.example.com'), isNotNull);
      expect(AppEnv.releaseUrlProblem('https://pourfect.example'), isNotNull);
    });

    test('cleartext is refused', () {
      // A bearer token and a Firebase ID token in plain text, and a release
      // build has no network security exception to permit it anyway.
      expect(AppEnv.releaseUrlProblem('http://api.pourfect.dev'), isNotNull);
    });

    test('a development machine is refused', () {
      for (final url in [
        'https://localhost:8394',
        'https://127.0.0.1:8394',
        'https://192.168.0.141:8394',
        'https://10.0.0.5',
        'https://172.20.1.1',
      ]) {
        expect(AppEnv.releaseUrlProblem(url), isNotNull, reason: url);
      }
    });

    test('a real https host is accepted', () {
      expect(AppEnv.releaseUrlProblem('https://api.pourfect.dev'), isNull);
      expect(AppEnv.releaseUrlProblem('https://pourfect.pranta.dev'), isNull);
      // A public IP is somebody's actual deployment.
      expect(AppEnv.releaseUrlProblem('https://46.62.254.22'), isNull);
    });

    test('unconfigured is not a problem, it is a supported state', () {
      // The campaign needs no server. Refusing to start over a missing
      // leaderboard would be absurd.
      expect(AppEnv.releaseUrlProblem(''), isNull);
    });

    test('nonsense is refused rather than attempted', () {
      expect(AppEnv.releaseUrlProblem('not a url'), isNotNull);
      expect(AppEnv.releaseUrlProblem('https://'), isNotNull);
    });

    test('a fill-me-in host is refused even though it parses', () {
      // Uri.tryParse is lenient enough to hand back a Uri whose host is
      // `<your-api-host>`, brackets included, so the most natural way anybody
      // writes a placeholder passed every other rule here and would have
      // shipped. The denylist cannot enumerate placeholders nobody has
      // thought of; requiring the host to be shaped like a hostname rules out
      // the class.
      expect(AppEnv.releaseUrlProblem('https://<your-api-host>'), isNotNull);
      expect(AppEnv.releaseUrlProblem('https://TODO fill me in'), isNotNull);
      expect(AppEnv.releaseUrlProblem('https://api_host.dev'), isNotNull);
      expect(AppEnv.releaseUrlProblem('https://-leading-hyphen.dev'), isNotNull);
      expect(AppEnv.releaseUrlProblem('https://double..dot.dev'), isNotNull);
    });

    test('the host the example file ships is refused', () {
      // Whatever `.env.example` carries is what a hurried copy carries, so
      // the two have to stay in step. `.example` is the reserved
      // documentation TLD.
      expect(
        AppEnv.releaseUrlProblem('https://api.your-domain.example'),
        isNotNull,
      );
    });

    test('the real production host is still accepted', () {
      expect(AppEnv.releaseUrlProblem('https://pourfect.pranta.dev'), isNull);
    });
  });

  // ---- 3: an authoritative revocation, and only that ----------------------

  group('a server revocation reaches the game, and nothing else does', () {
    test('a voided purchase turns the entitlement off, cache included', () async {
      final billing = ReceiptBillingService();
      addTearDown(billing.dispose);

      final built = harness(
        (_) async => emptySync(),
        billing: billing,
        adsRevoked: true,
      );
      built.container
          .read(monetizationProvider.notifier)
          .debugSet(adsRemoved: true);

      await built.container.read(syncControllerProvider.notifier).syncNow();

      expect(built.container.read(monetizationProvider).adsRemoved, isFalse);
      expect(
        billing.revoked,
        isTrue,
        reason: 'the billing cache still grants it, so the next launch undoes '
            'the refund',
      );
    });

    test('a bare "not entitled" does NOT revoke', () async {
      // The case that makes a plain false unusable as a revocation signal. The
      // device grants the moment the store says so, long before any server
      // hears about it — so "the server does not know about your purchase" is
      // what a purchase made ten seconds ago looks like, and stripping it
      // would take away something somebody has just paid for.
      final billing = ReceiptBillingService();
      addTearDown(billing.dispose);

      final built = harness((_) async => emptySync(), billing: billing);
      built.container
          .read(monetizationProvider.notifier)
          .debugSet(adsRemoved: true);

      await built.container.read(syncControllerProvider.notifier).syncNow();

      expect(built.container.read(monetizationProvider).adsRemoved, isTrue);
      expect(billing.revoked, isFalse);
    });

    test('a verification refused as voided revokes; an outage does not',
        () async {
      final billing = ReceiptBillingService();
      addTearDown(billing.dispose);

      var voided = false;
      final built = harness((request) async {
        if (!request.url.path.endsWith('/purchases/verify')) return emptySync();
        return voided
            ? http.Response(
                '{"state":"refunded","ads_removed":false,"ads_revoked":true}',
                200,
              )
            : http.Response('down', 503);
      }, billing: billing);

      built.container
          .read(monetizationProvider.notifier)
          .debugSet(adsRemoved: true);

      const receipt = PurchaseReceipt(
        productId: 'remove_ads',
        token: 't',
        restored: true,
      );

      billing.deliver(receipt);
      await pumpEventQueue();
      expect(
        built.container.read(monetizationProvider).adsRemoved,
        isTrue,
        reason: 'an unreachable server was treated as a refund',
      );

      voided = true;
      billing.deliver(receipt);
      await pumpEventQueue();
      expect(built.container.read(monetizationProvider).adsRemoved, isFalse);
    });
  });

  // ---- 4: a launch replay must survive a lazy verifier --------------------

  group('a receipt is never lost between the store and the verifier', () {
    test('one delivered before monetization exists is still verified', () async {
      // The shell starts billing at launch and the store replays every owned
      // purchase immediately. Monetization is lazy, so the broadcast had no
      // subscriber and the event was simply dropped — which was the ONLY retry
      // a purchase whose first verification failed had.
      final billing = ReceiptBillingService();
      addTearDown(billing.dispose);

      var verifications = 0;
      final built = harness((request) async {
        if (request.url.path.endsWith('/purchases/verify')) verifications++;
        return http.Response('{"state":"purchased","ads_removed":true}', 200);
      }, billing: billing);

      billing.deliver(
        const PurchaseReceipt(
          productId: 'remove_ads',
          token: 'replay',
          restored: true,
        ),
      );
      await pumpEventQueue();

      // Only now does anything read the provider — a hint, or the settings
      // screen, or nothing at all until tomorrow.
      built.container.read(monetizationProvider);
      await pumpEventQueue();

      expect(verifications, 1);
    });

    test('a verified receipt stops being retried', () async {
      final billing = ReceiptBillingService();
      addTearDown(billing.dispose);

      final built = harness(
        (_) async =>
            http.Response('{"state":"purchased","ads_removed":true}', 200),
        billing: billing,
      );

      billing.deliver(
        const PurchaseReceipt(
          productId: 'remove_ads',
          token: 'settled',
          restored: true,
        ),
      );
      built.container.read(monetizationProvider);
      await pumpEventQueue();

      expect(billing.pendingReceipts, isEmpty);
    });
  });

  // ---- 5: a sync acknowledges only what it sent ---------------------------

  group('a sync response settles only the rows it carried', () {
    test('a level finished mid-request is still pushed afterwards', () async {
      final entered = Completer<void>();
      final release = Completer<void>();
      final sent = <List<Object?>>[];

      final built = harness((request) async {
        sent.add((jsonDecode(request.body) as Map)['items'] as List);
        if (sent.length == 2) {
          entered.complete();
          await release.future;
        }
        return emptySync();
      });

      final sync = built.container.read(syncControllerProvider.notifier);
      await sync.syncNow();

      final progress = built.container.read(progressProvider.notifier);
      progress.record(
        level: levelWith(id: 1),
        levelSetVersion: 1,
        movesUsed: 5,
        elapsedSeconds: 55,
      );
      sync.markDirty(1);

      final inFlight = sync.syncNow();
      await entered.future;

      // Somebody plays two in a row. This one was never in the payload above.
      progress.record(
        level: levelWith(id: 2),
        levelSetVersion: 1,
        movesUsed: 5,
        elapsedSeconds: 55,
      );
      sync.markDirty(2);

      release.complete();
      await inFlight;
      await sync.syncNow();

      expect(
        sent.last.map((r) => (r! as Map)['level_id']),
        contains(2),
        reason: 'the in-flight response cleared a completion it never sent',
      );
    });

    test('the pending count reflects what is still owed', () async {
      final built = harness((_) async => http.Response('down', 503));
      final sync = built.container.read(syncControllerProvider.notifier);

      built.container
          .read(progressProvider.notifier)
          .record(
            level: levelWith(id: 1),
            levelSetVersion: 1,
            movesUsed: 5,
            elapsedSeconds: 55,
          );
      sync.markDirty(1);
      await sync.syncNow();

      expect(built.container.read(syncControllerProvider).pending, 1);
    });
  });

  // ---- 6: a score belongs to an attempt that happened ---------------------

  group('sync never invents an attempt', () {
    test('the submitted pair is the run that earned the score', () async {
      // Independent bests are not a run. Five moves over 110 seconds and ten
      // over 20 give a best-moves of 5 and a best-time of 20 — and that pair
      // scored 625 against two real attempts worth 250 and 313, doubling the
      // stored score with nobody at the phone.
      Map<String, Object?>? payload;
      final built = harness((request) async {
        payload =
            ((jsonDecode(request.body) as Map)['items'] as List).single
                as Map<String, Object?>;
        return emptySync();
      });

      final progress = built.container.read(progressProvider.notifier);
      await progress.restored;
      progress.record(
        level: levelWith(id: 1),
        levelSetVersion: 1,
        movesUsed: 5,
        elapsedSeconds: 110,
      );
      progress.record(
        level: levelWith(id: 1),
        levelSetVersion: 1,
        movesUsed: 10,
        elapsedSeconds: 20,
      );

      final actualBest = built.container.read(progressProvider)[1]!.bestPoints;

      await ProgressApi(
        built.container.read(apiClientProvider),
      ).sync(built.container.read(progressProvider).values);

      final reconstructed = pointsFor(
        minMoves: 5,
        movesUsed: payload!['moves_used']! as int,
        elapsedSeconds: payload!['elapsed_seconds']! as int,
      );

      expect(reconstructed, lessThanOrEqualTo(actualBest));
    });

    test('the independent bests still travel, as statistics', () async {
      // They are worth keeping and worth showing. What they are not is a run.
      Map<String, Object?>? payload;
      final built = harness((request) async {
        payload =
            ((jsonDecode(request.body) as Map)['items'] as List).single
                as Map<String, Object?>;
        return emptySync();
      });

      final progress = built.container.read(progressProvider.notifier);
      await progress.restored;
      progress.record(
        level: levelWith(id: 1),
        levelSetVersion: 1,
        movesUsed: 5,
        elapsedSeconds: 110,
      );
      progress.record(
        level: levelWith(id: 1),
        levelSetVersion: 1,
        movesUsed: 10,
        elapsedSeconds: 20,
      );

      await ProgressApi(
        built.container.read(apiClientProvider),
      ).sync(built.container.read(progressProvider).values);

      expect(payload!['best_moves'], 5);
      expect(payload!['best_time_seconds'], 20);
    });

    test('a row from before the clock claims no score at all', () async {
      // Sending its move count with a borrowed time would be the same
      // fabrication. Stars come from moves and are unaffected.
      Map<String, Object?>? payload;
      final built = harness((request) async {
        payload =
            ((jsonDecode(request.body) as Map)['items'] as List).single
                as Map<String, Object?>;
        return emptySync();
      });

      built.container.read(progressProvider.notifier).debugSeed({
        1: const LevelProgress(
          levelId: 1,
          levelSetVersion: 1,
          stars: 3,
          bestMoves: 5,
          bestTimeSeconds: 40,
        ),
      });

      await ProgressApi(
        built.container.read(apiClientProvider),
      ).sync(built.container.read(progressProvider).values);

      expect(payload!['moves_used'], 5);
      expect(
        payload!['elapsed_seconds'],
        0,
        reason: 'a time from a different run was passed off as this one',
      );
    });
  });

  // ---- 8: a reset stays reset --------------------------------------------

  group('reset progress means reset', () {
    test('the next sync does not put it all back', () async {
      // The server honours the reset, as a real one does — which is the whole
      // point: the erase has to reach it, or the next snapshot restores
      // everything the player asked to remove.
      var erased = false;
      final built = harness((request) async {
        if (request.url.path.endsWith('/progress/reset')) {
          erased = true;
          return http.Response('{"levels_cleared":1}', 200);
        }
        return http.Response(
          jsonEncode({
            'accepted': 0,
            'rejected': 0,
            'changed': 0,
            'progress': erased ? <Object?>[] : [serverRow(levelId: 1)],
          }),
          200,
        );
      });

      final sync = built.container.read(syncControllerProvider.notifier);
      await sync.syncNow();
      expect(built.container.read(progressProvider), isNotEmpty);

      await built.container.read(progressProvider.notifier).resetAll();
      await sync.reset();
      await sync.syncNow();

      expect(
        built.container.read(progressProvider),
        isEmpty,
        reason: 'the server snapshot restored what the player erased',
      );
    });

    test('it asks the server to erase, not just this device', () async {
      final built = harness((_) async => emptySync());

      await built.container.read(syncControllerProvider.notifier).reset();

      expect(
        built.calls.any((c) => c.url.path.endsWith('/progress/reset')),
        isTrue,
      );
    });

    test('a reset that could not be delivered blocks merging until it is',
        () async {
      // An offline reset must be a reset, not a pause. Without this the first
      // sync of the next session merges every star straight back.
      var offline = true;
      final built = harness((request) async {
        if (offline) return http.Response('down', 503);
        if (request.url.path.endsWith('/progress/reset')) {
          return http.Response('{"levels_cleared":1}', 200);
        }
        return http.Response(
          jsonEncode({
            'accepted': 0,
            'rejected': 0,
            'changed': 0,
            'progress': [serverRow(levelId: 1)],
          }),
          200,
        );
      });

      final sync = built.container.read(syncControllerProvider.notifier);
      await built.container.read(progressProvider.notifier).resetAll();
      await sync.reset();

      // Still offline: the merge must not happen.
      await sync.syncNow();
      expect(built.container.read(progressProvider), isEmpty);

      // Back online: the reset lands, and STILL nothing is merged in the same
      // breath — that snapshot was computed before the erase.
      offline = false;
      await sync.syncNow();
      expect(built.container.read(progressProvider), isEmpty);
    });
  });

  // ---- 7: a daily result belongs to the board it was played on ------------

  testWidgets('a daily completion stays bound to the board that was opened', (
    tester,
  ) async {
    // The shell refreshes the daily on every app resume. A board left open
    // across midnight UTC therefore had tomorrow's challenge loaded underneath
    // it, and finishing yesterday's submitted its moves as today's result —
    // scored against a different optimum, on a different day's board.
    var date = '2026-09-08';
    Map<String, Object?>? submission;

    final built = harness((request) async {
      if (request.url.path.endsWith('/daily/submit')) {
        submission = jsonDecode(request.body) as Map<String, Object?>;
        return http.Response('{"stars":3,"moves":3,"daily_streak":1}', 200);
      }
      return http.Response(
        jsonEncode({
          'date': date,
          'capacity': 2,
          'min_moves': 3,
          'color_count': 2,
          'empty_tube_count': 1,
          'tubes': date == '2026-09-08'
              ? [
                  [0, 1],
                  [1, 0],
                  <int>[],
                ]
              : [
                  [1, 0],
                  [0, 1],
                  <int>[],
                ],
        }),
        200,
      );
    });

    final daily = built.container.read(dailyProvider.notifier);
    await daily.ensureLoaded();

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: built.container,
        child: MaterialApp(
          theme: ThemeData.dark().copyWith(
            extensions: const [PourfectTokens.dark],
          ),
          home: DailyChallengeScreen(onExit: () {}),
        ),
      ),
    );
    await tester.pump();

    final openedBoard = built.container.read(gameControllerProvider)!.board;

    // Midnight passes while the screen is up.
    date = '2026-09-09';
    await daily.refresh();
    await tester.pump();

    expect(
      built.container.read(gameControllerProvider)!.board,
      same(openedBoard),
      reason: 'the board changed under the player',
    );

    for (final tube in [0, 2, 1, 0, 1, 2]) {
      tester.widget<BoardView>(find.byType(BoardView)).onTapTube(tube);
      await tester.pump(const Duration(milliseconds: 400));
    }
    await tester.pump();

    expect(built.container.read(gameControllerProvider)!.isWon, isTrue);
    expect(submission, isNotNull);
    expect(
      submission!['date'],
      '2026-09-08',
      reason: 'yesterday’s board was submitted as today’s result',
    );
  });
}

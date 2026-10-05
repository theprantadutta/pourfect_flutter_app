// When the hub offers notifications, and what the switches in Settings do.
//
// The owner's rule (2026-10-05): ask after a few wins, and if the answer was
// not yes, ask again occasionally, about every 15 days, never as nagging.

import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pourfect_flutter_app/services/api/api_client.dart';
import 'package:pourfect_flutter_app/services/api/push_service.dart';
import 'package:pourfect_flutter_app/state/notification_prefs.dart';
import 'package:pourfect_flutter_app/state/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  ProviderContainer harness({
    PushPermission permission = PushPermission.notAsked,
    bool serverUp = true,
  }) {
    final client = ApiClient(
      httpClient: MockClient((request) async {
        if (!serverUp) return http.Response('', 503);
        if (request.method == 'PUT') return http.Response(request.body, 200);
        return http.Response(
          jsonEncode({'reminders': true, 'news': true}),
          200,
        );
      }),
      baseUrl: 'https://api.test',
      tokenProvider: ({bool forceRefresh = false}) async => 'tok',
    );
    final container = ProviderContainer(
      overrides: [
        pushServiceProvider.overrideWithValue(
          PushService(
            client: () => client,
            readPermission: () async => permission,
            requestPermission: () async => PushPermission.granted,
            readToken: () async => null,
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  final day = DateTime(2026, 10, 5, 20);

  group('the offer on the hub', () {
    test('not before the third level', () async {
      final prefs = harness().read(notificationPrefsProvider.notifier);
      expect(await prefs.shouldSoftAsk(solved: 2, now: day), isFalse);
      expect(await prefs.shouldSoftAsk(solved: 3, now: day), isTrue);
    });

    test('never to somebody who already has them on', () async {
      final prefs = harness(permission: PushPermission.granted)
          .read(notificationPrefsProvider.notifier);
      expect(await prefs.shouldSoftAsk(solved: 40, now: day), isFalse);
    });

    test('again after 15 days, not before', () async {
      final prefs = harness().read(notificationPrefsProvider.notifier);
      await prefs.markSoftAskShown(now: day);

      expect(
        await prefs.shouldSoftAsk(
          solved: 9,
          now: day.add(const Duration(days: 14)),
        ),
        isFalse,
      );
      expect(
        await prefs.shouldSoftAsk(solved: 9, now: day.add(kSoftAskEvery)),
        isTrue,
      );
    });

    test(
      'still offered to somebody who said no to the system prompt',
      () async {
        // Android will not show its prompt again, so the card is the only way
        // back; it opens the system settings for them.
        final prefs = harness(permission: PushPermission.denied)
            .read(notificationPrefsProvider.notifier);
        expect(await prefs.shouldSoftAsk(solved: 9, now: day), isTrue);
      },
    );

    test('stops after six offers', () async {
      final prefs = harness().read(notificationPrefsProvider.notifier);
      var at = day;
      for (var i = 0; i < kSoftAskMax; i++) {
        expect(
          await prefs.shouldSoftAsk(solved: 9, now: at),
          isTrue,
          reason: 'offer ${i + 1}',
        );
        await prefs.markSoftAskShown(now: at);
        at = at.add(kSoftAskEvery);
      }
      expect(await prefs.shouldSoftAsk(solved: 9, now: at), isFalse);
    });
  });

  group('the switches in Settings', () {
    test('move once the server agrees', () async {
      final container = harness();
      final prefs = container.read(notificationPrefsProvider.notifier);

      expect(await prefs.setReminders(false), isTrue);
      expect(
        container.read(notificationPrefsProvider).prefs.reminders,
        isFalse,
      );
      expect(container.read(notificationPrefsProvider).prefs.news, isTrue);
    });

    test('stay put when the server did not take it', () async {
      // A switch that shows "off" while the server keeps sending is worse
      // than one that refuses to move.
      final container = harness(serverUp: false);
      final prefs = container.read(notificationPrefsProvider.notifier);

      expect(await prefs.setNews(false), isFalse);
      expect(container.read(notificationPrefsProvider).prefs.news, isTrue);
    });
  });
}

// Push registration, and the one moment it is appropriate to ask.
//
// The rule these defend is a product one rather than a technical one:
// PERMISSION IS NEVER ASKED FOR AT LAUNCH. A prompt on first run is a
// measurable D1 killer, and organic Play ranking — this game's only
// acquisition channel — weights retention heavily. The ask belongs where it
// means something: just after somebody finishes a daily challenge, which is
// also the only population the reminder job will ever send to.

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pourfect_flutter_app/services/api/api_client.dart';
import 'package:pourfect_flutter_app/services/api/push_service.dart';

void main() {
  ({PushService push, List<http.Request> calls}) build({
    PushPermission current = PushPermission.notAsked,
    PushPermission afterAsking = PushPermission.granted,
    String? token = 'fcm-token',
    String baseUrl = 'https://api.test',
    void Function()? onAsk,
  }) {
    final calls = <http.Request>[];
    final client = ApiClient(
      httpClient: MockClient((request) {
        calls.add(request);
        return Future.value(http.Response('', 200));
      }),
      baseUrl: baseUrl,
      tokenProvider: ({bool forceRefresh = false}) async => 'tok',
    );

    return (
      push: PushService(
        client: () => client,
        readPermission: () async => current,
        requestPermission: () async {
          onAsk?.call();
          return afterAsking;
        },
        readToken: () async => token,
      ),
      calls: calls,
    );
  }

  group('on launch', () {
    test('an already-granted token is re-registered', () async {
      // Tokens rotate on reinstall, on restore, and whenever the OS decides.
      // Re-registering every session is what keeps the stored row pointing at
      // a device that still exists.
      final built = build(current: PushPermission.granted);

      expect(await built.push.registerIfPermitted(), isTrue);
      expect(built.calls.single.url.path, '/api/v1/notifications/token');
    });

    test('nothing is asked and nothing is sent when never granted', () async {
      var asked = false;
      final built = build(
        current: PushPermission.notAsked,
        onAsk: () => asked = true,
      );

      expect(await built.push.registerIfPermitted(), isFalse);
      expect(asked, isFalse, reason: 'launch prompted for notifications');
      expect(built.calls, isEmpty);
    });

    test('a declined permission is not revisited', () async {
      var asked = false;
      final built = build(
        current: PushPermission.denied,
        onAsk: () => asked = true,
      );

      expect(await built.push.registerIfPermitted(), isFalse);
      expect(asked, isFalse);
    });
  });

  group('the deliberate ask', () {
    test('registers the token when the answer is yes', () async {
      final built = build(afterAsking: PushPermission.granted);

      expect(await built.push.requestAndRegister(), isTrue);
      expect(built.calls, hasLength(1));
    });

    test('sends the token and the platform', () async {
      final built = build();
      await built.push.requestAndRegister();

      final body = built.calls.single.body;
      expect(body, contains('fcm-token'));
      expect(body, anyOf(contains('android'), contains('ios')));
    });

    test('sends nothing when the answer is no', () async {
      final built = build(afterAsking: PushPermission.denied);

      expect(await built.push.requestAndRegister(), isFalse);
      expect(built.calls, isEmpty);
    });

    test('somebody who already declined is never asked again', () async {
      // A second prompt is not available on iOS at all, and nagging on Android
      // earns an uninstall rather than a reminder.
      var asked = false;
      final built = build(
        current: PushPermission.denied,
        onAsk: () => asked = true,
      );

      expect(await built.push.requestAndRegister(), isFalse);
      expect(asked, isFalse);
    });

    test('a granted permission with no token registers nothing', () async {
      // Play Services missing, or Firebase never initialised.
      final built = build(afterAsking: PushPermission.granted, token: null);

      expect(await built.push.requestAndRegister(), isFalse);
      expect(built.calls, isEmpty);
    });
  });

  group('when registration cannot be delivered', () {
    test('it is a silent no, not a failure the player sees', () async {
      // One missed reminder. The next launch tries again.
      final built = build(current: PushPermission.granted, baseUrl: '');

      expect(await built.push.registerIfPermitted(), isFalse);
      expect(built.calls, isEmpty);
    });
  });
}

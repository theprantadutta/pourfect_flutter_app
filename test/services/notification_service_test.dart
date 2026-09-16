// What a notification says it is, and where a tap should therefore land.
//
// The platform half of this service — the channel, the permission prompt, the
// small icon — can only be checked on a device, and it was. What IS testable
// here is the part that decides things, and it is the part most likely to be
// broken by a backend that starts sending a new `type` one day.

import 'package:flutter_test/flutter_test.dart';
import 'package:pourfect_flutter_app/services/notifications/notification_service.dart';

void main() {
  group('reading what a message is about', () {
    test('the daily reminder is recognised', () {
      // Exactly what NotificationJobService puts on the wire.
      expect(
        PourfectNotification.fromData({'kind': 'daily_reminder'}),
        PourfectNotification.dailyChallenge,
      );
    });

    test('the key the server does NOT send is not recognised', () {
      // The first draft of the client read `type` and looked for
      // `daily_challenge`. Both were invented here rather than read off the
      // server, and every reminder tap would have opened the hub in silence.
      expect(
        PourfectNotification.fromData({'type': 'daily_challenge'}),
        PourfectNotification.unknown,
      );
    });

    test('a type this build has never heard of is not dropped', () {
      // A NEWER BACKEND IS NOT AN ERROR. The server is deployed separately and
      // will eventually send kinds that shipped after this build — those are
      // still shown, and still open something, rather than being discarded by
      // an app that decided it knew the full list.
      expect(
        PourfectNotification.fromData({'kind': 'streak_about_to_break'}),
        PourfectNotification.unknown,
      );
    });

    test('a message carrying no type at all is unknown, not a crash', () {
      // Data-only messages, and anything sent by hand from the Firebase
      // console, arrive with no `type` key.
      expect(
        PourfectNotification.fromData(const {}),
        PourfectNotification.unknown,
      );
    });

    test('a type of the wrong shape is unknown, not a crash', () {
      // `data` is Map<String, dynamic> off the wire, so the value is whatever
      // the sender put there — a number, a nested map, anything.
      expect(
        PourfectNotification.fromData({'kind': 42}),
        PourfectNotification.unknown,
      );
      expect(
        PourfectNotification.fromData({'kind': null}),
        PourfectNotification.unknown,
      );
    });
  });

  group('the keys are a wire contract', () {
    test('the key is spelled the way the backend sends it', () {
      // NOT ours to choose. NotificationJobService sends
      // `["kind"] = "daily_reminder"`; changing this string silently routes
      // every reminder to the hub instead of the challenge, and nothing
      // anywhere reports an error. Verified against the backend source, after
      // the first draft of this file guessed and got it wrong.
      expect(PourfectNotification.dailyChallenge.key, 'daily_reminder');
    });

    test('every value has a distinct key', () {
      final keys = PourfectNotification.values.map((v) => v.key).toList();
      expect(keys.toSet().length, keys.length);
    });
  });
}

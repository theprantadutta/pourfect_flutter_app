// What a notification says it is, and where a tap should therefore land.
//
// The platform half of this service (the channel, the permission prompt, the
// small icon) can only be checked on a device, and it was. What IS testable
// here is the part that decides things, and it is the part most likely to be
// broken by a backend that starts sending something new one day.

import 'package:flutter_test/flutter_test.dart';
import 'package:pourfect_flutter_app/services/notifications/notification_service.dart';

void main() {
  group('reading where a tap goes', () {
    test('the server names the screen under nav_route', () {
      final tap = NotificationTap.fromData({
        'kind': 'new_levels',
        'nav_route': 'rankings',
        'nid': 'abc',
      });
      expect(tap.destination, NotificationDestination.rankings);
      expect(tap.kind, 'new_levels');
      expect(tap.id, 'abc');
    });

    test('every screen the server can name is one the app knows', () {
      // Wire contract with NotificationRoutes on the server.
      for (final key in ['home', 'daily', 'journey', 'rankings', 'stats']) {
        expect(NotificationDestination.fromKey(key), isNotNull, reason: key);
      }
    });

    test('a key called "route" is ignored', () {
      // Android hands data keys to Flutter as launch extras, and "route" is
      // read as the initial route: Snake Classic froze on its splash screen.
      // The app reads nav_route and nothing else.
      final tap = NotificationTap.fromData({
        'kind': 'broadcast',
        'route': 'daily',
      });
      expect(tap.destination, NotificationDestination.home);
    });

    test('an older server that sent only the kind still opens the daily', () {
      expect(
        NotificationTap.fromData({'kind': 'daily_reminder'}).destination,
        NotificationDestination.daily,
      );
      expect(
        NotificationTap.fromData({'kind': 'new_levels'}).destination,
        NotificationDestination.journey,
      );
    });

    test('the key the server does NOT send is not read', () {
      // `type` was the first draft's mistake: every reminder tap would have
      // opened the hub, with no error anywhere.
      final tap = NotificationTap.fromData({'type': 'daily_reminder'});
      expect(tap.kind, 'unknown');
      expect(tap.destination, NotificationDestination.home);
    });

    test('a kind this build has never heard of opens the hub, not nothing', () {
      final tap = NotificationTap.fromData({'kind': 'tournament_started'});
      expect(tap.kind, 'tournament_started');
      expect(tap.destination, NotificationDestination.home);
    });

    test('a payload of the wrong shape is a hub tap, not a crash', () {
      expect(
        NotificationTap.fromData({'kind': 42, 'nav_route': 7, 'nid': 3})
            .destination,
        NotificationDestination.home,
      );
      expect(NotificationTap.fromData(const {}).id, isNull);
    });
  });

  group('a tap before anybody is listening', () {
    test('is held, not dropped', () async {
      // The tap that LAUNCHED the app is read during start-up, beside the
      // first frames. A broadcast stream with no subscriber drops it.
      final service = NotificationService(firebaseIsReady: () => false);
      service.debugEmit(NotificationTap.fromData({'kind': 'daily_reminder'}));

      final heard = <NotificationTap>[];
      final sub = service.taps.listen(heard.add);
      final pending = service.takePending();

      expect(heard, isEmpty);
      expect(pending.single.destination, NotificationDestination.daily);
      expect(service.takePending(), isEmpty, reason: 'handed over twice');
      await sub.cancel();
    });

    test('goes straight to a listener once there is one', () async {
      final service = NotificationService(firebaseIsReady: () => false);
      final heard = <NotificationTap>[];
      final sub = service.taps.listen(heard.add);

      service.debugEmit(NotificationTap.fromData({'kind': 'win_back'}));
      await Future<void>.delayed(Duration.zero);

      expect(heard.single.kind, 'win_back');
      expect(service.takePending(), isEmpty);
      await sub.cancel();
    });
  });
}

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pourfect_flutter_app/services/analytics/analytics_service.dart';
import 'package:pourfect_flutter_app/services/analytics/pending_abandon.dart';
import 'package:pourfect_flutter_app/services/analytics/screen_observer.dart';
import 'package:pourfect_flutter_app/ui/transitions.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The analytics added on 2026-11-09: screen names, user properties, the
/// parked abandon, and what a purchase carries.
void main() {
  group('screen names', () {
    test('come from the route name, ids dropped', () {
      expect(AnalyticsScreenObserver.screenNameFor('/'), 'home');
      expect(AnalyticsScreenObserver.screenNameFor('/daily'), 'daily');
      expect(AnalyticsScreenObserver.screenNameFor('/level/12'), 'level');
      expect(
        AnalyticsScreenObserver.screenNameFor('/event/play'),
        'event_play',
      );
    });

    test('an unnamed route has no screen name', () {
      expect(AnalyticsScreenObserver.screenNameFor(null), isNull);
    });

    test('pushing a page reports it, popping reports what it uncovers', () {
      final analytics = RecordingAnalyticsService();
      final observer = AnalyticsScreenObserver(() => analytics);
      final home = PourfectPageRoute<void>(
        settings: const RouteSettings(name: '/'),
        builder: (_) => const SizedBox(),
      );
      final daily = PourfectPageRoute<void>(
        settings: const RouteSettings(name: '/daily'),
        builder: (_) => const SizedBox(),
      );

      observer.didPush(home, null);
      observer.didPush(daily, home);
      observer.didPop(daily, home);

      expect(analytics.ofType<ScreenView>().map((e) => e.screenName), [
        'home',
        'daily',
        'home',
      ]);
    });

    test('an unnamed page is not reported', () {
      final analytics = RecordingAnalyticsService();
      final observer = AnalyticsScreenObserver(() => analytics);
      observer.didPush(
        PourfectPageRoute<void>(builder: (_) => const SizedBox()),
        null,
      );
      expect(analytics.events, isEmpty);
    });
  });

  test('levels solved is banded by ten', () {
    expect(levelsSolvedBand(0), '0');
    expect(levelsSolvedBand(1), '1-10');
    expect(levelsSolvedBand(10), '1-10');
    expect(levelsSolvedBand(11), '11-20');
    expect(levelsSolvedBand(150), '141-150');
  });

  group('purchase value', () {
    test('carries value and currency when the store gave both', () {
      const event = IapPurchased(
        productId: 'remove_ads',
        placement: 'settings',
        price: 290,
        currency: 'BDT',
      );
      expect(event.parameters['value'], 290.0);
      expect(event.parameters['currency'], 'BDT');
    });

    test('leaves them out rather than sending half of the pair', () {
      const event = IapPurchased(
        productId: 'remove_ads',
        placement: 'settings',
        price: 290,
      );
      expect(event.parameters.containsKey('value'), isFalse);
      expect(event.parameters.containsKey('currency'), isFalse);
    });
  });

  group('the parked abandon', () {
    const abandon = LevelAbandon(
      levelId: 41,
      levelSetVersion: 3,
      moves: 17,
      minMoves: 22,
      durationSeconds: 95,
      reason: AbandonReason.backgrounded,
      progress: 0.5,
    );

    test('survives a round trip through its parameters', () {
      final back = LevelAbandon.fromParameters(abandon.parameters)!;
      expect(back.parameters, abandon.parameters);
    });

    test('an unreadable one is dropped, not half-sent', () {
      expect(LevelAbandon.fromParameters({'level_id': 'x'}), isNull);
    });

    test('is kept on disk until taken, and taken once', () async {
      SharedPreferences.setMockInitialValues({});
      const store = PrefsPendingAbandonStore();
      await store.save(abandon);

      final taken = await store.take();
      expect(taken?.levelId, 41);
      expect(await store.take(), isNull);
    });

    test('clearing it means nothing is sent next launch', () async {
      SharedPreferences.setMockInitialValues({});
      const store = PrefsPendingAbandonStore();
      await store.save(abandon);
      await store.clear();

      final analytics = RecordingAnalyticsService();
      await sendAbandonLeftByLastRun(store, analytics);
      expect(analytics.events, isEmpty);
    });
  });
}

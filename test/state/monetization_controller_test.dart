// The monetization provider, built headlessly.
//
// This file exists because of a specific bug that cost a device round-trip to
// find. `build()` assigned `state` before returning an initial value, which
// Riverpod forbids. In debug that is a red error box; in a RELEASE build it is
// a blank grey rectangle where the settings screen should be, with nothing
// pointing at monetization at all. The whole screen was gone and the symptom
// looked like layout.
//
// Constructing the provider in a test catches it in milliseconds. The rule
// worth keeping: any Notifier reachable from a screen deserves a test that
// merely BUILDS it, whatever else is or is not asserted.

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pourfect_flutter_app/services/ads/ad_service.dart';
import 'package:pourfect_flutter_app/services/analytics/analytics_service.dart';
import 'package:pourfect_flutter_app/services/iap/billing_service.dart';
import 'package:pourfect_flutter_app/state/monetization_controller.dart';
import 'package:pourfect_flutter_app/state/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Billing with a settable entitlement and a real stream.
class FakeBillingService implements BillingService {
  final _changes = StreamController<bool>.broadcast();
  bool _adsRemoved;

  FakeBillingService({bool adsRemoved = false}) : _adsRemoved = adsRemoved;

  void emit(bool value) {
    _adsRemoved = value;
    _changes.add(value);
  }

  @override
  bool get adsRemoved => _adsRemoved;

  @override
  Stream<bool> get adsRemovedChanges => _changes.stream;

  @override
  StoreProduct? get removeAdsProduct =>
      const StoreProduct(id: 'remove_ads', title: 'Remove Ads', price: r'$1.99');

  @override
  Future<PurchaseOutcome> buyRemoveAds() async {
    emit(true);
    return PurchaseOutcome.purchased;
  }

  @override
  Future<void> init() async {}

  @override
  Future<void> restorePurchases() async {}

  @override
  Future<void> dispose() async {
    await _changes.close();
  }
}

ProviderContainer containerWith(FakeBillingService billing) {
  final container = ProviderContainer(
    overrides: [
      billingServiceProvider.overrideWithValue(billing),
      adServiceProvider.overrideWithValue(const NoopAdService()),
      analyticsServiceProvider.overrideWithValue(
        const NoopAnalyticsService(),
      ),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('build', () {
    test('constructing the provider does not throw', () {
      // The regression. If `build()` ever writes `state` again, this is where
      // it surfaces — not on a phone, in a release APK, as a grey rectangle.
      final container = containerWith(FakeBillingService());
      expect(() => container.read(monetizationProvider), returnsNormally);
    });

    test('an entitlement known at build time is honoured immediately', () {
      // A player who already paid must not see ads on the very first level
      // completion after launch, before any stream event has arrived. So the
      // value has to be read INTO the initial state, not pushed in afterwards.
      final container = containerWith(FakeBillingService(adsRemoved: true));
      expect(container.read(monetizationProvider).adsRemoved, isTrue);
    });

    test('starts with the full complement of free hints', () {
      final container = containerWith(FakeBillingService());
      final state = container.read(monetizationProvider);
      expect(state.freeHintsRemaining, kFreeHints);
      expect(state.hintNeedsAd, isFalse);
    });
  });

  group('entitlement changes', () {
    test('a later purchase reaches the state through the stream', () async {
      final billing = FakeBillingService();
      final container = containerWith(billing);
      expect(container.read(monetizationProvider).adsRemoved, isFalse);

      billing.emit(true);
      await Future<void>.delayed(Duration.zero);

      expect(container.read(monetizationProvider).adsRemoved, isTrue);
    });
  });

  group('the free hint budget survives a relaunch', () {
    test('a stored count is honoured by the FIRST spend', () async {
      // The bug this exists to prevent, and it is a revenue bug rather than a
      // cosmetic one.
      //
      // This provider is LAZY: nothing builds it until the first hint is
      // asked for, so build() and the first spend happen in the same breath.
      // If the spend does not wait for the persisted count to load, it is
      // always measured against a freshly-zeroed counter — which means every
      // launch hands out a full set of free hints and the rewarded prompt,
      // the primary revenue driver, is never reached by anybody willing to
      // reopen the app.
      SharedPreferences.setMockInitialValues({'pourfect.hints.used': kFreeHints});

      final container = containerWith(FakeBillingService());
      final notifier = container.read(monetizationProvider.notifier);

      expect(
        await notifier.consumeFreeHint(),
        isFalse,
        reason: 'the budget was already spent before this launch',
      );
      expect(container.read(monetizationProvider).hintNeedsAd, isTrue);
    });

    test('a partially spent budget resumes where it left off', () async {
      SharedPreferences.setMockInitialValues({'pourfect.hints.used': kFreeHints - 1});

      final container = containerWith(FakeBillingService());
      final notifier = container.read(monetizationProvider.notifier);

      expect(await notifier.consumeFreeHint(), isTrue, reason: 'one was left');
      expect(await notifier.consumeFreeHint(), isFalse);
    });

    test('restoring can never hand a spent hint back', () async {
      // The other half of the same race. A plain assignment in _restore walks
      // the counter BACKWARDS when a spend lands while it is still loading,
      // so the merge has to be monotonic — spending only ever increases the
      // count, so the larger number is always the true one.
      SharedPreferences.setMockInitialValues({});

      final container = containerWith(FakeBillingService());
      final notifier = container.read(monetizationProvider.notifier);

      for (var i = 0; i < kFreeHints; i++) {
        await notifier.consumeFreeHint();
      }
      // Let any in-flight restore settle on top of the spending.
      await Future<void>.delayed(Duration.zero);

      expect(container.read(monetizationProvider).freeHintsRemaining, 0);
      expect(await notifier.consumeFreeHint(), isFalse);
    });
  });

  group('free hints', () {
    test('spends down to zero, then reports that an ad is needed', () async {
      final container = containerWith(FakeBillingService());
      final notifier = container.read(monetizationProvider.notifier);

      for (var i = 0; i < kFreeHints; i++) {
        expect(await notifier.consumeFreeHint(), isTrue, reason: 'hint $i');
      }
      expect(await notifier.consumeFreeHint(), isFalse);

      final state = container.read(monetizationProvider);
      expect(state.freeHintsRemaining, 0);
      expect(state.hintNeedsAd, isTrue);
    });

    test('buying Remove Ads does not make hints free', () async {
      // Stated in the design and worth pinning: the purchase stops
      // INTERRUPTIONS. Rewarded video stays an opt-in the player can choose,
      // because taking a feature away from somebody who just paid is how a
      // $1.99 sale becomes a refund.
      final container = containerWith(FakeBillingService());
      final notifier = container.read(monetizationProvider.notifier);

      for (var i = 0; i < kFreeHints; i++) {
        await notifier.consumeFreeHint();
      }
      await notifier.buyRemoveAds(placement: 'test');

      final state = container.read(monetizationProvider);
      expect(state.adsRemoved, isTrue);
      expect(state.hintNeedsAd, isTrue);
    });
  });
}

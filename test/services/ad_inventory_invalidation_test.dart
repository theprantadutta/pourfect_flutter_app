// A load that completes after we stopped wanting it.
//
// The consent gate stops a request from going out. It cannot stop one that has
// already gone: an ad load takes a moment, its callback is not cancellable,
// and it fires whenever the network gets round to it. So withdrawing consent
// emptied the cache and a request already in flight then filled it back up —
// quietly undoing the discard that had just been promised. The same shape
// refilled a service that had been disposed, leaving it holding an ad object
// nothing would ever dispose.
//
// The request cannot be recalled. Its RESULT can be thrown away, and that is
// what a generation marker buys: every load remembers the batch it belongs to,
// and anything that invalidates inventory moves on to the next one.
//
// These tests reach into the plugin's own registry to deliver a callback by
// hand. That is deliberate — the defect only exists in the gap between the
// request and its answer, and nothing observable from outside the SDK can open
// that gap on demand.

import 'package:flutter_test/flutter_test.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
// ignore: implementation_imports
import 'package:google_mobile_ads/src/ad_instance_manager.dart';
import 'package:pourfect_flutter_app/services/ads/ad_service.dart';
import 'package:pourfect_flutter_app/services/ads/admob_ad_service.dart';
import 'package:pourfect_flutter_app/services/ads/consent_gate.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// Ad ids the plugin asked the platform to load, newest last.
  late List<int> interstitialIds;
  late List<int> rewardedIds;

  setUp(() {
    interstitialIds = [];
    rewardedIds = [];

    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

    messenger.setMockMethodCallHandler(instanceManager.channel, (call) async {
      final id = (call.arguments as Map)['adId'] as int?;
      if (id == null) return null;
      if (call.method == 'loadInterstitialAd') interstitialIds.add(id);
      if (call.method == 'loadRewardedAd') rewardedIds.add(id);
      return null;
    });

    addTearDown(
      () => messenger.setMockMethodCallHandler(instanceManager.channel, null),
    );
  });

  AdMobAdService serviceWith(ConsentGate gate) =>
      AdMobAdService(consent: gate)..debugMarkInitialised();

  /// Delivers the load callback the platform would have delivered.
  void completeLoad(int adId) {
    final ad = instanceManager.adFor(adId)!;
    switch (ad) {
      case InterstitialAd():
        ad.adLoadCallback.onAdLoaded(ad);
      case RewardedAd():
        ad.rewardedAdLoadCallback.onAdLoaded(ad);
      default:
        fail('unexpected ad type for $adId');
    }
  }

  group('consent withdrawn while a load is in flight', () {
    test('a late interstitial is discarded, not cached', () async {
      final gate = ConsentGate()..canRequestAds = true;
      final service = serviceWith(gate);

      service.preload();
      await Future<void>.delayed(Duration.zero);
      expect(interstitialIds, isNotEmpty, reason: 'nothing was requested');

      gate.canRequestAds = false;
      await service.applyConsent();
      expect(service.isInterstitialReady, isFalse);

      // The network answers the request we can no longer recall.
      completeLoad(interstitialIds.last);

      expect(
        service.isInterstitialReady,
        isFalse,
        reason: 'a late load restored inventory after consent was withdrawn',
      );
      await service.dispose();
    });

    test('a late rewarded ad is discarded too', () async {
      final gate = ConsentGate()..canRequestAds = true;
      final service = serviceWith(gate);

      service.preload();
      await Future<void>.delayed(Duration.zero);
      expect(rewardedIds, isNotEmpty);

      gate.canRequestAds = false;
      await service.applyConsent();

      for (final id in rewardedIds) {
        completeLoad(id);
      }

      // The only externally visible proof for rewarded inventory: a cached ad
      // would be shown, an absent one reports unavailable.
      expect(
        await service.showRewarded(RewardedPlacement.hint),
        RewardOutcome.unavailable,
      );
      await service.dispose();
    });
  });

  group('consent withdrawn and granted again before the answer arrives', () {
    test('the old result is still discarded', () async {
      // The case a bare "is it allowed right now?" check gets wrong: by the
      // time the callback fires, consent says yes again — but this particular
      // ad was requested, then explicitly thrown away, and reviving it means
      // the discard never really happened.
      final gate = ConsentGate()..canRequestAds = true;
      final service = serviceWith(gate);

      service.preload();
      await Future<void>.delayed(Duration.zero);
      final abandoned = interstitialIds.last;

      gate.canRequestAds = false;
      await service.applyConsent();

      gate.canRequestAds = true;
      await service.applyConsent();
      await Future<void>.delayed(Duration.zero);

      completeLoad(abandoned);

      expect(
        service.isInterstitialReady,
        isFalse,
        reason: 'inventory discarded under withdrawal came back to life',
      );

      // ...and the fresh request made after the re-grant is honoured, so this
      // is not passing by simply refusing everything.
      expect(
        interstitialIds.length,
        greaterThan(1),
        reason: 'granting consent again did not request anything',
      );
      completeLoad(interstitialIds.last);
      expect(service.isInterstitialReady, isTrue);

      await service.dispose();
    });
  });

  group('after the service is disposed', () {
    test('a late load is discarded rather than cached', () async {
      final gate = ConsentGate()..canRequestAds = true;
      final service = serviceWith(gate);

      service.preload();
      await Future<void>.delayed(Duration.zero);
      final pending = interstitialIds.last;

      await service.dispose();
      completeLoad(pending);

      expect(
        service.isInterstitialReady,
        isFalse,
        reason: 'a disposed service was refilled and now leaks that ad',
      );
    });
  });
}

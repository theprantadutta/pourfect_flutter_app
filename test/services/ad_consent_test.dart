// Consent is checked before REQUESTING an ad, on every path.
//
// The follow-up audit's finding: `preload()` honoured the gate and nothing
// else did. `showRewarded()` called the private loader directly whenever its
// cache was empty — which is every first hint of a session — and so did every
// retry and every post-dismissal refill. Reproduced with the native channel
// mocked: canRequestAds=false still emitted loadRewardedAd.
//
// This asserts against the actual platform traffic rather than against a flag,
// because the bug was precisely that the flag was consulted somewhere other
// than where the request happens. Google's UMP integration requires the check
// before the REQUEST; by the time an ad is on screen it is far too late.

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pourfect_flutter_app/services/ads/ad_service.dart';
import 'package:pourfect_flutter_app/services/ads/admob_ad_service.dart';
import 'package:pourfect_flutter_app/services/ads/consent_gate.dart';

/// The plugin's own channel name.
const _adChannel = 'plugins.flutter.io/google_mobile_ads';

/// Every method name the plugin sent, in order.
///
/// Read out of the RAW payload rather than decoded, deliberately: the plugin
/// wraps its arguments in a private codec that a test cannot construct, and
/// the only thing worth asserting here is whether a load went out at all.
class ChannelSpy {
  final List<String> methods = [];

  static const _watched = [
    'loadRewardedAd',
    'loadInterstitialAd',
    'loadBannerAd',
  ];

  void install() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler(_adChannel, (ByteData? message) async {
          if (message != null) _record(message);
          // A well-formed empty success, so the plugin does not see a missing
          // implementation and take a different branch than production would.
          return const StandardMethodCodec().encodeSuccessEnvelope(null);
        });
  }

  void remove() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler(_adChannel, null);
  }

  void _record(ByteData message) {
    final bytes = message.buffer.asUint8List(
      message.offsetInBytes,
      message.lengthInBytes,
    );
    final text = String.fromCharCodes(bytes.where((b) => b >= 32 && b < 127));
    for (final method in _watched) {
      if (text.contains(method)) methods.add(method);
    }
  }

  bool get sawAnyLoad => methods.isNotEmpty;

  bool sawLoadOf(String method) => methods.contains(method);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ChannelSpy channel;

  setUp(() {
    channel = ChannelSpy()..install();
    addTearDown(channel.remove);
  });

  AdMobAdService serviceWith({required bool consented}) {
    final gate = ConsentGate()..canRequestAds = consented;
    final service = AdMobAdService(consent: gate)..debugMarkInitialised();
    return service;
  }

  group('with consent granted, ads really are requested', () {
    // Without this the rest of the file could pass by simply never working.

    test('preload puts loads on the wire', () async {
      serviceWith(consented: true).preload();
      await Future<void>.delayed(Duration.zero);

      expect(channel.sawLoadOf('loadInterstitialAd'), isTrue);
      expect(channel.sawLoadOf('loadRewardedAd'), isTrue);
    });

    test('an empty rewarded cache refills', () async {
      final service = serviceWith(consented: true);

      final outcome = await service.showRewarded(RewardedPlacement.hint);

      expect(outcome, RewardOutcome.unavailable);
      expect(
        channel.sawLoadOf('loadRewardedAd'),
        isTrue,
        reason: 'the refill that makes the next hint instant went missing',
      );
    });
  });

  group('with consent withheld, nothing is requested', () {
    test('preload requests nothing', () async {
      serviceWith(consented: false).preload();
      await Future<void>.delayed(Duration.zero);

      expect(channel.sawAnyLoad, isFalse);
    });

    test('showRewarded requests nothing — the path that leaked', () async {
      final service = serviceWith(consented: false);

      final outcome = await service.showRewarded(RewardedPlacement.hint);

      expect(outcome, RewardOutcome.unavailable);
      expect(
        channel.sawLoadOf('loadRewardedAd'),
        isFalse,
        reason: 'a rewarded ad was requested without a basis for requesting it',
      );
    });

    test('every rewarded placement is covered, not just hints', () async {
      final service = serviceWith(consented: false);

      for (final placement in RewardedPlacement.values) {
        await service.showRewarded(placement);
      }

      expect(channel.sawAnyLoad, isFalse);
    });

    test('showInterstitial neither shows nor refills', () async {
      final service = serviceWith(consented: false);

      expect(await service.showInterstitial(), isFalse);
      expect(channel.sawAnyLoad, isFalse);
    });
  });

  group('an SDK that never initialised requests nothing either', () {
    test('consent alone is not enough', () async {
      // `_ready` is false here: consent granted, SDK not up. Requesting in that
      // state is how an ad unit gets served before test-device registration
      // has been applied.
      final service = AdMobAdService(
        consent: ConsentGate()..canRequestAds = true,
      );

      service.preload();
      await service.showRewarded(RewardedPlacement.hint);
      await Future<void>.delayed(Duration.zero);

      expect(channel.sawAnyLoad, isFalse);
    });
  });

  group('a consent change takes effect without a relaunch', () {
    test('withdrawing it stops future requests', () async {
      final gate = ConsentGate()..canRequestAds = true;
      final service = AdMobAdService(consent: gate)..debugMarkInitialised();

      gate.canRequestAds = false;
      await service.applyConsent();
      channel.methods.clear();

      service.preload();
      await service.showRewarded(RewardedPlacement.hint);
      await Future<void>.delayed(Duration.zero);

      expect(channel.sawAnyLoad, isFalse);
      expect(
        service.isInterstitialReady,
        isFalse,
        reason: 'inventory requested under the old answer was kept',
      );
    });

    test('granting it starts requesting again', () async {
      // Somebody who opens the privacy form and opts IN should not have to
      // relaunch before the next hint has a video behind it.
      final gate = ConsentGate()..canRequestAds = false;
      final service = AdMobAdService(consent: gate)..debugMarkInitialised();

      service.preload();
      expect(channel.sawAnyLoad, isFalse);

      gate.canRequestAds = true;
      await service.applyConsent();
      await Future<void>.delayed(Duration.zero);

      expect(channel.sawLoadOf('loadRewardedAd'), isTrue);
    });
  });

  group('the privacy-options entry point is exposed', () {
    test('the service reports what the SDK required', () {
      final gate = ConsentGate()..privacyOptionsRequired = true;
      expect(AdMobAdService(consent: gate).privacyOptionsRequired, isTrue);

      expect(
        AdMobAdService(consent: ConsentGate()).privacyOptionsRequired,
        isFalse,
      );
    });
  });
}

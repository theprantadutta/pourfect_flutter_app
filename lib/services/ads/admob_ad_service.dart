/// AdMob implementation.
///
/// Kept thin. All the judgement about WHETHER to show an ad lives in
/// `InterstitialPolicy`, which is pure Dart and heavily tested; this file only
/// loads, shows, and reports honestly what happened.
///
/// Two habits worth keeping:
///
///  * **Every ad is single-use.** AdMob invalidates an ad object once shown, so
///    each one is disposed and a fresh load kicked off immediately. Reusing a
///    shown ad fails silently, which looks exactly like "no fill" and wastes a
///    long time to diagnose.
///  * **Nothing here throws.** A player with no Play Services, no network or a
///    blocked ad domain still gets a working game — they just get no ads.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ad_ids.dart';
import 'consent_gate.dart';
import 'ad_service.dart';

class AdMobAdService implements AdService {
  /// Decides whether an ad may be requested at all. Exposed so the settings
  /// screen can offer the privacy-options form where one is required.
  final ConsentGate consent = ConsentGate();

  InterstitialAd? _interstitial;
  final Map<RewardedPlacement, RewardedAd> _rewarded = {};

  bool _ready = false;
  bool _showing = false;
  bool _disposed = false;

  /// Failed load attempts this session, per placement.
  final Map<String, int> _retries = {};

  static const _maxRetries = 3;

  @override
  Future<void> init() async {
    if (_ready) return;
    try {
      // Registered BEFORE initialize so the very first request already
      // honours it. Set after the first ad has loaded, the device has
      // already taken a live impression.
      if (kAdMobTestDeviceIds.isNotEmpty) {
        await MobileAds.instance.updateRequestConfiguration(
          RequestConfiguration(testDeviceIds: kAdMobTestDeviceIds),
        );
      }

      // Consent BEFORE any request. Requesting first and asking later is the
      // arrangement the whole gate exists to prevent.
      await consent.ensure();

      await MobileAds.instance.initialize();
      _ready = true;

      if (consent.canRequestAds) {
        preload();
      } else {
        debugPrint('[ads] consent not granted — no ads will be requested');
      }

      if (kUsingTestAdIds) {
        debugPrint(
          '[ads] GOOGLE TEST ad units (non-release build) — every ad should '
          'carry a "Test Ad" label. An unlabelled ad here means ad_ids.dart '
          'is broken; stop and fix it before tapping anything.',
        );
      } else {
        debugPrint(
          '[ads] LIVE ad units. Test devices registered: '
          '${kAdMobTestDeviceIds.length}. Tapping a live ad on an '
          'unregistered device is invalid traffic.',
        );
      }
    } catch (error) {
      debugPrint('[ads] init failed, continuing without ads: $error');
      _ready = false;
    }
  }

  @override
  bool get isInterstitialReady => _interstitial != null;

  @override
  void preload() {
    if (!_ready) return;
    if (!consent.canRequestAds) return;
    _loadInterstitial();
    for (final placement in RewardedPlacement.values) {
      _loadRewarded(placement);
    }
  }

  void _loadInterstitial() {
    if (_interstitial != null) return;
    InterstitialAd.load(
      adUnitId: AdIds.interstitialLevelComplete,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitial = ad;
          _retries.remove('interstitial');
        },
        onAdFailedToLoad: (error) {
          _interstitial = null;
          debugPrint('[ads] interstitial load failed: ${error.code}');
          _scheduleRetry(() => _loadInterstitial(), 'interstitial');
        },
      ),
    );
  }

  void _loadRewarded(RewardedPlacement placement) {
    if (_rewarded[placement] != null) return;
    RewardedAd.load(
      adUnitId: _unitFor(placement),
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewarded[placement] = ad;
          _retries.remove(placement.eventName);
        },
        onAdFailedToLoad: (error) {
          _rewarded.remove(placement);
          debugPrint(
            '[ads] rewarded ${placement.eventName} load failed: ${error.code}',
          );
          _scheduleRetry(() => _loadRewarded(placement), placement.eventName);
        },
      ),
    );
  }

  static String _unitFor(RewardedPlacement placement) => switch (placement) {
    RewardedPlacement.hint => AdIds.rewardedHint,
    RewardedPlacement.extraTube => AdIds.rewardedExtraTube,
    RewardedPlacement.levelSkip => AdIds.rewardedLevelSkip,
  };

  @override
  Future<bool> showInterstitial() async {
    final ad = _interstitial;
    // The guard against a second ad while one is on screen. Without it a
    // double-tap can queue two, and the player is hit twice in a row.
    if (ad == null || _showing) return false;

    _interstitial = null;
    _showing = true;
    final closed = Completer<bool>();

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _showing = false;
        _loadInterstitial();
        if (!closed.isCompleted) closed.complete(true);
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _showing = false;
        _loadInterstitial();
        debugPrint('[ads] interstitial show failed: ${error.code}');
        if (!closed.isCompleted) closed.complete(false);
      },
    );

    try {
      await ad.show();
    } catch (error) {
      _showing = false;
      _loadInterstitial();
      debugPrint('[ads] interstitial threw: $error');
      return false;
    }
    return closed.future;
  }

  @override
  Future<RewardOutcome> showRewarded(RewardedPlacement placement) async {
    final ad = _rewarded[placement];
    if (ad == null || _showing) {
      _loadRewarded(placement);
      return RewardOutcome.unavailable;
    }

    _rewarded.remove(placement);
    _showing = true;

    final done = Completer<RewardOutcome>();
    // Set by the reward callback, read when the ad closes. AdMob fires the
    // reward BEFORE dismissal, so the outcome is only final once both have
    // happened — completing on the reward callback alone would report success
    // for an ad the player then failed to close.
    var earned = false;

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _showing = false;
        _loadRewarded(placement);
        if (!done.isCompleted) {
          done.complete(
            earned ? RewardOutcome.earned : RewardOutcome.dismissed,
          );
        }
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _showing = false;
        _loadRewarded(placement);
        debugPrint('[ads] rewarded show failed: ${error.code}');
        if (!done.isCompleted) done.complete(RewardOutcome.failed);
      },
    );

    try {
      await ad.show(onUserEarnedReward: (_, _) => earned = true);
    } catch (error) {
      _showing = false;
      _loadRewarded(placement);
      debugPrint('[ads] rewarded threw: $error');
      return RewardOutcome.failed;
    }
    return done.future;
  }

  /// Retries a failed load, backing off, a bounded number of times.
  ///
  /// A failed load used to be permanent for the session: nothing retried, so a
  /// player who launched with no signal got no interstitials and no rewarded
  /// videos even after reconnecting — which quietly removes the hint paywall
  /// and the revenue with it.
  ///
  /// Bounded and backed off on purpose. Retrying a no-fill in a tight loop
  /// burns battery and gets an app throttled by the network; the app-resume
  /// preload in GameScreen covers the longer outages.
  void _scheduleRetry(void Function() load, String label) {
    final attempts = _retries.update(label, (n) => n + 1, ifAbsent: () => 1);
    if (attempts > _maxRetries) {
      debugPrint('[ads] $label giving up after $attempts attempts this session');
      return;
    }

    // 2s, 8s, 32s.
    final delay = Duration(seconds: 2 << (2 * (attempts - 1)));
    Future<void>.delayed(delay, () {
      if (_disposed) return;
      load();
    });
  }

  @override
  Future<void> dispose() async {
    _disposed = true;
    await _interstitial?.dispose();
    _interstitial = null;
    for (final ad in _rewarded.values) {
      await ad.dispose();
    }
    _rewarded.clear();
  }
}

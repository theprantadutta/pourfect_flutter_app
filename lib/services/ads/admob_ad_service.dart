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
import 'ad_service.dart';

class AdMobAdService implements AdService {
  InterstitialAd? _interstitial;
  final Map<RewardedPlacement, RewardedAd> _rewarded = {};

  bool _ready = false;
  bool _showing = false;

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

      await MobileAds.instance.initialize();
      _ready = true;
      preload();

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
        onAdLoaded: (ad) => _interstitial = ad,
        onAdFailedToLoad: (error) {
          _interstitial = null;
          debugPrint('[ads] interstitial load failed: ${error.code}');
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
        onAdLoaded: (ad) => _rewarded[placement] = ad,
        onAdFailedToLoad: (error) {
          _rewarded.remove(placement);
          debugPrint(
            '[ads] rewarded ${placement.eventName} load failed: ${error.code}',
          );
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

  @override
  Future<void> dispose() async {
    await _interstitial?.dispose();
    _interstitial = null;
    for (final ad in _rewarded.values) {
      await ad.dispose();
    }
    _rewarded.clear();
  }
}

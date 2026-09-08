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
  /// Decides whether an ad may be requested at all.
  ///
  /// Injectable so a test can state the consent answer directly. Everything
  /// this class does with consent has to be provable without a device, since
  /// the failure it guards against is invisible on one: an ad requested
  /// without a legal basis looks exactly like an ad requested with one.
  final ConsentGate consent;

  AdMobAdService({ConsentGate? consent}) : consent = consent ?? ConsentGate();

  InterstitialAd? _interstitial;
  final Map<RewardedPlacement, RewardedAd> _rewarded = {};

  bool _ready = false;
  bool _showing = false;
  bool _disposed = false;

  /// Failed load attempts this session, per placement.
  final Map<String, int> _retries = {};

  /// Which batch of requests is still wanted.
  ///
  /// A load is not instant and its callback is not cancellable. Withdrawing
  /// consent cleared the cache, but a request already in flight completed
  /// afterwards and cached its result — quietly undoing the discard that had
  /// just been promised. The same shape refilled a DISPOSED service, which
  /// then leaked the ad it was holding.
  ///
  /// So every load carries the generation it was issued in, and anything that
  /// invalidates inventory bumps it. A callback from an older generation
  /// disposes its ad instead of keeping it: the request cannot be recalled,
  /// but its result can be thrown away.
  int _generation = 0;

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

  /// THE SINGLE GATE. Every path that could put a request on the wire asks
  /// this first, and nothing requests an ad any other way.
  ///
  /// It used to be checked in `preload()` alone, which is the one place that
  /// does not matter: `showRewarded()` called the private loader directly
  /// whenever its cache was empty, and so did every retry and every
  /// post-dismissal refill. Reproduced with the native channel mocked —
  /// canRequestAds=false still emitted loadRewardedAd. A guard on one caller
  /// is not a gate, it is a comment.
  ///
  /// Google's UMP integration requires consent to be checked before REQUESTING
  /// ads, not before showing them; by the time an ad is on screen the request
  /// has already happened.
  bool get _mayRequestAds => _ready && !_disposed && consent.canRequestAds;

  @override
  bool get privacyOptionsRequired => consent.privacyOptionsRequired;

  @override
  Future<void> showPrivacyOptions() async {
    await consent.showPrivacyOptions();
    await applyConsent();
  }

  /// Brings cached inventory into line with the current consent answer.
  ///
  /// Both directions matter. Withdrawing consent has to DISCARD ads that were
  /// requested while it was granted — keeping them means the next hint shows
  /// an ad the player has just refused, from a request they have just
  /// withdrawn the basis for. Granting it has to start filling again, or the
  /// player who has just opted in gets nothing until they relaunch.
  @visibleForTesting
  Future<void> applyConsent() async {
    if (consent.canRequestAds) {
      preload();
      return;
    }

    // Invalidated FIRST, before anything is disposed. A load that completes
    // between these two lines must already be seen as stale, or it lands in a
    // cache that has just been emptied.
    _generation++;

    await _interstitial?.dispose();
    _interstitial = null;
    for (final ad in _rewarded.values) {
      await ad.dispose();
    }
    _rewarded.clear();
    _retries.clear();
  }

  /// Marks the SDK as initialised, for tests that cannot call [init].
  @visibleForTesting
  void debugMarkInitialised() => _ready = true;

  @override
  void preload() {
    if (!_mayRequestAds) return;
    _loadInterstitial();
    for (final placement in RewardedPlacement.values) {
      _loadRewarded(placement);
    }
  }

  void _loadInterstitial() {
    if (_interstitial != null) return;
    if (!_mayRequestAds) return;

    final generation = _generation;
    InterstitialAd.load(
      adUnitId: AdIds.interstitialLevelComplete,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          if (_isStale(generation)) {
            ad.dispose();
            return;
          }
          _interstitial = ad;
          _retries.remove('interstitial');
        },
        onAdFailedToLoad: (error) {
          if (_isStale(generation)) return;
          _interstitial = null;
          debugPrint('[ads] interstitial load failed: ${error.code}');
          _scheduleRetry(() => _loadInterstitial(), 'interstitial');
        },
      ),
    );
  }

  /// Whether a callback belongs to a batch of requests we no longer want.
  ///
  /// Checks the generation AND current eligibility. The generation catches a
  /// result that was superseded; the eligibility check catches the case where
  /// the answer changed back and forth while a single load was in flight, and
  /// covers disposal, which no generation bump alone should have to remember.
  bool _isStale(int generation) => generation != _generation || !_mayRequestAds;

  void _loadRewarded(RewardedPlacement placement) {
    if (_rewarded[placement] != null) return;
    if (!_mayRequestAds) return;

    final generation = _generation;
    RewardedAd.load(
      adUnitId: _unitFor(placement),
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          if (_isStale(generation)) {
            ad.dispose();
            return;
          }
          _rewarded[placement] = ad;
          _retries.remove(placement.eventName);
        },
        onAdFailedToLoad: (error) {
          if (_isStale(generation)) return;
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
    //
    // Consent is checked here as well as at load time. An ad cached before the
    // player withdrew consent must not be shown afterwards, and the
    // withdrawal can land between the two.
    if (ad == null || _showing || !consent.canRequestAds) return false;

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

    // THE PATH THAT LEAKED. A hint request with an empty cache reached
    // `_loadRewarded` directly, so the gate that `preload()` respected was
    // simply stepped around by the busiest caller in the app.
    //
    // The refill attempt stays — it is what makes the next hint instant — but
    // it now passes the same gate as everything else, and a player who has not
    // consented gets "no video available" rather than a request they never
    // agreed to.
    if (ad == null || _showing || !consent.canRequestAds) {
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
      debugPrint(
        '[ads] $label giving up after $attempts attempts this session',
      );
      return;
    }

    final generation = _generation;

    // 2s, 8s, 32s.
    final delay = Duration(seconds: 2 << (2 * (attempts - 1)));
    Future<void>.delayed(delay, () {
      // A retry armed under one consent answer must not fire under another.
      // The loader would refuse it anyway, but a timer that outlives its
      // reason is worth cancelling where it is armed rather than relying on
      // the far end.
      if (_isStale(generation)) return;
      load();
    });
  }

  @override
  Future<void> dispose() async {
    _disposed = true;
    // Same reason as consent withdrawal: a load still in flight would
    // otherwise complete into a service nobody is using and hold an ad object
    // that nothing will ever dispose.
    _generation++;
    await _interstitial?.dispose();
    _interstitial = null;
    for (final ad in _rewarded.values) {
      await ad.dispose();
    }
    _rewarded.clear();
  }
}

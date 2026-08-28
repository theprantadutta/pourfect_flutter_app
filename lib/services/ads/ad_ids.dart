/// AdMob identifiers.
///
/// The live ids are real, and which set is used is decided by BUILD MODE
/// rather than by a constant somebody has to remember to flip:
///
///   * release  → the live units below
///   * debug / profile → Google's official test units, always
///
/// That direction matters. A flat "swap the constants when you go live" leaves
/// every developer build serving real ads, and tapping your own live ad is the
/// single most reliable way to get an AdMob account flagged for invalid
/// traffic — a suspension that takes weeks to appeal and costs the whole
/// revenue line. Tying it to `kReleaseMode` makes that impossible by
/// construction instead of by discipline.
///
/// Test ads serve real placements filled with placeholder creative and carry a
/// "Test Ad" label across the top. That label is the proof the plumbing works.
/// Seeing an UNLABELLED ad in a debug build means this file is broken and
/// should be stopped immediately.
///
/// The distinction that causes outages: an APP id uses a **tilde** and lives in
/// `AndroidManifest.xml`; an AD UNIT id uses a **slash** and lives here.
/// Swapping them either crashes on launch ("Invalid application ID") or, far
/// worse, silently never loads an ad.
///
/// The app id in the manifest is the LIVE one in every build. That is correct
/// and is what Google documents: test unit ids serve under any app id, so
/// there is no reason to carry a second value that only differs in debug.
///
/// Source of truth for all of these: `generated/ad_config.md`.
library;

import 'dart:io';

import 'package:flutter/foundation.dart';

/// True while the app is serving Google's test inventory.
///
/// Computed, never assigned. A release build is live; everything else is not.
/// The app logs this at startup rather than letting it be discovered from a
/// revenue graph that stayed at zero.
const bool kUsingTestAdIds = !kReleaseMode;

abstract final class AdIds {
  // ---- Google's official test units --------------------------------------
  //
  // Google provides exactly one rewarded test unit per platform, so all three
  // rewarded placements share it here. The live units below are separate,
  // which is the point of having four.
  static const _testAndroidInterstitial = 'ca-app-pub-3940256099942544/1033173712';
  static const _testAndroidRewarded = 'ca-app-pub-3940256099942544/5224354917';
  static const _testIosInterstitial = 'ca-app-pub-3940256099942544/4411468910';
  static const _testIosRewarded = 'ca-app-pub-3940256099942544/1712485313';

  // ---- Live units — Android ----------------------------------------------
  static const _androidInterstitial = 'ca-app-pub-9242904787767394/2104344149';
  static const _androidRewardedHint = 'ca-app-pub-9242904787767394/2509714423';
  static const _androidRewardedExtraTube = 'ca-app-pub-9242904787767394/9813489373';
  static const _androidRewardedLevelSkip = 'ca-app-pub-9242904787767394/2046679999';

  // ---- Live units — iOS --------------------------------------------------
  static const _iosInterstitial = 'ca-app-pub-9242904787767394/6698195277';
  static const _iosRewardedHint = 'ca-app-pub-9242904787767394/1496955005';
  static const _iosRewardedExtraTube = 'ca-app-pub-9242904787767394/4833564783';
  static const _iosRewardedLevelSkip = 'ca-app-pub-9242904787767394/1336233558';

  static bool get _isIOS => !kIsWeb && Platform.isIOS;

  /// Shown only after a level is completed. Never on restart, never mid-play.
  static String get interstitialLevelComplete {
    if (kUsingTestAdIds) {
      return _isIOS ? _testIosInterstitial : _testAndroidInterstitial;
    }
    return _isIOS ? _iosInterstitial : _androidInterstitial;
  }

  /// A separate unit per placement, so AdMob reports fill rate and revenue per
  /// placement. Without that split, "rewarded video earns well" is a single
  /// number that cannot say whether it is the hint, the extra tube or the
  /// skip doing the work — and therefore cannot say which one to build on.
  static String get rewardedHint =>
      _rewarded(_androidRewardedHint, _iosRewardedHint);

  static String get rewardedExtraTube =>
      _rewarded(_androidRewardedExtraTube, _iosRewardedExtraTube);

  static String get rewardedLevelSkip =>
      _rewarded(_androidRewardedLevelSkip, _iosRewardedLevelSkip);

  static String _rewarded(String android, String ios) {
    if (kUsingTestAdIds) {
      return _isIOS ? _testIosRewarded : _testAndroidRewarded;
    }
    return _isIOS ? ios : android;
  }
}

/// Devices that always receive test ads, even from a release build.
///
/// Register your own handset here before doing ANY release-mode ad testing.
/// Without it, every ad you look at while checking the release build is a live
/// impression on your own account — which is exactly the invalid traffic the
/// build-mode split above exists to prevent, arriving through the one door it
/// cannot close.
///
/// The id is printed by the Google Mobile Ads SDK on first request:
///
///     adb logcat | grep "RequestConfiguration.Builder().setTestDeviceIds"
///
/// It is a hash of the device's ad id, not a secret, and it changes if the
/// advertising id is reset.
const List<String> kAdMobTestDeviceIds = <String>[
  // '33BE2250B43518CCDA7DE426D04EE231',
];

/// Product identifiers for in-app purchase.
abstract final class IapIds {
  /// One-time purchase. Kills interstitials; rewarded videos stay available as
  /// an opt-in, because a player who wants a hint should still be able to earn
  /// one.
  ///
  /// TO GO LIVE: must match the product created in Play Console exactly. A
  /// product id can never be changed or reused once created, so it is worth
  /// being sure before the first upload.
  static const removeAds = 'remove_ads';

  static const all = <String>{removeAds};
}

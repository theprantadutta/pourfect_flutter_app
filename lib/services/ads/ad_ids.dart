/// AdMob identifiers.
///
/// Currently Google's OFFICIAL TEST IDS. They serve a real ad filled with
/// placeholder creative and every one is labelled "Test Ad" across the top —
/// that label is the proof the plumbing works. Seeing an unlabelled ad before
/// the real ids land means something is misconfigured and should be stopped.
///
/// TO GO LIVE: fill in `generated/ad_config.md` and replace the four constants
/// per platform below. Nothing else changes.
///
/// The distinction that causes outages: an APP id uses a tilde and lives in
/// `AndroidManifest.xml`; an AD UNIT id uses a slash and lives here. Swapping
/// them either crashes on launch or, worse, silently never loads an ad.
library;

import 'dart:io';

import 'package:flutter/foundation.dart';

/// True while the app is still on Google's test inventory.
///
/// Flipped to false by replacing the constants below. The app SHOWS this in a
/// debug banner rather than letting it be discovered in production.
const bool kUsingTestAdIds = true;

abstract final class AdIds {
  // ---- Android (Google test units) ---------------------------------------
  static const _androidInterstitial = 'ca-app-pub-3940256099942544/1033173712';
  static const _androidRewarded = 'ca-app-pub-3940256099942544/5224354917';

  // ---- iOS (Google test units) -------------------------------------------
  static const _iosInterstitial = 'ca-app-pub-3940256099942544/4411468910';
  static const _iosRewarded = 'ca-app-pub-3940256099942544/1712485313';

  static bool get _isIOS => !kIsWeb && Platform.isIOS;

  /// Shown only after a level is completed. Never on restart, never mid-play.
  static String get interstitialLevelComplete =>
      _isIOS ? _iosInterstitial : _androidInterstitial;

  /// One unit per placement once live, so AdMob reports revenue and fill rate
  /// per placement. On test ids they share a unit because Google provides only
  /// one rewarded test unit per platform.
  static String get rewardedHint => _isIOS ? _iosRewarded : _androidRewarded;

  static String get rewardedExtraTube =>
      _isIOS ? _iosRewarded : _androidRewarded;

  static String get rewardedLevelSkip =>
      _isIOS ? _iosRewarded : _androidRewarded;
}

/// Product identifiers for in-app purchase.
abstract final class IapIds {
  /// One-time purchase. Kills interstitials; rewarded videos stay available as
  /// an opt-in, because a player who wants a hint should still be able to earn
  /// one.
  ///
  /// TO GO LIVE: must match the product created in Play Console exactly, and a
  /// product id can never be changed or reused once created.
  static const removeAds = 'remove_ads';

  static const all = <String>{removeAds};
}

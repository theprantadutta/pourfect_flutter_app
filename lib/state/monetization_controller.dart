/// The one place that decides whether a player is shown an ad.
///
/// Every rule lives here or in `InterstitialPolicy`, and the game screen only
/// asks. That matters because monetization rules rot when they are scattered:
/// one well-meaning call site added later is all it takes for somebody to be
/// interrupted on a level restart.
///
/// The rule that governs rewarded video: **the reward is granted only after the
/// thing the player was promised actually happens.** Watching a video and then
/// being told "no hint available" is a refund request. So the flow is always
/// show ad → confirm earned → perform the action → and if the action fails, the
/// player keeps whatever they spent.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/ads/ad_service.dart';
import '../services/ads/interstitial_policy.dart';
import '../services/analytics/analytics_service.dart';
import '../services/iap/billing_service.dart';
import 'providers.dart';

/// Hints a player gets without watching anything.
///
/// Generous on purpose. A hint is how somebody stuck at level 30 keeps playing
/// instead of uninstalling, and the first few are worth more as retention than
/// as inventory.
const int kFreeHints = 3;

/// Snapshot of what the player is currently entitled to.
class MonetizationState {
  final bool adsRemoved;
  final int freeHintsUsed;
  final InterstitialPolicy interstitials;

  const MonetizationState({
    required this.adsRemoved,
    required this.freeHintsUsed,
    required this.interstitials,
  });

  int get freeHintsRemaining =>
      (kFreeHints - freeHintsUsed).clamp(0, kFreeHints);

  /// True when the next hint costs a rewarded video.
  ///
  /// Buying Remove Ads does NOT make hints free — it stops interruptions, and
  /// rewarded video stays an opt-in the player can still choose.
  bool get hintNeedsAd => freeHintsRemaining == 0;

  MonetizationState copyWith({
    bool? adsRemoved,
    int? freeHintsUsed,
    InterstitialPolicy? interstitials,
  }) => MonetizationState(
    adsRemoved: adsRemoved ?? this.adsRemoved,
    freeHintsUsed: freeHintsUsed ?? this.freeHintsUsed,
    interstitials: interstitials ?? this.interstitials,
  );
}

class MonetizationController extends Notifier<MonetizationState> {
  static const _hintsKey = 'pourfect.hints.used';

  @override
  MonetizationState build() {
    final billing = ref.read(billingServiceProvider);

    // The entitlement is read INTO the returned value rather than assigned to
    // `state`. Writing `state` from inside build() — before the initial value
    // exists — throws, and in a release build Flutter renders that as a blank
    // grey screen rather than a red error, so it presents as a layout bug.
    final sub = billing.adsRemovedChanges.listen(
      (removed) => state = state.copyWith(adsRemoved: removed),
    );
    ref.onDispose(sub.cancel);

    // Async: settles after build returns, which is allowed.
    _restore();

    return MonetizationState(
      adsRemoved: billing.adsRemoved,
      freeHintsUsed: 0,
      interstitials: const InterstitialPolicy(),
    );
  }

  Future<void> _restore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      state = state.copyWith(freeHintsUsed: prefs.getInt(_hintsKey) ?? 0);
    } catch (_) {}
  }

  // ---- interstitial --------------------------------------------------------

  /// Offers an interstitial after [levelId] was COMPLETED.
  ///
  /// The only call site is the level-advance path. There is deliberately no
  /// method here that could be called on restart or mid-level.
  Future<void> maybeShowInterstitialAfter(int levelId) async {
    final ads = ref.read(adServiceProvider);
    final analytics = ref.read(analyticsServiceProvider);

    final decision = state.interstitials.decide(
      levelId: levelId,
      adsRemoved: state.adsRemoved,
      isLoaded: ads.isInterstitialReady,
      now: DateTime.now(),
    );
    if (!decision.allowed) return;

    analytics.log(
      AdShown(
        format: AdFormat.interstitial,
        placement: 'level_complete',
        levelId: levelId,
      ),
    );

    final shown = await ads.showInterstitial();

    analytics.log(
      AdCompleted(
        format: AdFormat.interstitial,
        placement: 'level_complete',
        levelId: levelId,
        // An interstitial has no reward; "granted" means it actually played,
        // so the gap between shown and completed stays readable as failures.
        rewardGranted: shown,
      ),
    );

    if (shown) {
      state = state.copyWith(
        interstitials: state.interstitials.recordShown(
          levelId: levelId,
          now: DateTime.now(),
        ),
      );
    }
  }

  // ---- rewarded ------------------------------------------------------------

  /// Spends a free hint if one remains.
  Future<bool> consumeFreeHint() async {
    if (state.freeHintsRemaining == 0) return false;
    final used = state.freeHintsUsed + 1;
    state = state.copyWith(freeHintsUsed: used);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_hintsKey, used);
    } catch (_) {}
    return true;
  }

  /// Offers a rewarded video for [placement].
  ///
  /// Returns whether the player EARNED it. The caller then performs the action
  /// — and if the action itself fails, nothing was spent, because a rewarded
  /// video costs attention rather than a balance.
  Future<RewardOutcome> offerRewarded(
    RewardedPlacement placement, {
    required int levelId,
  }) async {
    final ads = ref.read(adServiceProvider);
    final analytics = ref.read(analyticsServiceProvider);

    analytics.log(
      AdShown(
        format: AdFormat.rewarded,
        placement: placement.eventName,
        levelId: levelId,
      ),
    );

    final outcome = await ads.showRewarded(placement);

    analytics.log(
      AdCompleted(
        format: AdFormat.rewarded,
        placement: placement.eventName,
        levelId: levelId,
        rewardGranted: outcome == RewardOutcome.earned,
      ),
    );

    return outcome;
  }

  // ---- purchase ------------------------------------------------------------

  Future<PurchaseOutcome> buyRemoveAds({required String placement}) async {
    final billing = ref.read(billingServiceProvider);
    final analytics = ref.read(analyticsServiceProvider);

    final outcome = await billing.buyRemoveAds();

    if (outcome == PurchaseOutcome.purchased) {
      analytics.log(
        IapPurchased(productId: 'remove_ads', placement: placement),
      );
      state = state.copyWith(adsRemoved: true);
    }
    return outcome;
  }

  /// Test seam.
  void debugSet({bool? adsRemoved, int? freeHintsUsed}) => state = state
      .copyWith(adsRemoved: adsRemoved, freeHintsUsed: freeHintsUsed);
}

final monetizationProvider =
    NotifierProvider<MonetizationController, MonetizationState>(
      MonetizationController.new,
    );

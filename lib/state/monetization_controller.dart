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

import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/ads/ad_service.dart';
import '../services/ads/interstitial_policy.dart';
import '../services/analytics/analytics_service.dart';
import '../services/iap/billing_service.dart';

import 'package:flutter/foundation.dart';

import '../services/api/api_result.dart';
import '../services/api/purchases_api.dart';
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

  /// Hints that are PAID FOR but not yet delivered.
  ///
  /// A rewarded video is watched before the solver is asked, so the solver can
  /// still come back empty — and the player has already spent their attention.
  /// The credit is what makes "your reward was not used" true instead of a
  /// polite lie: the next request spends it rather than another video.
  ///
  /// Persisted, so closing the app does not quietly pocket it.
  final int hintCredits;

  final InterstitialPolicy interstitials;

  const MonetizationState({
    required this.adsRemoved,
    required this.freeHintsUsed,
    required this.hintCredits,
    required this.interstitials,
  });

  int get freeHintsRemaining =>
      (kFreeHints - freeHintsUsed).clamp(0, kFreeHints);

  /// True when a paid-for hint is waiting to be delivered.
  bool get hasHintCredit => hintCredits > 0;

  /// True when the next hint costs a rewarded video.
  ///
  /// Buying Remove Ads does NOT make hints free — it stops interruptions, and
  /// rewarded video stays an opt-in the player can still choose.
  bool get hintNeedsAd => freeHintsRemaining == 0 && !hasHintCredit;

  MonetizationState copyWith({
    bool? adsRemoved,
    int? freeHintsUsed,
    int? hintCredits,
    InterstitialPolicy? interstitials,
  }) => MonetizationState(
    adsRemoved: adsRemoved ?? this.adsRemoved,
    freeHintsUsed: freeHintsUsed ?? this.freeHintsUsed,
    hintCredits: hintCredits ?? this.hintCredits,
    interstitials: interstitials ?? this.interstitials,
  );
}

class MonetizationController extends Notifier<MonetizationState> {
  static const _hintsKey = 'pourfect.hints.used';
  static const _creditsKey = 'pourfect.hints.credits';

  /// Completes once the persisted hint count has been read.
  ///
  /// This provider is LAZY: nothing builds it until the first hint is asked
  /// for, which means `build()` and the first spend happen in the same
  /// breath. Without waiting on this, that first spend is always measured
  /// against a freshly-zeroed counter.
  late final Future<void> _restored;

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

    // Every receipt the store hands over goes to the server, including the
    // ones it replays on launch. That replay IS the retry: a purchase made
    // while the phone had no signal verifies on the next launch instead, with
    // no queue to persist and nothing that can be lost.
    final receipts = billing.receipts.listen(_verifyWithServer);
    ref.onDispose(receipts.cancel);

    // Async: settles after build returns, which is allowed. The future is
    // KEPT, because anything that spends the hint budget has to wait for it —
    // see consumeFreeHint.
    _restored = _restore();

    return MonetizationState(
      adsRemoved: billing.adsRemoved,
      freeHintsUsed: 0,
      hintCredits: 0,
      interstitials: const InterstitialPolicy(),
    );
  }

  Future<void> _restore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getInt(_hintsKey) ?? 0;

      // MONOTONIC. A plain assignment here can walk the counter backwards: if
      // a hint was spent while this was still loading, restoring the old
      // stored value hands that hint straight back. Spending only ever
      // increases the count, so the larger number is always the true one.
      state = state.copyWith(
        freeHintsUsed: math.max(state.freeHintsUsed, stored),
        // Credits move both ways, so the same trick does not apply — but the
        // restore only runs before anything can spend one, and a credit
        // granted meanwhile is additive.
        hintCredits: state.hintCredits + (prefs.getInt(_creditsKey) ?? 0),
      );
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
    // Never spend before we know what has already been spent.
    //
    // Skipping this wait does not merely risk one extra hint: because the
    // provider is built on the first hint tap, the count is ALWAYS zero at
    // that moment, so every launch hands out a fresh set of free hints and
    // the rewarded prompt — the primary revenue driver — is never reached by
    // anybody willing to reopen the app.
    await _restored;

    if (state.freeHintsRemaining == 0) return false;
    final used = state.freeHintsUsed + 1;
    state = state.copyWith(freeHintsUsed: used);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_hintsKey, used);
    } catch (_) {}
    return true;
  }

  /// Hands back a free hint that was spent on a hint never delivered.
  ///
  /// Charging before the solver answers is what makes this necessary: the
  /// alternative is silently taking one of three free hints for nothing, which
  /// a player notices and cannot dispute.
  Future<void> refundFreeHint() async {
    if (state.freeHintsUsed == 0) return;
    final used = state.freeHintsUsed - 1;
    state = state.copyWith(freeHintsUsed: used);
    await _persistInt(_hintsKey, used);
  }

  /// Records a hint that has been paid for but not yet delivered.
  Future<void> grantHintCredit() async {
    final credits = state.hintCredits + 1;
    state = state.copyWith(hintCredits: credits);
    await _persistInt(_creditsKey, credits);
  }

  /// Spends a waiting credit, if there is one.
  Future<bool> consumeHintCredit() async {
    await _restored;
    if (state.hintCredits == 0) return false;
    final credits = state.hintCredits - 1;
    state = state.copyWith(hintCredits: credits);
    await _persistInt(_creditsKey, credits);
    return true;
  }

  Future<void> _persistInt(String key, int value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(key, value);
    } catch (_) {}
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

  /// Sends one receipt to the server and applies what comes back.
  ///
  /// Nothing here can cost the player their entitlement. The local grant has
  /// already happened — somebody who paid does not wait on our backend to stop
  /// seeing ads — and a verification that cannot be delivered is retried by the
  /// store's next replay. What the round trip buys is on the server: ownership
  /// becomes exclusive to one account, and a later refund becomes something
  /// that can be noticed at all.
  Future<void> _verifyWithServer(PurchaseReceipt receipt) async {
    final result = await PurchasesApi(ref.read(apiClientProvider))
        .verify(productId: receipt.productId, purchaseToken: receipt.token);

    switch (result) {
      case ApiOk(:final value):
        // GRANT ONLY. A `false` here is not a revocation: it is what a pending
        // purchase looks like, what a token the server refused looks like, and
        // what an outage half-way through looks like. Taking the entitlement
        // away on any of those would strip somebody mid-session over a
        // question the device cannot answer. Revocation belongs to the server's
        // refund scan, which has Play's own word for it.
        if (value.adsRemoved) applyServerEntitlement(true);

        if (!value.isPurchased && !value.isPending) {
          debugPrint(
            '[iap] server verdict for ${receipt.productId}: ${value.state}'
            '${value.error == null ? '' : ' (${value.error})'}',
          );
        }

      case ApiFailure(:final kind):
        // Not shown, not retried here, and not treated as a failed purchase.
        // The store replays every owned purchase on launch, so the next one
        // tries again.
        debugPrint('[iap] verification deferred: $kind');
    }
  }

  /// Applies an entitlement the SERVER has confirmed.
  ///
  /// One direction only, and deliberately. The server knows about purchases
  /// this device has never seen — somebody who paid, reinstalled, and now has
  /// a store that has not replayed the token yet — so it can grant. It must
  /// not revoke: a sync that arrives during an outage, against a stale row, or
  /// before Play has redelivered, would take away something the player paid
  /// for while they were using it. Revocation is a decision for the purchase
  /// path, where there is a store verdict to act on.
  void applyServerEntitlement(bool adsRemoved) {
    if (!adsRemoved || state.adsRemoved) return;
    state = state.copyWith(adsRemoved: true);
  }

  /// Test seam.
  void debugSet({bool? adsRemoved, int? freeHintsUsed, int? hintCredits}) =>
      state = state.copyWith(
        adsRemoved: adsRemoved,
        freeHintsUsed: freeHintsUsed,
        hintCredits: hintCredits,
      );
}

final monetizationProvider =
    NotifierProvider<MonetizationController, MonetizationState>(
      MonetizationController.new,
    );

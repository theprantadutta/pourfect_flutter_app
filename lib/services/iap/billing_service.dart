/// The single in-app purchase: Remove Ads.
///
/// What the purchase actually buys, stated once so it cannot drift:
///
///  * Interstitials stop, permanently.
///  * **Rewarded videos stay available.** Somebody who paid to stop being
///    interrupted should still be able to CHOOSE to watch a video for a hint.
///    Removing that would take away a feature they had before paying, which is
///    how a $1.99 purchase turns into a refund and a one-star review.
///
/// Entitlement is cached locally so it survives offline launches, and restored
/// from the store on demand. Server-side verification against the Play
/// Developer API lands with the backend; the local cache is the fast path, not
/// the source of truth.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../ads/ad_ids.dart';

/// What came of asking to buy.
enum PurchaseOutcome {
  /// Bought and the entitlement is live.
  purchased,

  /// Already owned — restoring rather than charging again.
  alreadyOwned,

  /// The player backed out. Not an error, and must not be reported as one.
  cancelled,

  /// The store rejected it or the product is not available.
  failed,

  /// Billing is not available at all on this device.
  unavailable,
}

/// Price and title as the store reports them, for display.
class StoreProduct {
  final String id;
  final String title;
  final String price;

  const StoreProduct({
    required this.id,
    required this.title,
    required this.price,
  });
}

/// A purchase the store has confirmed, in the form the server needs.
///
/// Carried out of this layer as a plain value rather than verified here, so
/// `services/iap/` keeps knowing nothing about HTTP and the retry rule lives
/// in one place.
class PurchaseReceipt {
  final String productId;

  /// Play's purchase token. On Android this is what
  /// `serverVerificationData` holds; on iOS it will be the transaction id.
  final String token;

  /// True when the store replayed a purchase we already had, rather than one
  /// the player has just made.
  final bool restored;

  const PurchaseReceipt({
    required this.productId,
    required this.token,
    required this.restored,
  });
}

abstract interface class BillingService {
  Future<void> init();

  /// True when interstitials should be suppressed.
  bool get adsRemoved;

  /// Emits whenever the entitlement changes.
  Stream<bool> get adsRemovedChanges;

  /// The Remove Ads product as the store describes it, or null if unavailable.
  StoreProduct? get removeAdsProduct;

  Future<PurchaseOutcome> buyRemoveAds();

  /// Re-reads past purchases. Play requires a user-visible way to do this.
  Future<void> restorePurchases();

  /// Receipts worth showing the server.
  ///
  /// Emitted for a fresh purchase AND for every purchase the store replays on
  /// launch, which is what makes verification self-healing: a device that was
  /// offline when the purchase completed simply verifies it on the next launch
  /// instead, with no queue to persist and nothing to lose.
  Stream<PurchaseReceipt> get receipts;

  Future<void> dispose();
}

class PlayBillingService implements BillingService {
  static const _entitlementKey = 'pourfect.entitlement.remove_ads';

  final InAppPurchase _iap;
  final _changes = StreamController<bool>.broadcast();
  final _receipts = StreamController<PurchaseReceipt>.broadcast();

  StreamSubscription<List<PurchaseDetails>>? _subscription;
  Completer<PurchaseOutcome>? _pending;

  bool _adsRemoved = false;
  StoreProduct? _product;
  bool _available = false;

  PlayBillingService({InAppPurchase? iap})
    : _iap = iap ?? InAppPurchase.instance;

  @override
  bool get adsRemoved => _adsRemoved;

  @override
  Stream<bool> get adsRemovedChanges => _changes.stream;

  @override
  StoreProduct? get removeAdsProduct => _product;

  @override
  Future<void> init() async {
    // The cached entitlement is read FIRST and never gated on the network. A
    // player who paid and then opened the app on a plane must not see ads.
    await _restoreCachedEntitlement();

    try {
      _available = await _iap.isAvailable();
      if (!_available) {
        debugPrint('[iap] billing unavailable on this device');
        return;
      }

      _subscription = _iap.purchaseStream.listen(
        _onPurchaseUpdate,
        onError: (Object error) => debugPrint('[iap] stream error: $error'),
      );

      final response = await _iap.queryProductDetails(IapIds.all);
      if (response.notFoundIDs.isNotEmpty) {
        // Expected until the product is Active in Play Console and the account
        // is on a testing track — not an error worth surfacing to a player.
        debugPrint('[iap] product not found: ${response.notFoundIDs}');
      }
      for (final details in response.productDetails) {
        if (details.id == IapIds.removeAds) {
          _product = StoreProduct(
            id: details.id,
            title: details.title,
            price: details.price,
          );
        }
      }

      // Surfaces a purchase made on another device, or one that completed after
      // the app was killed mid-flow.
      await _iap.restorePurchases();
    } catch (error) {
      debugPrint('[iap] init failed, continuing without billing: $error');
      _available = false;
    }
  }

  Future<void> _restoreCachedEntitlement() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _setEntitlement(prefs.getBool(_entitlementKey) ?? false);
    } catch (_) {}
  }

  @override
  Stream<PurchaseReceipt> get receipts => _receipts.stream;

  void _setEntitlement(bool value) {
    if (_adsRemoved == value) return;
    _adsRemoved = value;
    _changes.add(value);
  }

  Future<void> _persistEntitlement(bool value) async {
    _setEntitlement(value);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_entitlementKey, value);
    } catch (_) {}
  }

  void _onPurchaseUpdate(List<PurchaseDetails> purchases) {
    for (final purchase in purchases) {
      if (purchase.productID != IapIds.removeAds) continue;

      switch (purchase.status) {
        case PurchaseStatus.pending:
          // Deferred payment (carrier billing, parental approval). Grant
          // NOTHING yet — a pending purchase can still fail.
          break;

        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          _persistEntitlement(true);

          // Offered to the server on every delivery, including the replays
          // the store performs on launch. The local entitlement is granted
          // either way — a player who has paid does not wait on our backend
          // to stop seeing ads — but the server needs the token to make the
          // ownership exclusive and to notice a later refund.
          final token = purchase.verificationData.serverVerificationData;
          if (token.isNotEmpty) {
            _receipts.add(
              PurchaseReceipt(
                productId: purchase.productID,
                token: token,
                restored: purchase.status == PurchaseStatus.restored,
              ),
            );
          }

          _complete(
            purchase.status == PurchaseStatus.restored
                ? PurchaseOutcome.alreadyOwned
                : PurchaseOutcome.purchased,
          );

        case PurchaseStatus.canceled:
          _complete(PurchaseOutcome.cancelled);

        case PurchaseStatus.error:
          debugPrint('[iap] purchase error: ${purchase.error?.message}');
          _complete(PurchaseOutcome.failed);
      }

      // ALWAYS complete the purchase, including on error. An un-completed
      // purchase is re-delivered on every launch forever, and on Android it
      // eventually auto-refunds — the player is charged, loses the
      // entitlement, and blames us.
      if (purchase.pendingCompletePurchase) {
        _iap.completePurchase(purchase);
      }
    }
  }

  void _complete(PurchaseOutcome outcome) {
    final pending = _pending;
    if (pending == null) return;

    _pending = null;
    if (!pending.isCompleted) pending.complete(outcome);
  }

  @override
  Future<PurchaseOutcome> buyRemoveAds() async {
    if (_adsRemoved) return PurchaseOutcome.alreadyOwned;
    if (!_available) return PurchaseOutcome.unavailable;

    final product = _product;
    if (product == null) return PurchaseOutcome.unavailable;

    // One purchase flow at a time. A second tap while the store sheet is open
    // would otherwise replace the completer the first call is waiting on, and
    // that first caller would hang until its timeout. Reported as cancelled
    // because nothing was charged for the second tap — the first flow is still
    // running and will report the real outcome.
    if (_pending != null) return PurchaseOutcome.cancelled;

    // Held LOCALLY, not read back from the field.
    //
    // The purchase stream can deliver the result DURING the await below —
    // `_complete` then clears `_pending`, and the old code's `_pending!`
    // threw on null, was caught, and returned `failed` for a purchase that had
    // actually succeeded. The player was charged, the entitlement was granted,
    // and the app told them it did not work.
    final pending = Completer<PurchaseOutcome>();
    _pending = pending;

    try {
      final response = await _iap.queryProductDetails({IapIds.removeAds});
      final details = response.productDetails.firstWhere(
        (d) => d.id == IapIds.removeAds,
      );

      await _iap.buyNonConsumable(
        purchaseParam: PurchaseParam(productDetails: details),
      );

      // The store UI can sit open indefinitely, but a purchase that never
      // resolves must not leave the caller awaiting forever.
      return await pending.future.timeout(
        const Duration(minutes: 5),
        onTimeout: () => PurchaseOutcome.failed,
      );
    } catch (error) {
      debugPrint('[iap] buy failed: $error');

      // If the stream already resolved this attempt, that answer is the true
      // one — the entitlement may well have been granted. Only report a
      // failure for an attempt that genuinely never completed.
      if (pending.isCompleted) return pending.future;

      return PurchaseOutcome.failed;
    } finally {
      // Only clear the field if it still refers to THIS attempt.
      if (identical(_pending, pending)) _pending = null;
    }
  }

  @override
  Future<void> restorePurchases() async {
    if (!_available) return;
    try {
      await _iap.restorePurchases();
    } catch (error) {
      debugPrint('[iap] restore failed: $error');
    }
  }

  @override
  Future<void> dispose() async {
    await _subscription?.cancel();
    await _changes.close();
    await _receipts.close();
  }
}

/// Never sells anything and owns nothing. Tests, and platforms without billing.
class NoopBillingService implements BillingService {
  const NoopBillingService();

  @override
  Future<void> init() async {}

  @override
  bool get adsRemoved => false;

  @override
  Stream<bool> get adsRemovedChanges => const Stream.empty();

  @override
  StoreProduct? get removeAdsProduct => null;

  @override
  Future<PurchaseOutcome> buyRemoveAds() async => PurchaseOutcome.unavailable;

  @override
  Future<void> restorePurchases() async {}

  @override
  Stream<PurchaseReceipt> get receipts => const Stream.empty();

  @override
  Future<void> dispose() async {}
}

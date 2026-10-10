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
/// from the store on demand. The server verifies every token against the Play
/// Developer API, acknowledges it, and hears about refunds through Play's
/// real-time notifications; the local cache is the fast path, not the source
/// of truth.
///
/// Built on `flutter_inapp_purchase` (OpenIAP), which brings Play Billing 9 —
/// what Play requires of updates from 2026-11-01.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_inapp_purchase/flutter_inapp_purchase.dart';
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

  /// Deferred payment — carrier billing or parental approval. Nothing is
  /// granted until it clears, which can take days or never happen.
  pending,

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

  /// Starts the purchase. [accountId] is the player's opaque server id, sent
  /// to Play as the obfuscated account id so a purchase can be matched to its
  /// account from Play's own notifications.
  Future<PurchaseOutcome> buyRemoveAds({String? accountId});

  /// Any product the app sells, as the store describes it, or null.
  StoreProduct? productFor(String productId);

  /// Buys [productId] (see `IapIds`). Remove Ads also has [buyRemoveAds].
  Future<PurchaseOutcome> buy(String productId, {String? accountId});

  /// Re-reads past purchases. Play requires a user-visible way to do this.
  Future<void> restorePurchases();

  /// Records that the server accepted a purchase, clearing any revocation.
  Future<void> confirmEntitlement();

  /// Receipts the store has delivered that no verification has settled.
  ///
  /// Survives a relaunch, because the store's replay is the only retry there
  /// is and a dropped broadcast event would otherwise be the end of it.
  List<PurchaseReceipt> get pendingReceipts;

  /// Marks a receipt as settled, so it stops being retried.
  Future<void> settleReceipt(String token);

  /// Finishes (acknowledges) a purchase the server has verified.
  ///
  /// Only ever after verification. An unacknowledged purchase is refunded by
  /// Play after three days, which is exactly right for one our server
  /// rejected — and wrong to prevent by acknowledging before anybody checked.
  Future<void> finishPurchase(String token);

  /// Records that the store voided the purchase behind the entitlement.
  ///
  /// Wipes the cached grant AND remembers that it was revoked, because the
  /// store replays every owned purchase on the next launch and would otherwise
  /// hand it straight back. Cleared again only by a verification the server
  /// accepts, which is the one thing that can mean the player owns it again.
  Future<void> revokeEntitlement();

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

  /// Set once the store has voided the purchase behind the entitlement.
  ///
  /// Persisted, because the thing it defends against happens on the NEXT
  /// launch: the store still reports every owned purchase, and without this
  /// the reconcile grants the refunded entitlement straight back.
  static const _revokedKey = 'pourfect.entitlement.revoked';

  /// Tokens the store has delivered that no verification has settled.
  ///
  /// Persisted for the same reason the revocation is. A receipt delivered
  /// before the verifier was listening — or during a crash — would otherwise
  /// never be offered again.
  static const _pendingKey = 'pourfect.iap.pending_receipts';

  final FlutterInappPurchase _iap;
  final _changes = StreamController<bool>.broadcast();
  final _receipts = StreamController<PurchaseReceipt>.broadcast();

  StreamSubscription<Purchase>? _purchaseSub;
  StreamSubscription<PurchaseError>? _errorSub;
  Completer<PurchaseOutcome>? _pending;

  bool _adsRemoved = false;
  bool _revoked = false;
  final Map<String, StoreProduct> _products = {};
  bool _available = false;

  final List<PurchaseReceipt> _pendingReceipts = [];

  /// Purchases the store delivered that are not finished (acknowledged) yet,
  /// by token. Finished only once the server has verified them — see
  /// [finishPurchase].
  final Map<String, Purchase> _unfinished = {};

  PlayBillingService({FlutterInappPurchase? iap})
    : _iap = iap ?? FlutterInappPurchase.instance;

  @override
  bool get adsRemoved => _adsRemoved;

  @override
  Stream<bool> get adsRemovedChanges => _changes.stream;

  @override
  StoreProduct? get removeAdsProduct => _products[IapIds.removeAds];

  @override
  StoreProduct? productFor(String productId) => _products[productId];

  @override
  Future<void> init() async {
    // The cached entitlement is read FIRST and never gated on the network. A
    // player who paid and then opened the app on a plane must not see ads.
    await _restoreCachedEntitlement();

    // Listeners BEFORE the connection opens. A purchase completed in a
    // previous session can be delivered the moment it does, and a listener
    // attached afterwards misses it.
    _purchaseSub = _iap.purchaseUpdatedListener.listen(
      (purchase) => _onPurchase(purchase, restored: false),
      onError: (Object error) => debugPrint('[iap] stream error: $error'),
    );
    _errorSub = _iap.purchaseErrorListener.listen(_onPurchaseError);

    try {
      // Bounded: a store that never answers must not hold the launch, and the
      // game is perfectly playable without billing.
      _available = await _iap.initConnection().timeout(
        const Duration(seconds: 10),
      );
      if (!_available) {
        debugPrint('[iap] billing unavailable on this device');
        return;
      }

      final products = await _iap.fetchProducts<ProductCommon>(
        skus: IapIds.all.toList(),
        type: ProductQueryType.InApp,
      );
      for (final details in products) {
        // A product with no price is not on sale — Play answers like this
        // before a product is created and active. Kept out, so the store
        // buttons read "not available" instead of showing an empty price.
        if (details.displayPrice.trim().isEmpty) continue;
        if (IapIds.all.contains(details.id)) {
          _products[details.id] = StoreProduct(
            id: details.id,
            title: details.title,
            price: details.displayPrice,
          );
        }
      }
      final missing = IapIds.all.difference(_products.keys.toSet());
      if (missing.isNotEmpty) {
        // Expected until a product is Active in Play Console and the account
        // is on a testing track — not an error worth surfacing to a player.
        debugPrint('[iap] products not found: $missing');
      }

      // Surfaces a purchase made on another device, one that completed after
      // the app was killed mid-flow, and anything still unacknowledged.
      // OpenIAP does not replay these onto the stream; they must be asked for.
      await _reconcile();
    } catch (error) {
      debugPrint('[iap] init failed, continuing without billing: $error');
      _available = false;
    }
  }

  Future<void> _restoreCachedEntitlement() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _revoked = prefs.getBool(_revokedKey) ?? false;
      // A revoked entitlement stays off even if the cached grant says
      // otherwise. The cache is what the store last told us; the revocation is
      // what the store's own refund list says, and it is newer by definition.
      _setEntitlement(!_revoked && (prefs.getBool(_entitlementKey) ?? false));

      // `product|token`; a bare token is from before there were two
      // products, when it could only have been Remove Ads.
      for (final entry in prefs.getStringList(_pendingKey) ?? const []) {
        final split = entry.indexOf('|');
        _pendingReceipts.add(
          PurchaseReceipt(
            productId: split < 0 ? IapIds.removeAds : entry.substring(0, split),
            token: split < 0 ? entry : entry.substring(split + 1),
            restored: true,
          ),
        );
      }
    } catch (_) {}
  }

  /// Everything the store says this Google account owns, offered to the
  /// server as restored receipts.
  Future<void> _reconcile() async {
    final owned = await _iap.getAvailablePurchases();
    for (final purchase in owned) {
      if (purchase.purchaseState == PurchaseState.Purchased) {
        _onPurchase(purchase, restored: true);
      }
    }
  }

  @override
  List<PurchaseReceipt> get pendingReceipts =>
      List.unmodifiable(_pendingReceipts);

  @override
  Future<void> settleReceipt(String token) async {
    _pendingReceipts.removeWhere((r) => r.token == token);
    await _persistPending();
  }

  @override
  Future<void> finishPurchase(String token) async {
    final purchase = _unfinished.remove(token);
    if (purchase == null) return;
    // Already acknowledged — by the server, which acknowledges as soon as it
    // has verified, or in an earlier session. Finishing again is harmless but
    // a wasted round trip.
    if (purchase is PurchaseAndroid && purchase.isAcknowledgedAndroid == true) {
      return;
    }
    try {
      // NOT consumable: Remove Ads is bought once and owned forever. Consuming
      // it would make it purchasable again, and the next tap would charge the
      // player a second time.
      await _iap.finishTransaction(purchase: purchase, isConsumable: false);
    } catch (error) {
      // Put back, so the next delivery or reconcile tries again.
      _unfinished[token] = purchase;
      debugPrint('[iap] finish failed: $error');
    }
  }

  Future<void> _rememberPending(PurchaseReceipt receipt) async {
    if (_pendingReceipts.any((r) => r.token == receipt.token)) return;
    _pendingReceipts.add(receipt);
    await _persistPending();
  }

  Future<void> _persistPending() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_pendingKey, [
        for (final r in _pendingReceipts) '${r.productId}|${r.token}',
      ]);
    } catch (_) {}
  }

  @override
  Future<void> revokeEntitlement() async {
    _revoked = true;
    _setEntitlement(false);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_revokedKey, true);
      await prefs.setBool(_entitlementKey, false);
    } catch (_) {}
  }

  @override
  Future<void> confirmEntitlement() async {
    _revoked = false;
    _setEntitlement(true);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_revokedKey, false);
      await prefs.setBool(_entitlementKey, true);
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

  void _onPurchase(Purchase purchase, {required bool restored}) {
    if (!IapIds.all.contains(purchase.productId)) return;

    switch (purchase.purchaseState) {
      case PurchaseState.Pending:
        // Deferred payment (carrier billing, parental approval). Grant
        // NOTHING and finish nothing — a pending purchase can still fail, and
        // it arrives again as Purchased if it clears.
        _complete(PurchaseOutcome.pending);
        return;

      case PurchaseState.Unknown:
        debugPrint('[iap] purchase in an unknown state');
        _complete(PurchaseOutcome.failed);
        return;

      case PurchaseState.Purchased:
        break;
    }

    // NOT granted while the entitlement stands revoked. The store keeps
    // reporting a refunded one-time purchase as owned, so this is exactly
    // where a refund would otherwise be undone on every launch. The receipt
    // still goes to the server below: if the refund was itself wrong, the
    // server's verdict is what turns the entitlement back on.
    //
    // Remove Ads only. The Skin pack is the server's to grant: its skins are
    // listed from the server's answer, which the verification refreshes.
    if (purchase.productId == IapIds.removeAds && !_revoked) {
      _persistEntitlement(true);
    }

    // Offered to the server on every delivery, including the reconcile at
    // launch. The local entitlement is granted either way — a player who has
    // paid does not wait on our backend to stop seeing ads — but the server
    // needs the token to make ownership exclusive, to acknowledge the sale,
    // and to notice a later refund.
    final token = purchase.purchaseToken;
    if (token != null && token.isNotEmpty) {
      // Held UNFINISHED until the server has verified it. Play refunds a
      // purchase nobody acknowledges within three days, which is the right
      // outcome for one our server rejected, and the server acknowledges a
      // good one itself the moment it verifies — so finishing here first
      // would only ever acknowledge something nobody had checked.
      _unfinished[token] = purchase;

      final receipt = PurchaseReceipt(
        productId: purchase.productId,
        token: token,
        restored: restored,
      );
      // Remembered BEFORE it is announced. A broadcast stream drops events
      // nobody is listening to yet, and at launch the store can deliver before
      // the verifier exists — which used to silently consume the only retry a
      // failed verification had.
      _rememberPending(receipt);
      _receipts.add(receipt);
    }

    _complete(
      restored ? PurchaseOutcome.alreadyOwned : PurchaseOutcome.purchased,
    );
  }

  void _onPurchaseError(PurchaseError error) {
    switch (error.code) {
      case ErrorCode.UserCancelled:
        // Backing out is not an error and must not be reported as one.
        _complete(PurchaseOutcome.cancelled);
      case ErrorCode.AlreadyOwned:
        // Owned on this Google account but not known here — a reinstall, or a
        // purchase made on another phone. Ask the store for it, which grants
        // and verifies through the normal path, then say so.
        unawaited(
          _reconcile().catchError(
            (Object e) => debugPrint('[iap] reconcile failed: $e'),
          ),
        );
        _complete(PurchaseOutcome.alreadyOwned);
      default:
        debugPrint('[iap] purchase error: ${error.code} ${error.message}');
        _complete(PurchaseOutcome.failed);
    }
  }

  void _complete(PurchaseOutcome outcome) {
    final pending = _pending;
    if (pending == null) return;

    _pending = null;
    if (!pending.isCompleted) pending.complete(outcome);
  }

  @override
  Future<PurchaseOutcome> buyRemoveAds({String? accountId}) async {
    if (_adsRemoved) return PurchaseOutcome.alreadyOwned;
    return buy(IapIds.removeAds, accountId: accountId);
  }

  @override
  Future<PurchaseOutcome> buy(String productId, {String? accountId}) async {
    if (!_available) return PurchaseOutcome.unavailable;
    if (_products[productId] == null) return PurchaseOutcome.unavailable;

    // One purchase flow at a time. A second tap while the store sheet is open
    // would otherwise replace the completer the first call is waiting on, and
    // that first caller would hang until its timeout. Reported as cancelled
    // because nothing was charged for the second tap — the first flow is still
    // running and will report the real outcome.
    if (_pending != null) return PurchaseOutcome.cancelled;

    // Held LOCALLY, not read back from the field: the listener can deliver
    // the result during the await below and clear `_pending`.
    final pending = Completer<PurchaseOutcome>();
    _pending = pending;

    try {
      await _iap.requestPurchase(
        RequestPurchaseProps.inApp((
          apple: RequestPurchaseIosProps(sku: productId),
          google: RequestPurchaseAndroidProps(
            skus: [productId],
            // Ties the purchase to the account that made it, so Play's
            // real-time notifications can be matched to a player even when
            // the app never reports the purchase itself. An opaque server id,
            // never anything personal: Play forbids PII here.
            obfuscatedAccountId: accountId,
          ),
        )),
      );

      // The store UI can sit open indefinitely, but a purchase that never
      // resolves must not leave the caller awaiting forever.
      return await pending.future.timeout(
        const Duration(minutes: 5),
        onTimeout: () => PurchaseOutcome.failed,
      );
    } catch (error) {
      debugPrint('[iap] buy failed: $error');

      // If the listener already resolved this attempt, that answer is the true
      // one — the entitlement may well have been granted.
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
      await _reconcile();
    } catch (error) {
      debugPrint('[iap] restore failed: $error');
    }
  }

  @override
  Future<void> dispose() async {
    await _purchaseSub?.cancel();
    await _errorSub?.cancel();
    try {
      await _iap.endConnection();
    } catch (_) {}
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
  Future<PurchaseOutcome> buyRemoveAds({String? accountId}) async =>
      PurchaseOutcome.unavailable;

  @override
  StoreProduct? productFor(String productId) => null;

  @override
  Future<PurchaseOutcome> buy(String productId, {String? accountId}) async =>
      PurchaseOutcome.unavailable;

  @override
  Future<void> restorePurchases() async {}

  @override
  Future<void> finishPurchase(String token) async {}

  @override
  Future<void> revokeEntitlement() async {}

  @override
  Future<void> confirmEntitlement() async {}

  @override
  List<PurchaseReceipt> get pendingReceipts => const [];

  @override
  Future<void> settleReceipt(String token) async {}

  @override
  Stream<PurchaseReceipt> get receipts => const Stream.empty();

  @override
  Future<void> dispose() async {}
}

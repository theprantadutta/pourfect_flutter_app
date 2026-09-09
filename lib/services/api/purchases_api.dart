/// Showing the server what the store said.
///
/// Local billing already grants the entitlement — a player who has paid does
/// not wait on our backend to stop seeing ads — so this is not what unlocks
/// anything on the device. It is what makes ownership EXCLUSIVE and REVOCABLE:
///
///  * exclusive, because one purchase must unlock one account. A token replayed
///    on a second install would otherwise unlock both, and there is nothing on
///    a phone that could notice.
///  * revocable, because a refund is invisible to the device. Play keeps
///    reporting a refunded one-time purchase as purchased, so only the server
///    — which reconciles against the voided-purchases list — can ever take the
///    entitlement back.
library;

import 'api_client.dart';
import 'api_result.dart';

/// The server's verdict on a token.
class VerifiedPurchase {
  /// purchased, pending, cancelled, refunded, or unknown — the store's answer,
  /// not ours.
  final String state;

  /// Whether the ACCOUNT is entitled after this verification. Not the same
  /// question as whether this token was valid: an account can hold others.
  final bool adsRemoved;

  /// Why the store refused, when it did.
  final String? error;

  /// True only when the store VOIDED the purchase behind the entitlement.
  ///
  /// The one "no" a client may act on. A bare [adsRemoved] of false is also
  /// what a pending purchase, a refused token and an outage look like.
  final bool adsRevoked;

  const VerifiedPurchase({
    required this.state,
    required this.adsRemoved,
    required this.error,
    required this.adsRevoked,
  });

  bool get isPurchased => state == 'purchased';

  /// Deferred payment — carrier billing, or a parent yet to approve. Neither
  /// success nor failure, and treating it as either is wrong: granting hands
  /// the entitlement away, refusing makes a later completion look like a
  /// double charge.
  bool get isPending => state == 'pending';
}

class PurchasesApi {
  final ApiClient _client;

  const PurchasesApi(this._client);

  Future<ApiResult<VerifiedPurchase>> verify({
    required String productId,
    required String purchaseToken,
  }) async {
    final response = await _client.post('/api/v1/purchases/verify', {
      'product_id': productId,
      'purchase_token': purchaseToken,
    });

    return switch (response) {
      ApiOk(:final value) => ApiOk(
        VerifiedPurchase(
          state: value['state'] as String? ?? 'unknown',
          adsRemoved: value['ads_removed'] as bool? ?? false,
          error: value['error'] as String?,
          adsRevoked: value['ads_revoked'] as bool? ?? false,
        ),
      ),
      ApiFailure(:final kind, :final detail, :final statusCode) => ApiFailure(
        kind,
        detail: detail,
        statusCode: statusCode,
      ),
    };
  }
}

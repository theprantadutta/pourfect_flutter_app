// Telling the server what the store said.
//
// Local billing already grants the entitlement, so none of this is what stops
// the ads. What the round trip buys happens on the server: ownership becomes
// exclusive to one account, and a refund becomes something anybody can notice
// at all — Play keeps reporting a refunded one-time purchase as purchased, so
// the device can never work it out for itself.
//
// The rule underneath every test here: VERIFICATION CAN GRANT, NEVER REVOKE.
// A `false` from the server is what a pending purchase looks like, what a
// refused token looks like, and what an outage half-way through looks like.
// Acting on it would strip somebody mid-session over a question the phone
// cannot answer.

import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pourfect_flutter_app/services/ads/ad_service.dart';
import 'package:pourfect_flutter_app/services/analytics/analytics_service.dart';
import 'package:pourfect_flutter_app/services/api/api_client.dart';
import 'package:pourfect_flutter_app/services/iap/billing_service.dart';
import 'package:pourfect_flutter_app/state/monetization_controller.dart';
import 'package:pourfect_flutter_app/state/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Billing whose receipt stream the test drives by hand.
class ReceiptBillingService implements BillingService {
  final _receipts = StreamController<PurchaseReceipt>.broadcast();
  final _changes = StreamController<bool>.broadcast();

  void deliver(PurchaseReceipt receipt) => _receipts.add(receipt);

  @override
  Stream<PurchaseReceipt> get receipts => _receipts.stream;

  @override
  Stream<bool> get adsRemovedChanges => _changes.stream;

  @override
  bool get adsRemoved => false;

  @override
  StoreProduct? get removeAdsProduct => null;

  @override
  Future<PurchaseOutcome> buyRemoveAds() async => PurchaseOutcome.unavailable;

  @override
  Future<void> init() async {}

  @override
  Future<void> restorePurchases() async {}

  @override
  Future<void> dispose() async {
    await _receipts.close();
    await _changes.close();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  ({
    ProviderContainer container,
    ReceiptBillingService billing,
    List<http.Request> calls,
  })
  harness({
    required MockClientHandler handler,
    String baseUrl = 'https://x.test',
  }) {
    final calls = <http.Request>[];
    final billing = ReceiptBillingService();

    final container = ProviderContainer(
      overrides: [
        billingServiceProvider.overrideWithValue(billing),
        adServiceProvider.overrideWithValue(const NoopAdService()),
        analyticsServiceProvider.overrideWithValue(
          const NoopAnalyticsService(),
        ),
        apiClientProvider.overrideWithValue(
          ApiClient(
            httpClient: MockClient((request) {
              calls.add(request);
              return handler(request);
            }),
            baseUrl: baseUrl,
            tokenProvider: ({bool forceRefresh = false}) async => 'tok',
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    addTearDown(billing.dispose);

    return (container: container, billing: billing, calls: calls);
  }

  String verdict({
    String state = 'purchased',
    bool adsRemoved = true,
    String? error,
  }) => jsonEncode({'state': state, 'ads_removed': adsRemoved, 'error': error});

  Future<void> settle() async {
    for (var i = 0; i < 5; i++) {
      await Future<void>.delayed(Duration.zero);
    }
  }

  const receipt = PurchaseReceipt(
    productId: 'remove_ads',
    token: 'play-token-123',
    restored: false,
  );

  group('a receipt reaches the server', () {
    test('with the product and the token, and nothing else', () async {
      final built = harness(
        handler: (_) async => http.Response(verdict(), 200),
      );
      built.container.read(monetizationProvider);

      built.billing.deliver(receipt);
      await settle();

      final call = built.calls.single;
      expect(call.url.path, '/api/v1/purchases/verify');
      expect(jsonDecode(call.body), {
        'product_id': 'remove_ads',
        'purchase_token': 'play-token-123',
      });
    });

    test('and a confirmed entitlement is applied', () async {
      final built = harness(
        handler: (_) async => http.Response(verdict(), 200),
      );
      built.container.read(monetizationProvider);

      built.billing.deliver(receipt);
      await settle();

      expect(built.container.read(monetizationProvider).adsRemoved, isTrue);
    });

    test('including a purchase the store merely replayed', () async {
      // THE RETRY MECHANISM. The store replays every owned purchase on launch,
      // so a purchase made while the phone had no signal verifies on the next
      // launch instead — no queue to persist, nothing that can be lost.
      final built = harness(
        handler: (_) async => http.Response(verdict(), 200),
      );
      built.container.read(monetizationProvider);

      built.billing.deliver(
        const PurchaseReceipt(
          productId: 'remove_ads',
          token: 'play-token-123',
          restored: true,
        ),
      );
      await settle();

      expect(built.calls, hasLength(1));
      expect(built.container.read(monetizationProvider).adsRemoved, isTrue);
    });
  });

  group('verification never costs an entitlement', () {
    test('a pending purchase does not grant, and does not revoke', () async {
      // Carrier billing, or a parent yet to approve. Granting hands the
      // entitlement away; refusing makes a later completion look like a double
      // charge. It is neither.
      final built = harness(
        handler: (_) async =>
            http.Response(verdict(state: 'pending', adsRemoved: false), 200),
      );
      built.container.read(monetizationProvider);

      built.billing.deliver(receipt);
      await settle();

      expect(built.container.read(monetizationProvider).adsRemoved, isFalse);
    });

    test('a server that says no does not take away a local grant', () async {
      final built = harness(
        handler: (_) async =>
            http.Response(verdict(state: 'unknown', adsRemoved: false), 200),
      );
      final money = built.container.read(monetizationProvider.notifier);
      money.debugSet(adsRemoved: true);

      built.billing.deliver(receipt);
      await settle();

      expect(
        built.container.read(monetizationProvider).adsRemoved,
        isTrue,
        reason: 'a server verdict revoked something the store had granted',
      );
    });

    test('an outage does not take away a local grant either', () async {
      final built = harness(handler: (_) async => http.Response('down', 503));
      final money = built.container.read(monetizationProvider.notifier);
      money.debugSet(adsRemoved: true);

      built.billing.deliver(receipt);
      await settle();

      expect(built.container.read(monetizationProvider).adsRemoved, isTrue);
    });

    test('a refused token does not take away a local grant', () async {
      final built = harness(
        handler: (_) async => http.Response('{"error":"Unknown product"}', 400),
      );
      final money = built.container.read(monetizationProvider.notifier);
      money.debugSet(adsRemoved: true);

      built.billing.deliver(receipt);
      await settle();

      expect(built.container.read(monetizationProvider).adsRemoved, isTrue);
    });
  });

  group('with no backend', () {
    test('nothing is sent and nothing breaks', () async {
      final built = harness(
        handler: (_) async => http.Response(verdict(), 200),
        baseUrl: '',
      );
      built.container.read(monetizationProvider);

      built.billing.deliver(receipt);
      await settle();

      expect(built.calls, isEmpty);
      expect(built.container.read(monetizationProvider).adsRemoved, isFalse);
    });
  });
}

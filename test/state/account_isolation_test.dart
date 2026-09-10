// The September 10 recheck, kept.
//
// Six interleavings that all looked fine sequentially and were wrong the
// moment two things overlapped. They are here rather than in the audit folder
// because every one of them is a rule the app has to keep:
//
//   * an acknowledgement names a REVISION, not a level;
//   * a reset invalidates the answers already in the air;
//   * "no session" is not "no account";
//   * a changed uid means the previous account's token is dead;
//   * a deleted account's data does not come back from an old request;
//   * a cached entitlement never outranks a newer confirmed refund.
//
// Adapted from the auditor's reproductions; the assertions are theirs.

import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pourfect_flutter_app/services/api/api_client.dart';
import 'package:pourfect_flutter_app/services/api/auth_service.dart';
import 'package:pourfect_flutter_app/services/api/identity.dart';
import 'package:pourfect_flutter_app/services/ads/ad_service.dart';
import 'package:pourfect_flutter_app/services/analytics/analytics_service.dart';
import 'package:pourfect_flutter_app/services/iap/billing_service.dart';
import 'package:pourfect_flutter_app/state/account_controller.dart';
import 'package:pourfect_flutter_app/state/monetization_controller.dart';
import 'package:pourfect_flutter_app/state/progress_repository.dart';
import 'package:pourfect_flutter_app/state/providers.dart';
import 'package:pourfect_flutter_app/state/sync_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'account_controller_test.dart' show FakeIdentity;
import 'sync_controller_test.dart' show levelWith, serverRow;
import 'purchase_verification_test.dart' show ReceiptBillingService;

class SwitchingIdentity extends FakeIdentity {
  @override
  Future<IdentityResult> signInWithEmail(String email,String password) async {
    uid='uid-2';
    return super.signInWithEmail(email,password);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));
  http.Response snapshot([bool populated=false]) => http.Response(jsonEncode({
    'accepted':1,'rejected':0,'changed':0,'progress':populated?[serverRow(levelId:1)]:[]}),200);
  ProviderContainer harness(MockClientHandler handler, {
    FakeIdentity? identity, IdTokenProvider? idToken, DateTime Function()? now,
    bool Function()? authFails,
    bool adsRemoved=false, BillingService billing=const NoopBillingService(),
  }) {
    final fake=identity??FakeIdentity();
    late AuthService auth;
    final client=ApiClient(baseUrl:'https://audit.test',
      tokenProvider:({bool forceRefresh=false})=>auth.bearerToken(forceRefresh:forceRefresh),
      httpClient:MockClient((request) async {
        if(request.url.path.endsWith('/auth/device')) {
          if(authFails?.call()??false) return http.Response('unavailable',503);
          return http.Response(jsonEncode({'access_token':'jwt-${fake.uid}',
            'user_id':fake.uid,'expires_in_seconds':3600,'is_anonymous':fake.isAnonymous,
            'ads_removed':adsRemoved}),200);
        }
        return handler(request);
      }));
    auth=AuthService(client:()=>client,now:now,
      idTokenProvider:idToken??({bool forceRefresh=false})async=>'firebase');
    final c=ProviderContainer(overrides:[
      apiClientProvider.overrideWithValue(client),authServiceProvider.overrideWithValue(auth),
      identityProvider.overrideWithValue(fake),
      billingServiceProvider.overrideWithValue(billing),
      adServiceProvider.overrideWithValue(const NoopAdService()),
      analyticsServiceProvider.overrideWithValue(const NoopAnalyticsService()),
    ]);
    addTearDown(c.dispose); addTearDown(client.close); return c;
  }

  test('an improved replay of the same level stays dirty during sync',() async {
    final entered=Completer<void>(),release=Completer<void>();
    final payloads=<List<dynamic>>[];
    final c=harness((r)async {
      payloads.add((jsonDecode(r.body)as Map)['items']as List);
      if(payloads.length==2){entered.complete();await release.future;}
      return snapshot();
    });
    final sync=c.read(syncControllerProvider.notifier);
    await sync.syncNow();
    final p=c.read(progressProvider.notifier);
    p.record(level:levelWith(id:1),levelSetVersion:1,movesUsed:10,elapsedSeconds:100);
    sync.markDirty(1);
    final running=sync.syncNow();await entered.future;
    p.record(level:levelWith(id:1),levelSetVersion:1,movesUsed:5,elapsedSeconds:50);
    sync.markDirty(1);
    release.complete();await running;await sync.syncNow();
    expect(payloads.last,isNotEmpty,reason:'removeAll(submitted) discarded a newer revision of level 1');
  });

  test('reset during a pending sync does not restore the old snapshot',()async {
    final entered=Completer<void>(),release=Completer<void>();
    var syncs=0;
    final c=harness((r)async {
      if(r.url.path.endsWith('/reset'))return http.Response('{}',200);
      if(++syncs==2){entered.complete();await release.future;}
      return snapshot(true);
    });
    final sync=c.read(syncControllerProvider.notifier);await sync.syncNow();
    final running=sync.syncNow();await entered.future;
    await c.read(progressProvider.notifier).resetAll();
    final resetting=sync.reset();
    await Future<void>.delayed(Duration.zero);
    release.complete();await running;await resetting;
    expect(c.read(progressProvider),isEmpty,reason:'An older response undid the local reset');
  });

  test('failed authentication must not report remote account deletion',()async {
    var online=true;var now=DateTime.utc(2026,9,10);
    var deleteCalls=0;
    final identity=FakeIdentity(isAnonymous:false);
    final c=harness((r)async {if(r.method=='DELETE')deleteCalls++;return snapshot();},
      identity:identity,now:()=>now,
      idToken:({bool forceRefresh=false})async=>online?'firebase':null);
    await c.read(authServiceProvider).ensureSession();
    now=now.add(const Duration(hours:2));online=false;
    final result=await c.read(accountProvider.notifier).deleteAccount();
    expect(deleteCalls,0);
    expect(result,isNot(AccountDeletion.deleted),reason:'No server request was made, but deletion reported success');
  });

  test('failed exchange after changing uid must not sync using the old account',()async {
    var authFails=false;
    final syncTokens=<String?>[];
    final identity=SwitchingIdentity();
    final c=harness((r)async {
      if(r.url.path.endsWith('/sync'))syncTokens.add(r.headers['authorization']);
      return snapshot();
    },identity:identity,authFails:()=>authFails);
    await c.read(authServiceProvider).ensureSession();
    authFails=true;
    await c.read(accountProvider.notifier).signIn('second@example.test','password');
    expect(identity.uid,'uid-2');
    expect(syncTokens, isNot(contains('Bearer jwt-uid-1')),
      reason:'Identity changed to uid-2 while an authenticated write still targeted uid-1');
  });

  test('a sync response after account deletion must not restore deleted data',()async {
    final entered=Completer<void>(),release=Completer<void>();
    var syncs=0;
    final c=harness((r)async {
      if(r.method=='DELETE')return http.Response('{}',200);
      if(++syncs==2){entered.complete();await release.future;}
      return snapshot(true);
    });
    final sync=c.read(syncControllerProvider.notifier);await sync.syncNow();
    final running=sync.syncNow();await entered.future;
    final deletion=await c.read(accountProvider.notifier).deleteAccount();
    expect(deletion,AccountDeletion.deleted);
    expect(c.read(progressProvider),isEmpty);
    release.complete();await running;
    expect(c.read(progressProvider),isEmpty,reason:'Deleted-account progress returned from an old request');
  });

  test('a cached auth grant cannot undo a newer confirmed refund',()async {
    final billing=ReceiptBillingService();addTearDown(billing.dispose);
    final c=harness((r)async {
      if(r.url.path.endsWith('/purchases/verify')) {
        return http.Response('{"state":"refunded","ads_removed":false,"ads_revoked":true}',200);
      }
      return snapshot();
    },adsRemoved:true,billing:billing);
    final sync=c.read(syncControllerProvider.notifier);await sync.syncNow();
    expect(c.read(monetizationProvider).adsRemoved,isTrue);
    billing.deliver(const PurchaseReceipt(productId:'remove_ads',token:'refunded',restored:true));
    for(var i=0;i<10;i++){await Future<void>.delayed(Duration.zero);}
    expect(c.read(monetizationProvider).adsRemoved,isFalse);
    await sync.syncNow();
    expect(c.read(monetizationProvider).adsRemoved,isFalse,
      reason:'Cached pre-refund auth.adsRemoved=true restored the entitlement');
  });
}

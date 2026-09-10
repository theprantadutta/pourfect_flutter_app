// Ownership of an operation, when the owner is not simply "who is signed in".
//
// Two more lifecycle holes, both left by the previous round's own fixes:
//
//   * reset() asked ensureSession() WHO we are. That answers a different
//     question — authorization — and returns null offline, so a reset made
//     with an expired login belonged to nobody, was filed under the unscoped
//     key, and was discarded the moment the real account's metadata loaded.
//
//   * _adoptRemoteReset() awaited a preference write and a full campaign
//     erase, then merged unconditionally. Switching accounts during that save
//     put account A's level 1 into account B, which uploaded it under B's
//     token.
//
// Scenarios and assertions are the auditor's, kept verbatim.

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pourfect_flutter_app/services/api/api_client.dart';
import 'package:pourfect_flutter_app/services/api/auth_service.dart';
import 'package:pourfect_flutter_app/services/ads/ad_service.dart';
import 'package:pourfect_flutter_app/services/analytics/analytics_service.dart';
import 'package:pourfect_flutter_app/services/iap/billing_service.dart';
import 'package:pourfect_flutter_app/state/account_controller.dart';
import 'package:pourfect_flutter_app/state/progress_repository.dart';
import 'package:pourfect_flutter_app/state/providers.dart';
import 'package:pourfect_flutter_app/state/sync_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'account_controller_test.dart' show FakeIdentity;
import 'sync_controller_test.dart' show serverRow;

class GatedProgressRepository extends ProgressRepository {
  final entered=Completer<void>(), release=Completer<void>();
  bool gate=true;
  @override Future<void> save(Map<int,LevelProgress> value) async {
    if(gate && value.isEmpty){gate=false;entered.complete();await release.future;}
    await super.save(value);
  }
}
http.Response sessionResponse(String uid)=>http.Response(jsonEncode({
  'access_token':'jwt-$uid','user_id':uid,'expires_in_seconds':3600,
  'is_anonymous':false,'ads_removed':false,
}),200);
http.Response snapshot({int generation=0,bool populated=false})=>http.Response(jsonEncode({
  'accepted':0,'rejected':0,'changed':0,'reset_generation':generation,
  'progress':populated?[serverRow(levelId:1)]:[],
}),200);

void main(){
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(()=>SharedPreferences.setMockInitialValues({}));
  ProviderContainer harness(MockClientHandler handler,{
    required FakeIdentity identity, DateTime Function()? now,
    IdTokenProvider? idToken,ProgressRepository? repository,
  }){
    late AuthService auth;
    final client=ApiClient(baseUrl:'https://audit.test',
      tokenProvider:({bool forceRefresh=false})=>auth.bearerToken(forceRefresh:forceRefresh),
      httpClient:MockClient((r)async=>r.url.path.endsWith('/auth/device')
        ?sessionResponse(identity.uid):await handler(r)));
    auth=AuthService(client:()=>client,now:now,
      idTokenProvider:idToken??({bool forceRefresh=false})async=>'firebase');
    final c=ProviderContainer(overrides:[
      apiClientProvider.overrideWithValue(client),authServiceProvider.overrideWithValue(auth),
      identityProvider.overrideWithValue(identity),
      billingServiceProvider.overrideWithValue(const NoopBillingService()),
      adServiceProvider.overrideWithValue(const NoopAdService()),
      analyticsServiceProvider.overrideWithValue(const NoopAnalyticsService()),
      if(repository!=null)progressRepositoryProvider.overrideWithValue(repository),
    ]);
    addTearDown(c.dispose);addTearDown(client.close);return c;
  }

  test('an offline reset with an expired session remains owned by the known account',()async{
    var now=DateTime.utc(2026,9,10),online=true;
    final paths=<String>[];
    final c=harness((r)async{
      paths.add(r.url.path);
      return snapshot(populated:!r.url.path.endsWith('/reset'));
    },identity:FakeIdentity(),now:()=>now,
      idToken:({bool forceRefresh=false})async=>online?'firebase':null);
    final auth=c.read(authServiceProvider);await auth.ensureSession();
    final sync=c.read(syncControllerProvider.notifier);await sync.syncNow();
    expect(c.read(progressProvider).containsKey(1),isTrue);
    now=now.add(const Duration(hours:2));online=false;
    await c.read(progressProvider.notifier).resetAll();
    expect(await sync.reset(),isFalse);
    expect(auth.accountId,'uid-1');
    paths.clear();online=true;await sync.syncNow();
    debugPrint('After offline expired-session reset: requests=$paths, local rows=${c.read(progressProvider).length}');
    expect(paths,contains('/api/v1/progress/reset'));
    expect(c.read(progressProvider),isEmpty);
  });

  test('remote reset adoption cannot merge old account rows after switching during save',()async{
    final repository=GatedProgressRepository();
    final identity=FakeIdentity();
    final uploadsToB=<List<dynamic>>[];
    final c=harness((r)async{
      if(r.headers['authorization']=='Bearer jwt-uid-existing'){
        if(r.url.path.endsWith('/sync')) uploadsToB.add((jsonDecode(r.body)as Map)['items']as List);
        return snapshot();
      }
      return snapshot(generation:1,populated:true);
    },
      identity:identity,repository:repository);
    final sync=c.read(syncControllerProvider.notifier);
    final running=sync.syncNow();await repository.entered.future;
    final switching=c.read(accountProvider.notifier).useExistingGoogleAccount();
    // Wait for the observable account abandonment, not a raced timeout.
    for(var i=0;i<100 && c.read(authServiceProvider).current!=null;i++){
      await Future<void>.delayed(Duration.zero);
    }
    expect(c.read(authServiceProvider).current,isNull);
    // Drain already queued microtasks so the switch reaches its local wipe.
    await Future<void>.delayed(Duration.zero);
    repository.release.complete();
    await running;expect((await switching).isOk,isTrue);
    debugPrint('After switch during reset adoption: account=${c.read(authServiceProvider).accountId}, local rows=${c.read(progressProvider).keys}');
    expect(c.read(authServiceProvider).accountId,'uid-existing');
    await sync.pushEverything();
    debugPrint('Rows uploaded with B bearer: $uploadsToB');
    expect(uploadsToB.single,isEmpty);
    expect(c.read(progressProvider),isEmpty);
  });
}

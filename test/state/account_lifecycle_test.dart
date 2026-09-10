// Account and reset LIFETIME, across awaits and across launches.
//
// The previous round bound sync responses to an account. These are the places
// that binding did not reach, all of which survived the first fix:
//
//   * dropping a Future pointer does not cancel the HTTP request behind it,
//     so an abandoned exchange still published its session to memory and disk;
//   * preference keys were namespaced while the in-memory copies were not, so
//     account A's undelivered reset was sent with account B's token;
//   * metadata was read before the session resolved, so a cold start read the
//     wrong keys and marked restoration done for the wrong account;
//   * pullOnly() had none of the guards _run() had, and account switching now
//     goes through it;
//   * adopting another device's reset erased local progress without keeping
//     the post-reset rows the same response had just delivered.
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
import 'package:pourfect_flutter_app/services/api/session.dart';
import 'package:pourfect_flutter_app/services/ads/ad_service.dart';
import 'package:pourfect_flutter_app/services/analytics/analytics_service.dart';
import 'package:pourfect_flutter_app/services/iap/billing_service.dart';
import 'package:pourfect_flutter_app/state/account_controller.dart';
import 'package:pourfect_flutter_app/state/progress_repository.dart';
import 'package:pourfect_flutter_app/state/providers.dart';
import 'package:pourfect_flutter_app/state/sync_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'account_controller_test.dart' show FakeIdentity;
import 'sync_controller_test.dart' show serverRow, levelWith;

http.Response sessionResponse(String uid) => http.Response(jsonEncode({
  'access_token':'jwt-$uid','user_id':uid,'expires_in_seconds':3600,
  'is_anonymous':false,'ads_removed':false,
}),200);
http.Response progressResponse({int generation=0,bool populated=false}) =>
  http.Response(jsonEncode({'accepted':0,'rejected':0,'changed':0,
    'reset_generation':generation,'progress':populated?[serverRow(levelId:1)]:[]}),200);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(()=>SharedPreferences.setMockInitialValues({}));
  ProviderContainer harness(MockClientHandler handler,{FakeIdentity? identity}) {
    final fake=identity??FakeIdentity();
    late AuthService auth;
    final client=ApiClient(baseUrl:'https://audit.test',
      tokenProvider:({bool forceRefresh=false})=>auth.bearerToken(forceRefresh:forceRefresh),
      httpClient:MockClient((r)async=>r.url.path.endsWith('/auth/device')
        ?sessionResponse(fake.uid):await handler(r)));
    auth=AuthService(client:()=>client,
      idTokenProvider:({bool forceRefresh=false})async=>'firebase-${fake.uid}');
    final c=ProviderContainer(overrides:[
      apiClientProvider.overrideWithValue(client),authServiceProvider.overrideWithValue(auth),
      identityProvider.overrideWithValue(fake),
      billingServiceProvider.overrideWithValue(const NoopBillingService()),
      adServiceProvider.overrideWithValue(const NoopAdService()),
      analyticsServiceProvider.overrideWithValue(const NoopAnalyticsService()),
    ]);
    addTearDown(c.dispose);addTearDown(client.close);return c;
  }

  test('late old auth exchange cannot replace the new account session',()async {
    final entered=Completer<void>(),release=Completer<void>();
    var uid='old';
    final client=ApiClient(baseUrl:'https://audit.test',httpClient:MockClient((r)async {
      final id=(jsonDecode(r.body)as Map)['id_token'] as String;
      if(id=='old'){entered.complete();await release.future;}
      return sessionResponse(id);
    }));
    addTearDown(client.close);
    final auth=AuthService(client:()=>client,
      idTokenProvider:({bool forceRefresh=false})async=>uid);
    final old=auth.ensureSession(forceRefresh:true);await entered.future;
    await auth.abandonAccount();uid='new';
    await auth.ensureSession(forceRefresh:true);
    expect(auth.current?.userId,'new');
    release.complete();await old;
    debugPrint('After old auth response: memory=${auth.current?.userId}, disk=${(await SessionStore().load())?.userId}');
    expect(auth.current?.userId,'new');
    expect((await SessionStore().load())?.userId,'new');
  });

  test('pending reset for A cannot be sent with B bearer token',()async {
    final resetTokens=<String?>[];
    final c=harness((r)async {
      if(r.url.path.endsWith('/reset')) {
        resetTokens.add(r.headers['authorization']);
        return r.headers['authorization']=='Bearer jwt-uid-1'
          ?http.Response('offline',503):progressResponse(generation:1);
      }
      return progressResponse();
    });
    final auth=c.read(authServiceProvider);await auth.ensureSession();
    final sync=c.read(syncControllerProvider.notifier);
    expect(await sync.reset(),isFalse);
    final switched=await c.read(accountProvider.notifier).useExistingGoogleAccount();
    expect(switched.isOk,isTrue);
    expect(auth.current?.userId,'uid-existing');
    await sync.syncNow();
    debugPrint('Reset authorization headers: $resetTokens');
    expect(resetTokens,isNot(contains('Bearer jwt-uid-existing')));
  });

  test('cold start restores pending reset from the stored account',()async {
    final first=harness((r)async=>http.Response('offline',503));
    await first.read(authServiceProvider).ensureSession();
    expect(await first.read(syncControllerProvider.notifier).reset(),isFalse);
    final prefs=await SharedPreferences.getInstance();
    expect(prefs.getBool('pourfect.sync.reset_pending.uid-1'),isTrue);
    final paths=<String>[];
    final relaunched=harness((r)async {
      paths.add(r.url.path);
      return progressResponse(populated:!r.url.path.endsWith('/reset'));
    });
    expect(relaunched.read(authServiceProvider).current,isNull);
    await relaunched.read(syncControllerProvider.notifier).syncNow();
    debugPrint('Cold-start requests: $paths; local rows=${relaunched.read(progressProvider).length}');
    expect(paths,contains('/api/v1/progress/reset'));
    expect(relaunched.read(progressProvider),isEmpty);
  });

  test('cold start keeps progress earned under the stored reset generation',()async {
    final first=harness((r)async=>progressResponse(generation:1));
    await first.read(authServiceProvider).ensureSession();
    expect(await first.read(syncControllerProvider.notifier).reset(),isTrue);
    final progress=first.read(progressProvider.notifier);await progress.restored;
    progress.record(level:levelWith(id:1),levelSetVersion:1,movesUsed:5,elapsedSeconds:50);
    await first.read(progressRepositoryProvider).save(first.read(progressProvider));
    final prefs=await SharedPreferences.getInstance();
    expect(prefs.getInt('pourfect.sync.reset_generation.uid-1'),1);
    final uploaded=<int>[];
    final relaunched=harness((r)async {
      final body=jsonDecode(r.body)as Map;
      uploaded.add(body['reset_generation']as int);
      return progressResponse(generation:1);
    });
    await relaunched.read(progressProvider.notifier).restored;
    expect(relaunched.read(progressProvider).containsKey(1),isTrue);
    await relaunched.read(syncControllerProvider.notifier).syncNow();
    debugPrint('Stored generation=1, uploaded=$uploaded; surviving local rows=${relaunched.read(progressProvider).length}');
    expect(uploaded,[1]);
    expect(relaunched.read(progressProvider).containsKey(1),isTrue);
  });

  test('pull response after deletion cannot restore the deleted campaign',()async {
    final entered=Completer<void>(),release=Completer<void>();
    final c=harness((r)async {
      if(r.method=='GET'){entered.complete();await release.future;return progressResponse(populated:true);}
      return http.Response('{}',200);
    });
    final sync=c.read(syncControllerProvider.notifier);
    final running=sync.pullOnly();await entered.future;
    expect(await c.read(accountProvider.notifier).deleteAccount(),AccountDeletion.deleted);
    expect(c.read(progressProvider),isEmpty);
    release.complete();await running;
    debugPrint('Local campaign after deleted account pull: ${c.read(progressProvider).keys}');
    expect(c.read(progressProvider),isEmpty);
  });

  test('adopting a remote reset includes the server post-reset progress',()async {
    final c=harness((r)async=>progressResponse(generation:1,populated:true));
    await c.read(syncControllerProvider.notifier).syncNow();
    debugPrint('Post-reset server row 1 present locally: ${c.read(progressProvider).containsKey(1)}');
    expect(c.read(progressProvider).containsKey(1),isTrue);
  });
}

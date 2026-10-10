// Ball skins and tube themes, as the app keeps them.

import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pourfect_flutter_app/services/api/api_client.dart';
import 'package:pourfect_flutter_app/services/api/auth_service.dart';
import 'package:pourfect_flutter_app/state/cosmetics_controller.dart';
import 'package:pourfect_flutter_app/state/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  Map<String, Object?> body({String ball = 'glossy', String tube = 'toy'}) => {
    'items': [
      {
        'id': 'classic',
        'name': 'Classic',
        'kind': 'ball_skin',
        'owned': true,
        'source': 'free',
        'value': 0,
      },
      {
        'id': 'glossy',
        'name': 'Glossy',
        'kind': 'ball_skin',
        'owned': true,
        'source': 'chest',
        'value': 3,
      },
      {
        'id': 'marble',
        'name': 'Marble',
        'kind': 'ball_skin',
        'owned': false,
        'source': 'pack',
        'value': 0,
      },
      {
        'id': 'toy',
        'name': 'Toy',
        'kind': 'tube_theme',
        'owned': true,
        'source': 'free',
        'value': 0,
      },
      {
        'id': 'frost',
        'name': 'Frost',
        'kind': 'tube_theme',
        'owned': false,
        'source': 'streak',
        'value': 30,
      },
    ],
    'equipped_ball_skin': ball,
    'equipped_tube_theme': tube,
    'skin_pack_owned': false,
  };

  ({ProviderContainer container, List<http.Request> calls}) harness(
    Future<http.Response> Function(http.Request) handler,
  ) {
    final calls = <http.Request>[];
    final client = ApiClient(
      httpClient: MockClient((request) async {
        calls.add(request);
        if (request.url.path.endsWith('/auth/device')) {
          return http.Response(
            jsonEncode({
              'access_token': 'jwt',
              'expires_in_seconds': 3600,
              'user_id': 'u',
              'ads_removed': false,
              'is_new_user': false,
              'is_anonymous': true,
              'auth_provider': 'anonymous',
            }),
            200,
          );
        }
        return handler(request);
      }),
      baseUrl: 'https://api.test',
      tokenProvider: ({bool forceRefresh = false}) async => 'tok',
    );
    final container = ProviderContainer(
      overrides: [
        apiClientProvider.overrideWithValue(client),
        authServiceProvider.overrideWith(
          (ref) => AuthService(
            client: () => client,
            idTokenProvider: ({bool forceRefresh = false}) async =>
                'firebase-id',
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    return (container: container, calls: calls);
  }

  test('reads what is owned and what is worn', () async {
    final built = harness((_) async => http.Response(jsonEncode(body()), 200));

    await built.container.read(cosmeticsProvider.notifier).refresh();
    final state = built.container.read(cosmeticsProvider);

    expect(state.ballSkin, 'glossy');
    expect(state.tubeTheme, 'toy');
    expect(state.owns('glossy'), isTrue);
    expect(state.owns('marble'), isFalse);
    expect(
      state.items.firstWhere((i) => i.id == 'frost').unlockHint,
      '30-day streak',
    );
  });

  test('what is worn is remembered for the next launch', () async {
    final built = harness((_) async => http.Response(jsonEncode(body()), 200));
    await built.container.read(cosmeticsProvider.notifier).refresh();
    await Future<void>.delayed(Duration.zero);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('pourfect.cosmetics.ball'), 'glossy');
  });

  test('equipping shows at once and keeps the server\'s answer', () async {
    final built = harness(
      (request) async => request.method == 'PUT'
          ? http.Response(jsonEncode(body(ball: 'classic')), 200)
          : http.Response(jsonEncode(body()), 200),
    );
    final cosmetics = built.container.read(cosmeticsProvider.notifier);
    await cosmetics.refresh();

    final ok = await cosmetics.equip(ballSkin: 'classic');

    expect(ok, isTrue);
    expect(built.container.read(cosmeticsProvider).ballSkin, 'classic');
    final put = built.calls.lastWhere((c) => c.method == 'PUT');
    expect(jsonDecode(put.body), {'ball_skin': 'classic'});
  });

  test('a refused equip puts the old skin back', () async {
    final built = harness(
      (request) async => request.method == 'PUT'
          ? http.Response('{"error":"Not unlocked yet"}', 403)
          : http.Response(jsonEncode(body()), 200),
    );
    final cosmetics = built.container.read(cosmeticsProvider.notifier);
    await cosmetics.refresh();

    final ok = await cosmetics.equip(ballSkin: 'marble');

    expect(ok, isFalse);
    expect(built.container.read(cosmeticsProvider).ballSkin, 'glossy');
  });
}

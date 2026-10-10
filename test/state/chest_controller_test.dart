// Star chests: earned on the device, opened by the server, banked as credits.

import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pourfect_flutter_app/services/api/api_client.dart';
import 'package:pourfect_flutter_app/services/api/auth_service.dart';
import 'package:pourfect_flutter_app/state/chest_controller.dart';
import 'package:pourfect_flutter_app/state/monetization_controller.dart';
import 'package:pourfect_flutter_app/state/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  String status({List<Map<String, Object?>> opened = const []}) => jsonEncode({
    'total_stars': 64,
    'stars_per_chest': 30,
    'earned': 2,
    'opened': opened,
  });

  String reward(int index, {bool doubled = false}) => jsonEncode({
    'index': index,
    'hints': 2,
    'extra_tubes': 1,
    'cosmetic': index % 3 == 0,
    'doubled': doubled,
  });

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
        if (!request.url.path.contains('/chests')) {
          // Sync and anything else the open path touches on its way.
          return http.Response('{}', 200);
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

  test('reads which chests are open', () async {
    final built = harness(
      (_) async => http.Response(
        status(
          opened: [
            {'index': 1, 'doubled': true},
          ],
        ),
        200,
      ),
    );

    await built.container.read(chestProvider.notifier).refresh();

    expect(built.container.read(chestProvider).server?.opened, {1: true});
  });

  test('an opened chest banks two hints and a tube', () async {
    final built = harness(
      (request) async => request.url.path.endsWith('/open')
          ? http.Response(reward(1), 200)
          : http.Response(status(), 200),
    );
    final chests = built.container.read(chestProvider.notifier);
    await chests.refresh();

    final (opened, failure) = await chests.open(1);

    expect(failure, isNull);
    expect(opened?.hints, 2);
    final money = built.container.read(monetizationProvider);
    expect(money.hintCredits, 2);
    expect(money.extraTubeCredits, 1);
    expect(built.container.read(chestProvider).server?.opened, {1: false});
  });

  test('a doubled chest banks the same again', () async {
    final built = harness(
      (request) async => request.url.path.endsWith('/double')
          ? http.Response(reward(1, doubled: true), 200)
          : request.url.path.endsWith('/open')
          ? http.Response(reward(1), 200)
          : http.Response(status(), 200),
    );
    final chests = built.container.read(chestProvider.notifier);
    await chests.refresh();
    await chests.open(1);

    await chests.double(1);

    final money = built.container.read(monetizationProvider);
    expect(money.hintCredits, 4);
    expect(money.extraTubeCredits, 2);
  });

  test('stars the server has not seen yet read as not yet', () async {
    final built = harness(
      (request) async => request.url.path.endsWith('/open')
          ? http.Response('{"error":"Chest 2 opens at 60 stars"}', 403)
          : http.Response(status(), 200),
    );

    final (opened, failure) = await built.container
        .read(chestProvider.notifier)
        .open(2);

    expect(opened, isNull);
    expect(failure, ChestFailure.notYet);
    expect(built.container.read(monetizationProvider).hintCredits, 0);
  });

  test('a chest another device opened banks nothing here', () async {
    final built = harness(
      (request) async => request.url.path.endsWith('/open')
          ? http.Response('{"error":"That chest is already open"}', 409)
          : http.Response(status(), 200),
    );

    final (_, failure) = await built.container
        .read(chestProvider.notifier)
        .open(1);

    expect(failure, ChestFailure.alreadyOpen);
    expect(built.container.read(monetizationProvider).hintCredits, 0);
  });
}

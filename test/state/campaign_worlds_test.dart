// Worlds past level 150: parsed, checked, downloaded near the end of what the
// phone holds, stored for offline play, and merged into the campaign.
//
// The server is scripted here. What is under test is the app's side of the
// contract: it asks at the right moment, never appends a world that would
// leave a hole, and keeps what it has across a relaunch.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pourfect_flutter_app/services/api/api_client.dart';
import 'package:pourfect_flutter_app/services/api/api_result.dart';
import 'package:pourfect_flutter_app/services/api/campaign_api.dart';
import 'package:pourfect_flutter_app/state/campaign_worlds.dart';
import 'package:pourfect_flutter_app/state/progress_repository.dart';
import 'package:pourfect_flutter_app/state/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A valid four-color board: every color exactly fills one tube.
const _tubes = [
  [0, 1, 2, 3],
  [1, 2, 3, 0],
  [2, 3, 0, 1],
  [3, 0, 1, 2],
  <int>[],
  <int>[],
];

Map<String, Object?> _levelJson(int id, {List<List<int>> tubes = _tubes}) => {
  'id': id,
  'capacity': 4,
  'tubes': tubes,
  'min_moves': 12,
  'difficulty_score': 70.5,
  'forced_move_ratio': 0.1,
  'is_breather': id % 10 == 0,
};

Map<String, Object?> _worldJson(
  int index, {
  List<String> mechanics = const [],
  Map<String, Object?> Function(int id)? level,
}) {
  final first = 151 + (index - 4) * 50;
  return {
    'index': index,
    'name': 'World $index',
    'first_level': first,
    'last_level': first + 49,
    'level_set_version': 1,
    'mechanics': mechanics,
    'levels': [
      for (var id = first; id < first + 50; id++) (level ?? _levelJson)(id),
    ],
  };
}

CampaignWorld _world(
  int index, {
  Map<String, Object?> Function(int id)? level,
}) {
  final parsed = CampaignApi.parse({
    'worlds': [_worldJson(index, level: level)],
    'update_required': false,
    'published_through': 300,
  });
  return (parsed as ApiOk<CampaignWorlds>).value.worlds.single;
}

/// Serves whatever it is told, and records every request.
class _FakeCampaignApi extends CampaignApi {
  _FakeCampaignApi(this.answer) : super(ApiClient());

  ApiResult<CampaignWorlds> Function(int after) answer;
  final requests = <int>[];

  @override
  Future<ApiResult<CampaignWorlds>> worlds({
    required int after,
    required List<String> mechanics,
    int limit = 2,
  }) async {
    requests.add(after);
    return answer(after);
  }
}

/// Serves worlds 4, 5 and 6, two at a time, like the real endpoint.
ApiResult<CampaignWorlds> _server(int after) {
  final worlds = [
    for (final index in [4, 5, 6])
      if (151 + (index - 4) * 50 > after) _worldJson(index),
  ].take(2).toList();
  return CampaignApi.parse({
    'worlds': worlds,
    'update_required': false,
    'published_through': 300,
  });
}

/// A player who has cleared levels 1..[cleared].
class _Cleared extends ProgressController {
  _Cleared(this.cleared);
  final int cleared;

  @override
  Map<int, LevelProgress> build() {
    super.build();
    return {
      for (var id = 1; id <= cleared; id++)
        id: LevelProgress(
          levelId: id,
          levelSetVersion: 1,
          stars: 3,
          bestMoves: 5,
        ),
    };
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  ({ProviderContainer container, _FakeCampaignApi api}) harness({
    required int cleared,
    ApiResult<CampaignWorlds> Function(int after) answer = _server,
  }) {
    final api = _FakeCampaignApi(answer);
    final container = ProviderContainer(
      overrides: [
        apiClientProvider.overrideWithValue(
          ApiClient(baseUrl: 'https://api.test'),
        ),
        campaignApiProvider.overrideWithValue(api),
        progressProvider.overrideWith(() => _Cleared(cleared)),
      ],
    );
    addTearDown(container.dispose);
    return (container: container, api: api);
  }

  group('parsing', () {
    test('a world arrives as campaign levels in its own band', () {
      final world = _world(4);
      expect(world.firstLevel, 151);
      expect(world.levels, hasLength(50));
      expect(world.levels.first.level.id, 151);
      expect(world.levels.first.bandIndex, 4);
      expect(world.levels.first.level.minMoves, 12);
      expect(world.levels[9].isBreather, isTrue);
    });

    test('one malformed level refuses the whole response', () {
      final result = CampaignApi.parse({
        'worlds': [
          _worldJson(4, level: (id) => id == 170 ? {'id': id} : _levelJson(id)),
        ],
      });
      expect(result, isA<ApiFailure<CampaignWorlds>>());
    });
  });

  group('what the phone accepts', () {
    test('a sound world directly after what is held', () {
      expect(worldProblem(_world(4), heldThrough: 150), isNull);
    });

    test('never one that would leave a hole', () {
      expect(
        worldProblem(_world(5), heldThrough: 150),
        contains('expected 151'),
      );
    });

    test('never a color with no palette entry', () {
      final world = _world(
        4,
        level: (id) => _levelJson(
          id,
          tubes: [
            [0, 1, 2, 10],
            [1, 2, 10, 0],
            [2, 10, 0, 1],
            [10, 0, 1, 2],
            [],
            [],
          ],
        ),
      );
      expect(worldProblem(world, heldThrough: 150), contains('color 10'));
    });

    test('never a board that can never be sorted', () {
      // Five of color 0 and three of color 3: no tube can ever be one color.
      final world = _world(
        4,
        level: (id) => _levelJson(
          id,
          tubes: [
            [0, 1, 2, 0],
            [1, 2, 3, 0],
            [2, 3, 0, 1],
            [0, 0, 1, 2],
            [],
            [],
          ],
        ),
      );
      expect(worldProblem(world, heldThrough: 150), contains('balls of color'));
    });

    test('never a mechanic this build cannot play', () {
      final parsed = CampaignApi.parse({
        'worlds': [
          _worldJson(4, mechanics: ['hidden_balls']),
        ],
      });
      final world = (parsed as ApiOk<CampaignWorlds>).value.worlds.single;
      expect(worldProblem(world, heldThrough: 150), contains('hidden_balls'));
    });

    group('tall tubes', () {
      const tall = [
        [0, 1, 2, 3, 0],
        [1, 2, 3, 0, 1],
        [2, 3, 0, 1, 2],
        [3, 0, 1, 2, 3],
        <int>[],
        <int>[],
      ];

      CampaignWorld tallWorld({
        required List<String> mechanics,
        required List<List<int>> tubes,
        required int capacity,
      }) {
        final parsed = CampaignApi.parse({
          'worlds': [
            _worldJson(
              4,
              mechanics: mechanics,
              level: (id) => {
                ..._levelJson(id, tubes: tubes),
                'capacity': capacity,
              },
            ),
          ],
        });
        return (parsed as ApiOk<CampaignWorlds>).value.worlds.single;
      }

      test('this build plays them', () {
        expect(kSupportedMechanics, contains(kTallTubes));
        final world = tallWorld(
          mechanics: [kTallTubes],
          tubes: tall,
          capacity: 5,
        );
        expect(worldProblem(world, heldThrough: 150), isNull);
        expect(world.levels.first.level.board.capacity, 5);
      });

      test('but only where the world declares them', () {
        // The declaration is all the server checks before serving a world,
        // so a five-ball board in a classic world would have reached an app
        // that cannot draw one.
        final undeclared = tallWorld(mechanics: [], tubes: tall, capacity: 5);
        expect(
          worldProblem(undeclared, heldThrough: 150),
          contains('declares 4'),
        );

        final short = tallWorld(
          mechanics: [kTallTubes],
          tubes: _tubes,
          capacity: 4,
        );
        expect(worldProblem(short, heldThrough: 150), contains('declares 5'));
      });
    });
  });

  group('when to ask', () {
    test('within one world of the end, and not before', () {
      expect(
        shouldFetchWorlds(furthestUnlocked: 100, heldThrough: 150),
        isFalse,
      );
      expect(
        shouldFetchWorlds(furthestUnlocked: 101, heldThrough: 150),
        isTrue,
      );
      expect(
        shouldFetchWorlds(furthestUnlocked: 151, heldThrough: 150),
        isTrue,
      );
    });

    test('a player early in the campaign never touches the network', () async {
      final h = harness(cleared: 40);
      await h.container.read(campaignWorldsProvider.notifier).maybeFetch();
      expect(h.api.requests, isEmpty);
    });
  });

  group('downloading', () {
    test(
      'a player past 100 gets the next worlds, merged into the campaign',
      () async {
        final h = harness(cleared: 120);
        await h.container.read(bundledCampaignProvider.future);
        await h.container.read(campaignWorldsProvider.notifier).maybeFetch();

        expect(h.api.requests.first, 150);
        final campaign = h.container.read(campaignProvider).value!;
        expect(campaign.levels.length, greaterThanOrEqualTo(250));
        expect(campaign.byId(151)!.level.minMoves, 12);

        final bands = h.container.read(campaignBandsProvider);
        expect(bands[4].name, 'World 4');
        expect(bands[4].firstLevel, 151);
      },
    );

    test(
      'a new phone restoring a player at 290 catches all the way up',
      () async {
        final h = harness(cleared: 290);
        await h.container.read(campaignWorldsProvider.notifier).maybeFetch();

        expect(h.container.read(campaignWorldsProvider).heldThrough, 300);
        // Still within a world of the end at 300, so it asks once more, finds
        // nothing newer, and goes quiet rather than asking again.
        expect(h.api.requests, [150, 250, 300]);
        await h.container.read(campaignWorldsProvider.notifier).maybeFetch();
        expect(h.api.requests, hasLength(3));
      },
    );

    test('what was downloaded is still there after a relaunch', () async {
      final first = harness(cleared: 120);
      await first.container.read(campaignWorldsProvider.notifier).maybeFetch();
      final held = first.container.read(campaignWorldsProvider).heldThrough;

      // Same preferences, fresh process, and a server that is down.
      final second = harness(
        cleared: 120,
        answer: (_) => const ApiFailure(ApiFailureKind.offline),
      );
      await second.container.read(campaignWorldsProvider.notifier).ready;
      final restored = second.container.read(campaignWorldsProvider);
      expect(restored.heldThrough, held);
      expect(restored.worlds.first.levels.first.level.id, 151);
    });

    test(
      'a failed download is reported, and not retried on every pour',
      () async {
        final h = harness(
          cleared: 150,
          answer: (_) => const ApiFailure(ApiFailureKind.offline),
        );
        final worlds = h.container.read(campaignWorldsProvider.notifier);
        await worlds.maybeFetch();
        await worlds.maybeFetch();

        expect(h.api.requests, hasLength(1));
        expect(
          h.container.read(campaignWorldsProvider).fetch,
          WorldsFetch.failed,
        );

        // An app resume skips the quiet period: the network may be back.
        await worlds.maybeFetch(force: true);
        expect(h.api.requests, hasLength(2));
      },
    );

    test(
      'an old build is told to update, not handed a world it cannot play',
      () async {
        final h = harness(
          cleared: 150,
          answer: (_) => CampaignApi.parse({
            'worlds': [],
            'update_required': true,
            'published_through': 200,
          }),
        );
        await h.container.read(campaignWorldsProvider.notifier).maybeFetch();

        final state = h.container.read(campaignWorldsProvider);
        expect(state.worlds, isEmpty);
        expect(state.updateRequired, isTrue);
      },
    );

    test(
      'a bad world stops the download there, keeping the good ones',
      () async {
        final h = harness(
          cleared: 150,
          answer: (after) => CampaignApi.parse({
            'worlds': [
              _worldJson(4),
              // World 5 claims to start at 201 but brings 49 levels.
              {..._worldJson(5), 'last_level': 251},
            ],
          }),
        );
        await h.container.read(campaignWorldsProvider.notifier).maybeFetch();

        expect(h.container.read(campaignWorldsProvider).heldThrough, 200);
      },
    );
  });
}

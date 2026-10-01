/// The campaign past level 150: worlds the server generates and this app
/// downloads in the background.
///
/// The APK carries levels 1-150 and nothing here ever stands between a player
/// and those. When a player comes within one world of the end of what this
/// phone holds, the next worlds are fetched quietly and stored for offline
/// play. A player who never goes online simply has the 150, and the hub tells
/// them more arrive when they connect.
///
/// Worlds are the SAME for every player (stars, sync and the leaderboards are
/// keyed on level id), so they belong to the install, not to an account:
/// signing out or switching account never touches them.
library;

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../engine/difficulty.dart' show kMaxColors;
import '../engine/level_curve.dart' show kCampaignLength, kLevelSetVersion;
import '../engine/level_set.dart';
import '../services/api/api_result.dart';
import '../services/api/campaign_api.dart';
import 'progress_repository.dart';
import 'providers.dart';

/// Five balls a tube. The board, geometry and solver are all capacity-generic
/// already; what this build adds is accepting such a world, and a tip the
/// first time one is played.
const String kTallTubes = 'tall_tubes';

/// Mechanics beyond the classic rules that THIS build can play. The server
/// never sends a world needing anything missing from this list; it says
/// "update required" instead. Add to it only in the same change that teaches
/// the board to play the new mechanic.
const List<String> kSupportedMechanics = <String>[kTallTubes];

/// The tube capacity a world's boards must have, from what it declares. A
/// classic world carrying a five-ball tube is a server fault, not a surprise
/// to draw.
int capacityFor(List<String> mechanics) =>
    mechanics.contains(kTallTubes) ? 5 : 4;

/// The most tubes a board may have. The bundled campaign peaks at twelve, and
/// that is what `BoardGeometry` has been proven against on a phone.
const int kMaxTubes = 12;

/// Fetch when the player is within this many levels of the end of what the
/// phone holds: one world. The server keeps three worlds published ahead of
/// the furthest player, so there is always something to fetch.
const int kPrefetchWithin = 50;

/// After a fetch that failed or brought nothing, how long before trying again
/// on its own. A retry is cheap; a retry on every single pour is not polite.
const Duration kWorldsRetryAfter = Duration(minutes: 10);

/// True when the phone should go looking for more levels.
///
/// Always, in a dev build with every level unlocked: that build exists to
/// verify the late campaign without playing to it, and the worlds past 150
/// are the late campaign.
bool shouldFetchWorlds({
  required int furthestUnlocked,
  required int heldThrough,
}) => kDevUnlockAll || heldThrough - furthestUnlocked < kPrefetchWithin;

/// Why [world] cannot be added after level [heldThrough], or null if it can.
///
/// Every world is checked before a single level is stored, because a bad one
/// is not a cosmetic problem: a board with an eleventh color has no palette
/// entry, a color with the wrong ball count can never be sorted, and a gap in
/// the ids strands the player at the level before it.
String? worldProblem(CampaignWorld world, {required int heldThrough}) {
  if (world.levelSetVersion != kLevelSetVersion) {
    return 'content version ${world.levelSetVersion}, this build plays $kLevelSetVersion';
  }
  if (world.firstLevel != heldThrough + 1) {
    return 'starts at ${world.firstLevel}, expected ${heldThrough + 1}';
  }
  if (world.lastLevel < world.firstLevel ||
      world.levels.length != world.lastLevel - world.firstLevel + 1) {
    return 'claims ${world.firstLevel}-${world.lastLevel} but has '
        '${world.levels.length} levels';
  }
  for (final mechanic in world.mechanics) {
    if (!kSupportedMechanics.contains(mechanic)) return 'needs "$mechanic"';
  }

  for (var i = 0; i < world.levels.length; i++) {
    final campaign = world.levels[i];
    final level = campaign.level;
    final board = level.board;
    final id = world.firstLevel + i;

    if (level.id != id) return 'level ${level.id} where $id belongs';
    if (campaign.bandIndex != world.index) {
      return 'level $id is in the wrong world';
    }
    if (level.minMoves <= 0) return 'level $id has no par';
    if (board.capacity != capacityFor(world.mechanics)) {
      return 'level $id has tubes of ${board.capacity}, its world declares '
          '${capacityFor(world.mechanics)}';
    }
    if (board.tubeCount > kMaxTubes) {
      return 'level $id has ${board.tubeCount} tubes';
    }

    final counts = <int, int>{};
    for (final tube in board.tubes) {
      for (final color in tube.balls) {
        counts[color] = (counts[color] ?? 0) + 1;
      }
    }
    if (counts.length > kMaxColors) {
      return 'level $id has ${counts.length} colors';
    }
    for (final entry in counts.entries) {
      if (entry.key < 0 || entry.key >= kMaxColors) {
        return 'level $id uses color ${entry.key}';
      }
      if (entry.value != board.capacity) {
        return 'level $id has ${entry.value} balls of color ${entry.key}';
      }
    }
  }
  return null;
}

enum WorldsFetch { idle, fetching, failed }

@immutable
class CampaignWorldsState {
  /// False until the stored worlds have been read.
  final bool loaded;

  /// Downloaded worlds, contiguous from level 151.
  final List<CampaignWorld> worlds;

  /// The server has more, but not for this build.
  final bool updateRequired;

  final WorldsFetch fetch;

  const CampaignWorldsState({
    this.loaded = false,
    this.worlds = const [],
    this.updateRequired = false,
    this.fetch = WorldsFetch.idle,
  });

  /// The last level this phone can play.
  int get heldThrough =>
      worlds.isEmpty ? kCampaignLength : worlds.last.lastLevel;

  CampaignWorldsState copyWith({
    bool? loaded,
    List<CampaignWorld>? worlds,
    bool? updateRequired,
    WorldsFetch? fetch,
  }) => CampaignWorldsState(
    loaded: loaded ?? this.loaded,
    worlds: worlds ?? this.worlds,
    updateRequired: updateRequired ?? this.updateRequired,
    fetch: fetch ?? this.fetch,
  );
}

class CampaignWorldsController extends Notifier<CampaignWorldsState> {
  static const _key = 'pourfect.campaign.worlds.v1';

  late final Future<void> _restored;
  Future<void>? _inFlight;
  DateTime? _quietUntil;

  @override
  CampaignWorldsState build() {
    _restored = _restore();
    // Every cleared level moves the player toward the end of what the phone
    // holds, so every change is a chance to look. The check is two integers;
    // the request only happens within a world of the end.
    ref.listen(progressProvider, (_, _) => maybeFetch());
    return const CampaignWorldsState();
  }

  /// Completes once the stored worlds are in [state].
  Future<void> get ready => _restored;

  /// Fetches more worlds if the player is near the end of what is held.
  ///
  /// Safe to call from anywhere and as often as liked: concurrent calls
  /// collapse into one, and outside the last world it returns at once.
  /// [force] skips the quiet period after a failure — for an app resume, when
  /// the network may well have come back.
  Future<void> maybeFetch({bool force = false}) =>
      _inFlight ??= _fetch(force).whenComplete(() => _inFlight = null);

  Future<void> _fetch(bool force) async {
    await _restored;
    final progress = ref.read(progressProvider.notifier);
    await progress.restored;

    // Several rounds, so a new phone restoring a player at level 290 catches
    // all the way up rather than one response's worth at a time.
    for (var round = 0; round < 6; round++) {
      final held = state.heldThrough;
      if (!shouldFetchWorlds(
        furthestUnlocked: progress.furthestUnlocked,
        heldThrough: held,
      )) {
        return;
      }

      final quiet = _quietUntil;
      if (!force && quiet != null && DateTime.now().isBefore(quiet)) return;
      if (!ref.read(apiClientProvider).isConfigured) return;

      state = state.copyWith(fetch: WorldsFetch.fetching);
      final result = await ref
          .read(campaignApiProvider)
          .worlds(after: held, mechanics: kSupportedMechanics);

      // The phone may have gained worlds from elsewhere while this was out
      // (it cannot today, but a stale answer must never be appended twice).
      if (state.heldThrough != held) continue;

      switch (result) {
        case ApiOk(:final value):
          final accepted = <CampaignWorld>[];
          var through = held;
          for (final world in value.worlds) {
            final problem = worldProblem(world, heldThrough: through);
            if (problem != null) {
              // Stops at the first bad world rather than skipping it: the one
              // after would start past a hole.
              debugPrint('[worlds] refused world ${world.index}: $problem');
              break;
            }
            accepted.add(world);
            through = world.lastLevel;
          }

          state = state.copyWith(
            worlds: [...state.worlds, ...accepted],
            updateRequired: accepted.isEmpty && value.updateRequired,
            fetch: WorldsFetch.idle,
          );

          if (accepted.isEmpty) {
            _quietUntil = DateTime.now().add(kWorldsRetryAfter);
            return;
          }
          _quietUntil = null;
          debugPrint(
            '[worlds] downloaded ${accepted.length} world(s), now through '
            '${state.heldThrough}',
          );
          await _persist();

        case ApiFailure(:final kind):
          debugPrint('[worlds] fetch failed: $kind');
          _quietUntil = DateTime.now().add(kWorldsRetryAfter);
          state = state.copyWith(fetch: WorldsFetch.failed);
          return;
      }
    }
  }

  Future<void> _restore() async {
    var worlds = <CampaignWorld>[];
    var updateRequired = false;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw != null) {
        final json = jsonDecode(raw) as Map<String, Object?>;
        updateRequired = json['update_required'] as bool? ?? false;
        var through = kCampaignLength;
        for (final entry in json['worlds'] as List<Object?>) {
          final world = _decode((entry as Map).cast<String, Object?>());
          // Re-checked on the way in: a build that plays fewer mechanics than
          // the one that stored these (a downgrade) must not load them.
          if (worldProblem(world, heldThrough: through) != null) break;
          worlds.add(world);
          through = world.lastLevel;
        }
      }
    } catch (error) {
      // Unreadable storage costs a re-download, nothing else.
      debugPrint('[worlds] could not read stored worlds: $error');
      worlds = [];
    }

    state = state.copyWith(
      loaded: true,
      worlds: worlds,
      updateRequired: updateRequired,
    );
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _key,
        jsonEncode({
          'update_required': state.updateRequired,
          'worlds': [for (final w in state.worlds) _encode(w)],
        }),
      );
    } catch (error) {
      debugPrint('[worlds] could not store worlds: $error');
    }
  }

  /// A world's levels go through the same binary codec as the bundled
  /// campaign: about 60 bytes a level, against ~200 as JSON. Preferences are
  /// read whole at every launch, so the difference is worth having.
  static Map<String, Object?> _encode(CampaignWorld world) => {
    'index': world.index,
    'name': world.name,
    'first': world.firstLevel,
    'last': world.lastLevel,
    'version': world.levelSetVersion,
    'mechanics': world.mechanics,
    'levels': base64Encode(
      LevelSetCodec.encode(
        LevelSet(levelSetVersion: world.levelSetVersion, levels: world.levels),
      ),
    ),
  };

  static CampaignWorld _decode(Map<String, Object?> json) {
    final set = LevelSetCodec.decode(base64Decode(json['levels'] as String));
    return CampaignWorld(
      index: json['index'] as int,
      name: json['name'] as String,
      firstLevel: json['first'] as int,
      lastLevel: json['last'] as int,
      levelSetVersion: json['version'] as int,
      mechanics: [for (final m in json['mechanics'] as List) '$m'],
      levels: set.levels,
    );
  }
}

final campaignApiProvider = Provider<CampaignApi>(
  (ref) => CampaignApi(ref.read(apiClientProvider)),
);

final campaignWorldsProvider =
    NotifierProvider<CampaignWorldsController, CampaignWorldsState>(
      CampaignWorldsController.new,
    );

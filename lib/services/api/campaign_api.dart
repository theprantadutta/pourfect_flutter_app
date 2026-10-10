/// The campaign past the 150 bundled levels, over the wire.
///
/// The server generates worlds of 50 levels and every player gets the same
/// ones, because stars, sync and the leaderboards are keyed on level id. The
/// app downloads them in the background when a player nears the end of what
/// it holds, and keeps them for offline play.
///
/// This file only parses. Deciding whether a world is fit to play (contiguous
/// ids, every color exactly filling its tubes, nothing past the color ceiling)
/// is game logic and lives in `state/campaign_worlds.dart`.
library;

import '../../engine/board.dart';
import '../../engine/level.dart';
import '../../engine/level_set.dart';
import 'api_client.dart';
import 'api_result.dart';

/// One downloaded world: its place in the campaign and its levels.
class CampaignWorld {
  /// Campaign band index. 0-3 are bundled, so the first world is 4.
  final int index;
  final String name;
  final int firstLevel;
  final int lastLevel;
  final int levelSetVersion;

  /// Mechanics beyond the classic rules this world uses.
  final List<String> mechanics;

  final List<CampaignLevel> levels;

  const CampaignWorld({
    required this.index,
    required this.name,
    required this.firstLevel,
    required this.lastLevel,
    required this.levelSetVersion,
    required this.mechanics,
    required this.levels,
  });
}

/// What the server returned.
class CampaignWorlds {
  final List<CampaignWorld> worlds;

  /// True when the next world needs a mechanic this build does not know, so
  /// more levels exist but only after an app update.
  final bool updateRequired;

  /// Last level the server has published for any app.
  final int publishedThrough;

  const CampaignWorlds({
    required this.worlds,
    required this.updateRequired,
    required this.publishedThrough,
  });
}

class CampaignApi {
  final ApiClient _client;

  const CampaignApi(this._client);

  /// Worlds after level [after], only ones this build can play.
  Future<ApiResult<CampaignWorlds>> worlds({
    required int after,
    required List<String> mechanics,
    int limit = 2,
  }) async {
    final query = [
      'after=$after',
      'limit=$limit',
      if (mechanics.isNotEmpty)
        'mechanics=${Uri.encodeQueryComponent(mechanics.join(','))}',
    ].join('&');

    final response = await _client.get('/api/v1/campaign/worlds?$query');
    return switch (response) {
      ApiOk(:final value) => parse(value),
      ApiFailure(:final kind, :final detail, :final statusCode) => ApiFailure(
        kind,
        detail: detail,
        statusCode: statusCode,
      ),
    };
  }

  /// Public for tests. Any structural problem fails the WHOLE response: a
  /// half-parsed world is worse than none, because the next one would start
  /// after a hole.
  static ApiResult<CampaignWorlds> parse(Map<String, Object?> body) {
    final rawWorlds = body['worlds'];
    if (rawWorlds is! List) return _bad('worlds missing');

    final worlds = <CampaignWorld>[];
    for (final raw in rawWorlds) {
      if (raw is! Map) return _bad('world is not an object');
      final json = raw.cast<String, Object?>();

      final index = _int(json['index']);
      final first = _int(json['first_level']);
      final last = _int(json['last_level']);
      final version = _int(json['level_set_version']);
      final name = json['name'];
      final rawLevels = json['levels'];
      final rawMechanics = json['mechanics'];
      if (index == null ||
          first == null ||
          last == null ||
          version == null ||
          name is! String ||
          rawLevels is! List ||
          rawMechanics is! List) {
        return _bad('world is missing a field');
      }

      final levels = <CampaignLevel>[];
      for (final rawLevel in rawLevels) {
        final level = _level(rawLevel, index);
        if (level == null) return _bad('level in world $index is malformed');
        levels.add(level);
      }

      worlds.add(
        CampaignWorld(
          index: index,
          name: name,
          firstLevel: first,
          lastLevel: last,
          levelSetVersion: version,
          mechanics: [for (final m in rawMechanics) '$m'],
          levels: levels,
        ),
      );
    }

    return ApiOk(
      CampaignWorlds(
        worlds: worlds,
        updateRequired: body['update_required'] as bool? ?? false,
        publishedThrough: _int(body['published_through']) ?? 0,
      ),
    );
  }

  static CampaignLevel? _level(Object? raw, int bandIndex) {
    if (raw is! Map) return null;
    final json = raw.cast<String, Object?>();

    final id = _int(json['id']);
    final capacity = _int(json['capacity']);
    final minMoves = _int(json['min_moves']);
    final tubes = json['tubes'];
    if (id == null || capacity == null || minMoves == null || tubes is! List) {
      return null;
    }

    final lists = <List<ColorId>>[];
    for (final tube in tubes) {
      if (tube is! List) return null;
      final balls = <ColorId>[];
      for (final ball in tube) {
        final color = _int(ball);
        if (color == null) return null;
        balls.add(color);
      }
      lists.add(balls);
    }

    final Board board;
    try {
      board = Board.fromLists(lists, capacity: capacity);
    } catch (_) {
      return null;
    }

    return CampaignLevel(
      level: LevelSetCodec.quantiseLevel(
        Level(
          id: id,
          board: board,
          minMoves: minMoves,
          difficultyScore: (json['difficulty_score'] as num?)?.toDouble() ?? 0,
          forcedMoveRatio: (json['forced_move_ratio'] as num?)?.toDouble() ?? 0,
          // The server's flag, not this phone's rule: it can see whole blocks
          // of ten this phone has not downloaded yet.
          isHard: json['is_hard'] as bool? ?? false,
        ),
      ),
      bandIndex: bandIndex,
      isBreather: json['is_breather'] as bool? ?? false,
    );
  }

  static int? _int(Object? value) => value is num ? value.toInt() : null;

  static ApiFailure<CampaignWorlds> _bad(String detail) =>
      ApiFailure(ApiFailureKind.server, detail: 'campaign worlds: $detail');
}

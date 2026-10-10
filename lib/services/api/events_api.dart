/// The weekly event on the server: seven boards, Monday to Sunday (UTC), one
/// board for everybody, ranked by total points.
library;

import 'package:flutter/foundation.dart';

import '../../engine/board.dart';
import '../../engine/level.dart';
import 'api_client.dart';
import 'api_result.dart';

@immutable
class EventBoard {
  final int slot;
  final Board board;
  final int minMoves;

  const EventBoard({
    required this.slot,
    required this.board,
    required this.minMoves,
  });

  /// Played like the daily: id 0 and level set version 0, so it is never
  /// mistaken for a campaign level.
  Level get asLevel => Level(
    id: 0,
    board: board,
    minMoves: minMoves,
    difficultyScore: 0,
    forcedMoveRatio: 0,
  );
}

@immutable
class EventResult {
  final int slot;
  final int moves;
  final int stars;
  final int points;

  const EventResult({
    required this.slot,
    required this.moves,
    required this.stars,
    required this.points,
  });
}

@immutable
class WeeklyEventInfo {
  final String name;
  final DateTime weekStart;
  final DateTime endsAt;
  final List<EventBoard> boards;
  final Map<int, EventResult> results;
  final int totalPoints;

  /// Null when the player is not on the board (no name, or hidden).
  final int? rank;
  final int players;

  const WeeklyEventInfo({
    required this.name,
    required this.weekStart,
    required this.endsAt,
    required this.boards,
    required this.results,
    required this.totalPoints,
    required this.rank,
    required this.players,
  });

  int get cleared => results.length;

  static WeeklyEventInfo? fromJson(Map<String, Object?> body) {
    final weekStart = DateTime.tryParse(body['week_start'] as String? ?? '');
    final endsAt = DateTime.tryParse(body['ends_at'] as String? ?? '');
    if (weekStart == null || endsAt == null) return null;

    final boards = <EventBoard>[];
    for (final row in body['levels'] as List? ?? const []) {
      if (row is! Map) return null;
      final tubes = row['tubes'];
      final capacity = (row['capacity'] as num?)?.toInt();
      if (tubes is! List || capacity == null) return null;
      try {
        boards.add(
          EventBoard(
            slot: (row['slot'] as num).toInt(),
            minMoves: (row['min_moves'] as num).toInt(),
            board: Board.fromLists([
              for (final t in tubes)
                [for (final b in t as List) (b as num).toInt()],
            ], capacity: capacity),
          ),
        );
      } catch (_) {
        return null;
      }
    }

    return WeeklyEventInfo(
      name: body['name'] as String? ?? 'Weekly event',
      weekStart: DateTime.utc(weekStart.year, weekStart.month, weekStart.day),
      endsAt: endsAt.toUtc(),
      boards: boards,
      results: {
        for (final row in body['results'] as List? ?? const [])
          if (row is Map)
            (row['slot'] as num).toInt(): EventResult(
              slot: (row['slot'] as num).toInt(),
              moves: (row['moves'] as num?)?.toInt() ?? 0,
              stars: (row['stars'] as num?)?.toInt() ?? 0,
              points: (row['points'] as num?)?.toInt() ?? 0,
            ),
      },
      totalPoints: (body['total_points'] as num?)?.toInt() ?? 0,
      rank: (body['rank'] as num?)?.toInt(),
      players: (body['players'] as num?)?.toInt() ?? 0,
    );
  }
}

class EventsApi {
  final ApiClient _client;

  const EventsApi(this._client);

  Future<ApiResult<WeeklyEventInfo>> current() async =>
      _parse(await _client.get('/api/v1/events/current'));

  Future<ApiResult<WeeklyEventInfo>> submit({
    required DateTime weekStart,
    required int slot,
    required int movesUsed,
    required int durationSeconds,
  }) async => _parse(
    await _client.post('/api/v1/events/submit', {
      'week_start':
          '${weekStart.year.toString().padLeft(4, '0')}-'
          '${weekStart.month.toString().padLeft(2, '0')}-'
          '${weekStart.day.toString().padLeft(2, '0')}',
      'slot': slot,
      'moves_used': movesUsed,
      'duration_seconds': durationSeconds,
    }),
  );

  static ApiResult<WeeklyEventInfo> _parse(
    ApiResult<Map<String, Object?>> response,
  ) => switch (response) {
    ApiOk(:final value) => switch (WeeklyEventInfo.fromJson(value)) {
      final info? => ApiOk(info),
      null => const ApiFailure(
        ApiFailureKind.server,
        detail: 'event was malformed',
      ),
    },
    ApiFailure(:final kind, :final detail, :final statusCode) => ApiFailure(
      kind,
      detail: detail,
      statusCode: statusCode,
    ),
  };
}

/// The daily challenge, over the wire.
///
/// This one really does need the network. The campaign is bundled in the APK
/// and playable forever; the daily board is generated on the server from a
/// seed that never ships to a device, and deliberately so — the pool used to
/// be baked into this repo, which is public, and generation is deterministic,
/// so the artifact plus its seed published every board for the next year
/// together with its proven optimal solution. The anti-cheat floor only
/// rejects scores BELOW the optimum; it cannot tell an honest one from a
/// looked-up one.
///
/// So "no network, no daily" is correct rather than a limitation to work
/// around. What must never happen is that the daily's absence costs the player
/// anything else, which is why nothing here is on the path to a campaign level.
library;

import 'package:flutter/foundation.dart';

import '../../engine/board.dart';
import '../../engine/level.dart';
import 'api_client.dart';
import 'api_result.dart';

/// Today's board, and what this player has already done with it.
class DailyChallenge {
  final DateTime date;
  final Board board;

  /// The solver's proven optimum, sent so the phone can show stars the instant
  /// the board is solved. The server recomputes it on submission and never
  /// trusts a client-sent star count — this is a convenience for the UI, not
  /// the scoring authority.
  final int minMoves;

  final int colorCount;
  final int emptyTubeCount;
  final DailyAttempt? yourAttempt;

  const DailyChallenge({
    required this.date,
    required this.board,
    required this.minMoves,
    required this.colorCount,
    required this.emptyTubeCount,
    required this.yourAttempt,
  });

  /// The board as the game engine wants it.
  ///
  /// Level zero, because it is not part of the campaign and must never be
  /// mistaken for a level id in progress or analytics.
  Level get asLevel => Level(
    id: 0,
    board: board,
    minMoves: minMoves,
    difficultyScore: 0,
    forcedMoveRatio: 0,
  );

  bool get isPlayed => yourAttempt != null;
}

class DailyAttempt {
  final int moves;
  final int stars;
  final int durationSeconds;
  final DateTime completedAt;

  const DailyAttempt({
    required this.moves,
    required this.stars,
    required this.durationSeconds,
    required this.completedAt,
  });
}

/// What the server made of a submission.
class DailyResult {
  final int stars;
  final int moves;
  final bool isPersonalBest;
  final int dailyStreak;

  /// Null when the player has not chosen a display name. Setting one is the
  /// leaderboard opt-in, so an unnamed player genuinely has no position —
  /// reporting a number against a board they cannot appear on would be a lie
  /// the leaderboard contradicts a moment later.
  final int? rank;

  final int totalPlayers;

  /// The longest streak ever, after this submission.
  final int bestDailyStreak;

  /// Streak freezes held after this submission.
  final int streakFreezes;

  const DailyResult({
    required this.stars,
    required this.moves,
    required this.isPersonalBest,
    required this.dailyStreak,
    required this.rank,
    required this.totalPlayers,
    this.bestDailyStreak = 0,
    this.streakFreezes = 0,
  });
}

/// The daily streak, as the server keeps it, and a calendar of days.
///
/// The server is the only authority here: freezes are spent and given by days
/// passing, which this device cannot see happen.
@immutable
class StreakInfo {
  /// Played days in the unbroken run. 0 once broken.
  final int current;
  final int best;
  final int freezes;
  final int maxFreezes;

  /// Whether a rewarded video would add a freeze right now.
  final bool canEarnFreeze;

  /// The Monday the next free freeze arrives.
  final DateTime nextWeeklyFreezeOn;

  /// The server's day, which is the daily's day (UTC).
  final DateTime today;

  /// UTC days with a completed daily, within the range asked for.
  final Set<DateTime> played;

  /// UTC days a freeze covered, within the range asked for.
  final Set<DateTime> frozen;

  const StreakInfo({
    required this.current,
    required this.best,
    required this.freezes,
    required this.maxFreezes,
    required this.canEarnFreeze,
    required this.nextWeeklyFreezeOn,
    required this.today,
    required this.played,
    required this.frozen,
  });

  static StreakInfo? fromJson(Map<String, Object?> body) {
    final today = _day(body['today']);
    final next = _day(body['next_weekly_freeze_on']);
    if (today == null || next == null) return null;
    Set<DateTime> days(Object? list) => {
      if (list is List)
        for (final d in list) ?_day(d),
    };
    return StreakInfo(
      current: (body['current'] as num?)?.toInt() ?? 0,
      best: (body['best'] as num?)?.toInt() ?? 0,
      freezes: (body['freezes'] as num?)?.toInt() ?? 0,
      maxFreezes: (body['max_freezes'] as num?)?.toInt() ?? 2,
      canEarnFreeze: body['can_earn_freeze'] as bool? ?? false,
      nextWeeklyFreezeOn: next,
      today: today,
      played: days(body['played']),
      frozen: days(body['frozen']),
    );
  }

  static DateTime? _day(Object? value) {
    final parsed = DateTime.tryParse(value is String ? value : '');
    return parsed == null
        ? null
        : DateTime.utc(parsed.year, parsed.month, parsed.day);
  }
}

class DailyApi {
  final ApiClient _client;

  const DailyApi(this._client);

  Future<ApiResult<DailyChallenge>> today() async {
    final response = await _client.get('/api/v1/daily');
    return switch (response) {
      ApiOk(:final value) => _parse(value),
      ApiFailure(:final kind, :final detail, :final statusCode) => ApiFailure(
        kind,
        detail: detail,
        statusCode: statusCode,
      ),
    };
  }

  Future<ApiResult<DailyResult>> submit({
    required DateTime date,
    required int movesUsed,
    required int durationSeconds,
  }) async {
    final response = await _client.post('/api/v1/daily/submit', {
      'date': _dateOnly(date),
      'moves_used': movesUsed,
      'duration_seconds': durationSeconds,
    });

    return switch (response) {
      ApiOk(:final value) => ApiOk(
        DailyResult(
          stars: (value['stars'] as num?)?.toInt() ?? 0,
          moves: (value['moves'] as num?)?.toInt() ?? movesUsed,
          isPersonalBest: value['is_personal_best'] as bool? ?? false,
          dailyStreak: (value['daily_streak'] as num?)?.toInt() ?? 0,
          rank: (value['rank'] as num?)?.toInt(),
          totalPlayers: (value['total_players'] as num?)?.toInt() ?? 0,
          bestDailyStreak: (value['best_daily_streak'] as num?)?.toInt() ?? 0,
          streakFreezes: (value['streak_freezes'] as num?)?.toInt() ?? 0,
        ),
      ),
      ApiFailure(:final kind, :final detail, :final statusCode) => ApiFailure(
        kind,
        detail: detail,
        statusCode: statusCode,
      ),
    };
  }

  /// The streak, settled to today, with the calendar from [from] to [to]
  /// (UTC days, at most 62). Defaults to the last six weeks.
  Future<ApiResult<StreakInfo>> streak({DateTime? from, DateTime? to}) async {
    final query = [
      if (from != null) 'from=${_dateOnly(from)}',
      if (to != null) 'to=${_dateOnly(to)}',
    ].join('&');
    final response = await _client.get(
      '/api/v1/daily/streak${query.isEmpty ? '' : '?$query'}',
    );
    return _streakResult(response);
  }

  /// A rewarded video finished: one more freeze, if there is room.
  Future<ApiResult<StreakInfo>> earnFreeze() async =>
      _streakResult(await _client.post('/api/v1/daily/streak/freeze', {}));

  static ApiResult<StreakInfo> _streakResult(
    ApiResult<Map<String, Object?>> response,
  ) => switch (response) {
    ApiOk(:final value) => switch (StreakInfo.fromJson(value)) {
      final info? => ApiOk(info),
      null => const ApiFailure(
        ApiFailureKind.server,
        detail: 'streak was malformed',
      ),
    },
    ApiFailure(:final kind, :final detail, :final statusCode) => ApiFailure(
      kind,
      detail: detail,
      statusCode: statusCode,
    ),
  };

  /// `yyyy-mm-dd`, which is what a `DateOnly` deserializes from.
  static String _dateOnly(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  static ApiResult<DailyChallenge> _parse(Map<String, Object?> body) {
    final date = DateTime.tryParse(body['date'] as String? ?? '');
    final capacity = (body['capacity'] as num?)?.toInt();
    final tubes = body['tubes'];

    if (date == null || capacity == null || tubes is! List) {
      return const ApiFailure(
        ApiFailureKind.server,
        detail: 'daily challenge was missing a board',
      );
    }

    final lists = <List<int>>[];
    for (final tube in tubes) {
      if (tube is! List) {
        return const ApiFailure(
          ApiFailureKind.server,
          detail: 'daily challenge board was malformed',
        );
      }
      lists.add([for (final ball in tube) (ball as num).toInt()]);
    }

    final Board board;
    try {
      board = Board.fromLists(lists, capacity: capacity);
    } catch (error) {
      // A board the engine refuses is a server-side content problem. Reporting
      // it as a failure keeps the daily absent rather than crashing a screen
      // over it.
      return ApiFailure(
        ApiFailureKind.server,
        detail: 'daily challenge board was invalid: $error',
      );
    }

    return ApiOk(
      DailyChallenge(
        date: date,
        board: board,
        minMoves: (body['min_moves'] as num?)?.toInt() ?? 0,
        colorCount: (body['color_count'] as num?)?.toInt() ?? 0,
        emptyTubeCount: (body['empty_tube_count'] as num?)?.toInt() ?? 0,
        yourAttempt: _attempt(body['your_attempt']),
      ),
    );
  }

  static DailyAttempt? _attempt(Object? raw) {
    if (raw is! Map) return null;
    final json = raw.cast<String, Object?>();

    return DailyAttempt(
      moves: (json['moves'] as num?)?.toInt() ?? 0,
      stars: (json['stars'] as num?)?.toInt() ?? 0,
      durationSeconds: (json['duration_seconds'] as num?)?.toInt() ?? 0,
      completedAt:
          DateTime.tryParse(json['completed_at'] as String? ?? '') ??
          DateTime.now().toUtc(),
    );
  }
}

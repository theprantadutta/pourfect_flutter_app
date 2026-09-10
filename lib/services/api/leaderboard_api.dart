/// Leaderboards, and the name that puts somebody on one.
///
/// SETTING A DISPLAY NAME IS THE OPT-IN. An account with no name appears on no
/// board, and nothing anywhere invents one — publishing a stranger as
/// "Player 4821" puts somebody on a public list they never agreed to join.
/// That rule lives on the server; this side must never present a board as
/// something a player is already on when they are not.
library;

import 'api_client.dart';
import 'api_result.dart';

class LeaderboardRow {
  final int rank;
  final String displayName;

  /// Stars for the campaign board, moves for the daily.
  final int value;

  /// Levels cleared, or the daily's duration tie-break. Null when there is no
  /// second axis.
  final int? tieBreak;

  final bool isYou;

  const LeaderboardRow({
    required this.rank,
    required this.displayName,
    required this.value,
    required this.tieBreak,
    required this.isYou,
  });
}

class Leaderboard {
  final List<LeaderboardRow> rows;

  /// The caller's own row, returned even when they are nowhere near the top.
  ///
  /// A board that shows only the top fifty tells somebody nothing about
  /// themselves, which is the one thing they came to see. Null when they have
  /// no name and are therefore on no board.
  final LeaderboardRow? you;

  final int totalPlayers;

  const Leaderboard({
    required this.rows,
    required this.you,
    required this.totalPlayers,
  });

  bool get isEmpty => rows.isEmpty;
}

class LeaderboardApi {
  final ApiClient _client;

  const LeaderboardApi(this._client);

  Future<ApiResult<Leaderboard>> daily({int limit = 50}) =>
      _fetch('/api/v1/leaderboard/daily', limit);

  Future<ApiResult<Leaderboard>> campaign({int limit = 50}) =>
      _fetch('/api/v1/leaderboard/campaign', limit);

  Future<ApiResult<Leaderboard>> _fetch(String path, int limit) async {
    final response = await _client.get(path, query: {'limit': '$limit'});

    return switch (response) {
      ApiOk(:final value) => ApiOk(
        Leaderboard(
          rows: _rows(value['rows']),
          you: _row(value['you']),
          totalPlayers: (value['total_players'] as num?)?.toInt() ?? 0,
        ),
      ),
      ApiFailure(:final kind, :final detail, :final statusCode) => ApiFailure(
        kind,
        detail: detail,
        statusCode: statusCode,
      ),
    };
  }

  static List<LeaderboardRow> _rows(Object? raw) {
    if (raw is! List) return const [];
    final rows = <LeaderboardRow>[];
    for (final entry in raw) {
      final row = _row(entry);
      if (row != null) rows.add(row);
    }
    return rows;
  }

  static LeaderboardRow? _row(Object? raw) {
    if (raw is! Map) return null;
    final json = raw.cast<String, Object?>();
    final name = json['display_name'];
    if (name is! String) return null;

    return LeaderboardRow(
      rank: (json['rank'] as num?)?.toInt() ?? 0,
      displayName: name,
      value: (json['value'] as num?)?.toInt() ?? 0,
      tieBreak: (json['tie_break'] as num?)?.toInt(),
      isYou: json['is_you'] as bool? ?? false,
    );
  }
}

/// Constraints the server enforces, mirrored so the UI can say no first.
///
/// Duplicated deliberately: the server is the authority and validates
/// regardless, but a player who types a 40-character name deserves to be told
/// before a round trip rather than after one.
const int kMinDisplayName = 2;
const int kMaxDisplayName = 24;
final RegExp kDisplayNamePattern = RegExp(r'^[A-Za-z0-9 _-]+$');

/// Why a name was refused, or null if it is fine.
String? displayNameProblem(String name) {
  final trimmed = name.trim();
  if (trimmed.length < kMinDisplayName) {
    return 'At least $kMinDisplayName characters.';
  }
  if (trimmed.length > kMaxDisplayName) {
    return 'At most $kMaxDisplayName characters.';
  }
  if (!kDisplayNamePattern.hasMatch(trimmed)) {
    return 'Letters, numbers, spaces, hyphens and underscores only.';
  }
  return null;
}

class UsersApi {
  final ApiClient _client;

  const UsersApi(this._client);

  /// Sets the leaderboard name. THIS IS THE OPT-IN.
  Future<ApiResult<String>> setDisplayName(String name) async {
    final response = await _client.put('/api/v1/users/display-name', {
      'display_name': name.trim(),
    });

    return switch (response) {
      ApiOk(:final value) => ApiOk(value['display_name'] as String? ?? name),
      ApiFailure(:final kind, :final detail, :final statusCode) => ApiFailure(
        kind,
        detail: detail,
        statusCode: statusCode,
      ),
    };
  }

  /// Deletes the account and everything hanging off it.
  ///
  /// Required by Play: an app that lets people create accounts must offer
  /// in-app deletion, not only a web form. Cascades do the work server-side, so
  /// a table added later cannot be forgotten here.
  ///
  /// The SERVER goes first and the Firebase identity second — see
  /// AccountController for why that order is the safe one.
  Future<ApiResult<void>> deleteAccount() async {
    final response = await _client.delete('/api/v1/users/me');

    return switch (response) {
      ApiOk() => const ApiOk(null),
      ApiFailure(:final kind, :final detail, :final statusCode) => ApiFailure(
        kind,
        detail: detail,
        statusCode: statusCode,
      ),
    };
  }
}

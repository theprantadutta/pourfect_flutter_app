/// Campaign progress, over the wire.
///
/// Translation only: this turns `LevelProgress` into the payload the server
/// wants and its answer back into `LevelProgress`. It decides nothing about
/// WHEN to sync or what to do with a failure — that is `SyncController`, which
/// is where the retry and merge rules belong and where they can be tested
/// without a socket.
///
/// Note what is NOT sent: stars, and the score. The server recomputes both
/// from the submitted move count and clock against the solver's proven
/// optimum, so a modified client can misreport its inputs and be caught by the
/// anti-cheat floor, but cannot simply assert that it earned three stars.
/// Sending them would be sending numbers the server is obliged to ignore.
library;

import '../../state/progress_repository.dart';
import 'api_client.dart';
import 'api_result.dart';

/// What the server made of a batch.
class SyncOutcome {
  /// Items it took. `accepted + rejected` always equals what was sent.
  final int accepted;

  /// Items it refused — an unknown level, or a move count below the proven
  /// optimum. Worth logging: a client silently having submissions dropped is
  /// the kind of thing that runs for months unnoticed.
  final int rejected;

  /// Stored rows that actually moved. Zero for an identical resubmission.
  final int changed;

  /// The server's merged view of every level, not just the ones sent.
  final List<LevelProgress> progress;

  const SyncOutcome({
    required this.accepted,
    required this.rejected,
    required this.changed,
    required this.progress,
  });
}

class ProgressApi {
  final ApiClient _client;

  const ProgressApi(this._client);

  /// Pushes results and returns the merged server view.
  Future<ApiResult<SyncOutcome>> sync(Iterable<LevelProgress> rows) async {
    final items = [for (final row in rows) _payload(row)];
    final response = await _client.post('/api/v1/progress/sync', {
      'items': items,
    });

    return switch (response) {
      ApiOk(:final value) => ApiOk(_outcome(value)),
      ApiFailure(:final kind, :final detail, :final statusCode) => ApiFailure(
        kind,
        detail: detail,
        statusCode: statusCode,
      ),
    };
  }

  /// Pulls everything the server holds. For a fresh install.
  Future<ApiResult<List<LevelProgress>>> snapshot() async {
    final response = await _client.get('/api/v1/progress');

    return switch (response) {
      ApiOk(:final value) => ApiOk(_rows(value['progress'])),
      ApiFailure(:final kind, :final detail, :final statusCode) => ApiFailure(
        kind,
        detail: detail,
        statusCode: statusCode,
      ),
    };
  }

  static Map<String, Object?> _payload(LevelProgress row) => {
    'level_id': row.levelId,
    'level_set_version': row.levelSetVersion,
    'moves_used': row.bestMoves,
    // The clock is optional on the wire and 0 means "no time recorded", which
    // is every row cleared before the clock shipped. The server treats that as
    // unknown rather than as an instant solve.
    'elapsed_seconds': row.bestTimeSeconds,
    'completed_at': (row.firstClearedAt ?? DateTime.now().toUtc())
        .toIso8601String(),
  };

  static SyncOutcome _outcome(Map<String, Object?> body) => SyncOutcome(
    accepted: (body['accepted'] as num?)?.toInt() ?? 0,
    rejected: (body['rejected'] as num?)?.toInt() ?? 0,
    changed: (body['changed'] as num?)?.toInt() ?? 0,
    progress: _rows(body['progress']),
  );

  static List<LevelProgress> _rows(Object? raw) {
    if (raw is! List) return const [];

    final rows = <LevelProgress>[];
    for (final entry in raw) {
      if (entry is! Map) continue;
      final row = _row(entry.cast<String, Object?>());
      if (row != null) rows.add(row);
    }
    return rows;
  }

  /// One row, or null if it is not one we can use.
  ///
  /// Skipped rather than thrown on. A server that grows a field, or one row
  /// that arrives malformed, must not cost the player the other 149.
  static LevelProgress? _row(Map<String, Object?> json) {
    final levelId = (json['level_id'] as num?)?.toInt();
    final version = (json['level_set_version'] as num?)?.toInt();
    if (levelId == null || version == null) return null;

    final completedAt = DateTime.tryParse(
      json['completed_at'] as String? ?? '',
    );

    return LevelProgress(
      levelId: levelId,
      levelSetVersion: version,
      stars: (json['stars'] as num?)?.toInt() ?? 0,
      bestMoves: (json['best_moves'] as num?)?.toInt() ?? 0,
      bestTimeSeconds: (json['best_time_seconds'] as num?)?.toInt() ?? 0,
      bestPoints: (json['best_points'] as num?)?.toInt() ?? 0,
      firstClearedAtMillis: completedAt?.toUtc().millisecondsSinceEpoch ?? 0,
    );
  }
}

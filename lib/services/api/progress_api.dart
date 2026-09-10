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

  /// The reset this account is currently on.
  ///
  /// Higher than ours means somebody reset the account from another device
  /// while this one was away, and everything held here predates it.
  final int resetGeneration;

  const SyncOutcome({
    required this.accepted,
    required this.rejected,
    required this.changed,
    required this.progress,
    this.resetGeneration = 0,
  });
}

class ProgressApi {
  final ApiClient _client;

  const ProgressApi(this._client);

  /// Pushes results and returns the merged server view.
  Future<ApiResult<SyncOutcome>> sync(
    Iterable<LevelProgress> rows, {
    int resetGeneration = 0,
  }) async {
    final items = [for (final row in rows) _payload(row)];
    final response = await _client.post('/api/v1/progress/sync', {
      'items': items,
      // Which reset these rows were recorded under. The server refuses rows
      // from before its own latest reset, so a device that was offline across
      // one cannot upload the progress that reset erased.
      'reset_generation': resetGeneration,
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

  /// Erases this account's campaign progress on the server.
  ///
  /// The other half of Reset progress. Without it the reset was local only and
  /// the next sync merged every star straight back — the confirmation said
  /// "erase every star and start from level 1" and the app could not do it.
  Future<ApiResult<int>> reset() async {
    final response = await _client.post('/api/v1/progress/reset', const {});

    return switch (response) {
      // The new generation, which every later upload is measured against.
      ApiOk(:final value) => ApiOk(
        (value['reset_generation'] as num?)?.toInt() ?? 0,
      ),
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

  /// One row as an attempt that actually happened.
  ///
  /// A submission is a MOVE COUNT AND A CLOCK FROM THE SAME RUN, because the
  /// server scores the pair. Sending the independent bests instead invents a
  /// run nobody played: a level cleared in 5 moves over 110 seconds and again
  /// in 10 moves over 20 has a best-moves of 5 and a best-time of 20, and that
  /// pair scored 625 against two real attempts worth 250 and 313. Re-syncing
  /// it doubled the stored score with nobody at the phone.
  ///
  /// So the scoring attempt is sent when we have one. Where we do not — every
  /// row written before it was recorded — the move count goes up with an
  /// UNKNOWN clock rather than a borrowed one. Stars come from moves and are
  /// unaffected; a score we cannot evidence is simply not claimed, and the
  /// server keeps whatever it already had.
  static Map<String, Object?> _payload(LevelProgress row) {
    final hasScoringAttempt = row.bestPointsMoves > 0;

    return {
      'level_id': row.levelId,
      'level_set_version': row.levelSetVersion,
      'moves_used': hasScoringAttempt ? row.bestPointsMoves : row.bestMoves,
      // Zero means "no time recorded". The server treats it as unknown rather
      // than as an instant solve.
      'elapsed_seconds': hasScoringAttempt ? row.bestPointsSeconds : 0,
      'completed_at': (row.firstClearedAt ?? DateTime.now().toUtc())
          .toIso8601String(),
      // Sent so another device can merge the score against the attempt that
      // earned it rather than against its own bests.
      'best_moves': row.bestMoves,
      'best_time_seconds': row.bestTimeSeconds,
    };
  }

  static SyncOutcome _outcome(Map<String, Object?> body) => SyncOutcome(
    accepted: (body['accepted'] as num?)?.toInt() ?? 0,
    rejected: (body['rejected'] as num?)?.toInt() ?? 0,
    changed: (body['changed'] as num?)?.toInt() ?? 0,
    progress: _rows(body['progress']),
    resetGeneration: (body['reset_generation'] as num?)?.toInt() ?? 0,
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
      bestPointsMoves: (json['best_points_moves'] as num?)?.toInt() ?? 0,
      bestPointsSeconds: (json['best_points_seconds'] as num?)?.toInt() ?? 0,
      firstClearedAtMillis: completedAt?.toUtc().millisecondsSinceEpoch ?? 0,
    );
  }
}

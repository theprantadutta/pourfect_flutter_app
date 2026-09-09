/// A day-by-day log of what the player actually did.
///
/// `LevelProgress` records the BEST of everything — best moves, fastest time,
/// highest score — which is exactly what a level-select screen needs and
/// exactly the wrong shape for "how often do I play?". A personal best carries
/// no date, and a level solved and re-solved five times leaves one row.
///
/// So this is the other half: one row per calendar day, holding what happened
/// that day. Streaks, the activity chart and honest total-time-played all fall
/// out of it, and none of them can be reconstructed from the progress map.
///
/// DAILY AGGREGATES, NOT AN EVENT LOG. A row per solve would grow without
/// bound on the device of the player who plays most, which is the last person
/// whose game should get slower. A row per day is a few dozen bytes, capped at
/// [kMaxHistoryDays], and answers every question the statistics screen asks.
library;

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Roughly two years. Long enough that "longest streak" stays meaningful,
/// short enough that the payload never becomes something worth paging.
const int kMaxHistoryDays = 730;

/// One calendar day of play, in the player's own timezone.
///
/// Local dates, deliberately. A streak is a human fact about the days somebody
/// showed up, and a player in Dhaka who plays every evening must not lose a
/// streak because UTC disagrees about when their day ended.
@immutable
class DayRecord {
  /// Local calendar day, as `yyyy-mm-dd`.
  final String date;

  /// Levels finished that day. Re-solving the same level counts again — this
  /// measures activity, not campaign progress.
  final int solved;

  /// Seconds of play banked that day, solved or not.
  final int seconds;

  /// Points earned that day, from solves.
  final int points;

  final int moves;

  const DayRecord({
    required this.date,
    this.solved = 0,
    this.seconds = 0,
    this.points = 0,
    this.moves = 0,
  });

  DayRecord plus({
    int solved = 0,
    int seconds = 0,
    int points = 0,
    int moves = 0,
  }) => DayRecord(
    date: date,
    solved: this.solved + solved,
    seconds: this.seconds + seconds,
    points: this.points + points,
    moves: this.moves + moves,
  );

  Map<String, Object?> toJson() => {
    'd': date,
    'n': solved,
    's': seconds,
    'p': points,
    'm': moves,
  };

  factory DayRecord.fromJson(Map<String, Object?> json) => DayRecord(
    date: json['d']! as String,
    solved: (json['n'] as num?)?.toInt() ?? 0,
    seconds: (json['s'] as num?)?.toInt() ?? 0,
    points: (json['p'] as num?)?.toInt() ?? 0,
    moves: (json['m'] as num?)?.toInt() ?? 0,
  );
}

/// Formats a local [DateTime] as the key this file is stored on.
String dayKey(DateTime local) =>
    '${local.year.toString().padLeft(4, '0')}-'
    '${local.month.toString().padLeft(2, '0')}-'
    '${local.day.toString().padLeft(2, '0')}';

/// Parses a [dayKey] back to local midnight. Returns null on anything else,
/// so one corrupt row is skipped rather than taking the screen down.
DateTime? parseDayKey(String key) {
  final parts = key.split('-');
  if (parts.length != 3) return null;
  final y = int.tryParse(parts[0]);
  final m = int.tryParse(parts[1]);
  final d = int.tryParse(parts[2]);
  if (y == null || m == null || d == null) return null;
  return DateTime(y, m, d);
}

class PlayHistoryRepository {
  static const _key = 'pourfect.history.v1';

  Future<Map<String, DayRecord>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return {};

    try {
      final list = jsonDecode(raw) as List;
      return {
        for (final entry in list)
          (entry as Map<String, Object?>)['d']! as String: DayRecord.fromJson(
            entry,
          ),
      };
    } catch (_) {
      // Same rule as progress: a corrupt history costs a statistics screen,
      // never the ability to play.
      return {};
    }
  }

  Future<void> save(Map<String, DayRecord> history) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode([for (final day in history.values) day.toJson()]),
    );
  }
}

class PlayHistoryController extends Notifier<Map<String, DayRecord>> {
  late final Future<void> _restored;
  Future<void> _writes = Future<void>.value();

  @override
  Map<String, DayRecord> build() {
    _restored = _restore();
    return const {};
  }

  /// Folds the stored history into whatever this session has already logged.
  ///
  /// Additive per day, for the same reason `ProgressController._restore` is a
  /// merge: this provider is built lazily, so a level can be finished before
  /// the stored snapshot lands, and assigning over the top would drop it.
  Future<void> _restore() async {
    final loaded = await ref.read(playHistoryRepositoryProvider).load();
    if (loaded.isEmpty) return;

    final merged = <String, DayRecord>{...loaded};
    for (final entry in state.entries) {
      final stored = merged[entry.key];
      merged[entry.key] = stored == null
          ? entry.value
          : stored.plus(
              solved: entry.value.solved,
              seconds: entry.value.seconds,
              points: entry.value.points,
              moves: entry.value.moves,
            );
    }

    state = _trimmed(merged);
    if (state.length != loaded.length) _enqueueSave();
  }

  static Map<String, DayRecord> _trimmed(Map<String, DayRecord> history) {
    if (history.length <= kMaxHistoryDays) return history;
    final keys = history.keys.toList()..sort();
    final keep = keys.sublist(keys.length - kMaxHistoryDays);
    return {for (final k in keep) k: history[k]!};
  }

  void _enqueueSave() {
    final snapshot = state;
    final repository = ref.read(playHistoryRepositoryProvider);
    _writes = _writes.then((_) => repository.save(snapshot)).catchError((
      Object error,
    ) {
      debugPrint('[history] save failed: $error');
    });
  }

  void _add({
    required int solved,
    required int seconds,
    required int points,
    required int moves,
    DateTime? now,
  }) {
    if (solved == 0 && seconds <= 0 && points == 0 && moves == 0) return;

    final key = dayKey(now ?? DateTime.now());
    final existing = state[key] ?? DayRecord(date: key);
    state = _trimmed({
      ...state,
      key: existing.plus(
        solved: solved,
        seconds: seconds,
        points: points,
        moves: moves,
      ),
    });
    _enqueueSave();
  }

  /// Logs a finished level.
  void recordSolve({
    required int levelId,
    required int seconds,
    required int moves,
    required int stars,
    required int points,
    DateTime? now,
  }) =>
      _add(solved: 1, seconds: seconds, points: points, moves: moves, now: now);

  /// Logs time spent on a level that was NOT finished.
  ///
  /// Without this, "time played" would only ever count successes, and the
  /// levels a player wrestled with longest — the ones worth knowing about —
  /// would contribute nothing at all.
  void recordPlaytime({required int seconds, DateTime? now}) =>
      _add(solved: 0, seconds: seconds, points: 0, moves: 0, now: now);

  // ---- aggregates ----------------------------------------------------------

  int get daysPlayed =>
      state.values.where((d) => d.seconds > 0 || d.solved > 0).length;

  int get totalSeconds => state.values.fold(0, (sum, d) => sum + d.seconds);

  int get totalSolves => state.values.fold(0, (sum, d) => sum + d.solved);

  /// Days in a row up to today, counting back.
  ///
  /// Today NOT having been played does not break the streak — yesterday is
  /// still a live anchor until midnight passes again. A streak that died the
  /// instant the clock rolled over would read as broken to somebody who simply
  /// has not opened the app yet this morning.
  int currentStreak({DateTime? now}) {
    final at = now ?? DateTime.now();
    final today = DateTime(at.year, at.month, at.day);

    var anchor = today;
    if (!_played(today)) {
      anchor = today.subtract(const Duration(days: 1));
      if (!_played(anchor)) return 0;
    }

    var streak = 0;
    var day = anchor;
    while (_played(day)) {
      streak++;
      day = day.subtract(const Duration(days: 1));
    }
    return streak;
  }

  int get longestStreak {
    final days = state.keys.map(parseDayKey).whereType<DateTime>().toList()
      ..sort();
    if (days.isEmpty) return 0;

    var longest = 1;
    var run = 1;
    for (var i = 1; i < days.length; i++) {
      final gap = days[i].difference(days[i - 1]).inDays;
      run = gap == 1 ? run + 1 : 1;
      if (run > longest) longest = run;
    }
    return longest;
  }

  bool _played(DateTime day) => state.containsKey(dayKey(day));

  /// The last [days] calendar days, oldest first, with empty days filled in.
  /// Ready to draw as a chart without the widget knowing about gaps.
  List<DayRecord> recentDays(int days, {DateTime? now}) {
    final at = now ?? DateTime.now();
    final today = DateTime(at.year, at.month, at.day);
    return [
      for (var i = days - 1; i >= 0; i--)
        _dayAt(today.subtract(Duration(days: i))),
    ];
  }

  DayRecord _dayAt(DateTime day) {
    final key = dayKey(day);
    return state[key] ?? DayRecord(date: key);
  }

  /// Erases everything. Reached from the same confirm dialog as a progress
  /// reset — leaving a two-year streak behind a wiped campaign would be a lie.
  Future<void> resetAll() async {
    await _restored;
    state = const {};
    _enqueueSave();
    await _writes;
  }

  /// Test seam.
  void debugSeed(Map<String, DayRecord> seed) => state = seed;
}

final playHistoryRepositoryProvider = Provider<PlayHistoryRepository>(
  (ref) => PlayHistoryRepository(),
);

final playHistoryProvider =
    NotifierProvider<PlayHistoryController, Map<String, DayRecord>>(
      PlayHistoryController.new,
    );

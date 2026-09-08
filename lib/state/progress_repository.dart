/// Local level progress. Works with zero network, always.
///
/// The backend is optional enrichment: it may sync this later, but a player
/// with no connection must be able to open the app, play, and have their stars
/// still there tomorrow. Nothing here awaits a server.
library;

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../engine/level.dart';

/// What a player has achieved on one level.
class LevelProgress {
  final int levelId;

  /// The level set this was earned against.
  ///
  /// THIS IS WHY THE FIELD EXISTS. Progress is keyed on level id, so without
  /// recording the version, changing a level after launch would silently
  /// repoint a saved 3-star at a board the player has never seen — and the
  /// server's anti-cheat floor would compare against the wrong `minMoves`.
  /// v1 ships no migration; the field is here because it cannot be added
  /// retroactively.
  final int levelSetVersion;

  /// Best (highest) star count achieved.
  final int stars;

  /// Fewest moves used. The number a "new best" is measured against.
  final int bestMoves;

  const LevelProgress({
    required this.levelId,
    required this.levelSetVersion,
    required this.stars,
    required this.bestMoves,
  });

  Map<String, Object?> toJson() => {
    'id': levelId,
    'v': levelSetVersion,
    's': stars,
    'm': bestMoves,
  };

  factory LevelProgress.fromJson(Map<String, Object?> json) => LevelProgress(
    levelId: (json['id']! as num).toInt(),
    levelSetVersion: (json['v']! as num).toInt(),
    stars: (json['s']! as num).toInt(),
    bestMoves: (json['m']! as num).toInt(),
  );

  /// Merges a fresh result, keeping the player's best of each.
  ///
  /// Monotonic on BOTH axes and independent of arrival order — the same rule
  /// the backend sync uses. A worse replay can never take a star away, which
  /// is exactly the bug that produces "the game deleted my progress" reviews.
  LevelProgress mergedWith({required int stars, required int moves}) =>
      LevelProgress(
        levelId: levelId,
        levelSetVersion: levelSetVersion,
        stars: stars > this.stars ? stars : this.stars,
        bestMoves: moves < bestMoves ? moves : bestMoves,
      );
}

class ProgressRepository {
  static const _key = 'pourfect.progress.v1';

  Future<Map<int, LevelProgress>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return {};

    try {
      final list = jsonDecode(raw) as List;
      return {
        for (final entry in list)
          (entry as Map<String, Object?>)['id']! as int: LevelProgress.fromJson(
            entry,
          ),
      };
    } catch (_) {
      // Corrupt payload is not worth blocking play over. Losing stars is bad;
      // refusing to start the game is worse.
      return {};
    }
  }

  Future<void> save(Map<int, LevelProgress> progress) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode([for (final p in progress.values) p.toJson()]),
    );
  }
}

/// The result of recording a finished level, for the win sequence to read.
class CompletionResult {
  final int stars;

  /// True when this run beat the player's own previous move count. Earns its
  /// own treatment in the win sequence, not a badge on the usual one.
  final bool isNewBest;

  /// The best BEFORE this run, or null if this was the first clear.
  final int? previousBest;

  const CompletionResult({
    required this.stars,
    required this.isNewBest,
    required this.previousBest,
  });
}

class ProgressController extends Notifier<Map<int, LevelProgress>> {
  /// Completes once the stored progress has been read and merged in.
  late final Future<void> _restored;

  /// Serialises persistence.
  ///
  /// Saves were fire-and-forget, so two completions in quick succession raced
  /// each other to the same key and the LATER write could land first — leaving
  /// disk holding the earlier, smaller map. Chaining them keeps writes in the
  /// order the player made them without making the win sequence wait.
  Future<void> _writes = Future<void>.value();

  @override
  Map<int, LevelProgress> build() {
    _restored = _restore();
    return const {};
  }

  /// Folds stored progress into whatever is already in memory.
  ///
  /// MERGES, never replaces. This provider is built lazily and the load is
  /// asynchronous, so a level can be completed before the stored snapshot
  /// arrives — and assigning `state = loaded` then deleted that completion
  /// outright, after which the next save persisted the loss. Reproduced in the
  /// audit: level 2 vanished when the level-1-only snapshot landed late.
  ///
  /// The union is monotonic per level, the same rule the server uses, so it
  /// cannot matter which side arrived first.
  Future<void> _restore() async {
    final loaded = await ref.read(progressRepositoryProvider).load();
    if (loaded.isEmpty) return;

    final merged = <int, LevelProgress>{...loaded};
    for (final entry in state.entries) {
      final stored = merged[entry.key];
      merged[entry.key] = stored == null
          ? entry.value
          : stored.mergedWith(
              stars: entry.value.stars,
              moves: entry.value.bestMoves,
            );
    }

    state = merged;

    // Anything recorded before the load arrived exists only in memory until
    // this lands, so the merged view is written back rather than assumed.
    if (merged.length != loaded.length) _enqueueSave();
  }

  /// Queues a write behind any already in flight.
  ///
  /// The repository is resolved NOW, not inside the queued callback. A queued
  /// write can run after the provider is disposed, and `ref.read` at that point
  /// throws — the save is the last thing that should fail when a screen goes
  /// away mid-write.
  void _enqueueSave() {
    final snapshot = state;
    final repository = ref.read(progressRepositoryProvider);

    // A failed write must not poison the chain and block every later save.
    _writes = _writes
        .then((_) => repository.save(snapshot))
        .catchError((Object error) {
          debugPrint('[progress] save failed: $error');
        });
  }

  LevelProgress? forLevel(int id) => state[id];

  /// True when the player may open level [id].
  ///
  /// Level 1 is always open; after that, clearing the previous level opens the
  /// next. Deliberately simple — a star-gate would let a player who is enjoying
  /// themselves hit a wall they have to grind past, which is a retention cost
  /// with no upside.
  bool isUnlocked(int id) =>
      kDevUnlockAll || id <= 1 || state.containsKey(id - 1);

  /// Highest level the player may play.
  int get furthestUnlocked {
    var id = 1;
    while (state.containsKey(id)) {
      id++;
    }
    return id;
  }

  int get totalStars => state.values.fold(0, (sum, p) => sum + p.stars);

  /// Levels cleared within a band's inclusive id range.
  int clearedIn(int firstLevel, int lastLevel) {
    var n = 0;
    for (var id = firstLevel; id <= lastLevel; id++) {
      if (state.containsKey(id)) n++;
    }
    return n;
  }

  /// Records a finished level and reports what was newly achieved.
  CompletionResult record({
    required Level level,
    required int levelSetVersion,
    required int movesUsed,
  }) {
    final stars = level.stars(movesUsed);
    final existing = state[level.id];
    final isNewBest = existing != null && movesUsed < existing.bestMoves;

    final merged =
        existing?.mergedWith(stars: stars, moves: movesUsed) ??
        LevelProgress(
          levelId: level.id,
          levelSetVersion: levelSetVersion,
          stars: stars,
          bestMoves: movesUsed,
        );

    state = {...state, level.id: merged};
    // Still not awaited — a slow disk write must never delay the win sequence
    // — but queued, so writes cannot land out of order.
    _enqueueSave();

    return CompletionResult(
      stars: stars,
      isNewBest: isNewBest,
      previousBest: existing?.bestMoves,
    );
  }

  /// Erases everything. Only ever reached through a confirm dialog.
  Future<void> resetAll() async {
    // Waits for the restore first. Without it, a load still in flight would
    // merge the old progress back in immediately after the wipe.
    await _restored;

    state = const {};
    _enqueueSave();
    await _writes;
  }

  /// Test seam.
  void debugSeed(Map<int, LevelProgress> seed) => state = seed;
}

/// Opens every level, for verifying the late campaign without playing 120
/// levels first:
///
///     flutter build apk --profile --dart-define=POURFECT_UNLOCK_ALL=true
///
/// Double-gated ON PURPOSE. It needs an explicit build flag AND a non-release
/// build, so there is no combination of flags that ships an unlocked campaign
/// to a player — `pourfect_dev_flags_test` asserts the release path.
const bool kDevUnlockAll =
    !kReleaseMode && bool.fromEnvironment('POURFECT_UNLOCK_ALL');

final progressRepositoryProvider = Provider<ProgressRepository>(
  (ref) => ProgressRepository(),
);

final progressProvider =
    NotifierProvider<ProgressController, Map<int, LevelProgress>>(
      ProgressController.new,
    );

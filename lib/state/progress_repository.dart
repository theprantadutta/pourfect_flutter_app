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
import '../engine/level_set.dart';

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

  /// Fastest solve, in whole seconds.
  ///
  /// ZERO MEANS UNKNOWN, not instantaneous. Every level cleared before the
  /// clock shipped has no time on record, and there is no honest way to invent
  /// one — the statistics screen shows those as a dash and every comparison
  /// here skips them.
  final int bestTimeSeconds;

  /// Highest score earned on this level. Also 0 when unknown.
  final int bestPoints;

  const LevelProgress({
    required this.levelId,
    required this.levelSetVersion,
    required this.stars,
    required this.bestMoves,
    this.bestTimeSeconds = 0,
    this.bestPoints = 0,
  });

  /// True when this level was cleared before the clock existed.
  bool get hasTime => bestTimeSeconds > 0;

  Map<String, Object?> toJson() => {
    'id': levelId,
    'v': levelSetVersion,
    's': stars,
    'm': bestMoves,
    't': bestTimeSeconds,
    'p': bestPoints,
  };

  factory LevelProgress.fromJson(Map<String, Object?> json) => LevelProgress(
    levelId: (json['id']! as num).toInt(),
    levelSetVersion: (json['v']! as num).toInt(),
    stars: (json['s']! as num).toInt(),
    bestMoves: (json['m']! as num).toInt(),
    // Absent on every row written before the clock shipped. Defaulting rather
    // than failing is the difference between an upgrade and a wipe.
    bestTimeSeconds: (json['t'] as num?)?.toInt() ?? 0,
    bestPoints: (json['p'] as num?)?.toInt() ?? 0,
  );

  /// Merges a fresh result, keeping the player's best of each.
  ///
  /// Monotonic on BOTH axes and independent of arrival order — the same rule
  /// the backend sync uses. A worse replay can never take a star away, which
  /// is exactly the bug that produces "the game deleted my progress" reviews.
  LevelProgress mergedWith({
    required int stars,
    required int moves,
    int timeSeconds = 0,
    int points = 0,
  }) => LevelProgress(
    levelId: levelId,
    levelSetVersion: levelSetVersion,
    stars: stars > this.stars ? stars : this.stars,
    bestMoves: moves < bestMoves ? moves : bestMoves,
    // Fastest wins, but an unknown time (0) is not the fastest time — it is
    // no time at all, and must never displace a real one.
    bestTimeSeconds: _fastest(bestTimeSeconds, timeSeconds),
    bestPoints: points > bestPoints ? points : bestPoints,
  );

  static int _fastest(int a, int b) {
    if (a <= 0) return b > 0 ? b : 0;
    if (b <= 0) return a;
    return a < b ? a : b;
  }
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

  /// This run's time and score, and the pace it was scored against.
  final int elapsedSeconds;
  final int parSeconds;
  final int points;

  /// True when this run beat the player's own previous time on this level.
  /// False on a first clear — there was nothing to beat.
  final bool isNewFastest;

  /// The fastest BEFORE this run, or null if this level had no time on record
  /// (a first clear, or one cleared before the clock shipped).
  final int? previousFastest;

  const CompletionResult({
    required this.stars,
    required this.isNewBest,
    required this.previousBest,
    required this.elapsedSeconds,
    required this.parSeconds,
    required this.points,
    required this.isNewFastest,
    required this.previousFastest,
  });

  /// True when the level was finished at or inside its par time.
  bool get isUnderPar => elapsedSeconds <= parSeconds;

  /// How far off par this run was, as a signed fraction. -0.2 is 20% faster
  /// than par; +0.5 is half again as long.
  double get parDelta =>
      parSeconds <= 0 ? 0 : (elapsedSeconds - parSeconds) / parSeconds;
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
              timeSeconds: entry.value.bestTimeSeconds,
              points: entry.value.bestPoints,
            );
    }

    state = _latest = merged;

    // Anything recorded before the load arrived exists only in memory until
    // this lands, so the merged view is written back rather than assumed.
    //
    // COMPARED BY VALUE, not by size. This used to ask whether the map had
    // grown, which is only true when the two sides disagree about which
    // LEVELS exist. The damaging case is the one where they agree: a level
    // stored at 3 stars in 5 moves, replayed badly to 1 star in 20 before the
    // load landed. Same single key on both sides, so no save was queued —
    // memory recovered the 3 stars and the disk kept the 1, and the next
    // launch restored the loss as though it were the truth.
    if (_differs(merged, loaded)) _enqueueSave();
  }

  /// Whether [merged] holds anything [loaded] does not already say.
  ///
  /// Only ever asked in the direction that matters: the merge is monotonic, so
  /// a difference can only mean the merged view is BETTER, and better is worth
  /// a write.
  static bool _differs(
    Map<int, LevelProgress> merged,
    Map<int, LevelProgress> loaded,
  ) {
    if (merged.length != loaded.length) return true;

    for (final entry in merged.entries) {
      final stored = loaded[entry.key];
      if (stored == null) return true;

      final fresh = entry.value;
      if (stored.stars != fresh.stars ||
          stored.bestMoves != fresh.bestMoves ||
          stored.bestTimeSeconds != fresh.bestTimeSeconds ||
          stored.bestPoints != fresh.bestPoints) {
        return true;
      }
    }
    return false;
  }

  /// Queues a write behind any already in flight.
  ///
  /// Two things here are load-bearing and neither is obvious.
  ///
  /// **The write waits for the restore.** A completion recorded during startup
  /// used to be persisted immediately, and what it persisted was the whole map
  /// as it stood: one level, because the stored snapshot had not arrived yet.
  /// That write is not merely redundant, it is a truncation — it lands on disk
  /// over a file that held the player's entire campaign. Waiting costs nothing
  /// (the restore is a single prefs read) and removes the window entirely.
  ///
  /// **The snapshot is taken when the write RUNS, not when it is queued.**
  /// Whatever is in memory at that moment has already absorbed everything
  /// earlier, because every path into this state is a monotonic merge. Queuing
  /// the value instead means a stale snapshot can be written after a fresher
  /// one, which is the same lost-update shape in a different place.
  ///
  /// The repository is resolved NOW rather than inside the callback: a queued
  /// write can run after the provider is disposed, and `ref.read` at that
  /// point throws — the save is the last thing that should fail when a screen
  /// goes away mid-write.
  void _enqueueSave() {
    final repository = ref.read(progressRepositoryProvider);

    // A failed write must not poison the chain and block every later save.
    _writes = _writes
        .then((_) => _restored)
        .then((_) => repository.save(_latest))
        .catchError((Object error) {
          debugPrint('[progress] save failed: $error');
        });
  }

  /// The newest state, readable from the write chain.
  ///
  /// Kept alongside `state` because a queued write can outlive the provider,
  /// and reading `state` after disposal throws — which would turn a routine
  /// screen change into a lost save.
  Map<int, LevelProgress> _latest = const {};

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

  int get totalPoints => state.values.fold(0, (sum, p) => sum + p.bestPoints);

  /// Sum of every level's FASTEST clear — not total time played. Time actually
  /// spent, including runs that were slower or abandoned, lives in the play
  /// history.
  int get totalBestTimeSeconds =>
      state.values.fold(0, (sum, p) => sum + p.bestTimeSeconds);

  /// Levels whose fastest clear beat par.
  int levelsUnderPar(LevelSet levels) {
    var n = 0;
    for (final p in state.values) {
      if (!p.hasTime) continue;
      final level = levels.byId(p.levelId);
      if (level != null && p.bestTimeSeconds <= level.level.parSeconds) n++;
    }
    return n;
  }

  /// Mean fastest-clear time as a fraction of par, over levels that have a
  /// time on record. 1.0 is exactly on pace; null when nothing qualifies.
  double? averageParRatio(LevelSet levels) {
    var sum = 0.0;
    var n = 0;
    for (final p in state.values) {
      if (!p.hasTime) continue;
      final level = levels.byId(p.levelId);
      if (level == null || level.level.parSeconds <= 0) continue;
      sum += p.bestTimeSeconds / level.level.parSeconds;
      n++;
    }
    return n == 0 ? null : sum / n;
  }

  /// The fastest and slowest clears on record, by raw seconds.
  LevelProgress? get fastestClear => _extremeByTime((a, b) => a < b);

  LevelProgress? get slowestClear => _extremeByTime((a, b) => a > b);

  LevelProgress? _extremeByTime(bool Function(int a, int b) wins) {
    LevelProgress? best;
    for (final p in state.values) {
      if (!p.hasTime) continue;
      if (best == null || wins(p.bestTimeSeconds, best.bestTimeSeconds)) {
        best = p;
      }
    }
    return best;
  }

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
    required int elapsedSeconds,
  }) {
    final stars = level.stars(movesUsed);
    final points = level.points(
      movesUsed: movesUsed,
      elapsedSeconds: elapsedSeconds,
    );
    final existing = state[level.id];
    final isNewBest = existing != null && movesUsed < existing.bestMoves;
    final previousFastest = (existing?.hasTime ?? false)
        ? existing!.bestTimeSeconds
        : null;
    final isNewFastest =
        previousFastest != null &&
        elapsedSeconds > 0 &&
        elapsedSeconds < previousFastest;

    final merged =
        existing?.mergedWith(
          stars: stars,
          moves: movesUsed,
          timeSeconds: elapsedSeconds,
          points: points,
        ) ??
        LevelProgress(
          levelId: level.id,
          levelSetVersion: levelSetVersion,
          stars: stars,
          bestMoves: movesUsed,
          bestTimeSeconds: elapsedSeconds,
          bestPoints: points,
        );

    state = _latest = {...state, level.id: merged};
    // Still not awaited — a slow disk write must never delay the win sequence
    // — but queued, so writes cannot land out of order.
    _enqueueSave();

    return CompletionResult(
      stars: stars,
      isNewBest: isNewBest,
      previousBest: existing?.bestMoves,
      elapsedSeconds: elapsedSeconds,
      parSeconds: level.parSeconds,
      points: points,
      isNewFastest: isNewFastest,
      previousFastest: previousFastest,
    );
  }

  /// Erases everything. Only ever reached through a confirm dialog.
  Future<void> resetAll() async {
    // Waits for the restore first. Without it, a load still in flight would
    // merge the old progress back in immediately after the wipe.
    await _restored;

    state = _latest = const {};
    _enqueueSave();
    await _writes;
  }

  /// Test seam.
  void debugSeed(Map<int, LevelProgress> seed) => state = _latest = seed;
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

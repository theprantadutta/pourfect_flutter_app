/// Achievements: long goals that run alongside the campaign.
///
/// The app decides when one is earned — several hang on moments only the
/// phone sees, like a clear with no undo — and the server keeps the record so
/// they follow the account to a new phone (see the API's
/// `AchievementCatalogue`, which allowlists these ids). Nothing here is worth
/// cheating for: an achievement buys nothing.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/api/api_result.dart';
import 'account_controller.dart';
import 'chest_controller.dart';
import 'event_controller.dart';
import 'progress_repository.dart';
import 'providers.dart';
import 'streak_controller.dart';

/// What the player's record adds up to, for checking achievements against.
@immutable
class AchievementFacts {
  final int levelsCleared;
  final int stars;

  /// Levels whose best clear was at par.
  final int parClears;
  final int hardClears;

  /// Worlds with every level at three stars.
  final int perfectWorlds;
  final int bestStreak;
  final int chestsOpened;
  final int eventBoardsCleared;
  final int zenBoards;

  /// The clear that has just happened, when there is one.
  final bool lastClearWithoutUndo;
  final int? lastClearSeconds;

  const AchievementFacts({
    this.levelsCleared = 0,
    this.stars = 0,
    this.parClears = 0,
    this.hardClears = 0,
    this.perfectWorlds = 0,
    this.bestStreak = 0,
    this.chestsOpened = 0,
    this.eventBoardsCleared = 0,
    this.zenBoards = 0,
    this.lastClearWithoutUndo = false,
    this.lastClearSeconds,
  });
}

@immutable
class Achievement {
  /// Shared with the API. Never rename.
  final String id;
  final String title;
  final String description;

  /// How far along the player is, out of [target].
  final int Function(AchievementFacts) progress;
  final int target;

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.progress,
    this.target = 1,
  });

  bool earnedBy(AchievementFacts facts) => progress(facts) >= target;
}

int _one(bool yes) => yes ? 1 : 0;

final List<Achievement> kAchievements = [
  Achievement(
    id: 'first_pour',
    title: 'First pour',
    description: 'Clear your first level.',
    progress: (f) => f.levelsCleared,
  ),
  Achievement(
    id: 'par_10',
    title: 'On par',
    description: 'Clear 10 levels in exactly par.',
    progress: (f) => f.parClears,
    target: 10,
  ),
  Achievement(
    id: 'par_50',
    title: 'Par master',
    description: 'Clear 50 levels in exactly par.',
    progress: (f) => f.parClears,
    target: 50,
  ),
  Achievement(
    id: 'clean_clear',
    title: 'No take-backs',
    description: 'Clear a level without using undo.',
    progress: (f) => _one(f.lastClearWithoutUndo),
  ),
  Achievement(
    id: 'speedy',
    title: 'Quick pour',
    description: 'Clear a level in under 30 seconds.',
    progress: (f) {
      final seconds = f.lastClearSeconds;
      return _one(seconds != null && seconds > 0 && seconds < 30);
    },
  ),
  Achievement(
    id: 'levels_100',
    title: 'Centurion',
    description: 'Clear 100 levels.',
    progress: (f) => f.levelsCleared,
    target: 100,
  ),
  Achievement(
    id: 'stars_300',
    title: 'Star hoarder',
    description: 'Collect 300 stars.',
    progress: (f) => f.stars,
    target: 300,
  ),
  Achievement(
    id: 'world_perfect',
    title: 'Flawless world',
    description: 'Three-star every level in a world.',
    progress: (f) => f.perfectWorlds,
  ),
  Achievement(
    id: 'streak_7',
    title: 'Week of pours',
    description: 'Reach a 7-day Daily Pour streak.',
    progress: (f) => f.bestStreak,
    target: 7,
  ),
  Achievement(
    id: 'streak_30',
    title: 'Month of pours',
    description: 'Reach a 30-day Daily Pour streak.',
    progress: (f) => f.bestStreak,
    target: 30,
  ),
  Achievement(
    id: 'chests_5',
    title: 'Treasure hunter',
    description: 'Open 5 star chests.',
    progress: (f) => f.chestsOpened,
    target: 5,
  ),
  Achievement(
    id: 'hard_5',
    title: 'Tough nut',
    description: 'Clear 5 HARD levels.',
    progress: (f) => f.hardClears,
    target: 5,
  ),
  Achievement(
    id: 'event_full',
    title: 'Full week',
    description: 'Clear all seven boards of a weekly event.',
    progress: (f) => f.eventBoardsCleared,
    target: 7,
  ),
  Achievement(
    id: 'zen_25',
    title: 'Zen garden',
    description: 'Pour 25 boards in Zen mode.',
    progress: (f) => f.zenBoards,
    target: 25,
  ),
];

@immutable
class AchievementsState {
  /// Unlocked ids.
  final Set<String> unlocked;

  /// The most recent unlocks, for the toast. Replaced on every unlock.
  final List<Achievement> justUnlocked;

  /// The facts as last worked out, for progress bars.
  final AchievementFacts facts;

  const AchievementsState({
    this.unlocked = const {},
    this.justUnlocked = const [],
    this.facts = const AchievementFacts(),
  });
}

class AchievementsController extends Notifier<AchievementsState> {
  static const _key = 'pourfect.achievements.v1';

  /// Zen boards poured, counted here because Zen keeps no other record.
  static const _zenKey = 'pourfect.zen.boards.v1';

  int _zenBoards = 0;

  /// False until the saved unlocks are read: a check before then would
  /// "unlock" everything already earned all over again.
  bool _ready = false;

  /// True on a phone that has never kept achievements — the first launch
  /// after they shipped. Everything a long-time player has already earned is
  /// unlocked quietly then, rather than as a dozen toasts at once.
  bool _silent = false;

  @override
  AchievementsState build() {
    // Checked whenever anything they depend on moves.
    ref.listen(progressProvider, (_, _) => check());
    ref.listen(streakProvider, (_, _) => check());
    ref.listen(chestProvider, (_, _) => check());
    ref.listen(eventProvider, (_, _) => check());
    ref.listen(accountProvider.select((a) => a.userId), (previous, next) {
      if (previous != next) unawaited(refresh());
    });
    unawaited(_restore());
    return const AchievementsState();
  }

  Future<void> _restore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _zenBoards = prefs.getInt(_zenKey) ?? 0;
      final ids = prefs.getStringList(_key);
      _silent = ids == null;
      state = AchievementsState(unlocked: {...?ids}, facts: _facts());
    } catch (_) {}
    _ready = true;
    check();
  }

  /// A level was just cleared: the one-off achievements look at it.
  void recordClear({required int undosUsed, required int seconds}) =>
      check(withoutUndo: undosUsed == 0, seconds: seconds);

  /// A Zen board was poured.
  Future<void> recordZenBoard() async {
    _zenBoards++;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_zenKey, _zenBoards);
    } catch (_) {}
    check();
  }

  int get zenBoards => _zenBoards;

  AchievementFacts _facts({bool withoutUndo = false, int? seconds}) {
    final progress = ref.read(progressProvider);
    final campaign = ref.read(campaignProvider).value;
    final bands = ref.read(campaignBandsProvider);

    var par = 0;
    var hard = 0;
    for (final entry in progress.values) {
      final level = campaign?.byId(entry.levelId)?.level;
      if (level == null) continue;
      if (entry.bestMoves <= level.minMoves) par++;
      if (level.isHard) hard++;
    }

    var perfect = 0;
    for (final band in bands) {
      var all = true;
      for (var id = band.firstLevel; id <= band.lastLevel; id++) {
        if ((progress[id]?.stars ?? 0) < 3) {
          all = false;
          break;
        }
      }
      if (all) perfect++;
    }

    return AchievementFacts(
      levelsCleared: progress.length,
      stars: progress.values.fold(0, (n, p) => n + p.stars),
      parClears: par,
      hardClears: hard,
      perfectWorlds: perfect,
      bestStreak: ref.read(streakProvider)?.best ?? 0,
      chestsOpened: ref.read(chestProvider).server?.opened.length ?? 0,
      eventBoardsCleared: ref.read(eventProvider).event?.cleared ?? 0,
      zenBoards: _zenBoards,
      lastClearWithoutUndo: withoutUndo,
      lastClearSeconds: seconds,
    );
  }

  /// Unlocks anything newly earned. Returns what was unlocked just now.
  List<Achievement> check({bool withoutUndo = false, int? seconds}) {
    if (!_ready) return const [];
    final facts = _facts(withoutUndo: withoutUndo, seconds: seconds);
    final fresh = [
      for (final a in kAchievements)
        if (!state.unlocked.contains(a.id) && a.earnedBy(facts)) a,
    ];
    if (fresh.isEmpty) {
      state = AchievementsState(unlocked: state.unlocked, facts: facts);
      return const [];
    }

    final unlocked = {...state.unlocked, for (final a in fresh) a.id};
    state = AchievementsState(
      unlocked: unlocked,
      justUnlocked: _silent ? const [] : fresh,
      facts: facts,
    );
    // Only the FIRST batch on a never-saved phone is quiet: progress loads a
    // moment after this does, so that batch can arrive after the restore.
    _silent = false;
    unawaited(_persist(unlocked));
    unawaited(_send([for (final a in fresh) a.id]));
    return fresh;
  }

  Future<void> _persist(Set<String> ids) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_key, ids.toList());
    } catch (_) {}
  }

  Future<void> _send(List<String> ids) async {
    final client = ref.read(apiClientProvider);
    if (!client.isConfigured) return;
    if (await ref.read(authServiceProvider).ensureSession() == null) return;
    final result = await client.post('/api/v1/achievements/unlock', {
      'ids': ids,
    });
    if (result case ApiFailure(:final kind)) {
      // Kept locally; the next refresh sends the whole set again.
      debugPrint('[achievements] not sent: $kind');
    }
  }

  /// Merges what the server holds with what this phone has, both ways.
  Future<void> refresh() async {
    final client = ref.read(apiClientProvider);
    if (!client.isConfigured) return;
    if (await ref.read(authServiceProvider).ensureSession() == null) return;
    final result = await client.post('/api/v1/achievements/unlock', {
      'ids': state.unlocked.toList(),
    });
    if (result case ApiOk(:final value)) {
      final rows = value['items'];
      if (rows is List) {
        final server = {
          for (final row in rows)
            if (row is Map && row['id'] is String) row['id'] as String,
        };
        final merged = {...state.unlocked, ...server};
        state = AchievementsState(unlocked: merged, facts: state.facts);
        await _persist(merged);
      }
    }
  }
}

final achievementsProvider =
    NotifierProvider<AchievementsController, AchievementsState>(
      AchievementsController.new,
    );

/// The abandon that waits to see whether the player comes back.
///
/// Backgrounding a level used to log `level_abandon` on the spot. Most trips
/// to the background are a notification or a text, and the player comes back
/// and finishes the board, so one run reported an abandon AND a completion:
/// 264 abandons against 297 completions in the first month, which made every
/// level look far harder than it is.
///
/// Now backgrounding only PARKS the abandon. Coming back to the level throws
/// it away. If the process dies while it is parked (the player swiped the game
/// away, or the OS reclaimed it), it is still on disk, and the next launch
/// sends it. That is the abandon that really happened.
library;

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'analytics_service.dart';

/// Where a parked abandon lives between processes.
abstract interface class PendingAbandonStore {
  Future<void> save(LevelAbandon abandon);
  Future<void> clear();

  /// Returns the parked abandon, if any, and clears it.
  Future<LevelAbandon?> take();
}

/// SharedPreferences, so a parked abandon outlives the process. Never throws:
/// losing one abandon is better than a lifecycle callback that fails.
final class PrefsPendingAbandonStore implements PendingAbandonStore {
  const PrefsPendingAbandonStore();

  static const _key = 'analytics_pending_abandon';

  @override
  Future<void> save(LevelAbandon abandon) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, jsonEncode(abandon.parameters));
    } catch (_) {}
  }

  @override
  Future<void> clear() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key);
    } catch (_) {}
  }

  @override
  Future<LevelAbandon?> take() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null) return null;
      await prefs.remove(_key);
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, Object?>) return null;
      return LevelAbandon.fromParameters(decoded);
    } catch (_) {
      return null;
    }
  }
}

/// In memory, for tests.
final class MemoryPendingAbandonStore implements PendingAbandonStore {
  LevelAbandon? parked;

  @override
  Future<void> save(LevelAbandon abandon) async => parked = abandon;

  @override
  Future<void> clear() async => parked = null;

  @override
  Future<LevelAbandon?> take() async {
    final value = parked;
    parked = null;
    return value;
  }
}

/// Sends an abandon parked by a process that never came back. Once per
/// launch, before any new level can park one of its own.
Future<void> sendAbandonLeftByLastRun(
  PendingAbandonStore store,
  AnalyticsService analytics,
) async {
  final abandon = await store.take();
  if (abandon != null) await analytics.log(abandon);
}

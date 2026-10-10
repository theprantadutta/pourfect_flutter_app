/// Notification permission, the player's two switches, and the one-time ask.
///
/// What the server sends is decided there (two a day at most, at the player's
/// local time). This owns what the PLAYER controls: whether the phone may show
/// anything at all, and which of the two kinds they want.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/api/push_service.dart';
import 'providers.dart';

@immutable
class NotificationPrefsState {
  /// What the OS allows.
  final PushPermission permission;

  /// The switches, as last known: the server's answer when there is one.
  final NotificationPreferences prefs;

  /// True once the first read has landed, so the screen does not flash the
  /// defaults before the real values.
  final bool loaded;

  const NotificationPrefsState({
    this.permission = PushPermission.notAsked,
    this.prefs = const NotificationPreferences(reminders: true, news: true),
    this.loaded = false,
  });

  NotificationPrefsState copyWith({
    PushPermission? permission,
    NotificationPreferences? prefs,
    bool? loaded,
  }) => NotificationPrefsState(
    permission: permission ?? this.permission,
    prefs: prefs ?? this.prefs,
    loaded: loaded ?? this.loaded,
  );
}

/// Levels cleared before the hub first offers notifications. By the third a
/// player has decided they like the game, and has something to be reminded of.
const int kSoftAskAfterSolved = 3;

/// How long after an offer the hub may offer again, to somebody who still
/// has notifications off. The owner's call (2026-10-05): ask occasionally,
/// not once and never again.
const Duration kSoftAskEvery = Duration(days: 15);

/// Offers in the life of the install, first one included. Six at fifteen
/// days is about three months of a gentle question; after that, the answer
/// is the answer, and the switch in Settings is still there.
const int kSoftAskMax = 6;

class NotificationPrefsController extends Notifier<NotificationPrefsState> {
  PushService get _push => ref.read(pushServiceProvider);

  @override
  // Read on demand (Settings calls [refresh] when it opens), not on build:
  // nothing else needs the server's switches, and a read nobody awaits
  // outlives whatever built this.
  NotificationPrefsState build() => const NotificationPrefsState();

  /// Reads the OS permission and the server's switches again. Called when
  /// Settings opens: the player may have changed either somewhere else.
  Future<void> refresh() async {
    final permission = await _push.refreshPermission();
    state = state.copyWith(permission: permission, loaded: true);
    final prefs = await _push.fetchPreferences();
    if (prefs != null) state = state.copyWith(prefs: prefs);
  }

  /// Asks the OS, and registers the device if the answer is yes. On a phone
  /// that has already said no, opens the system settings instead: Android
  /// will not show the prompt a second time.
  Future<bool> turnOn() async {
    if (state.permission == PushPermission.denied) {
      await _push.openSystemSettings();
      return false;
    }
    final on = await _push.requestAndRegister();
    state = state.copyWith(
      permission: on ? PushPermission.granted : PushPermission.denied,
    );
    return on;
  }

  /// Sets one switch. Moves only once the server agrees: a switch that shows
  /// "off" while the server still sends is the one failure worse than none.
  Future<bool> setReminders(bool on) =>
      _save(state.prefs.copyWith(reminders: on));

  Future<bool> setNews(bool on) => _save(state.prefs.copyWith(news: on));

  Future<bool> _save(NotificationPreferences next) async {
    final saved = await _push.savePreferences(next);
    if (saved == null) return false;
    state = state.copyWith(prefs: saved);
    return true;
  }

  // v2 (2026-10-10): every offer made under v1 on Android 13+ could only
  // say "open your settings" — the prompt itself was never raised (see
  // PushService.permission). Those offers used up the budget without ever
  // really asking, so the count starts again for everybody.
  static const _askCountKey = 'pourfect.push.soft_ask_count.v2';
  static const _askAtKey = 'pourfect.push.soft_ask_at.v2';

  /// Whether the hub should offer notifications now.
  ///
  /// Only to somebody who does not have them on, has cleared a few levels,
  /// has not been asked in the last [kSoftAskEvery], and has been asked fewer
  /// than [kSoftAskMax] times. A player who declined the system prompt is
  /// still offered (the card then opens the system settings), because the
  /// OS will not ask them again and nothing else would.
  Future<bool> shouldSoftAsk({required int solved, DateTime? now}) async {
    if (solved < kSoftAskAfterSolved) return false;
    if (await _push.refreshPermission() == PushPermission.granted) return false;
    try {
      final prefs = await SharedPreferences.getInstance();
      final count = prefs.getInt(_askCountKey) ?? 0;
      if (count >= kSoftAskMax) return false;
      final last = prefs.getInt(_askAtKey);
      if (last == null) return true;
      final since = (now ?? DateTime.now()).difference(
        DateTime.fromMillisecondsSinceEpoch(last),
      );
      return since >= kSoftAskEvery;
    } catch (_) {
      return false;
    }
  }

  /// Records an offer, whatever the answer.
  Future<void> markSoftAskShown({DateTime? now}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_askCountKey, (prefs.getInt(_askCountKey) ?? 0) + 1);
      await prefs.setInt(
        _askAtKey,
        (now ?? DateTime.now()).millisecondsSinceEpoch,
      );
    } catch (_) {}
  }
}

final notificationPrefsProvider =
    NotifierProvider<NotificationPrefsController, NotificationPrefsState>(
      NotificationPrefsController.new,
    );

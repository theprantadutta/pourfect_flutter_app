/// The provider graph.
///
/// MANUAL PROVIDERS ONLY — no `@riverpod`, no build_runner, no mixing styles.
/// The graph is small enough that code generation buys nothing and costs a
/// build step, and a codebase carrying two Riverpod styles is how the reference
/// project ended up with four state-management libraries at once.
library;

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../engine/level_set.dart';
import '../services/analytics/analytics_service.dart';
import '../services/analytics/firebase_analytics_service.dart';
import '../services/audio/audio_service.dart';
import '../services/audio/soloud_audio_service.dart';
import '../services/haptics/haptics_service.dart';
import 'game_controller.dart';
import 'game_state.dart';
import 'level_repository.dart';

/// Player-facing toggles. Persisted, and read live so a change takes effect on
/// the very next tap rather than the next level.
class Settings {
  final bool hapticsEnabled;
  final bool soundEnabled;

  /// Draws the accessibility glyphs larger and at full contrast.
  ///
  /// The glyphs are ALWAYS present — they are not a mode a colour-blind player
  /// has to discover in a menu, which is the mistake this genre usually makes.
  /// What this controls is emphasis: at the default weight they sit quietly
  /// inside the ball so the board stays calm, and turning this on trades that
  /// calm for maximum separability. Somebody who needs the shape to do all the
  /// work should not have to squint at a design decision.
  final bool boldSymbols;

  const Settings({
    this.hapticsEnabled = true,
    this.soundEnabled = true,
    this.boldSymbols = false,
  });

  Settings copyWith({
    bool? hapticsEnabled,
    bool? soundEnabled,
    bool? boldSymbols,
  }) => Settings(
    hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
    soundEnabled: soundEnabled ?? this.soundEnabled,
    boldSymbols: boldSymbols ?? this.boldSymbols,
  );

  Map<String, Object?> toJson() => {
    'haptics': hapticsEnabled,
    'sound': soundEnabled,
    'bold_symbols': boldSymbols,
  };

  factory Settings.fromJson(Map<String, Object?> json) => Settings(
    hapticsEnabled: json['haptics'] as bool? ?? true,
    soundEnabled: json['sound'] as bool? ?? true,
    boldSymbols: json['bold_symbols'] as bool? ?? false,
  );
}

class SettingsController extends Notifier<Settings> {
  static const _key = 'pourfect.settings.v1';

  @override
  Settings build() {
    _restore();
    return const Settings();
  }

  Future<void> _restore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null) return;
      state = Settings.fromJson(jsonDecode(raw) as Map<String, Object?>);
    } catch (_) {
      // Corrupt settings are not worth blocking play over; defaults are fine.
    }
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, jsonEncode(state.toJson()));
    } catch (_) {}
  }

  void setHaptics(bool value) {
    state = state.copyWith(hapticsEnabled: value);
    _persist();
  }

  void setSound(bool value) {
    state = state.copyWith(soundEnabled: value);
    _persist();
  }

  void setBoldSymbols(bool value) {
    state = state.copyWith(boldSymbols: value);
    _persist();
  }
}

final settingsProvider = NotifierProvider<SettingsController, Settings>(
  SettingsController.new,
);

/// Where analytics events go.
///
/// Overridden in tests with `RecordingAnalyticsService`, and in a future
/// privacy setting with `NoopAnalyticsService` — which is the entire point of
/// the indirection.
final analyticsServiceProvider = Provider<AnalyticsService>(
  (ref) => FirebaseAnalyticsService(debugLog: kDebugMode),
);

final hapticsServiceProvider = Provider<HapticsService>(
  (ref) => PlatformHapticsService(
    // Read, not watched: this closure runs at tap time, so it always sees the
    // current setting without rebuilding the service on every toggle.
    enabled: () => ref.read(settingsProvider).hapticsEnabled,
  ),
);

/// Sound. Every cue is synthesised at startup, so this ships no audio assets.
///
/// The session policy — mix with other audio, never take focus, obey the iOS
/// silent switch — lives in the implementation and is the part that decides
/// whether we stop somebody's podcast.
final audioServiceProvider = Provider<AudioService>((ref) {
  final service = SoLoudAudioService(
    enabled: () => ref.read(settingsProvider).soundEnabled,
  );
  ref.onDispose(service.dispose);
  return service;
});

final levelRepositoryProvider = Provider<LevelRepository>(
  (ref) => LevelRepository(),
);

/// The decoded campaign. ~7.8 KB, loaded once.
final campaignProvider = FutureProvider<LevelSet>(
  (ref) => ref.read(levelRepositoryProvider).load(),
);

/// The level currently being played.
final gameControllerProvider = NotifierProvider<GameController, GameState?>(
  GameController.new,
);

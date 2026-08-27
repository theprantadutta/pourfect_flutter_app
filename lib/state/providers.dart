/// The provider graph.
///
/// MANUAL PROVIDERS ONLY — no `@riverpod`, no build_runner, no mixing styles.
/// The graph is small enough that code generation buys nothing and costs a
/// build step, and a codebase carrying two Riverpod styles is how the reference
/// project ended up with four state-management libraries at once.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../engine/level_set.dart';
import '../services/analytics/analytics_service.dart';
import '../services/analytics/firebase_analytics_service.dart';
import '../services/haptics/haptics_service.dart';
import 'game_controller.dart';
import 'game_state.dart';
import 'level_repository.dart';

/// Player-facing toggles.
///
/// In-memory for now; persistence lands with the settings screen. Kept as a
/// notifier from the start so haptics can read it live — a toggle that only
/// takes effect next level would feel broken.
class Settings {
  final bool hapticsEnabled;
  final bool soundEnabled;

  const Settings({this.hapticsEnabled = true, this.soundEnabled = true});

  Settings copyWith({bool? hapticsEnabled, bool? soundEnabled}) => Settings(
    hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
    soundEnabled: soundEnabled ?? this.soundEnabled,
  );
}

class SettingsController extends Notifier<Settings> {
  @override
  Settings build() => const Settings();

  void setHaptics(bool value) => state = state.copyWith(hapticsEnabled: value);

  void setSound(bool value) => state = state.copyWith(soundEnabled: value);
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

/// The provider graph.
///
/// MANUAL PROVIDERS ONLY — no `@riverpod`, no build_runner, no mixing styles.
/// The graph is small enough that code generation buys nothing and costs a
/// build step, and a codebase carrying two Riverpod styles is how the reference
/// project ended up with four state-management libraries at once.
library;

import 'dart:convert';

import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../engine/level_set.dart';
import '../services/ads/ad_service.dart';
import '../services/ads/admob_ad_service.dart';
import '../services/analytics/analytics_service.dart';
import '../services/analytics/firebase_analytics_service.dart';
import '../services/iap/billing_service.dart';
import '../services/audio/audio_service.dart';
import '../services/audio/soloud_audio_service.dart';
import '../services/api/api_client.dart';
import '../services/api/auth_service.dart';
import '../services/api/identity.dart';
import '../services/api/api_result.dart';
import 'account_controller.dart';
import 'campaign_worlds.dart';
import 'frame_pace.dart';
import '../services/api/leaderboard_api.dart';
import '../services/review/play_review_service.dart';
import '../services/review/review_service.dart';
import '../services/api/push_service.dart';
import '../services/display/display_rate_service.dart';
import '../services/haptics/haptics_service.dart';
import 'game_controller.dart';
import 'game_state.dart';
import 'level_repository.dart';

/// Player-facing toggles. Persisted, and read live so a change takes effect on
/// the very next tap rather than the next level.
class Settings {
  final bool hapticsEnabled;

  /// Sound effects: the board, the buttons, the rewards.
  final bool soundEnabled;

  /// The background music. On by default (owner's call, 2026-10-10); it
  /// never starts over music the player is already listening to.
  final bool musicEnabled;

  /// 0..1, applied on top of each cue's own level.
  final double soundVolume;
  final double musicVolume;

  /// Draws the accessibility glyphs larger and at full contrast.
  ///
  /// The glyphs are ALWAYS present — they are not a mode a color-blind player
  /// has to discover in a menu, which is the mistake this genre usually makes.
  /// What this controls is emphasis: at the default weight they sit quietly
  /// inside the ball so the board stays calm, and turning this on trades that
  /// calm for maximum separability. Somebody who needs the shape to do all the
  /// work should not have to squint at a design decision.
  final bool boldSymbols;

  /// How fast the display is asked to run. See [SmoothMotion].
  ///
  /// Stored with the other settings on this device, not on the account —
  /// whether smooth motion is worth it depends on the phone in your hand.
  final SmoothMotion smoothMotion;

  const Settings({
    this.hapticsEnabled = true,
    this.soundEnabled = true,
    this.musicEnabled = true,
    this.soundVolume = 1.0,
    this.musicVolume = 0.6,
    this.boldSymbols = false,
    this.smoothMotion = SmoothMotion.auto,
  });

  Settings copyWith({
    bool? hapticsEnabled,
    bool? soundEnabled,
    bool? musicEnabled,
    double? soundVolume,
    double? musicVolume,
    bool? boldSymbols,
    SmoothMotion? smoothMotion,
  }) => Settings(
    hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
    soundEnabled: soundEnabled ?? this.soundEnabled,
    musicEnabled: musicEnabled ?? this.musicEnabled,
    soundVolume: soundVolume ?? this.soundVolume,
    musicVolume: musicVolume ?? this.musicVolume,
    boldSymbols: boldSymbols ?? this.boldSymbols,
    smoothMotion: smoothMotion ?? this.smoothMotion,
  );

  Map<String, Object?> toJson() => {
    'haptics': hapticsEnabled,
    'sound': soundEnabled,
    'music': musicEnabled,
    'sound_volume': soundVolume,
    'music_volume': musicVolume,
    'bold_symbols': boldSymbols,
    'smooth_motion': smoothMotion.name,
  };

  factory Settings.fromJson(Map<String, Object?> json) => Settings(
    hapticsEnabled: json['haptics'] as bool? ?? true,
    soundEnabled: json['sound'] as bool? ?? true,
    musicEnabled: json['music'] as bool? ?? true,
    soundVolume: ((json['sound_volume'] as num?)?.toDouble() ?? 1.0).clamp(
      0.0,
      1.0,
    ),
    musicVolume: ((json['music_volume'] as num?)?.toDouble() ?? 0.6).clamp(
      0.0,
      1.0,
    ),
    boldSymbols: json['bold_symbols'] as bool? ?? false,
    // Absent on every settings blob written before this existed: Auto.
    smoothMotion:
        SmoothMotion.values.asNameMap()[json['smooth_motion']] ??
        SmoothMotion.auto,
  );
}

/// The Smooth motion choice.
enum SmoothMotion {
  /// Ask for the panel's top rate, and step down to the system's standard
  /// rate if this phone turns out unable to draw frames that fast. The
  /// default: a fast panel says nothing about the chip driving it.
  auto,

  /// The system's standard rate — 60 Hz on almost every phone.
  standard,

  /// The panel's top rate, always, whatever it costs.
  max,
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

  void setMusic(bool value) {
    state = state.copyWith(musicEnabled: value);
    _persist();
  }

  void setSoundVolume(double value) {
    state = state.copyWith(soundVolume: value.clamp(0.0, 1.0));
    _persist();
  }

  void setMusicVolume(double value) {
    state = state.copyWith(musicVolume: value.clamp(0.0, 1.0));
    _persist();
  }

  void setBoldSymbols(bool value) {
    state = state.copyWith(boldSymbols: value);
    _persist();
  }

  void setSmoothMotion(SmoothMotion value) {
    state = state.copyWith(smoothMotion: value);
    _persist();
  }
}

final settingsProvider = NotifierProvider<SettingsController, Settings>(
  SettingsController.new,
);

final displayRateServiceProvider = Provider<DisplayRateService>(
  (ref) => const PluginDisplayRateService(),
);

/// What the display is asked for and what it is doing, for the Settings row.
@immutable
class DisplayRateState {
  final DisplayRate rate;

  /// Auto tried the fast rate on this phone and it could not keep up.
  final bool autoStepdown;

  const DisplayRateState({required this.rate, this.autoStepdown = false});

  static const initial = DisplayRateState(rate: DisplayRate.unknown);
}

/// Keeps the display rate in step with the Smooth motion setting.
///
/// Watching the setting is what applies it: a change in Settings, or the
/// stored choice arriving after the async restore, rebuilds this and re-asks
/// the platform. [reapply] exists for resume — some Android builds drop a
/// window's preferred mode while the app is in the background.
///
/// AUTO watches every frame the app draws while it is at the fast rate. If
/// [FramePaceJudge] finds this phone missing the shorter budget, the rate
/// steps down and the verdict is remembered for this install, so it is not
/// relearned by stuttering on every launch. Choosing Auto again in Settings
/// forgets the verdict and gives the phone another try.
class DisplayRateController extends Notifier<DisplayRateState> {
  static const _stepdownKey = 'pourfect.display.auto_stepdown.v1';

  DisplayRateState _last = DisplayRateState.initial;
  bool _stepdown = false;
  bool _stepdownRestored = false;
  TimingsCallback? _timings;

  @override
  DisplayRateState build() {
    final mode = ref.watch(settingsProvider.select((s) => s.smoothMotion));
    ref.onDispose(_stopWatching);
    _applyFor(mode);
    return _last;
  }

  Future<void> _applyFor(SmoothMotion mode) async {
    if (!_stepdownRestored) {
      _stepdownRestored = true;
      try {
        final prefs = await SharedPreferences.getInstance();
        _stepdown = prefs.getBool(_stepdownKey) ?? false;
      } catch (_) {}
      if (!ref.mounted) return;
    }

    final high = switch (mode) {
      SmoothMotion.max => true,
      SmoothMotion.standard => false,
      SmoothMotion.auto => !_stepdown,
    };
    final rate = await ref.read(displayRateServiceProvider).apply(high: high);
    if (!ref.mounted) return;

    _last = DisplayRateState(
      rate: rate,
      autoStepdown: mode == SmoothMotion.auto && _stepdown,
    );
    state = _last;

    // Only Auto, and only while actually above the standard rate: there is
    // nothing to learn from a phone that is already at 60.
    if (mode == SmoothMotion.auto && high && rate.current > 61) {
      _startWatching();
    } else {
      _stopWatching();
    }
  }

  void _startWatching() {
    if (_timings != null) return;
    final judge = FramePaceJudge();
    void onTimings(List<FrameTiming> frames) {
      final hz =
          ui.PlatformDispatcher.instance.implicitView?.display.refreshRate ??
          60;
      if (hz <= 61) return;
      final budget = (1000000 / hz).round();
      for (final f in frames) {
        final tipped = judge.add(
          buildMicros: f.buildDuration.inMicroseconds,
          rasterMicros: f.rasterDuration.inMicroseconds,
          budgetMicros: budget,
        );
        if (tipped) {
          _stepDown(hz);
          return;
        }
      }
    }

    _timings = onTimings;
    SchedulerBinding.instance.addTimingsCallback(onTimings);
  }

  void _stopWatching() {
    final t = _timings;
    if (t == null) return;
    SchedulerBinding.instance.removeTimingsCallback(t);
    _timings = null;
  }

  Future<void> _stepDown(double hz) async {
    _stopWatching();
    _stepdown = true;
    debugPrint(
      '[display] auto: frames miss the ${hz.round()} Hz budget; '
      'stepping down to the standard rate',
    );
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_stepdownKey, true);
    } catch (_) {}
    if (!ref.mounted) return;
    await _applyFor(ref.read(settingsProvider).smoothMotion);
  }

  /// Auto chosen again in Settings: forget the old verdict and let the phone
  /// try the fast rate once more.
  Future<void> retryAuto() async {
    _stepdown = false;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_stepdownKey);
    } catch (_) {}
    if (!ref.mounted) return;
    await _applyFor(ref.read(settingsProvider).smoothMotion);
  }

  Future<void> reapply() => _applyFor(ref.read(settingsProvider).smoothMotion);
}

final displayRateProvider =
    NotifierProvider<DisplayRateController, DisplayRateState>(
      DisplayRateController.new,
    );

/// Where analytics events go.
///
/// Overridden in tests with `RecordingAnalyticsService`, and in a future
/// privacy setting with `NoopAnalyticsService` — which is the entire point of
/// the indirection.
final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  // Noop when Firebase never came up. Constructing the real one reaches for
  // FirebaseAnalytics.instance, which throws without a default app — and it
  // does so outside the try that caught the initialisation failure, so the
  // app would survive startup and then fail on its first gameplay event.
  if (!firebaseReady) return const NoopAnalyticsService();
  return FirebaseAnalyticsService(debugLog: kDebugMode);
});

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
    volume: () => ref.read(settingsProvider).soundVolume,
    musicEnabled: () => ref.read(settingsProvider).musicEnabled,
    musicVolume: () => ref.read(settingsProvider).musicVolume,
  );
  ref.onDispose(service.dispose);
  return service;
});

/// Ads. Overridden with `NoopAdService` in tests and `FakeAdService` where a
/// scripted outcome is needed — which is the whole reason the interface exists.
/// The Play rating card.
///
/// Real on mobile, a no-op everywhere else — `isAvailable` answers false off a
/// Play device, so the prompter's rules never reach a platform call that cannot
/// work.
final reviewServiceProvider = Provider<ReviewService>((ref) {
  if (kIsWeb) return const NoopReviewService();
  return PlayReviewService();
});

final adServiceProvider = Provider<AdService>((ref) {
  final service = AdMobAdService();
  ref.onDispose(service.dispose);
  return service;
});

/// The single Remove Ads purchase.
final billingServiceProvider = Provider<BillingService>((ref) {
  final service = PlayBillingService();
  ref.onDispose(service.dispose);
  return service;
});

// ---- the backend -----------------------------------------------------------
//
// EVERY ONE OF THESE IS OPTIONAL. A build with no `POURFECT_API_BASE_URL` gets
// a client that reports `notConfigured` to everything and never opens a
// socket, and the game behaves exactly as it did before any of this existed.
// That is not a debug convenience — it is how the offline guarantee is kept
// honest, because the code path where there is no server is the one that runs
// on every plane, every underground train and every install in a country we
// have not deployed to.

/// The HTTP client. One per app, so connections are reused.
final Provider<ApiClient> apiClientProvider = Provider<ApiClient>((ref) {
  final client = ApiClient(
    // Resolved lazily, and it has to be: the auth service needs this client to
    // exchange a token, and this client needs the auth service to supply one.
    // Reading through `ref` at call time rather than at construction is what
    // keeps that from being a cycle.
    tokenProvider: ({bool forceRefresh = false}) =>
        ref.read(authServiceProvider).bearerToken(forceRefresh: forceRefresh),
  );
  ref.onDispose(client.close);
  return client;
});

/// The session, and how one is obtained.
final Provider<AuthService> authServiceProvider = Provider<AuthService>(
  (ref) => AuthService(
    client: () => ref.read(apiClientProvider),
    appVersion: () => ref.read(appVersionProvider),
  ),
);

/// Who the player is to Firebase, and how that can change.
///
/// Separate from [authServiceProvider], which owns the exchange with our own
/// backend. Overridden in tests with a fake, so the whole account flow runs
/// without a Firebase project.
final Provider<Identity> identityProvider = Provider<Identity>(
  (ref) => FirebaseIdentity(),
);

/// The leaderboard name, and account deletion.
final Provider<UsersApi> usersApiProvider = Provider<UsersApi>(
  (ref) => UsersApi(ref.read(apiClientProvider)),
);

/// Push registration, and the one moment it is appropriate to ask.
final Provider<PushService> pushServiceProvider = Provider<PushService>(
  (ref) => PushService(client: () => ref.read(apiClientProvider)),
);

/// The running app's version string, for the auth handshake.
///
/// Set once at startup. A `Provider` rather than a `FutureProvider` because
/// auth must never wait on a plugin call to learn something this unimportant —
/// an empty version is a fine thing to send.
final appVersionProvider = Provider<String>((ref) => '');

final levelRepositoryProvider = Provider<LevelRepository>(
  (ref) => LevelRepository(),
);

/// The campaign bundled in the APK: levels 1-150. ~7.8 KB, loaded once.
final bundledCampaignProvider = FutureProvider<LevelSet>(
  (ref) => ref.read(levelRepositoryProvider).load(),
);

/// The campaign this phone can play: the bundled 150 plus every world
/// downloaded since (see `campaign_worlds.dart`).
///
/// A plain Provider of an AsyncValue rather than a FutureProvider, and that is
/// deliberate. A world lands in the background, often while the hub is on
/// screen; a FutureProvider would pass through loading to absorb it, and every
/// screen reading `asData` would blink its board out for a frame. Merging
/// synchronously means the campaign simply gets longer.
final campaignProvider = Provider<AsyncValue<LevelSet>>((ref) {
  final worlds = ref.watch(campaignWorldsProvider).worlds;
  return ref
      .watch(bundledCampaignProvider)
      .whenData(
        (bundled) => worlds.isEmpty
            ? bundled
            : LevelSet(
                levelSetVersion: bundled.levelSetVersion,
                levels: [
                  ...bundled.levels,
                  for (final world in worlds) ...world.levels,
                ],
              ),
      );
});

/// Every world in campaign order, bundled bands first.
final campaignBandsProvider = Provider<List<BandInfo>>((ref) {
  final worlds = ref.watch(campaignWorldsProvider).worlds;
  return [
    ...campaignBands(),
    for (final world in worlds)
      BandInfo(
        index: world.index,
        name: world.name,
        firstLevel: world.firstLevel,
        lastLevel: world.lastLevel,
        shape: shapeLabelFor([for (final l in world.levels) l.level.board]),
      ),
  ];
});

/// The level currently being played.
final gameControllerProvider = NotifierProvider<GameController, GameState?>(
  GameController.new,
);

/// The player's own position on the campaign board, or null when they have
/// none.
///
/// **A rank nobody can see is not a rank.** The home screen's RANK figure was
/// a hardcoded em dash — it never displayed a position even for a player who
/// had one, because nothing ever fetched it. The leaderboard existed, the
/// server served it, and the one place a player looks said nothing.
///
/// Null covers every reason there is no number to show, and they are all the
/// same to the screen: offline, no backend configured, no stars yet, or the
/// player has taken themselves off the boards. An em dash is the honest
/// rendering of all four.
///
/// A `limit` of 1 because only `you` is read — the server returns the caller's
/// own row regardless of whether they are in the requested window, so asking
/// for fifty rows to discard forty-nine is a page of JSON for nothing.
final campaignRankProvider = FutureProvider<int?>((ref) async {
  final client = ref.watch(apiClientProvider);
  if (!client.isConfigured) return null;

  // Rebuilds when the account changes, so a rename, a sign-in or switching
  // the leaderboard off is reflected without the player restarting the app.
  ref.watch(accountProvider);

  final result = await LeaderboardApi(client).campaign(limit: 1);
  return switch (result) {
    ApiOk(:final value) => value.you?.rank,
    ApiFailure() => null,
  };
});

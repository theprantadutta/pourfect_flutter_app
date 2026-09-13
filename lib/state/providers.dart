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
import '../services/api/leaderboard_api.dart';
import '../services/api/push_service.dart';
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
  /// The glyphs are ALWAYS present — they are not a mode a color-blind player
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
  );
  ref.onDispose(service.dispose);
  return service;
});

/// Ads. Overridden with `NoopAdService` in tests and `FakeAdService` where a
/// scripted outcome is needed — which is the whole reason the interface exists.
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

/// The decoded campaign. ~7.8 KB, loaded once.
final campaignProvider = FutureProvider<LevelSet>(
  (ref) => ref.read(levelRepositoryProvider).load(),
);

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

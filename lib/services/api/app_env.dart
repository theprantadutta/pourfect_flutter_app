/// Configuration that differs between machines and environments.
///
/// Read from the bundled `.env`, which this project already uses for exactly
/// this — see `.env.example`. **Everything in it ships inside the APK and can
/// be read out of a downloaded build**, so it holds public identifiers and
/// endpoint URLs and nothing else. A signing key, a service account or an API
/// secret in here would be a secret published to every install.
///
/// Parsed by hand rather than with a package. It is `KEY=value` with comments,
/// the whole grammar fits in twenty lines, and this codebase has already
/// dropped a dependency over 257 KB of unused icons — a package to split
/// strings on `=` is not a trade worth making.
///
/// Nothing here throws. A missing or unreadable file leaves every value empty,
/// which switches the backend off and leaves the game exactly as playable as
/// it is with no network at all.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class AppEnv {
  /// Overrides the URL from `.env` when passed at build time.
  ///
  ///     flutter build apk --dart-define=POURFECT_API_BASE_URL=https://...
  ///
  /// For CI and for pointing one build at a scratch server without editing a
  /// file that every other build on the machine shares.
  static const String _override = String.fromEnvironment(
    'POURFECT_API_BASE_URL',
  );

  static Map<String, String> _values = const {};
  static bool _loaded = false;

  /// Reads the bundle. Call once, before `runApp`.
  static Future<void> load({AssetBundle? bundle}) async {
    if (_loaded) return;
    _loaded = true;

    try {
      final raw = await (bundle ?? rootBundle).loadString('.env');
      _values = parse(raw);
    } catch (error) {
      // A fresh clone has no `.env` — it is gitignored, and `.env.example`
      // says to copy it. Continuing with nothing configured is the right
      // answer: the campaign does not need a backend, and refusing to start
      // over a missing leaderboard would be absurd.
      debugPrint('[env] no .env bundled ($error); backend features are off');
      _values = const {};
    }
  }

  @visibleForTesting
  static void debugSet(Map<String, String> values) {
    _values = values;
    _loaded = true;
  }

  @visibleForTesting
  static Map<String, String> parse(String raw) {
    final values = <String, String>{};

    for (final line in raw.split('\n')) {
      final trimmed = line.trim();
      if (trimmed.isEmpty || trimmed.startsWith('#')) continue;

      final split = trimmed.indexOf('=');
      if (split <= 0) continue;

      final key = trimmed.substring(0, split).trim();
      var value = trimmed.substring(split + 1).trim();

      // Quotes are stripped, because a URL somebody pasted in quotes should
      // work rather than produce a hostname with a `"` in it.
      if (value.length >= 2 &&
          ((value.startsWith('"') && value.endsWith('"')) ||
              (value.startsWith("'") && value.endsWith("'")))) {
        value = value.substring(1, value.length - 1);
      }

      values[key] = value;
    }

    return values;
  }

  static String get(String key) => _values[key] ?? '';

  /// Where the API lives for THIS build.
  ///
  /// The release/debug split is the same rule the ad ids follow, and for the
  /// same reason: a constant somebody remembers to flip is a constant somebody
  /// forgets to flip. A debug build points at the development machine's LAN
  /// address — `localhost` on a handset is the handset — and a release build
  /// can only ever reach production.
  static String get apiBaseUrl {
    if (_override.isNotEmpty) return _override;
    return kReleaseMode
        ? get('PROD_API_BACKEND_URL')
        : get('DEV_API_BACKEND_URL');
  }

  /// The OAuth WEB client id, for Google Sign-In.
  ///
  /// Android will not return an ID TOKEN without it: sign-in appears to
  /// succeed, hands back an account, and `idToken` is null with nothing to
  /// give Firebase.
  static String get googleWebClientId => get('GOOGLE_WEB_CLIENT_ID');

  /// Whether this build can reach a backend at all.
  static bool get backendConfigured => apiBaseUrl.isNotEmpty;
}

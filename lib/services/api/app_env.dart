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
  ///
  /// A release URL that does not pass [releaseUrlProblem] is DISCARDED, and
  /// the build behaves as one with no backend at all. That is not defensive
  /// tidiness: `.env.example` ships `PROD_API_BACKEND_URL=https://example.com`
  /// and a real `.env` copied from it inherits the placeholder, so the
  /// alternative is a signed release quietly sending every player's progress
  /// and Firebase token to a domain we do not own. Silence is the only safe
  /// failure here — the campaign does not need a server, and a leaderboard
  /// that is missing is better than one that is somebody else's.
  static String get apiBaseUrl {
    final configured = _override.isNotEmpty
        ? _override
        : kReleaseMode
        ? get('PROD_API_BACKEND_URL')
        : get('DEV_API_BACKEND_URL');

    if (!kReleaseMode) return configured;

    final problem = releaseUrlProblem(configured);
    if (problem == null) return configured;

    debugPrint('[env] release API URL refused ($problem); backend features off');
    return '';
  }

  /// Why a URL must not be used by a RELEASE build, or null if it is fine.
  ///
  /// Deliberately a denylist of things that cannot be right rather than an
  /// allowlist of hosts, which would need editing for every environment. Each
  /// rule exists because shipping it would be worse than shipping nothing:
  ///
  ///  * **A placeholder** is the failure this was written for. It is what the
  ///    example file contains, so it is what a hurried copy contains.
  ///  * **Cleartext** would put a bearer token and a Firebase ID token on the
  ///    wire in plain text, and a release build has no network security
  ///    exception to permit it anyway.
  ///  * **A private or loopback address** is a development machine. On a
  ///    player's phone it resolves to their own network, or to their phone.
  @visibleForTesting
  static String? releaseUrlProblem(String url) {
    if (url.isEmpty) return null; // Unconfigured is a supported state.

    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      return 'not a URL';
    }

    if (uri.scheme != 'https') return 'not https';

    final host = uri.host.toLowerCase();

    const placeholders = {
      'example.com',
      'example.org',
      'example.net',
      'changeme',
      'todo',
      'your-api',
      'api.example.com',
    };
    if (placeholders.contains(host)) return 'placeholder host';

    // Reserved for documentation and testing; never a real deployment.
    for (final suffix in const ['.example', '.invalid', '.test', '.local', '.localhost']) {
      if (host.endsWith(suffix)) return 'reserved host suffix';
    }

    if (host == 'localhost' || host == '127.0.0.1' || host == '::1') {
      return 'loopback host';
    }

    if (_isPrivateAddress(host)) return 'private network address';

    return null;
  }

  static bool _isPrivateAddress(String host) {
    final parts = host.split('.');
    if (parts.length != 4) return false;

    final octets = <int>[];
    for (final part in parts) {
      final value = int.tryParse(part);
      if (value == null || value < 0 || value > 255) return false;
      octets.add(value);
    }

    if (octets[0] == 10) return true;
    if (octets[0] == 192 && octets[1] == 168) return true;
    if (octets[0] == 172 && octets[1] >= 16 && octets[1] <= 31) return true;
    return false;
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

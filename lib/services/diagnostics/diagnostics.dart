/// Logging that survives a release build, and the startup report that says
/// which configuration this build actually picked up.
///
/// **This exists because a release build had no voice.** Google sign-in failed
/// in production and worked in development, and there was nothing to read: the
/// one branch that fired logged nothing at all, and the two most important
/// startup failures — Firebase init and the version read — went through
/// `dart:developer`'s `log`, which posts to the VM service and never reaches
/// `adb logcat`. So the only build anybody could diagnose was the one that
/// already worked.
///
/// **`debugPrint`, deliberately, and not `developer.log`.** The name is
/// misleading: `debugPrint` is not stripped in release. It calls `print`,
/// which the engine routes to logcat under the `flutter` tag in every build
/// mode. `developer.log` is the one that goes quiet, because it publishes to
/// the VM service and a release build has none attached. The same trap is
/// already recorded in CLAUDE.md for the analytics mirror; this is the second
/// place it bit.
///
/// Everything here is prefixed with [_prefix] so one grep gets the lot:
///
///     adb logcat | grep pourfect
library;

import 'package:flutter/foundation.dart';

/// One tag, so a single grep finds every line this app writes.
const _prefix = 'pourfect';

/// Writes a line that a release build will actually emit.
///
/// [area] is the short subsystem name that already prefixes the existing
/// `debugPrint` calls — `identity`, `auth`, `env`, `sync` — kept so the two
/// styles read the same in one log.
void logLine(String area, String message) {
  debugPrint('[$_prefix][$area] $message');
}

/// Writes an error with its stack, in a form that survives release.
///
/// The stack is printed on its own lines rather than interpolated, because a
/// one-line stack in logcat is unreadable and logcat will truncate it anyway.
void logError(String area, Object error, [StackTrace? stack]) {
  debugPrint('[$_prefix][$area] ERROR $error');
  if (stack != null) {
    debugPrint('[$_prefix][$area] $stack');
  }
}

/// What this build is, and what configuration it resolved.
///
/// Printed once at startup, as a block, so a bug report can be answered by
/// asking for the first twenty lines of logcat rather than by guessing which
/// `.env` a signed APK was built against.
///
/// **Values are reported as resolved, not as configured.** The difference is
/// the whole point: a release build silently discards an API URL that fails
/// `AppEnv.releaseUrlProblem`, so "what is in .env" and "what the app will
/// actually call" are different questions and only the second one matters.
class StartupReport {
  const StartupReport({
    required this.buildMode,
    required this.version,
    required this.packageName,
    required this.apiBaseUrl,
    required this.apiUrlRefusedBecause,
    required this.firebaseReady,
    required this.firebaseProjectId,
    required this.googleWebClientIdPresent,
    required this.signingSha1,
  });

  final String buildMode;
  final String version;
  final String packageName;

  /// The URL the app will actually use. Empty means no backend this run.
  final String apiBaseUrl;

  /// Why a release build threw the configured URL away, or null if it kept it.
  final String? apiUrlRefusedBecause;

  final bool firebaseReady;
  final String firebaseProjectId;

  /// Presence only. The id is not a secret — it ships in the APK — but a
  /// truncated form is enough to tell "set" from "empty", and a log full of
  /// long constants is a log nobody reads.
  final bool googleWebClientIdPresent;

  /// The certificate this build is signed with, as Google sees it.
  ///
  /// **The single most useful line in this report.** Google Play Services
  /// validates the signing certificate against the OAuth clients registered
  /// for the package, so a fingerprint that is not in the Firebase console is
  /// exactly why sign-in works in debug and fails in release — and the failure
  /// arrives as a cancellation, indistinguishable from the player pressing
  /// back. Printing it turns an afternoon into one line.
  ///
  /// Null when the platform could not answer, which is every non-Android
  /// build.
  final String? signingSha1;

  void write() {
    logLine('startup', '--- Pourfect $version ($buildMode) ---');
    logLine('startup', 'package        $packageName');
    logLine('startup', 'signing SHA-1  ${signingSha1 ?? "unavailable"}');
    logLine(
      'startup',
      'api            ${apiBaseUrl.isEmpty ? "(none — backend features off)" : apiBaseUrl}',
    );
    if (apiUrlRefusedBecause != null) {
      logLine('startup', 'api REFUSED    $apiUrlRefusedBecause');
    }
    logLine(
      'startup',
      'firebase       ${firebaseReady ? "ready" : "NOT READY"} '
          '${firebaseProjectId.isEmpty ? "" : "($firebaseProjectId)"}',
    );
    logLine(
      'startup',
      'google client  ${googleWebClientIdPresent ? "set" : "MISSING — Google sign-in returns a null ID token"}',
    );
    logLine('startup', '---');
  }
}

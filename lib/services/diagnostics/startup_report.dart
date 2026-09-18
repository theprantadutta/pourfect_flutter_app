/// Builds the startup report by asking each source what it actually resolved.
///
/// Separate from `diagnostics.dart` so the report's *shape* has no imports and
/// stays trivially testable, while the gathering — which needs the env, the
/// Firebase options and a platform channel — lives here.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../analytics/analytics_service.dart' show firebaseReady;
import '../api/app_env.dart';
import 'diagnostics.dart';

/// The Android side of `MainActivity.kt`.
const _channel = MethodChannel('pourfect/diagnostics');

/// Asks the platform which certificate signed this build.
///
/// Never throws and never blocks startup for long: a missing implementation,
/// a non-Android platform and a platform exception all mean the same thing to
/// the report — the line reads "unavailable" and everything else still prints.
Future<String?> signingSha1() async {
  if (defaultTargetPlatform != TargetPlatform.android) return null;

  try {
    return await _channel.invokeMethod<String>('signingSha1');
  } catch (error) {
    logLine('startup', 'signing fingerprint unavailable: $error');
    return null;
  }
}

/// Gathers everything and writes it.
///
/// Called once, after `AppEnv.load()` and the Firebase attempt, so every value
/// it reports is the resolved one rather than the intended one.
Future<void> writeStartupReport({
  required String version,
  required String buildNumber,
  required String packageName,
  required String firebaseProjectId,
}) async {
  // Asked separately from `apiBaseUrl` on purpose. `apiBaseUrl` returns the
  // empty string when a release URL is refused and says nothing about why;
  // the reason is the only part that tells somebody what to fix.
  final refusal = AppEnv.apiUrlRefusal;

  StartupReport(
    buildMode: kReleaseMode
        ? 'release'
        : kProfileMode
        ? 'profile'
        : 'debug',
    version: '$version+$buildNumber',
    packageName: packageName,
    apiBaseUrl: AppEnv.apiBaseUrl,
    apiUrlRefusedBecause: refusal,
    firebaseReady: firebaseReady,
    firebaseProjectId: firebaseProjectId,
    googleWebClientIdPresent: AppEnv.googleWebClientId.isNotEmpty,
    signingSha1: await signingSha1(),
  ).write();
}

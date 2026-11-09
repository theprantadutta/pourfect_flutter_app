/// Crashlytics and the release-only switch for everything Firebase reports.
///
/// ONE RULE: only a release build reports. A debug or profile build is us at a
/// desk, and its crashes, undos and level funnels landing in the same property
/// as players' made both dashboards unreadable: on 2026-11-09 one tester
/// accounted for 225 `undo_used` events, a tenth of everything recorded.
///
/// The switch exists twice on purpose. Android also turns collection off in
/// the manifest for debug builds (see `android/app/build.gradle.kts`), because
/// the SDK logs `first_open` and `session_start` natively before any Dart
/// runs. The calls here are what decide it on iOS, and they repeat the
/// decision on Android at no cost.
library;

import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

import 'diagnostics.dart';

/// Whether this build reports to Firebase at all.
const bool kReportsTelemetry = kReleaseMode;

/// Applies [kReportsTelemetry] to Analytics and Crashlytics, and routes
/// uncaught errors to Crashlytics.
///
/// Call once, after `Firebase.initializeApp` has succeeded. Never throws: a
/// crash reporter that can stop the game starting is the worst kind of bug.
Future<void> configureTelemetry() async {
  try {
    await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(
      kReportsTelemetry,
    );
  } catch (error) {
    logLine('telemetry', 'analytics switch failed: $error');
  }

  final FirebaseCrashlytics crashlytics;
  try {
    crashlytics = FirebaseCrashlytics.instance;
    await crashlytics.setCrashlyticsCollectionEnabled(kReportsTelemetry);
  } catch (error) {
    logLine('telemetry', 'crashlytics unavailable: $error');
    return;
  }

  // Framework errors: a build, layout or paint that threw. Fatal in the sense
  // Crashlytics means it, the frame was lost, even though the app carries
  // on. The original handler still runs, so a debug build prints the red
  // screen and the console dump exactly as before.
  final previous = FlutterError.onError;
  FlutterError.onError = (details) {
    previous?.call(details);
    if (kReportsTelemetry) crashlytics.recordFlutterFatalError(details);
  };

  // Everything else that escaped: a future nobody awaited, a callback from a
  // platform channel. Returning true marks it handled, which is what keeps a
  // release build alive after reporting it, the same as before this existed.
  PlatformDispatcher.instance.onError = (error, stack) {
    if (kReportsTelemetry) {
      crashlytics.recordError(error, stack, fatal: true);
    } else {
      logError('uncaught', error, stack);
    }
    return true;
  };
}

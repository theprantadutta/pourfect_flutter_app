/// Firebase implementation of [AnalyticsService].
///
/// Kept deliberately thin. Everything interesting about our analytics lives in
/// the event catalogue in `analytics_service.dart`; this file only translates
/// and forwards, so swapping provider later is a one-file change.
library;

import 'dart:developer' as developer;

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

import 'analytics_service.dart';

class FirebaseAnalyticsService implements AnalyticsService {
  final FirebaseAnalytics _analytics;

  /// Mirrors every event to the device console. On in debug builds so the
  /// funnel can be verified while actually playing, rather than discovered to
  /// be mis-wired a week after release.
  ///
  /// Uses `debugPrint`, NOT `dart:developer.log`: the latter posts to the VM
  /// service and never reaches `adb logcat`, so a funnel "verified" through it
  /// is really just verified against DevTools being attached.
  final bool debugLog;

  FirebaseAnalyticsService({
    FirebaseAnalytics? analytics,
    this.debugLog = false,
  }) : _analytics = analytics ?? FirebaseAnalytics.instance;

  @override
  Future<void> log(AnalyticsEvent event) async {
    if (debugLog) {
      debugPrint('[analytics] ${event.name} ${event.parameters}');
    }

    // Analytics must never take gameplay down with it. A network blip, a
    // malformed parameter or an uninitialised Firebase app are all survivable;
    // a crash mid-pour is not.
    try {
      await _analytics.logEvent(name: event.name, parameters: event.parameters);
    } catch (error, stack) {
      developer.log(
        'failed to log ${event.name}',
        name: 'analytics',
        error: error,
        stackTrace: stack,
      );
    }
  }

  @override
  Future<void> flush() async {
    // The Firebase SDK batches and uploads on its own schedule and exposes no
    // explicit flush. Kept as a no-op so the interface still expresses the
    // intent — and so a future sink that DOES buffer can honour it without a
    // signature change.
  }
}

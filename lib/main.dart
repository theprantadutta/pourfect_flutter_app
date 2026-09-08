import 'dart:developer' as developer;

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'firebase_options.dart';
import 'services/analytics/analytics_service.dart';
import 'services/licenses.dart';
import 'services/perf/frame_watch.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  configureSystemChrome();
  registerFontLicenses();

  // THE GAME IS FULLY PLAYABLE OFFLINE and no network call may ever block it.
  // Firebase only powers analytics and, later, optional cloud sync — so a
  // failure here is logged and shrugged off rather than allowed to stop a
  // player reaching level 1.
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    firebaseReady = true;
  } catch (error, stack) {
    developer.log(
      'Firebase init failed; continuing offline',
      name: 'startup',
      error: error,
      stackTrace: stack,
    );
  }

  // Profile/debug only — reports build and raster percentiles to logcat every
  // few seconds of play. `dumpsys gfxinfo` cannot see a Flutter app's frames,
  // so the app measures itself.
  FrameWatch().start();

  runApp(const ProviderScope(child: PourfectApp()));
}

import 'dart:developer' as developer;

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'app.dart';
import 'firebase_options.dart';
import 'services/api/app_env.dart';
import 'services/analytics/analytics_service.dart';
import 'services/licenses.dart';
import 'services/perf/frame_watch.dart';
import 'state/providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  configureSystemChrome();
  registerFontLicenses();

  // One small asset read, before anything can ask where the backend is. It
  // cannot fail loudly: a build with no `.env` simply has no backend, which is
  // a fully supported way for this game to run.
  await AppEnv.load();

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

  // The version rides on the auth handshake, so the server can tell which
  // build a report came from. Read here rather than inside auth because auth
  // must not wait on a plugin channel to learn something this unimportant —
  // and an empty version is a perfectly fine thing to send.
  var appVersion = '';
  try {
    appVersion = (await PackageInfo.fromPlatform()).version;
  } catch (error) {
    developer.log('version unavailable', name: 'startup', error: error);
  }

  runApp(
    ProviderScope(
      overrides: [appVersionProvider.overrideWithValue(appVersion)],
      child: const PourfectApp(),
    ),
  );
}

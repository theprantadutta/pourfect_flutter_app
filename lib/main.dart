import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'dart:async';

import 'app.dart';
import 'firebase_options.dart';
import 'services/api/app_env.dart';
import 'services/diagnostics/diagnostics.dart';
import 'services/diagnostics/startup_report.dart';
import 'services/notifications/notification_service.dart';
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
    // RELEASE-VISIBLE. This used to go through `dart:developer`'s `log`, which
    // publishes to the VM service and reaches no logcat a release build has —
    // so the one failure that turns off analytics, sign-in and sync for the
    // whole session was invisible on precisely the builds players run.
    logError('startup', 'Firebase init failed; continuing offline', stack);
    logLine('startup', 'firebase error: $error');
  }

  // OFF unless asked for: --dart-define=FRAME_WATCH=true. Reports build and
  // raster percentiles to logcat every few seconds of play, which is the only
  // way to measure frames here — `dumpsys gfxinfo` cannot see an Impeller
  // app's frames — but is pure noise when the log is being read for anything
  // else.
  FrameWatch().start();

  // The version rides on the auth handshake, so the server can tell which
  // build a report came from. Read here rather than inside auth because auth
  // must not wait on a plugin channel to learn something this unimportant —
  // and an empty version is a perfectly fine thing to send.
  var appVersion = '';
  var buildNumber = '';
  var packageName = '';
  try {
    final info = await PackageInfo.fromPlatform();
    appVersion = info.version;
    buildNumber = info.buildNumber;
    packageName = info.packageName;
  } catch (error) {
    logLine('startup', 'version unavailable: $error');
  }

  // ONE BLOCK, BEFORE ANYTHING ELSE CAN SPEAK. Answers the questions a bug
  // report otherwise costs a day each: which build is this, which backend did
  // it resolve, did Firebase come up, and — the one that matters most for
  // Google sign-in — which certificate signed it.
  await writeStartupReport(
    version: appVersion,
    buildNumber: buildNumber,
    packageName: packageName,
    firebaseProjectId: DefaultFirebaseOptions.currentPlatform.projectId,
  );

  // Channel first, listeners second. A message can arrive before the first
  // frame — a player who tapped a reminder to get here has one waiting — and
  // `getInitialMessage` is the only place that one is ever delivered.
  unawaited(NotificationService.shared.start());

  runApp(
    ProviderScope(
      overrides: [appVersionProvider.overrideWithValue(appVersion)],
      child: const PourfectApp(),
    ),
  );
}

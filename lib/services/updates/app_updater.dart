/// Keeping players on a current build, without taking the game away from them.
///
/// Play's in-app update API offers two shapes and the choice is a product
/// decision, not a technical one:
///
///  * **Immediate** takes over the screen and will not let go until the update
///    installs. It is correct for a build that is genuinely broken.
///  * **Flexible** downloads in the background while the player keeps playing,
///    then needs a restart to install.
///
/// **Flexible is the default here, and that follows from the same rule as the
/// rest of the app.** Nothing may sit between a player and level 1 — the
/// campaign is fully offline and a backend outage costs a leaderboard, not a
/// level. A blocking update screen on launch is exactly the thing that rule
/// exists to prevent.
///
/// ## The download is only half of it
///
/// **A flexible update does NOT install itself.** `startFlexibleUpdate` fetches
/// the bytes and stops; `completeFlexibleUpdate` is what installs them, and it
/// restarts the app to do it. The first version of this file downloaded and
/// never completed, so Play's dialog appeared, the player accepted, the
/// download ran to completion, and then nothing happened for ever — which is
/// precisely what it looked like from the outside.
///
/// It was worse on the second launch. An update that has been downloaded and
/// not installed reports `developerTriggeredUpdateInProgress`, not
/// `updateAvailable`, so the check fell into the "nothing to do" branch and
/// went quiet. The update was sitting on the device the whole time.
///
/// **The install is never automatic.** `completeFlexibleUpdate` restarts the
/// process, and doing that unasked would close the game on somebody halfway
/// through a board. [readyToInstall] is raised instead and the app offers it;
/// the player picks the moment.
library;

import 'package:flutter/foundation.dart';
import 'package:in_app_update/in_app_update.dart';

import '../diagnostics/diagnostics.dart';

class AppUpdater {
  AppUpdater({InAppUpdateApi? api}) : _api = api ?? const _PlayUpdateApi();

  final InAppUpdateApi _api;

  /// True once an update is downloaded and waiting for the restart that
  /// installs it.
  ///
  /// A notifier rather than a flag because the download finishes on its own
  /// schedule, minutes after the check, and whatever offers the restart has to
  /// hear about it then rather than having asked at launch.
  final ValueNotifier<bool> readyToInstall = ValueNotifier(false);

  /// Looks for an update, and resumes one already part-way through.
  ///
  /// Never throws. It is called fire-and-forget from startup, so an escaping
  /// error would be an unhandled async error on the launch path — the worst
  /// possible place for one, for a feature nobody asked for.
  Future<void> check({bool forceImmediate = false}) async {
    try {
      final info = await _api.checkForUpdate();

      // ALREADY DOWNLOADED, FROM AN EARLIER RUN. This is the state a flexible
      // update sits in between accepting it and restarting, and it is reported
      // as `developerTriggeredUpdateInProgress` rather than as an available
      // update — so checking only for `updateAvailable` loses track of an
      // update that is already on the device.
      if (info.installStatus == InstallStatus.downloaded ||
          info.updateAvailability ==
              UpdateAvailability.developerTriggeredUpdateInProgress) {
        logLine('update', 'an update is downloaded and waiting for a restart');
        readyToInstall.value = true;
        return;
      }

      if (info.updateAvailability != UpdateAvailability.updateAvailable) {
        logLine('update', 'no update available');
        return;
      }

      if (forceImmediate && info.immediateUpdateAllowed) {
        logLine('update', 'starting immediate update');
        await _api.performImmediateUpdate();
        return;
      }

      if (info.flexibleUpdateAllowed) {
        logLine('update', 'asking about a flexible update');
        final result = await _api.startFlexibleUpdate();

        // The RESULT was being discarded. Declining is an ordinary answer and
        // has to be distinguishable from a download that succeeded, or the app
        // offers a restart for an update that was never fetched.
        if (result != AppUpdateResult.success) {
          logLine('update', 'not downloaded: $result');
          return;
        }

        logLine('update', 'downloaded; waiting for the player to restart');
        readyToInstall.value = true;
        return;
      }

      logLine('update', 'update available but no flow permitted');
    } catch (error) {
      // The ordinary case off Play, where the app has no update owner.
      logLine('update', 'unavailable: $error');
    }
  }

  /// Installs a downloaded update. **This restarts the app.**
  ///
  /// Only ever called from somewhere the player chose, never on a timer and
  /// never mid-level.
  Future<void> install() async {
    if (!readyToInstall.value) return;
    try {
      logLine('update', 'installing; the app will restart');
      await _api.completeFlexibleUpdate();
    } catch (error) {
      // The update stays downloaded, so the offer is worth keeping up.
      logLine('update', 'could not install: $error');
    }
  }

  void dispose() => readyToInstall.dispose();
}

/// The seam. Play's plugin is all statics, which cannot be faked, so the tests
/// drive this instead.
abstract class InAppUpdateApi {
  Future<AppUpdateInfo> checkForUpdate();
  Future<void> performImmediateUpdate();

  /// Returns whether the player accepted and the download succeeded.
  Future<AppUpdateResult> startFlexibleUpdate();
  Future<void> completeFlexibleUpdate();
}

class _PlayUpdateApi implements InAppUpdateApi {
  const _PlayUpdateApi();

  @override
  Future<AppUpdateInfo> checkForUpdate() => InAppUpdate.checkForUpdate();

  @override
  Future<void> performImmediateUpdate() => InAppUpdate.performImmediateUpdate();

  @override
  Future<AppUpdateResult> startFlexibleUpdate() =>
      InAppUpdate.startFlexibleUpdate();

  @override
  Future<void> completeFlexibleUpdate() => InAppUpdate.completeFlexibleUpdate();
}

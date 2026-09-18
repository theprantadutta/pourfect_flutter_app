/// Keeping players on a current build, without taking the game away from them.
///
/// Play's in-app update API offers two shapes and the choice is a product
/// decision, not a technical one:
///
///  * **Immediate** takes over the screen and will not let go until the update
///    installs. It is correct for a build that is genuinely broken.
///  * **Flexible** downloads in the background while the player keeps playing,
///    then offers a restart once the bytes are on the device.
///
/// **Flexible is the default here, and that follows from the same rule as the
/// rest of the app.** Nothing may sit between a player and level 1 — the
/// campaign is fully offline and a backend outage costs a leaderboard, not a
/// level. A blocking update screen on launch is exactly the thing that rule
/// exists to prevent, and it is worse than the problem it solves: the player
/// who gets it is the one who opened the game to play for four minutes on a
/// train with one bar.
///
/// [forceImmediate] is there for the build where that trade flips — a broken
/// release, or a server contract the old client can no longer satisfy.
///
/// **This does nothing unless the app came from Play.** A sideloaded or
/// `flutter run` build has no update owner, so `checkForUpdate` fails; that is
/// the ordinary case during development and is logged, not surfaced. Same
/// shape as the review prompter, and for the same reason — neither can be
/// verified on a debug build.
library;

import 'package:in_app_update/in_app_update.dart';

import '../diagnostics/diagnostics.dart';

class AppUpdater {
  AppUpdater({InAppUpdateApi? api}) : _api = api ?? const _PlayUpdateApi();

  final InAppUpdateApi _api;

  /// True once a flexible update has finished downloading and is waiting for
  /// the restart that installs it.
  bool get downloadReady => _downloadReady;
  var _downloadReady = false;

  /// Looks for an update and starts one if there is any.
  ///
  /// Never throws. It is called fire-and-forget from startup, so an escaping
  /// error would be an unhandled async error on the launch path — the worst
  /// possible place to put one, for a feature nobody asked for.
  Future<void> check({bool forceImmediate = false}) async {
    try {
      final info = await _api.checkForUpdate();

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
        logLine('update', 'starting flexible update in the background');
        await _api.startFlexibleUpdate();
        _downloadReady = true;
        logLine('update', 'flexible update downloaded; awaiting restart');
        return;
      }

      // Play said there is an update but permits neither shape. Nothing to do
      // and nothing wrong — worth one line so the silence is explained.
      logLine('update', 'update available but no flow permitted');
    } catch (error) {
      // The ordinary case off Play. Not an error the player should ever see.
      logLine('update', 'unavailable: $error');
    }
  }

  /// Installs a flexible update that has finished downloading.
  ///
  /// Restarts the app, so it is only ever called from somewhere the player
  /// chose — never automatically mid-level.
  Future<void> completeDownloadedUpdate() async {
    if (!_downloadReady) return;
    try {
      await _api.completeFlexibleUpdate();
    } catch (error) {
      logLine('update', 'could not complete update: $error');
    }
  }
}

/// The seam. Play's plugin is all statics, which cannot be faked, so the tests
/// drive this instead.
abstract class InAppUpdateApi {
  Future<AppUpdateInfo> checkForUpdate();
  Future<void> performImmediateUpdate();
  Future<void> startFlexibleUpdate();
  Future<void> completeFlexibleUpdate();
}

class _PlayUpdateApi implements InAppUpdateApi {
  const _PlayUpdateApi();

  @override
  Future<AppUpdateInfo> checkForUpdate() => InAppUpdate.checkForUpdate();

  @override
  Future<void> performImmediateUpdate() => InAppUpdate.performImmediateUpdate();

  @override
  Future<void> startFlexibleUpdate() => InAppUpdate.startFlexibleUpdate();

  @override
  Future<void> completeFlexibleUpdate() => InAppUpdate.completeFlexibleUpdate();
}

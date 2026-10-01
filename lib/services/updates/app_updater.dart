/// Keeping players on a current build.
///
/// Play's in-app update API offers two shapes:
///
///  * **Immediate**: Play takes over the screen, shows the download with real
///    progress, installs, and reopens the game. Nothing for the player to find.
///  * **Flexible**: downloads in the background, then needs a restart to
///    install, which the app has to offer and the player has to take.
///
/// ## Asked, then immediate
///
/// The app asks first, in its own words ("A new Pourfect is ready"), and
/// **Update now** runs the IMMEDIATE flow. That replaced flexible-by-default
/// because players missed the restart: the download landed, a bar offered
/// Restart for ten seconds, and most updates then sat on the device unused.
///
/// The rule this used to defend still holds: nothing blocks level 1 on its
/// own. The prompt only appears on the hub, between levels, and **Not now**
/// is always there unless the build is below the supported minimum. What
/// changed is that the restart is the player's explicit choice now, so taking
/// it for them is the point rather than a surprise.
///
/// ## The parts that are easy to lose
///
/// **An immediate update can be interrupted.** Leaving the app during Play's
/// download leaves it reported as `developerTriggeredUpdateInProgress`, and
/// Play's guidance is to resume the flow when the player returns. A flexible
/// download that finished but was never installed reports the SAME
/// availability, so the two are told apart by what this app remembers
/// starting ([UpdateMemory]), not by guessing from Play's answer.
///
/// **A flexible update does NOT install itself.** `startFlexibleUpdate` fetches
/// the bytes and stops; `completeFlexibleUpdate` installs them. Flexible is only
/// a fallback now (Play may refuse immediate), and after **Update now** it is
/// completed straight away, because the player already asked for exactly that.
/// An update an older build downloaded flexibly and never installed still
/// raises [readyToInstall], so it is not stranded.
library;

import 'package:flutter/foundation.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../diagnostics/diagnostics.dart';

/// How long **Not now** quiets the prompt for one version.
const Duration kUpdateSnooze = Duration(days: 1);

/// What **Update now** came to.
enum UpdateNowOutcome {
  /// Play is installing; the app is about to be restarted by Play.
  installing,

  /// The player backed out of Play's screen.
  declined,

  /// Play could not run either flow.
  failed,
}

class AppUpdater {
  AppUpdater({
    InAppUpdateApi? api,
    UpdateMemory? memory,
    DateTime Function()? now,
  }) : _api = api ?? const _PlayUpdateApi(),
       _memory = memory ?? PrefsUpdateMemory(),
       _now = now ?? DateTime.now;

  final InAppUpdateApi _api;
  final UpdateMemory _memory;
  final DateTime Function() _now;

  /// True while an update is available and the player should be asked.
  ///
  /// A notifier because the check finishes on its own schedule, after the
  /// hub is up, and whatever asks has to hear about it then.
  final ValueNotifier<bool> updateAvailable = ValueNotifier(false);

  /// True once a flexible update is downloaded and waiting for the restart
  /// that installs it. Only an older build's download, or the fallback path,
  /// ever leaves one here.
  final ValueNotifier<bool> readyToInstall = ValueNotifier(false);

  /// When true, the prompt may not offer **Not now**: this build is below the
  /// minimum the game still supports. Set by the caller before [check].
  bool mandatory = false;

  AppUpdateInfo? _info;

  /// True while Play's screen is up. The app RESUMES as that screen closes,
  /// and the resume check must not start a second flow on top of the first.
  bool _busy = false;

  /// Looks for an update, and resumes one already part-way through.
  ///
  /// Never throws. It is called fire-and-forget from startup and resume, so an
  /// escaping error would be an unhandled async error on the launch path.
  Future<void> check() async {
    if (_busy) return;
    try {
      final info = await _api.checkForUpdate();
      _info = info;

      // A FLEXIBLE download that finished and was never installed.
      if (info.installStatus == InstallStatus.downloaded) {
        logLine('update', 'an update is downloaded and waiting for a restart');
        readyToInstall.value = true;
        return;
      }

      if (info.updateAvailability ==
          UpdateAvailability.developerTriggeredUpdateInProgress) {
        // An IMMEDIATE update this app started, interrupted by the player
        // leaving. Play's guidance: put the flow back up when they return.
        if (await _memory.immediateStarted() && info.immediateUpdateAllowed) {
          logLine('update', 'resuming an interrupted update');
          _busy = true;
          try {
            await _runImmediate();
          } finally {
            _busy = false;
          }
          return;
        }
        // Otherwise a flexible download still running, or finished under an
        // older build that tracked nothing. Either way the bytes are Play's
        // and the restart is what is missing.
        logLine('update', 'an update is in progress; offering the restart');
        readyToInstall.value = true;
        return;
      }

      if (info.updateAvailability != UpdateAvailability.updateAvailable) {
        // Nothing pending, so anything remembered is over: the update landed
        // or was abandoned.
        await _memory.clearImmediateStarted();
        logLine('update', 'no update available');
        return;
      }

      if (!info.immediateUpdateAllowed && !info.flexibleUpdateAllowed) {
        logLine('update', 'update available but no flow permitted');
        return;
      }

      if (!mandatory &&
          await _memory.snoozed(info.availableVersionCode ?? 0, _now())) {
        logLine('update', 'update available; player said not now');
        return;
      }

      logLine('update', 'update available; asking the player');
      updateAvailable.value = true;
    } catch (error) {
      // The ordinary case off Play, where the app has no update owner.
      logLine('update', 'unavailable: $error');
    }
  }

  /// The player chose **Update now**.
  ///
  /// Immediate when Play allows it: Play shows the download and reopens the
  /// game itself. Otherwise flexible, completed as soon as it lands, because
  /// the player has already said yes to the restart.
  Future<UpdateNowOutcome> updateNow() async {
    updateAvailable.value = false;
    final info = _info;
    if (info == null || _busy) return UpdateNowOutcome.failed;

    _busy = true;
    try {
      if (info.immediateUpdateAllowed) return await _runImmediate();

      if (info.flexibleUpdateAllowed) {
        logLine('update', 'immediate refused; downloading flexibly');
        final result = await _api.startFlexibleUpdate();
        if (result == AppUpdateResult.userDeniedUpdate) {
          return UpdateNowOutcome.declined;
        }
        if (result != AppUpdateResult.success) return UpdateNowOutcome.failed;
        logLine('update', 'downloaded; installing as asked');
        await _api.completeFlexibleUpdate();
        return UpdateNowOutcome.installing;
      }
    } catch (error) {
      logLine('update', 'could not update: $error');
    } finally {
      _busy = false;
    }
    return UpdateNowOutcome.failed;
  }

  /// The player chose **Not now**: quiet for [kUpdateSnooze], for this version.
  Future<void> later() async {
    updateAvailable.value = false;
    final version = _info?.availableVersionCode ?? 0;
    await _memory.snooze(version, _now());
    logLine('update', 'not now; asking again after ${kUpdateSnooze.inHours}h');
  }

  Future<UpdateNowOutcome> _runImmediate() async {
    // Remembered BEFORE Play takes over: if the player leaves mid-download,
    // this is the only record that the in-progress update is ours to resume.
    await _memory.markImmediateStarted();
    logLine('update', 'starting immediate update');
    final result = await _api.performImmediateUpdate();
    if (result == AppUpdateResult.success) return UpdateNowOutcome.installing;

    await _memory.clearImmediateStarted();
    if (result == AppUpdateResult.userDeniedUpdate) {
      logLine('update', 'player backed out of the update');
      return UpdateNowOutcome.declined;
    }
    logLine('update', 'immediate update failed: $result');
    return UpdateNowOutcome.failed;
  }

  /// Installs a flexible update already downloaded. **This restarts the app.**
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

  void dispose() {
    updateAvailable.dispose();
    readyToInstall.dispose();
  }
}

/// What the updater has to remember across launches.
abstract class UpdateMemory {
  Future<bool> immediateStarted();
  Future<void> markImmediateStarted();
  Future<void> clearImmediateStarted();

  /// True when [versionCode] was snoozed less than [kUpdateSnooze] before [now].
  Future<bool> snoozed(int versionCode, DateTime now);
  Future<void> snooze(int versionCode, DateTime at);
}

class PrefsUpdateMemory implements UpdateMemory {
  static const _startedKey = 'pourfect.update.immediate_started.v1';
  static const _snoozeKey = 'pourfect.update.snoozed.v1';

  @override
  Future<bool> immediateStarted() async =>
      (await SharedPreferences.getInstance()).getBool(_startedKey) ?? false;

  @override
  Future<void> markImmediateStarted() async =>
      (await SharedPreferences.getInstance()).setBool(_startedKey, true);

  @override
  Future<void> clearImmediateStarted() async =>
      (await SharedPreferences.getInstance()).remove(_startedKey);

  @override
  Future<bool> snoozed(int versionCode, DateTime now) async {
    final raw = (await SharedPreferences.getInstance()).getString(_snoozeKey);
    if (raw == null) return false;
    final parts = raw.split(':');
    if (parts.length != 2 || int.tryParse(parts[0]) != versionCode) {
      return false; // a NEWER version than the one snoozed is worth asking about
    }
    final at = DateTime.fromMillisecondsSinceEpoch(int.tryParse(parts[1]) ?? 0);
    return now.difference(at) < kUpdateSnooze;
  }

  @override
  Future<void> snooze(int versionCode, DateTime at) async =>
      (await SharedPreferences.getInstance()).setString(
        _snoozeKey,
        '$versionCode:${at.millisecondsSinceEpoch}',
      );
}

/// The seam. Play's plugin is all statics, which cannot be faked, so the tests
/// drive this instead.
abstract class InAppUpdateApi {
  Future<AppUpdateInfo> checkForUpdate();

  /// Play's full-screen flow. Success means it is installing.
  Future<AppUpdateResult> performImmediateUpdate();

  /// Returns whether the player accepted and the download succeeded.
  Future<AppUpdateResult> startFlexibleUpdate();
  Future<void> completeFlexibleUpdate();
}

class _PlayUpdateApi implements InAppUpdateApi {
  const _PlayUpdateApi();

  @override
  Future<AppUpdateInfo> checkForUpdate() => InAppUpdate.checkForUpdate();

  @override
  Future<AppUpdateResult> performImmediateUpdate() =>
      InAppUpdate.performImmediateUpdate();

  @override
  Future<AppUpdateResult> startFlexibleUpdate() =>
      InAppUpdate.startFlexibleUpdate();

  @override
  Future<void> completeFlexibleUpdate() => InAppUpdate.completeFlexibleUpdate();
}

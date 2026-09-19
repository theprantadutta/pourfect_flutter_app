// Keeping players current without taking the game off them.
//
// The rules here are a product decision rather than a technical one, so they
// are what is worth pinning: flexible by default, because a blocking update
// screen is exactly what the offline-first rule exists to prevent; the install
// never automatic, because it restarts the process; and never, under any
// circumstance, an exception escaping onto the launch path.
//
// The first version of this file tested `completeDownloadedUpdate` in
// isolation and passed, while NOTHING in the app called it. So Play's dialog
// appeared, the player accepted, the download completed, and the update was
// never installed. A test that drives a method the product never reaches is
// not evidence about the product — hence `readyToInstall`, which is the signal
// the app actually consumes, being asserted on every path below.

import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:pourfect_flutter_app/services/updates/app_updater.dart';

AppUpdateInfo _info({
  required UpdateAvailability availability,
  bool immediate = true,
  bool flexible = true,
  InstallStatus installStatus = InstallStatus.unknown,
}) => AppUpdateInfo(
  updateAvailability: availability,
  immediateUpdateAllowed: immediate,
  immediateAllowedPreconditions: null,
  flexibleUpdateAllowed: flexible,
  flexibleAllowedPreconditions: null,
  availableVersionCode: 2,
  installStatus: installStatus,
  packageName: 'com.pranta.pourfect',
  clientVersionStalenessDays: null,
  updatePriority: 0,
);

class FakeUpdateApi implements InAppUpdateApi {
  FakeUpdateApi({
    this.info,
    this.throwOnCheck = false,
    this.flexibleResult = AppUpdateResult.success,
  });

  final AppUpdateInfo? info;
  final bool throwOnCheck;
  final AppUpdateResult flexibleResult;

  final calls = <String>[];

  @override
  Future<AppUpdateInfo> checkForUpdate() async {
    calls.add('check');
    // What Play throws when the app did not come from Play — the ordinary case
    // for every debug build and every sideloaded APK.
    if (throwOnCheck) throw NotOwnedByPlay();
    return info!;
  }

  @override
  Future<void> performImmediateUpdate() async => calls.add('immediate');

  @override
  Future<AppUpdateResult> startFlexibleUpdate() async {
    calls.add('flexible');
    return flexibleResult;
  }

  @override
  Future<void> completeFlexibleUpdate() async => calls.add('complete');
}

class NotOwnedByPlay implements Exception {
  @override
  String toString() => 'ERROR_APP_NOT_OWNED';
}

void main() {
  test('no update available starts nothing', () async {
    final api = FakeUpdateApi(
      info: _info(availability: UpdateAvailability.updateNotAvailable),
    );
    final updater = AppUpdater(api: api);

    await updater.check();

    expect(api.calls, ['check']);
    expect(updater.readyToInstall.value, isFalse);
  });

  test('an available update takes the FLEXIBLE path by default', () async {
    // The default is the whole point. Immediate would put a blocking screen
    // between a player and level 1, in a game whose campaign needs no network
    // at all — the one interruption the offline-first rule exists to prevent.
    final api = FakeUpdateApi(
      info: _info(availability: UpdateAvailability.updateAvailable),
    );

    await AppUpdater(api: api).check();

    expect(api.calls, ['check', 'flexible']);
    expect(api.calls, isNot(contains('immediate')));
  });

  test('a completed download RAISES the restart offer', () async {
    // THE BUG THIS FILE EXISTS FOR. Downloading is only half of a flexible
    // update; without something offering the restart, the bytes sit on the
    // device for ever and the app looks like it did nothing at all.
    final api = FakeUpdateApi(
      info: _info(availability: UpdateAvailability.updateAvailable),
    );
    final updater = AppUpdater(api: api);

    var offered = false;
    updater.readyToInstall.addListener(() => offered = true);

    await updater.check();

    expect(updater.readyToInstall.value, isTrue);
    expect(offered, isTrue, reason: 'nothing would ever offer the restart');
  });

  test('an update downloaded on an EARLIER run is picked up again', () async {
    // The second half of the same bug. Between accepting an update and
    // restarting, Play reports `developerTriggeredUpdateInProgress` rather
    // than `updateAvailable` — so a check that only looks for the latter goes
    // quiet about an update already sitting on the device, which is exactly
    // what happened on the next launch.
    final api = FakeUpdateApi(
      info: _info(
        availability: UpdateAvailability.developerTriggeredUpdateInProgress,
      ),
    );
    final updater = AppUpdater(api: api);

    await updater.check();

    expect(updater.readyToInstall.value, isTrue);
    // Nothing is re-downloaded; it is already here.
    expect(api.calls, ['check']);
  });

  test('a downloaded install status is picked up too', () async {
    final api = FakeUpdateApi(
      info: _info(
        availability: UpdateAvailability.updateNotAvailable,
        installStatus: InstallStatus.downloaded,
      ),
    );
    final updater = AppUpdater(api: api);

    await updater.check();

    expect(updater.readyToInstall.value, isTrue);
  });

  test('DECLINING the update offers no restart', () async {
    // `startFlexibleUpdate` reports whether the player accepted, and that
    // result was being discarded — so declining still raised the offer, for an
    // update that had never been fetched.
    final api = FakeUpdateApi(
      info: _info(availability: UpdateAvailability.updateAvailable),
      flexibleResult: AppUpdateResult.userDeniedUpdate,
    );
    final updater = AppUpdater(api: api);

    await updater.check();

    expect(updater.readyToInstall.value, isFalse);
    expect(api.calls, ['check', 'flexible']);
  });

  test('a failed download offers no restart', () async {
    final api = FakeUpdateApi(
      info: _info(availability: UpdateAvailability.updateAvailable),
      flexibleResult: AppUpdateResult.inAppUpdateFailed,
    );
    final updater = AppUpdater(api: api);

    await updater.check();

    expect(updater.readyToInstall.value, isFalse);
  });

  test('forceImmediate is honoured when Play permits it', () async {
    final api = FakeUpdateApi(
      info: _info(availability: UpdateAvailability.updateAvailable),
    );

    await AppUpdater(api: api).check(forceImmediate: true);

    expect(api.calls, ['check', 'immediate']);
  });

  test('forceImmediate falls back to flexible when immediate is refused',
      () async {
    // Play decides what it will allow. Asking for immediate and getting no
    // update at all would be the worst of both.
    final api = FakeUpdateApi(
      info: _info(
        availability: UpdateAvailability.updateAvailable,
        immediate: false,
      ),
    );

    await AppUpdater(api: api).check(forceImmediate: true);

    expect(api.calls, ['check', 'flexible']);
  });

  test('neither flow permitted is survivable', () async {
    final api = FakeUpdateApi(
      info: _info(
        availability: UpdateAvailability.updateAvailable,
        immediate: false,
        flexible: false,
      ),
    );

    await AppUpdater(api: api).check();

    expect(api.calls, ['check']);
  });

  test('NOT being installed from Play never throws', () async {
    // `check` is called fire-and-forget from the first frame, so an escaping
    // error is an unhandled async error on the launch path — and off Play this
    // throws on every launch, which is every debug build.
    final api = FakeUpdateApi(throwOnCheck: true);

    await expectLater(AppUpdater(api: api).check(), completes);
    expect(api.calls, ['check']);
  });

  test('installing does nothing when nothing is waiting', () async {
    final api = FakeUpdateApi(
      info: _info(availability: UpdateAvailability.updateNotAvailable),
    );
    final updater = AppUpdater(api: api);

    await updater.check();
    await updater.install();

    // Restarting to install an update that was never downloaded would close
    // the game under somebody mid-level for nothing.
    expect(api.calls, isNot(contains('complete')));
  });

  test('installing completes a download that IS waiting', () async {
    final api = FakeUpdateApi(
      info: _info(availability: UpdateAvailability.updateAvailable),
    );
    final updater = AppUpdater(api: api);

    await updater.check();
    await updater.install();

    expect(api.calls, ['check', 'flexible', 'complete']);
  });
}

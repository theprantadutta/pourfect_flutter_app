// Keeping players current without taking the game off them.
//
// The rules here are a product decision rather than a technical one, so they
// are what is worth pinning: flexible by default, because a blocking update
// screen is exactly the thing the offline-first rule exists to prevent; and
// never, under any circumstance, an exception escaping onto the launch path.

import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:pourfect_flutter_app/services/updates/app_updater.dart';

AppUpdateInfo _info({
  required UpdateAvailability availability,
  bool immediate = true,
  bool flexible = true,
}) => AppUpdateInfo(
  updateAvailability: availability,
  immediateUpdateAllowed: immediate,
  immediateAllowedPreconditions: null,
  flexibleUpdateAllowed: flexible,
  flexibleAllowedPreconditions: null,
  availableVersionCode: 2,
  installStatus: InstallStatus.unknown,
  packageName: 'com.pranta.pourfect',
  clientVersionStalenessDays: null,
  updatePriority: 0,
);

class FakeUpdateApi implements InAppUpdateApi {
  FakeUpdateApi({this.info, this.throwOnCheck = false});

  final AppUpdateInfo? info;
  final bool throwOnCheck;

  final calls = <String>[];

  @override
  Future<AppUpdateInfo> checkForUpdate() async {
    calls.add('check');
    // What Play throws when the app did not come from Play — the ordinary
    // case for every debug build and every sideloaded APK.
    if (throwOnCheck) throw PlatformExceptionLike();
    return info!;
  }

  @override
  Future<void> performImmediateUpdate() async => calls.add('immediate');

  @override
  Future<void> startFlexibleUpdate() async => calls.add('flexible');

  @override
  Future<void> completeFlexibleUpdate() async => calls.add('complete');
}

/// Stands in for a PlatformException without importing services.
class PlatformExceptionLike implements Exception {
  @override
  String toString() => 'ERROR_APP_NOT_OWNED';
}

void main() {
  test('no update available starts nothing', () async {
    final api = FakeUpdateApi(
      info: _info(availability: UpdateAvailability.updateNotAvailable),
    );

    await AppUpdater(api: api).check();

    expect(api.calls, ['check']);
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
    // THE CASE THAT MATTERS MOST. `check` is called fire-and-forget from the
    // first frame, so an escaping error is an unhandled async error on the
    // launch path — and off Play this throws on every single launch, which is
    // every debug build anybody develops against.
    final api = FakeUpdateApi(throwOnCheck: true);

    await expectLater(AppUpdater(api: api).check(), completes);
    expect(api.calls, ['check']);
  });

  test('completing does nothing when no download is waiting', () async {
    final api = FakeUpdateApi(
      info: _info(availability: UpdateAvailability.updateNotAvailable),
    );
    final updater = AppUpdater(api: api);

    await updater.check();
    await updater.completeDownloadedUpdate();

    // Restarting the app to install an update that was never downloaded would
    // close the game under somebody mid-level.
    expect(api.calls, isNot(contains('complete')));
  });

  test('completing installs a download that IS waiting', () async {
    final api = FakeUpdateApi(
      info: _info(availability: UpdateAvailability.updateAvailable),
    );
    final updater = AppUpdater(api: api);

    await updater.check();
    expect(updater.downloadReady, isTrue);

    await updater.completeDownloadedUpdate();

    expect(api.calls, ['check', 'flexible', 'complete']);
  });
}

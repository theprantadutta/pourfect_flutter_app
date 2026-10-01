// Keeping players current: ask on the hub, then let Play do the rest.
//
// The rules worth pinning are the product ones. An available update is ASKED
// about, never started unasked. Update now runs Play's immediate flow, so the
// player never has to find a restart. Not now is honored for a day, for that
// version only. An update interrupted by leaving the app is resumed. A
// flexible download from an older build is still installed rather than
// stranded. And nothing ever escapes onto the launch path.
//
// History worth keeping: the first version of the flexible flow had a test
// that drove the install method directly and passed while nothing in the app
// called it. Every path below asserts the notifier the shell actually listens
// to.

import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:pourfect_flutter_app/services/updates/app_updater.dart';

AppUpdateInfo _info({
  required UpdateAvailability availability,
  bool immediate = true,
  bool flexible = true,
  InstallStatus installStatus = InstallStatus.unknown,
  int versionCode = 12,
}) => AppUpdateInfo(
  updateAvailability: availability,
  immediateUpdateAllowed: immediate,
  immediateAllowedPreconditions: null,
  flexibleUpdateAllowed: flexible,
  flexibleAllowedPreconditions: null,
  availableVersionCode: versionCode,
  installStatus: installStatus,
  packageName: 'com.pranta.pourfect',
  clientVersionStalenessDays: null,
  updatePriority: 0,
);

class FakeUpdateApi implements InAppUpdateApi {
  FakeUpdateApi({
    this.info,
    this.throwOnCheck = false,
    this.immediateResult = AppUpdateResult.success,
    this.flexibleResult = AppUpdateResult.success,
  });

  AppUpdateInfo? info;
  final bool throwOnCheck;
  AppUpdateResult immediateResult;
  final AppUpdateResult flexibleResult;

  final calls = <String>[];

  @override
  Future<AppUpdateInfo> checkForUpdate() async {
    calls.add('check');
    // What Play throws when the app did not come from Play: every debug
    // build and every sideloaded APK.
    if (throwOnCheck) throw NotOwnedByPlay();
    return info!;
  }

  @override
  Future<AppUpdateResult> performImmediateUpdate() async {
    calls.add('immediate');
    return immediateResult;
  }

  @override
  Future<AppUpdateResult> startFlexibleUpdate() async {
    calls.add('flexible');
    return flexibleResult;
  }

  @override
  Future<void> completeFlexibleUpdate() async => calls.add('complete');
}

class MemoryUpdateMemory implements UpdateMemory {
  bool started = false;
  (int, DateTime)? snoozedAt;

  @override
  Future<bool> immediateStarted() async => started;

  @override
  Future<void> markImmediateStarted() async => started = true;

  @override
  Future<void> clearImmediateStarted() async => started = false;

  @override
  Future<bool> snoozed(int versionCode, DateTime now) async {
    final s = snoozedAt;
    return s != null &&
        s.$1 == versionCode &&
        now.difference(s.$2) < kUpdateSnooze;
  }

  @override
  Future<void> snooze(int versionCode, DateTime at) async =>
      snoozedAt = (versionCode, at);
}

class NotOwnedByPlay implements Exception {
  @override
  String toString() => 'ERROR_APP_NOT_OWNED';
}

void main() {
  var now = DateTime(2026, 10, 1, 12);

  ({AppUpdater updater, FakeUpdateApi api, MemoryUpdateMemory memory}) make(
    AppUpdateInfo info, {
    AppUpdateResult immediateResult = AppUpdateResult.success,
    AppUpdateResult flexibleResult = AppUpdateResult.success,
    MemoryUpdateMemory? memory,
  }) {
    final api = FakeUpdateApi(
      info: info,
      immediateResult: immediateResult,
      flexibleResult: flexibleResult,
    );
    final mem = memory ?? MemoryUpdateMemory();
    return (
      updater: AppUpdater(api: api, memory: mem, now: () => now),
      api: api,
      memory: mem,
    );
  }

  setUp(() => now = DateTime(2026, 10, 1, 12));

  test('no update available asks nothing and starts nothing', () async {
    final h = make(_info(availability: UpdateAvailability.updateNotAvailable));
    await h.updater.check();

    expect(h.api.calls, ['check']);
    expect(h.updater.updateAvailable.value, isFalse);
    expect(h.updater.readyToInstall.value, isFalse);
  });

  test('an available update is ASKED about, never started unasked', () async {
    final h = make(_info(availability: UpdateAvailability.updateAvailable));
    await h.updater.check();

    expect(h.updater.updateAvailable.value, isTrue);
    expect(h.api.calls, ['check']);
  });

  test(
    'Update now runs the immediate flow, so nobody has to find a restart',
    () async {
      final h = make(_info(availability: UpdateAvailability.updateAvailable));
      await h.updater.check();

      expect(await h.updater.updateNow(), UpdateNowOutcome.installing);
      expect(h.api.calls, ['check', 'immediate']);
      expect(h.updater.updateAvailable.value, isFalse);
    },
  );

  test(
    'when Play refuses immediate, flexible is downloaded AND installed',
    () async {
      // The player already said yes to the restart, so there is nothing left to
      // offer them afterwards: the old flow's missed Restart bar was the whole
      // reason for this change.
      final h = make(
        _info(
          availability: UpdateAvailability.updateAvailable,
          immediate: false,
        ),
      );
      await h.updater.check();

      expect(await h.updater.updateNow(), UpdateNowOutcome.installing);
      expect(h.api.calls, ['check', 'flexible', 'complete']);
    },
  );

  test('backing out of Play\'s screen is reported as declined', () async {
    final h = make(
      _info(availability: UpdateAvailability.updateAvailable),
      immediateResult: AppUpdateResult.userDeniedUpdate,
    );
    await h.updater.check();

    expect(await h.updater.updateNow(), UpdateNowOutcome.declined);
    // Nothing in progress any more, so a later check must not "resume" it.
    expect(h.memory.started, isFalse);
  });

  group('Not now', () {
    test('quiets the same version for a day', () async {
      final h = make(_info(availability: UpdateAvailability.updateAvailable));
      await h.updater.check();
      await h.updater.later();

      h.updater.updateAvailable.value = false;
      now = now.add(const Duration(hours: 23));
      await h.updater.check();
      expect(h.updater.updateAvailable.value, isFalse);

      now = now.add(const Duration(hours: 2));
      await h.updater.check();
      expect(h.updater.updateAvailable.value, isTrue);
    });

    test('never silences a NEWER version', () async {
      final h = make(
        _info(
          availability: UpdateAvailability.updateAvailable,
          versionCode: 12,
        ),
      );
      await h.updater.check();
      await h.updater.later();

      h.api.info = _info(
        availability: UpdateAvailability.updateAvailable,
        versionCode: 13,
      );
      await h.updater.check();
      expect(h.updater.updateAvailable.value, isTrue);
    });

    test('is not honored for a build below the supported minimum', () async {
      final h = make(_info(availability: UpdateAvailability.updateAvailable));
      await h.updater.check();
      await h.updater.later();

      h.updater.mandatory = true;
      await h.updater.check();
      expect(h.updater.updateAvailable.value, isTrue);
    });
  });

  test('an update interrupted by leaving the app is RESUMED', () async {
    // Play's guidance for immediate updates: if the player leaves mid-flow,
    // put it back up when they return. The flag is what says it was ours.
    final memory = MemoryUpdateMemory()..started = true;
    final h = make(
      _info(
        availability: UpdateAvailability.developerTriggeredUpdateInProgress,
      ),
      memory: memory,
    );
    await h.updater.check();

    expect(h.api.calls, ['check', 'immediate']);
    expect(h.updater.readyToInstall.value, isFalse);
  });

  test(
    'a flexible download from an older build gets its restart offered',
    () async {
      // Same availability as an interrupted immediate update, but this app
      // never started one, so it is an older build's download waiting.
      final h = make(
        _info(
          availability: UpdateAvailability.developerTriggeredUpdateInProgress,
        ),
      );
      await h.updater.check();

      expect(h.updater.readyToInstall.value, isTrue);
      expect(h.api.calls, ['check']);
    },
  );

  test('a downloaded install status is offered for restart', () async {
    final h = make(
      _info(
        availability: UpdateAvailability.updateNotAvailable,
        installStatus: InstallStatus.downloaded,
      ),
    );
    await h.updater.check();

    expect(h.updater.readyToInstall.value, isTrue);
    await h.updater.install();
    expect(h.api.calls, ['check', 'complete']);
  });

  test('a finished update clears the in-progress memory', () async {
    final memory = MemoryUpdateMemory()..started = true;
    final h = make(
      _info(availability: UpdateAvailability.updateNotAvailable),
      memory: memory,
    );
    await h.updater.check();
    expect(memory.started, isFalse);
  });

  test('a check while Play\'s screen is up starts nothing', () async {
    // The app RESUMES as Play's screen closes; a resume check landing then
    // must not open a second flow on top of the first.
    final h = make(_info(availability: UpdateAvailability.updateAvailable));
    await h.updater.check();

    final running = h.updater.updateNow();
    await h.updater.check();
    await running;

    expect(h.api.calls.where((c) => c == 'immediate'), hasLength(1));
  });

  test('off Play, nothing escapes onto the launch path', () async {
    final api = FakeUpdateApi(throwOnCheck: true);
    final updater = AppUpdater(api: api, memory: MemoryUpdateMemory());

    await expectLater(updater.check(), completes);
    expect(updater.updateAvailable.value, isFalse);
  });
}

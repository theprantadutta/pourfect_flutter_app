// Smooth motion: stored with the other settings, Auto by default, passed to
// the display whenever it changes — and Auto backs off on a phone that cannot
// draw frames as fast as its screen can show them.

import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pourfect_flutter_app/services/display/display_rate_service.dart';
import 'package:pourfect_flutter_app/state/frame_pace.dart';
import 'package:pourfect_flutter_app/state/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Records every request and answers like a 60/90 Hz panel.
class FakeDisplayRateService implements DisplayRateService {
  final requests = <bool>[];

  @override
  Future<DisplayRate> apply({required bool high}) async {
    requests.add(high);
    return DisplayRate(
      current: high ? 90 : 60,
      max: 90,
      supported: const [60, 90],
      lowPower: false,
    );
  }

  @override
  Future<DisplayRate> read() async => DisplayRate.unknown;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('the setting', () {
    late FakeDisplayRateService display;

    ProviderContainer make() {
      display = FakeDisplayRateService();
      final c = ProviderContainer(
        overrides: [displayRateServiceProvider.overrideWithValue(display)],
      );
      addTearDown(c.dispose);
      return c;
    }

    Future<void> settle() async {
      for (var i = 0; i < 4; i++) {
        await Future<void>.delayed(Duration.zero);
      }
    }

    test('Auto by default, including settings from before it existed', () {
      expect(const Settings().smoothMotion, SmoothMotion.auto);
      expect(
        Settings.fromJson({'haptics': true, 'sound': true}).smoothMotion,
        SmoothMotion.auto,
      );
      expect(
        Settings.fromJson({'smooth_motion': 'nonsense'}).smoothMotion,
        SmoothMotion.auto,
      );
    });

    test('the choice round-trips through the stored settings', () async {
      SharedPreferences.setMockInitialValues({});
      final c = make();
      c.read(settingsProvider);
      c.read(settingsProvider.notifier).setSmoothMotion(SmoothMotion.max);
      await settle();

      final prefs = await SharedPreferences.getInstance();
      final stored =
          jsonDecode(prefs.getString('pourfect.settings.v1')!)
              as Map<String, Object?>;
      expect(stored['smooth_motion'], 'max');
      expect(Settings.fromJson(stored).smoothMotion, SmoothMotion.max);
    });

    test('Auto starts at the fast rate', () async {
      SharedPreferences.setMockInitialValues({});
      final c = make();
      c.listen(displayRateProvider, (_, _) {});
      await settle();

      expect(display.requests, [true]);
      expect(c.read(displayRateProvider).rate.current, 90);
      expect(c.read(displayRateProvider).autoStepdown, isFalse);
    });

    test('60 Hz hands the rate back to the system', () async {
      SharedPreferences.setMockInitialValues({});
      final c = make();
      c.listen(displayRateProvider, (_, _) {});
      await settle();

      c.read(settingsProvider.notifier).setSmoothMotion(SmoothMotion.standard);
      await settle();

      expect(display.requests.last, isFalse);
      expect(c.read(displayRateProvider).rate.current, 60);
    });

    test('a remembered step-down keeps Auto at the standard rate', () async {
      SharedPreferences.setMockInitialValues({
        'pourfect.display.auto_stepdown.v1': true,
      });
      final c = make();
      c.listen(displayRateProvider, (_, _) {});
      await settle();

      expect(display.requests, [false]);
      expect(c.read(displayRateProvider).autoStepdown, isTrue);
    });

    test('Max ignores a remembered step-down', () async {
      SharedPreferences.setMockInitialValues({
        'pourfect.display.auto_stepdown.v1': true,
        'pourfect.settings.v1': jsonEncode({'smooth_motion': 'max'}),
      });
      final c = make();
      c.listen(displayRateProvider, (_, _) {});
      await settle();

      expect(display.requests.last, isTrue);
    });

    test('choosing Auto again forgets the step-down and retries', () async {
      SharedPreferences.setMockInitialValues({
        'pourfect.display.auto_stepdown.v1': true,
      });
      final c = make();
      c.listen(displayRateProvider, (_, _) {});
      await settle();

      await c.read(displayRateProvider.notifier).retryAuto();

      expect(display.requests.last, isTrue);
      expect(c.read(displayRateProvider).autoStepdown, isFalse);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('pourfect.display.auto_stepdown.v1'), isNull);
    });

    test('reapply re-asks for whatever the setting says', () async {
      SharedPreferences.setMockInitialValues({});
      final c = make();
      c.listen(displayRateProvider, (_, _) {});
      await settle();
      final before = display.requests.length;

      await c.read(displayRateProvider.notifier).reapply();
      expect(display.requests.length, before + 1);
      expect(display.requests.last, isTrue);
    });
  });

  group('FramePaceJudge', () {
    const budget = 11111; // 90 Hz

    void feed(FramePaceJudge j, int frames, {required int missEvery}) {
      for (var i = 0; i < frames; i++) {
        final miss = missEvery > 0 && i % missEvery == 0;
        j.add(
          buildMicros: miss ? 14000 : 5000,
          rasterMicros: 4000,
          budgetMicros: budget,
        );
      }
    }

    test('a phone that keeps up is left at the fast rate', () {
      final j = FramePaceJudge();
      feed(j, 1800, missEvery: 50); // 2% late
      expect(j.tooSlow, isFalse);
    });

    test('one bad window is not enough — a shader compile is a moment', () {
      final j = FramePaceJudge();
      feed(j, 180, missEvery: 4); // 25% late, once
      feed(j, 180, missEvery: 0);
      feed(j, 180, missEvery: 4);
      expect(j.tooSlow, isFalse);
    });

    test('two bad windows in a row steps it down', () {
      final j = FramePaceJudge();
      feed(j, 360, missEvery: 5); // 20% late, sustained
      expect(j.tooSlow, isTrue);
    });

    test('raster overruns count as much as build overruns', () {
      final j = FramePaceJudge();
      for (var i = 0; i < 360; i++) {
        j.add(
          buildMicros: 3000,
          rasterMicros: i.isEven ? 12000 : 4000,
          budgetMicros: budget,
        );
      }
      expect(j.tooSlow, isTrue);
    });

    test('reports the tipping frame exactly once', () {
      final j = FramePaceJudge();
      var tips = 0;
      for (var i = 0; i < 720; i++) {
        if (j.add(
          buildMicros: 20000,
          rasterMicros: 4000,
          budgetMicros: budget,
        )) {
          tips++;
        }
      }
      expect(tips, 1);
    });
  });
}

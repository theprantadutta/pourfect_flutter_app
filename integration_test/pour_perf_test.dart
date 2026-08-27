// On-device frame timing for the pour animation.
//
//   flutter drive \
//     --driver=test_driver/perf_driver.dart \
//     --target=integration_test/pour_perf_test.dart \
//     --profile
//
// Writes build/pour_timeline.timeline_summary.json.
//
// This exists because `adb shell dumpsys gfxinfo` reports ZERO frames for this
// app: Flutter renders through Impeller onto its own surface and never touches
// Android's HWUI pipeline, so the usual tool is blind to it. A timeline summary
// captured on the device is the only honest number.
//
// The pour is the right thing to measure. It is the animation a player triggers
// thousands of times a session, it runs several balls with staggered springs
// and a per-frame Bézier, and it is the only place the board rebuilds every
// frame.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:pourfect_flutter_app/app.dart';
import 'package:pourfect_flutter_app/engine/rules.dart';
import 'package:pourfect_flutter_app/services/analytics/analytics_service.dart';
import 'package:pourfect_flutter_app/services/audio/audio_service.dart';
import 'package:pourfect_flutter_app/state/providers.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Real frames, driven by the device's own vsync rather than the test
  // scheduler — otherwise the timings describe a simulation, not a phone.
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets('pour animation holds frame budget', (tester) async {
    // Analytics and audio are stubbed out: neither is part of the render path,
    // and letting them fire would measure Firebase's startup rather than ours.
    final container = ProviderContainer(
      overrides: [
        analyticsServiceProvider.overrideWithValue(NoopAnalyticsService()),
        audioServiceProvider.overrideWithValue(const NoopAudioService()),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const PourfectApp(),
      ),
    );
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // Semantics are off by default in tests, so a semantics finder would match
    // nothing at all rather than failing usefully.
    final semantics = tester.ensureSemantics();
    addTearDown(semantics.dispose);

    // Open a level from the map, so the route transition is on the timeline too.
    final level1 = find.bySemanticsLabel(RegExp(r'^Level 1,'));
    expect(level1, findsOneWidget);
    await tester.tap(level1);
    await tester.pumpAndSettle(const Duration(seconds: 2));

    final controller = container.read(gameControllerProvider.notifier);
    expect(container.read(gameControllerProvider), isNotNull);

    await binding.watchPerformance(() async {
      // Play and undo repeatedly. Undo is what lets one level generate a long
      // run of pours without ever reaching a win state and stopping.
      for (var round = 0; round < 12; round++) {
        final state = container.read(gameControllerProvider);
        if (state == null) break;

        final moves = usefulMoves(state.board);
        if (moves.isEmpty) break;

        // Prefer a move that carries several balls: that is the expensive case,
        // with staggered springs and multiple sprites in flight at once.
        final move = moves.reduce(
          (a, b) =>
              ballsThatWouldMove(state.board, b.from, b.to) >
                  ballsThatWouldMove(state.board, a.from, a.to)
              ? b
              : a,
        );

        controller.tapTube(move.from);
        await tester.pump(const Duration(milliseconds: 16));
        controller.tapTube(move.to);

        // Pump through the whole pour at frame cadence rather than settling,
        // so every frame of the animation lands on the timeline.
        for (var frame = 0; frame < 40; frame++) {
          await tester.pump(const Duration(milliseconds: 16));
        }

        controller.undo();
        for (var frame = 0; frame < 12; frame++) {
          await tester.pump(const Duration(milliseconds: 16));
        }
      }
    }, reportKey: 'pour_timeline');
  });
}

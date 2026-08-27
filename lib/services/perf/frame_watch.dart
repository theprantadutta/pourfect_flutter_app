/// Frame timing, measured from inside the app.
///
/// `adb shell dumpsys gfxinfo` reports ZERO frames for this app: Flutter renders
/// through Impeller onto its own surface and never touches Android's HWUI
/// pipeline, so the usual Android tool is blind to it.
///
/// The documented alternative — `integration_test` + `flutter drive` with a
/// timeline summary — needs the on-device test to reach the host VM service,
/// which fails in this environment with a connection refused. That harness is
/// still in the repo and is the right tool where the plumbing works.
///
/// This is the fallback that always works: Flutter itself hands every frame's
/// build and raster time to `addTimingsCallback`, so the app can measure
/// itself and print the result. No driver, no VM service, no host connection —
/// just `adb logcat`.
///
/// Build and raster are reported SEPARATELY because they fail for different
/// reasons and have different fixes. Build time is Dart work: too much
/// recomputation per frame. Raster time is GPU work: shaders, saveLayers,
/// overdraw — which is why `BackdropFilter` is banned in this codebase.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

/// One frame's budget at 60Hz. A frame whose build OR raster exceeds this is
/// a dropped frame as far as the player's eye is concerned.
const Duration kFrameBudget = Duration(microseconds: 16667);

class FrameWatch {
  final List<int> _build = [];
  final List<int> _raster = [];
  TimingsCallback? _callback;

  /// Frames to gather before reporting and resetting.
  final int window;

  FrameWatch({this.window = 240});

  /// Starts watching. No-op in release: the callback costs a little per frame
  /// and players should never pay for our instrumentation.
  void start() {
    if (kReleaseMode || _callback != null) return;

    _callback = (List<FrameTiming> timings) {
      for (final t in timings) {
        _build.add(t.buildDuration.inMicroseconds);
        _raster.add(t.rasterDuration.inMicroseconds);
      }
      if (_build.length >= window) report(reset: true);
    };
    SchedulerBinding.instance.addTimingsCallback(_callback!);
  }

  void stop() {
    final callback = _callback;
    if (callback == null) return;
    SchedulerBinding.instance.removeTimingsCallback(callback);
    _callback = null;
  }

  /// Prints percentiles and the jank count for the frames gathered so far.
  void report({bool reset = false}) {
    if (_build.isEmpty) return;

    final build = [..._build]..sort();
    final raster = [..._raster]..sort();
    final budget = kFrameBudget.inMicroseconds;

    int pct(List<int> xs, double q) => xs[(q * (xs.length - 1)).round()];
    String ms(int micros) => (micros / 1000).toStringAsFixed(2);
    int over(List<int> xs) => xs.where((v) => v > budget).length;

    final janky = <int>{
      for (var i = 0; i < _build.length; i++)
        if (_build[i] > budget || _raster[i] > budget) i,
    }.length;

    debugPrint(
      '[frames] n=${build.length}  '
      'build p50 ${ms(pct(build, .5))}ms p95 ${ms(pct(build, .95))}ms '
      'max ${ms(build.last)}ms over=${over(build)}  |  '
      'raster p50 ${ms(pct(raster, .5))}ms p95 ${ms(pct(raster, .95))}ms '
      'max ${ms(raster.last)}ms over=${over(raster)}  |  '
      'janky $janky/${build.length} '
      '(${(janky / build.length * 100).toStringAsFixed(1)}%)',
    );

    if (reset) {
      _build.clear();
      _raster.clear();
    }
  }
}

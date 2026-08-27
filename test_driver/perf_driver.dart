// Writes the timeline summary captured by integration_test/pour_perf_test.dart.
//
// Reports both halves of the budget, because they fail for different reasons
// and have different fixes:
//
//   * BUILD time is Dart work — widget rebuilds, layout, our own per-frame
//     maths. Blown budget here means too much recomputation per frame.
//   * RASTER time is GPU work — shaders, blurs, saveLayers, overdraw. Blown
//     budget here is why `BackdropFilter` is banned from this codebase.

import 'package:flutter_driver/flutter_driver.dart' as driver;
import 'package:integration_test/integration_test_driver.dart';

Future<void> main() => integrationDriver(
  responseDataCallback: (data) async {
    if (data == null) return;
    final summary = driver.TimelineSummary.summarize(
      driver.Timeline.fromJson(data['pour_timeline'] as Map<String, dynamic>),
    );
    await summary.writeTimelineToFile(
      'pour_timeline',
      pretty: true,
      includeSummary: true,
    );
  },
);

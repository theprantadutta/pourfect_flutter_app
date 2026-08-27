/// Loads the baked campaign out of the bundled asset.
library;

import 'package:flutter/services.dart' show rootBundle;

import '../engine/level_curve.dart';
import '../engine/level_set.dart';

/// Reads `assets/levels/levels.bin`.
///
/// The whole campaign is ~7.8 KB, so it is decoded once at startup and held —
/// paging levels in individually would add failure modes and latency to save
/// nothing measurable.
class LevelRepository {
  static const assetPath = 'assets/levels/levels.bin';

  LevelSet? _cache;

  Future<LevelSet> load() async {
    final cached = _cache;
    if (cached != null) return cached;

    final data = await rootBundle.load(assetPath);
    final decoded = LevelSetCodec.decode(data.buffer.asUint8List());
    _cache = decoded;
    return decoded;
  }
}

/// Display name of a campaign band.
///
/// Lives in `state/` because `level_curve.dart` is engine LOGIC and `ui/` may
/// not import it. This one-line accessor is the seam: the names stay defined
/// once, next to the curve they describe, and the UI reaches them through the
/// state layer like everything else.
String bandNameFor(int bandIndex) => kCampaignBands[bandIndex].name;

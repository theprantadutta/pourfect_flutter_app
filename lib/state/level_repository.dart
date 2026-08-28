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

/// A campaign band, in the shape the UI needs it.
///
/// `level_curve.dart` is engine LOGIC and `ui/` may not import it, so the band
/// definitions are projected here. This is the seam: the curve stays defined
/// once, next to the generator that builds it.
class BandInfo {
  final int index;
  final String name;
  final int firstLevel;
  final int lastLevel;

  /// Human-readable board shape, e.g. "5–7 colors · 2 spare".
  final String shape;

  const BandInfo({
    required this.index,
    required this.name,
    required this.firstLevel,
    required this.lastLevel,
    required this.shape,
  });

  int get length => lastLevel - firstLevel + 1;

  bool contains(int levelId) => levelId >= firstLevel && levelId <= lastLevel;
}

/// Every band, in campaign order.
List<BandInfo> campaignBands() => [
  for (var i = 0; i < kCampaignBands.length; i++)
    BandInfo(
      index: i,
      name: kCampaignBands[i].name,
      firstLevel: kCampaignBands[i].firstLevel,
      lastLevel: kCampaignBands[i].lastLevel,
      shape: _shapeLabel(kCampaignBands[i]),
    ),
];

String _shapeLabel(CampaignBand band) {
  final colors = band.tiers.map((t) => t.colorCount).toList()..sort();
  final low = colors.first;
  final high = colors.last;
  final spare = band.tiers
      .map((t) => t.emptyTubeCount)
      .reduce((a, b) => a < b ? a : b);
  final maxSpare = band.tiers
      .map((t) => t.emptyTubeCount)
      .reduce((a, b) => a > b ? a : b);

  final colorPart = low == high ? '$low colors' : '$low\u2013$high colors';
  final sparePart = spare == maxSpare
      ? '$spare spare'
      : '$spare\u2013$maxSpare spare';
  return '$colorPart \u00b7 $sparePart';
}

/// True when [levelId] is the last level of its band — one of the moments the
/// win sequence runs at full length.
bool isBandFinalLevel(int levelId) {
  final band = bandForLevel(levelId);
  return band != null && band.lastLevel == levelId;
}

/// Display name of a campaign band.
String bandNameForLevel(int levelId) => bandForLevel(levelId)?.name ?? '';

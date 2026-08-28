/// The shape of the 150-level campaign, and the algorithm that builds it.
///
/// ENGINE LOGIC — `ui/` must not import this file. Runs at BUILD TIME only,
/// from `tool/generate_levels.dart`; nothing here ever executes on a device.
library;

import 'dart:math';

import 'difficulty.dart';
import 'generator.dart';
import 'level.dart';
import 'level_set.dart';
import 'solver.dart';

/// Seed for the shipped campaign. CHANGING THIS RESHUFFLES EVERY LEVEL.
///
/// The baked `levels.bin` is committed and must be reproducible byte-for-byte
/// from this constant. Player progress is keyed on level id, and `minMoves`
/// feeds both the star rating and the server's anti-cheat floor — so a silent
/// reshuffle would repoint every saved star at a board the player never saw.
/// If you must change it, bump [kLevelSetVersion] in the same commit.
const int kDefaultCampaignSeed = 20260827;

/// Seed for the daily-challenge pool. Independent of the campaign seed so the
/// two sets can be regenerated separately.
const int kDefaultDailySeed = 71042;

/// CONTENT version of the shipped campaign. See [LevelSet.levelSetVersion].
const int kLevelSetVersion = 1;

/// Levels in the campaign.
const int kCampaignLength = 150;

/// Days of daily challenges to pre-generate.
const int kDailyPoolSize = 365;

/// A breather must score at least this much BELOW the running average of the
/// levels before it. 0.75 means "at least 25% easier".
///
/// This is a ratio on the CALIBRATED score, which is why `difficulty.dart`
/// calibrates at all — the same ratio on the raw blend would demand a
/// 3-color board and turn every breather into a jarring size collapse.
const double kBreatherReliefFactor = 0.75;

/// A breather must ALSO score no lower than this fraction of the running
/// average. 0.60 means "at most 40% easier".
///
/// Without a floor, `maxScore` alone accepts anything under the bar, and the
/// first candidate under it is usually far under: the first bake put level 50
/// at 19.2 against a ceiling of 56.9 — a 6-move board dropped in after a run of
/// 7-color puzzles. That is not a breather, it is a hole in the curve. The
/// window turns "at least 25% easier" into "meaningfully but not absurdly
/// easier".
const double kBreatherFloorFactor = 0.60;

/// How many preceding levels the breather rule averages over.
const int kBreatherLookback = 5;

/// Last level of the ONBOARDING ZONE, where the difficulty rail below applies.
const int kOnboardingLastLevel = 20;

/// Hard ceiling on the difficulty step between consecutive non-breather levels
/// inside the onboarding zone.
///
/// The first bake got this exactly backwards. Read as a ramp rate it was:
///
///     levels   1-15   2.8 points/level
///     levels  16-60   0.4
///     levels  61-120  0.17
///     levels 121-150  0.17
///
/// — the tutorial climbing SEVEN TIMES faster than anything after it. That is
/// the opposite of what the curve is for. Levels 1-15 are where D1 retention is
/// won or lost, and a player who bounces at level 9 never sees the carefully
/// graded 90 levels built for them further in. The rail makes the failure
/// impossible to reintroduce by accident.
const double kOnboardingMaxJump = 6;

/// One sub-segment of a band: a board shape, optionally pinned to a difficulty
/// window.
///
/// Most tiers are open-ended and simply take the easiest boards above the
/// running floor, which keeps the ramp gentle. The opening band pins explicit
/// windows instead, because the tutorial's job is not to be as easy as
/// possible — it is to occupy a KNOWN, near-flat range so a new player is
/// learning the controls rather than being tested.
final class CampaignTier {
  final LevelSpec spec;

  /// Lowest calibrated difficulty this tier may use, on top of the running
  /// floor.
  final double? minScore;

  /// Highest calibrated difficulty this tier may use.
  final double? maxScore;

  const CampaignTier(this.spec, {this.minScore, this.maxScore});

  bool get hasWindow => minScore != null || maxScore != null;

  int get colorCount => spec.colorCount;

  int get emptyTubeCount => spec.emptyTubeCount;

  @override
  String toString() =>
      '${spec.colorCount}c/${spec.emptyTubeCount}e'
      '${hasWindow ? " [${minScore ?? "-"}, ${maxScore ?? "-"}]" : ""}';
}

/// One stretch of the campaign, built from ordered difficulty tiers.
final class CampaignBand {
  final String name;

  /// 1-based inclusive level range.
  final int firstLevel;
  final int lastLevel;

  /// Sub-segments in ascending difficulty. Slots are split evenly between them,
  /// so the board grows steadily rather than jumping around within a band.
  final List<CampaignTier> tiers;

  /// Spec used for this band's breather levels — deliberately a smaller board
  /// than the band's tiers, because that is what "relief" looks like.
  final LevelSpec breatherSpec;

  const CampaignBand({
    required this.name,
    required this.firstLevel,
    required this.lastLevel,
    required this.tiers,
    required this.breatherSpec,
  });

  int get length => lastLevel - firstLevel + 1;
}

/// The campaign curve.
///
/// Color counts rise across the whole run and never exceed [kMaxColors]. The
/// final band gets its step up from REMOVING an empty tube rather than adding
/// colors — one empty tube is the hardest constraint in the game, and it keeps
/// the board readable at the point where the puzzles are hardest.
const List<CampaignBand> kCampaignBands = [
  // The onboarding band, and the only one with pinned windows.
  //
  // Levels 1-8 sit in a near-flat 18-30: a new player should find it almost
  // impossible to fail while they learn that a tap pours, that the whole run
  // travels, and that undo is free and unlimited. They are not being tested.
  // Levels 9-15 then ease up to 52 and hand off to "Finding Rhythm" at that
  // level rather than at 61, so band two continues the line instead of
  // stepping over it.
  CampaignBand(
    name: 'First Pours',
    firstLevel: 1,
    lastLevel: 15,
    tiers: [
      CampaignTier(
        LevelSpec(colorCount: 3, emptyTubeCount: 2),
        minScore: 18,
        maxScore: 30,
      ),
      CampaignTier(
        LevelSpec(colorCount: 4, emptyTubeCount: 2),
        minScore: 30,
        maxScore: 52,
      ),
    ],
    breatherSpec: LevelSpec(colorCount: 3, emptyTubeCount: 2),
  ),
  CampaignBand(
    name: 'Finding Rhythm',
    firstLevel: 16,
    lastLevel: 60,
    tiers: [
      CampaignTier(LevelSpec(colorCount: 5, emptyTubeCount: 2)),
      CampaignTier(LevelSpec(colorCount: 6, emptyTubeCount: 2)),
      CampaignTier(LevelSpec(colorCount: 7, emptyTubeCount: 2)),
    ],
    breatherSpec: LevelSpec(colorCount: 4, emptyTubeCount: 2),
  ),
  CampaignBand(
    name: 'Deep Water',
    firstLevel: 61,
    lastLevel: 120,
    tiers: [
      CampaignTier(LevelSpec(colorCount: 8, emptyTubeCount: 2)),
      CampaignTier(LevelSpec(colorCount: 9, emptyTubeCount: 2)),
      CampaignTier(LevelSpec(colorCount: 10, emptyTubeCount: 2)),
    ],
    breatherSpec: LevelSpec(colorCount: 6, emptyTubeCount: 2),
  ),
  CampaignBand(
    name: 'Mastery',
    firstLevel: 121,
    lastLevel: 150,
    tiers: [
      CampaignTier(LevelSpec(colorCount: 10, emptyTubeCount: 2)),
      CampaignTier(LevelSpec(colorCount: 10, emptyTubeCount: 1)),
    ],
    breatherSpec: LevelSpec(colorCount: 8, emptyTubeCount: 2),
  ),
];

/// Specs the daily pool is drawn from.
///
/// Mid-campaign difficulty on purpose — a daily is one-shot, and abandoning
/// today's challenge costs more engagement than abandoning a campaign level a
/// player can return to. Never drawn from the campaign's own boards; the
/// generator excludes them by canonical key so nobody is handed a puzzle they
/// already solved.
const List<LevelSpec> kDailySpecs = [
  LevelSpec(colorCount: 6, emptyTubeCount: 2),
  LevelSpec(colorCount: 7, emptyTubeCount: 2),
  LevelSpec(colorCount: 8, emptyTubeCount: 2),
];

/// Calibrated difficulty window for daily challenges.
const double kDailyMinScore = 45;
const double kDailyMaxScore = 80;

/// True when campaign level [id] is a deliberate breather.
///
/// Every tenth level, except:
///  * anywhere in the tutorial band, which is already the gentlest stretch in
///    the game — a breather there would relieve nothing; and
///  * the LAST level of any band, because a band should hand off at its peak.
///    Ending "Finding Rhythm" on an easy level and opening "Deep Water" three
///    colors higher is the exact difficulty cliff the breathers exist to
///    prevent.
bool isBreatherLevel(int id) {
  if (id % 10 != 0) return false;
  final band = bandForLevel(id);
  if (band == null) return false;
  if (band == kCampaignBands.first) return false;
  return id != band.lastLevel;
}

/// The band containing 1-based campaign level [id], or null if out of range.
CampaignBand? bandForLevel(int id) {
  for (final band in kCampaignBands) {
    if (id >= band.firstLevel && id <= band.lastLevel) return band;
  }
  return null;
}

int bandIndexForLevel(int id) {
  for (var i = 0; i < kCampaignBands.length; i++) {
    final band = kCampaignBands[i];
    if (id >= band.firstLevel && id <= band.lastLevel) return i;
  }
  throw ArgumentError.value(id, 'id', 'outside the campaign');
}

/// A built campaign plus the statistics gathered making it.
final class CampaignBuildResult {
  final LevelSet levelSet;
  final GenerationStats stats;

  /// Canonical keys of every campaign board, for excluding them from the daily
  /// pool.
  final Set<String> canonicalKeys;

  /// Full metrics per level id.
  ///
  /// Carried out of the build because the curve report wants `meanBranching`,
  /// which is not persisted on [Level] — recomputing it would mean re-solving
  /// all 150 boards purely to print a table.
  final Map<int, DifficultyMetrics> metrics;

  const CampaignBuildResult({
    required this.levelSet,
    required this.stats,
    required this.canonicalKeys,
    required this.metrics,
  });
}

/// Builds the full campaign deterministically from [seed].
///
/// The ordering strategy, and why it is not just "sort everything by score":
///
///  * Slots are filled TIER BY TIER, in ascending color count, so board size
///    grows steadily. Sorting the whole band by score instead would leave a
///    7-color board at level 20 and a 5-color board at level 55 — monotonic
///    on paper, erratic to play.
///  * Each tier generates a pool and keeps the LOWEST-scoring candidates above
///    a running floor. The floor carries across tiers AND across bands, so the
///    non-breather curve is globally non-decreasing, not merely non-decreasing
///    within each band.
///  * Breathers are placed last, once their neighbours exist, because the rule
///    is defined against the levels that actually precede them.
CampaignBuildResult buildCampaign({
  required int seed,
  void Function(String message)? onProgress,
}) {
  final generator = LevelGenerator(random: Random(seed));
  final stats = GenerationStats();
  final seenKeys = <String>{};
  final assigned = <int, CampaignLevel>{};
  final metrics = <int, DifficultyMetrics>{};

  var floor = 0.0;

  for (var bandIndex = 0; bandIndex < kCampaignBands.length; bandIndex++) {
    final band = kCampaignBands[bandIndex];

    final normalSlots = [
      for (var id = band.firstLevel; id <= band.lastLevel; id++)
        if (!isBreatherLevel(id)) id,
    ];

    final tierSlots = _splitEvenly(normalSlots, band.tiers.length);

    for (var t = 0; t < band.tiers.length; t++) {
      final tier = band.tiers[t];
      final slots = tierSlots[t];
      if (slots.isEmpty) continue;

      // A tier's own floor never drops below the running floor, so a pinned
      // window can raise the ramp but never walk it backwards.
      final tierFloor = tier.minScore == null
          ? floor
          : max(floor, tier.minScore!);

      // A pool larger than the slot count gives the selection something to
      // choose from.
      final poolSize = max(slots.length + 6, (slots.length * 1.5).round());

      onProgress?.call(
        'band ${band.name}: tier $tier -> ${slots.length} levels '
        '(pool $poolSize, floor ${tierFloor.toStringAsFixed(1)})',
      );

      // A PINNED tier is built SLOT BY SLOT, each aimed at its own narrow
      // sub-window. Sampling a pool and spreading the picks cannot work here:
      // a pool only ever contains what the distribution commonly produces, so
      // asking 13 four-color boards to cover 30-52 returns 41-52 — 41 is that
      // shape's 10th percentile, and nothing in the sample reaches below it.
      // That is precisely how the first re-bake put a 13.6-point cliff between
      // levels 8 and 9. Targeting each slot forces generation into the tail.
      //
      // An OPEN tier still takes the lowest candidates above the floor, which
      // keeps the ramp gentle and leaves harder boards for later tiers.
      final List<GeneratedLevel> picks;
      if (tier.hasWindow) {
        picks = _generatePinnedTier(
          generator: generator,
          tier: tier,
          floor: tierFloor,
          count: slots.length,
          seenKeys: seenKeys,
          stats: stats,
        );
      } else {
        picks =
            generator
                .generateBatch(
                  tier.spec,
                  poolSize,
                  minScore: tierFloor,
                  maxAttemptsPerLevel: 60000,
                  seenKeys: seenKeys,
                  stats: stats,
                )
                .toList()
              ..sort((a, b) => a.score.compareTo(b.score));
      }

      for (var i = 0; i < slots.length; i++) {
        final id = slots[i];
        assigned[id] = CampaignLevel(
          level: LevelSetCodec.quantiseLevel(picks[i].toLevel(id)),
          bandIndex: bandIndex,
          isBreather: false,
        );
        metrics[id] = picks[i].metrics;
      }
      floor = assigned[slots.last]!.level.difficultyScore;
    }
  }

  _placeBreathers(
    generator: generator,
    stats: stats,
    seenKeys: seenKeys,
    assigned: assigned,
    metrics: metrics,
    onProgress: onProgress,
  );

  final levels = [for (var id = 1; id <= kCampaignLength; id++) assigned[id]!];

  return CampaignBuildResult(
    levelSet: LevelSet(levelSetVersion: kLevelSetVersion, levels: levels),
    stats: stats,
    canonicalKeys: seenKeys,
    metrics: metrics,
  );
}

/// Fills every breather slot, in ascending order, against its real neighbours.
void _placeBreathers({
  required LevelGenerator generator,
  required GenerationStats stats,
  required Set<String> seenKeys,
  required Map<int, CampaignLevel> assigned,
  required Map<int, DifficultyMetrics> metrics,
  void Function(String)? onProgress,
}) {
  for (var id = 1; id <= kCampaignLength; id++) {
    if (!isBreatherLevel(id)) continue;

    final bandIndex = bandIndexForLevel(id);
    final band = kCampaignBands[bandIndex];
    final (floor, ceiling) = breatherWindowFor(id, assigned);

    onProgress?.call(
      'breather $id: must score in '
      '[${floor.toStringAsFixed(1)}, ${ceiling.toStringAsFixed(1)}] '
      '(${band.breatherSpec.colorCount}c/'
      '${band.breatherSpec.emptyTubeCount}e)',
    );

    late final GeneratedLevel generated;
    try {
      generated = generator.generate(
        band.breatherSpec,
        minScore: floor,
        maxScore: ceiling,
        maxAttempts: 60000,
        stats: stats,
      );
    } on StateError catch (e) {
      // Loud, per the design: a breather that is not actually easier is worse
      // than no breather, because the curve then claims relief it never gives.
      throw StateError(
        'Could not build breather at level $id. Needed difficulty in '
        '[${floor.toStringAsFixed(1)}, ${ceiling.toStringAsFixed(1)}] from '
        '${band.breatherSpec}, which that spec may not be able to reach. '
        'Either change the breather spec for band "${band.name}" or widen '
        'kBreatherFloorFactor / kBreatherReliefFactor.\n  cause: $e',
      );
    }

    seenKeys.add(canonicalKeyOf(generated.board));
    assigned[id] = CampaignLevel(
      level: LevelSetCodec.quantiseLevel(generated.toLevel(id)),
      bandIndex: bandIndex,
      isBreather: true,
    );
    metrics[id] = generated.metrics;
  }
}

/// The score window a breather at [id] must land in.
///
/// Shared by the builder and the validator so the rule is stated once — a
/// validator that recomputed it slightly differently would either pass bad
/// levels or fail good ones.
(double floor, double ceiling) breatherWindowFor(
  int id,
  Map<int, CampaignLevel> assigned,
) {
  final preceding = <double>[];
  for (var i = id - kBreatherLookback; i < id; i++) {
    final level = assigned[i];
    if (level != null) preceding.add(level.level.difficultyScore);
  }
  if (preceding.isEmpty) return (0, double.infinity);

  final average = preceding.reduce((a, b) => a + b) / preceding.length;
  return (average * kBreatherFloorFactor, average * kBreatherReliefFactor);
}

/// Builds the daily-challenge pool.
///
/// A separate artifact with its own seed, and explicitly disjoint from the
/// campaign: [excludeKeys] carries every campaign board's canonical key, so no
/// player is ever served a daily they already solved in the campaign.
List<Level> buildDailyPool({
  required int seed,
  required Set<String> excludeKeys,
  int count = kDailyPoolSize,
  GenerationStats? stats,
  void Function(String message)? onProgress,
}) {
  final generator = LevelGenerator(random: Random(seed));
  final seen = <String>{...excludeKeys};
  final levels = <Level>[];

  while (levels.length < count) {
    // Rotate specs so the pool is a mix rather than 365 boards of one shape.
    final spec = kDailySpecs[levels.length % kDailySpecs.length];
    final generated = generator.generate(
      spec,
      minScore: kDailyMinScore,
      maxScore: kDailyMaxScore,
      maxAttempts: 60000,
      stats: stats,
    );

    if (!seen.add(canonicalKeyOf(generated.board))) continue;

    levels.add(
      LevelSetCodec.quantiseLevel(generated.toLevel(levels.length + 1)),
    );
    if (levels.length % 50 == 0) {
      onProgress?.call('daily pool: ${levels.length}/$count');
    }
  }

  return levels;
}

/// Builds a pinned tier one level at a time, each aimed at its own slice of the
/// tier's window, so the window is FILLED evenly rather than merely respected.
///
/// Each slot's floor also carries the previous level's score, which keeps the
/// tier monotonic even when a slot has to be widened.
///
/// Widening is the graceful-degradation path. Difficulty is not continuous at
/// the easy end: a 3-color board has only a handful of reachable scores
/// (5-6 optimal moves, a coarse scatter term), so a narrow sub-window can be
/// genuinely unhittable rather than merely rare. Rather than failing the build
/// on a lattice gap, the search widens toward the tier's full window — and the
/// onboarding rail stays the hard assertion that catches a real cliff.
List<GeneratedLevel> _generatePinnedTier({
  required LevelGenerator generator,
  required CampaignTier tier,
  required double floor,
  required int count,
  required Set<String> seenKeys,
  required GenerationStats stats,
}) {
  final windowLow = floor;
  final windowHigh = tier.maxScore ?? double.infinity;
  final step = windowHigh.isFinite ? (windowHigh - windowLow) / count : 0.0;

  final levels = <GeneratedLevel>[];
  var previousScore = windowLow;

  for (var i = 0; i < count; i++) {
    final targetLow = windowLow + i * step;
    final targetHigh = step > 0 ? windowLow + (i + 1) * step : windowHigh;

    GeneratedLevel? chosen;
    for (final widen in const [0.0, 0.5, 1.5, 4.0]) {
      final low = max(previousScore, targetLow - step * widen);
      final high = windowHigh.isFinite
          ? min(windowHigh, targetHigh + step * widen)
          : null;
      if (high != null && high <= low) continue;

      try {
        final candidate = generator.generate(
          tier.spec,
          minScore: low,
          maxScore: high,
          maxAttempts: 40000,
          stats: stats,
        );
        if (!seenKeys.add(canonicalKeyOf(candidate.board))) continue;
        chosen = candidate;
        break;
      } on StateError {
        continue;
      }
    }

    if (chosen == null) {
      throw StateError(
        'Could not build pinned level ${i + 1}/$count for tier $tier '
        'targeting [${targetLow.toStringAsFixed(1)}, '
        '${targetHigh.toStringAsFixed(1)}]. Widen the tier window or change '
        'its board shape.',
      );
    }

    levels.add(chosen);
    previousScore = chosen.score;
  }

  return levels;
}

/// The worst upward difficulty step between consecutive non-breather levels in
/// the onboarding zone, or null when the curve is clean.
///
/// Breathers are skipped rather than flagged: a breather is a deliberate DIP,
/// and the level after one is meant to return to the underlying line. What this
/// guards is that line.
///
/// Shared by the validator and the tests so the rail is stated once.
({int fromLevel, int toLevel, double jump})? worstOnboardingJump(
  List<CampaignLevel> levels,
) {
  CampaignLevel? previous;
  ({int fromLevel, int toLevel, double jump})? worst;

  for (final level in levels) {
    if (level.id > kOnboardingLastLevel) break;
    if (level.isBreather) continue;

    if (previous != null) {
      final jump = level.level.difficultyScore - previous.level.difficultyScore;
      if (jump > kOnboardingMaxJump && (worst == null || jump > worst.jump)) {
        worst = (fromLevel: previous.id, toLevel: level.id, jump: jump);
      }
    }
    previous = level;
  }

  return worst;
}

/// Splits [items] into [parts] contiguous groups of near-equal size.
///
/// Remainder goes to the EARLIER groups, so when slots do not divide evenly the
/// gentler tiers get the extra levels rather than the hardest one.
List<List<T>> _splitEvenly<T>(List<T> items, int parts) {
  final result = <List<T>>[];
  final base = items.length ~/ parts;
  final remainder = items.length % parts;

  var offset = 0;
  for (var i = 0; i < parts; i++) {
    final size = base + (i < remainder ? 1 : 0);
    result.add(items.sublist(offset, offset + size));
    offset += size;
  }
  return result;
}

/// Re-solves [level] and confirms the recorded [Level.minMoves] is right.
///
/// Used by the validator. Kept here so the campaign's definition of "valid"
/// lives next to its definition of "built".
bool verifyLevel(Level level, {Solver solver = const Solver()}) {
  final outcome = solver.solve(level.board);
  return outcome is Solved && outcome.moveCount == level.minMoves;
}

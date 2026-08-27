/// Timing spec for the level-complete sequence.
///
/// One source of truth. The board, the overlay and the audio cues all read
/// these numbers, so the sequence cannot drift out of sync with itself.
///
/// WHY TWO PROFILES. The win moment is the emotional payoff of the loop, and
/// it earns its length — but only when there is something to celebrate. A
/// player clearing level 60 on a two-star retry has seen this sixty times; a
/// player who just three-starred it has not. So the beats never change, only
/// their spacing: the FULL profile runs 1820ms for a three-star, a personal
/// best, or the last level of a band, and the BRIEF profile does the same
/// sequence in 1150ms for everything else.
///
/// Cutting beats instead of spacing would make the short version feel like a
/// different, cheaper screen. Cutting spacing makes it feel brisk.
library;

/// A single reveal: when it starts and how long it takes.
class Beat {
  final int at;
  final int length;

  const Beat(this.at, this.length);

  int get end => at + length;
}

class WinProfile {
  /// Whole sequence length.
  final int total;

  /// Per-tube delay on the completion glow, left to right.
  final int glowStagger;
  final int glowLength;

  /// The board's "presenting" lift, or null when it is skipped.
  ///
  /// Dropped in the brief profile: it is a flourish, and a flourish on a
  /// routine clear is exactly what makes a sequence feel padded.
  final Beat? present;

  /// One entry per star, in landing order.
  final List<int> starAt;
  final int starLength;

  /// The third star's extra ring pulse and warm board wash. Full profile only —
  /// this is the thing that has to make three stars feel different from two.
  final int thirdStarFlourishLength;

  final Beat moves;
  final Beat band;
  final Beat cta;
  final Beat secondary;

  const WinProfile({
    required this.total,
    required this.glowStagger,
    required this.glowLength,
    required this.present,
    required this.starAt,
    required this.starLength,
    required this.thirdStarFlourishLength,
    required this.moves,
    required this.band,
    required this.cta,
    required this.secondary,
  });

  /// The moment worth the time: three stars, a personal best, or a band ending.
  static const full = WinProfile(
    total: 1820,
    glowStagger: 60,
    glowLength: 420,
    present: Beat(200, 380),
    starAt: [520, 700, 880],
    starLength: 260,
    thirdStarFlourishLength: 340,
    moves: Beat(940, 380),
    band: Beat(1180, 420),
    cta: Beat(1500, 300),
    secondary: Beat(1620, 200),
  );

  /// Every other clear. Same beats, tighter spacing, no present-lift.
  static const brief = WinProfile(
    total: 1150,
    glowStagger: 40,
    glowLength: 300,
    present: null,
    starAt: [340, 460, 580],
    starLength: 200,
    thirdStarFlourishLength: 240,
    moves: Beat(620, 280),
    band: Beat(700, 300),
    cta: Beat(950, 200),
    secondary: Beat(1030, 120),
  );

  /// Picks the profile this particular clear has earned.
  static WinProfile forOutcome({
    required int stars,
    required bool isNewBest,
    required bool isBandFinal,
  }) => (stars >= 3 || isNewBest || isBandFinal) ? full : brief;

  bool get isFull => present != null;

  Duration get duration => Duration(milliseconds: total);
}

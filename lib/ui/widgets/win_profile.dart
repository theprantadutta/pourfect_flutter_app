/// Timing for the level-complete sequence.
///
/// Two profiles, and which one plays is EARNED. A player clearing level 60 on
/// a two-star retry has seen this sixty times; a three-star clear, a personal
/// best or the end of a world gets the whole show.
///
/// The full sequence, as the Toybox handoff choreographs it:
///
///   1. 0ms      the last ball lands; the board bumps to 1.03 (board_view).
///   2. 150ms    yellow rays fade in behind the board and turn slowly.
///   3. 200ms    confetti BALLS, glyphs and all, burst out and fall.
///   4. 700ms    cross-fade to blue; the title slams in from 1.6x at −12°.
///   5.          stars drop in one by one, each with a pop and a ping.
///   6.          the chips slide up in a stagger.
///   7.          NEW BEST slaps on.
///   8.          NEXT LEVEL arrives and starts to breathe.
///
/// The brief profile keeps only the beats that carry information — the landing,
/// the title and the stars — and tightens their spacing.
///
/// All values are milliseconds from the winning move.
library;

/// One timed beat: when it starts and how long its own animation runs.
class Beat {
  final int at;
  final int length;

  const Beat(this.at, this.length);

  int get end => at + length;
}

class WinProfile {
  /// When the sequence is over and the result screen is fully at rest.
  final int total;

  /// The ring flash rippling across the solved tubes (board_view).
  final int glowStagger;
  final int glowLength;

  /// Yellow rays behind the board. Null on the brief profile.
  final Beat? rays;

  /// Confetti balls. Null on the brief profile.
  final Beat? confetti;

  /// The cross-fade from the board to the blue result screen.
  final Beat settle;

  /// The title slamming in.
  final Beat title;

  final List<int> starAt;
  final int starLength;

  /// The third star's extra ring. Only a three-star run fires it.
  final int thirdStarFlourishLength;

  /// The result chips: moves, time, points. They arrive [chipStagger] apart;
  /// a zero stagger means they simply fade in together.
  final Beat chips;
  final int chipStagger;

  /// The world progress bar running from before to after.
  final Beat band;

  /// NEW BEST / UNDER PAR stickers slapping on.
  final Beat sticker;

  /// NEXT LEVEL and replay.
  final Beat cta;

  const WinProfile({
    required this.total,
    required this.glowStagger,
    required this.glowLength,
    required this.rays,
    required this.confetti,
    required this.settle,
    required this.title,
    required this.starAt,
    required this.starLength,
    required this.thirdStarFlourishLength,
    required this.chips,
    required this.chipStagger,
    required this.band,
    required this.sticker,
    required this.cta,
  });

  static const full = WinProfile(
    total: 1820,
    glowStagger: 60,
    glowLength: 420,
    rays: Beat(150, 300),
    confetti: Beat(200, 900),
    settle: Beat(700, 260),
    title: Beat(760, 380),
    starAt: [1000, 1120, 1240],
    starLength: 260,
    thirdStarFlourishLength: 340,
    chips: Beat(1300, 240),
    chipStagger: 60,
    band: Beat(1380, 360),
    sticker: Beat(1480, 220),
    cta: Beat(1560, 260),
  );

  static const brief = WinProfile(
    total: 1150,
    glowStagger: 40,
    glowLength: 300,
    rays: null,
    confetti: null,
    settle: Beat(240, 220),
    title: Beat(280, 320),
    starAt: [520, 640, 760],
    starLength: 200,
    thirdStarFlourishLength: 240,
    chips: Beat(860, 160),
    chipStagger: 0,
    band: Beat(900, 200),
    sticker: Beat(940, 160),
    cta: Beat(960, 190),
  );

  /// Three stars, a personal best, or the end of a world earns the full show.
  static WinProfile forOutcome({
    required int stars,
    required bool isNewBest,
    required bool isBandFinal,
  }) => (stars >= 3 || isNewBest || isBandFinal) ? full : brief;

  bool get isFull => rays != null;

  Duration get duration => Duration(milliseconds: total);
}

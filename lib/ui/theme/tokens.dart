/// Semantic design tokens.
///
/// Every color, space and type ramp in the app resolves through here. Nothing
/// downstream writes a raw hex value or a magic number — that is what makes the
/// warm-paper light theme a token remap later rather than a rewrite, and it is
/// why [PourfectTokens] is read off the widget tree instead of being a global.
///
/// Design direction, restated because it constrains every value below: deep
/// calm dark, near-black ink ground, frosted-glass tubes, muted jewel balls,
/// hairline borders. References are deliberately outside the genre — meditation
/// apps, premium habit trackers, high-end audio equipment UI. Explicitly NOT
/// the mobile-puzzle house style: no rainbow gradients, no cartoon bevels, no
/// bouncy display faces, no confetti.
library;

import 'package:flutter/material.dart';

import 'ball_palette.dart';

/// The app's color, spacing, radius and motion tokens.
@immutable
class PourfectTokens extends ThemeExtension<PourfectTokens> {
  // ---- surfaces ----------------------------------------------------------

  /// The board's ground. Everything else sits on this.
  final Color surface;

  /// Raised panels: HUD bar, sheets, the level-complete card.
  final Color surfaceRaised;

  /// The tube interior — a frosted pane, not a solid fill.
  final Color tubeGlass;

  /// The tube's rim/edge highlight, and hairline dividers.
  final Color hairline;

  /// Slightly stronger line for a focused or selected element.
  final Color hairlineStrong;

  // ---- text --------------------------------------------------------------

  final Color textPrimary;
  final Color textMuted;

  /// Numerals, timers, counters. Always monospace.
  final Color textNumeric;

  /// The quietest text tier: locked levels, inactive captions. Present so
  /// "unavailable" can be expressed without dropping opacity on a color that
  /// was already muted, which compounds into unreadable.
  final Color dimText;

  // ---- accents -----------------------------------------------------------

  /// The single accent. Used sparingly: the selected tube's glow and the
  /// completion flourish. A second accent would start to look like a brand
  /// guideline rather than a game.
  final Color accent;

  /// Warm tint for the completion moment only.
  final Color accentWarm;

  // ---- geometry ----------------------------------------------------------

  final double ballSize;
  final double tubeRadius;
  final double panelRadius;

  /// Spacing scale. Generous by intent — the board is the hero and needs air.
  final double space1;
  final double space2;
  final double space3;
  final double space4;
  final double space5;

  // ---- motion ------------------------------------------------------------

  /// One ball travelling between tubes.
  final Duration pourDuration;

  /// The squash-and-stretch settle after a ball lands.
  final Duration settleDuration;

  /// Selection lift and drop.
  final Duration selectDuration;

  const PourfectTokens({
    required this.surface,
    required this.surfaceRaised,
    required this.tubeGlass,
    required this.hairline,
    required this.hairlineStrong,
    required this.textPrimary,
    required this.textMuted,
    required this.textNumeric,
    required this.dimText,
    required this.accent,
    required this.accentWarm,
    required this.ballSize,
    required this.tubeRadius,
    required this.panelRadius,
    required this.space1,
    required this.space2,
    required this.space3,
    required this.space4,
    required this.space5,
    required this.pourDuration,
    required this.settleDuration,
    required this.selectDuration,
  });

  /// The shipped dark theme.
  ///
  /// Surfaces step in small increments (0E→18→1F) rather than the usual
  /// dark-grey jumps: on OLED the eye reads separation from the hairlines, and
  /// big fills would flatten the frosted-glass effect the tubes depend on.
  static const dark = PourfectTokens(
    surface: Color(0xFF0E1116),
    surfaceRaised: Color(0xFF181C24),
    tubeGlass: Color(0x14FFFFFF),
    hairline: Color(0x1AFFFFFF),
    hairlineStrong: Color(0x33FFFFFF),
    textPrimary: Color(0xFFE8EAF0),
    textMuted: Color(0xFF7C8698),
    textNumeric: Color(0xFFC3CAD8),
    dimText: Color(0xFF545C6B),
    accent: Color(0xFF8FC9E8),
    accentWarm: Color(0xFFE4D9B4),
    ballSize: 30,
    tubeRadius: 18,
    panelRadius: 16,
    space1: 4,
    space2: 8,
    space3: 16,
    space4: 24,
    space5: 40,
    pourDuration: Duration(milliseconds: 260),
    settleDuration: Duration(milliseconds: 180),
    selectDuration: Duration(milliseconds: 140),
  );

  /// Opacity applied to a tube that cannot receive the held run.
  ///
  /// 40%, not 30%: on a near-black ground the muted jewel tones crush toward
  /// invisible below about 35%, and a dimmed tube still has to read as a tube.
  static const double illegalTargetOpacity = 0.4;

  /// Reads the tokens off the tree.
  static PourfectTokens of(BuildContext context) =>
      Theme.of(context).extension<PourfectTokens>() ?? dark;

  @override
  PourfectTokens copyWith({
    Color? surface,
    Color? surfaceRaised,
    Color? tubeGlass,
    Color? hairline,
    Color? hairlineStrong,
    Color? textPrimary,
    Color? textMuted,
    Color? textNumeric,
    Color? dimText,
    Color? accent,
    Color? accentWarm,
    double? ballSize,
    double? tubeRadius,
    double? panelRadius,
    double? space1,
    double? space2,
    double? space3,
    double? space4,
    double? space5,
    Duration? pourDuration,
    Duration? settleDuration,
    Duration? selectDuration,
  }) => PourfectTokens(
    surface: surface ?? this.surface,
    surfaceRaised: surfaceRaised ?? this.surfaceRaised,
    tubeGlass: tubeGlass ?? this.tubeGlass,
    hairline: hairline ?? this.hairline,
    hairlineStrong: hairlineStrong ?? this.hairlineStrong,
    textPrimary: textPrimary ?? this.textPrimary,
    textMuted: textMuted ?? this.textMuted,
    textNumeric: textNumeric ?? this.textNumeric,
    dimText: dimText ?? this.dimText,
    accent: accent ?? this.accent,
    accentWarm: accentWarm ?? this.accentWarm,
    ballSize: ballSize ?? this.ballSize,
    tubeRadius: tubeRadius ?? this.tubeRadius,
    panelRadius: panelRadius ?? this.panelRadius,
    space1: space1 ?? this.space1,
    space2: space2 ?? this.space2,
    space3: space3 ?? this.space3,
    space4: space4 ?? this.space4,
    space5: space5 ?? this.space5,
    pourDuration: pourDuration ?? this.pourDuration,
    settleDuration: settleDuration ?? this.settleDuration,
    selectDuration: selectDuration ?? this.selectDuration,
  );

  @override
  PourfectTokens lerp(ThemeExtension<PourfectTokens>? other, double t) {
    if (other is! PourfectTokens) return this;
    return PourfectTokens(
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceRaised: Color.lerp(surfaceRaised, other.surfaceRaised, t)!,
      tubeGlass: Color.lerp(tubeGlass, other.tubeGlass, t)!,
      hairline: Color.lerp(hairline, other.hairline, t)!,
      hairlineStrong: Color.lerp(hairlineStrong, other.hairlineStrong, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      textNumeric: Color.lerp(textNumeric, other.textNumeric, t)!,
      dimText: Color.lerp(dimText, other.dimText, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentWarm: Color.lerp(accentWarm, other.accentWarm, t)!,
      ballSize: _lerpD(ballSize, other.ballSize, t),
      tubeRadius: _lerpD(tubeRadius, other.tubeRadius, t),
      panelRadius: _lerpD(panelRadius, other.panelRadius, t),
      space1: _lerpD(space1, other.space1, t),
      space2: _lerpD(space2, other.space2, t),
      space3: _lerpD(space3, other.space3, t),
      space4: _lerpD(space4, other.space4, t),
      space5: _lerpD(space5, other.space5, t),
      pourDuration: t < 0.5 ? pourDuration : other.pourDuration,
      settleDuration: t < 0.5 ? settleDuration : other.settleDuration,
      selectDuration: t < 0.5 ? selectDuration : other.selectDuration,
    );
  }

  static double _lerpD(double a, double b, double t) => a + (b - a) * t;
}

/// Resolves an engine `ColorId` to its ball fill.
///
/// The engine deals in opaque integers and knows nothing about appearance; this
/// is the only place the two meet.
Color ballColor(int colorId) =>
    Color(0xFF000000 | kBallPalette[colorId % kBallPalette.length].rgb);

/// Resolves an engine `ColorId` to its accessibility glyph.
BallGlyph ballGlyph(int colorId) =>
    kBallPalette[colorId % kBallPalette.length].glyph;

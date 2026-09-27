/// The ball palette: ten colors, each paired with a distinct shape glyph.
///
/// PURE DART, deliberately. No Flutter import, so `tool/cvd_harness.dart` can
/// read it and render the color-blindness proof sheet without a device. The
/// Flutter theme wraps these into `Color`; this file stays the single source of
/// truth for both.
///
/// TWO RULES THIS FILE EXISTS TO ENFORCE:
///
/// 1. **Color is never the only cue.** Every ball carries a color AND a
///    glyph, always both — not a mode a player has to discover in settings. A
///    meaningful share of puzzle players are color-blind, and in this genre it
///    is the single most common accessibility complaint in reviews.
/// 2. **Ten is the ceiling.** Past ten, the glyphs stop being tellable apart at
///    ball size and the muted palette runs out of separable hues. Raising it is
///    not a constant edit — it needs `tool/cvd_harness.dart` re-run and the
///    pairwise separations re-checked.
///
/// The palette is the Toybox set: bright toy colors on a cream ground, each
/// ball wrapped in a 2.5px ink outline. The outline and the glyph do the
/// separating work that saturation cannot do alone under dichromacy — the CVD
/// harness passes with every color-weak pair carried by a distinct silhouette.
library;

/// A shape drawn on the ball, in addition to its color.
///
/// Chosen for silhouette contrast rather than prettiness: filled against
/// hollow, angular against round, one stroke against two. A glyph does not need
/// to be identifiable in isolation — it needs to be unmistakable against the
/// other nine.
enum BallGlyph {
  dot,
  ring,
  triangle,
  square,
  plus,
  bar,
  diamond,
  cross,
  arc,
  hexagon,
}

/// One entry in the ball palette.
final class BallStyle {
  /// Stable name, used in code and in the CVD report.
  final String name;

  /// 0xRRGGBB. No alpha — balls are always opaque.
  final int rgb;

  /// The shape drawn on this ball.
  final BallGlyph glyph;

  /// 0xRRGGBB the glyph is drawn in. Ink, except where the ball is too dark
  /// for ink to read (indigo), where it is white.
  final int glyphInk;

  const BallStyle(this.name, this.rgb, this.glyph, {this.glyphInk = kInkRgb});

  int get r => (rgb >> 16) & 0xFF;

  int get g => (rgb >> 8) & 0xFF;

  int get b => rgb & 0xFF;

  String get hex => '#${rgb.toRadixString(16).padLeft(6, '0').toUpperCase()}';

  @override
  String toString() => '$name($hex, ${glyph.name})';
}

/// The ten ball styles, indexed by the engine's `ColorId`.
///
/// Order is meaningful: a level using N colors uses ids 0..N-1, so the FIRST
/// entries are the ones a new player meets. The opening three are the most
/// widely separated set in the palette — the tutorial should never be where
/// somebody discovers they cannot tell two balls apart.
const List<BallStyle> kBallPalette = [
  BallStyle('amber', 0xFFC233, BallGlyph.dot),
  BallStyle('azure', 0x3D8BFF, BallGlyph.ring),
  BallStyle('rose', 0xFF5F8F, BallGlyph.triangle),
  BallStyle('teal', 0x22C3A6, BallGlyph.square),
  BallStyle('iris', 0xA78BFA, BallGlyph.plus),
  BallStyle('moss', 0x9BE15D, BallGlyph.bar),
  BallStyle('cream', 0xF6E3B4, BallGlyph.diamond),
  BallStyle('clay', 0xE0703F, BallGlyph.cross),
  BallStyle('sky', 0x7FD8FF, BallGlyph.arc),
  BallStyle('indigo', 0x4B50C8, BallGlyph.hexagon, glyphInk: 0xFFFFFF),
];

/// Ceiling on simultaneous colors. Mirrors the engine's `kMaxColors`.
const int kPaletteSize = 10;

/// Ground the palette is tuned against — the Toybox cream.
const int kSurfaceRgb = 0xFFF3DF;

/// The tube interior the balls sit inside.
const int kSurfaceRaisedRgb = 0xFFFFFF;

/// The ink every ball is outlined in, and most glyphs are drawn in.
const int kInkRgb = 0x1F1A33;

/// The ball palette: ten colours, each paired with a distinct shape glyph.
///
/// PURE DART, deliberately. No Flutter import, so `tool/cvd_harness.dart` can
/// read it and render the colour-blindness proof sheet without a device. The
/// Flutter theme wraps these into `Color`; this file stays the single source of
/// truth for both.
///
/// TWO RULES THIS FILE EXISTS TO ENFORCE:
///
/// 1. **Colour is never the only cue.** Every ball carries a colour AND a
///    glyph, always both — not a mode a player has to discover in settings. A
///    meaningful share of puzzle players are colour-blind, and in this genre it
///    is the single most common accessibility complaint in reviews.
/// 2. **Ten is the ceiling.** Past ten, the glyphs stop being tellable apart at
///    ball size and the muted palette runs out of separable hues. Raising it is
///    not a constant edit — it needs `tool/cvd_harness.dart` re-run and the
///    pairwise separations re-checked.
///
/// The palette is tuned for a near-black ground and deliberately muted: this is
/// a relaxing game, not a toy. Saturation is kept moderate and LIGHTNESS does
/// much of the separating work, because lightness is the one channel no form of
/// colour blindness takes away.
library;

/// A shape drawn on the ball, in addition to its colour.
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

  const BallStyle(this.name, this.rgb, this.glyph);

  int get r => (rgb >> 16) & 0xFF;

  int get g => (rgb >> 8) & 0xFF;

  int get b => rgb & 0xFF;

  String get hex => '#${rgb.toRadixString(16).padLeft(6, '0').toUpperCase()}';

  @override
  String toString() => '$name($hex, ${glyph.name})';
}

/// The ten ball styles, indexed by the engine's `ColorId`.
///
/// Order is meaningful: a level using N colours uses ids 0..N-1, so the FIRST
/// entries are the ones a new player meets. The opening three are the most
/// widely separated set in the palette — the tutorial should never be where
/// somebody discovers they cannot tell two balls apart.
const List<BallStyle> kBallPalette = [
  BallStyle('amber', 0xD9A047, BallGlyph.dot),
  BallStyle('azure', 0x4A8FD4, BallGlyph.ring),
  BallStyle('rose', 0xC85F72, BallGlyph.triangle),
  BallStyle('teal', 0x3FA396, BallGlyph.square),
  BallStyle('iris', 0xA4A9EA, BallGlyph.plus),
  BallStyle('moss', 0xB2DB76, BallGlyph.bar),
  BallStyle('cream', 0xE4D9B4, BallGlyph.diamond),
  BallStyle('clay', 0xB25A38, BallGlyph.cross),
  BallStyle('sky', 0x8FC9E8, BallGlyph.arc),
  BallStyle('indigo', 0x3B4E8C, BallGlyph.hexagon),
];

/// Ceiling on simultaneous colours. Mirrors the engine's `kMaxColours`.
const int kPaletteSize = 10;

/// Ground the palette is tuned against — the deep-calm-dark surface.
const int kSurfaceRgb = 0x0E1116;

/// Raised surface (tube glass) the balls sit inside.
const int kSurfaceRaisedRgb = 0x181C24;

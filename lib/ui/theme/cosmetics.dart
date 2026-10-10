/// Ball skins and tube themes: what each looks like, and which one is worn.
///
/// A skin RESTYLES. Every ball keeps its palette color and its glyph, the pair
/// `tool/cvd_harness.dart` signed off for color-blind players; a skin only
/// changes the finish on top (a highlight, stripes, sprinkles). A tube theme
/// changes the resting tube's glass and pattern; the selected, legal and
/// sorted fills keep their meaning on every theme.
///
/// Ids are shared with the API's `CosmeticCatalogue` and must never be renamed.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

enum BallSkin {
  classic('classic', 'Classic'),
  glossy('glossy', 'Glossy'),
  striped('striped', 'Candy stripe'),
  glow('glow', 'Glow'),
  speckled('speckled', 'Sprinkles'),
  marble('marble', 'Marble'),
  pearl('pearl', 'Pearl'),
  checker('checker', 'Checker');

  final String id;
  final String label;

  const BallSkin(this.id, this.label);

  static BallSkin byId(String? id) =>
      values.firstWhere((s) => s.id == id, orElse: () => classic);
}

enum TubeTheme {
  toy('toy', 'Toy', Color(0xFFFFFFFF)),
  frost('frost', 'Frost', Color(0xFFEFF5FF)),
  wood('wood', 'Wood', Color(0xFFF6E7D2)),
  lilac('lilac', 'Lilac', Color(0xFFF5EEFF));

  final String id;
  final String label;

  /// The resting tube's fill.
  final Color glass;

  const TubeTheme(this.id, this.label, this.glass);

  static TubeTheme byId(String? id) =>
      values.firstWhere((t) => t.id == id, orElse: () => toy);
}

/// The ball skin being worn. A notifier, not a provider, because ball sprites
/// are painted from plain `CustomPainter`s all over the app; every ball
/// painter repaints when it changes.
final ValueNotifier<BallSkin> wornBallSkin = ValueNotifier(BallSkin.classic);

/// The tube theme being worn.
final ValueNotifier<TubeTheme> wornTubeTheme = ValueNotifier(TubeTheme.toy);

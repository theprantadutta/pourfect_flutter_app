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

import '../../l10n/l10n.dart';

enum BallSkin {
  classic('classic'),
  glossy('glossy'),
  striped('striped'),
  glow('glow'),
  speckled('speckled'),
  marble('marble'),
  pearl('pearl'),
  checker('checker');

  final String id;

  const BallSkin(this.id);

  /// The skin's name in [l]'s language.
  String displayName(AppLocalizations l) => switch (this) {
    classic => l.settingsSkinClassic,
    glossy => l.settingsSkinGlossy,
    striped => l.settingsSkinStriped,
    glow => l.settingsSkinGlow,
    speckled => l.settingsSkinSpeckled,
    marble => l.settingsSkinMarble,
    pearl => l.settingsSkinPearl,
    checker => l.settingsSkinChecker,
  };

  /// The name in the device's language, for code with no BuildContext.
  /// Widgets use [displayName] with `context.l10n`.
  String get label => displayName(appL10n());

  static BallSkin byId(String? id) =>
      values.firstWhere((s) => s.id == id, orElse: () => classic);
}

enum TubeTheme {
  toy('toy', Color(0xFFFFFFFF)),
  frost('frost', Color(0xFFEFF5FF)),
  wood('wood', Color(0xFFF6E7D2)),
  lilac('lilac', Color(0xFFF5EEFF));

  final String id;

  /// The resting tube's fill.
  final Color glass;

  const TubeTheme(this.id, this.glass);

  /// The theme's name in [l]'s language.
  String displayName(AppLocalizations l) => switch (this) {
    toy => l.settingsTubeToy,
    frost => l.settingsTubeFrost,
    wood => l.settingsTubeWood,
    lilac => l.settingsTubeLilac,
  };

  /// The name in the device's language, for code with no BuildContext.
  /// Widgets use [displayName] with `context.l10n`.
  String get label => displayName(appL10n());

  static TubeTheme byId(String? id) =>
      values.firstWhere((t) => t.id == id, orElse: () => toy);
}

/// The ball skin being worn. A notifier, not a provider, because ball sprites
/// are painted from plain `CustomPainter`s all over the app; every ball
/// painter repaints when it changes.
final ValueNotifier<BallSkin> wornBallSkin = ValueNotifier(BallSkin.classic);

/// The tube theme being worn.
final ValueNotifier<TubeTheme> wornTubeTheme = ValueNotifier(TubeTheme.toy);

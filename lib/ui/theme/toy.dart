/// The Toybox visual system: cream dotted ground, chunky ink outlines, hard
/// drop shadows, toy balls.
///
/// [PourfectTokens] still carries the semantic values the board and older
/// widgets read off the tree. This file adds what that set never had: the ink
/// stroke, the no-blur offset shadow, the brand accents, and the four screen
/// surfaces. Everything here is `const` or a pure function, so a widget can use
/// it without a BuildContext.
///
/// Three rules the whole look depends on:
///
///  * **Shadows never blur.** A toy shadow is solid ink offset straight down.
///    A soft shadow anywhere reads as a different app.
///  * **Everything interactive has the 2.5px ink stroke.** Small chips use 2.
///  * **Tilt is a garnish.** At most two tilted elements per screen, and never
///    on a list row.
library;

import 'package:flutter/material.dart';
import 'dart:ui' show PointMode;

import 'package:flutter/services.dart';

abstract final class Toy {
  // ---- ink and ground ------------------------------------------------------

  /// Every stroke, every shadow, and all body text.
  static const ink = Color(0xFF1F1A33);
  static const inkMuted = Color(0xFF6B6480);

  /// Quietest text: locked levels, disabled captions.
  static const inkDim = Color(0xFF9C95AE);

  static const cream = Color(0xFFFFF3DF);
  static const creamDot = Color(0x171F1A33);
  static const card = Color(0xFFFFFFFF);
  static const divider = Color(0xFFEFE6D6);
  static const track = Color(0xFFF0E6D4);
  static const toggleOff = Color(0xFFE9DFCC);

  /// The interior of a tube in a small board preview.
  static const tubePreview = Color(0xFFF4ECFF);

  // ---- accents -------------------------------------------------------------

  /// Primary action and "this one is current".
  static const tomato = Color(0xFFFF5A36);
  static const tomatoDark = Color(0xFFD8401F);
  static const tomatoTint = Color(0xFFFFE4DC);

  /// Stars, rank, hint.
  static const yellow = Color(0xFFFFC233);

  /// Daily, worlds, the win surface.
  static const blue = Color(0xFF3D8BFF);

  /// Done, on.
  static const mint = Color(0xFF22C3A6);
  static const pink = Color(0xFFFF5F8F);
  static const lilac = Color(0xFFA78BFA);

  // ---- board ---------------------------------------------------------------

  static const tubeFill = Color(0xFFFFFFFF);
  static const selectedTubeFill = Color(0xFFFFF1EC);
  static const legalTubeFill = Color(0xFFEAFFF9);
  static const sortedTubeFill = Color(0xFFFFF8E1);

  static const scrim = Color(0x9E1F1A33);

  // ---- geometry ------------------------------------------------------------

  static const stroke = 2.5;
  static const strokeThin = 2.0;

  static const rChip = 10.0;
  static const rButton = 14.0;
  static const rControl = 18.0;
  static const rCard = 20.0;
  static const rHero = 26.0;

  /// How far a pressed control sinks. The shadow shrinks by the same amount, so
  /// the bottom edge of the shadow stays put — the button goes DOWN into it.
  static const pressDepth = 3.0;

  // ---- shadows -------------------------------------------------------------

  /// The signature toy shadow: solid, no blur, straight down.
  static List<BoxShadow> hard([double dy = 4, Color color = ink]) => dy <= 0
      ? const []
      : [BoxShadow(color: color, offset: Offset(0, dy))];

  /// White card, ink stroke, hard shadow — the default container.
  static BoxDecoration box({
    Color fill = card,
    double radius = rCard,
    double shadow = 4,
    Color stroke = ink,
    Color? shadowColor,
    double strokeWidth = Toy.stroke,
  }) => BoxDecoration(
    color: fill,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: stroke, width: strokeWidth),
    boxShadow: hard(shadow, shadowColor ?? stroke),
  );

  // ---- type ----------------------------------------------------------------

  static const displayFamily = 'BagelFatOne';
  static const uiFamily = 'Outfit';

  /// Display face. Bagel Fat One has one weight; the ink drop is what gives it
  /// its sticker weight, so [shadow] defaults on. Pass 0 for flat ink titles.
  static TextStyle display(
    double size, {
    Color color = ink,
    double shadow = 0,
    double height = 1.0,
    double letterSpacing = 0,
  }) => TextStyle(
    fontFamily: displayFamily,
    fontSize: size,
    height: height,
    letterSpacing: letterSpacing,
    color: color,
    shadows: shadow > 0
        ? [Shadow(color: ink, offset: Offset(shadow, shadow + 1))]
        : null,
  );

  /// Outfit at any weight.
  static TextStyle ui(
    double size, {
    FontWeight weight = FontWeight.w600,
    Color color = ink,
    double? height,
    double letterSpacing = 0,
  }) => TextStyle(
    fontFamily: uiFamily,
    fontSize: size,
    fontWeight: weight,
    color: color,
    height: height,
    letterSpacing: letterSpacing,
  );

  /// 11/800/+2 caps label.
  static TextStyle caps({double size = 11, Color color = inkMuted}) =>
      TextStyle(
        fontFamily: uiFamily,
        fontSize: size,
        fontWeight: FontWeight.w800,
        letterSpacing: 2,
        height: 1.2,
        color: color,
      );

  /// Timers and counters: tabular, so 9 → 10 does not shift the row.
  static TextStyle numbers(
    double size, {
    Color color = ink,
    FontWeight weight = FontWeight.w800,
  }) => TextStyle(
    fontFamily: uiFamily,
    fontSize: size,
    fontWeight: weight,
    height: 1.1,
    color: color,
    fontFeatures: const [FontFeature.tabularFigures()],
  );

  // ---- motion --------------------------------------------------------------

  /// Whether flourishes should be skipped. State changes still happen; only
  /// the decoration around them is dropped.
  static bool calm(BuildContext context) =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false;
}

/// One of the four grounds a screen can stand on.
enum ToySurface {
  /// Cream with ink dots. Almost every screen.
  cream(Toy.cream, Toy.creamDot, Brightness.dark),

  /// Blue with white dots: the daily challenge.
  daily(Toy.blue, Color(0x33FFFFFF), Brightness.light),

  /// Blue under rays: the win screen. No dots — the rays are the texture.
  win(Toy.blue, Color(0x00000000), Brightness.light),

  /// Tomato with ink dots: the splash and first frame.
  splash(Toy.tomato, Color(0x241F1A33), Brightness.light);

  final Color background;
  final Color dot;

  /// Status and navigation bar ICON brightness for this ground.
  final Brightness icons;

  const ToySurface(this.background, this.dot, this.icons);

  SystemUiOverlayStyle get overlay => SystemUiOverlayStyle(
    statusBarColor: const Color(0x00000000),
    systemNavigationBarColor: const Color(0x00000000),
    statusBarIconBrightness: icons,
    systemNavigationBarIconBrightness: icons,
    // iOS reads the inverse: the brightness of the BAR, not the icons.
    statusBarBrightness: icons == Brightness.dark
        ? Brightness.light
        : Brightness.dark,
  );
}

/// The dotted ground: a 16px grid of 1.2px dots.
///
/// Drawn as ONE `drawPoints` call with round caps rather than a circle per
/// dot. A tall screen is ~2,000 dots, and that difference is visible on the
/// low-end Android this game has to hold 60fps on.
class DotGridPainter extends CustomPainter {
  const DotGridPainter({
    this.background = Toy.cream,
    this.dot = Toy.creamDot,
    this.spacing = 16,
    this.radius = 1.2,
  });

  DotGridPainter.surface(ToySurface surface)
    : this(background: surface.background, dot: surface.dot);

  final Color background;
  final Color dot;
  final double spacing;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = background);
    if (dot.a == 0) return;

    final points = <Offset>[
      for (var y = spacing / 2; y < size.height; y += spacing)
        for (var x = spacing / 2; x < size.width; x += spacing) Offset(x, y),
    ];
    canvas.drawPoints(
      PointMode.points,
      points,
      Paint()
        ..color = dot
        ..strokeWidth = radius * 2
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(DotGridPainter old) =>
      old.background != background ||
      old.dot != dot ||
      old.spacing != spacing ||
      old.radius != radius;
}

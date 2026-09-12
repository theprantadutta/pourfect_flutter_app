/// Where every level sits on the winding path, and how it is drawn.
///
/// **Geometry is a pure function of the level number**, not a layout pass. A
/// level is always in the same place, on every launch and every device width,
/// which is what makes the path feel like a map rather than a list that happens
/// to wiggle. It also means scrolling to a level is arithmetic.
///
/// **Painted, never built.** 150 levels as widgets is 150 layouts on a scroll
/// that has to stay inside a 16.67ms frame, and the measured budget here is
/// already 1.2ms build plus 4.5ms raster in steady play. One painter draws the
/// lot and a hit test maps a tap back to a level, so the whole campaign costs
/// one widget.
library;

import 'dart:math' as math;
import 'dart:ui' show PointMode;

import 'package:flutter/material.dart';

import '../theme/ball_palette.dart';
import '../theme/tokens.dart';
import 'ball.dart' show paintBallGlyph;

/// Vertical distance between consecutive levels.
/// Tuned on a device, not guessed. At 104 only five levels fitted a screen and
/// the path read as scattered marbles. 52 is as tight as the swing allows
/// before consecutive levels start to overlap on a narrow phone.
const double kJourneyStep = 52;

/// How far the path swings either side of centre, as a fraction of width.
const double _kSwing = 0.30;

/// Levels per full left-right-left cycle. Non-integer on purpose: a whole
/// number lines every nth level up in a column and the eye finds the grid.
const double _kPeriod = 7.5;

/// Room above the first level and below the last, so neither is jammed into a
/// screen edge.
const double kJourneyPadTop = 180;
// Room for a band label beside level 1 and no more. It was 240 to clear a
// floating action bar that now lives in the fixed head above the path, and
// the difference was dead space under the first level.
const double kJourneyPadBottom = 90;

/// Total scrollable height for [levelCount] levels.
double journeyHeight(int levelCount) =>
    kJourneyPadTop + kJourneyPadBottom + (levelCount - 1) * kJourneyStep;

/// Where a level sits, in the path's own coordinate space.
///
/// Level 1 is at the BOTTOM and the campaign climbs. Going up as you progress
/// is the whole reason the shape means anything.
Offset journeyPosition(int levelId, int levelCount, double width) {
  final fromBottom = levelId - 1;
  final y = journeyHeight(levelCount) - kJourneyPadBottom -
      fromBottom * kJourneyStep;
  final x = width / 2 +
      math.sin(fromBottom / _kPeriod * 2 * math.pi) * width * _kSwing;
  return Offset(x, y);
}

/// One level's state on the path.
enum JourneyMark { locked, unlocked, solved, current }

class JourneyLevel {
  const JourneyLevel({
    required this.id,
    required this.mark,
    required this.stars,
    required this.colorId,
  });

  final int id;
  final JourneyMark mark;
  final int stars;

  /// Which ball a solved level shows. Derived from the level number so the
  /// path has the palette running through it rather than one repeated hue.
  final int colorId;
}

/// A band's name and size, pinned to its first level.
class JourneyBand {
  const JourneyBand({
    required this.firstLevel,
    required this.name,
    required this.length,
    required this.reached,
  });

  final int firstLevel;
  final String name;
  final int length;

  /// Dimmed until the player has arrived, so the path ahead reads as unwritten.
  final bool reached;
}

class JourneyPainter extends CustomPainter {
  JourneyPainter({
    required this.levels,
    required this.bands,
    required this.tokens,
    required this.boldGlyphs,
    required this.pulse,
    required this.visibleTop,
    required this.visibleBottom,
  });

  final List<JourneyLevel> levels;
  final List<JourneyBand> bands;
  final PourfectTokens tokens;
  final bool boldGlyphs;

  /// 0-1, drives the current level's breathing ring. The only thing that
  /// animates, so the repaint it forces is confined to this painter.
  final double pulse;

  /// The slice of the path actually on screen.
  ///
  /// The canvas is the whole campaign — around 16,000px — and the pulse
  /// repaints it every frame. Without this, a breathing ring costs 150 circles
  /// and 450 dots per frame, nearly all of them off screen. Clipping to the
  /// viewport turns that into the dozen that can be seen.
  final double visibleTop;
  final double visibleBottom;

  bool _onScreen(double y) =>
      y >= visibleTop - kJourneyStep && y <= visibleBottom + kJourneyStep;

  static const double _ball = 34;

  @override
  void paint(Canvas canvas, Size size) {
    final count = levels.length;
    Offset at(int id) => journeyPosition(id, count, size.width);

    _paintTrail(canvas, size, count, at);

    for (final band in bands) {
      final centre = at(band.firstLevel);
      if (_onScreen(centre.dy)) _paintBandMarker(canvas, band, centre);
    }

    for (final level in levels) {
      final centre = at(level.id);
      if (_onScreen(centre.dy)) _paintLevel(canvas, level, centre);
    }
  }

  /// The breadcrumbs between levels.
  ///
  /// Three small dots rather than a drawn line: a continuous stroke reads as a
  /// track to be followed, and the design wants stepping stones. Drawn as one
  /// batched point call, not three canvas ops per gap.
  void _paintTrail(
    Canvas canvas,
    Size size,
    int count,
    Offset Function(int) at,
  ) {
    final dots = <Offset>[];
    for (var id = 1; id < count; id++) {
      final a = at(id);
      if (!_onScreen(a.dy)) continue;
      final b = at(id + 1);
      for (var i = 1; i <= 3; i++) {
        dots.add(Offset.lerp(a, b, i / 4)!);
      }
    }
    if (dots.isEmpty) return;

    canvas.drawPoints(
      PointMode.points,
      dots,
      Paint()
        ..color = tokens.hairlineStrong
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round
        ..isAntiAlias = true,
    );
  }

  void _paintLevel(Canvas canvas, JourneyLevel level, Offset centre) {
    final r = _ball / 2;

    switch (level.mark) {
      case JourneyMark.locked:
        canvas.drawCircle(
          centre,
          r * 0.62,
          Paint()
            ..color = tokens.hairline
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5
            ..isAntiAlias = true,
        );

      case JourneyMark.unlocked:
        canvas.drawCircle(
          centre,
          r * 0.8,
          Paint()
            ..color = tokens.hairlineStrong
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2
            ..isAntiAlias = true,
        );

      case JourneyMark.solved:
        _paintBall(canvas, centre, r, level.colorId, 1);

      case JourneyMark.current:
        // THE ACCENT, not a palette color.
        //
        // Deriving this one from the level number the way solved levels are
        // derived put the player's own position on indigo — the darkest ball
        // there is — so "where you are" was the least visible thing on a
        // near-black screen. Where you are is fixed and bright by definition.
        //
        // Two rings, scale and alpha only. No blur: a live blur on a scrolling
        // surface is the one thing this engine cannot afford.
        for (final ring in [0.0, 1.0]) {
          canvas.drawCircle(
            centre,
            r + 8 + ring * 10 + pulse * 8,
            Paint()
              ..color = tokens.accent
                  .withValues(alpha: (0.34 - ring * 0.18) * (1 - pulse * 0.6))
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2
              ..isAntiAlias = true,
          );
        }

        canvas.drawCircle(
          centre,
          r * 1.25,
          Paint()
            ..color = tokens.accent
            ..isAntiAlias = true,
        );
        canvas.drawCircle(
          centre,
          r * 0.42,
          Paint()
            ..color = tokens.surface
            ..isAntiAlias = true,
        );
    }
  }

  void _paintBall(
    Canvas canvas,
    Offset centre,
    double radius,
    int colorId,
    double opacity,
  ) {
    final style = kBallPalette[colorId % kBallPalette.length];
    final color = Color(0xFF000000 | style.rgb).withValues(alpha: opacity);

    canvas.drawCircle(
      centre,
      radius,
      Paint()
        ..color = color
        ..isAntiAlias = true,
    );

    // The glyph is not decoration. Color is never the only cue in this game,
    // and the path is where a color-blind player reads their own progress.
    canvas.save();
    canvas.translate(centre.dx - radius, centre.dy - radius);
    paintBallGlyph(
      canvas,
      Size(radius * 2, radius * 2),
      style.glyph,
      bold: boldGlyphs,
      opacity: opacity,
    );
    canvas.restore();
  }

  /// A band's name, set beside its first level rather than across the path.
  void _paintBandMarker(Canvas canvas, JourneyBand band, Offset centre) {
    final onLeft = centre.dx > 0;
    final painter = TextPainter(
      text: TextSpan(
        text: '${band.name.toUpperCase()}  ·  ${band.length}',
        style: TextStyle(
          fontFamily: 'JetBrainsMono',
          fontSize: 11,
          letterSpacing: 2,
          fontWeight: FontWeight.w500,
          color: band.reached ? tokens.textMuted : tokens.dimText,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    // Placed on whichever side has room, so a label never crosses the path.
    final dx = onLeft
        ? centre.dx - _ball / 2 - 14 - painter.width
        : centre.dx + _ball / 2 + 14;

    painter.paint(canvas, Offset(dx, centre.dy - painter.height / 2));
  }

  /// Which level a tap landed on, or null.
  ///
  /// Generous radius: these are 34px targets on a path, and the alternative to
  /// a forgiving hit test is a player tapping three times.
  static int? levelAt(Offset point, int count, double width) {
    for (var id = 1; id <= count; id++) {
      if ((journeyPosition(id, count, width) - point).distance <= 30) return id;
    }
    return null;
  }

  @override
  bool shouldRepaint(JourneyPainter old) =>
      old.pulse != pulse ||
      old.levels != levels ||
      old.bands != bands ||
      old.boldGlyphs != boldGlyphs ||
      old.visibleTop != visibleTop ||
      old.visibleBottom != visibleBottom;
}

/// The ball: a toy disc with an ink outline, carrying its accessibility glyph.
///
/// Glyph geometry here MIRRORS `tool/cvd_harness.dart` exactly, in the same
/// normalised 100x100 space (100 = the disc inside its outline). The harness is
/// the artifact the palette was signed off against, so if these two ever
/// drift, the proof sheet stops proving anything about the shipped game.
library;

import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../theme/ball_palette.dart';
import '../theme/tokens.dart';
import '../theme/toy.dart';

/// A single ball, painted at [size].
class Ball extends StatelessWidget {
  final int colorId;
  final double size;

  /// Vertical squash factor. 1.0 is at rest; the landing settle drives this
  /// below 1 and lets it spring back, and flight stretches it above 1.
  final double squash;

  /// Dimming applied when this ball's tube cannot receive the held run.
  final double opacity;

  /// 0-1 yellow ring flash, for a tube completing and the win sequence.
  final double glow;

  /// Paints the hard ink drop under the ball — a lifted or flying ball.
  final bool drop;

  /// Draws the glyph larger. The glyph is ALWAYS drawn — it is not a mode to
  /// discover in a menu. This only controls emphasis, for a player who needs
  /// the shape rather than the color to carry the whole distinction.
  final bool boldGlyph;

  const Ball({
    super.key,
    required this.colorId,
    required this.size,
    this.squash = 1,
    this.opacity = 1,
    this.glow = 0,
    this.drop = false,
    this.boldGlyph = false,
  });

  @override
  Widget build(BuildContext context) {
    // Squash preserves volume: as the ball flattens it widens, which is what
    // makes a landing read as weight rather than as a scale animation.
    final s = squash.clamp(0.35, 1.6);
    final width = size / math.sqrt(s);
    final height = size * s;

    final painted = SizedBox(
      width: size,
      height: size,
      // Both bounds pinned: a stretched ball is NARROWER than its slot, and a
      // max below the parent's tight min is an invalid constraint.
      child: OverflowBox(
        minWidth: width,
        maxWidth: width,
        minHeight: height,
        maxHeight: height,
        child: SizedBox(
          width: width,
          height: height,
          child: CustomPaint(
            painter: BallPainter(
              color: ballColor(colorId),
              ink: ballGlyphInk(colorId),
              glyph: ballGlyph(colorId),
              glow: glow,
              drop: drop,
              bold: boldGlyph,
            ),
          ),
        ),
      ),
    );
    return opacity >= 1 ? painted : Opacity(opacity: opacity, child: painted);
  }
}

/// Paints one toy ball into its size. Public so other painters (the journey
/// path, confetti) can draw balls without a widget each.
class BallPainter extends CustomPainter {
  final Color color;
  final Color ink;
  final BallGlyph glyph;
  final double glow;
  final bool drop;
  final bool bold;

  const BallPainter({
    required this.color,
    required this.glyph,
    this.ink = Toy.ink,
    this.glow = 0,
    this.drop = false,
    this.bold = false,
  });

  @override
  void paint(Canvas canvas, Size size) =>
      paintToyBall(
        canvas,
        Offset.zero & size,
        color: color,
        glyph: glyph,
        glyphInk: ink,
        glow: glow,
        drop: drop,
        bold: bold,
      );

  @override
  bool shouldRepaint(BallPainter old) =>
      old.color != color ||
      old.ink != ink ||
      old.glyph != glyph ||
      old.glow != glow ||
      old.drop != drop ||
      old.bold != bold;
}

/// Draws a toy ball filling [rect]: fill, bottom shade, top highlight, ink
/// outline, glyph.
///
/// Every measurement scales with the diameter against the 40px reference the
/// mockups were drawn at, so a 22px preview ball and a 58px board ball are the
/// same object at different sizes.
void paintToyBall(
  Canvas canvas,
  Rect rect, {
  required Color color,
  required BallGlyph glyph,
  Color glyphInk = Toy.ink,
  double glow = 0,
  bool drop = false,
  bool bold = false,
  double opacity = 1,
}) {
  final k = rect.shortestSide / 40;
  final stroke = Toy.stroke * k;
  final centre = rect.center;
  final oval = rect.deflate(stroke / 2);

  Color a(Color c) => opacity >= 1 ? c : c.withValues(alpha: c.a * opacity);

  if (glow > 0) {
    canvas.drawOval(
      rect.inflate(2 * k + 5 * k * glow),
      Paint()
        ..color = a(Toy.yellow.withValues(alpha: 0.9 * glow))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5 * k,
    );
  }

  if (drop) {
    canvas.drawOval(rect.shift(Offset(0, 4 * k)), Paint()..color = a(Toy.ink));
  }

  canvas.drawOval(oval, Paint()..color = a(color));

  // The two inset bands from the mockup's box-shadow: a shade along the bottom
  // and a highlight along the top, both crescents of the disc against a copy
  // of itself nudged vertically. Solid, no gradient — this is a toy, not glass.
  final disc = Path()..addOval(oval);
  canvas
    ..save()
    ..clipPath(disc)
    ..drawPath(
      Path.combine(
        PathOperation.difference,
        disc,
        Path()..addOval(oval.shift(Offset(0, -4 * k))),
      ),
      Paint()..color = a(const Color(0x29000000)),
    )
    ..drawPath(
      Path.combine(
        PathOperation.difference,
        disc,
        Path()..addOval(oval.shift(Offset(0, 3 * k))),
      ),
      Paint()..color = a(const Color(0x73FFFFFF)),
    )
    ..restore();

  canvas.drawOval(
    oval,
    Paint()
      ..color = a(Toy.ink)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke,
  );

  final inner = Rect.fromCenter(
    center: centre,
    width: rect.width - stroke * 2,
    height: rect.height - stroke * 2,
  );
  paintBallGlyph(
    canvas,
    inner,
    glyph,
    ink: a(glyphInk),
    background: a(color),
    bold: bold,
  );
}

/// Draws [glyph] into [rect] (the disc inside its outline) in solid [ink].
///
/// [background] is the ball's own color, used to knock out the ring and arc
/// holes so they read as holes on any ground.
void paintBallGlyph(
  Canvas canvas,
  Rect rect,
  BallGlyph glyph, {
  required Color ink,
  required Color background,
  bool bold = false,
}) {
  final scale = bold ? 1.18 : 1.0;
  final sx = rect.width / 100 * scale;
  final sy = rect.height / 100 * scale;
  final ox = rect.center.dx - 50 * sx;
  final oy = rect.center.dy - 50 * sy;
  Offset p(double x, double y) => Offset(ox + x * sx, oy + y * sy);
  Rect r(double l, double t, double w, double h) =>
      Rect.fromLTWH(ox + l * sx, oy + t * sy, w * sx, h * sy);
  Path poly(List<List<double>> pts) {
    final path = Path()..moveTo(p(pts[0][0], pts[0][1]).dx, p(pts[0][0], pts[0][1]).dy);
    for (final pt in pts.skip(1)) {
      path.lineTo(p(pt[0], pt[1]).dx, p(pt[0], pt[1]).dy);
    }
    return path..close();
  }

  final fill = Paint()
    ..color = ink
    ..isAntiAlias = true;
  final hole = Paint()..color = background;

  // Coordinates below are in the 100-unit space and must match _ballSvg in
  // tool/cvd_harness.dart.
  switch (glyph) {
    case BallGlyph.dot:
      canvas.drawOval(r(37, 37, 26, 26), fill);
    case BallGlyph.ring:
      canvas
        ..drawOval(r(27, 27, 46, 46), fill)
        ..drawOval(r(39, 39, 22, 22), hole);
    case BallGlyph.triangle:
      canvas.drawPath(
        poly([
          [50, 29],
          [71, 66],
          [29, 66],
        ]),
        fill,
      );
    case BallGlyph.square:
      canvas.drawRRect(
        RRect.fromRectAndRadius(r(34, 34, 32, 32), Radius.circular(4.5 * sx)),
        fill,
      );
    case BallGlyph.plus:
    case BallGlyph.cross:
      canvas.save();
      if (glyph == BallGlyph.cross) {
        final c = p(50, 50);
        canvas
          ..translate(c.dx, c.dy)
          ..rotate(math.pi / 4)
          ..translate(-c.dx, -c.dy);
      }
      final radius = Radius.circular(2.5 * sx);
      canvas
        ..drawRRect(RRect.fromRectAndRadius(r(27, 45.4, 46, 9.2), radius), fill)
        ..drawRRect(RRect.fromRectAndRadius(r(45.4, 27, 9.2, 46), radius), fill)
        ..restore();
    case BallGlyph.bar:
      canvas.drawRRect(
        RRect.fromRectAndRadius(r(25, 41.5, 50, 17), Radius.circular(5 * sx)),
        fill,
      );
    case BallGlyph.diamond:
      final c = p(50, 50);
      canvas
        ..save()
        ..translate(c.dx, c.dy)
        ..rotate(math.pi / 4)
        ..translate(-c.dx, -c.dy)
        ..drawRRect(
          RRect.fromRectAndRadius(r(35, 35, 30, 30), Radius.circular(3 * sx)),
          fill,
        )
        ..restore();
    case BallGlyph.arc:
      // The top half of a ring whose centre sits below the middle.
      canvas
        ..save()
        ..clipRect(r(0, 0, 100, 61))
        ..drawOval(r(25, 36, 50, 50), fill)
        ..drawOval(r(37, 48, 26, 26), hole)
        ..restore();
    case BallGlyph.hexagon:
      canvas.drawPath(
        poly([
          [40, 32],
          [60, 32],
          [70, 50],
          [60, 68],
          [40, 68],
          [30, 50],
        ]),
        fill,
      );
  }
}

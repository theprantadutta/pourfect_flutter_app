/// The ball: a colored disc carrying its accessibility glyph.
///
/// Geometry here MIRRORS `tool/cvd_harness.dart` exactly, in the same
/// normalised 100x100 space. The harness is the artifact the palette was signed
/// off against, so if these two ever drift, the proof sheet stops proving
/// anything about the shipped game.
library;

import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../theme/ball_palette.dart';
import '../theme/tokens.dart';

/// A single ball, painted at [size].
class Ball extends StatelessWidget {
  final int colorId;
  final double size;

  /// Vertical squash factor. 1.0 is at rest; the landing settle drives this
  /// below 1 and lets it spring back.
  final double squash;

  /// Dimming applied when this ball's tube cannot receive the held run.
  final double opacity;

  /// 0-1 glow used for the completion flourish.
  final double glow;

  /// Draws the glyph larger and at full contrast.
  ///
  /// The glyph is ALWAYS drawn — it is not a mode to discover in a menu. This
  /// only controls emphasis, for a player who needs the shape rather than the
  /// color to carry the whole distinction. See Settings.
  final bool boldGlyph;

  const Ball({
    super.key,
    required this.colorId,
    required this.size,
    this.squash = 1,
    this.opacity = 1,
    this.glow = 0,
    this.boldGlyph = false,
  });

  @override
  Widget build(BuildContext context) {
    // Squash preserves volume: as the ball flattens it widens, which is what
    // makes a landing read as weight rather than as a scale animation.
    final width = size / math.sqrt(squash.clamp(0.35, 1.6));
    final height = size * squash.clamp(0.35, 1.6);

    return Opacity(
      opacity: opacity,
      child: SizedBox(
        width: size,
        height: size,
        child: Center(
          child: SizedBox(
            width: width,
            height: height,
            child: CustomPaint(
              painter: _BallPainter(
                color: ballColor(colorId),
                glyph: ballGlyph(colorId),
                glow: glow,
                bold: boldGlyph,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BallPainter extends CustomPainter {
  final Color color;
  final BallGlyph glyph;
  final double glow;
  final bool bold;

  _BallPainter({
    required this.color,
    required this.glyph,
    required this.glow,
    required this.bold,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final centre = rect.center;

    if (glow > 0) {
      canvas.drawCircle(
        centre,
        size.width * 0.5 + 6 * glow,
        Paint()
          ..color = color.withValues(alpha: 0.35 * glow)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 8 * glow),
      );
    }

    // A single soft top-left light, not a bevel. Real objects under diffuse
    // light have one gentle gradient; the stacked highlight-plus-rim-plus-drop
    // -shadow treatment is what makes puzzle games look like toys.
    canvas.drawOval(
      rect,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.35, -0.45),
          radius: 0.95,
          colors: [
            Color.lerp(color, const Color(0xFFFFFFFF), 0.16)!,
            color,
            Color.lerp(color, const Color(0xFF000000), 0.22)!,
          ],
          stops: const [0, 0.55, 1],
        ).createShader(rect),
    );

    paintBallGlyph(canvas, size, glyph, bold: bold);
  }

  @override
  bool shouldRepaint(_BallPainter old) =>
      old.color != color ||
      old.glyph != glyph ||
      old.glow != glow ||
      old.bold != bold;
}

/// Glyphs are drawn in translucent ink rather than a per-color foreground,
/// so one rule works on the palest ball and the deepest without a lookup
/// table that would inevitably fall out of sync with the palette.
///
/// Public because the journey path paints its own balls: it draws hundreds on
/// a long scroll and cannot afford a widget each, and a second copy of this
/// switch would drift from the palette the first time a glyph changed.
void paintBallGlyph(
Canvas canvas,
Size size,
BallGlyph glyph, {
bool bold = false,
double opacity = 1,
}) {
  // Bold mode scales the glyph up and takes the ink to near-opaque, so shape
  // alone can carry the distinction.
  final scale = bold ? 1.18 : 1.0;
  final s = size.width / 100 * scale;
  final sy = size.height / 100 * scale;
  final ink = const Color(0xFF0A0C10)
      .withValues(alpha: (bold ? 0.92 : 0.72) * opacity);

  final fill = Paint()
    ..color = ink
    ..style = PaintingStyle.fill
    ..isAntiAlias = true;
  final stroke = Paint()
    ..color = ink
    ..style = PaintingStyle.stroke
    ..strokeWidth = 9 * s
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..isAntiAlias = true;

  final dx = (size.width - 100 * s) / 2;
  final dy = (size.height - 100 * sy) / 2;
  Offset p(double x, double y) => Offset(dx + x * s, dy + y * sy);

  switch (glyph) {
    case BallGlyph.dot:
      canvas.drawCircle(p(50, 50), 13 * s, fill);
    case BallGlyph.ring:
      canvas.drawCircle(p(50, 50), 17 * s, stroke);
    case BallGlyph.triangle:
      canvas.drawPath(
        Path()
          ..moveTo(p(50, 30).dx, p(50, 30).dy)
          ..lineTo(p(69, 64).dx, p(69, 64).dy)
          ..lineTo(p(31, 64).dx, p(31, 64).dy)
          ..close(),
        fill,
      );
    case BallGlyph.square:
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(dx + 33 * s, dy + 33 * sy, 34 * s, 34 * sy),
          Radius.circular(3 * s),
        ),
        fill,
      );
    case BallGlyph.plus:
      canvas
        ..drawLine(p(50, 30), p(50, 70), stroke)
        ..drawLine(p(30, 50), p(70, 50), stroke);
    case BallGlyph.bar:
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(dx + 28 * s, dy + 43 * sy, 44 * s, 14 * sy),
          Radius.circular(7 * s),
        ),
        fill,
      );
    case BallGlyph.diamond:
      canvas.drawPath(
        Path()
          ..moveTo(p(50, 28).dx, p(50, 28).dy)
          ..lineTo(p(70, 50).dx, p(70, 50).dy)
          ..lineTo(p(50, 72).dx, p(50, 72).dy)
          ..lineTo(p(30, 50).dx, p(30, 50).dy)
          ..close(),
        fill,
      );
    case BallGlyph.cross:
      canvas
        ..drawLine(p(35, 35), p(65, 65), stroke)
        ..drawLine(p(65, 35), p(35, 65), stroke);
    case BallGlyph.arc:
      canvas.drawArc(
        Rect.fromLTWH(dx + 30 * s, dy + 38 * sy, 40 * s, 48 * sy),
        math.pi,
        math.pi,
        false,
        stroke,
      );
    case BallGlyph.hexagon:
      canvas.drawPath(
        Path()
          ..moveTo(p(50, 28).dx, p(50, 28).dy)
          ..lineTo(p(69, 39).dx, p(69, 39).dy)
          ..lineTo(p(69, 61).dx, p(69, 61).dy)
          ..lineTo(p(50, 72).dx, p(50, 72).dy)
          ..lineTo(p(31, 61).dx, p(31, 61).dy)
          ..lineTo(p(31, 39).dx, p(31, 39).dy)
          ..close(),
        stroke,
      );
  }
}

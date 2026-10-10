/// The streak's two pictures: a flame for the run, a snowflake for a freeze.
///
/// Painted rather than taken from an icon font, like every other glyph in the
/// Toybox kit: chunky ink outlines, flat fills, nothing that looks borrowed.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/toy.dart';

/// A tomato flame with a yellow heart. Dimmed (grey) when [lit] is false — a
/// broken streak keeps its place but not its color.
class StreakFlame extends StatelessWidget {
  final double size;
  final bool lit;

  const StreakFlame({super.key, this.size = 24, this.lit = true});

  @override
  Widget build(BuildContext context) => SizedBox(
    width: size * 0.82,
    height: size,
    child: CustomPaint(painter: _FlamePainter(lit: lit)),
  );
}

class _FlamePainter extends CustomPainter {
  final bool lit;

  const _FlamePainter({required this.lit});

  Path _drop(Size s, double inset) {
    final w = s.width;
    final h = s.height;
    final l = w * inset;
    final r = w * (1 - inset);
    final top = h * (0.04 + inset * 0.9);
    final bottom = h * (0.97 - inset * 0.25);
    return Path()
      ..moveTo(w * 0.52, top)
      ..cubicTo(w * 0.62, h * 0.28, r, h * 0.38, r, h * 0.62)
      ..cubicTo(r, h * 0.84, w * 0.72, bottom, w * 0.5, bottom)
      ..cubicTo(w * 0.28, bottom, l, h * 0.84, l, h * 0.62)
      ..cubicTo(l, h * 0.46, w * 0.3, h * 0.4, w * 0.36, h * 0.24)
      ..cubicTo(w * 0.42, h * 0.32, w * 0.44, h * 0.18, w * 0.52, top)
      ..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final outer = _drop(size, 0.06);
    canvas.drawPath(outer, Paint()..color = lit ? Toy.tomato : Toy.toggleOff);
    final inner = _drop(size, 0.3);
    canvas.drawPath(inner, Paint()..color = lit ? Toy.yellow : Toy.card);
    canvas.drawPath(
      outer,
      Paint()
        ..color = Toy.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.6, size.width * 0.1)
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_FlamePainter old) => old.lit != lit;
}

/// Six arms with a V at each tip.
class StreakSnowflake extends StatelessWidget {
  final double size;
  final Color color;

  const StreakSnowflake({super.key, this.size = 18, this.color = Toy.ink});

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: CustomPaint(painter: _SnowflakePainter(color)),
  );
}

class _SnowflakePainter extends CustomPainter {
  final Color color;

  const _SnowflakePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide * 0.46;
    final line = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.6, size.shortestSide * 0.12)
      ..strokeCap = StrokeCap.round;

    for (var i = 0; i < 6; i++) {
      final a = i * math.pi / 3 - math.pi / 2;
      final tip = c + Offset(math.cos(a), math.sin(a)) * r;
      canvas.drawLine(c, tip, line);
      final mid = c + Offset(math.cos(a), math.sin(a)) * r * 0.62;
      for (final side in [-1, 1]) {
        final b = a + side * math.pi / 4;
        canvas.drawLine(
          mid,
          mid + Offset(math.cos(b), math.sin(b)) * r * 0.3,
          line,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_SnowflakePainter old) => old.color != color;
}

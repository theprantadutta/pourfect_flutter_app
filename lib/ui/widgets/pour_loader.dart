/// Pourfect's loading animation: the game, playing itself in miniature.
///
/// One tube. Four balls of one color drop in, each stretching as it falls and
/// squashing as it lands; the full tube flashes the yellow SORTED ring and
/// bumps; the balls drain away and the next color begins. It is the moment a
/// player works toward on every board, which makes waiting look like the game
/// rather than like a spinner bolted onto it.
///
/// Built from the real [Ball], so the colors, glyphs, squash and ring are
/// exactly the board's. One controller drives everything (four colors per
/// lap), and it runs only while the loader is on screen. Reduced motion shows
/// a sorted tube, still.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/toy.dart';
import 'ball.dart';

/// Colors the loader cycles through, one per pour.
const _kPourColors = [0, 3, 2, 1];

/// One pour: four drops, the flash, the drain, a breath.
const _kPourMs = 2200;

class PourLoader extends StatefulWidget {
  /// Ball diameter; the tube is sized around it.
  final double ballSize;

  /// A line under the tube, e.g. "Pouring today's board…". Optional.
  final String? caption;

  /// Caption color: ink on cream, white on the blue daily ground.
  final Color captionColor;

  const PourLoader({
    super.key,
    this.ballSize = 26,
    this.caption,
    this.captionColor = Toy.inkMuted,
  });

  @override
  State<PourLoader> createState() => _PourLoaderState();
}

class _PourLoaderState extends State<PourLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _clock = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: _kPourMs * _kPourColors.length),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (Toy.calm(context)) {
      _clock.stop();
    } else if (!_clock.isAnimating) {
      _clock.repeat();
    }
  }

  @override
  void dispose() {
    _clock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final calm = Toy.calm(context);
    return Semantics(
      label: widget.caption ?? 'Loading',
      liveRegion: true,
      child: ExcludeSemantics(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Its own layer: the loader repaints every frame, nothing around
            // it has to.
            RepaintBoundary(
              child: calm
                  ? _Tube(ballSize: widget.ballSize, lap: 0, t: 0.7)
                  : AnimatedBuilder(
                      animation: _clock,
                      builder: (context, _) {
                        final laps = _clock.value * _kPourColors.length;
                        return _Tube(
                          ballSize: widget.ballSize,
                          lap: laps.floor() % _kPourColors.length,
                          t: laps - laps.floor(),
                        );
                      },
                    ),
            ),
            if (widget.caption != null) ...[
              SizedBox(height: widget.ballSize * 0.7),
              Text(
                widget.caption!,
                textAlign: TextAlign.center,
                style: Toy.ui(
                  15,
                  weight: FontWeight.w700,
                  color: widget.captionColor,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// The tube at one instant of one pour. [t] runs 0-1 across the pour:
///
///     0.00-0.56  four balls drop, 0.14 apart
///     0.56-0.72  sorted: ring flash and a bump
///     0.72-0.90  the run drains down and out
///     0.90-1.00  empty, a breath before the next color
class _Tube extends StatelessWidget {
  final double ballSize;
  final int lap;
  final double t;

  const _Tube({required this.ballSize, required this.lap, required this.t});

  static const _capacity = 4;
  static const _dropSpan = 0.14;

  @override
  Widget build(BuildContext context) {
    final b = ballSize;
    final pad = b * 0.16;
    final gap = b * 0.08;
    final tubeW = b + pad * 2;
    final tubeH = b * _capacity + gap * (_capacity - 1) + pad * 2;
    final headroom = b * 2.2; // where a ball falls from
    final color = _kPourColors[lap];

    // Sorted flash and bump.
    final flash = t >= 0.56 && t < 0.72
        ? math.sin((t - 0.56) / 0.16 * math.pi)
        : 0.0;
    final bump = 1 + 0.06 * flash;

    // Drain: the whole run slides down and fades.
    final drain = ((t - 0.72) / 0.18).clamp(0.0, 1.0);
    final drainCurve = Curves.easeIn.transform(drain);

    final balls = <Widget>[];
    for (var i = 0; i < _capacity; i++) {
      final start = i * _dropSpan;
      final local = ((t - start) / _dropSpan).clamp(0.0, 1.0);
      if (t < start || (t >= 0.9)) continue;

      // Resting slot, bottom-first.
      final restTop = headroom + tubeH - pad - b * (i + 1) - gap * i;
      double top;
      double squash;
      if (local < 0.62) {
        // Falling: eased in, stretched by speed.
        final fall = Curves.easeIn.transform(local / 0.62);
        top = -b + (restTop + b) * fall;
        squash = 1 + 0.32 * fall;
      } else {
        // Landed: squash, then spring back.
        final settle = (local - 0.62) / 0.38;
        top = restTop;
        squash = 1 - 0.28 * math.sin(settle * math.pi) * (1 - settle);
      }

      top += drainCurve * b * 1.4;
      final opacity = 1 - drainCurve;

      balls.add(
        Positioned(
          top: top,
          left: pad + (tubeW - pad * 2 - b) / 2,
          child: Ball(
            colorId: color,
            size: b,
            squash: squash,
            opacity: opacity,
            glow: flash,
            drop: local < 0.62,
          ),
        ),
      );
    }

    return SizedBox(
      width: tubeW + 8,
      height: headroom + tubeH + 6,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          Positioned(
            top: headroom,
            child: Transform.scale(
              scale: bump,
              alignment: Alignment.bottomCenter,
              child: Container(
                width: tubeW,
                height: tubeH,
                decoration: BoxDecoration(
                  color: flash > 0
                      ? Color.lerp(Toy.card, Toy.sortedTubeFill, flash)
                      : Toy.card,
                  border: Border.all(color: Toy.ink, width: Toy.stroke),
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(8),
                    topRight: const Radius.circular(8),
                    bottomLeft: Radius.circular(tubeW / 2),
                    bottomRight: Radius.circular(tubeW / 2),
                  ),
                  boxShadow: Toy.hard(3),
                ),
              ),
            ),
          ),
          // The balls ride inside the tube's drawn outline but above its
          // fill, so a falling ball is visible from the moment it enters.
          Positioned.fill(
            left: 4,
            child: ClipRect(
              clipper: _AboveBottom(headroom + tubeH - Toy.stroke),
              child: Stack(clipBehavior: Clip.none, children: balls),
            ),
          ),
        ],
      ),
    );
  }
}

/// Clips draining balls at the tube's floor, so they pour OUT rather than
/// sliding through it.
class _AboveBottom extends CustomClipper<Rect> {
  final double floor;

  const _AboveBottom(this.floor);

  @override
  Rect getClip(Size size) =>
      Rect.fromLTRB(-100, -1000, size.width + 100, floor);

  @override
  bool shouldReclip(_AboveBottom old) => old.floor != floor;
}

/// Three tiny balls hopping in turn: for inside a button, where a whole
/// loader would not fit. White glyph-less dots on a colored button.
class BounceDots extends StatefulWidget {
  final Color color;
  final double size;

  const BounceDots({super.key, this.color = Colors.white, this.size = 7});

  @override
  State<BounceDots> createState() => _BounceDotsState();
}

class _BounceDotsState extends State<BounceDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _clock = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat();

  @override
  void dispose() {
    _clock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.size;
    return Semantics(
      label: 'Working',
      child: SizedBox(
        width: s * 3 + s * 1.2,
        height: s * 2.4,
        child: AnimatedBuilder(
          animation: _clock,
          builder: (context, _) => Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (var i = 0; i < 3; i++)
                Transform.translate(
                  offset: Offset(
                    0,
                    -s *
                        1.2 *
                        math.max(
                          0,
                          math.sin((_clock.value - i * 0.18) * 2 * math.pi),
                        ),
                  ),
                  child: Container(
                    width: s,
                    height: s,
                    decoration: BoxDecoration(
                      color: widget.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

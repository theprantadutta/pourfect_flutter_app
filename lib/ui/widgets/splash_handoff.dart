/// The seam between the native splash and the first real screen.
///
/// The first Flutter frame paints EXACTLY what the native splash was showing,
/// so the engine taking over is invisible:
///
///  * **Android 12+** shows only the icon — `android12_splash_icon_1152.png`
///    at 288dp, centered, which is just the amber ball. The handoff starts
///    from that, then lifts and shrinks the ball onto the full logo's ball and
///    cross-fades the wordmark in around it. Measured on the A24: native ball
///    130dp, 4dp below center; logo ball 120dp, 34dp above.
///  * **Everything else** (iOS, older Android) shows `splash_logo_1200.png`
///    at 300dp, and the handoff starts from that and bounces it.
///
/// Then the dots, the POUR · SORT · RELAX tag and three balls arrive, and the
/// whole thing fades off the hub underneath.
///
/// It is short on purpose (about 900ms) and a tap ends it. This plays on every
/// cold start, and a launch animation somebody has to sit through on their
/// fortieth open is a tax on exactly the players retention depends on.
library;

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../theme/ball_palette.dart';
import '../theme/toy.dart';
import 'toy_kit.dart';

class SplashHandoff extends StatefulWidget {
  final VoidCallback onDone;

  const SplashHandoff({super.key, required this.onDone});

  @override
  State<SplashHandoff> createState() => _SplashHandoffState();
}

class _SplashHandoffState extends State<SplashHandoff>
    with SingleTickerProviderStateMixin {
  late final AnimationController _t = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..addStatusListener((s) {
      if (s == AnimationStatus.completed) widget.onDone();
    });

  bool _begun = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_begun) return;
    _begun = true;
    // Reduced motion: no bounce, just a quick fade to the hub.
    if (Toy.calm(context)) _t.duration = const Duration(milliseconds: 250);

    // The first frame is held until the logo is decoded. Otherwise the
    // native splash hands over to a tomato screen with NO logo for a frame or
    // two, which is precisely the jump this widget exists to prevent.
    final binding = WidgetsBinding.instance..deferFirstFrame();
    Future.wait([
      precacheImage(_logo, context),
      if (_fromIcon) precacheImage(_icon, context),
    ]).whenComplete(() {
      binding.allowFirstFrame();
      if (mounted) _t.forward();
    });
  }

  static const _logo = AssetImage('assets/brand/splash_logo_1200.png');
  static const _icon = AssetImage(
    'assets/brand/android12_splash_icon_1152.png',
  );

  /// Android's native splash is the icon alone (every Android the game
  /// supports in practice is 12+); elsewhere it is the full logo.
  bool get _fromIcon => defaultTargetPlatform == TargetPlatform.android;

  @override
  void dispose() {
    _t.dispose();
    super.dispose();
  }

  double _span(double from, double to) =>
      ((_t.value - from) / (to - from)).clamp(0.0, 1.0);

  /// The icon rises onto the logo's ball; the logo fades in under it.
  List<Widget> _fromIconLayers(bool calm) {
    final rise = calm ? 1.0 : Curves.easeOutBack.transform(_span(0.06, 0.4));
    final swap = calm ? 1.0 : _span(0.32, 0.46);
    // Native ball: 130dp, 4dp below center. Logo ball: 120dp, 34dp above.
    const endScale = 120 / 130;
    final scale = 1 + (endScale - 1) * rise;
    final dy = (-34 - 4 * endScale) * rise;
    return [
      Center(
        child: Opacity(
          opacity: swap,
          child: const Image(
            image: _logo,
            width: 300,
            height: 300,
            gaplessPlayback: true,
          ),
        ),
      ),
      Center(
        child: Opacity(
          opacity: 1 - swap,
          child: Transform.translate(
            offset: Offset(0, dy),
            child: Transform.scale(
              scale: scale,
              child: const Image(
                image: _icon,
                width: 288,
                height: 288,
                gaplessPlayback: true,
              ),
            ),
          ),
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final calm = Toy.calm(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _t.value = 1,
      child: AnimatedBuilder(
        animation: _t,
        builder: (context, _) {
          final extras = calm ? 0.0 : _span(0.1, 0.35);
          final fadeOut = calm ? _t.value : _span(0.72, 1);
          // Down, squash, up past rest, settle: two bounces in ~500ms.
          final b = calm ? 1.0 : _span(0.05, 0.6);
          final bounce = calm ? 0.0 : math.sin(b * math.pi * 2) * (1 - b) * 14;
          final squash = calm
              ? 1.0
              : 1 - 0.06 * math.max(0, math.sin(b * math.pi * 2 - math.pi));

          return Opacity(
            opacity: 1 - fadeOut,
            child: Material(
              color: Toy.tomato,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Opacity(
                    opacity: extras,
                    child: CustomPaint(
                      painter: DotGridPainter.surface(ToySurface.splash),
                    ),
                  ),
                  if (_fromIcon) ..._fromIconLayers(calm) else
                    Center(
                      child: Transform.translate(
                        offset: Offset(0, bounce),
                        child: Transform(
                          alignment: Alignment.bottomCenter,
                          transform: Matrix4.diagonal3Values(
                            2 - squash,
                            squash,
                            1,
                          ),
                          child: const Image(
                            image: _logo,
                            width: 300,
                            height: 300,
                            gaplessPlayback: true,
                          ),
                        ),
                      ),
                    ),
                  // Tag and balls sit below the logo and arrive after it has
                  // landed; they are extras, not part of the native frame.
                  Align(
                    alignment: const Alignment(0, 0.42),
                    child: Opacity(
                      opacity: extras,
                      child: Transform.rotate(
                        angle: -2 * math.pi / 180,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Toy.ink,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'POUR · SORT · RELAX',
                            style: Toy.caps(size: 14, color: Toy.cream),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Align(
                    alignment: const Alignment(0, 0.82),
                    child: Opacity(
                      opacity: extras,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (final id in const [3, 1, 2])
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 6),
                              child: ToyBall(
                                color: Color(0xFF000000 | kBallPalette[id].rgb),
                                glyph: kBallPalette[id].glyph,
                                size: 20,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

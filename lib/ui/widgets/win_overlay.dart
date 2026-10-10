/// The level-complete sequence, in two acts.
///
/// **The win moment** plays ON the board. The last ball lands, the board bumps,
/// yellow rays open up behind it and confetti — real balls, glyphs and all —
/// bursts out of the finished tubes. The solved tubes wear their SORTED!
/// stickers. The board is the trophy, so nothing covers it yet.
///
/// **The result** follows: a cross-fade to the blue ground, the title slamming
/// in, the stars dropping one by one, the solved board on a card, the numbers,
/// the world bar and NEXT LEVEL. It is a whole screen, not a dialog — it has
/// the room to be a celebration rather than an alert box.
///
/// Timing comes from `win_profile.dart`; this file only draws, as a pure
/// function of the elapsed time, so the screen can skip to the end by setting
/// one number.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../engine/board.dart';
import '../format.dart';
import '../theme/ball_palette.dart';
import '../theme/toy.dart';
import 'ball.dart';
import 'toy_kit.dart';
import 'win_profile.dart';

double _span(double elapsedMs, int at, int length) => length <= 0
    ? (elapsedMs >= at ? 1 : 0)
    : ((elapsedMs - at) / length).clamp(0.0, 1.0);

/// The title for a result. It does not always say the same thing: the words
/// are part of the reward, and three stars should read differently from one.
String winTitle(int stars) => switch (stars) {
  >= 3 => 'Perfect\nPour!',
  2 => 'Nice\nPour!',
  _ => 'Poured!',
};

// ---------------------------------------------------------------------------
// Rays
// ---------------------------------------------------------------------------

/// Sunburst rays turning slowly behind whatever is on top: yellow on cream for
/// the win moment, white on blue for the result. One turn every 20 seconds.
class WinRays extends StatefulWidget {
  final Color color;

  /// Where the rays converge, as an alignment in the box.
  final Alignment center;

  /// 0..1 fade.
  final double opacity;

  const WinRays({
    super.key,
    required this.color,
    this.center = const Alignment(0, -0.1),
    this.opacity = 1,
  });

  @override
  State<WinRays> createState() => _WinRaysState();
}

class _WinRaysState extends State<WinRays> with SingleTickerProviderStateMixin {
  late final AnimationController _turn = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 20),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (Toy.calm(context)) {
      _turn.stop();
    } else if (!_turn.isAnimating) {
      _turn.repeat();
    }
  }

  @override
  void dispose() {
    _turn.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.opacity <= 0) return const SizedBox.shrink();
    return IgnorePointer(
      child: Opacity(
        opacity: widget.opacity,
        child: RepaintBoundary(
          child: AnimatedBuilder(
            animation: _turn,
            builder: (context, _) => CustomPaint(
              size: Size.infinite,
              painter: _RaysPainter(
                color: widget.color,
                center: widget.center,
                angle: _turn.value * 2 * math.pi,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RaysPainter extends CustomPainter {
  final Color color;
  final Alignment center;
  final double angle;

  const _RaysPainter({
    required this.color,
    required this.center,
    required this.angle,
  });

  /// The fan, built once per radius and rotated with the canvas each frame,
  /// rather than recomputing 23 triangles 90 times a second.
  static final _fans = <double, Path>{};

  static Path _fan(double r) => _fans.putIfAbsent(r, () {
    // 8° on, 8° off, as the mockup's conic gradient.
    const step = math.pi / 22.5;
    final path = Path();
    for (var a = 0.0; a < 2 * math.pi; a += step * 2) {
      path
        ..moveTo(0, 0)
        ..lineTo(r * math.cos(a), r * math.sin(a))
        ..lineTo(r * math.cos(a + step), r * math.sin(a + step))
        ..close();
    }
    return path;
  });

  @override
  void paint(Canvas canvas, Size size) {
    final c = center.alongSize(size);
    // Far enough to reach every corner from wherever the rays converge.
    final r = (size.longestSide * 1.2).roundToDouble();
    canvas
      ..save()
      ..translate(c.dx, c.dy)
      ..rotate(angle)
      ..drawPath(_fan(r), Paint()..color = color)
      ..restore();
  }

  @override
  bool shouldRepaint(_RaysPainter old) =>
      old.angle != angle || old.color != color || old.center != center;
}

// ---------------------------------------------------------------------------
// Confetti
// ---------------------------------------------------------------------------

/// Toy balls bursting up and falling under gravity. Seeded, so a replay of the
/// same level throws the same handful — randomness that changes every frame
/// reads as noise, not as a burst.
class WinConfetti extends StatelessWidget {
  /// 0..1 through the confetti beat.
  final double t;
  final int seed;

  /// Where the burst comes from, as a fraction of the box: the board's middle.
  final Offset origin;

  const WinConfetti({
    super.key,
    required this.t,
    required this.seed,
    this.origin = const Offset(0.5, 0.45),
  });

  @override
  Widget build(BuildContext context) {
    if (t <= 0 || t >= 1) return const SizedBox.shrink();
    return IgnorePointer(
      child: CustomPaint(
        size: Size.infinite,
        painter: _ConfettiPainter(t: t, seed: seed, origin: origin),
      ),
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  final double t;
  final int seed;
  final Offset origin;

  const _ConfettiPainter({
    required this.t,
    required this.seed,
    required this.origin,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(seed);
    const count = 14;
    const seconds = 0.9;
    final time = t * seconds;
    final fade = t < 0.8 ? 1.0 : 1 - (t - 0.8) / 0.2;

    for (var i = 0; i < count; i++) {
      final style = kBallPalette[(i + seed) % kBallPalette.length];
      final x0 = size.width * (origin.dx + (rng.nextDouble() - 0.5) * 0.7);
      final y0 = size.height * origin.dy;
      final vx = (rng.nextDouble() - 0.5) * size.width * 1.1;
      final vy = -(size.height * (0.9 + rng.nextDouble() * 0.7));
      final g = size.height * 2.6;
      final d = 14.0 + rng.nextDouble() * 12;
      final spin = (rng.nextDouble() - 0.5) * 8;

      final p = Offset(x0 + vx * time, y0 + vy * time + 0.5 * g * time * time);
      canvas
        ..save()
        ..translate(p.dx, p.dy)
        ..rotate(spin * time);
      drawToyBall(
        canvas,
        Rect.fromCircle(center: Offset.zero, radius: d / 2),
        color: Color(0xFF000000 | style.rgb),
        glyph: style.glyph,
        glyphInk: Color(0xFF000000 | style.glyphInk),
        opacity: fade,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.t != t;
}

// ---------------------------------------------------------------------------
// The win moment caption
// ---------------------------------------------------------------------------

/// "Last pour…" over an ink pill with the count, where the action bar was.
class WinMomentCaption extends StatelessWidget {
  final int movesUsed;
  final int minMoves;
  final double opacity;

  const WinMomentCaption({
    super.key,
    required this.movesUsed,
    required this.minMoves,
    required this.opacity,
  });

  @override
  Widget build(BuildContext context) => Opacity(
    opacity: opacity,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Transform.rotate(
            angle: -3 * math.pi / 180,
            child: Text(
              'Last pour…',
              style: Toy.display(52, color: Toy.tomato, shadow: 3),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: Toy.ink,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$movesUsed ${movesUsed == 1 ? 'MOVE' : 'MOVES'} · PAR $minMoves',
              style: Toy.numbers(
                15,
                color: Colors.white,
                weight: FontWeight.w800,
              ).copyWith(letterSpacing: 1),
            ),
          ),
        ],
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// The result
// ---------------------------------------------------------------------------

/// The blue result screen.
class WinResult extends StatefulWidget {
  final WinProfile profile;
  final double elapsedMs;

  final int levelId;

  /// The finished board, drawn on a card as the trophy.
  final Board board;

  final int stars;
  final int movesUsed;
  final int minMoves;

  /// Previous personal best, if this level had been cleared before.
  final int? previousBest;
  final bool isNewBest;

  final String bandName;
  final int worldNumber;

  /// Levels cleared in this world BEFORE and AFTER this one, over its size.
  final int bandClearedBefore;
  final int bandClearedAfter;
  final int bandTotal;

  /// This run's clock, the pace it was scored against, and what it earned.
  final int elapsedSeconds;
  final int parSeconds;
  final int points;

  /// The player's own previous fastest on this level, or null if there was
  /// none — a first clear, or one from before the clock shipped.
  final int? previousFastest;

  /// Null when this was the last level available.
  final VoidCallback? onNext;
  final VoidCallback onReplay;
  final VoidCallback onLevels;

  /// Restarts for three stars. Offered on any clear short of three; null
  /// falls back to [onReplay].
  final VoidCallback? onTryForStars;

  /// Straight back to the hub. Null hides the button.
  final VoidCallback? onHome;

  /// The clear used a bought extra tube, which caps it at two stars.
  final bool assisted;

  /// True once the sequence has finished or been skipped — nothing on this
  /// screen accepts taps before that. See the skip layer in GameScreen.
  final bool interactive;

  const WinResult({
    super.key,
    required this.profile,
    required this.elapsedMs,
    required this.levelId,
    required this.board,
    required this.stars,
    required this.movesUsed,
    required this.minMoves,
    required this.previousBest,
    required this.isNewBest,
    required this.elapsedSeconds,
    required this.parSeconds,
    required this.points,
    required this.previousFastest,
    required this.bandName,
    required this.worldNumber,
    required this.bandClearedBefore,
    required this.bandClearedAfter,
    required this.bandTotal,
    required this.onNext,
    required this.onReplay,
    required this.onLevels,
    required this.interactive,
    this.onTryForStars,
    this.assisted = false,
    this.onHome,
  });

  @override
  State<WinResult> createState() => _WinResultState();
}

class _WinResultState extends State<WinResult>
    with SingleTickerProviderStateMixin {
  /// NEXT LEVEL breathing, 1 ↔ 1.03 over 1.6s. Full profile only.
  late final AnimationController _breath = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
  );

  @override
  void didUpdateWidget(WinResult old) {
    super.didUpdateWidget(old);
    _syncBreath();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncBreath();
  }

  void _syncBreath() {
    final breathe =
        widget.interactive && widget.profile.isFull && !Toy.calm(context);
    if (breathe && !_breath.isAnimating) {
      _breath.repeat(reverse: true);
    } else if (!breathe && _breath.isAnimating) {
      _breath
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _breath.dispose();
    super.dispose();
  }

  double _s(int at, int length) => _span(widget.elapsedMs, at, length);

  @override
  Widget build(BuildContext context) {
    final p = widget.profile;
    final beatPar =
        widget.parSeconds > 0 &&
        widget.elapsedSeconds > 0 &&
        widget.elapsedSeconds <= widget.parSeconds;
    final newFastest =
        widget.previousFastest != null &&
        widget.elapsedSeconds > 0 &&
        widget.elapsedSeconds < widget.previousFastest!;

    return IgnorePointer(
      ignoring: !widget.interactive,
      child: ToyScaffold(
        surface: ToySurface.win,
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        backdrop: WinRays(
          color: const Color(0x24FFFFFF),
          center: const Alignment(0, -0.55),
          opacity: p.isFull ? 1 : 0.6,
        ),
        child: LayoutBuilder(
          builder: (context, box) => SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: box.maxHeight),
              child: IntrinsicHeight(
                child: Column(
                  children: [
                    _topRow(),
                    const SizedBox(height: 10),
                    _title(),
                    const SizedBox(height: 10),
                    _stars(),
                    const SizedBox(height: 14),
                    // The solved board takes whatever height the phone has
                    // spare. A Spacer here left a dead band of blue above
                    // NEXT LEVEL on any phone taller than the mockup.
                    Expanded(child: _boardCard()),
                    const SizedBox(height: 14),
                    _chips(beatPar: beatPar, newFastest: newFastest),
                    const SizedBox(height: 18),
                    _worldBar(),
                    if (widget.stars < 3) ...[
                      const SizedBox(height: 14),
                      _tryForStars(),
                      const SizedBox(height: 14),
                    ] else
                      const SizedBox(height: 24),
                    _cta(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _topRow() => Row(
    children: [
      // Not in the mockup. There is no system back on iOS, and a result screen
      // whose only ways out are "play again" and "play on" is a trap for
      // somebody who wanted to stop.
      ToyBackButton(onPressed: widget.onLevels),
      Expanded(
        child: Center(
          child: ToyChip(
            color: Toy.card,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            child: Text(
              'Level ${widget.levelId} · ${widget.bandName}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Toy.ui(14, weight: FontWeight.w800),
            ),
          ),
        ),
      ),
      const SizedBox(width: 44),
    ],
  );

  /// Slams in from 1.6x at −12° and settles at −4°.
  Widget _title() {
    final t = _s(widget.profile.title.at, widget.profile.title.length);
    final slam = Curves.easeOutBack.transform(t);
    final scale = 1.6 - 0.6 * slam;
    final angle = (-12 + 8 * slam) * math.pi / 180;
    return Opacity(
      opacity: (t * 4).clamp(0.0, 1.0),
      child: Transform.rotate(
        angle: angle,
        child: Transform.scale(
          scale: scale,
          child: SizedBox(
            height: 138,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                winTitle(widget.stars),
                textAlign: TextAlign.center,
                style: Toy.display(
                  66,
                  color: Toy.yellow,
                  shadow: 4,
                  height: 0.98,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _stars() {
    final p = widget.profile;
    return Semantics(
      label: '${widget.stars} of 3 stars',
      child: ExcludeSemantics(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (var i = 0; i < 3; i++)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: _DroppingStar(
                  t: _s(p.starAt[i], p.starLength),
                  ring: i == 2 && widget.stars >= 3
                      ? _s(p.starAt[i], p.thirdStarFlourishLength)
                      : 0,
                  earned: i < widget.stars,
                  size: i == 1 ? 66 : 54,
                  lift: i == 1 ? 10 : 0,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _boardCard() {
    final sticker = _s(
      widget.profile.sticker.at,
      widget.profile.sticker.length,
    );
    return Stack(
      clipBehavior: Clip.none,
      fit: StackFit.expand,
      children: [
        ToyBox(
          radius: Toy.rHero,
          shadow: 5,
          padding: const EdgeInsets.all(14),
          // Its natural height on a short phone, and all the spare height on
          // a tall one; the painter centres the board in whatever it gets.
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 150),
            child: CustomPaint(
              painter: _SolvedBoardPainter(
                widget.board,
                // Bigger on a tablet, whose card has the room; 1 on a phone.
                scale: Toy.tabletScale(context),
              ),
            ),
          ),
        ),
        if (widget.isNewBest && sticker > 0)
          Positioned(
            top: -16,
            right: -6,
            child: _Slap(
              t: sticker,
              child: ToySticker.text('NEW BEST!', angle: 10),
            ),
          ),
      ],
    );
  }

  Widget _chips({required bool beatPar, required bool newFastest}) {
    final p = widget.profile;
    Widget chip(int i, Widget child) {
      final t = _s(p.chips.at + i * p.chipStagger, p.chips.length);
      final rise = p.chipStagger == 0
          ? 0.0
          : (1 - Curves.easeOutCubic.transform(t)) * 24;
      return Expanded(
        child: Opacity(
          opacity: t,
          child: Transform.translate(offset: Offset(0, rise), child: child),
        ),
      );
    }

    final sticker = _s(p.sticker.at, p.sticker.length);
    final shownMoves =
        (Curves.easeOut.transform(_s(p.chips.at, p.chips.length + 200)) *
                widget.movesUsed)
            .round();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        chip(
          0,
          _ResultChip(
            value: '$shownMoves',
            label: 'moves · par ${widget.minMoves}',
          ),
        ),
        const SizedBox(width: 10),
        chip(
          1,
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.topCenter,
            children: [
              _ResultChip(
                // Zero is an untimed run — the guided first level — and the
                // app reads 0 as "unknown" everywhere, never as instant.
                value: widget.elapsedSeconds > 0
                    ? formatClock(widget.elapsedSeconds)
                    : '—',
                label: widget.elapsedSeconds <= 0
                    ? 'untimed'
                    : newFastest
                    ? 'fastest yet!'
                    : 'time',
              ),
              if (beatPar && sticker > 0)
                Positioned(
                  top: -14,
                  child: _Slap(
                    t: sticker,
                    child: ToySticker.text(
                      'UNDER PAR!',
                      color: Toy.mint,
                      size: 11,
                      angle: -6,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      radius: 8,
                      shadow: 2,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        chip(
          2,
          _ResultChip(
            value: '+${formatCount(widget.points)}',
            label: 'points',
            color: Toy.yellow,
          ),
        ),
      ],
    );
  }

  Widget _worldBar() {
    final p = widget.profile;
    final t = Curves.easeOutCubic.transform(_s(p.band.at, p.band.length));
    final total = widget.bandTotal <= 0 ? 1 : widget.bandTotal;
    final cleared =
        widget.bandClearedBefore +
        (widget.bandClearedAfter - widget.bandClearedBefore) * t;
    return Opacity(
      opacity: _s(p.band.at, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'WORLD ${widget.worldNumber} · ${widget.bandName.toUpperCase()}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Toy.ui(
                    13,
                    weight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
              Text(
                '${widget.bandClearedAfter} / ${widget.bandTotal}',
                style: Toy.numbers(14, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ToyProgressBar(
            value: cleared / total,
            fill: Toy.yellow,
            track: const Color(0x55FFFFFF),
            height: 16,
          ),
        ],
      ),
    );
  }

  /// "Par N, you took M. Try for 3★?" — the cheapest replay hook there is:
  /// the player already knows the board.
  Widget _tryForStars() {
    final p = widget.profile;
    final t = _s(p.cta.at, p.cta.length);
    final short = widget.movesUsed - widget.minMoves;
    final message = widget.assisted
        ? 'Three stars need a clear without the extra tube.'
        : short > 0
        ? 'Par ${widget.minMoves}, you took ${widget.movesUsed}. '
              '${short == 1 ? 'One move' : '$short moves'} from 3★.'
        : 'Par ${widget.minMoves}. Three stars are in reach.';
    return Opacity(
      opacity: t,
      child: ToyBox(
        radius: 18,
        shadow: 4,
        padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
        child: Row(
          children: [
            Expanded(
              child: Text(
                message,
                style: Toy.ui(13.5, weight: FontWeight.w700, height: 1.25),
              ),
            ),
            const SizedBox(width: 10),
            ToyButton(
              label: 'TRY FOR 3★',
              onPressed: widget.onTryForStars ?? widget.onReplay,
              color: Toy.yellow,
              textColor: Toy.ink,
              height: 42,
              radius: 14,
              shadow: 3,
              fontSize: 15,
              compact: true,
              semanticLabel: 'Replay this level for three stars',
            ),
          ],
        ),
      ),
    );
  }

  Widget _cta() {
    final p = widget.profile;
    final t = _s(p.cta.at, p.cta.length);
    final next = widget.onNext;
    return Opacity(
      opacity: t,
      child: Transform.translate(
        offset: Offset(0, (1 - Curves.easeOutCubic.transform(t)) * 20),
        child: Row(
          children: [
            SizedBox(
              width: 64,
              child: Pressable(
                onPressed: widget.onReplay,
                semanticLabel: 'Replay this level',
                child: const ToyBox(
                  height: 64,
                  radius: Toy.rControl,
                  shadow: 5,
                  alignment: Alignment.center,
                  child: ToyIcon(ToyGlyph.restart, size: 28),
                ),
              ),
            ),
            if (widget.onHome case final home?) ...[
              const SizedBox(width: 10),
              SizedBox(
                width: 64,
                child: Pressable(
                  onPressed: home,
                  semanticLabel: 'Back to the home screen',
                  child: const ToyBox(
                    height: 64,
                    radius: Toy.rControl,
                    shadow: 5,
                    alignment: Alignment.center,
                    child: Icon(Icons.home_rounded, size: 30, color: Toy.ink),
                  ),
                ),
              ),
            ],
            const SizedBox(width: 12),
            Expanded(
              child: AnimatedBuilder(
                animation: _breath,
                builder: (context, child) => Transform.scale(
                  scale: 1 + 0.03 * Curves.easeInOut.transform(_breath.value),
                  child: child,
                ),
                child: ToyButton(
                  label: next == null ? 'BACK TO LEVELS' : 'NEXT LEVEL',
                  onPressed: next ?? widget.onLevels,
                  height: 64,
                  fontSize: 28,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A sticker slapped on: from 1.4x down to rest.
class _Slap extends StatelessWidget {
  final double t;
  final Widget child;

  const _Slap({required this.t, required this.child});

  @override
  Widget build(BuildContext context) => Opacity(
    opacity: (t * 3).clamp(0.0, 1.0),
    child: Transform.scale(
      scale: 1.4 - 0.4 * Curves.easeOutBack.transform(t),
      child: child,
    ),
  );
}

/// One result chip: a big number over a small label.
class _ResultChip extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _ResultChip({
    required this.value,
    required this.label,
    this.color = Toy.card,
  });

  @override
  Widget build(BuildContext context) => ToyBox(
    width: double.infinity,
    color: color,
    radius: Toy.rControl,
    shadow: 0,
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
    child: Column(
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(value, style: Toy.numbers(26)),
        ),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            maxLines: 1,
            style: Toy.ui(13, weight: FontWeight.w600),
          ),
        ),
      ],
    ),
  );
}

/// A star that drops in from above, overshoots, and — on a three-star run's
/// last star — throws a ring. Unearned stars arrive hollow and silent: the
/// absence IS the feedback.
class _DroppingStar extends StatelessWidget {
  final double t;
  final double ring;
  final bool earned;
  final double size;
  final double lift;

  const _DroppingStar({
    required this.t,
    required this.ring,
    required this.earned,
    required this.size,
    required this.lift,
  });

  @override
  Widget build(BuildContext context) {
    final settle = Curves.easeOutBack.transform(t);
    return Padding(
      padding: EdgeInsets.only(bottom: lift),
      child: Opacity(
        opacity: (t * 3).clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, earned ? -(1 - settle) * 40 : 0),
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              if (ring > 0 && ring < 1)
                Transform.scale(
                  scale: 0.8 + 1.2 * ring,
                  child: Opacity(
                    opacity: 1 - ring,
                    child: Container(
                      width: size,
                      height: size,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Toy.yellow, width: 4),
                      ),
                    ),
                  ),
                ),
              Transform.scale(
                scale: earned ? 0.5 + 0.5 * settle : 1,
                child: ToyStar(size: size, filled: earned),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The finished board, small, on the result card: the trophy.
class _SolvedBoardPainter extends CustomPainter {
  final Board board;

  /// Grows the ball ceiling and the gaps together on a tablet.
  final double scale;

  const _SolvedBoardPainter(this.board, {this.scale = 1});

  @override
  void paint(Canvas canvas, Size size) {
    final n = board.tubeCount;
    if (n == 0) return;
    final rows = n <= 6 ? 1 : 2;
    final perRow = (n / rows).ceil();
    final gap = 10.0 * scale;
    final rowGap = 10.0 * scale;

    final cap = board.capacity;
    // Solve for the ball that fits both axes; the tube pads the ball by 12%.
    final byWidth = (size.width - gap * (perRow - 1)) / perRow / 1.24;
    final byHeight = (size.height - rowGap * (rows - 1)) / rows / (cap + 0.34);
    final ball = math.min(byWidth, byHeight).clamp(8.0, 36.0 * scale);
    final pad = ball * 0.12;
    final tubeW = ball + pad * 2;
    final tubeH = ball * cap + pad * 2;
    final k = ball / 30;

    final totalH = rows * tubeH + (rows - 1) * rowGap;
    var top = (size.height - totalH) / 2;

    for (var row = 0; row < rows; row++) {
      final first = row * perRow;
      final count = math.min(perRow, n - first);
      final rowW = count * tubeW + (count - 1) * gap;
      final left = (size.width - rowW) / 2;
      for (var i = 0; i < count; i++) {
        final tube = board[first + i];
        final rect = Rect.fromLTWH(left + i * (tubeW + gap), top, tubeW, tubeH);
        final rrect = RRect.fromRectAndCorners(
          rect,
          topLeft: Radius.circular(8 * k),
          topRight: Radius.circular(8 * k),
          bottomLeft: Radius.circular(tubeW / 2),
          bottomRight: Radius.circular(tubeW / 2),
        );
        canvas
          ..drawRRect(rrect, Paint()..color = Toy.tubePreview)
          ..drawRRect(
            rrect,
            Paint()
              ..color = Toy.ink
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2 * k,
          );
        for (var s = 0; s < tube.balls.length; s++) {
          final style = kBallPalette[tube.balls[s] % kBallPalette.length];
          final c = Offset(
            rect.center.dx,
            rect.bottom - pad - ball / 2 - s * ball,
          );
          drawToyBall(
            canvas,
            Rect.fromCircle(center: c, radius: ball / 2 * 0.94),
            color: Color(0xFF000000 | style.rgb),
            glyph: style.glyph,
            glyphInk: Color(0xFF000000 | style.glyphInk),
          );
        }
      }
      top += tubeH + rowGap;
    }
  }

  @override
  bool shouldRepaint(_SolvedBoardPainter old) =>
      old.board != board || old.scale != scale;
}

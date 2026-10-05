/// The board: tubes, balls, and every animation that happens between them.
///
/// This is the hero of the screen and the only thing a player looks at, so the
/// motion here is the product. Three deliberate choices:
///
///  * **Balls arc, they do not slide.** A ball rises clear of its tube, travels,
///    and drops in — a cubic Bézier whose control points sit directly above each
///    tube, which makes it leave vertically and enter vertically for free.
///  * **They stretch in flight and squash on landing.** Volume preserved, on
///    an elastic curve. This is what makes a ball feel like it has weight.
///  * **Nothing blurs.** Tubes are a flat fill, an ink stroke and a hard offset
///    shadow — the Toybox look — and a blur behind twelve tubes is the fastest
///    way to miss 60fps on the low-end Android this game has to run on anyway.
///
/// While a run is held, every tube that can take it gets a mint fill and a
/// bobbing tomato ▼; the rest dim to 40%. A tube that completes pops a SORTED!
/// sticker and flashes a yellow ring.
///
/// The board also PARTICIPATES IN THE WIN SEQUENCE rather than being covered by
/// it: it bumps to 1.03 and the solved tubes flash in turn. See
/// `win_profile.dart` for the timing.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/game_state.dart';
import '../../state/providers.dart';
import '../theme/tokens.dart';
import '../theme/toy.dart';
import 'ball.dart';
import 'board_geometry.dart';
import 'win_profile.dart';

/// Gap between successive balls leaving in one pour.
const pourStagger = Duration(milliseconds: 58);

/// How long a completed tube's ring flash and sticker pop run.
const _flourishDuration = Duration(milliseconds: 420);

/// One bob of the ▼ over a legal target: 6px, sine, 600ms.
const _bobDuration = Duration(milliseconds: 600);

/// The board's state during a win sequence, or absent while playing.
class WinPhase {
  final WinProfile profile;
  final double elapsedMs;

  /// True when the run earned the third star.
  final bool celebrateThird;

  const WinPhase({
    required this.profile,
    required this.elapsedMs,
    required this.celebrateThird,
  });
}

class BoardView extends ConsumerStatefulWidget {
  final void Function(int tube) onTapTube;

  /// Non-null while the level-complete sequence is running.
  final WinPhase? win;

  /// Fires as each ball lands, with how full the destination now is (0..1) and
  /// whether that landing completed the tube. The screen turns this into sound
  /// and haptics.
  final void Function(double fill, bool completed)? onBallLanded;

  /// The tube the guided first level wants tapped next. A hand under it bobs
  /// toward it. Null draws nothing.
  final int? guideTube;

  const BoardView({
    super.key,
    required this.onTapTube,
    this.win,
    this.onBallLanded,
    this.guideTube,
  });

  @override
  ConsumerState<BoardView> createState() => _BoardViewState();
}

class _BoardViewState extends ConsumerState<BoardView>
    with TickerProviderStateMixin {
  late final AnimationController _pour;
  late final AnimationController _flourish;

  /// Breathes while a hint is on screen.
  ///
  /// A hint drawn with the same static treatment as a tapped tube is
  /// indistinguishable from the player's own selection — worst of all right
  /// after a rewarded video, when they return from a fullscreen ad having lost
  /// all context and cannot tell they were given anything. Motion is what
  /// separates "the game is telling you something" from "you tapped this".
  late final AnimationController _hintPulse;

  /// Drives the ▼ bobbing over every legal target while a run is held. Like
  /// the hint pulse, it only runs while there is something to point at.
  late final AnimationController _bob;

  /// Drives the guiding hand. Runs only while there is a tube to point at.
  late final AnimationController _guide;

  PourEvent? _active;
  int? _glowTube;

  /// Balls of the active pour that have already landed, so each fires its cue
  /// exactly once and the resting layer takes ownership at the right moment.
  int _landed = 0;

  @override
  void initState() {
    super.initState();
    _pour = AnimationController(vsync: this)
      ..addListener(_checkLandings)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed && mounted) {
          setState(() => _active = null);
        }
      });
    _flourish = AnimationController(vsync: this, duration: _flourishDuration);
    _hintPulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _bob = AnimationController(vsync: this, duration: _bobDuration);
    _guide = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
  }

  @override
  void dispose() {
    _pour.dispose();
    _flourish.dispose();
    _hintPulse.dispose();
    _bob.dispose();
    _guide.dispose();
    super.dispose();
  }

  /// Fires the per-ball callback the instant each ball touches down, rather
  /// than once for the whole pour. The sound and the haptic have to land WITH
  /// the ball or the weight illusion falls apart.
  void _checkLandings() {
    final active = _active;
    if (active == null) return;

    final travel = PourfectTokens.of(context).pourDuration.inMilliseconds;
    final elapsed = _pour.value * _pour.duration!.inMilliseconds;
    final capacity = ref.read(gameControllerProvider)?.board.capacity ?? 4;

    while (_landed < active.ballsMoved) {
      if (elapsed < _landed * pourStagger.inMilliseconds + travel) break;

      final slot = active.destBaseSlot + _landed;
      final isLast = _landed == active.ballsMoved - 1;
      _landed++;

      widget.onBallLanded?.call(
        (slot + 1) / capacity,
        isLast && active.completedDestination,
      );
      if (isLast && active.completedDestination) {
        // The ring and the sticker go off as the tube actually fills, not when
        // the pour was requested.
        _glowTube = active.move.to;
        _flourish.forward(from: 0);
      }
      if (mounted) setState(() {});
    }
  }

  void _startPour(PourEvent event, PourfectTokens tokens) {
    _landed = 0;
    // The controller runs on past the last landing for the settle, so the
    // final ball squashes and springs back instead of freezing mid-squash.
    _pour
      ..duration =
          tokens.pourDuration +
          pourStagger * (event.ballsMoved - 1) +
          tokens.settleDuration
      ..forward(from: 0);
    setState(() => _active = event);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = PourfectTokens.of(context);
    final state = ref.watch(gameControllerProvider);

    ref.listen(gameControllerProvider, (previous, next) {
      final pour = next?.pour;
      if (pour != null && previous?.pour?.sequence != pour.sequence) {
        _startPour(pour, tokens);
        return;
      }
      // The board changed with no new pour: an undo, a restart, a new level.
      // Whatever is still in flight belongs to a board that is gone, and left
      // running it drew the restored balls twice, played landing sounds for
      // a pour that was taken back, and hid the new board's top balls until
      // the ghosts touched down.
      if (_active != null && next?.board != previous?.board) {
        _pour.stop();
        _flourish.stop();
        _flourish.value = 0;
        setState(() {
          _active = null;
          _glowTube = null;
        });
      }
    });

    if (state == null) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final geometry = BoardGeometry.fit(
          available: Size(constraints.maxWidth, constraints.maxHeight),
          tubeCount: state.board.tubeCount,
          capacity: state.board.capacity,
        );

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapUp: widget.win != null
              ? null
              : (details) {
                  final tube = geometry.tubeAt(details.localPosition);
                  if (tube != null) widget.onTapTube(tube);
                },
          child: SizedBox(
            width: constraints.maxWidth,
            height: constraints.maxHeight,
            child: AnimatedBuilder(
              animation: Listenable.merge([_pour, _flourish]),
              builder: (context, _) => Transform.scale(
                scale: _presentScale(),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    ..._buildTubes(state, geometry, tokens),
                    ..._buildRestingBalls(state, geometry, tokens),
                    ..._buildFlyingBalls(state, geometry, tokens),
                    ..._buildLegalArrows(state, geometry),
                    ..._buildSortedStickers(state, geometry),
                    ..._buildGuide(geometry),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ---- the board presenting itself ----------------------------------------

  /// Progress through a win beat, 0..1.
  double _winSpan(int at, int length) {
    final win = widget.win;
    if (win == null) return 0;
    return ((win.elapsedMs - at) / length).clamp(0.0, 1.0);
  }

  /// The board bumps to 1.03 as the last ball lands and settles back — the
  /// toy equivalent of holding something up. Every win gets it.
  double _presentScale() {
    if (widget.win == null || Toy.calm(context)) return 1;
    return 1 + 0.03 * math.sin(math.pi * _winSpan(0, 250));
  }

  // ---- tubes ---------------------------------------------------------------

  List<Widget> _buildTubes(
    GameState state,
    BoardGeometry geometry,
    PourfectTokens tokens,
  ) {
    _syncHintPulse(state.hintMove != null);

    final k = geometry.ballSize / 41;
    return [
      for (var i = 0; i < geometry.tubeRects.length; i++)
        Positioned.fromRect(
          rect: geometry.tubeRects[i],
          child: AnimatedBuilder(
            animation: _hintPulse,
            builder: (context, _) => _TubeShell(
              tokens: tokens,
              scale: k,
              look: _tubeLook(state, i),
              // A slow triangle wave, so it eases at both ends instead of
              // snapping back.
              hintPulse: Curves.easeInOut.transform(
                1 - (2 * _hintPulse.value - 1).abs(),
              ),
              opacity: _tubeOpacity(state, i),
              ring: math.max(_tubeGlow(i), _winGlow(state, i)),
            ),
          ),
        ),
    ];
  }

  _TubeLook _tubeLook(GameState state, int i) {
    final playing = widget.win == null;
    if (playing && state.hintMove?.to == i) return _TubeLook.hintTarget;
    if (playing && state.hintMove?.from == i) return _TubeLook.hintSource;
    if (playing && state.selectedTube == i) return _TubeLook.selected;
    if (playing &&
        state.selectedTube != null &&
        state.legalTargets.contains(i)) {
      return _TubeLook.legal;
    }
    if (state.board[i].isComplete && !_stillLanding(i)) return _TubeLook.sorted;
    return _TubeLook.idle;
  }

  /// A tube still receiving the ball that completes it is not complete on
  /// screen yet.
  bool _stillLanding(int tube) {
    final active = _active;
    return active != null &&
        active.move.to == tube &&
        _landed < active.ballsMoved;
  }

  /// Runs the pulse only while a hint is up. A permanently repeating
  /// controller would keep the board rebuilding every frame for the whole
  /// session, which is exactly the kind of idle cost that turns a measured
  /// 1.2ms build into a warm phone.
  void _syncHintPulse(bool showing) {
    if (showing && !_hintPulse.isAnimating) {
      _hintPulse.repeat();
    } else if (!showing && _hintPulse.isAnimating) {
      _hintPulse.stop();
      _hintPulse.value = 0;
    }
  }

  /// Same rule as the hint pulse: the bob runs only while a run is held.
  void _syncBob(bool holding) {
    if (holding && !_bob.isAnimating && !Toy.calm(context)) {
      _bob.repeat();
    } else if (!holding && _bob.isAnimating) {
      _bob.stop();
      _bob.value = 0;
    }
  }

  double _tubeOpacity(GameState state, int tube) {
    // During a win every tube stays at full strength: the solved ones wear
    // their stickers and the empties are part of the finished picture.
    if (widget.win != null) return 1;
    if (state.selectedTube == null) return 1;
    if (state.selectedTube == tube) return 1;
    if (state.hintMove?.to == tube) return 1;
    return state.legalTargets.contains(tube)
        ? 1
        : PourfectTokens.illegalTargetOpacity;
  }

  /// A yellow ring flash on each solved tube during the win, staggered left to
  /// right so the board reads as a ripple rather than switching on.
  double _winGlow(GameState state, int tube) {
    final win = widget.win;
    if (win == null || state.board[tube].isEmpty || Toy.calm(context)) {
      return 0;
    }
    final t = _winSpan(tube * win.profile.glowStagger, win.profile.glowLength);
    if (t <= 0 || t >= 1) return 0;
    return math.sin(math.pi * t);
  }

  double _tubeGlow(int tube) => _glowTube == tube ? _flourishCurve : 0;

  /// The completion ring: at full strength the instant the tube fills, then
  /// spreading out and fading.
  double get _flourishCurve {
    final t = _flourish.value;
    if (t == 0 || t == 1) return 0;
    return 1 - Curves.easeIn.transform(t);
  }

  // ---- the guiding hand -----------------------------------------------------

  /// A hand under the tube the guided level wants tapped, nudging up at it.
  ///
  /// Under the tube, not over it: above is where a lifted run and the legal
  /// arrows live, and a hand there would sit on top of the very thing it is
  /// pointing at.
  List<Widget> _buildGuide(BoardGeometry geometry) {
    final tube = widget.guideTube;
    final show = tube != null && widget.win == null;
    if (show && !_guide.isAnimating && !Toy.calm(context)) {
      _guide.repeat(reverse: true);
    } else if (!show && _guide.isAnimating) {
      _guide
        ..stop()
        ..value = 0;
    }
    if (!show || tube >= geometry.tubeRects.length) return const [];

    final rect = geometry.tubeRects[tube];
    const size = 46.0;
    return [
      Positioned(
        left: rect.center.dx - size / 2,
        top: rect.bottom + 10,
        width: size,
        height: size,
        child: IgnorePointer(
          child: AnimatedBuilder(
            animation: _guide,
            builder: (context, child) => Transform.translate(
              offset: Offset(0, 8 * Curves.easeInOut.transform(_guide.value)),
              child: child,
            ),
            child: const _GuideHand(),
          ),
        ),
      ),
    ];
  }

  // ---- markers over tubes --------------------------------------------------

  /// A tomato ▼ over every tube that can take the held run, and a yellow one
  /// over a hint's destination.
  List<Widget> _buildLegalArrows(GameState state, BoardGeometry geometry) {
    final playing = widget.win == null;
    final holding = playing && state.selectedTube != null;
    final hintTarget = playing ? state.hintMove?.to : null;
    final targets = {if (holding) ...state.legalTargets, ?hintTarget};
    _syncBob(targets.isNotEmpty);
    if (targets.isEmpty) return const [];

    final k = geometry.ballSize / 41;
    final size = 22 * k;
    return [
      for (final i in targets)
        Positioned(
          left: geometry.tubeRects[i].center.dx - size / 2,
          top: geometry.tubeRects[i].top - size - 12 * k,
          width: size,
          height: size * 0.8,
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: _bob,
              builder: (context, child) => Transform.translate(
                offset: Offset(0, 3 * k * math.sin(2 * math.pi * _bob.value)),
                child: child,
              ),
              child: CustomPaint(
                painter: _ArrowPainter(
                  i == hintTarget ? Toy.yellow : Toy.tomato,
                ),
              ),
            ),
          ),
        ),
    ];
  }

  /// SORTED! over each completed tube. Pops in when the tube completes during
  /// play; a tube already complete simply wears it.
  List<Widget> _buildSortedStickers(GameState state, BoardGeometry geometry) {
    final k = geometry.ballSize / 41;
    final calm = Toy.calm(context);
    final widgets = <Widget>[];
    for (var i = 0; i < state.board.tubeCount; i++) {
      if (!state.board[i].isComplete || _stillLanding(i)) continue;
      // Lifted: the sticker would sit on top of the held run.
      if (state.selectedTube == i && widget.win == null) continue;

      var pop = 1.0;
      if (_glowTube == i && _flourish.isAnimating && !calm) {
        // 320ms of the flourish: 0 → 1.15 → 1.
        pop = Curves.easeOutBack.transform(
          (_flourish.value * 420 / 320).clamp(0.0, 1.0),
        );
      }

      final rect = geometry.tubeRects[i];
      widgets.add(
        Positioned(
          left: rect.center.dx - 60 * k,
          width: 120 * k,
          top: rect.top - 22 * k,
          child: IgnorePointer(
            child: Center(
              child: Transform.scale(
                scale: pop,
                child: Transform.rotate(
                  angle: -8 * math.pi / 180,
                  child: Opacity(
                    opacity: _tubeOpacity(state, i),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 6 * k,
                        vertical: 2 * k,
                      ),
                      decoration: BoxDecoration(
                        color: Toy.mint,
                        borderRadius: BorderRadius.circular(6 * k),
                        border: Border.all(color: Toy.ink, width: 2 * k),
                        boxShadow: Toy.hard(2.5 * k),
                      ),
                      child: Text(
                        'SORTED!',
                        maxLines: 1,
                        style: Toy.ui(
                          10 * k,
                          weight: FontWeight.w800,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }
    return widgets;
  }

  // ---- balls at rest -------------------------------------------------------

  List<Widget> _buildRestingBalls(
    GameState state,
    BoardGeometry geometry,
    PourfectTokens tokens,
  ) {
    final widgets = <Widget>[];
    final active = _active;
    final bold = ref.watch(settingsProvider).boldSymbols;
    final calm = Toy.calm(context);

    for (var tube = 0; tube < state.board.tubeCount; tube++) {
      final balls = state.board[tube].balls;

      // Slots the in-flight balls are still heading for stay hidden; the
      // overlay owns them until they touch down.
      var visibleCount = balls.length;
      if (active != null && tube == active.move.to) {
        visibleCount = math.min(visibleCount, active.destBaseSlot + _landed);
      }

      final liftedFrom = _liftedFromSlot(state, tube);
      final lift = liftedFrom < 0
          ? 0.0
          : geometry.liftOffset(tube, balls.length - 1);
      final opacity = _tubeOpacity(state, tube);

      for (var slot = 0; slot < visibleCount; slot++) {
        final centre = geometry.ballCentre(tube, slot);
        final isLifted = liftedFrom >= 0 && slot >= liftedFrom;
        final y = isLifted ? centre.dy - lift : centre.dy;

        widgets.add(
          AnimatedPositioned(
            key: ValueKey('ball-$tube-$slot'),
            duration: tokens.selectDuration,
            // A tiny overshoot on the way up, none on the way down.
            curve: isLifted && !calm ? Curves.easeOutBack : Curves.easeOutCubic,
            left: centre.dx - geometry.ballSize / 2,
            top: y - geometry.ballSize / 2,
            width: geometry.ballSize,
            height: geometry.ballSize,
            child: Ball(
              colorId: balls[slot],
              size: geometry.ballSize,
              opacity: opacity,
              squash: calm ? 1 : _settleSquash(active, tube, slot, tokens),
              drop: isLifted,
              boldGlyph: bold,
            ),
          ),
        );
      }
    }
    return widgets;
  }

  /// Vertical scale of a ball that has just landed: squashed to 0.86 on
  /// contact, then springing back through 1 on an elastic curve.
  double _settleSquash(
    PourEvent? active,
    int tube,
    int slot,
    PourfectTokens tokens,
  ) {
    if (active == null || tube != active.move.to) return 1;
    final j = slot - active.destBaseSlot;
    if (j < 0 || j >= _landed) return 1;

    final landedAt =
        j * pourStagger.inMilliseconds + tokens.pourDuration.inMilliseconds;
    final elapsed = _pour.value * _pour.duration!.inMilliseconds;
    final t = (elapsed - landedAt) / tokens.settleDuration.inMilliseconds;
    if (t >= 1 || t < 0) return 1;
    return 0.86 + 0.14 * const ElasticOutCurve(0.6).transform(t);
  }

  /// Lowest slot of the run currently lifted out of [tube], or -1.
  ///
  /// The WHOLE top run lifts, because the whole run is what a pour moves.
  int _liftedFromSlot(GameState state, int tube) {
    if (widget.win != null) return -1;
    if (state.selectedTube != tube) return -1;
    final balls = state.board[tube];
    if (balls.isEmpty) return -1;
    return balls.length - balls.topRunLength;
  }

  // ---- balls in flight -----------------------------------------------------

  List<Widget> _buildFlyingBalls(
    GameState state,
    BoardGeometry geometry,
    PourfectTokens tokens,
  ) {
    final active = _active;
    if (active == null) return const [];

    final totalMs = _pour.duration!.inMilliseconds;
    final travelMs = tokens.pourDuration.inMilliseconds;
    final elapsedMs = _pour.value * totalMs;
    final calm = Toy.calm(context);

    // A pour always follows a selection, so the run leaves from where it was
    // HELD. Starting from the resting slots dropped it back into the tube for
    // a frame before it flew.
    final held = Offset(
      0,
      geometry.liftOffset(active.move.from, active.sourceTopSlot),
    );

    final widgets = <Widget>[];
    for (var j = 0; j < active.ballsMoved; j++) {
      final startMs = j * pourStagger.inMilliseconds;
      final local = ((elapsedMs - startMs) / travelMs).clamp(0.0, 1.0);
      if (local >= 1) continue; // landed — the resting layer has it now

      final from =
          geometry.ballCentre(active.move.from, active.sourceTopSlot - j) -
          held;
      final to = geometry.ballCentre(active.move.to, active.destBaseSlot + j);

      final position = elapsedMs < startMs
          ? from
          : _arc(
              from,
              to,
              geometry,
              active,
              Curves.easeInOutCubic.transform(local),
            );

      widgets.add(
        Positioned(
          left: position.dx - geometry.ballSize / 2,
          top: position.dy - geometry.ballSize / 2,
          width: geometry.ballSize,
          height: geometry.ballSize,
          child: Ball(
            colorId: active.color,
            size: geometry.ballSize,
            // Stretches along its flight and is round again as it lands.
            squash: calm ? 1 : 1 + 0.1 * math.sin(math.pi * local),
            drop: true,
            boldGlyph: ref.read(settingsProvider).boldSymbols,
          ),
        ),
      );
    }
    return widgets;
  }

  /// Cubic Bézier from [from] to [to] with both control points directly above
  /// their own tube, so the ball leaves straight up and arrives straight down
  /// and never appears to pass through a tube wall.
  Offset _arc(
    Offset from,
    Offset to,
    BoardGeometry geometry,
    PourEvent event,
    double t,
  ) {
    final apex =
        math.min(
          geometry.liftPoint(event.move.from).dy,
          geometry.liftPoint(event.move.to).dy,
        ) -
        geometry.ballSize * 0.15;

    final c1 = Offset(from.dx, apex);
    final c2 = Offset(to.dx, apex);
    final u = 1 - t;

    return Offset(
      u * u * u * from.dx +
          3 * u * u * t * c1.dx +
          3 * u * t * t * c2.dx +
          t * t * t * to.dx,
      u * u * u * from.dy +
          3 * u * u * t * c1.dy +
          3 * u * t * t * c2.dy +
          t * t * t * to.dy,
    );
  }
}

/// What a tube is doing right now, which decides its fill, stroke and shadow.
enum _TubeLook { idle, selected, legal, sorted, hintSource, hintTarget }

/// The tube itself: flat fill, ink stroke, hard shadow. Rounder at the base
/// than the mouth, like a real vessel.
class _TubeShell extends StatelessWidget {
  final PourfectTokens tokens;

  /// ballSize / 41 — stroke, shadow and radii scale with the board.
  final double scale;
  final _TubeLook look;

  /// 0..1, breathing, while a hint is on screen.
  final double hintPulse;

  final double opacity;

  /// 0..1 yellow ring flash: a tube completing, or the win ripple.
  final double ring;

  const _TubeShell({
    required this.tokens,
    required this.scale,
    required this.look,
    required this.hintPulse,
    required this.opacity,
    required this.ring,
  });

  @override
  Widget build(BuildContext context) {
    final k = scale;
    final (fill, stroke, shadow, shadowColor) = switch (look) {
      _TubeLook.idle => (Toy.tubeFill, Toy.ink, 4.0, Toy.ink),
      _TubeLook.selected => (Toy.selectedTubeFill, Toy.tomato, 5.0, Toy.tomato),
      _TubeLook.legal => (Toy.legalTubeFill, Toy.ink, 4.0, Toy.ink),
      _TubeLook.sorted => (Toy.sortedTubeFill, Toy.ink, 4.0, Toy.ink),
      _TubeLook.hintSource => (Toy.tubeFill, Toy.yellow, 4.0, Toy.ink),
      // The destination carries the message, so it is the one that breathes.
      _TubeLook.hintTarget => (
        Color.lerp(Toy.sortedTubeFill, const Color(0xFFFFE9A8), hintPulse)!,
        Toy.ink,
        4.0,
        Color.lerp(Toy.ink, Toy.yellow, hintPulse)!,
      ),
    };

    return LayoutBuilder(
      builder: (context, box) {
        final radius = BorderRadius.vertical(
          top: Radius.circular(12 * k),
          bottom: Radius.circular(box.maxWidth / 2),
        );
        return AnimatedOpacity(
          duration: tokens.selectDuration,
          opacity: opacity,
          child: Stack(
            clipBehavior: Clip.none,
            fit: StackFit.expand,
            children: [
              if (ring > 0)
                Positioned.fill(
                  left: -(3 + 7 * (1 - ring)) * k,
                  right: -(3 + 7 * (1 - ring)) * k,
                  top: -(3 + 7 * (1 - ring)) * k,
                  bottom: -(3 + 7 * (1 - ring)) * k,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(18 * k),
                        bottom: Radius.circular(box.maxWidth),
                      ),
                      border: Border.all(
                        color: Toy.yellow.withValues(alpha: ring),
                        width: 4 * k,
                      ),
                    ),
                  ),
                ),
              AnimatedContainer(
                duration: tokens.selectDuration,
                decoration: BoxDecoration(
                  color: fill,
                  borderRadius: radius,
                  border: Border.all(
                    color: stroke,
                    width:
                        (look == _TubeLook.hintSource ? 3.5 : Toy.stroke) * k,
                  ),
                  boxShadow: Toy.hard(shadow * k, shadowColor),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// The bobbing ▼ over a tube that can take the held run.
class _ArrowPainter extends CustomPainter {
  final Color color;

  const _ArrowPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
    // Yellow alone disappears into the cream; it gets the ink outline.
    if (color == Toy.yellow) {
      canvas.drawPath(
        path,
        Paint()
          ..color = Toy.ink
          ..style = PaintingStyle.stroke
          ..strokeWidth = size.width * 0.09
          ..strokeJoin = StrokeJoin.round,
      );
    }
  }

  @override
  bool shouldRepaint(_ArrowPainter old) => old.color != color;
}

/// The tutorial's pointing hand: a white finger on a tomato button, in the
/// toy outline, so it reads as part of the game rather than an OS overlay.
class _GuideHand extends StatelessWidget {
  const _GuideHand();

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: Toy.tomato,
      shape: BoxShape.circle,
      border: Border.all(color: Toy.ink, width: Toy.stroke),
      boxShadow: Toy.hard(3),
    ),
    alignment: Alignment.center,
    child: const Icon(Icons.touch_app_rounded, color: Colors.white, size: 26),
  );
}

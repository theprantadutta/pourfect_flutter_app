/// The board: tubes, balls, and every animation that happens between them.
///
/// This is the hero of the screen and the only thing a player looks at, so the
/// motion here is the product. Three deliberate choices:
///
///  * **Balls arc, they do not slide.** A ball rises clear of its tube, travels,
///    and drops in — a cubic Bézier whose control points sit directly above each
///    tube, which makes it leave vertically and enter vertically for free. A
///    straight line would read as a data structure updating.
///  * **They squash on landing.** A damped spring on the vertical scale, volume
///    preserved. This is what makes a ball feel like it has weight.
///  * **No BackdropFilter anywhere.** The frosted-glass tubes are a translucent
///    fill plus a hairline, not a real blur. A blur behind twelve tubes is the
///    fastest way to miss 60fps on the low-end Android this game has to run on.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/game_state.dart';
import '../../state/providers.dart';
import '../theme/tokens.dart';
import 'ball.dart';
import 'board_geometry.dart';

/// Gap between successive balls leaving in one pour.
const _pourStagger = Duration(milliseconds: 58);

/// How long a completed tube glows.
const _flourishDuration = Duration(milliseconds: 720);

class BoardView extends ConsumerStatefulWidget {
  /// Called with the tapped tube index.
  final void Function(int tube) onTapTube;

  const BoardView({super.key, required this.onTapTube});

  @override
  ConsumerState<BoardView> createState() => _BoardViewState();
}

class _BoardViewState extends ConsumerState<BoardView>
    with TickerProviderStateMixin {
  late final AnimationController _pour;
  late final AnimationController _flourish;

  /// The pour currently being animated, or null when the board is at rest.
  PourEvent? _active;

  /// Tube whose completion is being celebrated.
  int? _glowTube;

  @override
  void initState() {
    super.initState();
    _pour = AnimationController(vsync: this)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed && mounted) {
          setState(() => _active = null);
        }
      });
    _flourish = AnimationController(vsync: this, duration: _flourishDuration);
  }

  @override
  void dispose() {
    _pour.dispose();
    _flourish.dispose();
    super.dispose();
  }

  void _startPour(PourEvent event, PourfectTokens tokens) {
    // Balls leave in quick succession rather than as a block, so a run of three
    // reads as a pour instead of a lump moving.
    _pour
      ..duration = tokens.pourDuration + _pourStagger * (event.ballsMoved - 1)
      ..forward(from: 0);
    setState(() => _active = event);

    if (event.completedDestination) {
      _glowTube = event.move.to;
      _flourish.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = PourfectTokens.of(context);
    final state = ref.watch(gameControllerProvider);

    // A pour is an EVENT, not a piece of state — listening rather than
    // comparing in build is what stops an unrelated rebuild replaying the last
    // animation.
    ref.listen(gameControllerProvider, (previous, next) {
      final pour = next?.pour;
      if (pour == null) return;
      if (previous?.pour?.sequence == pour.sequence) return;
      _startPour(pour, tokens);
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
          onTapUp: (details) {
            final tube = geometry.tubeAt(details.localPosition);
            if (tube != null) widget.onTapTube(tube);
          },
          child: SizedBox(
            width: constraints.maxWidth,
            height: constraints.maxHeight,
            child: AnimatedBuilder(
              animation: Listenable.merge([_pour, _flourish]),
              builder: (context, _) => Stack(
                clipBehavior: Clip.none,
                children: [
                  ..._buildTubes(state, geometry, tokens),
                  ..._buildRestingBalls(state, geometry, tokens),
                  ..._buildFlyingBalls(state, geometry, tokens),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ---- tubes ---------------------------------------------------------------

  List<Widget> _buildTubes(
    GameState state,
    BoardGeometry geometry,
    PourfectTokens tokens,
  ) => [
    for (var i = 0; i < geometry.tubeRects.length; i++)
      Positioned.fromRect(
        rect: geometry.tubeRects[i],
        child: _TubeShell(
          tokens: tokens,
          isSelected: state.selectedTube == i,
          isHintSource: state.hintMove?.from == i,
          isHintTarget: state.hintMove?.to == i,
          opacity: _tubeOpacity(state, i),
          glow: _glowTube == i ? _flourishCurve : 0,
        ),
      ),
  ];

  /// Tubes that cannot receive the held run dim to 40%.
  ///
  /// Not 30%: against a near-black ground the muted jewel tones crush toward
  /// invisible below about 35%, and a dimmed tube must still read as a tube the
  /// player could tap to switch selection.
  double _tubeOpacity(GameState state, int tube) {
    if (state.selectedTube == null) return 1;
    if (state.selectedTube == tube) return 1;
    return state.legalTargets.contains(tube)
        ? 1
        : PourfectTokens.illegalTargetOpacity;
  }

  double get _flourishCurve {
    final t = _flourish.value;
    if (t == 0 || t == 1) return 0;
    // Rise fast, linger, fade. A symmetric curve would feel like a blink.
    return t < 0.25
        ? Curves.easeOut.transform(t / 0.25)
        : Curves.easeInCubic.transform(1 - (t - 0.25) / 0.75);
  }

  // ---- balls at rest -------------------------------------------------------

  List<Widget> _buildRestingBalls(
    GameState state,
    BoardGeometry geometry,
    PourfectTokens tokens,
  ) {
    final widgets = <Widget>[];
    final active = _active;

    for (var tube = 0; tube < state.board.tubeCount; tube++) {
      final balls = state.board[tube].balls;

      // Hide the slots the in-flight balls are heading for; the overlay owns
      // them until they land.
      var visibleCount = balls.length;
      if (active != null && tube == active.move.to) {
        visibleCount = math.min(visibleCount, active.destBaseSlot);
      }

      // Slot of the LOWEST ball in the lifted run, or -1 when nothing is held.
      // The run hovers as a stack: this ball sits at the lift point and the
      // rest pile up above it, preserving the order they hold in the tube.
      final liftedFrom = _liftedFromSlot(state, tube);
      final opacity = _tubeOpacity(state, tube);

      for (var slot = 0; slot < visibleCount; slot++) {
        final centre = geometry.ballCentre(tube, slot);
        final isLifted = liftedFrom >= 0 && slot >= liftedFrom;
        final y = isLifted
            ? geometry.liftPoint(tube).dy -
                  (slot - liftedFrom) * geometry.ballSize
            : centre.dy;

        widgets.add(
          AnimatedPositioned(
            key: ValueKey('ball-$tube-$slot'),
            duration: tokens.selectDuration,
            curve: Curves.easeOutCubic,
            left: centre.dx - geometry.ballSize / 2,
            top: y - geometry.ballSize / 2,
            width: geometry.ballSize,
            height: geometry.ballSize,
            child: Ball(
              colorId: balls[slot],
              size: geometry.ballSize,
              opacity: opacity,
              glow: _glowTube == tube ? _flourishCurve : 0,
            ),
          ),
        );
      }
    }
    return widgets;
  }

  /// Lowest slot of the run currently lifted out of [tube], or -1.
  ///
  /// The WHOLE top run lifts, not just one ball, because the whole run is what
  /// a pour moves — showing a single ball would misrepresent the move the
  /// player is about to make.
  int _liftedFromSlot(GameState state, int tube) {
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

    final widgets = <Widget>[];
    for (var j = 0; j < active.ballsMoved; j++) {
      final startMs = j * _pourStagger.inMilliseconds;
      final local = ((elapsedMs - startMs) / travelMs).clamp(0.0, 1.0);

      final from = geometry.ballCentre(
        active.move.from,
        active.sourceTopSlot - j,
      );
      final to = geometry.ballCentre(active.move.to, active.destBaseSlot + j);

      final Offset position;
      double squash = 1;

      if (elapsedMs < startMs) {
        // Waiting its turn, still sitting in the source tube.
        position = from;
      } else if (local < 1) {
        position = _arc(
          from,
          to,
          geometry,
          active,
          Curves.easeInOut.transform(local),
        );
      } else {
        position = to;
        // Damped spring on the vertical scale. Volume is preserved inside
        // [Ball], so a squashed ball also widens — which is what sells weight.
        final sinceLandMs = elapsedMs - startMs - travelMs;
        final u = (sinceLandMs / tokens.settleDuration.inMilliseconds).clamp(
          0.0,
          1.0,
        );
        squash = 1 - 0.25 * math.exp(-6 * u) * math.cos(12 * u);
      }

      widgets.add(
        Positioned(
          left: position.dx - geometry.ballSize / 2,
          top: position.dy - geometry.ballSize / 2,
          width: geometry.ballSize,
          height: geometry.ballSize,
          child: Ball(
            colorId: active.colour,
            size: geometry.ballSize,
            squash: squash,
            glow: _glowTube == active.move.to ? _flourishCurve : 0,
          ),
        ),
      );
    }
    return widgets;
  }

  /// Cubic Bézier from [from] to [to] with both control points directly above
  /// their own tube.
  ///
  /// That placement is the whole trick: it forces the ball to leave straight
  /// up and arrive straight down, so it never appears to pass through a tube
  /// wall, without any explicit phase splitting.
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

/// The tube itself: a frosted pane with a hairline edge.
class _TubeShell extends StatelessWidget {
  final PourfectTokens tokens;
  final bool isSelected;
  final bool isHintSource;
  final bool isHintTarget;
  final double opacity;
  final double glow;

  const _TubeShell({
    required this.tokens,
    required this.isSelected,
    required this.isHintSource,
    required this.isHintTarget,
    required this.opacity,
    required this.glow,
  });

  @override
  Widget build(BuildContext context) {
    final highlighted = isSelected || isHintSource || isHintTarget;

    return AnimatedOpacity(
      duration: tokens.selectDuration,
      opacity: opacity,
      child: AnimatedContainer(
        duration: tokens.selectDuration,
        decoration: BoxDecoration(
          color: tokens.tubeGlass,
          // Rounder at the base than the mouth, like a real vessel. A uniform
          // radius reads as a rounded rectangle, not a tube.
          borderRadius: BorderRadius.vertical(
            top: const Radius.circular(6),
            bottom: Radius.circular(tokens.tubeRadius),
          ),
          border: Border.all(
            color: highlighted
                ? tokens.accent.withValues(alpha: isSelected ? 0.75 : 0.5)
                : tokens.hairline,
            width: highlighted ? 1.5 : 1,
          ),
          boxShadow: [
            if (glow > 0)
              BoxShadow(
                color: tokens.accentWarm.withValues(alpha: 0.28 * glow),
                blurRadius: 22 * glow,
                spreadRadius: 2 * glow,
              ),
            if (isSelected)
              BoxShadow(
                color: tokens.accent.withValues(alpha: 0.16),
                blurRadius: 18,
              ),
          ],
        ),
      ),
    );
  }
}

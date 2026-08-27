/// The board: tubes, balls, and every animation that happens between them.
///
/// This is the hero of the screen and the only thing a player looks at, so the
/// motion here is the product. Three deliberate choices:
///
///  * **Balls arc, they do not slide.** A ball rises clear of its tube, travels,
///    and drops in — a cubic Bézier whose control points sit directly above each
///    tube, which makes it leave vertically and enter vertically for free.
///  * **They squash on landing.** A damped spring on the vertical scale, volume
///    preserved. This is what makes a ball feel like it has weight.
///  * **No BackdropFilter anywhere.** The frosted-glass tubes are a translucent
///    fill plus a hairline, not a real blur. A blur behind twelve tubes is the
///    fastest way to miss 60fps on the low-end Android this game has to run on.
///
/// The board also PARTICIPATES IN THE WIN SEQUENCE rather than being covered by
/// it: the solved tubes are the trophy, so they glow, the empties recede, and
/// the whole board presents itself. See `win_profile.dart` for the timing.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/game_state.dart';
import '../../state/providers.dart';
import '../theme/tokens.dart';
import 'ball.dart';
import 'board_geometry.dart';
import 'win_profile.dart';

/// Gap between successive balls leaving in one pour.
const pourStagger = Duration(milliseconds: 58);

/// How long a completed tube glows during play (not the win sequence).
const _flourishDuration = Duration(milliseconds: 720);

/// The board's state during a win sequence, or absent while playing.
class WinPhase {
  final WinProfile profile;
  final double elapsedMs;

  /// True when the run earned the third star's extra warm wash.
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

  const BoardView({
    super.key,
    required this.onTapTube,
    this.win,
    this.onBallLanded,
  });

  @override
  ConsumerState<BoardView> createState() => _BoardViewState();
}

class _BoardViewState extends ConsumerState<BoardView>
    with TickerProviderStateMixin {
  late final AnimationController _pour;
  late final AnimationController _flourish;

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
  }

  @override
  void dispose() {
    _pour.dispose();
    _flourish.dispose();
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
      if (mounted) setState(() {});
    }
  }

  void _startPour(PourEvent event, PourfectTokens tokens) {
    _landed = 0;
    _pour
      ..duration = tokens.pourDuration + pourStagger * (event.ballsMoved - 1)
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
              builder: (context, _) => Transform.translate(
                offset: Offset(0, _presentLift()),
                child: Transform.scale(
                  scale: _presentScale(),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      ..._buildTubes(state, geometry, tokens),
                      ..._buildRestingBalls(state, geometry, tokens),
                      ..._buildFlyingBalls(state, geometry, tokens),
                    ],
                  ),
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

  double _presentLift() {
    final present = widget.win?.profile.present;
    if (present == null) return 0;
    return -24 *
        Curves.easeOutBack.transform(_winSpan(present.at, present.length));
  }

  double _presentScale() {
    final present = widget.win?.profile.present;
    if (present == null) return 1;
    // Swells to 1.04 and settles back — the gesture of holding something up.
    return 1 + 0.04 * math.sin(math.pi * _winSpan(present.at, present.length));
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
          warm: math.max(_tubeGlow(i), _winGlow(state, i)),
        ),
      ),
  ];

  double _tubeOpacity(GameState state, int tube) {
    final win = widget.win;
    if (win != null) {
      // Empty tubes did not participate in the solve, so they recede and let
      // the solved ones be the trophy.
      if (state.board[tube].isEmpty) {
        return 1 - 0.75 * _winSpan(0, win.profile.glowLength);
      }
      return 1;
    }
    if (state.selectedTube == null) return 1;
    if (state.selectedTube == tube) return 1;
    return state.legalTargets.contains(tube)
        ? 1
        : PourfectTokens.illegalTargetOpacity;
  }

  /// Warm glow on a solved tube during the win sequence, staggered left to
  /// right so the board reads as settling rather than switching on.
  double _winGlow(GameState state, int tube) {
    final win = widget.win;
    if (win == null || state.board[tube].isEmpty) return 0;

    final rise = _winSpan(
      tube * win.profile.glowStagger,
      win.profile.glowLength,
    );
    var glow = Curves.easeOut.transform(rise) * 0.6;

    if (win.celebrateThird) {
      // The third star's warm wash sweeps the board and fades. Only ever on a
      // three-star run — this is what the extra star buys.
      final at = win.profile.starAt[2];
      final wash =
          _winSpan(at, win.profile.thirdStarFlourishLength) *
          (1 - _winSpan(at + win.profile.thirdStarFlourishLength, 400));
      glow += 0.4 * wash;
    }
    return glow.clamp(0.0, 1.0);
  }

  double _tubeGlow(int tube) => _glowTube == tube ? _flourishCurve : 0;

  double get _flourishCurve {
    final t = _flourish.value;
    if (t == 0 || t == 1) return 0;
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

      // Slots the in-flight balls are still heading for stay hidden; the
      // overlay owns them until they touch down.
      var visibleCount = balls.length;
      if (active != null && tube == active.move.to) {
        visibleCount = math.min(visibleCount, active.destBaseSlot + _landed);
      }

      final liftedFrom = _liftedFromSlot(state, tube);
      final opacity = _tubeOpacity(state, tube);
      final warm = math.max(_tubeGlow(tube), _winGlow(state, tube));

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
              glow: warm,
            ),
          ),
        );
      }
    }
    return widgets;
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

    final widgets = <Widget>[];
    for (var j = 0; j < active.ballsMoved; j++) {
      final startMs = j * pourStagger.inMilliseconds;
      final local = ((elapsedMs - startMs) / travelMs).clamp(0.0, 1.0);
      if (local >= 1) continue; // landed — the resting layer has it now

      final from = geometry.ballCentre(
        active.move.from,
        active.sourceTopSlot - j,
      );
      final to = geometry.ballCentre(active.move.to, active.destBaseSlot + j);

      final position = elapsedMs < startMs
          ? from
          : _arc(from, to, geometry, active, Curves.easeInOut.transform(local));

      widgets.add(
        Positioned(
          left: position.dx - geometry.ballSize / 2,
          top: position.dy - geometry.ballSize / 2,
          width: geometry.ballSize,
          height: geometry.ballSize,
          child: Ball(colorId: active.colour, size: geometry.ballSize),
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

/// The tube itself: a frosted pane with a hairline edge.
class _TubeShell extends StatelessWidget {
  final PourfectTokens tokens;
  final bool isSelected;
  final bool isHintSource;
  final bool isHintTarget;
  final double opacity;

  /// Completion warmth, 0..1 — from an in-play tube completing or from the win
  /// sequence.
  final double warm;

  const _TubeShell({
    required this.tokens,
    required this.isSelected,
    required this.isHintSource,
    required this.isHintTarget,
    required this.opacity,
    required this.warm,
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
          // Rounder at the base than the mouth, like a real vessel.
          borderRadius: BorderRadius.vertical(
            top: const Radius.circular(6),
            bottom: Radius.circular(tokens.tubeRadius),
          ),
          border: Border.all(
            color: warm > 0
                ? Color.lerp(
                    tokens.hairline,
                    tokens.accentWarm.withValues(alpha: 0.62),
                    warm,
                  )!
                : highlighted
                ? tokens.accent.withValues(alpha: isSelected ? 0.75 : 0.5)
                : tokens.hairline,
            width: highlighted || warm > 0.2 ? 1.5 : 1,
          ),
          boxShadow: [
            if (warm > 0)
              BoxShadow(
                color: tokens.accentWarm.withValues(alpha: 0.26 * warm),
                blurRadius: 24 * warm,
                spreadRadius: 2 * warm,
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

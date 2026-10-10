/// The only way anything in this app becomes tappable.
///
/// Every interactive element gets the same response — it physically SINKS
/// into its own hard shadow, a quiet sound on the way down and a light haptic
/// on release — because an element that changes nothing under your thumb feels
/// broken even when it works. Routing all of it through one widget means no
/// button can be added later that quietly forgets.
///
/// The sink is split across two widgets: Pressable translates the child down
/// by up to [Toy.pressDepth], and publishes how far through the press it is on
/// [PressDepth]. A [ToyBox] inside reads that and shrinks its shadow by the
/// same amount, so the bottom of the shadow stays planted and the button goes
/// down into it. A child with no ToyBox simply nudges down.
///
/// The press state also releases on cancel, not just on tap-up: dragging a
/// finger off a button has to un-press it, or the UI is left visibly stuck.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/providers.dart';
import '../../services/audio/audio_service.dart';
import '../theme/toy.dart';

class Pressable extends ConsumerStatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;

  /// Semantics label, when the child is not self-describing text.
  final String? semanticLabel;

  /// How far the child sinks, in logical pixels. Match it to the shadow the
  /// child's ToyBox casts; a flat child can leave the default.
  final double depth;

  /// The sound of pressing it. A plain tap unless the button means more.
  final UiCue cue;

  const Pressable({
    super.key,
    required this.child,
    required this.onPressed,
    this.semanticLabel,
    this.depth = Toy.pressDepth,
    this.cue = UiCue.tap,
  });

  @override
  ConsumerState<Pressable> createState() => _PressableState();
}

class _PressableState extends ConsumerState<Pressable>
    with SingleTickerProviderStateMixin {
  late final AnimationController _press = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 80),
    reverseDuration: const Duration(milliseconds: 140),
  );

  /// Down fast and flat; back up with a small overshoot, like a sprung key.
  late final Animation<double> _depth = CurvedAnimation(
    parent: _press,
    curve: Curves.easeOut,
    reverseCurve: Curves.easeOutBack.flipped,
  );

  bool _down = false;

  bool get _enabled => widget.onPressed != null;

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  void _set(bool value) {
    if (_down == value) return;
    _down = value;
    if (value) {
      _press.forward();
      ref.read(audioServiceProvider).ui(widget.cue);
    } else {
      _press.reverse();
    }
  }

  void _tap() {
    ref.read(hapticsServiceProvider).selection();
    widget.onPressed?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: _enabled,
      label: widget.semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: _enabled ? (_) => _set(true) : null,
        onTapUp: _enabled ? (_) => _set(false) : null,
        onTapCancel: _enabled ? () => _set(false) : null,
        onTap: _enabled ? _tap : null,
        child: AnimatedOpacity(
          opacity: _enabled ? 1 : 0.45,
          duration: const Duration(milliseconds: 160),
          child: AnimatedBuilder(
            animation: _depth,
            builder: (context, child) {
              final t = _depth.value;
              return PressDepth(
                value: t * widget.depth,
                child: Transform.translate(
                  offset: Offset(0, t * widget.depth),
                  child: child,
                ),
              );
            },
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

/// How many pixels the nearest enclosing [Pressable] has sunk. Zero at rest.
class PressDepth extends InheritedWidget {
  final double value;

  const PressDepth({super.key, required this.value, required super.child});

  static double of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<PressDepth>()?.value ?? 0;

  @override
  bool updateShouldNotify(PressDepth old) => old.value != value;
}

/// The chunky container: fill, ink stroke, hard shadow — and a shadow that
/// shrinks as an enclosing [Pressable] sinks.
class ToyBox extends StatelessWidget {
  final Widget? child;
  final Color color;
  final double radius;

  /// Resting shadow depth. 0 for none.
  final double shadow;
  final Color stroke;
  final double strokeWidth;

  /// Shadow color when it should differ from the stroke — a tomato shadow on
  /// the selected or danger variant.
  final Color? shadowColor;
  final EdgeInsetsGeometry? padding;
  final double? width;
  final double? height;
  final AlignmentGeometry? alignment;
  final BorderRadius? borderRadius;

  const ToyBox({
    super.key,
    this.child,
    this.color = Toy.card,
    this.radius = Toy.rCard,
    this.shadow = 4,
    this.stroke = Toy.ink,
    this.strokeWidth = Toy.stroke,
    this.shadowColor,
    this.padding,
    this.width,
    this.height,
    this.alignment,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final sunk = PressDepth.of(context);
    final depth = shadow <= 0 ? 0.0 : (shadow - sunk).clamp(1.0, shadow);
    return Container(
      width: width,
      height: height,
      padding: padding,
      alignment: alignment,
      // The shadow paints OUTSIDE the layout box. Leave [shadow] px of room
      // under a ToyBox, or a parent clip (a ListView, a ClipRRect) shaves it.
      decoration: BoxDecoration(
        color: color,
        borderRadius: borderRadius ?? BorderRadius.circular(radius),
        border: strokeWidth > 0
            ? Border.all(color: stroke, width: strokeWidth)
            : null,
        boxShadow: Toy.hard(depth, shadowColor ?? stroke),
      ),
      child: child,
    );
  }
}

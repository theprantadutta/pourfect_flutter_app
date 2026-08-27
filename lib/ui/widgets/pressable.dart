/// The only way anything in this app becomes tappable.
///
/// Every interactive element gets the same three-part response — a scale-down,
/// a haptic tick and a quiet sound — because an element that changes nothing
/// under your thumb feels broken even when it works. Routing all of it through
/// one widget means no button can be added later that quietly forgets.
///
/// The press state also releases on cancel, not just on tap-up: dragging a
/// finger off a button has to un-press it, or the UI is left visibly stuck.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/providers.dart';

class Pressable extends ConsumerStatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;

  /// How far it shrinks. Small by default — a button that visibly collapses
  /// reads as a toy.
  final double scale;

  /// Semantics label, when the child is not self-describing text.
  final String? semanticLabel;

  const Pressable({
    super.key,
    required this.child,
    required this.onPressed,
    this.scale = 0.955,
    this.semanticLabel,
  });

  @override
  ConsumerState<Pressable> createState() => _PressableState();
}

class _PressableState extends ConsumerState<Pressable> {
  bool _down = false;

  bool get _enabled => widget.onPressed != null;

  void _set(bool value) {
    if (_down == value) return;
    setState(() => _down = value);
    if (value) {
      ref.read(hapticsServiceProvider).selection();
      ref.read(audioServiceProvider).select();
    }
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
        onTap: widget.onPressed,
        child: AnimatedScale(
          scale: _down ? widget.scale : 1,
          // Fast down, slightly slower up: matches how a physical key feels.
          duration: Duration(milliseconds: _down ? 70 : 130),
          curve: Curves.easeOut,
          child: AnimatedOpacity(
            opacity: _enabled ? 1 : 0.32,
            duration: const Duration(milliseconds: 160),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

/// Screen transitions.
///
/// Never `MaterialPageRoute`. Its horizontal slide is an OS convention for
/// hierarchical navigation between documents, and using it here would say
/// "you have gone one level deeper into a list" when what actually happened is
/// that a vessel on a shelf opened into a board.
///
/// Two routes, both deliberate:
///
///  * [PourfectPageRoute] — a considered fade with a small scale, for moves
///    between peers.
///  * [PourfectPageRoute.fromRect] — the same, but growing out of the widget
///    the player actually touched. Tapping a level tile makes THAT tile become
///    the board, which is the closest honest thing to a shared element when the
///    destination is a whole board rather than one matching object.
library;

import 'package:flutter/widgets.dart';

class PourfectPageRoute<T> extends PageRoute<T> {
  final WidgetBuilder builder;

  /// Screen-space rect the new page grows from, if any.
  final Rect? origin;

  PourfectPageRoute({required this.builder, this.origin, super.settings});

  /// Grows the destination out of [origin], in global coordinates.
  factory PourfectPageRoute.fromRect({
    required WidgetBuilder builder,
    required Rect origin,
    RouteSettings? settings,
  }) => PourfectPageRoute(builder: builder, origin: origin, settings: settings);

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  bool get maintainState => true;

  /// Long enough to read as a considered move, short enough that a player
  /// moving between levels quickly never waits on it.
  @override
  Duration get transitionDuration => const Duration(milliseconds: 420);

  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 320);

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) => builder(context);

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    // The page being left recedes very slightly rather than sliding away, so
    // the two screens read as depth instead of as a filmstrip.
    final outgoing = CurvedAnimation(
      parent: secondaryAnimation,
      curve: Curves.easeOut,
    );

    return AnimatedBuilder(
      animation: Listenable.merge([curved, outgoing]),
      builder: (context, _) {
        final t = curved.value;
        final recede = 1 - 0.03 * outgoing.value;

        Widget content = Opacity(
          opacity: t,
          child: Transform.scale(scale: recede, child: child),
        );

        final rect = origin;
        if (rect != null) {
          final size = MediaQuery.sizeOf(context);
          // Start at the tile's scale and position, finish filling the screen.
          final startScale = rect.width / size.width;
          final scale = startScale + (1 - startScale) * t;
          final dx = (rect.center.dx - size.width / 2) * (1 - t);
          final dy = (rect.center.dy - size.height / 2) * (1 - t);

          content = Transform.translate(
            offset: Offset(dx, dy),
            child: Transform.scale(scale: scale, child: content),
          );
        } else {
          content = Transform.scale(scale: 0.97 + 0.03 * t, child: content);
        }

        return content;
      },
    );
  }
}

/// The global rect of a widget, for [PourfectPageRoute.fromRect].
Rect? globalRectOf(BuildContext context) {
  final box = context.findRenderObject();
  if (box is! RenderBox || !box.hasSize) return null;
  final origin = box.localToGlobal(Offset.zero);
  return origin & box.size;
}

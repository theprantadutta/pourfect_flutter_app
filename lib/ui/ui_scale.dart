/// Tablets draw the phone layout bigger, rather than a phone layout small.
///
/// Toybox is designed for a ~411dp phone, and on an iPad every screen came out
/// as phone-sized type, cards and buttons in a narrow column with most of the
/// glass empty. Re-laying-out thirteen screens and every dialog for a second
/// form factor would mean two designs to keep in step. Instead the whole app
/// is laid out on a phone-like canvas ([kTabletCanvas]) and drawn scaled up to
/// fill the screen: type, strokes, shadows, dialogs and toasts all grow
/// together and keep the proportions the design was made at.
///
/// **A phone is never touched.** Below 600dp shortest side the factor is
/// exactly 1 and [UiScale] adds nothing but a keyed passthrough — no
/// MediaQuery override, no transform — so every phone renders the same tree it
/// always did. The same holds for a tablet that is already about the canvas's
/// size (the 601dp Galaxy Tab A9 the tablet pass was checked on): under
/// [_minimumScale] it is left alone.
library;

import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// The logical size every tablet screen is laid out at, at most.
///
/// Wider than any phone so the 680dp content cap still has room, and about as
/// tall as a tall phone so the hub, the board and the result screen keep the
/// vertical rhythm they were designed with.
const Size kTabletCanvas = Size(600, 880);

/// Below this a tablet is close enough to the canvas to be left alone.
const double _minimumScale = 1.05;

/// The factor a screen of [size] (in logical points) is drawn at.
double uiScaleFor(Size size) {
  if (size.shortestSide < 600) return 1;
  final s = math.min(
    size.width / kTabletCanvas.width,
    size.height / kTabletCanvas.height,
  );
  return s < _minimumScale ? 1 : s;
}

/// Wraps the app (from `MaterialApp.builder`) and applies [uiScaleFor].
class UiScale extends StatefulWidget {
  const UiScale({super.key, required this.child});

  final Widget child;

  /// The factor in effect, for code that rasterises at physical resolution
  /// outside the widget tree (the ball sprite cache). 1 on every phone.
  static double current = 1;

  /// The factor in effect above [context]. 1 outside a [UiScale].
  static double of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_UiScaleScope>()?.scale ?? 1;

  @override
  State<UiScale> createState() => _UiScaleState();
}

class _UiScaleState extends State<UiScale> {
  /// Keeps the app's state (the navigator and every route on it) when a
  /// resizable iPad window crosses the threshold and the wrapper appears or
  /// disappears around it.
  final _app = GlobalKey();

  @override
  Widget build(BuildContext context) {
    // Size only, until scaling is known to apply: a phone's wrapper must not
    // rebuild every time the keyboard or a safe-area inset moves.
    final s = uiScaleFor(MediaQuery.sizeOf(context));
    UiScale.current = s;

    final app = KeyedSubtree(key: _app, child: widget.child);
    if (s == 1) return app;

    final media = MediaQuery.of(context);
    final logical = media.size / s;
    return MediaQuery(
      // Everything that is measured in logical points shrinks by the same
      // factor the picture grows by, so a safe area, the keyboard and a
      // gesture inset still land exactly where the system puts them. The
      // pixel ratio grows instead, so images and anything else that picks a
      // resolution from it are drawn sharp rather than upscaled.
      data: media.copyWith(
        size: logical,
        devicePixelRatio: media.devicePixelRatio * s,
        padding: media.padding / s,
        viewPadding: media.viewPadding / s,
        viewInsets: media.viewInsets / s,
        systemGestureInsets: media.systemGestureInsets / s,
      ),
      child: _UiScaleScope(
        scale: s,
        // FittedBox maps hit tests through the same transform it paints with,
        // so a tap lands on what is drawn under the finger.
        child: FittedBox(
          fit: BoxFit.fill,
          child: SizedBox.fromSize(size: logical, child: app),
        ),
      ),
    );
  }
}

class _UiScaleScope extends InheritedWidget {
  const _UiScaleScope({required this.scale, required super.child});

  final double scale;

  @override
  bool updateShouldNotify(_UiScaleScope old) => old.scale != scale;
}

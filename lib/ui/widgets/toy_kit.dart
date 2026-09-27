/// The Toybox component kit: every chunky building block the screens share.
///
/// Screens compose these rather than hand-rolling a BoxDecoration. The look
/// lives in a handful of numbers — the 2.5px stroke, the no-blur shadow, the
/// 14/18/20/26 radii — and the fastest way to lose it is thirty screens each
/// re-typing them slightly differently.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/ball_palette.dart';
import '../theme/toy.dart';
import 'ball.dart';
import 'pressable.dart';

export 'pressable.dart' show Pressable, PressDepth, ToyBox;

// ---------------------------------------------------------------------------
// Ground
// ---------------------------------------------------------------------------

/// A screen's ground: the dotted surface, the matching status-bar icons, and a
/// SafeArea. Every full screen starts here.
class ToyScaffold extends StatelessWidget {
  final ToySurface surface;
  final Widget child;

  /// Painted between the ground and [child] — the win rays, for instance.
  final Widget? backdrop;

  final EdgeInsetsGeometry padding;
  final bool safeBottom;

  const ToyScaffold({
    super.key,
    required this.child,
    this.surface = ToySurface.cream,
    this.backdrop,
    this.padding = const EdgeInsets.fromLTRB(20, 8, 20, 16),
    this.safeBottom = true,
  });

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: surface.overlay,
      child: Material(
        type: MaterialType.canvas,
        color: surface.background,
        child: Stack(
          fit: StackFit.expand,
          children: [
            RepaintBoundary(
              child: CustomPaint(painter: DotGridPainter.surface(surface)),
            ),
            ?backdrop,
            SafeArea(
              bottom: safeBottom,
              child: Padding(padding: padding, child: child),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Buttons
// ---------------------------------------------------------------------------

/// The big chunky CTA: PLAY, NEXT LEVEL, LET'S POUR!
///
/// Labels are the display face; [compact] switches to Outfit 800 for a
/// secondary button that should not shout (Cancel).
class ToyButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final Color color;
  final Color textColor;
  final Widget? icon;
  final double height;
  final double radius;
  final double shadow;
  final Color? shadowColor;
  final bool compact;
  final double fontSize;
  final String? semanticLabel;

  const ToyButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.color = Toy.tomato,
    this.textColor = Colors.white,
    this.icon,
    this.height = 60,
    this.radius = Toy.rControl,
    this.shadow = 5,
    this.shadowColor,
    this.compact = false,
    this.fontSize = 26,
    this.semanticLabel,
  });

  /// White secondary with ink text in Outfit.
  const ToyButton.secondary({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.height = 52,
    this.radius = 16,
    this.shadow = 4,
    this.fontSize = 16,
    this.semanticLabel,
  }) : color = Toy.card,
       textColor = Toy.ink,
       shadowColor = null,
       compact = true;

  @override
  Widget build(BuildContext context) {
    final style = compact
        ? Toy.ui(fontSize, weight: FontWeight.w800, color: textColor)
        : Toy.display(fontSize, color: textColor, letterSpacing: 0.5);
    return Pressable(
      onPressed: onPressed,
      semanticLabel: semanticLabel,
      depth: shadow - 1,
      child: ToyBox(
        height: height,
        color: color,
        radius: radius,
        shadow: shadow,
        shadowColor: shadowColor,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[icon!, const SizedBox(width: 10)],
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(label, style: style, maxLines: 1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The 44px square control: back, menu, the moves counter.
class ToySquareButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final Color color;
  final double size;
  final String? semanticLabel;

  const ToySquareButton({
    super.key,
    required this.child,
    required this.onPressed,
    this.color = Toy.card,
    this.size = 44,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    final box = ToyBox(
      width: size,
      height: size,
      radius: Toy.rButton,
      color: color,
      shadow: 3,
      alignment: Alignment.center,
      child: child,
    );
    if (onPressed == null) {
      return Semantics(label: semanticLabel, child: box);
    }
    return Pressable(
      onPressed: onPressed,
      semanticLabel: semanticLabel,
      depth: 2,
      child: box,
    );
  }
}

/// The back chevron, as a square button. Pops the route by default.
class ToyBackButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Color color;

  const ToyBackButton({super.key, this.onPressed, this.color = Toy.card});

  @override
  Widget build(BuildContext context) => ToySquareButton(
    semanticLabel: 'Back',
    color: color,
    onPressed: onPressed ?? () => Navigator.of(context).maybePop(),
    child: const CustomPaint(
      size: Size(18, 18),
      painter: ToyGlyphPainter(ToyGlyph.back),
    ),
  );
}

/// Screen header: back button, display title, optional trailing widget.
///
/// [centerTitle] is the gameplay/journey layout (title between two controls);
/// otherwise the title sits left, next to the back button, like Settings.
class ToyHeader extends StatelessWidget {
  final String title;
  final Widget? subtitle;
  final Widget? trailing;
  final bool centerTitle;
  final VoidCallback? onBack;
  final Color titleColor;
  final bool showBack;

  const ToyHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.centerTitle = false,
    this.onBack,
    this.titleColor = Toy.ink,
    this.showBack = true,
  });

  @override
  Widget build(BuildContext context) {
    final titleText = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: centerTitle
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            title,
            maxLines: 1,
            style: Toy.display(30, color: titleColor),
          ),
        ),
        ?subtitle,
      ],
    );

    return SizedBox(
      height: 50,
      child: Row(
        children: [
          if (showBack) ToyBackButton(onPressed: onBack),
          if (centerTitle)
            Expanded(child: Center(child: titleText))
          else ...[
            const SizedBox(width: 14),
            Expanded(child: titleText),
          ],
          if (trailing != null)
            trailing!
          else if (centerTitle && showBack)
            const SizedBox(width: 44),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Chips, stickers, labels
// ---------------------------------------------------------------------------

/// A small rounded label: "par 14", "51 ★", a pace chip.
class ToyChip extends StatelessWidget {
  final Widget child;
  final Color color;
  final double radius;
  final EdgeInsetsGeometry padding;
  final double shadow;

  const ToyChip({
    super.key,
    required this.child,
    this.color = Toy.cream,
    this.radius = 999,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
    this.shadow = 0,
  });

  /// Convenience for a plain text chip.
  ToyChip.text(
    String text, {
    super.key,
    this.color = Toy.cream,
    Color textColor = Toy.ink,
    double size = 12,
    this.radius = 999,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
    this.shadow = 0,
  }) : child = Text(
         text,
         style: Toy.numbers(size, color: textColor, weight: FontWeight.w700),
       );

  @override
  Widget build(BuildContext context) => ToyBox(
    color: color,
    radius: radius,
    strokeWidth: Toy.strokeThin,
    shadow: shadow,
    padding: padding,
    child: DefaultTextStyle.merge(
      style: Toy.ui(12, weight: FontWeight.w700),
      child: child,
    ),
  );
}

/// A tilted sticker: NEW BEST!, SORTED!, the daily rank badge.
///
/// Tilt is a garnish — two per screen at most, and never inside a list.
class ToySticker extends StatelessWidget {
  final Widget child;
  final Color color;

  /// Degrees, -12..12.
  final double angle;
  final double shadow;
  final EdgeInsetsGeometry padding;
  final double radius;

  const ToySticker({
    super.key,
    required this.child,
    this.color = Toy.pink,
    this.angle = 6,
    this.shadow = 3,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
    this.radius = 12,
  });

  /// A caps text sticker in the display face.
  ToySticker.text(
    String text, {
    super.key,
    this.color = Toy.pink,
    Color textColor = Toy.ink,
    double size = 16,
    this.angle = 6,
    this.shadow = 3,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
    this.radius = 12,
  }) : child = Text(text, style: Toy.display(size, color: textColor));

  @override
  Widget build(BuildContext context) => Transform.rotate(
    angle: angle * math.pi / 180,
    child: ToyBox(
      color: color,
      radius: radius,
      shadow: shadow,
      padding: padding,
      child: child,
    ),
  );
}

/// Section header above a card: FEEL, VISIBILITY, DANGER ZONE.
class ToySectionLabel extends StatelessWidget {
  final String text;
  final Color color;

  const ToySectionLabel(this.text, {super.key, this.color = Toy.inkMuted});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 6, 4, 6),
    child: Text(text.toUpperCase(), style: Toy.caps(color: color)),
  );
}

/// The ink pill toast: "Holding 2 · drop into a bouncing tube".
class ToyToast extends StatelessWidget {
  final Widget? leading;
  final String text;

  const ToyToast({super.key, required this.text, this.leading});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    decoration: BoxDecoration(
      color: Toy.ink,
      borderRadius: BorderRadius.circular(Toy.rControl),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (leading != null) ...[leading!, const SizedBox(width: 10)],
        Flexible(
          child: Text(
            text,
            maxLines: 2,
            textAlign: TextAlign.center,
            style: Toy.ui(15, weight: FontWeight.w700, color: Colors.white),
          ),
        ),
      ],
    ),
  );
}

// ---------------------------------------------------------------------------
// Controls
// ---------------------------------------------------------------------------

/// Toy toggle: mint when on, stroke + white knob.
class ToyToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  final String? semanticLabel;

  const ToyToggle({
    super.key,
    required this.value,
    required this.onChanged,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    final calm = Toy.calm(context);
    return Semantics(
      toggled: value,
      label: semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onChanged == null ? null : () => onChanged!(!value),
        child: AnimatedContainer(
          duration: calm ? Duration.zero : const Duration(milliseconds: 160),
          curve: Curves.easeOutBack,
          width: 50,
          height: 30,
          padding: const EdgeInsets.symmetric(horizontal: 3),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          decoration: BoxDecoration(
            color: value ? Toy.mint : Toy.toggleOff,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Toy.ink, width: Toy.stroke),
          ),
          child: Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: Toy.ink, width: Toy.stroke),
            ),
          ),
        ),
      ),
    );
  }
}

/// Pill tabs: Today / Campaign, Overview / Levels.
///
/// Tomato when the tab IS the primary choice on the screen (Rankings); ink
/// when it only switches a view (Stats), where tomato would shout.
class ToyTabs extends StatelessWidget {
  final List<String> labels;
  final int index;
  final ValueChanged<int> onChanged;
  final Color selectedColor;
  final double height;
  final double fontSize;

  const ToyTabs({
    super.key,
    required this.labels,
    required this.index,
    required this.onChanged,
    this.selectedColor = Toy.tomato,
    this.height = 38,
    this.fontSize = 15,
  });

  @override
  Widget build(BuildContext context) {
    final calm = Toy.calm(context);
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Toy.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Toy.ink, width: Toy.stroke),
      ),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++) ...[
            if (i > 0) const SizedBox(width: 4),
            Expanded(
              child: Semantics(
                selected: i == index,
                button: true,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onChanged(i),
                  child: AnimatedContainer(
                    duration: calm
                        ? Duration.zero
                        : const Duration(milliseconds: 160),
                    height: height,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: i == index ? selectedColor : Colors.transparent,
                      borderRadius: BorderRadius.circular(11),
                      border: Border.all(
                        color: i == index && selectedColor != Toy.ink
                            ? Toy.ink
                            : Colors.transparent,
                        width: Toy.strokeThin,
                      ),
                    ),
                    child: Text(
                      labels[i],
                      style: Toy.ui(
                        fontSize,
                        weight: FontWeight.w800,
                        color: i == index ? Colors.white : Toy.inkMuted,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// A stroked progress bar: yellow fill on a translucent or cream track.
class ToyProgressBar extends StatelessWidget {
  /// 0..1.
  final double value;
  final Color fill;
  final Color track;
  final double height;

  const ToyProgressBar({
    super.key,
    required this.value,
    this.fill = Toy.yellow,
    this.track = Toy.track,
    this.height = 14,
  });

  @override
  Widget build(BuildContext context) => Container(
    height: height,
    decoration: BoxDecoration(
      color: track,
      borderRadius: BorderRadius.circular(height),
      border: Border.all(color: Toy.ink, width: Toy.strokeThin),
    ),
    clipBehavior: Clip.antiAlias,
    child: Align(
      alignment: Alignment.centerLeft,
      child: FractionallySizedBox(
        widthFactor: value.clamp(0.0, 1.0),
        heightFactor: 1,
        child: ColoredBox(color: fill),
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// Tiles, avatars, balls
// ---------------------------------------------------------------------------

/// A colored rounded-square icon tile: settings row icons, list avatars.
class ToyIconTile extends StatelessWidget {
  final Widget child;
  final Color color;
  final double size;
  final double radius;
  final double strokeWidth;

  const ToyIconTile({
    super.key,
    required this.child,
    required this.color,
    this.size = 36,
    this.radius = 11,
    this.strokeWidth = Toy.strokeThin,
  });

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: Toy.ink, width: strokeWidth),
    ),
    child: IconTheme.merge(
      data: IconThemeData(color: Toy.ink, size: size * 0.5),
      child: DefaultTextStyle.merge(
        style: Toy.ui(size * 0.45, weight: FontWeight.w800),
        child: child,
      ),
    ),
  );
}

/// The ball colors, in order, used to color initial avatars so a name always
/// gets the same color.
const _avatarColors = [
  Toy.lilac,
  Toy.mint,
  Toy.pink,
  Toy.blue,
  Toy.yellow,
  Toy.tomato,
];

/// Stable avatar color for a name.
Color avatarColorFor(String name) {
  var h = 0;
  for (final c in name.codeUnits) {
    h = (h * 31 + c) & 0x7fffffff;
  }
  return _avatarColors[h % _avatarColors.length];
}

/// A player's avatar: their photo inside the toy frame when there is one,
/// otherwise their initial on a color tile.
class ToyAvatar extends StatelessWidget {
  final String name;
  final String? photoUrl;
  final double size;
  final Color? color;

  /// Initial color. White by default; lilac on a white tile (Settings card).
  final Color letterColor;
  final double? strokeWidth;

  const ToyAvatar({
    super.key,
    required this.name,
    this.photoUrl,
    this.size = 30,
    this.color,
    this.letterColor = Colors.white,
    this.strokeWidth,
  });

  @override
  Widget build(BuildContext context) {
    final radius = size * 0.3;
    final stroke = strokeWidth ?? (size >= 44 ? Toy.stroke : Toy.strokeThin);
    final initial = name.trim().isEmpty
        ? '?'
        : name.trim().characters.first.toUpperCase();
    final fallback = Center(
      child: Text(
        initial,
        style: Toy.display(size * 0.53, color: letterColor),
      ),
    );

    final url = photoUrl;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color ?? avatarColorFor(name),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: Toy.ink, width: stroke),
      ),
      clipBehavior: Clip.antiAlias,
      child: url == null || url.isEmpty
          ? fallback
          : Image.network(
              url,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => fallback,
              frameBuilder: (_, child, frame, sync) =>
                  sync || frame != null ? child : fallback,
            ),
    );
  }
}

/// A toy ball with an arbitrary color and glyph — for icons, the palette
/// strip, confetti. Board balls use [Ball] with an engine color id instead.
class ToyBall extends StatelessWidget {
  final Color color;
  final BallGlyph glyph;
  final double size;
  final Color ink;
  final bool drop;

  const ToyBall({
    super.key,
    required this.color,
    required this.glyph,
    this.size = 26,
    this.ink = Toy.ink,
    this.drop = false,
  });

  /// The ball for an engine color id.
  factory ToyBall.id(int colorId, {Key? key, double size = 26}) {
    final style = kBallPalette[colorId % kBallPalette.length];
    return ToyBall(
      key: key,
      color: Color(0xFF000000 | style.rgb),
      glyph: style.glyph,
      ink: Color(0xFF000000 | style.glyphInk),
      size: size,
    );
  }

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: CustomPaint(
      painter: BallPainter(color: color, glyph: glyph, ink: ink, drop: drop),
    ),
  );
}

// ---------------------------------------------------------------------------
// Stars
// ---------------------------------------------------------------------------

/// A row of stroked stars, [earned] of [total] filled.
class ToyStars extends StatelessWidget {
  final int earned;
  final int total;
  final double size;
  final double spacing;
  final Color fill;

  /// Draw the ink outline and drop. Off for the tiny tomato stars under a
  /// journey tile, which are flat glyphs.
  final bool outlined;

  const ToyStars({
    super.key,
    required this.earned,
    this.total = 3,
    this.size = 20,
    this.spacing = 2,
    this.fill = Toy.yellow,
    this.outlined = true,
  });

  @override
  Widget build(BuildContext context) => Semantics(
    label: '$earned of $total stars',
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < total; i++) ...[
          if (i > 0) SizedBox(width: spacing),
          ToyStar(size: size, filled: i < earned, fill: fill, outlined: outlined),
        ],
      ],
    ),
  );
}

/// One star.
class ToyStar extends StatelessWidget {
  final double size;
  final bool filled;
  final Color fill;
  final bool outlined;

  const ToyStar({
    super.key,
    this.size = 20,
    this.filled = true,
    this.fill = Toy.yellow,
    this.outlined = true,
  });

  @override
  Widget build(BuildContext context) => CustomPaint(
    size: Size.square(size),
    painter: _StarPainter(filled: filled, fill: fill, outlined: outlined),
  );
}

class _StarPainter extends CustomPainter {
  final bool filled;
  final Color fill;
  final bool outlined;

  const _StarPainter({
    required this.filled,
    required this.fill,
    required this.outlined,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final k = size.width / 40;
    final path = starPath(
      Offset(size.width / 2, size.height * 0.53),
      size.width * (outlined ? 0.46 : 0.5),
    );
    if (!outlined) {
      canvas.drawPath(
        path,
        filled
            ? (Paint()..color = fill)
            : (Paint()
                ..color = fill
                ..style = PaintingStyle.stroke
                ..strokeWidth = size.width * 0.09
                ..strokeJoin = StrokeJoin.round),
      );
      return;
    }
    if (filled) {
      canvas.drawPath(path.shift(Offset(0, 3 * k)), Paint()..color = Toy.ink);
    }
    canvas
      ..drawPath(path, Paint()..color = filled ? fill : const Color(0x33FFFFFF))
      ..drawPath(
        path,
        Paint()
          ..color = Toy.ink
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5 * k
          ..strokeJoin = StrokeJoin.round,
      );
  }

  @override
  bool shouldRepaint(_StarPainter old) =>
      old.filled != filled || old.fill != fill || old.outlined != outlined;
}

/// A five-point star centred on [c] with outer radius [r].
Path starPath(Offset c, double r) {
  final path = Path();
  const inner = 0.47;
  for (var i = 0; i < 10; i++) {
    final radius = i.isEven ? r : r * inner;
    final a = -math.pi / 2 + i * math.pi / 5;
    final p = c + Offset(math.cos(a) * radius, math.sin(a) * radius);
    i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
  }
  return path..close();
}

// ---------------------------------------------------------------------------
// Glyph icons
// ---------------------------------------------------------------------------

/// The handful of UI glyphs the mockups draw by hand, rather than pulling in a
/// Material icon whose stroke weight never matches the ink.
enum ToyGlyph { back, menu, play, undo, restart, hint, close, check, lock }

class ToyGlyphPainter extends CustomPainter {
  final ToyGlyph glyph;
  final Color color;

  const ToyGlyphPainter(this.glyph, {this.color = Toy.ink});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final line = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(2.5, w * 0.16)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final fill = Paint()..color = color;

    switch (glyph) {
      case ToyGlyph.back:
        canvas.drawPath(
          Path()
            ..moveTo(w * 0.62, h * 0.2)
            ..lineTo(w * 0.32, h * 0.5)
            ..lineTo(w * 0.62, h * 0.8),
          line,
        );
      case ToyGlyph.menu:
        line.strokeWidth = math.max(2.5, h * 0.14);
        for (final y in [0.22, 0.5, 0.78]) {
          canvas.drawLine(Offset(w * 0.1, h * y), Offset(w * 0.9, h * y), line);
        }
      case ToyGlyph.play:
        canvas.drawPath(
          Path()
            ..moveTo(w * 0.15, h * 0.08)
            ..lineTo(w * 0.92, h * 0.5)
            ..lineTo(w * 0.15, h * 0.92)
            ..close(),
          fill,
        );
      case ToyGlyph.undo:
      case ToyGlyph.restart:
        // Circular arrows are the one glyph a hand-drawn path gets visibly
        // wrong at 20px; the rounded Material pair has the right weight.
        final icon = glyph == ToyGlyph.undo
            ? Icons.undo_rounded
            : Icons.refresh_rounded;
        final tp = TextPainter(
          text: TextSpan(
            text: String.fromCharCode(icon.codePoint),
            style: TextStyle(
              fontFamily: icon.fontFamily,
              package: icon.fontPackage,
              fontSize: w * 1.15,
              color: color,
              fontWeight: FontWeight.w900,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset((w - tp.width) / 2, (h - tp.height) / 2));
      case ToyGlyph.hint:
        final style = Toy.display(h * 0.95, color: color);
        final tp = TextPainter(
          text: TextSpan(text: '?', style: style),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset((w - tp.width) / 2, (h - tp.height) / 2));
      case ToyGlyph.close:
        canvas
          ..drawLine(Offset(w * 0.22, h * 0.22), Offset(w * 0.78, h * 0.78), line)
          ..drawLine(Offset(w * 0.78, h * 0.22), Offset(w * 0.22, h * 0.78), line);
      case ToyGlyph.check:
        canvas.drawPath(
          Path()
            ..moveTo(w * 0.18, h * 0.52)
            ..lineTo(w * 0.42, h * 0.76)
            ..lineTo(w * 0.84, h * 0.26),
          line,
        );
      case ToyGlyph.lock:
        line.strokeWidth = math.max(2, w * 0.12);
        canvas
          ..drawArc(
            Rect.fromLTWH(w * 0.28, h * 0.1, w * 0.44, h * 0.5),
            math.pi,
            math.pi,
            false,
            line,
          )
          ..drawLine(Offset(w * 0.28, h * 0.35), Offset(w * 0.28, h * 0.46), line)
          ..drawLine(Offset(w * 0.72, h * 0.35), Offset(w * 0.72, h * 0.46), line)
          ..drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(w * 0.16, h * 0.44, w * 0.68, h * 0.48),
              Radius.circular(w * 0.1),
            ),
            fill,
          );
    }
  }

  @override
  bool shouldRepaint(ToyGlyphPainter old) =>
      old.glyph != glyph || old.color != color;
}

/// A [ToyGlyph] as a sized widget.
class ToyIcon extends StatelessWidget {
  final ToyGlyph glyph;
  final double size;
  final Color color;

  const ToyIcon(this.glyph, {super.key, this.size = 20, this.color = Toy.ink});

  @override
  Widget build(BuildContext context) => CustomPaint(
    size: Size.square(size),
    painter: ToyGlyphPainter(glyph, color: color),
  );
}

// ---------------------------------------------------------------------------
// Dialogs
// ---------------------------------------------------------------------------

/// Shows a Toybox dialog: ink scrim, and the card scales in from 0.9 with a
/// small overshoot.
Future<T?> showToyDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
}) {
  final calm = Toy.calm(context);
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierLabel: 'Dismiss',
    barrierColor: Toy.scrim,
    transitionDuration: calm ? Duration.zero : const Duration(milliseconds: 260),
    pageBuilder: (context, _, _) => SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Material(type: MaterialType.transparency, child: builder(context)),
        ),
      ),
    ),
    transitionBuilder: (context, animation, _, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutBack,
        reverseCurve: Curves.easeIn,
      );
      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        child: ScaleTransition(
          scale: Tween(begin: 0.9, end: 1.0).animate(curved),
          child: child,
        ),
      );
    },
  );
}

/// The standard dialog card: white, 3px ink stroke, 7px shadow, an optional
/// colored header band.
class ToyDialogCard extends StatelessWidget {
  final Widget? header;
  final Color headerColor;
  final Widget child;
  final double angle;

  const ToyDialogCard({
    super.key,
    required this.child,
    this.header,
    this.headerColor = Toy.tomato,
    this.angle = 0,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      constraints: const BoxConstraints(maxWidth: 420),
      decoration: BoxDecoration(
        color: Toy.card,
        borderRadius: BorderRadius.circular(Toy.rHero),
        border: Border.all(color: Toy.ink, width: 3),
        boxShadow: Toy.hard(7),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (header != null)
            Container(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 12),
              decoration: BoxDecoration(
                color: headerColor,
                border: const Border(
                  bottom: BorderSide(color: Toy.ink, width: 3),
                ),
              ),
              child: header,
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
            child: child,
          ),
        ],
      ),
    );
    return angle == 0
        ? card
        : Transform.rotate(angle: angle * math.pi / 180, child: card);
  }
}

/// A plain question dialog in the Toybox style: title, body, and two buttons.
/// Resolves true for [confirmLabel], false for [cancelLabel].
Future<bool> showToyConfirm({
  required BuildContext context,
  required String title,
  required String body,
  String confirmLabel = 'OK',
  String cancelLabel = 'Cancel',
  Color confirmColor = Toy.mint,
  Color confirmTextColor = Toy.ink,
}) async {
  final result = await showToyDialog<bool>(
    context: context,
    builder: (context) => ToyDialogCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: Toy.display(24, height: 1.1)),
          const SizedBox(height: 10),
          Text(
            body,
            style: Toy.ui(15, weight: FontWeight.w500, color: Toy.inkMuted, height: 1.4),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: ToyButton.secondary(
                  label: cancelLabel,
                  onPressed: () => Navigator.of(context).pop(false),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ToyButton(
                  label: confirmLabel,
                  color: confirmColor,
                  textColor: confirmTextColor,
                  height: 52,
                  radius: 16,
                  shadow: 4,
                  fontSize: 20,
                  onPressed: () => Navigator.of(context).pop(true),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
  return result ?? false;
}

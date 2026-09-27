/// Where every level sits on the winding path, and how it is drawn.
///
/// **Geometry is a pure function of the level number**, not a layout pass. A
/// level is always in the same place, on every launch and every device width,
/// which is what makes the path feel like a map rather than a list that happens
/// to wiggle. It also means scrolling to a level is arithmetic.
///
/// **Painted, never built.** 150 levels as widgets is 150 layouts on a scroll
/// that has to stay inside a 16.67ms frame, and the measured budget here is
/// already 1.2ms build plus 4.5ms raster in steady play. One painter draws the
/// lot and a hit test maps a tap back to a level, so the whole campaign costs
/// one widget.
///
/// Toybox look: every level is a chunky rounded-square tile. Done is mint with
/// its stars underneath, the current level is a bigger tomato tile under an
/// ink "YOU" pin with a breathing halo, and the road ahead is dashed.
library;

import 'dart:math' as math;
import 'dart:ui' show PointMode;

import 'package:flutter/material.dart';

import '../theme/toy.dart';
import '../theme/tokens.dart';
import 'toy_kit.dart' show starPath;

/// Vertical distance between consecutive levels.
///
/// A 46px tile, its row of stars underneath, and enough air that the dotted
/// trail between two tiles still reads as a trail. The mockup draws 62, but
/// at a turn two tiles stack almost vertically and 62 let the lower tile's
/// stars touch the upper tile.
const double kJourneyStep = 66;

/// How far the path swings either side of centre, as a fraction of width.
/// 100px either side on a 360dp phone, as drawn.
const double _kSwing = 0.28;

/// Radians of swing per level. Non-integer period (about 5.5 levels) on
/// purpose: a whole number lines every nth level up in a column and the eye
/// finds the grid.
const double _kTurn = 1.15;

/// Phase chosen so levels 21–28 sit exactly where the mockup draws them.
const double _kPhase = -0.9 - 21 * _kTurn;

/// Room above the last level: the YOU pin and the halo of a current tile.
const double kJourneyPadTop = 84;

/// Room below level 1 for its stars and its shadow.
const double kJourneyPadBottom = 72;

/// Side of a done / locked tile, and of the current one.
const double kJourneyTile = 46;
const double kJourneyTileCurrent = 62;

/// Total scrollable height for [levelCount] levels.
double journeyHeight(int levelCount) =>
    kJourneyPadTop + kJourneyPadBottom + (levelCount - 1) * kJourneyStep;

/// Where a level sits, in the path's own coordinate space.
///
/// Level 1 is at the BOTTOM and the campaign climbs. Going up as you progress
/// is the whole reason the shape means anything.
Offset journeyPosition(int levelId, int levelCount, double width) {
  final fromBottom = levelId - 1;
  final y =
      journeyHeight(levelCount) - kJourneyPadBottom - fromBottom * kJourneyStep;
  final x = width / 2 + math.sin(levelId * _kTurn + _kPhase) * width * _kSwing;
  return Offset(x, y);
}

/// One level's state on the path.
enum JourneyMark { locked, unlocked, solved, current }

class JourneyLevel {
  const JourneyLevel({
    required this.id,
    required this.mark,
    required this.stars,
    required this.colorId,
  });

  final int id;
  final JourneyMark mark;
  final int stars;

  /// A ball color for the level. The Toybox tiles are colored by state, not
  /// by ball, so the path no longer paints this; it is kept so callers that
  /// still build it compile.
  final int colorId;
}

/// A band's name and size, pinned to its first level.
class JourneyBand {
  const JourneyBand({
    required this.firstLevel,
    required this.name,
    required this.length,
    required this.reached,
  });

  final int firstLevel;
  final String name;
  final int length;

  /// Dimmed until the player has arrived, so the path ahead reads as unwritten.
  final bool reached;
}

class JourneyPainter extends CustomPainter {
  JourneyPainter({
    required this.levels,
    required this.bands,
    this.tokens,
    this.boldGlyphs = false,
    required this.pulse,
    required this.visibleTop,
    required this.visibleBottom,
  });

  final List<JourneyLevel> levels;
  final List<JourneyBand> bands;

  /// Unused by the Toybox path, which reads [Toy] directly. Kept optional so
  /// older callers compile.
  final PourfectTokens? tokens;

  /// Unused since the tiles stopped carrying balls; kept for callers.
  final bool boldGlyphs;

  /// 0-1, drives the current level's breathing halo. The only thing that
  /// animates, so the repaint it forces is confined to this painter.
  final double pulse;

  /// The slice of the path actually on screen.
  ///
  /// The canvas is the whole campaign — over 9,000px — and the pulse repaints
  /// it every frame. Clipping to the viewport turns 150 tiles and 450 dots
  /// per frame into the dozen that can be seen.
  final double visibleTop;
  final double visibleBottom;

  bool _onScreen(double y) =>
      y >= visibleTop - kJourneyStep && y <= visibleBottom + kJourneyStep;

  static const _trailDone = Toy.mint;
  static const _trailAhead = Color(0x401F1A33);
  static const _lockedStroke = Color(0x731F1A33);
  static const _lockedText = Color(0x8C1F1A33);
  static const _halo = Color(0x2EFF5A36);

  @override
  void paint(Canvas canvas, Size size) {
    final count = levels.length;
    Offset at(int id) => journeyPosition(id, count, size.width);

    _paintTrail(canvas, count, at);

    for (var i = 0; i < bands.length; i++) {
      final band = bands[i];
      final centre = at(band.firstLevel);
      if (_onScreen(centre.dy)) {
        _paintBandMarker(canvas, size, band, i + 1, centre);
      }
    }

    JourneyLevel? current;
    for (final level in levels) {
      final centre = at(level.id);
      if (!_onScreen(centre.dy)) continue;
      if (level.mark == JourneyMark.current) {
        current = level;
        continue;
      }
      _paintTile(canvas, level, centre);
    }
    // Last, so its halo and pin sit over the trail and any neighbor.
    if (current != null) _paintCurrent(canvas, current, at(current.id));
  }

  /// Stepping stones between levels: three dots per gap, batched into one
  /// point call per color rather than three canvas ops per gap. Mint where
  /// the player has already been, grey ahead.
  void _paintTrail(Canvas canvas, int count, Offset Function(int) at) {
    final done = <Offset>[];
    final ahead = <Offset>[];
    for (var id = 1; id < count; id++) {
      final a = at(id);
      if (!_onScreen(a.dy)) continue;
      final b = at(id + 1);
      final walked =
          levels[id - 1].mark == JourneyMark.solved &&
          (levels[id].mark == JourneyMark.solved ||
              levels[id].mark == JourneyMark.current);
      for (final f in const [0.35, 0.5, 0.65]) {
        (walked ? done : ahead).add(Offset.lerp(a, b, f)!);
      }
    }

    Paint dot(Color c) => Paint()
      ..color = c
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    if (ahead.isNotEmpty) {
      canvas.drawPoints(PointMode.points, ahead, dot(_trailAhead));
    }
    if (done.isNotEmpty) {
      canvas.drawPoints(PointMode.points, done, dot(_trailDone));
    }
  }

  void _paintTile(Canvas canvas, JourneyLevel level, Offset centre) {
    final rect = Rect.fromCenter(
      center: centre,
      width: kJourneyTile,
      height: kJourneyTile,
    );
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(15));
    final stroke = Paint()
      ..color = Toy.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = Toy.stroke;

    switch (level.mark) {
      case JourneyMark.solved:
      case JourneyMark.unlocked:
        final solved = level.mark == JourneyMark.solved;
        canvas
          ..drawRRect(rrect.shift(const Offset(0, 4)), Paint()..color = Toy.ink)
          ..drawRRect(rrect, Paint()..color = solved ? Toy.mint : Toy.card)
          ..drawRRect(rrect.deflate(Toy.stroke / 2), stroke);
        _label(canvas, _TileText.done, level.id, centre);
        if (solved) _paintStars(canvas, level.stars, rect.bottomCenter);

      case JourneyMark.locked:
        canvas
          ..drawRRect(rrect, Paint()..color = Toy.card)
          ..drawPath(
            _dashedTile.shift(rect.topLeft),
            Paint()
              ..color = _lockedStroke
              ..style = PaintingStyle.stroke
              ..strokeWidth = Toy.stroke,
          );
        _label(canvas, _TileText.locked, level.id, centre);

      case JourneyMark.current:
        break;
    }
  }

  void _paintCurrent(Canvas canvas, JourneyLevel level, Offset centre) {
    final rect = Rect.fromCenter(
      center: centre,
      width: kJourneyTileCurrent,
      height: kJourneyTileCurrent,
    );
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(19));

    // Halo: 8px of tomato tint, breathing out to 13px. Scale and alpha only;
    // no blur on a scrolling surface.
    final t = Curves.easeInOut.transform(pulse.clamp(0.0, 1.0));
    final spread = 8 + 5 * t;
    canvas.drawRRect(
      rrect.shift(const Offset(0, 2.5)).inflate(spread),
      Paint()..color = _halo.withValues(alpha: _halo.a * (1 - 0.35 * t)),
    );

    canvas
      ..drawRRect(rrect.shift(const Offset(0, 5)), Paint()..color = Toy.ink)
      ..drawRRect(rrect, Paint()..color = Toy.tomato)
      ..drawRRect(
        rrect.deflate(1.5),
        Paint()
          ..color = Toy.ink
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
    _label(canvas, _TileText.current, level.id, centre);

    // The YOU pin, 6px above the tile.
    final you = _text(
      'you',
      'YOU',
      Toy.ui(
        11,
        weight: FontWeight.w800,
        color: Colors.white,
        letterSpacing: 1,
      ),
    );
    final pin = Rect.fromCenter(
      center: Offset(centre.dx, rect.top - 6 - (you.height + 6) / 2),
      width: you.width + 16,
      height: you.height + 6,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(pin, const Radius.circular(8)),
      Paint()..color = Toy.ink,
    );
    you.paint(canvas, pin.center - Offset(you.width / 2, you.height / 2));
  }

  /// Flat tomato stars under a done tile: filled for earned, outlined for not.
  void _paintStars(Canvas canvas, int earned, Offset top) {
    const r = 5.6;
    const gap = 12.5;
    final fill = Paint()..color = Toy.tomato;
    final outline = Paint()
      ..color = Toy.tomato
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3
      ..strokeJoin = StrokeJoin.round;
    for (var i = 0; i < 3; i++) {
      final c = Offset(top.dx + (i - 1) * gap, top.dy + 11);
      final path = starPath(c, i < earned ? r : r - 0.6);
      canvas.drawPath(path, i < earned ? fill : outline);
    }
  }

  void _label(Canvas canvas, _TileText kind, int id, Offset centre) {
    final style = switch (kind) {
      _TileText.done => Toy.ui(16, weight: FontWeight.w800),
      _TileText.locked => Toy.ui(
        15,
        weight: FontWeight.w700,
        color: _lockedText,
      ),
      _TileText.current => Toy.display(26, color: Colors.white),
    };
    final painter = _text('${kind.name}$id', '$id', style);
    painter.paint(
      canvas,
      centre - Offset(painter.width / 2, painter.height / 2),
    );
  }

  /// A band's name, set beside its first level on whichever side has room.
  void _paintBandMarker(
    Canvas canvas,
    Size size,
    JourneyBand band,
    int world,
    Offset centre,
  ) {
    final onLeft = centre.dx > size.width / 2;
    final room = onLeft
        ? centre.dx - kJourneyTile / 2 - 14 - 8
        : size.width - centre.dx - kJourneyTile / 2 - 14 - 8;
    if (room < 60) return;

    final caps = _text(
      'bandc$world${band.reached}',
      'WORLD $world · ${band.length}',
      Toy.caps(size: 9.5, color: band.reached ? Toy.blue : Toy.inkDim),
    );
    final name = _text(
      'bandn$world${band.reached}',
      band.name.toUpperCase(),
      Toy.ui(
        12.5,
        weight: FontWeight.w800,
        color: band.reached ? Toy.ink : Toy.inkDim,
      ),
    );
    final textWidth = math.max(caps.width, name.width);
    final scale = textWidth + 20 > room ? room / (textWidth + 20) : 1.0;
    final w = (textWidth + 20) * scale;
    final h = (caps.height + name.height + 10) * scale;
    final left = onLeft
        ? centre.dx - kJourneyTile / 2 - 14 - w
        : centre.dx + kJourneyTile / 2 + 14;
    final box = Rect.fromLTWH(left, centre.dy - h / 2, w, h);
    final rrect = RRect.fromRectAndRadius(box, const Radius.circular(10));

    if (band.reached) {
      canvas.drawRRect(
        rrect.shift(const Offset(0, 3)),
        Paint()..color = Toy.ink,
      );
    }
    canvas
      ..drawRRect(rrect, Paint()..color = band.reached ? Toy.card : Toy.cream)
      ..drawRRect(
        rrect.deflate(1),
        Paint()
          ..color = band.reached ? Toy.ink : _lockedStroke
          ..style = PaintingStyle.stroke
          ..strokeWidth = Toy.strokeThin,
      );

    canvas
      ..save()
      ..translate(box.left, box.top)
      ..scale(scale);
    caps.paint(canvas, const Offset(10, 5));
    name.paint(canvas, Offset(10, 5 + caps.height));
    canvas.restore();
  }

  /// Laid-out labels, reused across frames. The pulse repaints every frame
  /// and re-laying out a dozen TextPainters each time is avoidable work.
  static final Map<String, TextPainter> _texts = {};

  static TextPainter _text(String key, String text, TextStyle style) {
    final cached = _texts[key];
    if (cached != null) return cached;
    if (_texts.length > 600) _texts.clear();
    return _texts[key] = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
  }

  /// The dashed outline of a locked tile, at the origin. Built once: walking
  /// path metrics every frame for every locked tile would be wasted work.
  static final Path _dashedTile = () {
    final outline = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(
            0,
            0,
            kJourneyTile,
            kJourneyTile,
          ).deflate(Toy.stroke / 2),
          const Radius.circular(14),
        ),
      );
    final dashed = Path();
    for (final metric in outline.computeMetrics()) {
      const dash = 6.0;
      const gap = 4.5;
      for (var d = 0.0; d < metric.length; d += dash + gap) {
        dashed.addPath(
          metric.extractPath(d, math.min(d + dash, metric.length)),
          Offset.zero,
        );
      }
    }
    return dashed;
  }();

  /// The tile a level occupies, in the path's coordinate space.
  static Rect tileRect(
    int id,
    int count,
    double width, {
    bool current = false,
  }) => Rect.fromCenter(
    center: journeyPosition(id, count, width),
    width: current ? kJourneyTileCurrent : kJourneyTile,
    height: current ? kJourneyTileCurrent : kJourneyTile,
  );

  /// Which level a tap landed on, or null.
  ///
  /// Generous: a 60px square around each tile, a little bigger than the tile
  /// itself, because the alternative to a forgiving hit test is a player
  /// tapping three times.
  static int? levelAt(Offset point, int count, double width) {
    for (var id = 1; id <= count; id++) {
      final d = journeyPosition(id, count, width) - point;
      if (d.dx.abs() <= 32 && d.dy.abs() <= 32) return id;
    }
    return null;
  }

  @override
  bool shouldRepaint(JourneyPainter old) =>
      old.pulse != pulse ||
      old.levels != levels ||
      old.bands != bands ||
      old.visibleTop != visibleTop ||
      old.visibleBottom != visibleBottom;
}

enum _TileText { done, locked, current }

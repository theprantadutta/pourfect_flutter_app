/// Deterministic board layout.
///
/// Tube and ball positions are COMPUTED, not measured. The pour animation needs
/// exact source and destination points every frame, and the usual approach —
/// GlobalKeys plus `findRenderObject` — only yields positions after a layout
/// pass, so the first frame of a pour would be wrong and every frame would cost
/// a tree walk. Computing the layout once per size change is both correct and
/// cheaper.
library;

import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// Where every tube and every ball slot sits, for one board size.
@immutable
class BoardGeometry {
  final int tubeCount;
  final int capacity;

  /// Ball diameter.
  final double ballSize;

  /// Padding between the balls and the tube wall.
  final double tubePadding;

  /// Tube bounding boxes, indexed by tube.
  final List<Rect> tubeRects;

  /// Total space the board occupies.
  final Size size;

  const BoardGeometry._({
    required this.tubeCount,
    required this.capacity,
    required this.ballSize,
    required this.tubePadding,
    required this.tubeRects,
    required this.size,
  });

  /// Lays out [tubeCount] tubes to fill [available] as generously as possible.
  ///
  /// The board is the hero of the screen, so the ball size scales UP to use the
  /// room rather than sitting at a fixed size with margins — but it is clamped,
  /// because a 4-tube tutorial board with 90px balls looks like a mistake.
  factory BoardGeometry.fit({
    required Size available,
    required int tubeCount,
    required int capacity,
    double minBallSize = 22,
    double maxBallSize = 58,
    double gap = 14,
    double rowGap = 28,
  }) {
    // Up to six tubes read comfortably in one row on a phone. Past that, two
    // rows keep the balls big enough to tell apart, which matters more than
    // keeping the board on one line.
    final rows = tubeCount <= 6 ? 1 : 2;
    final perRow = (tubeCount / rows).ceil();

    // Solve for the ball size that fits both axes, then clamp.
    final widthBudget = available.width - gap * (perRow - 1);
    final ballFromWidth = widthBudget / perRow - 2 * _paddingFor(1);

    // Reserve room above the board for the selection lift and the pour arc.
    final heightBudget =
        available.height - rowGap * (rows - 1) - _liftReserve(rows);
    final ballFromHeight =
        (heightBudget / rows - 2 * _paddingFor(1)) / capacity;

    final ballSize = math
        .min(ballFromWidth, ballFromHeight)
        .clamp(minBallSize, maxBallSize)
        .toDouble();

    final padding = _paddingFor(ballSize);
    final tubeWidth = ballSize + padding * 2;
    final tubeHeight = ballSize * capacity + padding * 2;

    final boardHeight = rows * tubeHeight + (rows - 1) * rowGap;

    // Centre the board in the space it was given, both axes. Without this the
    // tubes pin to the top of their slot and the screen reads as a header with
    // a large empty hole under it — the board is supposed to be the hero, so it
    // sits in the middle of the room it has.
    //
    // Balls need headroom ABOVE the top row for the selection lift and the
    // pour arc, so the centring is biased down slightly rather than being
    // exact; a lifted ball must never clip the HUD.
    final liftHeadroom = ballSize * 0.85;
    final verticalSlack = available.height - boardHeight;
    final top = verticalSlack <= 0
        ? 0.0
        : math.max(liftHeadroom, verticalSlack / 2);

    final rects = <Rect>[];
    for (var row = 0; row < rows; row++) {
      final first = row * perRow;
      final count = math.min(perRow, tubeCount - first);
      if (count <= 0) break;

      final rowWidth = count * tubeWidth + (count - 1) * gap;
      final left = (available.width - rowWidth) / 2;
      final rowTop = top + row * (tubeHeight + rowGap);

      for (var i = 0; i < count; i++) {
        rects.add(
          Rect.fromLTWH(
            left + i * (tubeWidth + gap),
            rowTop,
            tubeWidth,
            tubeHeight,
          ),
        );
      }
    }

    return BoardGeometry._(
      tubeCount: tubeCount,
      capacity: capacity,
      ballSize: ballSize,
      tubePadding: padding,
      tubeRects: rects,
      size: Size(available.width, boardHeight),
    );
  }

  static double _paddingFor(double ballSize) => math.max(5, ballSize * 0.16);

  /// Vertical space kept clear above the board so a lifted or in-flight ball
  /// never clips the HUD.
  static double _liftReserve(int rows) => 56.0 * rows;

  /// Centre of the ball occupying [slot] (0 = bottom) in [tube].
  ///
  /// Defined for slots beyond the tube's current fill too, so the animation can
  /// aim at the slot a ball is about to occupy.
  Offset ballCentre(int tube, int slot) {
    final rect = tubeRects[tube];
    return Offset(
      rect.center.dx,
      rect.bottom - tubePadding - ballSize / 2 - slot * ballSize,
    );
  }

  /// Where a selected ball hovers, just clear of the rim.
  ///
  /// Also the point a pour departs from and arrives over, so a ball never
  /// appears to pass through a tube wall.
  Offset liftPoint(int tube) {
    final rect = tubeRects[tube];
    return Offset(rect.center.dx, rect.top - ballSize * 0.58);
  }

  /// The tube containing [point], or null.
  int? tubeAt(Offset point) {
    for (var i = 0; i < tubeRects.length; i++) {
      // Inflated so the tap target stays comfortable even when the board
      // scales down; a miss on a 22px tube is a genuinely annoying failure.
      if (tubeRects[i].inflate(6).contains(point)) return i;
    }
    return null;
  }

  @override
  bool operator ==(Object other) =>
      other is BoardGeometry &&
      other.tubeCount == tubeCount &&
      other.capacity == capacity &&
      other.ballSize == ballSize &&
      other.size == size;

  @override
  int get hashCode => Object.hash(tubeCount, capacity, ballSize, size);
}

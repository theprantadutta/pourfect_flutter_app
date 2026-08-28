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
    //
    // But the row count cannot simply be ASSUMED: on a narrow screen a wide row
    // can demand a ball below `minBallSize`, and clamping the ball back up then
    // makes the row wider than the screen. So the desired split is checked
    // against what actually fits and rows are added until it does.
    final minTubeWidth = minBallSize + 2 * _paddingFor(minBallSize);
    final maxPerRow = ((available.width + gap) / (minTubeWidth + gap))
        .floor()
        .clamp(1, tubeCount);

    var rows = tubeCount <= 6 ? 1 : 2;
    while ((tubeCount / rows).ceil() > maxPerRow && rows < 4) {
      rows++;
    }
    final perRow = (tubeCount / rows).ceil();

    // Solve for the ball size that fits both axes, then clamp.
    //
    // Padding is itself a function of ball size (`_paddingFor`), so solving
    // with a FIXED padding guess under-computes the tube width and the row
    // overflows — which is exactly what clipped the sixth tube on level 150.
    // Both branches of that max() are solved and the smaller ball wins.
    final widthBudget = available.width - gap * (perRow - 1);
    final slot = widthBudget / perRow;
    final ballFromWidth = math.min(
      slot - 2 * _minPadding, // padding pinned at its floor
      slot / (1 + 2 * _paddingRatio), // padding scaling with the ball
    );

    // Reserve room above the board for the selection lift and the pour arc.
    final heightBudget =
        available.height - rowGap * (rows - 1) - _liftReserve(rows);
    final rowHeight = heightBudget / rows;
    final ballFromHeight = math.min(
      (rowHeight - 2 * _minPadding) / capacity,
      rowHeight / (capacity + 2 * _paddingRatio),
    );

    // Fitting WINS over the minimum. A ball a little under the comfortable
    // floor is survivable; a tube clipped off the screen edge is not.
    final fits = math.min(ballFromWidth, ballFromHeight);
    final ballSize = math
        .min(math.max(fits, math.min(minBallSize, fits)), maxBallSize)
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
    final liftHeadroom = _liftHeadroom(ballSize);
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

  static const double _minPadding = 5;
  static const double _paddingRatio = 0.16;

  static double _paddingFor(double ballSize) =>
      math.max(_minPadding, ballSize * _paddingRatio);

  /// Vertical space kept clear above the board so a lifted or in-flight ball
  /// never clips the HUD.
  static double _liftReserve(int rows) => 56.0 * rows;

  /// Clearance above the top row for a held run.
  ///
  /// `liftPoint` sits 0.58 ball-heights above the rim and the ball is drawn
  /// from its centre, so the topmost held ball reaches 1.08 ball-heights above
  /// the tube. Anything less than that here and a lifted run clips the HUD.
  static double _liftHeadroom(double ballSize) => ballSize * 1.12;

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

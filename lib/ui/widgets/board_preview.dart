/// A still render of a real board, for showing what a level looks like.
///
/// Not an illustration and not an icon — the actual tubes and balls of the
/// actual level. That matters on the home screen: a first-time player has
/// never seen this game, and a preview built from the real board answers
/// "what is this?" before they tap anything.
///
/// Deliberately dumb. No animation, no interaction, no selection state — the
/// board it draws is a value, so this is a pure function of that value. The
/// playable board lives in `board_view.dart` and carries all the motion.
///
/// **One row, always.** The preview sits inside the home hero card, whose
/// height is budgeted so the hub fits a 360×780 screen without scrolling. A
/// board that wrapped onto a second row would push PLAY and the dock off the
/// bottom, so a wide board shrinks its balls instead of growing a row.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../engine/board.dart';
import '../theme/toy.dart';
import 'ball.dart';

class BoardPreview extends StatelessWidget {
  final Board board;

  /// The ball diameter when there is room for it. A board too wide for the
  /// available width is drawn with smaller balls rather than wrapped.
  final double ballSize;

  /// Whether balls carry their larger, higher-contrast glyphs.
  final bool boldGlyphs;

  const BoardPreview({
    super.key,
    required this.board,
    this.ballSize = 22,
    this.boldGlyphs = false,
  });

  // Proportions off the mockup's 22px ball: a 3px inner pad, 2px between
  // balls and 8px between tubes. Expressed as fractions of the ball so a
  // shrunken board keeps the same shape instead of turning into all stroke.
  static const _pad = 3 / 22;
  static const _between = 2 / 22;
  static const _spacing = 8 / 22;
  static const _stroke = Toy.strokeThin;

  /// Gap between two rows of tubes, as a fraction of the ball.
  static const _rowGap = 12 / 22;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final n = board.tubeCount;
      if (n == 0) return const SizedBox.shrink();
      final cap = board.capacity;

      // The ball that fits [perRow] tubes across the width.
      double byWidth(int perRow) => !constraints.hasBoundedWidth
          ? double.infinity
          : (constraints.maxWidth - perRow * _stroke * 2) /
                (perRow * (1 + 2 * _pad) + (perRow - 1) * _spacing);

      // The ball that fits [rows] rows of tubes into the height, when the
      // parent gives the preview a height to fill (the hub on a tall phone).
      double byHeight(int rows) => !constraints.hasBoundedHeight
          ? double.infinity
          : (constraints.maxHeight - rows * _stroke * 2) /
                (rows * (cap + (cap - 1) * _between + 2 * _pad) +
                    (rows - 1) * _rowGap);

      // One row, or two when the board is wide and there is height to spare:
      // a nine-tube board squeezed into one row gets 19px balls, and in two
      // rows it can use the room a tall phone leaves under it.
      var rows = 1;
      var ball = math.min(byWidth(n), byHeight(1));
      if (n >= 6 && constraints.hasBoundedHeight) {
        final two = math.min(byWidth((n / 2).ceil()), byHeight(2));
        if (two > ball + 2) {
          rows = 2;
          ball = two;
        }
      }
      ball = math.max(math.min(ballSize, ball).floorToDouble(), 8);

      final perRow = (n / rows).ceil();
      Widget row(int from) => Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = from; i < math.min(from + perRow, n); i++) ...[
            if (i > from) SizedBox(width: ball * _spacing),
            _Tube(tube: board.tubes[i], ball: ball, bold: boldGlyphs),
          ],
        ],
      );

      if (rows == 1) return row(0);
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          row(0),
          SizedBox(height: ball * _rowGap),
          row(perRow),
        ],
      );
    },
  );
}

class _Tube extends StatelessWidget {
  final Tube tube;
  final double ball;
  final bool bold;

  const _Tube({required this.tube, required this.ball, required this.bold});

  @override
  Widget build(BuildContext context) {
    final pad = ball * BoardPreview._pad;
    final between = ball * BoardPreview._between;
    const stroke = BoardPreview._stroke;
    final capacity = tube.capacity;

    return Container(
      width: ball + pad * 2 + stroke * 2,
      height: ball * capacity + between * (capacity - 1) + pad * 2 + stroke * 2,
      padding: EdgeInsets.all(pad),
      decoration: BoxDecoration(
        color: Toy.tubePreview,
        // Rounder at the base than the mouth, like a real vessel.
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(ball * 8 / 22),
          bottom: Radius.circular(ball * 16 / 22),
        ),
        border: Border.all(color: Toy.ink, width: stroke),
      ),
      child: Column(
        // Balls rest on the bottom, so a part-filled tube reads as part-filled
        // rather than floating.
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          for (final (i, colorId) in tube.balls.reversed.indexed) ...[
            if (i > 0) SizedBox(height: between),
            Ball(colorId: colorId, size: ball, boldGlyph: bold),
          ],
        ],
      ),
    );
  }
}

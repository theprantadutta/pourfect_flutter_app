/// A still render of a real board, for showing what a level looks like.
///
/// Not an illustration and not an icon — the actual tubes and balls of the
/// actual level, at whatever scale it is given. That matters on the home
/// screen: a first-time player has never seen this game, and a preview built
/// from the real board answers "what is this?" before they tap anything.
///
/// Deliberately dumb. No animation, no interaction, no selection state — the
/// board it draws is a value, so this is a pure function of that value. The
/// playable board lives in `board_view.dart` and carries all the motion.
library;

import 'package:flutter/material.dart';

import '../../engine/board.dart';
import '../theme/tokens.dart';
import 'ball.dart';

class BoardPreview extends StatelessWidget {
  final Board board;

  /// Ball diameter. Tube widths and the whole layout follow from it.
  final double ballSize;

  /// Whether balls carry their larger, higher-contrast glyphs.
  final bool boldGlyphs;

  const BoardPreview({
    super.key,
    required this.board,
    this.ballSize = 26,
    this.boldGlyphs = false,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = PourfectTokens.of(context);

    final gap = ballSize * 0.22;
    final tubePadding = ballSize * 0.12;
    final tubeWidth = ballSize + tubePadding * 2;
    final tubeHeight = ballSize * board.capacity + tubePadding * 2;

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: gap,
      runSpacing: gap,
      children: [
        for (final tube in board.tubes)
          _Tube(
            tube: tube,
            tokens: tokens,
            width: tubeWidth,
            height: tubeHeight,
            padding: tubePadding,
            ballSize: ballSize,
            boldGlyphs: boldGlyphs,
          ),
      ],
    );
  }
}

class _Tube extends StatelessWidget {
  final Tube tube;
  final PourfectTokens tokens;
  final double width;
  final double height;
  final double padding;
  final double ballSize;
  final bool boldGlyphs;

  const _Tube({
    required this.tube,
    required this.tokens,
    required this.width,
    required this.height,
    required this.padding,
    required this.ballSize,
    required this.boldGlyphs,
  });

  @override
  Widget build(BuildContext context) => Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      color: tokens.tubeGlass,
      // Rounder at the base than the mouth, like a real vessel — the same
      // proportion the playable board uses, so the preview reads as the same
      // object rather than a lookalike.
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(ballSize * 0.16),
        bottom: Radius.circular(ballSize * 0.42),
      ),
      border: Border.all(color: tokens.hairline),
    ),
    padding: EdgeInsets.all(padding),
    child: Column(
      // Balls rest on the bottom, so a part-filled tube reads as part-filled
      // rather than floating.
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        for (final colorId in tube.balls.reversed)
          Ball(colorId: colorId, size: ballSize, boldGlyph: boldGlyphs),
      ],
    ),
  );
}

/// The home screen's answer to "what is this, and what do I do?"
///
/// The old level select opened on an index of 150 levels, of which one was
/// playable and the rest were near-invisible locked outlines. A first-time
/// player saw a wall of things they could not do, no verb anywhere, and a
/// scoreboard of zeros — and had to tap a tube-shaped outline on faith to
/// discover what the game even was.
///
/// This shows the actual next board with one verb under it. The game's own
/// object does the explaining, which no amount of label copy can. It is the
/// one white hero card on the hub, and PLAY is the only tomato on the screen,
/// so there is never a question about which button is the game.
library;

import 'dart:async';

import 'package:flutter/material.dart';

import '../../engine/board.dart';
import '../theme/toy.dart';
import '../transitions.dart';
import 'board_preview.dart';
import 'toy_kit.dart';

class NextLevelHero extends StatelessWidget {
  final int levelId;
  final Board board;

  /// The proven optimum, shown as "par".
  final int par;

  /// 1-based campaign band, which the player sees as a world.
  final int world;
  final String bandName;

  final bool boldGlyphs;

  /// Called with PLAY's global rect, so the level can grow out of the button.
  final void Function(Rect? origin) onPlay;

  /// Let the board grow into the height the card is given — as far as the
  /// board can actually use it — instead of sitting at its compact size. The
  /// card still sizes to what it draws, so height a wide board cannot use is
  /// left to the hub to spread out rather than turning into white card.
  final bool expand;

  const NextLevelHero({
    super.key,
    required this.levelId,
    required this.board,
    required this.par,
    required this.world,
    required this.bandName,
    required this.boldGlyphs,
    required this.onPlay,
    this.expand = false,
  });

  @override
  Widget build(BuildContext context) {
    return ToyBox(
      radius: Toy.rHero,
      shadow: 5,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Level $levelId', style: Toy.display(28)),
                    const SizedBox(height: 2),
                    Text(
                      bandName.isEmpty
                          ? 'World $world'
                          : 'World $world · $bandName',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Toy.ui(13, color: Toy.inkMuted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              ToyChip.text('par $par'),
            ],
          ),
          const SizedBox(height: 14),
          if (expand)
            Flexible(
              child: Center(
                heightFactor: 1,
                child: BoardPreview(
                  board: board,
                  boldGlyphs: boldGlyphs,
                  // Grows with the card, to about the playable board's size.
                  ballSize: 36,
                ),
              ),
            )
          else
            Center(
              child: BoardPreview(board: board, boldGlyphs: boldGlyphs),
            ),
          const SizedBox(height: 14),
          Builder(
            builder: (context) => ToyButton(
              label: 'PLAY',
              semanticLabel: 'Play level $levelId',
              icon: const _NudgingPlay(),
              onPressed: () => onPlay(globalRectOf(context)),
            ),
          ),
        ],
      ),
    );
  }
}

/// PLAY's white ▶, which leans toward the word every few seconds.
///
/// A still screen with one moving mark tells the eye where to go without an
/// arrow or a coach mark. A Timer rather than a repeating controller, so the
/// arrow is idle — no ticker, no frames — for the 3.5s it is not moving.
class _NudgingPlay extends StatefulWidget {
  const _NudgingPlay();

  @override
  State<_NudgingPlay> createState() => _NudgingPlayState();
}

class _NudgingPlayState extends State<_NudgingPlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _nudge = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 450),
  );
  Timer? _every;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _every?.cancel();
    _every = null;
    if (Toy.calm(context)) return;
    // Three nudges and it rests. It has made its point by then, and a hub left
    // open on a table should not redraw every four seconds until the battery
    // dies.
    var left = 3;
    _every = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (!mounted) return;
      _nudge.forward(from: 0);
      if (--left == 0) timer.cancel();
    });
  }

  @override
  void dispose() {
    _every?.cancel();
    _nudge.dispose();
    super.dispose();
  }

  // Its own layer: the nudge runs every four seconds for as long as the hub is
  // up, and without a boundary each of its frames repainted the whole screen.
  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: AnimatedBuilder(
      animation: _nudge,
      builder: (context, child) {
        // Out and back in one breath: a sine hump, 5px at the crest.
        final t = _nudge.value;
        final dx =
            5 *
            (t < 0.5
                ? Curves.easeOut.transform(t * 2)
                : Curves.easeIn.transform((1 - t) * 2));
        return Transform.translate(offset: Offset(dx, 0), child: child);
      },
      child: const CustomPaint(size: Size(14, 16), painter: _TrianglePainter()),
    ),
  );
}

class _TrianglePainter extends CustomPainter {
  const _TrianglePainter();

  @override
  void paint(Canvas canvas, Size size) => canvas.drawPath(
    Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, size.height / 2)
      ..lineTo(0, size.height)
      ..close(),
    Paint()..color = Colors.white,
  );

  @override
  bool shouldRepaint(_TrianglePainter old) => false;
}

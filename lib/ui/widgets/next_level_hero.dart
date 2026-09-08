/// The home screen's answer to "what is this, and what do I do?"
///
/// The old level select opened on an index of 150 levels, of which one was
/// playable and the rest were near-invisible locked outlines. A first-time
/// player saw a wall of things they could not do, no verb anywhere, and a
/// scoreboard of zeros — and had to tap a tube-shaped outline on faith to
/// discover what the game even was.
///
/// This shows the actual next board at hero scale with one verb under it. The
/// game's own object does the explaining, which no amount of label copy can.
library;

import 'package:flutter/material.dart';

import '../../engine/board.dart';
import '../theme/tokens.dart';
import '../theme/typography.dart';
import '../widgets/board_preview.dart';
import '../widgets/pressable.dart';

class NextLevelHero extends StatelessWidget {
  final int levelId;
  final Board board;

  /// True until the player has cleared anything.
  final bool isFirstEver;

  /// Stars already earned on this level, if it has been played before.
  final int? earnedStars;

  final bool boldGlyphs;
  final void Function(Rect? origin) onPlay;

  const NextLevelHero({
    super.key,
    required this.levelId,
    required this.board,
    required this.isFirstEver,
    required this.earnedStars,
    required this.boldGlyphs,
    required this.onPlay,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = PourfectTokens.of(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        tokens.space4,
        tokens.space3,
        tokens.space4,
        tokens.space4,
      ),
      child: Column(
        children: [
          _preview(tokens),
          SizedBox(height: tokens.space4),
          Text(
            'Level $levelId',
            style: numericStyle(tokens, size: 15, color: tokens.textMuted),
          ),
          SizedBox(height: tokens.space2),

          // The one sentence that says what the game is, and only while the
          // player still needs it. Repeating it forever would be nagging.
          if (isFirstEver) ...[
            SizedBox(
              width: 260,
              child: Text(
                'Pour balls between tubes until every colour has a tube of '
                'its own.',
                textAlign: TextAlign.center,
                style: bodyStyle(tokens).copyWith(fontSize: 14),
              ),
            ),
            SizedBox(height: tokens.space4),
          ] else
            SizedBox(height: tokens.space2),

          _playButton(tokens),
        ],
      ),
    );
  }

  Widget _preview(PourfectTokens tokens) => Builder(
    builder: (context) => Container(
      padding: EdgeInsets.symmetric(
        horizontal: tokens.space3,
        vertical: tokens.space4,
      ),
      decoration: BoxDecoration(
        color: tokens.surfaceRaised,
        borderRadius: BorderRadius.circular(tokens.panelRadius),
        border: Border.all(color: tokens.hairline),
      ),
      child: BoardPreview(
        board: board,
        // Sized so a 3-colour tutorial board and an 8-colour board both sit
        // comfortably without the widest case forcing a tiny ball.
        ballSize: board.tubeCount <= 6 ? 26 : 20,
        boldGlyphs: boldGlyphs,
      ),
    ),
  );

  Widget _playButton(PourfectTokens tokens) => Builder(
    builder: (context) => Pressable(
      onPressed: () {
        final box = context.findRenderObject() as RenderBox?;
        final origin = box == null
            ? null
            : box.localToGlobal(Offset.zero) & box.size;
        onPlay(origin);
      },
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 320),
        padding: const EdgeInsets.symmetric(vertical: 17),
        decoration: BoxDecoration(
          color: tokens.accent.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(tokens.panelRadius),
          border: Border.all(color: tokens.accent.withValues(alpha: 0.5)),
        ),
        child: Center(
          child: Text(
            // The verb changes with what the player is actually doing.
            // "Play" for somebody who has never started; "Continue" once they
            // are mid-campaign; "Replay" when the next thing is one they have
            // already cleared and are coming back to.
            isFirstEver
                ? 'Play'
                : (earnedStars != null ? 'Replay level $levelId' : 'Continue'),
            style: actionStyle(
              tokens,
              color: tokens.accent,
            ).copyWith(fontSize: 17),
          ),
        ),
      ),
    ),
  );
}

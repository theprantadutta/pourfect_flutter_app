/// The completion moment.
///
/// This is where the game earns its "satisfying" pitch, so the sequence is
/// deliberate: the finished tubes settle and glow, a single chime plays, the
/// board fades, and only then does this card arrive. Quiet and confident.
///
/// Explicitly NOT: confetti, a starburst, a coin shower, three bouncing stars
/// with a rising jingle. That vocabulary belongs to a different game, and it
/// would undo the calm the previous ninety seconds built.
library;

import 'package:flutter/material.dart';

import '../theme/tokens.dart';
import '../theme/typography.dart';

class LevelCompleteCard extends StatelessWidget {
  final int levelId;
  final int stars;
  final int movesUsed;
  final int minMoves;
  final VoidCallback? onNext;
  final VoidCallback onReplay;

  const LevelCompleteCard({
    super.key,
    required this.levelId,
    required this.stars,
    required this.movesUsed,
    required this.minMoves,
    required this.onNext,
    required this.onReplay,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = PourfectTokens.of(context);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Container(
          margin: EdgeInsets.all(tokens.space4),
          padding: EdgeInsets.symmetric(
            horizontal: tokens.space4,
            vertical: tokens.space5,
          ),
          decoration: BoxDecoration(
            color: tokens.surfaceRaised,
            borderRadius: BorderRadius.circular(tokens.panelRadius),
            border: Border.all(color: tokens.hairline),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('LEVEL $levelId', style: labelStyle(tokens)),
              SizedBox(height: tokens.space2),
              Text(_headline(stars), style: titleStyle(tokens)),
              SizedBox(height: tokens.space4),

              _StarRow(earned: stars),
              SizedBox(height: tokens.space4),

              // The one number worth showing, against the proven optimum.
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '$movesUsed',
                    style: numericStyle(
                      tokens,
                      size: 34,
                      color: tokens.textPrimary,
                    ),
                  ),
                  Text(' moves', style: bodyStyle(tokens)),
                ],
              ),
              SizedBox(height: tokens.space1),
              Text(
                movesUsed <= minMoves
                    ? 'A perfect solve.'
                    : 'Best possible is $minMoves.',
                style: bodyStyle(tokens).copyWith(fontSize: 13),
              ),

              SizedBox(height: tokens.space5),
              _PrimaryAction(
                label: onNext == null ? 'That’s all for now' : 'Next level',
                onPressed: onNext,
              ),
              SizedBox(height: tokens.space2),
              _QuietAction(label: 'Play again', onPressed: onReplay),
            ],
          ),
        ),
      ),
    );
  }

  /// Warm, never gushing. Three stars is worth a word; one star still finished
  /// the level and should not be told off for it.
  String _headline(int stars) => switch (stars) {
    3 => 'Beautifully done',
    2 => 'Nicely solved',
    _ => 'Solved',
  };
}

/// Three pips that fill as stars are earned.
///
/// Diamonds rather than five-pointed stars: the tier is just as readable and it
/// stays inside the palette's visual language instead of importing the arcade
/// one.
class _StarRow extends StatelessWidget {
  final int earned;

  const _StarRow({required this.earned});

  @override
  Widget build(BuildContext context) {
    final tokens = PourfectTokens.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < 3; i++)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: tokens.space2),
            child: TweenAnimationBuilder<double>(
              // Staggered so they arrive one after another — a single beat
              // each, not a fanfare.
              duration: Duration(milliseconds: 320 + i * 130),
              curve: Curves.easeOutBack,
              tween: Tween(begin: 0, end: i < earned ? 1 : 0),
              builder: (context, t, _) => Transform.scale(
                scale: 0.7 + 0.3 * t,
                child: Transform.rotate(
                  angle: 0.7854,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: Color.lerp(
                        Colors.transparent,
                        tokens.accentWarm,
                        t,
                      ),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: i < earned
                            ? tokens.accentWarm
                            : tokens.hairlineStrong,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _PrimaryAction extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;

  const _PrimaryAction({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final tokens = PourfectTokens.of(context);

    return SizedBox(
      width: double.infinity,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          backgroundColor: tokens.accent.withValues(alpha: 0.12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: tokens.accent.withValues(alpha: 0.4)),
          ),
        ),
        child: Text(label, style: actionStyle(tokens, color: tokens.accent)),
      ),
    );
  }
}

class _QuietAction extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _QuietAction({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final tokens = PourfectTokens.of(context);

    return SizedBox(
      width: double.infinity,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
        child: Text(label, style: actionStyle(tokens, color: tokens.textMuted)),
      ),
    );
  }
}

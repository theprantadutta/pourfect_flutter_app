/// The HUD, deliberately recessed.
///
/// The board is the hero; chrome should be legible and then disappear. No
/// filled buttons, no icon badges, no coin counter shouting at the player —
/// just muted labels, monospace numbers, and hairline-outlined actions that
/// respond crisply when pressed.
library;

import 'package:flutter/material.dart';

import '../theme/tokens.dart';
import '../theme/typography.dart';
import 'pressable.dart';

/// Level identity and move count.
class BoardHud extends StatelessWidget {
  final int levelId;
  final String bandName;
  final int movesUsed;
  final int minMoves;

  /// Back to the level map.
  final VoidCallback onExit;

  const BoardHud({
    super.key,
    required this.levelId,
    required this.bandName,
    required this.movesUsed,
    required this.minMoves,
    required this.onExit,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = PourfectTokens.of(context);

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: tokens.space4,
        vertical: tokens.space3,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // No boxed icon button: a hairline chevron and the level number,
          // which is all the chrome a board screen should carry.
          Pressable(
            onPressed: onExit,
            semanticLabel: 'Back to levels',
            child: Padding(
              padding: EdgeInsets.only(right: tokens.space3, bottom: 4),
              child: Icon(
                Icons.chevron_left_rounded,
                size: 26,
                color: tokens.textMuted,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('LEVEL', style: labelStyle(tokens)),
              SizedBox(height: tokens.space1),
              Text(
                levelId.toString().padLeft(2, '0'),
                style: numericStyle(
                  tokens,
                  size: 26,
                  color: tokens.textPrimary,
                ),
              ),
            ],
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(bandName.toUpperCase(), style: labelStyle(tokens)),
              SizedBox(height: tokens.space1),
              // "12 / 9" — moves taken against the proven optimum. Showing the
              // target is a nudge toward replaying for three stars, and it is
              // honest: minMoves is solver-proven, not an estimate.
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '$movesUsed',
                    style: numericStyle(
                      tokens,
                      size: 26,
                      color: movesUsed <= minMoves
                          ? tokens.textPrimary
                          : tokens.textNumeric,
                    ),
                  ),
                  Text(
                    ' / $minMoves',
                    style: numericStyle(
                      tokens,
                      size: 15,
                      weight: FontWeight.w500,
                      color: tokens.textMuted,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// A ghost action button. Press feedback comes from [Pressable], so every
/// control in the app responds identically.
class HudAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  /// Replaces the icon with a progress ring. Used for a hint being solved —
  /// the button reports the work; the board stays fully interactive.
  final bool busy;

  const HudAction({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.busy = false,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = PourfectTokens.of(context);

    return Pressable(
      onPressed: busy ? null : onPressed,
      semanticLabel: label,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: tokens.hairline),
            ),
            child: Center(
              child: busy
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(tokens.accent),
                      ),
                    )
                  : Icon(icon, size: 22, color: tokens.textNumeric),
            ),
          ),
          SizedBox(height: tokens.space2),
          Text(label.toUpperCase(), style: labelStyle(tokens)),
        ],
      ),
    );
  }
}

/// The row of board actions.
class BoardControls extends StatelessWidget {
  final VoidCallback? onUndo;
  final VoidCallback onRestart;
  final VoidCallback onHint;
  final bool hintBusy;

  const BoardControls({
    super.key,
    required this.onUndo,
    required this.onRestart,
    required this.onHint,
    required this.hintBusy,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = PourfectTokens.of(context);

    return Padding(
      padding: EdgeInsets.symmetric(vertical: tokens.space4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Undo is FREE and unlimited, and sits first because it is the thing
          // a stuck player reaches for. Gating it behind an ad would earn a
          // little and cost a lot.
          HudAction(icon: Icons.undo_rounded, label: 'Undo', onPressed: onUndo),
          SizedBox(width: tokens.space5),
          HudAction(
            icon: Icons.lightbulb_outline_rounded,
            label: 'Hint',
            onPressed: onHint,
            busy: hintBusy,
          ),
          SizedBox(width: tokens.space5),
          HudAction(
            icon: Icons.refresh_rounded,
            label: 'Restart',
            onPressed: onRestart,
          ),
        ],
      ),
    );
  }
}

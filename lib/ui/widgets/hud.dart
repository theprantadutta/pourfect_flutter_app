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

/// Level identity and move count.
class BoardHud extends StatelessWidget {
  final int levelId;
  final String bandName;
  final int movesUsed;
  final int minMoves;

  const BoardHud({
    super.key,
    required this.levelId,
    required this.bandName,
    required this.movesUsed,
    required this.minMoves,
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

/// A ghost action button with a real press state.
class HudAction extends StatefulWidget {
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
  State<HudAction> createState() => _HudActionState();
}

class _HudActionState extends State<HudAction> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final tokens = PourfectTokens.of(context);
    final enabled = widget.onPressed != null && !widget.busy;

    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.label,
      child: GestureDetector(
        onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
        onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
        onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
        onTap: enabled ? widget.onPressed : null,
        child: AnimatedScale(
          // Small, fast, and on release too — a press state that only appears
          // on tap-down feels unfinished.
          scale: _pressed ? 0.94 : 1,
          duration: const Duration(milliseconds: 90),
          curve: Curves.easeOut,
          child: AnimatedOpacity(
            opacity: enabled ? 1 : 0.32,
            duration: const Duration(milliseconds: 160),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: _pressed ? tokens.surfaceRaised : Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _pressed ? tokens.hairlineStrong : tokens.hairline,
                    ),
                  ),
                  child: Center(
                    child: widget.busy
                        ? SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(tokens.accent),
                            ),
                          )
                        : Icon(
                            widget.icon,
                            size: 22,
                            color: tokens.textNumeric,
                          ),
                  ),
                ),
                SizedBox(height: tokens.space2),
                Text(widget.label.toUpperCase(), style: labelStyle(tokens)),
              ],
            ),
          ),
        ),
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

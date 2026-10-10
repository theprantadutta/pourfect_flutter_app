/// The board's HUD and its action bar, in the Toybox style.
///
/// Top: a back square, the level title with its world underneath, and a yellow
/// moves counter. Under that, the PAR METER — how many stars this attempt is
/// still on for, how much of par it has spent, moves against par, and in words
/// what is left ("4 moves left for 3 stars"), so nobody has to do the
/// arithmetic. Its second line carries the clock against the time par and what
/// the clock is worth right now in points.
///
/// Bottom: three chunky labeled actions, Undo / Hint / Restart. Labels are not
/// optional here; an icon-only row is a row of guesses.
library;

import 'package:flutter/material.dart';

import '../../engine/level.dart' show kTwoStarMoveMultiplier;
import '../../services/audio/audio_service.dart';
import '../theme/toy.dart';
import 'toy_kit.dart';

/// Level identity, the clock, the move count and the par meter.
class BoardHud extends StatelessWidget {
  final int levelId;
  final String bandName;
  final int movesUsed;
  final int minMoves;

  /// The running clock, built by the screen so it can own its own ticker. It
  /// sits inline after the world name. Null collapses the slot.
  final Widget? clock;

  /// What the title says, when it is not a campaign level.
  ///
  /// The daily challenge is not level zero — it has no level id at all — and
  /// a board headed "Level 0" reads as a bug rather than as a challenge.
  /// [titleLabel] replaces the word "Level"; [titleValue] the number.
  final String? titleLabel;
  final String? titleValue;

  /// Back to wherever the board was opened from.
  final VoidCallback onExit;

  /// Title and subtitle ink. White on the blue daily ground.
  final Color titleColor;
  final Color? subtitleColor;

  /// The par meter row. On by default.
  final bool showParMeter;

  /// A hard level: badged beside the title, worth 1.5× points.
  final bool hard;

  const BoardHud({
    super.key,
    required this.levelId,
    required this.bandName,
    required this.movesUsed,
    required this.minMoves,
    required this.onExit,
    this.clock,
    this.titleLabel,
    this.titleValue,
    this.titleColor = Toy.ink,
    this.subtitleColor,
    this.showParMeter = true,
    this.hard = false,
  });

  bool get _meterShown => showParMeter && minMoves > 0;

  String get _title {
    final label = titleLabel == null
        ? 'Level'
        : titleLabel![0].toUpperCase() + titleLabel!.substring(1).toLowerCase();
    final value = titleValue ?? '$levelId';
    return value.isEmpty ? label : '$label $value';
  }

  @override
  Widget build(BuildContext context) {
    final sub =
        subtitleColor ??
        (titleColor == Toy.ink
            ? Toy.inkMuted
            : titleColor.withValues(alpha: 0.85));
    final subStyle = Toy.ui(13, weight: FontWeight.w600, color: sub);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              ToyBackButton(onPressed: onExit),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _title,
                            maxLines: 1,
                            style: Toy.display(30, color: titleColor),
                          ),
                          if (hard) ...[
                            const SizedBox(width: 8),
                            Semantics(
                              label:
                                  'Hard level, one and a half times the points',
                              excludeSemantics: true,
                              child: ToySticker.text(
                                'HARD ×1.5',
                                color: Toy.tomato,
                                size: 12,
                                angle: -4,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 3,
                                ),
                                radius: 8,
                                shadow: 2,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 2),
                    DefaultTextStyle(
                      style: subStyle,
                      child: IconTheme(
                        data: IconThemeData(color: sub),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                bandName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (clock != null && !_meterShown) ...[
                              if (bandName.isNotEmpty) const Text(' · '),
                              clock!,
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              _MovesCounter(moves: movesUsed),
            ],
          ),
          if (_meterShown) ...[
            const SizedBox(height: 12),
            ParMeter(movesUsed: movesUsed, minMoves: minMoves, clock: clock),
          ],
        ],
      ),
    );
  }
}

/// The yellow 44px moves square.
class _MovesCounter extends StatelessWidget {
  final int moves;

  const _MovesCounter({required this.moves});

  @override
  Widget build(BuildContext context) => Semantics(
    label: '$moves moves',
    child: ExcludeSemantics(
      child: ToyBox(
        width: 44,
        height: 44,
        radius: Toy.rButton,
        color: Toy.yellow,
        shadow: 3,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                '$moves',
                style: Toy.numbers(17, weight: FontWeight.w800),
              ),
            ),
            Text(
              'MOVES',
              style: Toy.ui(8, weight: FontWeight.w800, height: 1.1),
            ),
          ],
        ),
      ),
    ),
  );
}

/// ★★★ → bar → "5 / 14", and under it what is left and the clock.
///
/// The stars are the ones this attempt is STILL ON FOR: three until par is
/// spent, two until one and a half times par, then one. The bar is how much of
/// par has gone — mint while it is within par, yellow into the two-star band,
/// tomato past it. `minMoves` is solver-proven, so "par" here is honest.
class ParMeter extends StatelessWidget {
  final int movesUsed;
  final int minMoves;

  /// The level clock, in its detailed form, on the meter's second line.
  final Widget? clock;

  const ParMeter({
    super.key,
    required this.movesUsed,
    required this.minMoves,
    this.clock,
  });

  /// What this attempt can still earn, in words.
  static String pace({required int movesUsed, required int minMoves}) {
    final twoStarCeiling = (minMoves * kTwoStarMoveMultiplier).ceil();
    if (movesUsed < minMoves) {
      final left = minMoves - movesUsed;
      return '$left ${left == 1 ? 'move' : 'moves'} left for 3 stars';
    }
    if (movesUsed == minMoves) return 'Par spent · 2 stars from here';
    if (movesUsed < twoStarCeiling) {
      final left = twoStarCeiling - movesUsed;
      return '$left ${left == 1 ? 'move' : 'moves'} left for 2 stars';
    }
    if (movesUsed == twoStarCeiling) return '1 star from here · any finish';
    return 'Any finish earns 1 star';
  }

  @override
  Widget build(BuildContext context) {
    final twoStarCeiling = (minMoves * kTwoStarMoveMultiplier).ceil();
    final stars = movesUsed <= minMoves
        ? 3
        : movesUsed <= twoStarCeiling
        ? 2
        : 1;
    final fill = (movesUsed / minMoves).clamp(0.0, 1.0);
    final color = switch (stars) {
      3 => Toy.mint,
      2 => Toy.yellow,
      _ => Toy.tomato,
    };

    final words = pace(movesUsed: movesUsed, minMoves: minMoves);
    return Semantics(
      label: '$stars star pace, $movesUsed of par $minMoves moves. $words',
      child: ExcludeSemantics(
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 7, 12, 7),
          decoration: BoxDecoration(
            color: Toy.card,
            borderRadius: BorderRadius.circular(Toy.rButton),
            border: Border.all(color: Toy.ink, width: Toy.stroke),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  ToyStars(
                    earned: stars,
                    size: 15,
                    spacing: 0,
                    fill: Toy.tomato,
                    outlined: false,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(end: fill),
                      duration: Toy.calm(context)
                          ? Duration.zero
                          : const Duration(milliseconds: 220),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, _) => ToyProgressBar(
                        value: value,
                        fill: color,
                        track: Toy.track,
                        height: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: '$movesUsed',
                          style: Toy.numbers(
                            15,
                            weight: FontWeight.w800,
                            color: stars == 3 ? Toy.ink : Toy.tomato,
                          ),
                        ),
                        TextSpan(
                          text: ' / $minMoves',
                          style: Toy.numbers(14, weight: FontWeight.w800),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      words,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Toy.ui(
                        12,
                        weight: FontWeight.w700,
                        color: Toy.inkMuted,
                      ),
                    ),
                  ),
                  if (clock != null) ...[
                    const SizedBox(width: 8),
                    DefaultTextStyle(
                      style: Toy.ui(
                        12,
                        weight: FontWeight.w700,
                        color: Toy.inkMuted,
                      ),
                      child: clock!,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One chunky labeled action: an icon over a word, in a toy box.
///
/// Disabled reads as disabled without dropping the whole control to a ghost:
/// a paler fill, a grey stroke and grey shadow, so the bar keeps its shape.
class HudAction extends StatelessWidget {
  final Widget icon;
  final String label;
  final VoidCallback? onPressed;
  final Color color;

  /// Replaces the icon with a progress ring. Used for a hint being solved —
  /// the button reports the work; the board stays fully interactive.
  final bool busy;

  /// A small round badge on the top-right corner.
  final Widget? badge;

  /// The press sound.
  final UiCue cue;

  const HudAction({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.color = Toy.card,
    this.busy = false,
    this.badge,
    this.cue = UiCue.tap,
  });

  @override
  Widget build(BuildContext context) {
    // A hint being solved stays tappable: tapping again cancels it.
    final enabled = onPressed != null;
    const disabledInk = Color(0xFFB3ABBF);
    final ink = enabled ? Toy.ink : disabledInk;

    final box = ToyBox(
      width: double.infinity,
      height: 66,
      radius: Toy.rControl,
      color: enabled ? color : const Color(0xFFFFF8EE),
      stroke: ink,
      shadow: 4,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: busy
                ? const Padding(
                    padding: EdgeInsets.all(3),
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation(Toy.ink),
                    ),
                  )
                : IconTheme(
                    data: IconThemeData(color: ink, size: 24),
                    child: icon,
                  ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: Toy.ui(15, weight: FontWeight.w800, color: ink),
          ),
        ],
      ),
    );

    final content = Stack(
      clipBehavior: Clip.none,
      children: [
        box,
        if (badge != null) Positioned(top: -12, right: -8, child: badge!),
      ],
    );

    // Pressable would fade a disabled child on top of its own disabled look,
    // leaving a ghost; a disabled action just isn't pressable.
    if (!enabled) {
      return Semantics(
        button: true,
        enabled: false,
        label: label,
        child: content,
      );
    }
    return Pressable(
      cue: cue,
      onPressed: onPressed,
      semanticLabel: busy ? '$label, working. Tap to cancel' : label,
      child: content,
    );
  }
}

/// The row of board actions.
class BoardControls extends StatelessWidget {
  final VoidCallback? onUndo;
  final VoidCallback onRestart;
  final VoidCallback onHint;
  final bool hintBusy;

  /// Offered only while an extra tube is available. Null hides it entirely.
  final VoidCallback? onExtraTube;

  /// Hints the player can take without watching anything. Null shows no
  /// badge; zero turns the badge into a ▶, because the next hint is a video.
  /// No price is ever shown on the board.
  final int? hintBadge;

  const BoardControls({
    super.key,
    required this.onUndo,
    required this.onRestart,
    required this.onHint,
    required this.hintBusy,
    this.onExtraTube,
    this.hintBadge,
  });

  @override
  Widget build(BuildContext context) {
    final badge = hintBadge;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // APPEARS ONLY WHEN IT IS AVAILABLE, rather than sitting there
          // greyed out from move one. A disabled button is a promise with a
          // condition nobody can read, and this one's condition — par already
          // spent — would be baffling as a tooltip. Arriving exactly when
          // somebody has gone past par reads as the game noticing.
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            child: onExtraTube == null
                ? const SizedBox(width: double.infinity)
                : Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _ExtraTubeChip(onPressed: onExtraTube!),
                  ),
          ),
          Row(
            children: [
              // Undo is FREE and unlimited, and sits first because it is the
              // thing a stuck player reaches for. Gating it behind an ad would
              // earn a little and cost a lot.
              Expanded(
                child: HudAction(
                  cue: UiCue.undo,
                  icon: const ToyIcon(ToyGlyph.undo, size: 22),
                  label: 'Undo',
                  onPressed: onUndo,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: HudAction(
                  icon: const ToyIcon(ToyGlyph.hint, size: 24),
                  label: 'Hint',
                  color: Toy.yellow,
                  onPressed: onHint,
                  busy: hintBusy,
                  badge: badge == null ? null : _HintBadge(remaining: badge),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: HudAction(
                  icon: const ToyIcon(ToyGlyph.restart, size: 22),
                  label: 'Restart',
                  onPressed: onRestart,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The tomato count on the Hint button, or a ▶ once the free ones are gone.
class _HintBadge extends StatelessWidget {
  final int remaining;

  const _HintBadge({required this.remaining});

  @override
  Widget build(BuildContext context) => Container(
    width: 30,
    height: 30,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: Toy.tomato,
      shape: BoxShape.circle,
      border: Border.all(color: Toy.ink, width: Toy.stroke),
    ),
    child: remaining > 0
        ? Text(
            '$remaining',
            style: Toy.numbers(
              14,
              color: Colors.white,
              weight: FontWeight.w800,
            ),
          )
        : const Padding(
            padding: EdgeInsets.only(left: 2),
            child: ToyIcon(ToyGlyph.play, size: 11, color: Colors.white),
          ),
  );
}

/// "+ Tube ▶": the rewarded extra tube, offered once par is spent.
class _ExtraTubeChip extends StatelessWidget {
  final VoidCallback onPressed;

  const _ExtraTubeChip({required this.onPressed});

  @override
  Widget build(BuildContext context) => Center(
    child: Pressable(
      onPressed: onPressed,
      semanticLabel: 'Watch a video for an extra tube',
      depth: 2,
      child: ToyBox(
        color: Toy.lilac,
        radius: 999,
        shadow: 3,
        padding: const EdgeInsets.fromLTRB(14, 6, 12, 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('+ Tube', style: Toy.ui(14, weight: FontWeight.w800)),
            const SizedBox(width: 8),
            const ToyIcon(ToyGlyph.play, size: 12),
          ],
        ),
      ),
    ),
  );
}

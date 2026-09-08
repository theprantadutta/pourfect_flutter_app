/// The level-complete sequence. NOT a dialog.
///
/// There is no card, no scrim and no panel here on purpose. The solved tubes
/// stay visible and lit behind this — they are the trophy, and covering them
/// with a modal turns the emotional payoff of the whole loop into an alert box.
/// Every element below is positioned around the board, not over it.
///
/// Timing comes from `win_profile.dart`; this file only draws.
library;

import 'package:flutter/material.dart';

import '../format.dart';
import '../theme/tokens.dart';
import '../theme/typography.dart';
import 'pressable.dart';
import 'win_profile.dart';

class WinOverlay extends StatelessWidget {
  final WinProfile profile;
  final double elapsedMs;

  final int stars;
  final int movesUsed;
  final int minMoves;

  /// Previous personal best, if this level had been cleared before.
  final int? previousBest;
  final bool isNewBest;

  final String bandName;

  /// Levels cleared in this band BEFORE and AFTER this one, over the band size.
  final int bandClearedBefore;
  final int bandClearedAfter;
  final int bandTotal;

  /// This run's clock, the pace it was scored against, and what it earned.
  final int elapsedSeconds;
  final int parSeconds;
  final int points;

  /// The player's own previous fastest on this level, or null if there was
  /// none — a first clear, or one from before the clock shipped.
  final int? previousFastest;

  /// Null when this was the last level available.
  final VoidCallback? onNext;
  final VoidCallback onReplay;
  final VoidCallback onLevels;

  /// True once the sequence has finished or been skipped — the CTA only
  /// accepts taps from this point.
  final bool interactive;

  const WinOverlay({
    super.key,
    required this.profile,
    required this.elapsedMs,
    required this.stars,
    required this.movesUsed,
    required this.minMoves,
    required this.previousBest,
    required this.isNewBest,
    required this.elapsedSeconds,
    required this.parSeconds,
    required this.points,
    required this.previousFastest,
    required this.bandName,
    required this.bandClearedBefore,
    required this.bandClearedAfter,
    required this.bandTotal,
    required this.onNext,
    required this.onReplay,
    required this.onLevels,
    required this.interactive,
  });

  double _span(int at, int length) =>
      ((elapsedMs - at) / length).clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) {
    final tokens = PourfectTokens.of(context);

    return IgnorePointer(
      ignoring: !interactive,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: tokens.space4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Stars(profile: profile, elapsedMs: elapsedMs, earned: stars),
            SizedBox(height: tokens.space4),
            _Readout(
              opacity: _span(profile.moves.at, 120),
              progress: _span(profile.moves.at, profile.moves.length),
              movesUsed: movesUsed,
              minMoves: minMoves,
              previousBest: previousBest,
              isNewBest: isNewBest,
              bestRevealed: _span(profile.moves.at + 120, 220) > 0.5,
            ),
            SizedBox(height: tokens.space2),

            // Rides the tail of the moves beat rather than earning a beat of
            // its own. The win sequence is tuned to the millisecond and adding
            // 250ms to every three-star clear to announce a score would make
            // the payoff longer, not better.
            _ScoreLine(
              opacity: _span(profile.moves.at + 140, 220),
              elapsedSeconds: elapsedSeconds,
              parSeconds: parSeconds,
              points: points,
              previousFastest: previousFastest,
            ),
            SizedBox(height: tokens.space4),
            _BandTrack(
              opacity: _span(profile.band.at, 140),
              progress: _span(profile.band.at, profile.band.length),
              name: bandName,
              before: bandClearedBefore,
              after: bandClearedAfter,
              total: bandTotal,
            ),
            SizedBox(height: tokens.space5),
            Opacity(
              opacity: _span(profile.cta.at, profile.cta.length),
              child: _Primary(
                label: onNext == null ? 'Back to levels' : 'Next level',
                onPressed: onNext ?? onLevels,
              ),
            ),
            SizedBox(height: tokens.space3),
            Opacity(
              opacity: _span(profile.secondary.at, profile.secondary.length),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _Quiet(label: 'Replay', onPressed: onReplay),
                  SizedBox(width: tokens.space5),
                  _Quiet(label: 'Levels', onPressed: onLevels),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The clock and the score, on one line under the move count.
///
/// Deliberately smaller than the moves figure above it. Stars are the level's
/// result and the clock only moves the score, so it must not compete with the
/// number that decides how many stars were earned.
class _ScoreLine extends StatelessWidget {
  final double opacity;
  final int elapsedSeconds;
  final int parSeconds;
  final int points;
  final int? previousFastest;

  const _ScoreLine({
    required this.opacity,
    required this.elapsedSeconds,
    required this.parSeconds,
    required this.points,
    required this.previousFastest,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = PourfectTokens.of(context);

    final isNewFastest =
        previousFastest != null &&
        elapsedSeconds > 0 &&
        elapsedSeconds < previousFastest!;
    final beatPar = parSeconds > 0 && elapsedSeconds <= parSeconds;

    return Opacity(
      opacity: opacity,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                formatClock(elapsedSeconds),
                style: numericStyle(
                  tokens,
                  size: 17,
                  color: beatPar || isNewFastest
                      ? tokens.accentWarm
                      : tokens.textNumeric,
                ),
              ),
              Text(' time', style: bodyStyle(tokens).copyWith(fontSize: 13)),
              SizedBox(width: tokens.space4),
              Text(
                formatCount(points),
                style: numericStyle(
                  tokens,
                  size: 17,
                  color: tokens.textNumeric,
                ),
              ),
              Text(' points', style: bodyStyle(tokens).copyWith(fontSize: 13)),
            ],
          ),
          SizedBox(height: tokens.space1),
          Text(
            isNewFastest
                ? 'YOUR FASTEST YET'
                : formatParDelta(
                    seconds: elapsedSeconds,
                    parSeconds: parSeconds,
                  ).toUpperCase(),
            style: numericStyle(
              tokens,
              size: 11,
              color: beatPar || isNewFastest
                  ? tokens.accentWarm
                  : tokens.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

/// Three pips that land one at a time.
///
/// Diamonds rather than five-pointed stars: the tier is just as readable and it
/// stays inside the game's own visual language instead of importing the arcade
/// one.
class _Stars extends StatelessWidget {
  final WinProfile profile;
  final double elapsedMs;
  final int earned;

  const _Stars({
    required this.profile,
    required this.elapsedMs,
    required this.earned,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = PourfectTokens.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < 3; i++)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: tokens.space2),
            child: _Star(
              at: profile.starAt[i],
              length: profile.starLength,
              flourishLength: i == 2 ? profile.thirdStarFlourishLength : 0,
              elapsedMs: elapsedMs,
              earned: i < earned,
              // Unearned pips arrive quietly at the end as hairline outlines,
              // with no landing and no sound. The absence IS the feedback.
              silentAt: profile.starAt.last,
              tokens: tokens,
            ),
          ),
      ],
    );
  }
}

class _Star extends StatelessWidget {
  final int at;
  final int length;
  final int flourishLength;
  final double elapsedMs;
  final bool earned;
  final int silentAt;
  final PourfectTokens tokens;

  const _Star({
    required this.at,
    required this.length,
    required this.flourishLength,
    required this.elapsedMs,
    required this.earned,
    required this.silentAt,
    required this.tokens,
  });

  double _span(int start, int len) =>
      ((elapsedMs - start) / len).clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) {
    if (!earned) {
      return Opacity(
        opacity: 0.30 * _span(silentAt, 240),
        child: _pip(filled: false, scale: 1),
      );
    }

    final t = _span(at, length);
    // Drops in from above and overshoots — weight, not a fade.
    final settle = Curves.easeOutBack.transform(t);
    final drop = (1 - settle) * 40;

    return Opacity(
      opacity: (t * 3).clamp(0.0, 1.0),
      child: Transform.translate(
        offset: Offset(0, -drop),
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            if (flourishLength > 0) _ring(_span(at, flourishLength), 3.2),
            _ring(_span(at, (length * 0.9).round()), 1.9),
            _pip(filled: true, scale: 0.4 + 0.6 * settle),
          ],
        ),
      ),
    );
  }

  /// The flash that expands past the pip and fades.
  Widget _ring(double t, double reach) {
    if (t <= 0 || t >= 1) return const SizedBox.shrink();
    return Transform.scale(
      scale: 0.6 + reach * t,
      child: Opacity(
        opacity: (1 - t) * 0.8,
        child: Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(7),
            border: Border.all(color: tokens.accentWarm, width: 1.5),
          ),
        ),
      ),
    );
  }

  Widget _pip({required bool filled, required double scale}) => Transform.scale(
    scale: scale,
    child: Transform.rotate(
      angle: 0.7854,
      child: Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          color: filled ? tokens.accentWarm : Colors.transparent,
          borderRadius: BorderRadius.circular(5),
          border: Border.all(
            color: filled ? tokens.accentWarm : tokens.hairlineStrong,
            width: 1.5,
          ),
        ),
      ),
    ),
  );
}

/// The move count, running up.
///
/// Static digits are what make a result screen feel like a form. The count
/// decelerates so it SETTLES on the final number rather than appearing at it.
class _Readout extends StatelessWidget {
  final double opacity;
  final double progress;
  final int movesUsed;
  final int minMoves;
  final int? previousBest;
  final bool isNewBest;
  final bool bestRevealed;

  const _Readout({
    required this.opacity,
    required this.progress,
    required this.movesUsed,
    required this.minMoves,
    required this.previousBest,
    required this.isNewBest,
    required this.bestRevealed,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = PourfectTokens.of(context);
    final shown = (Curves.easeOut.transform(progress) * movesUsed).round();

    return Opacity(
      opacity: opacity,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '$shown',
                style: numericStyle(
                  tokens,
                  size: 38,
                  color: tokens.textPrimary,
                ),
              ),
              Text('  moves', style: bodyStyle(tokens)),
            ],
          ),
          SizedBox(height: tokens.space1),
          _subline(tokens),
        ],
      ),
    );
  }

  /// A personal best gets its OWN treatment: the old number is struck through
  /// as the new one passes it. A badge bolted onto the usual line would read as
  /// the same screen with different text.
  Widget _subline(PourfectTokens tokens) {
    if (isNewBest && previousBest != null) {
      if (!bestRevealed) {
        return Text(
          'BEST $previousBest',
          style: numericStyle(tokens, size: 11, color: tokens.textMuted),
        );
      }
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'NEW BEST',
            style: numericStyle(tokens, size: 11, color: tokens.accentWarm),
          ),
          Text(
            '  ·  WAS ',
            style: numericStyle(tokens, size: 11, color: tokens.textMuted),
          ),
          Text(
            '$previousBest',
            style: numericStyle(
              tokens,
              size: 11,
              color: tokens.textMuted,
            ).copyWith(decoration: TextDecoration.lineThrough),
          ),
        ],
      );
    }

    final best = previousBest;
    return Text(
      best == null
          ? (movesUsed <= minMoves ? 'PERFECT' : 'BEST POSSIBLE $minMoves')
          : 'BEST $best',
      style: numericStyle(
        tokens,
        size: 11,
        color: movesUsed <= minMoves ? tokens.accentWarm : tokens.textMuted,
      ),
    );
  }
}

/// A slim track showing the band advancing.
///
/// Finishing a level has to visibly move something, or the loop has no thread
/// running through it. This is that thread.
class _BandTrack extends StatelessWidget {
  final double opacity;
  final double progress;
  final String name;
  final int before;
  final int after;
  final int total;

  const _BandTrack({
    required this.opacity,
    required this.progress,
    required this.name,
    required this.before,
    required this.after,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = PourfectTokens.of(context);
    final eased = Curves.easeOut.transform(progress);
    final value = (before + (after - before) * eased) / total;
    final shown = progress > 0.5 ? after : before;

    return Opacity(
      opacity: opacity,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 300),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(name.toUpperCase(), style: labelStyle(tokens)),
                Text(
                  '$shown / $total',
                  style: numericStyle(
                    tokens,
                    size: 11,
                    color: tokens.textMuted,
                    weight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            SizedBox(height: tokens.space2),
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: SizedBox(
                height: 2,
                child: Stack(
                  children: [
                    Container(color: tokens.hairline),
                    FractionallySizedBox(
                      widthFactor: value.clamp(0.0, 1.0),
                      child: Container(color: tokens.accent),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The one gravitational centre. Arrives last and alone.
class _Primary extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _Primary({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final tokens = PourfectTokens.of(context);

    return Pressable(
      onPressed: onPressed,
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 340),
        padding: const EdgeInsets.symmetric(vertical: 17),
        decoration: BoxDecoration(
          color: tokens.accent.withValues(alpha: 0.13),
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: tokens.accent.withValues(alpha: 0.42)),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: actionStyle(
            tokens,
            color: tokens.accent,
          ).copyWith(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

class _Quiet extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _Quiet({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final tokens = PourfectTokens.of(context);

    return Pressable(
      onPressed: onPressed,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Text(label, style: actionStyle(tokens, color: tokens.textMuted)),
      ),
    );
  }
}

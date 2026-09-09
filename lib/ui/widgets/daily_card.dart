/// The way in to today's challenge and the leaderboards.
///
/// One quiet row under the Play hero, not a second hero. The redesign's whole
/// argument was that the board is the hero and everything else is the index;
/// a daily card competing with the Play button would put a first-time player
/// back where they started, choosing between two things they do not yet
/// understand.
///
/// **It disappears entirely when there is no backend.** A build with no server
/// configured, or a player with no network on first launch, gets the game they
/// already had rather than a row that never works.
library;

import 'package:flutter/material.dart';

import '../theme/tokens.dart';
import '../theme/typography.dart';
import 'pressable.dart';

class DailyCard extends StatelessWidget {
  /// Null while today's board is still being fetched.
  final bool? played;

  /// Stars already earned today, if it has been played.
  final int? stars;

  /// True when the board could not be had at all.
  final bool unavailable;

  final VoidCallback onOpenDaily;
  final VoidCallback onOpenLeaderboard;

  const DailyCard({
    super.key,
    required this.played,
    required this.stars,
    required this.unavailable,
    required this.onOpenDaily,
    required this.onOpenLeaderboard,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = PourfectTokens.of(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        tokens.space4,
        0,
        tokens.space4,
        tokens.space4,
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(tokens.panelRadius),
          border: Border.all(color: tokens.hairline),
        ),
        child: Column(
          children: [
            Pressable(
              onPressed: unavailable ? null : onOpenDaily,
              semanticLabel: 'Today’s challenge',
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: tokens.space4,
                  vertical: tokens.space3 + 2,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Today’s challenge',
                        style: bodyStyle(tokens)
                            .copyWith(fontSize: 14, color: tokens.textPrimary),
                      ),
                    ),
                    _status(tokens),
                  ],
                ),
              ),
            ),
            Divider(height: 1, color: tokens.hairline),
            Pressable(
              onPressed: onOpenLeaderboard,
              semanticLabel: 'Leaderboard',
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: tokens.space4,
                  vertical: tokens.space3 + 2,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Leaderboard',
                        style: bodyStyle(tokens)
                            .copyWith(fontSize: 14, color: tokens.textPrimary),
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 18,
                      color: tokens.dimText,
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

  Widget _status(PourfectTokens tokens) {
    if (unavailable) {
      return Text(
        'unavailable',
        style: bodyStyle(tokens)
            .copyWith(fontSize: 12.5, color: tokens.dimText),
      );
    }

    if (played == null) {
      // Loading. A dash rather than a spinner: this is a row on a screen the
      // player came to play from, and a spinner here would be the busiest
      // thing on it.
      return Text(
        '—',
        style: numericStyle(tokens, size: 13, color: tokens.dimText),
      );
    }

    if (!played!) {
      return Row(
        children: [
          Text(
            'not played',
            style: bodyStyle(tokens)
                .copyWith(fontSize: 12.5, color: tokens.accent),
          ),
          SizedBox(width: tokens.space1),
          Icon(Icons.chevron_right_rounded, size: 18, color: tokens.accent),
        ],
      );
    }

    return Row(
      children: [
        for (var i = 0; i < 3; i++)
          Padding(
            padding: const EdgeInsets.only(left: 3),
            child: Transform.rotate(
              angle: 0.785398,
              child: Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: i < (stars ?? 0)
                      ? tokens.accentWarm
                      : Colors.transparent,
                  border: i < (stars ?? 0)
                      ? null
                      : Border.all(color: tokens.hairlineStrong),
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ),
          ),
        SizedBox(width: tokens.space2),
        Icon(Icons.chevron_right_rounded, size: 18, color: tokens.dimText),
      ],
    );
  }
}

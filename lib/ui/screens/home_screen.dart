/// What the game opens on.
///
/// **No cards.** Nothing here is a bordered panel, a grouped row or a section
/// rule — the board's tubes sit directly on the ground, and the challenge and
/// rank are plain label-and-value pairs. Grouping is done with distance and
/// scale. Every box drawn on a game screen is a piece of app furniture, and a
/// screen made of them reads as Settings however well it is lit. That was the
/// actual diagnosis behind "this feels like an app".
///
/// The order is what a returning player cares about, in that order:
///
///  1. **Who you are**, and what you have accumulated.
///  2. **The board you are on**, at size. The game's own object is the hero
///     rather than an illustration of it.
///  3. **Continue**, the single primary action.
///  4. **What is live today** — the challenge and your rank.
///  5. **Where this is going** — a slice of the campaign path, which is the
///     whole of [JourneyScreen] seen through a window.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/account_controller.dart';
import '../../state/daily_controller.dart';
import '../../state/level_repository.dart';
import '../../state/play_history.dart';
import '../../state/progress_repository.dart';
import '../../state/providers.dart';
import '../theme/tokens.dart';
import '../theme/typography.dart';
import '../widgets/board_preview.dart';
import '../widgets/journey_path.dart';
import '../widgets/player_crest.dart';
import '../widgets/pressable.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({
    super.key,
    required this.onOpenLevel,
    required this.onOpenSettings,
    required this.onOpenStatistics,
    required this.onOpenDaily,
    required this.onOpenLeaderboard,
    required this.onOpenAccount,
    required this.onOpenJourney,
  });

  final void Function(int levelId, Rect? origin) onOpenLevel;
  final VoidCallback onOpenSettings;
  final VoidCallback onOpenStatistics;
  final VoidCallback onOpenDaily;
  final VoidCallback onOpenLeaderboard;
  final VoidCallback onOpenAccount;
  final VoidCallback onOpenJourney;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = PourfectTokens.of(context);
    final levelSet = ref.watch(campaignProvider).asData?.value;
    final progress = ref.watch(progressProvider);
    final progressOps = ref.read(progressProvider.notifier);
    ref.watch(playHistoryProvider);
    final history = ref.read(playHistoryProvider.notifier);

    final current = progressOps.furthestUnlocked;
    final board = levelSet?.byId(current)?.level.board;
    final streak = history.currentStreak();

    return Scaffold(
      backgroundColor: tokens.surface,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            tokens.space4, tokens.space3, tokens.space4, tokens.space5,
          ),
          children: [
            _TopRow(
              onOpenAccount: onOpenAccount,
              onOpenSettings: onOpenSettings,
            ),

            SizedBox(height: tokens.space4),

            // The name, with the presence a game's name should have. It sat at
            // 22px regular for a long time, which is a settings header.
            Text(
              'Pourfect',
              style: titleStyle(tokens).copyWith(
                fontSize: 44,
                fontWeight: FontWeight.w700,
                letterSpacing: -1,
                height: 1,
              ),
            ),

            SizedBox(height: tokens.space3),
            Pressable(
              onPressed: onOpenStatistics,
              semanticLabel: 'Statistics',
              child: Wrap(
                spacing: tokens.space4,
                runSpacing: tokens.space2,
                children: [
                  Figure(value: _pad(progress.length), label: 'SOLVED'),
                  Figure(
                    value: _pad(progressOps.totalStars),
                    label: 'STARS',
                    color: tokens.accentWarm,
                  ),
                  if (streak > 0)
                    Figure(
                      value: '${_pad(streak)}d',
                      label: 'STREAK',
                      color: tokens.accent,
                    ),
                ],
              ),
            ),

            SizedBox(height: tokens.space5),

            // The board, ON the ground. No panel, no frame, no border — the
            // tubes are the containers and wrapping them in another one is
            // exactly the app furniture this screen exists to remove.
            if (board != null)
              Center(
                child: BoardPreview(
                  board: board,
                  ballSize: board.tubeCount <= 6 ? 44 : 32,
                  boldGlyphs: ref.watch(settingsProvider).boldSymbols,
                ),
              ),

            SizedBox(height: tokens.space4),
            Text(
              'LEVEL ${_pad(current)}  ·  ${bandNameForLevel(current).toUpperCase()}',
              style: labelStyle(tokens).copyWith(letterSpacing: 1.8),
            ),

            SizedBox(height: tokens.space3),
            _ContinuePill(
              level: current,
              onTap: () => onOpenLevel(current, null),
            ),

            SizedBox(height: tokens.space5),
            _LiveRow(
              onOpenDaily: onOpenDaily,
              onOpenLeaderboard: onOpenLeaderboard,
            ),

            SizedBox(height: tokens.space5),
            Text('THE WAY AHEAD', style: labelStyle(tokens).copyWith(
              letterSpacing: 1.8,
            )),
            SizedBox(height: tokens.space2),
            _JourneyTeaser(
              levelSet: levelSet,
              current: current,
              onTap: onOpenJourney,
            ),
          ],
        ),
      ),
    );
  }

  /// Two digits, so a row of numbers does not reflow as the counts grow.
  static String _pad(int value) => value.toString().padLeft(2, '0');
}

class _TopRow extends ConsumerWidget {
  const _TopRow({required this.onOpenAccount, required this.onOpenSettings});

  final VoidCallback onOpenAccount;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = PourfectTokens.of(context);
    final account = ref.watch(accountProvider);
    final session = ref.watch(authServiceProvider).current;

    return Row(
      children: [
        if (account.available)
          Pressable(
            onPressed: onOpenAccount,
            semanticLabel:
                account.signedIn ? 'Your account' : 'Save your progress',
            child: PlayerCrest(
              seed: session?.userId,
              signedIn: account.signedIn,
              size: 38,
            ),
          ),
        const Spacer(),
        Pressable(
          onPressed: onOpenSettings,
          semanticLabel: 'Settings',
          child: Icon(Icons.tune_rounded, size: 22, color: tokens.textMuted),
        ),
      ],
    );
  }
}

/// A number with its unit, set as plain type.
class Figure extends StatelessWidget {
  const Figure({
    super.key,
    required this.value,
    required this.label,
    this.color,
    this.stacked = false,
  });

  final String value;
  final String label;
  final Color? color;

  /// Label above the value, for the wider pairs at the foot of the screen.
  final bool stacked;

  @override
  Widget build(BuildContext context) {
    final tokens = PourfectTokens.of(context);

    final number = Text(
      value,
      style: numericStyle(tokens, size: stacked ? 26 : 16).copyWith(
        color: color ?? tokens.textPrimary,
      ),
    );
    final unit = Text(
      label,
      style: labelStyle(tokens).copyWith(letterSpacing: 1.8),
    );

    if (stacked) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [unit, SizedBox(height: tokens.space2), number],
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [number, SizedBox(width: tokens.space2), unit],
    );
  }
}

/// Today's challenge and the player's rank, side by side.
class _LiveRow extends ConsumerWidget {
  const _LiveRow({required this.onOpenDaily, required this.onOpenLeaderboard});

  final VoidCallback onOpenDaily;
  final VoidCallback onOpenLeaderboard;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = PourfectTokens.of(context);
    final daily = ref.watch(dailyProvider);

    // A build with no server has no daily and no ranks, and showing two dead
    // labels is worse than showing neither.
    if (daily.isOff) return const SizedBox.shrink();

    final played = daily.challenge?.isPlayed ?? false;

    return Row(
      children: [
        Expanded(
          child: Pressable(
            onPressed: onOpenDaily,
            semanticLabel: "Today's challenge",
            child: Figure(
              label: "TODAY'S CHALLENGE",
              value: played ? 'SOLVED' : 'OPEN',
              color: played ? tokens.textMuted : tokens.accentWarm,
              stacked: true,
            ),
          ),
        ),
        Expanded(
          child: Pressable(
            onPressed: onOpenLeaderboard,
            semanticLabel: 'Leaderboard',
            child: Figure(
              label: 'RANK',
              value: '—',
              color: tokens.accent,
              stacked: true,
            ),
          ),
        ),
      ],
    );
  }
}

class _ContinuePill extends StatelessWidget {
  const _ContinuePill({required this.level, required this.onTap});

  final int level;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = PourfectTokens.of(context);

    return Pressable(
      onPressed: onTap,
      semanticLabel: 'Continue, level $level',
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          color: tokens.surfaceRaised,
          borderRadius: BorderRadius.circular(32),
        ),
        child: Row(
          children: [
            const SizedBox(width: 6),
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: tokens.accent,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.play_arrow_rounded,
                color: tokens.surface,
                size: 30,
              ),
            ),
            Expanded(
              child: Center(
                child: Text(
                  'Continue',
                  style: titleStyle(tokens).copyWith(
                    fontSize: 19,
                    color: tokens.accent,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 58),
          ],
        ),
      ),
    );
  }
}

/// A window onto the campaign path.
///
/// The same painter the full journey uses, clipped to a strip and scrolled to
/// where the player actually is. It is a teaser rather than a second
/// implementation: one geometry, one painter, so the slice shown here and the
/// screen it opens cannot disagree about where a level sits.
class _JourneyTeaser extends ConsumerWidget {
  const _JourneyTeaser({
    required this.levelSet,
    required this.current,
    required this.onTap,
  });

  final dynamic levelSet;
  final int current;
  final VoidCallback onTap;

  static const double _height = 230;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = PourfectTokens.of(context);
    if (levelSet == null) return const SizedBox.shrink();

    final count = levelSet.levels.length as int;
    final progress = ref.watch(progressProvider);
    final progressOps = ref.read(progressProvider.notifier);

    final levels = [
      for (var id = 1; id <= count; id++)
        JourneyLevel(
          id: id,
          mark: id == current
              ? JourneyMark.current
              : progress.containsKey(id)
                  ? JourneyMark.solved
                  : progressOps.isUnlocked(id)
                      ? JourneyMark.unlocked
                      : JourneyMark.locked,
          stars: progress[id]?.stars ?? 0,
          colorId: (id * 3) % 10,
        ),
    ];

    final bands = [
      for (final band in campaignBands())
        JourneyBand(
          firstLevel: band.firstLevel,
          name: band.name,
          length: band.length,
          reached: current >= band.firstLevel,
        ),
    ];

    return Pressable(
      onPressed: onTap,
      semanticLabel: 'The way ahead',
      scale: 0.99,
      child: SizedBox(
        height: _height,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            // Centred on the player, so the strip always shows the road just
            // travelled and the next few stones.
            final centre = journeyPosition(current, count, width).dy;
            final top = centre - _height * 0.62;

            return ClipRect(
              child: Stack(
                children: [
                  Positioned(
                    top: -top,
                    left: 0,
                    width: width,
                    height: journeyHeight(count),
                    child: CustomPaint(
                      painter: JourneyPainter(
                        levels: levels,
                        bands: bands,
                        tokens: tokens,
                        boldGlyphs: ref.watch(settingsProvider).boldSymbols,
                        // Still, not breathing. The hub should not carry a
                        // forever-running animation just to decorate a strip.
                        pulse: 0,
                        visibleTop: top,
                        visibleBottom: top + _height,
                      ),
                    ),
                  ),
                  // Fades at both edges, so the path runs off rather than
                  // stopping at a line. A hard edge would read as a card.
                  _EdgeFade(top: true),
                  _EdgeFade(top: false),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _EdgeFade extends StatelessWidget {
  const _EdgeFade({required this.top});

  final bool top;

  @override
  Widget build(BuildContext context) {
    final tokens = PourfectTokens.of(context);
    return Positioned(
      top: top ? 0 : null,
      bottom: top ? null : 0,
      left: 0,
      right: 0,
      child: IgnorePointer(
        child: Container(
          height: 54,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: top ? Alignment.topCenter : Alignment.bottomCenter,
              end: top ? Alignment.bottomCenter : Alignment.topCenter,
              colors: [
                tokens.surface,
                tokens.surface.withValues(alpha: 0),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

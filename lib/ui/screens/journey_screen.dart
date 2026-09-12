/// The campaign as a path you travel, not a grid you scan.
///
/// This REPLACES the level grid rather than sitting in front of it. A hundred
/// and fifty numbered squares is a table of contents; the same hundred and
/// fifty as a climb makes level 96 feel far from level 3, which is the only
/// honest way to show a campaign that takes weeks. It is the pattern the
/// biggest games in this genre use, and they use it because progression IS the
/// meta-game.
///
/// **No cards.** Nothing here is a bordered panel, a grouped row or a section
/// rule. Grouping is done with distance and scale. Every box drawn on a game
/// screen is a piece of app furniture, and a screen made of them reads as
/// Settings however well it is lit.
///
/// The path itself is painted rather than built — see [JourneyPainter] for why
/// 150 widgets would not survive the frame budget.
library;

import 'dart:math' as math;

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
import '../widgets/journey_path.dart';
import '../widgets/player_crest.dart';
import '../widgets/pressable.dart';

class JourneyScreen extends ConsumerStatefulWidget {
  const JourneyScreen({
    super.key,
    required this.onOpenLevel,
    required this.onOpenSettings,
    required this.onOpenStatistics,
    required this.onOpenDaily,
    required this.onOpenLeaderboard,
    required this.onOpenAccount,
  });

  final void Function(int levelId, Rect? origin) onOpenLevel;
  final VoidCallback onOpenSettings;
  final VoidCallback onOpenStatistics;
  final VoidCallback onOpenDaily;
  final VoidCallback onOpenLeaderboard;
  final VoidCallback onOpenAccount;

  @override
  ConsumerState<JourneyScreen> createState() => _JourneyScreenState();
}

class _JourneyScreenState extends ConsumerState<JourneyScreen>
    with SingleTickerProviderStateMixin {
  final _scroll = ScrollController();
  late final AnimationController _pulse;

  /// Set once the first layout has put the player where they actually are.
  bool _placed = false;

  @override
  void initState() {
    super.initState();
    // 3.2s, and the ONLY thing on this screen that animates. Honours the
    // platform's reduced-motion setting, which is checked at build time
    // because it can change while the app is open.
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    _scroll.dispose();
    super.dispose();
  }

  /// Jumps to the player's current level without animating.
  ///
  /// The campaign is roughly 16,000px tall. Somebody on level 96 opening the
  /// app to a slow scroll from the bottom would watch the screen travel for
  /// several seconds before they could do anything, so this is a jump and the
  /// animation is saved for when they have actually moved.
  void _placeAtCurrent(int current, int count, double width, double viewport) {
    final target = journeyPosition(current, count, width).dy - viewport * 0.46;
    final max = journeyHeight(count) - viewport;
    _scroll.jumpTo(target.clamp(0.0, math.max(0.0, max)));
    _placed = true;
  }

  @override
  Widget build(BuildContext context) {
    final tokens = PourfectTokens.of(context);
    final levelSet = ref.watch(campaignProvider).asData?.value;
    final progress = ref.watch(progressProvider);
    final progressOps = ref.read(progressProvider.notifier);
    ref.watch(playHistoryProvider);
    final history = ref.read(playHistoryProvider.notifier);

    if (levelSet == null) {
      return Scaffold(backgroundColor: tokens.surface, body: const SizedBox());
    }

    final count = levelSet.levels.length;
    final current = progressOps.furthestUnlocked;

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
          // Spread across the palette by level rather than by band, so the
          // path has the whole game's color running up it.
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

    final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    return Scaffold(
      backgroundColor: tokens.surface,
      body: Stack(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final viewport = constraints.maxHeight;

              if (!_placed) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted && _scroll.hasClients && !_placed) {
                    _placeAtCurrent(current, count, width, viewport);
                  }
                });
              }

              return SingleChildScrollView(
                controller: _scroll,
                child: SizedBox(
                  height: journeyHeight(count),
                  width: width,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTapUp: (details) {
                      final id = JourneyPainter.levelAt(
                        details.localPosition,
                        count,
                        width,
                      );
                      if (id != null && progressOps.isUnlocked(id)) {
                        widget.onOpenLevel(id, null);
                      }
                    },
                    child: AnimatedBuilder(
                      animation: _pulse,
                      builder: (context, _) => AnimatedBuilder(
                        animation: _scroll,
                        builder: (context, _) {
                          final offset =
                              _scroll.hasClients ? _scroll.offset : 0.0;
                          return CustomPaint(
                            size: Size(width, journeyHeight(count)),
                            painter: JourneyPainter(
                              levels: levels,
                              bands: bands,
                              tokens: tokens,
                              boldGlyphs: ref.watch(settingsProvider).boldSymbols,
                              pulse: reduceMotion ? 0 : _pulse.value,
                              visibleTop: offset,
                              visibleBottom: offset + viewport,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              );
            },
          ),

          // The path runs UNDER the header and the action, so the screen reads
          // as one surface rather than three stacked panels. A gradient does
          // the separating; a bar with a border would be a card.
          _TopFade(),
          _Header(
            solved: progress.length,
            stars: progressOps.totalStars,
            streak: history.currentStreak(),
            onOpenAccount: widget.onOpenAccount,
            onOpenSettings: widget.onOpenSettings,
            onOpenStatistics: widget.onOpenStatistics,
            onOpenDaily: widget.onOpenDaily,
            onOpenLeaderboard: widget.onOpenLeaderboard,
          ),

          _BottomFade(),
          _ContinueBar(
            level: current,
            onTap: () => widget.onOpenLevel(current, null),
          ),
        ],
      ),
    );
  }
}

/// Identity, then the numbers, set as plain type with no container.
class _Header extends ConsumerWidget {
  const _Header({
    required this.solved,
    required this.stars,
    required this.streak,
    required this.onOpenAccount,
    required this.onOpenSettings,
    required this.onOpenStatistics,
    required this.onOpenDaily,
    required this.onOpenLeaderboard,
  });

  final int solved;
  final int stars;
  final int streak;
  final VoidCallback onOpenAccount;
  final VoidCallback onOpenSettings;
  final VoidCallback onOpenStatistics;
  final VoidCallback onOpenDaily;
  final VoidCallback onOpenLeaderboard;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = PourfectTokens.of(context);
    final account = ref.watch(accountProvider);
    final session = ref.watch(authServiceProvider).current;
    final daily = ref.watch(dailyProvider);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          tokens.space4, tokens.space3, tokens.space4, 0,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                if (account.available) ...[
                  Pressable(
                    onPressed: onOpenAccount,
                    semanticLabel: account.signedIn
                        ? 'Your account'
                        : 'Save your progress',
                    child: PlayerCrest(
                      seed: session?.userId,
                      signedIn: account.signedIn,
                    ),
                  ),
                  SizedBox(width: tokens.space3),
                ],
                Text(
                  'Pourfect',
                  style: titleStyle(tokens).copyWith(fontSize: 22),
                ),
                const Spacer(),
                Pressable(
                  onPressed: onOpenSettings,
                  semanticLabel: 'Settings',
                  child: Icon(
                    Icons.tune_rounded,
                    size: 22,
                    color: tokens.textMuted,
                  ),
                ),
              ],
            ),

            SizedBox(height: tokens.space3),

            // Numbers first, unit after — "02 SOLVED" reads the way somebody
            // would say it, and the value is what the eye should land on.
            Pressable(
              onPressed: onOpenStatistics,
              semanticLabel: 'Statistics',
              child: Wrap(
                spacing: tokens.space4,
                runSpacing: tokens.space2,
                children: [
                  _Figure(value: _pad(solved), label: 'SOLVED'),
                  _Figure(
                    value: _pad(stars),
                    label: 'STARS',
                    color: tokens.accentWarm,
                  ),
                  if (streak > 0)
                    _Figure(
                      value: '${_pad(streak)}d',
                      label: 'STREAK',
                      color: tokens.accent,
                    ),
                ],
              ),
            ),

            SizedBox(height: tokens.space2),

            Wrap(
              spacing: tokens.space4,
              runSpacing: tokens.space2,
              children: [
                if (!daily.isOff)
                  Pressable(
                    onPressed: onOpenDaily,
                    semanticLabel: "Today's challenge",
                    child: _Figure(
                      label: 'CHALLENGE',
                      value: daily.challenge?.isPlayed ?? false
                          ? 'DONE'
                          : 'TODAY',
                      color: tokens.accentWarm,
                      labelFirst: true,
                    ),
                  ),
                Pressable(
                  onPressed: onOpenLeaderboard,
                  semanticLabel: 'Leaderboard',
                  child: _Figure(
                    label: 'RANKS',
                    value: 'OPEN',
                    color: tokens.accent,
                    labelFirst: true,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Two digits, so the row does not reflow as the counts grow.
  static String _pad(int value) => value.toString().padLeft(2, '0');
}

class _Figure extends StatelessWidget {
  const _Figure({
    required this.value,
    required this.label,
    this.color,
    this.labelFirst = false,
  });

  final String value;
  final String label;
  final Color? color;
  final bool labelFirst;

  @override
  Widget build(BuildContext context) {
    final tokens = PourfectTokens.of(context);

    final number = Text(
      value,
      style: numericStyle(tokens, size: 15).copyWith(
        color: color ?? tokens.textPrimary,
      ),
    );
    final unit = Text(
      label,
      style: labelStyle(tokens).copyWith(letterSpacing: 1.8),
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: labelFirst
          ? [unit, SizedBox(width: tokens.space2), number]
          : [number, SizedBox(width: tokens.space2), unit],
    );
  }
}

/// The primary action, as a pill rather than a card.
class _ContinueBar extends StatelessWidget {
  const _ContinueBar({required this.level, required this.onTap});

  final int level;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = PourfectTokens.of(context);

    return Positioned(
      left: tokens.space4,
      right: tokens.space4,
      bottom: tokens.space4,
      child: SafeArea(
        top: false,
        child: Pressable(
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
                SizedBox(width: tokens.space1),
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
                const SizedBox(width: 60),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Gradients rather than bars, so the path passes beneath rather than stopping
/// at an edge. An opaque strip with a border would be a card by another name.
class _TopFade extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final tokens = PourfectTokens.of(context);
    return IgnorePointer(
      child: Container(
        height: 230,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              tokens.surface,
              tokens.surface,
              tokens.surface.withValues(alpha: 0),
            ],
            stops: const [0, 0.55, 1],
          ),
        ),
      ),
    );
  }
}

class _BottomFade extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final tokens = PourfectTokens.of(context);
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: IgnorePointer(
        child: Container(
          height: 190,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [
                tokens.surface,
                tokens.surface,
                tokens.surface.withValues(alpha: 0),
              ],
              stops: const [0, 0.5, 1],
            ),
          ),
        ),
      ),
    );
  }
}

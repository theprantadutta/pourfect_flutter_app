/// Level select: the campaign as structure, not a grid of numbered squares.
///
/// Every level is drawn as a TUBE — the game's own object — holding one to
/// three pips for its stars, stacked the way balls stack. A numbered square
/// would be a list of integers; this is a shelf of vessels, some filled.
///
/// Bands are real sections with their own name, board shape and progress
/// track, so the difficulty curve built in stage 6 becomes something a player
/// can actually see rather than a thing they only feel.
///
/// Two things deliberately ABSENT:
///
///  * **Breathers are not marked.** They are a designed beat in the curve, and
///    labelling one "we made this easy for you" is both condescending and a
///    confession that the curve is engineered. They work because they are felt.
///  * **No star gate.** Clearing a level opens the next one, full stop. Making
///    someone grind for stars to continue is a retention cost with no upside.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/daily_controller.dart';
import '../../state/level_repository.dart';
import '../../state/progress_repository.dart';
import '../../state/account_controller.dart';
import '../../state/providers.dart';
import '../theme/tokens.dart';
import '../theme/typography.dart';
import '../transitions.dart';
import '../widgets/daily_card.dart';
import '../widgets/next_level_hero.dart';
import '../widgets/player_crest.dart';
import '../widgets/pressable.dart';

/// Tile metrics. Kept here because the scroll-to-current maths needs them
/// before the list is built.
const double _tileWidth = 46;
const double _vesselHeight = 58;
const double _tileHeight = _vesselHeight + 22;
const double _tileGap = 10;
const double _headerHeight = 74;
const double _sectionPadding = 26;

class LevelSelectScreen extends ConsumerStatefulWidget {
  /// Opens a level. Receives the tapped tile's global rect so the caller can
  /// grow the board out of the vessel the player actually touched.
  final void Function(int levelId, Rect? origin) onOpenLevel;

  /// Opens settings.
  final VoidCallback onOpenSettings;

  /// Opens the statistics screen.
  final VoidCallback onOpenStatistics;

  /// Opens today's challenge.
  final VoidCallback onOpenDaily;

  /// Opens the leaderboards.
  final VoidCallback onOpenLeaderboard;

  /// Opens the account screen. Reached from the crest in the masthead.
  final VoidCallback onOpenAccount;

  const LevelSelectScreen({
    super.key,
    required this.onOpenLevel,
    required this.onOpenSettings,
    required this.onOpenStatistics,
    required this.onOpenDaily,
    required this.onOpenLeaderboard,
    required this.onOpenAccount,
  });

  @override
  ConsumerState<LevelSelectScreen> createState() => _LevelSelectScreenState();
}

class _LevelSelectScreenState extends ConsumerState<LevelSelectScreen> {
  final ScrollController _controller = ScrollController();

  /// Marks the top of the level index, so "Jump to level N" knows where the
  /// grid begins. Measured rather than computed: the masthead and the hero
  /// above it change height with the board being previewed and with whether
  /// the first-run sentence is showing.
  final GlobalKey _indexKey = GlobalKey();
  double _indexTop = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Re-measures the top of the index after a frame, whenever it is laid out.
  void _measureIndex() {
    final box = _indexKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.attached || !_controller.hasClients) return;

    final viewport = context.findRenderObject() as RenderBox?;
    if (viewport == null || !viewport.attached) return;

    final top =
        box.localToGlobal(Offset.zero, ancestor: viewport).dy +
        _controller.offset;
    if ((top - _indexTop).abs() > 0.5) _indexTop = top;
  }

  Future<void> _jumpToCurrent(int current, double width) async {
    final target = (_indexTop + _offsetForLevel(current, width)).clamp(
      0.0,
      _controller.position.maxScrollExtent,
    );
    await _controller.animateTo(
      target,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
    );
  }

  /// Where the band containing [levelId] starts, in scroll pixels.
  ///
  /// 150 tubes is a lot of scrolling, and opening at the top would ask a player
  /// on level 96 to hunt for themselves every single time. The layout is
  /// deterministic once the width is known, so the offset can simply be
  /// computed rather than measured after a frame.
  static int _perRow(double width) =>
      ((width + _tileGap) / (_tileWidth + _tileGap)).floor().clamp(1, 12);

  double _offsetForLevel(int levelId, double width) {
    final perRow = _perRow(width);

    var offset = 0.0;
    for (final band in campaignBands()) {
      if (band.contains(levelId)) break;
      final rows = (band.length / perRow).ceil();
      offset +=
          _headerHeight + rows * (_tileHeight + _tileGap) + _sectionPadding;
    }
    // Leave the sticky header visible above the band rather than flush to it.
    return (offset - _headerHeight).clamp(0.0, double.infinity);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = PourfectTokens.of(context);
    // Warms the level asset while the player is still choosing, so opening a
    // board never shows a loading state. Also feeds the hero preview, which
    // draws the real next board.
    final levelSet = ref.watch(campaignProvider).asData?.value;
    final progress = ref.watch(progressProvider);
    final daily = ref.watch(dailyProvider);
    final controller = ref.read(progressProvider.notifier);
    final current = controller.furthestUnlocked;

    return Scaffold(
      backgroundColor: tokens.surface,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth - tokens.space4 * 2;
            WidgetsBinding.instance.addPostFrameCallback(
              (_) => _measureIndex(),
            );

            // Opens on the hero, every time. The old screen opened scrolled
            // into the middle of the index, which is why the first thing a
            // player saw was a wall of locked tubes.
            return CustomScrollView(
              controller: _controller,
              slivers: [
                SliverToBoxAdapter(
                  child: _Masthead(
                    onOpenAccount: widget.onOpenAccount,
                    cleared: progress.length,
                    stars: controller.totalStars,
                    onOpenSettings: widget.onOpenSettings,
                    onOpenStatistics: widget.onOpenStatistics,
                  ),
                ),

                // The hero: the actual next board, at scale, with one verb.
                // A first-time player used to meet a wall of locked outlines
                // and no instruction to do anything at all.
                if (levelSet?.byId(current) case final next?)
                  SliverToBoxAdapter(
                    child: NextLevelHero(
                      levelId: current,
                      board: next.level.board,
                      isFirstEver: progress.isEmpty,
                      earnedStars: progress[current]?.stars,
                      boldGlyphs: ref.watch(settingsProvider).boldSymbols,
                      onPlay: (origin) => widget.onOpenLevel(current, origin),
                    ),
                  ),

                // One quiet row, not a second hero. A daily card competing
                // with the Play button would put a first-time player back
                // where the redesign found them: choosing between two things
                // they do not understand yet.
                //
                // Absent entirely with no backend — a build with no server,
                // or a first launch with no signal, gets the game it already
                // had rather than a row that never works.
                if (daily.isOff)
                  const SliverToBoxAdapter(child: SizedBox.shrink())
                else
                  SliverToBoxAdapter(
                    child: DailyCard(
                      played: daily.challenge?.isPlayed,
                      stars: daily.challenge?.yourAttempt?.stars,
                      unavailable: daily.isUnavailable,
                      onOpenDaily: widget.onOpenDaily,
                      onOpenLeaderboard: widget.onOpenLeaderboard,
                    ),
                  ),

                // The index below is for browsing, not for starting. It is
                // named so, because an unlabelled grid of 150 tubes under a
                // Play button reads as "more things I should understand".
                SliverToBoxAdapter(
                  child: Padding(
                    key: _indexKey,
                    padding: EdgeInsets.fromLTRB(
                      tokens.space4,
                      tokens.space2,
                      tokens.space4,
                      0,
                    ),
                    child: Row(
                      children: [
                        Text(
                          'All levels',
                          style: titleStyle(tokens).copyWith(fontSize: 16),
                        ),
                        SizedBox(width: tokens.space2),
                        Expanded(child: Divider(color: tokens.hairline)),
                        // Only worth offering once the index is long enough
                        // that finding yourself in it is real work.
                        if (current > 12) ...[
                          SizedBox(width: tokens.space2),
                          Pressable(
                            onPressed: () => _jumpToCurrent(current, width),
                            child: Text(
                              'Jump to $current',
                              style: bodyStyle(tokens)
                                  .copyWith(fontSize: 13, color: tokens.accent),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                for (final band in campaignBands()) ...[
                  SliverToBoxAdapter(
                    child: _BandHeading(
                      band: band,
                      cleared: controller.clearedIn(
                        band.firstLevel,
                        band.lastLevel,
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(
                      tokens.space4,
                      0,
                      tokens.space4,
                      _sectionPadding,
                    ),
                    sliver: SliverToBoxAdapter(
                      child: Wrap(
                        spacing: _tileGap,
                        runSpacing: _tileGap,
                        children: [
                          for (
                            var id = band.firstLevel;
                            id <= band.lastLevel;
                            id++
                          )
                            _LevelTile(
                              levelId: id,
                              progress: progress[id],
                              isCurrent: id == current,
                              isUnlocked: controller.isUnlocked(id),
                              onOpen: widget.onOpenLevel,
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
                SliverToBoxAdapter(child: SizedBox(height: tokens.space5)),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Masthead extends ConsumerWidget {
  final int cleared;
  final int stars;
  final VoidCallback onOpenSettings;
  final VoidCallback onOpenStatistics;
  final VoidCallback onOpenAccount;

  const _Masthead({
    required this.cleared,
    required this.stars,
    required this.onOpenSettings,
    required this.onOpenStatistics,
    required this.onOpenAccount,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = PourfectTokens.of(context);
    final account = ref.watch(accountProvider);

    // Zeros are not a first impression. A brand-new player was greeted by
    // "SOLVED 0 / STARS 0", which is a scoreboard reporting that they have
    // done nothing. The counters appear once there is something to count.
    final hasProgress = cleared > 0;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        tokens.space4,
        tokens.space3,
        tokens.space4,
        tokens.space1,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // WHO IS PLAYING, before what the game is called.
          //
          // Signing in used to change nothing visible anywhere in the app: you
          // came back from the account screen to exactly the screen you left.
          // The crest is the smallest honest answer to that — it is here on
          // every launch, it is different once you have an account, and it is
          // the way back to the account screen.
          //
          // Hidden entirely in a build with no Firebase, rather than shown as
          // a control that cannot do anything.
          if (account.available) ...[
            Pressable(
              onPressed: onOpenAccount,
              semanticLabel: account.signedIn
                  ? 'Your account'
                  : 'Save your progress',
              child: PlayerCrest(
                seed: account.userId,
                signedIn: account.signedIn,
              ),
            ),
            SizedBox(width: tokens.space3),
          ],
          Text('Pourfect', style: titleStyle(tokens).copyWith(fontSize: 22)),
          const Spacer(),
          // The counters ARE the way in to statistics. Somebody looking at
          // "12 solved" who wants to know more taps the number they are
          // already reading; a chart icon in the corner would be one more
          // piece of chrome to learn to ignore. There is nothing to tap
          // before the first clear, which is also when the screen would have
          // nothing on it.
          if (hasProgress) ...[
            Pressable(
              onPressed: onOpenStatistics,
              semanticLabel: 'Statistics',
              child: Row(
                children: [
                  _Counter(
                    value: '$cleared',
                    label: 'solved',
                    color: tokens.textPrimary,
                  ),
                  SizedBox(width: tokens.space3),
                  _Counter(
                    value: '$stars',
                    label: 'stars',
                    color: tokens.accentWarm,
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: tokens.dimText,
                  ),
                ],
              ),
            ),
            SizedBox(width: tokens.space3),
          ],
          Pressable(
            onPressed: onOpenSettings,
            semanticLabel: 'Settings',
            child: Icon(Icons.tune_rounded, size: 22, color: tokens.textMuted),
          ),
        ],
      ),
    );
  }
}

/// A number with its unit beside it, rather than a tracked-out caps label
/// stacked above it. Reads as "12 solved", which is how somebody would say it.
class _Counter extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _Counter({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = PourfectTokens.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(value, style: numericStyle(tokens, size: 18, color: color)),
        SizedBox(width: tokens.space1),
        Text(label, style: bodyStyle(tokens).copyWith(fontSize: 13)),
      ],
    );
  }
}

/// An inline band heading. Scrolls away with its section — the pinned bar
/// above is what keeps position legible.
class _BandHeading extends StatelessWidget {
  final BandInfo band;
  final int cleared;

  const _BandHeading({required this.band, required this.cleared});

  @override
  Widget build(BuildContext context) {
    final tokens = PourfectTokens.of(context);
    final done = cleared >= band.length;

    return SizedBox(
      height: _headerHeight,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          tokens.space4,
          tokens.space3,
          tokens.space4,
          tokens.space2,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  band.name,
                  style: titleStyle(tokens).copyWith(fontSize: 16),
                ),
                const Spacer(),
                Text(
                  '$cleared / ${band.length}',
                  style: numericStyle(
                    tokens,
                    size: 11,
                    weight: FontWeight.w500,
                    color: done ? tokens.accentWarm : tokens.textMuted,
                  ),
                ),
              ],
            ),
            SizedBox(height: tokens.space2),
            _Track(value: cleared / band.length, done: done),
          ],
        ),
      ),
    );
  }
}

class _LevelTile extends StatelessWidget {
  final int levelId;
  final LevelProgress? progress;
  final bool isCurrent;
  final bool isUnlocked;
  final void Function(int levelId, Rect? origin) onOpen;

  const _LevelTile({
    required this.levelId,
    required this.progress,
    required this.isCurrent,
    required this.isUnlocked,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = PourfectTokens.of(context);
    final solved = progress != null;

    final borderColor = solved
        ? tokens.accentWarm.withValues(alpha: 0.34)
        : isCurrent
        ? tokens.accent.withValues(alpha: 0.75)
        : isUnlocked
        ? tokens.hairlineStrong
        : tokens.hairline;

    return Pressable(
      onPressed: isUnlocked
          ? () => onOpen(levelId, globalRectOf(context))
          : null,
      semanticLabel: solved
          ? 'Level $levelId, ${progress!.stars} of 3 stars'
          : isUnlocked
          ? 'Level $levelId, not yet solved'
          : 'Level $levelId, locked',
      child: SizedBox(
        width: _tileWidth,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: _tileWidth,
              height: _vesselHeight,
              decoration: BoxDecoration(
                color: solved
                    ? tokens.accentWarm.withValues(alpha: 0.08)
                    : isCurrent
                    ? tokens.accent.withValues(alpha: 0.10)
                    : isUnlocked
                    ? tokens.tubeGlass
                    : tokens.tubeGlass.withValues(alpha: 0.12),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(3),
                  bottom: Radius.circular(12),
                ),
                border: Border.all(color: borderColor),
                boxShadow: [
                  if (isCurrent)
                    BoxShadow(
                      color: tokens.accent.withValues(alpha: 0.22),
                      blurRadius: 16,
                    ),
                ],
              ),
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Stars stack from the bottom, like balls settling.
                  for (var i = 0; i < (progress?.stars ?? 0); i++)
                    Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: _pip(tokens.accentWarm),
                    ),
                  if (isCurrent && !solved) _pip(tokens.accent),
                ],
              ),
            ),
            SizedBox(height: tokens.space1 + 2),
            Text(
              '$levelId',
              style: numericStyle(
                tokens,
                size: 10,
                weight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                color: isCurrent
                    ? tokens.accent
                    : solved || isUnlocked
                    ? tokens.textMuted
                    : tokens.dimText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pip(Color color) => Container(
    width: 9,
    height: 9,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}

class _Track extends StatelessWidget {
  final double value;
  final bool done;

  const _Track({required this.value, required this.done});

  @override
  Widget build(BuildContext context) {
    final tokens = PourfectTokens.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(2),
      child: SizedBox(
        height: 2,
        child: Stack(
          children: [
            Container(color: tokens.hairline),
            FractionallySizedBox(
              widthFactor: value.clamp(0.0, 1.0),
              child: Container(color: done ? tokens.accentWarm : tokens.accent),
            ),
          ],
        ),
      ),
    );
  }
}

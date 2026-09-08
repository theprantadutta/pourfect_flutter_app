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

import '../../state/level_repository.dart';
import '../../state/progress_repository.dart';
import '../../state/providers.dart';
import '../theme/tokens.dart';
import '../theme/typography.dart';
import '../transitions.dart';
import '../widgets/next_level_hero.dart';
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

  const LevelSelectScreen({
    super.key,
    required this.onOpenLevel,
    required this.onOpenSettings,
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

  /// Which band the viewport is currently showing.
  ///
  /// The inverse of [_offsetForLevel], sharing the same deterministic layout,
  /// so the pinned bar and the scroll position can never disagree.
  BandInfo _bandAtOffset(double offset, double width) {
    final bands = campaignBands();
    var cursor = 0.0;
    for (final band in bands) {
      final rows = (band.length / _perRow(width)).ceil();
      final height =
          _headerHeight + rows * (_tileHeight + _tileGap) + _sectionPadding;
      // Flip to the next band as its heading reaches the top, not when the
      // previous band's last tile finally leaves.
      if (offset < cursor + height - _headerHeight) return band;
      cursor += height;
    }
    return bands.last;
  }

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
                    cleared: progress.length,
                    stars: controller.totalStars,
                    onOpenSettings: widget.onOpenSettings,
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
                              style: bodyStyle(
                                tokens,
                              ).copyWith(fontSize: 13, color: tokens.accent),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                // ONE pinned bar, not one per band. Flutter's pinned slivers
                // STACK rather than pushing each other off, so a header per
                // band left four piled up at the bottom of a 150-level list,
                // eating a third of the screen.
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _CurrentBandBar(
                    controller: _controller,
                    bandAt: (offset) => _bandAtOffset(offset, width),
                    clearedIn: controller.clearedIn,
                    tokens: tokens,
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

class _Masthead extends StatelessWidget {
  final int cleared;
  final int stars;
  final VoidCallback onOpenSettings;

  const _Masthead({
    required this.cleared,
    required this.stars,
    required this.onOpenSettings,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = PourfectTokens.of(context);

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
          Text('Pourfect', style: titleStyle(tokens).copyWith(fontSize: 22)),
          const Spacer(),
          if (hasProgress) ...[
            _Counter(
              value: '$cleared',
              label: 'solved',
              color: tokens.textPrimary,
            ),
            SizedBox(width: tokens.space4),
            _Counter(
              value: '$stars',
              label: 'stars',
              color: tokens.accentWarm,
            ),
            SizedBox(width: tokens.space4),
          ],
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

/// The single pinned bar, reporting whichever band the viewport is showing.
class _CurrentBandBar extends SliverPersistentHeaderDelegate {
  final ScrollController controller;
  final BandInfo Function(double offset) bandAt;
  final int Function(int first, int last) clearedIn;
  final PourfectTokens tokens;

  _CurrentBandBar({
    required this.controller,
    required this.bandAt,
    required this.clearedIn,
    required this.tokens,
  });

  /// Slim on purpose: this is a position indicator, not a second heading.
  @override
  double get minExtent => 44;

  @override
  double get maxExtent => 44;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlaps) =>
      AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          final offset = controller.hasClients ? controller.offset : 0.0;
          final band = bandAt(offset);
          final cleared = clearedIn(band.firstLevel, band.lastLevel);
          final done = cleared >= band.length;

          return Container(
            height: 44,
            // Opaque, so tiles never show through the pinned bar.
            color: tokens.surface,
            padding: EdgeInsets.symmetric(horizontal: tokens.space4),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        band.name.toUpperCase(),
                        style: labelStyle(
                          tokens,
                        ).copyWith(color: tokens.textNumeric, fontSize: 10.5),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '$cleared / ${band.length}',
                      style: numericStyle(
                        tokens,
                        size: 10.5,
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
          );
        },
      );

  @override
  bool shouldRebuild(_CurrentBandBar old) => true;
}

/// The hairline progress rule, shared by the bar and the headings.
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

/// One level, drawn as the vessel it is.
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

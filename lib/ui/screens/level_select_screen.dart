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

  const LevelSelectScreen({super.key, required this.onOpenLevel});

  @override
  ConsumerState<LevelSelectScreen> createState() => _LevelSelectScreenState();
}

class _LevelSelectScreenState extends ConsumerState<LevelSelectScreen> {
  ScrollController? _controller;

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  /// Where the band containing [levelId] starts, in scroll pixels.
  ///
  /// 150 tubes is a lot of scrolling, and opening at the top would ask a player
  /// on level 96 to hunt for themselves every single time. The layout is
  /// deterministic once the width is known, so the offset can simply be
  /// computed rather than measured after a frame.
  double _offsetForLevel(int levelId, double width) {
    final perRow = ((width + _tileGap) / (_tileWidth + _tileGap)).floor().clamp(
      1,
      12,
    );

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
    // board never shows a loading state.
    ref.watch(campaignProvider);
    final progress = ref.watch(progressProvider);
    final controller = ref.read(progressProvider.notifier);
    final current = controller.furthestUnlocked;

    return Scaffold(
      backgroundColor: tokens.surface,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth - tokens.space4 * 2;
            _controller ??= ScrollController(
              initialScrollOffset: _offsetForLevel(current, width),
            );

            return CustomScrollView(
              controller: _controller,
              slivers: [
                SliverToBoxAdapter(
                  child: _Masthead(
                    cleared: progress.length,
                    stars: controller.totalStars,
                  ),
                ),
                for (final band in campaignBands()) ...[
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _BandHeader(
                      band: band,
                      cleared: controller.clearedIn(
                        band.firstLevel,
                        band.lastLevel,
                      ),
                      tokens: tokens,
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

  const _Masthead({required this.cleared, required this.stars});

  @override
  Widget build(BuildContext context) {
    final tokens = PourfectTokens.of(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        tokens.space4,
        tokens.space3,
        tokens.space4,
        tokens.space1,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('POURFECT', style: labelStyle(tokens)),
              SizedBox(height: tokens.space1),
              Text('Levels', style: titleStyle(tokens).copyWith(fontSize: 26)),
            ],
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('SOLVED', style: labelStyle(tokens)),
              SizedBox(height: tokens.space1),
              Text(
                '$cleared',
                style: numericStyle(
                  tokens,
                  size: 20,
                  color: tokens.textPrimary,
                ),
              ),
            ],
          ),
          SizedBox(width: tokens.space4),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('STARS', style: labelStyle(tokens)),
              SizedBox(height: tokens.space1),
              Text(
                '$stars',
                style: numericStyle(tokens, size: 20, color: tokens.accentWarm),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Sticky band header, so position in a 150-level list is always legible.
class _BandHeader extends SliverPersistentHeaderDelegate {
  final BandInfo band;
  final int cleared;
  final PourfectTokens tokens;

  _BandHeader({
    required this.band,
    required this.cleared,
    required this.tokens,
  });

  @override
  double get minExtent => _headerHeight;

  @override
  double get maxExtent => _headerHeight;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final done = cleared >= band.length;

    return Container(
      height: _headerHeight,
      padding: EdgeInsets.fromLTRB(
        tokens.space4,
        tokens.space3,
        tokens.space4,
        tokens.space2,
      ),
      // Opaque so pinned headers never let tiles show through behind them.
      color: tokens.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(band.name, style: titleStyle(tokens).copyWith(fontSize: 16)),
              SizedBox(width: tokens.space2),
              Expanded(
                child: Text(
                  band.shape.toUpperCase(),
                  style: labelStyle(tokens).copyWith(fontSize: 9.5),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
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
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: SizedBox(
              height: 2,
              child: Stack(
                children: [
                  Container(color: tokens.hairline),
                  FractionallySizedBox(
                    widthFactor: (cleared / band.length).clamp(0.0, 1.0),
                    child: Container(
                      color: done ? tokens.accentWarm : tokens.accent,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(_BandHeader old) =>
      old.cleared != cleared || old.band.index != band.index;
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

    final borderColour = solved
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
                    : tokens.tubeGlass.withValues(alpha: 0.04),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(3),
                  bottom: Radius.circular(12),
                ),
                border: Border.all(color: borderColour),
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
                    : solved
                    ? tokens.textMuted
                    : tokens.dimText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pip(Color colour) => Container(
    width: 9,
    height: 9,
    decoration: BoxDecoration(color: colour, shape: BoxShape.circle),
  );
}

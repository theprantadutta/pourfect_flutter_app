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
                    onOpenSettings: widget.onOpenSettings,
                  ),
                ),
                // ONE pinned bar, not one per band. Flutter's pinned slivers
                // STACK rather than pushing each other off, so a header per
                // band left four piled up at the bottom of a 150-level list,
                // eating a third of the screen.
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _CurrentBandBar(
                    controller: _controller!,
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
          SizedBox(width: tokens.space3),
          Pressable(
            onPressed: onOpenSettings,
            semanticLabel: 'Settings',
            child: Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Icon(
                Icons.tune_rounded,
                size: 22,
                color: tokens.textMuted,
              ),
            ),
          ),
        ],
      ),
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
                    : tokens.tubeGlass.withValues(alpha: 0.04),
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

  Widget _pip(Color color) => Container(
    width: 9,
    height: 9,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}

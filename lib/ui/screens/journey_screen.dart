/// The campaign as a path you travel, not a grid you scan.
///
/// This REPLACES the level grid rather than sitting in front of it. A hundred
/// and fifty numbered squares is a table of contents; the same hundred and
/// fifty as a climb makes level 96 feel far from level 3, which is the only
/// honest way to show a campaign that takes weeks. It is the pattern the
/// biggest games in this genre use, and they use it because progression IS the
/// meta-game.
///
/// Toybox layout: a header with the star total, a tilted blue World card for
/// the world on screen, then the path, with the world below it pinned as a
/// ribbon at the bottom. The path itself is painted rather than built — see
/// [JourneyPainter] for why 150 widgets would not survive the frame budget.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/level_repository.dart';
import '../../state/progress_repository.dart';
import '../../state/providers.dart';
import '../theme/ball_palette.dart';
import '../theme/toy.dart';
import '../widgets/journey_path.dart';
import '../widgets/toy_kit.dart';

class JourneyScreen extends ConsumerStatefulWidget {
  const JourneyScreen({
    super.key,
    required this.onOpenLevel,
    this.onBack,
    this.onOpenSettings,
    this.onOpenStatistics,
    this.onOpenDaily,
    this.onOpenLeaderboard,
    this.onOpenAccount,
  });

  final void Function(int levelId, Rect? origin) onOpenLevel;

  /// Pops the route when null.
  final VoidCallback? onBack;

  // The Toybox Journey is a map and nothing else: the settings, statistics,
  // daily, leaderboard and account entries moved to the home dock. These are
  // still accepted so the shell's call site keeps compiling, and are unused.
  final VoidCallback? onOpenSettings;
  final VoidCallback? onOpenStatistics;
  final VoidCallback? onOpenDaily;
  final VoidCallback? onOpenLeaderboard;
  final VoidCallback? onOpenAccount;

  @override
  ConsumerState<JourneyScreen> createState() => _JourneyScreenState();
}

/// Each world's banner ball: cream, carrying the world's own glyph, so the
/// four worlds differ by shape as well as by name.
const _worldGlyphs = [
  BallGlyph.square,
  BallGlyph.ring,
  BallGlyph.hexagon,
  BallGlyph.diamond,
];

class _JourneyScreenState extends ConsumerState<JourneyScreen>
    with SingleTickerProviderStateMixin {
  final _scroll = ScrollController();
  final _pathKey = GlobalKey();

  /// Index of the world whose levels are in the middle of the viewport.
  ///
  /// The World card follows the SCROLL, not the player's position. On open
  /// the two agree, because the path opens on the current level; once the
  /// player scrolls down to look at old levels, a card still saying "World 3"
  /// over a screen of World 1 tiles would be a label on the wrong map. A
  /// notifier rather than setState, so scrolling rebuilds two cards and not
  /// the screen.
  final _viewedBand = ValueNotifier<int>(-1);

  late final AnimationController _pulse;

  /// Set once the first layout has put the player where they actually are.
  bool _placed = false;

  /// Viewport height of the path area, from the last layout.
  double _viewport = 0;
  int _count = 0;
  List<BandInfo> _bands = const [];

  @override
  void initState() {
    super.initState();
    // 1.6s there and back: the current tile's halo, and the only thing on
    // this screen that animates.
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _scroll.addListener(_trackViewedBand);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reduced motion can change while the app is open, so this is re-checked
    // whenever MediaQuery does. Calm stops the ticker outright rather than
    // painting a frozen value every frame.
    if (Toy.calm(context)) {
      _pulse
        ..stop()
        ..value = 0;
    } else if (!_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    _scroll.dispose();
    _viewedBand.dispose();
    super.dispose();
  }

  int _bandOf(int levelId) {
    final i = _bands.indexWhere((b) => b.contains(levelId));
    return i < 0 ? 0 : i;
  }

  void _trackViewedBand() {
    if (!_scroll.hasClients || _count == 0) return;
    final centre = _scroll.offset + _viewport / 2;
    final fromBottom =
        (journeyHeight(_count) - kJourneyPadBottom - centre) / kJourneyStep;
    final id = (fromBottom.round() + 1).clamp(1, _count);
    final band = _bandOf(id);
    if (_viewedBand.value != band) _viewedBand.value = band;
  }

  double _offsetFor(int levelId) {
    final target = journeyPosition(levelId, _count, 0).dy - _viewport * 0.55;
    final max = journeyHeight(_count) - _viewport;
    return target.clamp(0.0, math.max(0.0, max));
  }

  /// Jumps to the player's current level without animating.
  ///
  /// The campaign is over 9,000px tall. Somebody on level 96 opening the
  /// screen to a slow scroll from the bottom would watch it travel for
  /// several seconds before they could do anything, so this is a jump and the
  /// animation is saved for when they have actually moved.
  void _placeAtCurrent(int current) {
    _scroll.jumpTo(_offsetFor(current));
    _placed = true;
    _trackViewedBand();
  }

  /// Scrolls down to the end of an earlier world, from the ribbon.
  void _goToLevel(int levelId) {
    final to = _offsetFor(levelId);
    if (Toy.calm(context)) {
      _scroll.jumpTo(to);
    } else {
      _scroll.animateTo(
        to,
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _onTap(
    Offset local,
    double width,
    bool Function(int) isUnlocked,
    int current,
  ) {
    final id = JourneyPainter.levelAt(local, _count, width);
    if (id == null || !isUnlocked(id)) return;

    // Grows the board out of the tile that was touched.
    Rect? origin;
    final box = _pathKey.currentContext?.findRenderObject();
    if (box is RenderBox && box.hasSize) {
      final tile = JourneyPainter.tileRect(
        id,
        _count,
        width,
        current: id == current,
      );
      origin = box.localToGlobal(tile.topLeft) & tile.size;
    }
    widget.onOpenLevel(id, origin);
  }

  @override
  Widget build(BuildContext context) {
    final levelSet = ref.watch(campaignProvider).asData?.value;
    final progress = ref.watch(progressProvider);
    final progressOps = ref.read(progressProvider.notifier);

    if (levelSet == null) {
      return const ToyScaffold(child: SizedBox.expand());
    }

    final count = levelSet.levels.length;
    final current = progressOps.furthestUnlocked;
    _count = count;
    _bands = campaignBands();
    if (_viewedBand.value < 0) _viewedBand.value = _bandOf(current);

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
      for (final band in _bands)
        JourneyBand(
          firstLevel: band.firstLevel,
          name: band.name,
          length: band.length,
          reached: current >= band.firstLevel,
        ),
    ];

    int solvedIn(BandInfo band) => progress.keys.where(band.contains).length;

    return ToyScaffold(
      padding: EdgeInsets.zero,
      safeBottom: false,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
            child: ToyHeader(
              title: 'Journey',
              centerTitle: true,
              onBack: widget.onBack,
              trailing: _StarTotal(stars: progressOps.totalStars),
            ),
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: ValueListenableBuilder<int>(
              valueListenable: _viewedBand,
              builder: (context, index, _) {
                final band = _bands[index.clamp(0, _bands.length - 1)];
                return _WorldCard(
                  world: band.index + 1,
                  worlds: _bands.length,
                  name: band.name,
                  solved: solvedIn(band),
                  total: band.length,
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final width = constraints.maxWidth;
                      _viewport = constraints.maxHeight;

                      if (!_placed) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted && _scroll.hasClients && !_placed) {
                            _placeAtCurrent(current);
                          }
                        });
                      }

                      return SingleChildScrollView(
                        controller: _scroll,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTapUp: (details) => _onTap(
                            details.localPosition,
                            width,
                            progressOps.isUnlocked,
                            current,
                          ),
                          child: SizedBox(
                            key: _pathKey,
                            width: width,
                            height: journeyHeight(count),
                            child: AnimatedBuilder(
                              animation: Listenable.merge([_pulse, _scroll]),
                              builder: (context, _) {
                                final offset = _scroll.hasClients
                                    ? _scroll.offset
                                    : 0.0;
                                return CustomPaint(
                                  size: Size(width, journeyHeight(count)),
                                  painter: JourneyPainter(
                                    levels: levels,
                                    bands: bands,
                                    pulse: _pulse.value,
                                    visibleTop: offset,
                                    visibleBottom: offset + _viewport,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Positioned(
                  left: 20,
                  right: 20,
                  bottom: 18 + MediaQuery.paddingOf(context).bottom,
                  child: ValueListenableBuilder<int>(
                    valueListenable: _viewedBand,
                    builder: (context, index, _) {
                      // The world BELOW the one on screen: the ground already
                      // covered. Nothing is below World 1.
                      if (index < 1) return const SizedBox.shrink();
                      final band = _bands[index - 1];
                      return _WorldRibbon(
                        world: band.index + 1,
                        name: band.name,
                        solved: solvedIn(band),
                        total: band.length,
                        onTap: () => _goToLevel(band.lastLevel),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// "51 ★" — the player's star total, top right.
class _StarTotal extends StatelessWidget {
  const _StarTotal({required this.stars});

  final int stars;

  @override
  Widget build(BuildContext context) => Semantics(
    label: '$stars stars',
    excludeSemantics: true,
    child: ToyBox(
      height: 36,
      radius: 12,
      color: Toy.yellow,
      shadow: 0,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$stars', style: Toy.numbers(14)),
          const SizedBox(width: 4),
          const ToyStar(size: 14, fill: Toy.ink, outlined: false),
        ],
      ),
    ),
  );
}

/// The blue World card: which world is on screen, and how far through it.
class _WorldCard extends StatelessWidget {
  const _WorldCard({
    required this.world,
    required this.worlds,
    required this.name,
    required this.solved,
    required this.total,
  });

  final int world;
  final int worlds;
  final String name;
  final int solved;
  final int total;

  @override
  Widget build(BuildContext context) {
    final glyph = _worldGlyphs[(world - 1) % _worldGlyphs.length];

    return Semantics(
      label: 'World $world of $worlds, $name, $solved of $total solved',
      excludeSemantics: true,
      child: Transform.rotate(
        angle: -1 * math.pi / 180,
        child: ToyBox(
          color: Toy.blue,
          radius: 22,
          shadow: 5,
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Row(
            children: [
              ToyBall(color: Toy.cream, glyph: glyph, size: 48),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Expanded(
                          child: Text(
                            'WORLD $world OF $worlds',
                            style: Toy.caps(color: Colors.white)
                                .copyWith(letterSpacing: 1.5),
                          ),
                        ),
                        Text(
                          '$solved / $total',
                          style: Toy.numbers(
                            12,
                            color: Colors.white,
                            weight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        name,
                        maxLines: 1,
                        style: Toy.display(24, color: Colors.white, shadow: 2),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ToyProgressBar(
                      value: total == 0 ? 0 : solved / total,
                      height: 10,
                      track: const Color(0x59FFFFFF),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The world below the one on screen, pinned at the bottom. Mint with a tick
/// once it is finished; tapping it scrolls down to its last level.
class _WorldRibbon extends StatelessWidget {
  const _WorldRibbon({
    required this.world,
    required this.name,
    required this.solved,
    required this.total,
    required this.onTap,
  });

  final int world;
  final String name;
  final int solved;
  final int total;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final complete = solved >= total;
    final style = Toy.ui(13, weight: FontWeight.w800);

    return Pressable(
      onPressed: onTap,
      semanticLabel:
          'World $world, $name, $solved of $total solved. Scroll to it',
      child: ToyBox(
        color: complete ? Toy.mint : Toy.card,
        radius: Toy.rButton,
        shadow: 4,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'WORLD $world · ${name.toUpperCase()}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: style,
              ),
            ),
            const SizedBox(width: 8),
            Text('$solved/$total', style: Toy.numbers(13)),
            if (complete) ...[
              const SizedBox(width: 4),
              const ToyIcon(ToyGlyph.check, size: 15),
            ],
          ],
        ),
      ),
    );
  }
}

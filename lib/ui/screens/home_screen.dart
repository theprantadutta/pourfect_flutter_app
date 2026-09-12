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

import 'dart:async';

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
      // ONE SCREEN, and only the path moves.
      //
      // The whole thing used to be a ListView, so the board and the primary
      // action scrolled away together and the screen had no fixed shape. A
      // game's home is a place: what you are playing and the button that
      // plays it stay put, and the road ahead is the part you travel.
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                tokens.space4, tokens.space3, tokens.space4, 0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _TopRow(
                    onOpenAccount: onOpenAccount,
                    onOpenSettings: onOpenSettings,
                  ),

                  SizedBox(height: tokens.space4),
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

                  SizedBox(height: tokens.space4),

                  // The board, ON the ground. No panel, no frame, no border — the
                  // tubes are the containers and wrapping them in another one is
                  // exactly the app furniture this screen exists to remove.
                  if (board != null)
                    Center(
                      child: BoardPreview(
                  board: board,
                  // 25, measured off the reference rather than guessed: the
                  // ball is 68px on a 1080-wide design, which is 25 logical
                  // pixels at this density. It was 44, and the board ate the
                  // room the path needs.
                  ballSize: board.tubeCount <= 6 ? 25 : 20,
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

                  SizedBox(height: tokens.space4),
                  Text(
                    'THE WAY AHEAD',
                    style: labelStyle(tokens).copyWith(letterSpacing: 1.8),
                  ),
                ],
              ),
            ),

            // Everything left over, and the only thing that scrolls.
            Expanded(
              child: _JourneyStrip(
                levelSet: levelSet,
                current: current,
                onOpenLevel: onOpenLevel,
              ),
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

    // The name sits BETWEEN the two controls rather than on a line of its own.
    //
    // A 44px wordmark below the row had presence and cost a whole band of
    // vertical space, which on this screen comes straight out of the path. A
    // centred title is the ordinary game-header shape and buys that back.
    //
    // Stack rather than Row, so the title is centred on the SCREEN and not on
    // whatever is left between two controls of different widths — with a Row
    // it would drift left or right as the crest appears and disappears.
    return SizedBox(
      height: 44,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Text(
            'Pourfect',
            style: titleStyle(tokens).copyWith(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.4,
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: account.available
                ? Pressable(
                    onPressed: onOpenAccount,
                    semanticLabel: account.signedIn
                        ? 'Your account'
                        : 'Save your progress',
                    child: PlayerCrest(
                      seed: session?.userId,
                      signedIn: account.signedIn,
                      size: 38,
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Pressable(
              onPressed: onOpenSettings,
              semanticLabel: 'Settings',
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
            child: played
                ? Figure(
                    label: "TODAY'S CHALLENGE",
                    value: 'SOLVED',
                    color: tokens.textMuted,
                    stacked: true,
                  )
                : const _DailyCountdown(),
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

/// How long today's board has left.
///
/// A challenge that is merely "open" says nothing about whether to play it now.
/// The clock is the whole reason a daily works, so it is on the screen rather
/// than discoverable by opening it.
///
/// Counts to the next UTC midnight, because that is when the SERVER rolls the
/// board over. A local-midnight countdown would hit zero at the wrong moment
/// for everybody outside UTC and read as broken.
///
/// Its own widget so the per-second rebuild is confined to eight characters
/// rather than dragging the screen through a frame.
class _DailyCountdown extends StatefulWidget {
  const _DailyCountdown();

  @override
  State<_DailyCountdown> createState() => _DailyCountdownState();
}

class _DailyCountdownState extends State<_DailyCountdown> {
  Timer? _tick;
  late Duration _left = _remaining();

  static Duration _remaining() {
    final now = DateTime.now().toUtc();
    final midnight = DateTime.utc(now.year, now.month, now.day + 1);
    return midnight.difference(now);
  }

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _left = _remaining());
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = PourfectTokens.of(context);
    String two(int v) => v.toString().padLeft(2, '0');

    return Figure(
      label: "TODAY'S CHALLENGE",
      value: '${two(_left.inHours)}:${two(_left.inMinutes % 60)}'
          ':${two(_left.inSeconds % 60)}',
      color: tokens.accentWarm,
      stacked: true,
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

/// The campaign path, in whatever room the fixed head leaves.
///
/// The real thing rather than a preview: it scrolls, it opens levels, and it
/// uses the same painter and the same geometry as the full-screen journey, so
/// the two cannot disagree about where a level sits.
///
/// Opens centred on the player. The campaign is roughly 10,000px tall and
/// somebody on level 96 should not arrive at the bottom of it.
class _JourneyStrip extends ConsumerStatefulWidget {
  const _JourneyStrip({
    required this.levelSet,
    required this.current,
    required this.onOpenLevel,
  });

  final dynamic levelSet;
  final int current;
  final void Function(int levelId, Rect? origin) onOpenLevel;

  @override
  ConsumerState<_JourneyStrip> createState() => _JourneyStripState();
}

class _JourneyStripState extends ConsumerState<_JourneyStrip>
    with SingleTickerProviderStateMixin {
  final _scroll = ScrollController();
  late final AnimationController _pulse;
  bool _placed = false;

  @override
  void initState() {
    super.initState();
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

  @override
  Widget build(BuildContext context) {
    final tokens = PourfectTokens.of(context);
    if (widget.levelSet == null) return const SizedBox.shrink();

    final count = widget.levelSet.levels.length as int;
    final current = widget.current;
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

    final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final viewport = constraints.maxHeight;

        if (!_placed) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted || !_scroll.hasClients || _placed) return;
            final target =
                journeyPosition(current, count, width).dy - viewport * 0.46;
            final max = journeyHeight(count) - viewport;
            _scroll.jumpTo(target.clamp(0.0, max < 0 ? 0.0 : max));
            _placed = true;
          });
        }

        return ClipRect(
          child: Stack(
            children: [
              SingleChildScrollView(
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
                      animation: Listenable.merge([_pulse, _scroll]),
                      builder: (context, _) {
                        final offset = _scroll.hasClients ? _scroll.offset : 0.0;
                        return CustomPaint(
                          size: Size(width, journeyHeight(count)),
                          painter: JourneyPainter(
                            levels: levels,
                            bands: bands,
                            tokens: tokens,
                            boldGlyphs:
                                ref.watch(settingsProvider).boldSymbols,
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
              // The path runs off rather than stopping at a line. A hard edge
              // would read as the top of a card.
              const _EdgeFade(top: true),
            ],
          ),
        );
      },
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

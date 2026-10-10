/// What the game opens on.
///
/// A toy box: every piece is a chunky object with an ink outline and a hard
/// shadow, on the dotted cream ground. The previous hub was built to have no
/// boxes at all, and read as calm but inert; this one is built so that every
/// thing that can be tapped LOOKS like something you could pick up.
///
/// The order is what a returning player cares about, in that order:
///
///  1. **Who you are** — the player chip, and the brand, and what you have
///     accumulated in three colored chips.
///  2. **The board you are on**, in the one white hero card, with PLAY as the
///     only tomato on the screen.
///  3. **What is live today** — the blue daily card and your rank.
///  4. **Everywhere else** — a dock of three buttons. The campaign path that
///     used to fill the bottom of the hub lives on Journey now, one tap away.
library;

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/ads/ad_service.dart';
import '../../state/account_controller.dart';
import '../../state/daily_controller.dart';
import '../../state/event_controller.dart';
import '../../state/zen.dart';
import '../../state/monetization_controller.dart';
import '../../state/onboarding.dart';
import '../../state/play_history.dart';
import '../../state/progress_repository.dart';
import '../../state/providers.dart';
import '../../state/streak_controller.dart';
import '../theme/ball_palette.dart';
import '../theme/toy.dart';
import '../transitions.dart';
import '../widgets/daily_card.dart';
import 'event_screen.dart';
import 'zen_screen.dart';
import '../widgets/next_level_hero.dart';
import '../widgets/player_crest.dart';
import '../widgets/streak_dialog.dart';
import '../widgets/more_levels_card.dart';
import '../widgets/toy_kit.dart';
import '../widgets/tutorial.dart';

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
    final levelSet = ref.watch(campaignProvider).asData?.value;
    final progress = ref.watch(progressProvider);
    final progressOps = ref.read(progressProvider.notifier);
    ref.watch(playHistoryProvider);
    final history = ref.read(playHistoryProvider.notifier);

    final current = progressOps.furthestUnlocked;
    final level = levelSet?.byId(current)?.level;
    final bands = ref.watch(campaignBandsProvider);
    final band = bands.where((b) => b.contains(current)).firstOrNull;

    Widget hero({required bool expand}) => NextLevelHero(
      levelId: current,
      board: level!.board,
      par: level.minMoves,
      world: (band?.index ?? 0) + 1,
      bandName: band?.name ?? '',
      boldGlyphs: ref.watch(settingsProvider).boldSymbols,
      onPlay: (origin) => onOpenLevel(current, origin),
      expand: expand,
    );

    final top = <Widget>[
      _TopRow(onOpenAccount: onOpenAccount, onOpenSettings: onOpenSettings),
      const SizedBox(height: 16),
      const _Wordmark(),
      const SizedBox(height: 14),
      _StatChips(
        solved: progress.length,
        stars: progressOps.totalStars,
        streak: history.currentStreak(),
        onOpenStatistics: onOpenStatistics,
      ),
      const SizedBox(height: 14),
    ];
    final daily = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _Daily(onOpenDaily: onOpenDaily, onOpenLeaderboard: onOpenLeaderboard),
        const _Extras(),
      ],
    );
    final foot = <Widget>[
      const SizedBox(height: 14),
      _Dock(
        onOpenJourney: onOpenJourney,
        onOpenLeaderboard: onOpenLeaderboard,
        onOpenStatistics: onOpenStatistics,
      ),
      // The dock's hard shadow paints below its layout box; this keeps the
      // scroll view's clip from shaving it.
      const SizedBox(height: 6),
    ];

    return ToyScaffold(
      padding: EdgeInsets.zero,
      child: Stack(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              // A TALL PHONE fills its height: the hero card takes every spare
              // pixel and grows the board into it. Stacking the content at the top
              // and pinning the dock to the floor left a dead band of cream above
              // the dock that read as a layout bug — measured at ~100dp on the
              // A24, and more on taller phones.
              //
              // Below [_fillFrom] the content is laid out at its natural size and
              // scrolls, because a squeezed toy stops looking like a toy and an
              // overflow stripe is worse than either.
              if (level != null && constraints.maxHeight >= _fillFrom) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(20, 6, 20, 14),
                  // The hero grows its board into the spare height as far as the
                  // board can use it; whatever is still left is shared equally
                  // between the sections, so nothing collects in one dead band.
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: top.sublist(0, top.length - 1),
                      ),
                      Flexible(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          child: hero(expand: true),
                        ),
                      ),
                      daily,
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: foot,
                      ),
                    ],
                  ),
                );
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 6, 20, 14),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: math.max(0, constraints.maxHeight - 20),
                  ),
                  // spaceBetween on an unbounded Column sizes it to the larger of
                  // its content and minHeight, so the dock sits on the floor and
                  // follows the content on a short phone.
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ...top,
                          // Absent only for the few frames before the bundled
                          // campaign has decoded; the card would otherwise flash
                          // a board-less shell.
                          if (level != null) ...[
                            hero(expand: false),
                            const SizedBox(height: 14),
                          ] else if (levelSet != null) ...[
                            // Everything on this phone is cleared.
                            const MoreLevelsCard(),
                            const SizedBox(height: 14),
                          ],
                          daily,
                        ],
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: foot,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          // Over the layout, not in it: a one-time bubble must not shove the
          // hub around when it appears and again when it goes.
          const Positioned(left: 20, right: 20, bottom: 96, child: _HubTip()),
        ],
      ),
    );
  }

  /// The height at which the hub stops scrolling and fills the screen. The
  /// natural layout needs about 700dp with the board preview at its smallest,
  /// so anything taller has room for the board to grow.
  static const double _fillFrom = 700;
}

class _TopRow extends ConsumerWidget {
  const _TopRow({required this.onOpenAccount, required this.onOpenSettings});

  final VoidCallback onOpenAccount;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final account = ref.watch(accountProvider);

    return Row(
      children: [
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            // Absent in a build with no Firebase: there is no account to open.
            child: !account.available
                ? null
                : Pressable(
                    onPressed: onOpenAccount,
                    semanticLabel: account.signedIn
                        ? 'Your account'
                        : 'Save your progress',
                    child: ToyBox(
                      radius: Toy.rButton,
                      shadow: 3,
                      padding: const EdgeInsets.fromLTRB(4, 4, 12, 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          PlayerCrest(
                            seed: account.userId,
                            photoUrl: account.photoUrl,
                            signedIn: account.signedIn,
                            size: 30,
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              // The server names every account at creation, so a
                              // null handle only ever means "not loaded yet".
                              account.handle ?? 'Player',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Toy.ui(14, weight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
        ),
        const SizedBox(width: 12),
        ToySquareButton(
          semanticLabel: 'Settings',
          onPressed: onOpenSettings,
          child: const _MenuBars(),
        ),
      ],
    );
  }
}

/// Three 16×2.5 bars, 4px apart — the mockup's menu mark, drawn with the ink
/// stroke weight so it matches every outline around it.
class _MenuBars extends StatelessWidget {
  const _MenuBars();

  @override
  Widget build(BuildContext context) {
    Widget bar() => Container(
      width: 16,
      height: 2.5,
      decoration: BoxDecoration(
        color: Toy.ink,
        borderRadius: BorderRadius.circular(2),
      ),
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        bar(),
        const SizedBox(height: 4),
        bar(),
        const SizedBox(height: 4),
        bar(),
      ],
    );
  }
}

/// The Ball-O wordmark: "P", an amber dot ball, "urfect".
///
/// Built from type and a painted ball rather than the PNG so the ball can
/// move: it drops into the word and bounces twice on the first frame, which
/// is the splash's own ball arriving where it belongs.
class _Wordmark extends StatefulWidget {
  const _Wordmark();

  @override
  State<_Wordmark> createState() => _WordmarkState();
}

class _WordmarkState extends State<_Wordmark>
    with SingleTickerProviderStateMixin {
  late final AnimationController _drop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    // Reduced motion lands the ball where it ends up. Nothing is lost: the
    // bounce says nothing the resting wordmark does not.
    if (Toy.calm(context)) {
      _drop.value = 1;
    } else {
      _drop.forward();
    }
  }

  @override
  void dispose() {
    _drop.dispose();
    super.dispose();
  }

  /// Height above rest, in px, at [t] of the drop: a fall, then two hops,
  /// each lower than the last. Parabolas throughout, so it reads as gravity.
  static double _lift(double t) {
    const fall = 0.46;
    const hop1 = 0.76;
    if (t < fall) {
      final s = t / fall;
      return 110 * (1 - s * s);
    }
    if (t < hop1) {
      final s = (t - fall) / (hop1 - fall);
      return 18 * 4 * s * (1 - s);
    }
    final s = (t - hop1) / (1 - hop1);
    return 6 * 4 * s * (1 - s);
  }

  @override
  Widget build(BuildContext context) {
    final type = Toy.display(60, color: Toy.tomato, shadow: 3);

    return Semantics(
      label: 'Pourfect',
      header: true,
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('P', style: type),
                Padding(
                  padding: const EdgeInsets.fromLTRB(2, 13, 2, 0),
                  child: AnimatedBuilder(
                    animation: _drop,
                    builder: (context, child) => Transform.translate(
                      offset: Offset(0, -_lift(_drop.value)),
                      child: child,
                    ),
                    child: ToyBall(
                      color: Toy.yellow,
                      glyph: BallGlyph.dot,
                      size: 44,
                      drop: true,
                    ),
                  ),
                ),
                Text('urfect', style: type),
              ],
            ),
          ),
          const SizedBox(height: 6),
          // The tagline is the screen's one tilted strip; the rank sticker is
          // the other. Two is the ceiling.
          Transform.rotate(
            angle: -2 * math.pi / 180,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: Toy.ink,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'POUR · SORT · RELAX',
                style: Toy.ui(
                  13,
                  weight: FontWeight.w800,
                  color: Toy.cream,
                  letterSpacing: 2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Solved, stars, streak: three toy blocks, and each one opens Statistics.
///
/// They were plain figures with a chevron, and read as a caption — "how do I
/// get to the statistics screen" was a real report. A chunky block with a
/// shadow does not need a chevron to say it can be pressed.
class _StatChips extends StatelessWidget {
  const _StatChips({
    required this.solved,
    required this.stars,
    required this.streak,
    required this.onOpenStatistics,
  });

  final int solved;
  final int stars;
  final int streak;
  final VoidCallback onOpenStatistics;

  @override
  Widget build(BuildContext context) {
    Widget chip(Color color, String value, String label, {bool star = false}) =>
        Expanded(
          child: Pressable(
            onPressed: onOpenStatistics,
            semanticLabel: '$value $label. Statistics',
            child: ToyBox(
              color: color,
              radius: Toy.rButton,
              shadow: 3,
              padding: const EdgeInsets.fromLTRB(10, 7, 10, 7),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(value, maxLines: 1, style: Toy.numbers(22)),
                        // Painted rather than typed: Outfit has no ★, and the
                        // fallback font's star sits on a different baseline on
                        // every device.
                        if (star)
                          const Padding(
                            padding: EdgeInsets.only(left: 1),
                            child: ToyStar(
                              size: 20,
                              fill: Toy.ink,
                              outlined: false,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Text(label, style: Toy.ui(12)),
                ],
              ),
            ),
          ),
        );

    return Row(
      children: [
        chip(Toy.yellow, '$solved', 'solved'),
        const SizedBox(width: 8),
        chip(Toy.pink, '$stars', 'stars', star: true),
        const SizedBox(width: 8),
        // Always shown, zero included. The old row dropped the streak at 0,
        // which here would leave a hole in a row of three.
        chip(Toy.mint, streak == 1 ? '1 day' : '$streak days', 'streak'),
      ],
    );
  }
}

/// The daily card, fed from the providers, or nothing in a build without a
/// server.
class _Daily extends ConsumerWidget {
  const _Daily({required this.onOpenDaily, required this.onOpenLeaderboard});

  final VoidCallback onOpenDaily;
  final VoidCallback onOpenLeaderboard;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final daily = ref.watch(dailyProvider);

    // A build with no server has no daily and no ranks, and a card that
    // never works is worse than no card.
    if (daily.isOff) return const SizedBox.shrink();

    return DailyCard(
      played: daily.challenge?.isPlayed,
      stars: daily.challenge?.yourAttempt?.stars,
      unavailable: daily.isUnavailable,
      rank: switch (ref.watch(dailyRankProvider)) {
        AsyncData(:final value?) => value,
        _ => null,
      },
      onOpenDaily: onOpenDaily,
      onOpenLeaderboard: onOpenLeaderboard,
      streak: ref.watch(streakProvider)?.current,
      onOpenStreak: () => showStreakDialog(
        context,
        watchVideo: () => ref
            .read(monetizationProvider.notifier)
            .offerRewarded(RewardedPlacement.streakFreeze, levelId: 0),
      ),
    );
  }
}

/// This week's event, under the daily: seven boards, one week, one board.
/// Nothing at all when there is no server or no event yet.
/// The weekly event and Zen, side by side and compact: the hub does not
/// scroll, and stacking two more full-width cards squeezed the hero board out
/// of its card. Zen takes the whole row when there is no event to show.
class _Extras extends ConsumerWidget {
  const _Extras();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasEvent = ref.watch(eventProvider.select((e) => e.event != null));
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (hasEvent) ...[
              const Expanded(child: _Event()),
              const SizedBox(width: 12),
            ],
            const Expanded(child: _Zen()),
          ],
        ),
      ),
    );
  }
}

class _Event extends ConsumerWidget {
  const _Event();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final event = ref.watch(eventProvider).event;
    if (event == null) {
      // No server or no event yet: keep the slot so Zen does not stretch.
      return const SizedBox.shrink();
    }

    return Pressable(
      onPressed: () => Navigator.of(context).push(
        PourfectPageRoute<void>(
          builder: (route) =>
              EventScreen(onClose: () => Navigator.of(route).maybePop()),
        ),
      ),
      semanticLabel: 'Weekly event, ${event.cleared} of 7 boards',
      child: ToyBox(
        color: Toy.mint,
        radius: 20,
        shadow: 5,
        padding: const EdgeInsets.fromLTRB(14, 10, 12, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              event.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Toy.display(17, height: 1.1),
            ),
            const SizedBox(height: 2),
            Text(
              '${event.cleared}/${event.boards.length}'
              '${event.rank == null ? '' : ' · #${event.rank}'}'
              ' · ${eventEndsIn(event.endsAt).replaceFirst('ends in ', '')}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Toy.ui(12, weight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }
}

class _Zen extends ConsumerWidget {
  const _Zen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cleared = ref.watch(progressProvider).length;
    final open = cleared >= kZenUnlockLevel;
    final ink = open ? Colors.white : Toy.inkMuted;

    return Pressable(
      onPressed: open
          ? () => Navigator.of(context).push(
              PourfectPageRoute<void>(
                builder: (route) =>
                    ZenScreen(onExit: () => Navigator.of(route).maybePop()),
              ),
            )
          : null,
      semanticLabel: open
          ? 'Zen mode'
          : 'Zen mode unlocks at level $kZenUnlockLevel',
      child: ToyBox(
        color: open ? Toy.lilac : Toy.card,
        radius: 20,
        shadow: open ? 5 : 3,
        padding: const EdgeInsets.fromLTRB(14, 10, 12, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Zen',
                    style: Toy.display(17, height: 1.1, color: ink),
                  ),
                ),
                if (!open) const ToyIcon(ToyGlyph.lock, size: 14),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              open
                  ? 'Endless, no clock'
                  : 'Level $kZenUnlockLevel · ${kZenUnlockLevel - cleared} to go',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Toy.ui(12, weight: FontWeight.w800, color: ink),
            ),
          ],
        ),
      ),
    );
  }
}

/// Journey, Rankings, Stats. Each carries a small toy ball in place of an
/// icon, so the dock is made of the game's own objects.
class _Dock extends StatelessWidget {
  const _Dock({
    required this.onOpenJourney,
    required this.onOpenLeaderboard,
    required this.onOpenStatistics,
  });

  final VoidCallback onOpenJourney;
  final VoidCallback onOpenLeaderboard;
  final VoidCallback onOpenStatistics;

  @override
  Widget build(BuildContext context) {
    Widget button(
      String label,
      Color color,
      BallGlyph glyph,
      VoidCallback onPressed,
    ) => Expanded(
      child: Pressable(
        onPressed: onPressed,
        semanticLabel: label,
        child: ToyBox(
          height: 66,
          radius: Toy.rControl,
          shadow: 4,
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          // Scales down rather than overflowing the fixed height when the
          // system font is set large.
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ToyBall(color: color, glyph: glyph, size: 26),
                const SizedBox(height: 4),
                Text(label, style: Toy.ui(13, weight: FontWeight.w800)),
              ],
            ),
          ),
        ),
      ),
    );

    return Row(
      children: [
        button('Journey', Toy.mint, BallGlyph.square, onOpenJourney),
        const SizedBox(width: 10),
        button('Rankings', Toy.yellow, BallGlyph.diamond, onOpenLeaderboard),
        const SizedBox(width: 10),
        button('Stats', Toy.pink, BallGlyph.bar, onOpenStatistics),
      ],
    );
  }
}

/// The one-time hub bubble after the first win: where the rest of the game is.
///
/// Only for a genuinely new player (one to three levels cleared). Somebody
/// updating with fifty levels behind them knows where Journey is.
class _HubTip extends ConsumerStatefulWidget {
  const _HubTip();

  @override
  ConsumerState<_HubTip> createState() => _HubTipState();
}

class _HubTipState extends ConsumerState<_HubTip> {
  bool _asked = false;
  bool _showing = false;
  Timer? _hide;

  @override
  void dispose() {
    _hide?.cancel();
    super.dispose();
  }

  Future<void> _claim() async {
    if (!await ref.read(onboardingProvider.notifier).claim(Tip.hub)) return;
    if (!mounted) return;
    setState(() => _showing = true);
    _hide = Timer(const Duration(seconds: 9), _dismiss);
  }

  void _dismiss() {
    _hide?.cancel();
    if (mounted) setState(() => _showing = false);
  }

  @override
  Widget build(BuildContext context) {
    final onboarding = ref.watch(onboardingProvider);
    final solved = ref.watch(progressProvider).length;
    if (!_asked &&
        onboarding.loaded &&
        !onboarding.hasSeen(Tip.hub) &&
        solved >= 1 &&
        solved <= 3) {
      _asked = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _claim());
    }

    return IgnorePointer(
      ignoring: !_showing,
      child: AnimatedOpacity(
        duration: Toy.calm(context)
            ? Duration.zero
            : const Duration(milliseconds: 220),
        opacity: _showing ? 1 : 0,
        child: TipBubble(
          text:
              'Nice! Journey maps every level, and there\'s a new '
              'Daily Pour to play each day.',
          onDismiss: _dismiss,
        ),
      ),
    );
  }
}

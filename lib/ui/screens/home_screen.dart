/// The hub. What the game opens on.
///
/// It used to open straight into the level list, and that single fact was most
/// of why the app read as a utility rather than a game: you launched it and got
/// a table of contents. A game opens on a place — who you are, where you got
/// to, and one obvious thing to press.
///
/// **The restraint is not the problem and is not being traded away.** The
/// palette, the hairlines and the near-black ground all stay exactly as they
/// were; what this adds is the furniture a calm game still needs and this one
/// did not have. Meditation apps and premium habit trackers — the references
/// this design has always cited — all show you an identity, a streak and a
/// number you are trying to move. None of them look like a toy.
///
/// Four things, in the order a returning player cares about them:
///
///  1. **Who you are**, with your progress beside it. Signing in used to change
///     nothing visible anywhere in the app.
///  2. **Continue**, the single primary action, naming the actual level.
///  3. **Today**, because a daily challenge nobody can see is not a reason to
///     come back.
///  4. **Everything else**, small and equal — levels, stats, leaderboard.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/account_controller.dart';
import '../../state/daily_controller.dart';
import '../../state/play_history.dart';
import '../../state/progress_repository.dart';
import '../../state/providers.dart';
import '../theme/tokens.dart';
import '../theme/typography.dart';
import '../widgets/player_crest.dart';
import '../widgets/pressable.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({
    super.key,
    required this.onContinue,
    required this.onOpenLevels,
    required this.onOpenDaily,
    required this.onOpenStatistics,
    required this.onOpenLeaderboard,
    required this.onOpenSettings,
    required this.onOpenAccount,
  });

  final void Function(int levelId) onContinue;
  final VoidCallback onOpenLevels;
  final VoidCallback onOpenDaily;
  final VoidCallback onOpenStatistics;
  final VoidCallback onOpenLeaderboard;
  final VoidCallback onOpenSettings;
  final VoidCallback onOpenAccount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = PourfectTokens.of(context);

    final progress = ref.watch(progressProvider);
    final progressOps = ref.read(progressProvider.notifier);
    ref.watch(playHistoryProvider);
    final history = ref.read(playHistoryProvider.notifier);
    final account = ref.watch(accountProvider);
    final session = ref.watch(authServiceProvider).current;

    final next = progressOps.furthestUnlocked;
    final stars = progressOps.totalStars;
    final streak = history.currentStreak();
    final solved = progress.length;

    return Scaffold(
      backgroundColor: tokens.surface,
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            tokens.space4, tokens.space4, tokens.space4, tokens.space5,
          ),
          children: [
            _Identity(
              name: session?.displayName,
              signedIn: account.signedIn,
              seed: session?.userId,
              onTap: account.signedIn ? onOpenSettings : onOpenAccount,
            ),

            SizedBox(height: tokens.space4),
            _StatStrip(stars: stars, solved: solved, streak: streak),

            SizedBox(height: tokens.space5),
            _ContinueCard(level: next, onTap: () => onContinue(next)),

            SizedBox(height: tokens.space4),
            _TodayCard(onTap: onOpenDaily),

            SizedBox(height: tokens.space4),
            Row(
              children: [
                Expanded(child: _Tile(label: 'Levels', onTap: onOpenLevels)),
                SizedBox(width: tokens.space3),
                Expanded(child: _Tile(label: 'Stats', onTap: onOpenStatistics)),
                SizedBox(width: tokens.space3),
                Expanded(
                  child: _Tile(label: 'Ranks', onTap: onOpenLeaderboard),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// The crest, the name, and what tapping it does.
///
/// For an anonymous player the subtitle is an invitation rather than a warning.
/// It says what an account actually buys — a new phone keeps your stars — and
/// nothing stronger, because that is the whole of the promise.
class _Identity extends StatelessWidget {
  const _Identity({
    required this.name,
    required this.signedIn,
    required this.seed,
    required this.onTap,
  });

  final String? name;
  final bool signedIn;
  final String? seed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = PourfectTokens.of(context);

    return Pressable(
      onPressed: onTap,
      semanticLabel: signedIn ? 'Your account' : 'Save your progress',
      scale: 0.99,
      child: Row(
        children: [
          PlayerCrest(seed: seed, signedIn: signedIn, size: 48),
          SizedBox(width: tokens.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name ?? (signedIn ? 'Signed in' : 'Playing as a guest'),
                  style: titleStyle(tokens).copyWith(fontSize: 18),
                ),
                SizedBox(height: tokens.space1),
                Text(
                  signedIn
                      ? 'Your progress moves with your account.'
                      : 'Keep your stars if you change phones.',
                  style: bodyStyle(tokens).copyWith(fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Three numbers, monospaced.
///
/// Numerals are the one thing this game has always set in JetBrains Mono, and
/// they are what a player is actually accumulating. Showing them on the hub is
/// the difference between progress existing and progress being visible.
class _StatStrip extends StatelessWidget {
  const _StatStrip({
    required this.stars,
    required this.solved,
    required this.streak,
  });

  final int stars;
  final int solved;
  final int streak;

  @override
  Widget build(BuildContext context) {
    final tokens = PourfectTokens.of(context);

    return Container(
      padding: EdgeInsets.symmetric(vertical: tokens.space3),
      decoration: BoxDecoration(
        color: tokens.surfaceRaised,
        borderRadius: BorderRadius.circular(tokens.panelRadius),
        border: Border.all(color: tokens.hairline),
      ),
      child: Row(
        children: [
          Expanded(child: _Stat(value: '$stars', label: 'Stars')),
          _Divider(),
          Expanded(child: _Stat(value: '$solved', label: 'Solved')),
          _Divider(),
          Expanded(
            child: _Stat(
              value: '$streak',
              label: streak == 1 ? 'Day' : 'Days',
              // The only warm accent on the screen, and only when it has
              // actually been earned. A streak of zero is not a celebration.
              highlight: streak > 0,
            ),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final tokens = PourfectTokens.of(context);
    return Container(width: 1, height: 28, color: tokens.hairline);
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.value,
    required this.label,
    this.highlight = false,
  });

  final String value;
  final String label;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final tokens = PourfectTokens.of(context);

    return Column(
      children: [
        Text(
          value,
          style: numericStyle(tokens).copyWith(
            fontSize: 22,
            color: highlight ? tokens.accentWarm : tokens.textNumeric,
          ),
        ),
        SizedBox(height: tokens.space1),
        Text(label, style: labelStyle(tokens)),
      ],
    );
  }
}

/// The primary action, and the only filled control on the screen.
class _ContinueCard extends StatelessWidget {
  const _ContinueCard({required this.level, required this.onTap});

  final int level;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = PourfectTokens.of(context);

    return Pressable(
      onPressed: onTap,
      semanticLabel: 'Continue, level $level',
      child: Container(
        padding: EdgeInsets.all(tokens.space4),
        decoration: BoxDecoration(
          color: tokens.accent,
          borderRadius: BorderRadius.circular(tokens.panelRadius),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Continue',
                    style: titleStyle(tokens).copyWith(
                      color: tokens.surface,
                      fontSize: 20,
                    ),
                  ),
                  SizedBox(height: tokens.space1),
                  Text(
                    'Level $level',
                    style: numericStyle(tokens).copyWith(
                      color: tokens.surface.withValues(alpha: 0.75),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.play_arrow_rounded, color: tokens.surface, size: 32),
          ],
        ),
      ),
    );
  }
}

/// Today's challenge, surfaced.
///
/// The backend has generated these for weeks and nothing on the way in
/// mentioned them. A daily a player has to go looking for is not a reason to
/// open the app tomorrow, which is the entire point of having one.
class _TodayCard extends ConsumerWidget {
  const _TodayCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = PourfectTokens.of(context);
    final daily = ref.watch(dailyProvider);

    final played = daily.challenge?.isPlayed ?? false;
    final stars = daily.challenge?.yourAttempt?.stars;

    return Pressable(
      onPressed: onTap,
      semanticLabel: "Today's challenge",
      scale: 0.99,
      child: Container(
        padding: EdgeInsets.all(tokens.space4),
        decoration: BoxDecoration(
          color: tokens.surfaceRaised,
          borderRadius: BorderRadius.circular(tokens.panelRadius),
          border: Border.all(
            color: played ? tokens.hairline : tokens.hairlineStrong,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('TODAY', style: labelStyle(tokens)),
                  SizedBox(height: tokens.space2),
                  Text(
                    daily.isOff
                        ? 'Daily challenge'
                        : played
                            ? 'Solved today'
                            : "Today's challenge",
                    style: titleStyle(tokens).copyWith(fontSize: 16),
                  ),
                ],
              ),
            ),
            if (played && stars != null)
              Text(
                '$stars★',
                style: numericStyle(tokens).copyWith(
                  color: tokens.accentWarm,
                  fontSize: 18,
                ),
              )
            else
              Icon(
                Icons.chevron_right_rounded,
                color: tokens.textMuted,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = PourfectTokens.of(context);

    return Pressable(
      onPressed: onTap,
      semanticLabel: label,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: tokens.space3),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: tokens.surfaceRaised,
          borderRadius: BorderRadius.circular(tokens.panelRadius),
          border: Border.all(color: tokens.hairline),
        ),
        child: Text(
          label,
          style: actionStyle(tokens, color: tokens.textPrimary),
        ),
      ),
    );
  }
}

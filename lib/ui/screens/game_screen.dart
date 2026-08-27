/// The game screen. For now the only screen — the onboarding is the thing that
/// has to feel right before anything downstream is worth building.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/analytics/analytics_service.dart';
import '../../state/game_controller.dart';
import '../../state/hint_controller.dart';
import '../../state/level_repository.dart';
import '../../state/providers.dart';
import '../theme/tokens.dart';
import '../theme/typography.dart';
import '../widgets/board_view.dart';
import '../widgets/hud.dart';
import '../widgets/level_complete_card.dart';

/// How long the completion flourish is allowed to play before the board fades.
///
/// Matches the tube glow in `board_view.dart`. The card must not cut across the
/// moment the player just earned.
const _flourishHold = Duration(milliseconds: 780);

class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen>
    with WidgetsBindingObserver {
  bool _showComplete = false;
  bool _bootstrapped = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// THE ABANDON PATH THAT ACTUALLY MATTERS.
  ///
  /// Most players who give up never press back — they close the app, or a call
  /// arrives, or they swipe away. A funnel that only counts clean exits
  /// undercounts abandonment on exactly the hard levels it exists to find, so
  /// backgrounding is treated as leaving the level and the event is flushed
  /// while the process is still alive to send it.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        ref
            .read(gameControllerProvider.notifier)
            .reportAbandon(AbandonReason.backgrounded);
        ref.read(analyticsServiceProvider).flush();
      case AppLifecycleState.resumed:
      case AppLifecycleState.inactive:
        break;
    }
  }

  Future<void> _onHint() async {
    final hints = ref.read(hintServiceProvider);

    // Tapping hint while one is already solving cancels it. The board was never
    // blocked, so this is the only affordance needed.
    if (ref.read(gameControllerProvider)?.hintPending ?? false) {
      hints.cancel();
      return;
    }

    // In stage 9 this call is preceded by a rewarded video, and the reward is
    // debited ONLY on HintOutcome.resolved. Never grant before this returns.
    final outcome = await hints.request();
    if (!mounted) return;

    if (outcome == HintOutcome.unavailable) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          const SnackBar(
            content: Text('No hint available for this position.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
    }
  }

  void _onTapTube(int tube) {
    final controller = ref.read(gameControllerProvider.notifier);
    final outcome = controller.tapTube(tube);

    if (outcome == TapOutcome.poured ||
        outcome == TapOutcome.pouredAndCompleted) {
      final state = ref.read(gameControllerProvider);
      if (state != null && state.isWon) {
        ref.read(hapticsServiceProvider).levelCompleted();
        // Let the tubes settle and glow before the card arrives.
        Future.delayed(_flourishHold, () {
          if (mounted) setState(() => _showComplete = true);
        });
      }
    }
  }

  void _startLevel(int id) {
    final campaign = ref.read(campaignProvider).value;
    if (campaign == null) return;
    final level = campaign.byId(id);
    if (level == null) return;

    setState(() => _showComplete = false);
    ref
        .read(gameControllerProvider.notifier)
        .startLevel(level.level, levelSetVersion: campaign.levelSetVersion);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = PourfectTokens.of(context);
    final campaign = ref.watch(campaignProvider);
    final state = ref.watch(gameControllerProvider);

    return Scaffold(
      backgroundColor: tokens.surface,
      body: campaign.when(
        loading: () => const _Loading(),
        error: (error, _) => _LoadFailed(message: '$error'),
        data: (levelSet) {
          // Open level 1 once the campaign is available. Level select arrives
          // after the onboarding feels right.
          if (!_bootstrapped) {
            _bootstrapped = true;
            WidgetsBinding.instance.addPostFrameCallback((_) => _startLevel(1));
          }
          if (state == null) return const _Loading();

          final campaignLevel = levelSet.byId(state.level.id);
          final bandName = campaignLevel == null
              ? ''
              : bandNameFor(campaignLevel.bandIndex);

          return SafeArea(
            child: Stack(
              children: [
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 420),
                  curve: Curves.easeOut,
                  opacity: _showComplete ? 0.12 : 1,
                  child: Column(
                    children: [
                      BoardHud(
                        levelId: state.level.id,
                        bandName: bandName,
                        movesUsed: state.movesUsed,
                        minMoves: state.level.minMoves,
                      ),
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: tokens.space4,
                          ),
                          child: BoardView(onTapTube: _onTapTube),
                        ),
                      ),
                      if (state.isStuck && !state.isWon)
                        _StuckBanner(
                          onUndo: () =>
                              ref.read(gameControllerProvider.notifier).undo(),
                        ),
                      BoardControls(
                        onUndo: state.canUndo
                            ? () => ref
                                  .read(gameControllerProvider.notifier)
                                  .undo()
                            : null,
                        onRestart: () =>
                            ref.read(gameControllerProvider.notifier).restart(),
                        onHint: _onHint,
                        hintBusy: state.hintPending,
                      ),
                    ],
                  ),
                ),
                if (_showComplete)
                  TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 380),
                    curve: Curves.easeOutCubic,
                    tween: Tween(begin: 0, end: 1),
                    builder: (context, t, child) => Opacity(
                      opacity: t,
                      child: Transform.translate(
                        offset: Offset(0, 16 * (1 - t)),
                        child: child,
                      ),
                    ),
                    child: LevelCompleteCard(
                      levelId: state.level.id,
                      stars: state.stars,
                      movesUsed: state.movesUsed,
                      minMoves: state.level.minMoves,
                      onNext: levelSet.byId(state.level.id + 1) == null
                          ? null
                          : () => _startLevel(state.level.id + 1),
                      onReplay: () {
                        setState(() => _showComplete = false);
                        ref.read(gameControllerProvider.notifier).restart();
                      },
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Surfaced the moment the board has no legal move left.
///
/// Leaving a player stuck, quietly, wondering what they missed is how a
/// relaxing game earns a one-star review. Undo is offered right here, and it is
/// free.
class _StuckBanner extends StatelessWidget {
  final VoidCallback onUndo;

  const _StuckBanner({required this.onUndo});

  @override
  Widget build(BuildContext context) {
    final tokens = PourfectTokens.of(context);

    return Container(
      margin: EdgeInsets.symmetric(horizontal: tokens.space4),
      padding: EdgeInsets.symmetric(
        horizontal: tokens.space3,
        vertical: tokens.space2,
      ),
      decoration: BoxDecoration(
        color: tokens.surfaceRaised,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: tokens.hairline),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'No moves left — step back and try another line.',
              style: bodyStyle(tokens).copyWith(fontSize: 13),
            ),
          ),
          TextButton(
            onPressed: onUndo,
            child: Text(
              'Undo',
              style: actionStyle(tokens, color: tokens.accent),
            ),
          ),
        ],
      ),
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) {
    final tokens = PourfectTokens.of(context);
    return Center(child: Text('POURFECT', style: labelStyle(tokens)));
  }
}

class _LoadFailed extends StatelessWidget {
  final String message;

  const _LoadFailed({required this.message});

  @override
  Widget build(BuildContext context) {
    final tokens = PourfectTokens.of(context);
    return Center(
      child: Padding(
        padding: EdgeInsets.all(tokens.space4),
        child: Text(
          'Could not load levels.\n$message',
          textAlign: TextAlign.center,
          style: bodyStyle(tokens),
        ),
      ),
    );
  }
}

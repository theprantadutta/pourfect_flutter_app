/// The board screen, and the level-complete sequence that plays on top of it.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/ads/ad_service.dart';
import '../../services/analytics/analytics_service.dart';
import '../../state/game_controller.dart';
import '../../state/hint_controller.dart';
import '../../state/level_repository.dart';
import '../../state/monetization_controller.dart';
import '../../state/progress_repository.dart';
import '../../state/providers.dart';
import '../theme/tokens.dart';
import '../theme/typography.dart';
import '../widgets/board_view.dart';
import '../widgets/hud.dart';
import '../widgets/win_overlay.dart';
import '../widgets/win_profile.dart';

class GameScreen extends ConsumerStatefulWidget {
  final int levelId;

  /// Returns to the level map.
  final VoidCallback onExit;

  const GameScreen({super.key, required this.levelId, required this.onExit});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _win;

  WinProfile _profile = WinProfile.full;
  CompletionResult? _result;

  /// Cue keys already fired this sequence, so a rebuild cannot retrigger a
  /// sound.
  final Set<String> _fired = {};

  /// True once the player has skipped. The skip layer is then removed, which is
  /// what makes Next require a SEPARATE tap — see [_skipActive].
  bool _skipped = false;

  bool _started = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _win = AnimationController(vsync: this)..addListener(_onWinTick);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _win.dispose();
    super.dispose();
  }

  /// THE ABANDON PATH THAT ACTUALLY MATTERS. Most players who give up close the
  /// app rather than pressing back, so a funnel counting only clean exits
  /// undercounts abandonment on exactly the hard levels it exists to find.
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

  // ---- level lifecycle -----------------------------------------------------

  /// Advances after a COMPLETED level, offering an interstitial at the break.
  ///
  /// This is the ONLY path that can show an interstitial. Restart and exit go
  /// straight to `_startLevel`, so there is no code path where quitting or
  /// replaying a level can produce an ad.
  Future<void> _advanceFrom(int completedLevelId, int nextLevelId) async {
    await ref
        .read(monetizationProvider.notifier)
        .maybeShowInterstitialAfter(completedLevelId);
    if (!mounted) return;
    _startLevel(nextLevelId);
  }

  void _startLevel(int id) {
    final campaign = ref.read(campaignProvider).value;
    if (campaign == null) return;
    final level = campaign.byId(id);
    if (level == null) return;

    _win.stop();
    _win.value = 0;
    _fired.clear();
    setState(() {
      _skipped = false;
      _result = null;
      _started = true;
    });

    ref
        .read(gameControllerProvider.notifier)
        .startLevel(level.level, levelSetVersion: campaign.levelSetVersion);
  }

  void _onBallLanded(double fill, bool completedTube) {
    // Pitch rises with how full the tube now is, so a run of four plays as a
    // rising figure rather than the same note four times.
    ref.read(audioServiceProvider).pour(fill: fill);
    if (completedTube) {
      ref.read(audioServiceProvider).tubeComplete();
      ref.read(hapticsServiceProvider).tubeCompleted();
    } else {
      ref.read(hapticsServiceProvider).ballLanded();
    }
  }

  void _onTapTube(int tube) {
    final outcome = ref.read(gameControllerProvider.notifier).tapTube(tube);
    if (outcome == TapOutcome.selected ||
        outcome == TapOutcome.deselected ||
        outcome == TapOutcome.reselected) {
      ref.read(audioServiceProvider).select();
    }

    final state = ref.read(gameControllerProvider);
    if (state != null && state.isWon && _result == null) {
      _beginWinSequence(state.level.id, state.movesUsed);
    }
  }

  /// Records the result, picks the profile this clear has earned, and runs it.
  void _beginWinSequence(int levelId, int movesUsed) {
    final campaign = ref.read(campaignProvider).value;
    final state = ref.read(gameControllerProvider);
    if (campaign == null || state == null) return;

    final result = ref
        .read(progressProvider.notifier)
        .record(
          level: state.level,
          levelSetVersion: campaign.levelSetVersion,
          movesUsed: movesUsed,
        );

    // Length is EARNED, not constant. Three stars, a personal best, or the end
    // of a band gets the full 1820ms; a routine two-star retry on level 60 gets
    // the same beats in 1150ms.
    final profile = WinProfile.forOutcome(
      stars: result.stars,
      isNewBest: result.isNewBest,
      isBandFinal: isBandFinalLevel(levelId),
    );

    setState(() {
      _result = result;
      _profile = profile;
    });

    ref.read(audioServiceProvider).win();
    ref.read(hapticsServiceProvider).levelCompleted();

    _win
      ..duration = profile.duration
      ..forward(from: 0);
  }

  /// Fires star and personal-best cues as their beats arrive.
  void _onWinTick() {
    final result = _result;
    if (result == null) return;

    final elapsed = _win.value * _profile.total;

    for (var i = 0; i < result.stars && i < _profile.starAt.length; i++) {
      if (elapsed < _profile.starAt[i]) continue;
      if (!_fired.add('star$i')) continue;

      ref.read(audioServiceProvider).star(i);
      // The third star is the one that has to feel different — a stronger
      // haptic on top of the richer tone.
      if (i == 2) {
        ref.read(hapticsServiceProvider).tubeCompleted();
      } else {
        ref.read(hapticsServiceProvider).ballLanded();
      }
    }

    if (result.isNewBest &&
        elapsed >= _profile.moves.at + 120 &&
        _fired.add('best')) {
      ref.read(audioServiceProvider).newBest();
      ref.read(hapticsServiceProvider).tubeCompleted();
    }

    if (mounted) setState(() {});
  }

  /// Jumps to the end state.
  ///
  /// Deliberately does NOT advance the level. If a skip also triggered Next,
  /// the gesture would become muscle memory and players would blow through two
  /// levels by accident — then, correctly, blame the game.
  void _skip() {
    if (_result == null || _skipped) return;
    _win.stop();
    _win.value = 1;
    setState(() => _skipped = true);
  }

  bool get _winActive => _result != null;

  /// The skip layer sits above everything and swallows one tap. Once it is
  /// gone the CTA becomes reachable — the "separate tap" rule expressed as
  /// layout rather than as a flag somebody has to remember to check.
  bool get _skipActive => _winActive && !_skipped && _win.value < 1;

  /// Asks for a hint, spending a free one or a rewarded video.
  ///
  /// THE ORDER HERE IS THE WHOLE POINT. The video plays, the reward is
  /// confirmed EARNED, and only then is the solver asked. If the solver cannot
  /// answer, the player is told plainly — and because a rewarded video costs
  /// attention rather than a balance, nothing of theirs was consumed. The one
  /// arrangement never to write is "grant, then check".
  Future<void> _onHint() async {
    final hints = ref.read(hintServiceProvider);
    if (ref.read(gameControllerProvider)?.hintPending ?? false) {
      hints.cancel();
      return;
    }

    final levelId = ref.read(gameControllerProvider)?.level.id ?? 0;
    final money = ref.read(monetizationProvider.notifier);

    var wasRewarded = false;
    if (!await money.consumeFreeHint()) {
      if (!mounted) return;
      if (!await _confirmWatchAd()) return;
      if (!mounted) return;

      final outcome = await money.offerRewarded(
        RewardedPlacement.hint,
        levelId: levelId,
      );
      if (!mounted) return;

      if (outcome != RewardOutcome.earned) {
        _toast(switch (outcome) {
          RewardOutcome.dismissed => 'No hint — the video was not finished.',
          RewardOutcome.unavailable => 'No video available right now.',
          _ => 'Something went wrong. Nothing was used.',
        });
        return;
      }
      wasRewarded = true;
    }

    final outcome = await hints.request(wasRewarded: wasRewarded);
    if (!mounted) return;

    if (outcome == HintOutcome.unavailable) {
      _toast(
        wasRewarded
            ? 'No hint for this position — your reward was not used.'
            : 'No hint available for this position.',
      );
    }
  }

  /// Asks before taking the player into a video. Never auto-play an ad.
  Future<bool> _confirmWatchAd() async {
    final tokens = PourfectTokens.of(context);
    final remaining = ref.read(monetizationProvider).freeHintsRemaining;

    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: tokens.surfaceRaised,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(tokens.panelRadius),
              side: BorderSide(color: tokens.hairline),
            ),
            title: Text('Watch a video for a hint?', style: titleStyle(tokens)),
            content: Text(
              remaining > 0 ? 'You have $remaining free hints left.' : 'Your free hints are used up. A short video earns one more.',
              style: bodyStyle(tokens),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(
                  'Not now',
                  style: actionStyle(tokens, color: tokens.textMuted),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(
                  'Watch',
                  style: actionStyle(tokens, color: tokens.accent),
                ),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }

  // ---- build ---------------------------------------------------------------

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
          // Started from HERE, not from initState: the campaign is a future,
          // and a post-frame callback fires before it resolves. Opening the
          // level the moment the data actually exists is the only ordering
          // that cannot race.
          if (!_started) {
            WidgetsBinding.instance.addPostFrameCallback(
              (_) => _startLevel(widget.levelId),
            );
            return const _Loading();
          }
          if (state == null) return const _Loading();

          final elapsed = _win.value * _profile.total;
          final result = _result;
          final progress = ref.read(progressProvider.notifier);
          final band = campaignBands().firstWhere(
            (b) => b.contains(state.level.id),
          );
          final clearedNow = progress.clearedIn(
            band.firstLevel,
            band.lastLevel,
          );

          return SafeArea(
            child: Stack(
              children: [
                Column(
                  children: [
                    // The HUD recedes rather than disappearing — the level
                    // number is still the answer to "where am I".
                    AnimatedOpacity(
                      duration: const Duration(milliseconds: 380),
                      opacity: _winActive ? 0.34 : 1,
                      child: BoardHud(
                        levelId: state.level.id,
                        bandName: band.name,
                        movesUsed: state.movesUsed,
                        minMoves: state.level.minMoves,
                        onExit: widget.onExit,
                      ),
                    ),
                    Expanded(
                      flex: _winActive ? 5 : 7,
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: tokens.space4,
                        ),
                        child: BoardView(
                          onTapTube: _onTapTube,
                          onBallLanded: _onBallLanded,
                          win: result == null
                              ? null
                              : WinPhase(
                                  profile: _profile,
                                  elapsedMs: elapsed,
                                  celebrateThird: result.stars >= 3,
                                ),
                        ),
                      ),
                    ),
                    if (result != null)
                      Expanded(
                        flex: 5,
                        child: SingleChildScrollView(
                          child: WinOverlay(
                            profile: _profile,
                            elapsedMs: elapsed,
                            stars: result.stars,
                            movesUsed: state.movesUsed,
                            minMoves: state.level.minMoves,
                            previousBest: result.previousBest,
                            isNewBest: result.isNewBest,
                            bandName: band.name,
                            bandClearedBefore: (clearedNow - 1).clamp(
                              0,
                              band.length,
                            ),
                            bandClearedAfter: clearedNow,
                            bandTotal: band.length,
                            onNext: levelSet.byId(state.level.id + 1) == null
                                ? null
                                : () => _advanceFrom(
                                    state.level.id,
                                    state.level.id + 1,
                                  ),
                            onReplay: () => _startLevel(state.level.id),
                            onLevels: widget.onExit,
                            interactive: !_skipActive,
                          ),
                        ),
                      )
                    else ...[
                      if (state.isStuck && !state.isWon)
                        _StuckBanner(
                          onUndo: () =>
                              ref.read(gameControllerProvider.notifier).undo(),
                        ),
                      BoardControls(
                        onUndo: state.canUndo
                            ? () {
                                ref
                                    .read(gameControllerProvider.notifier)
                                    .undo();
                              }
                            : null,
                        onRestart: () => _startLevel(state.level.id),
                        onHint: _onHint,
                        hintBusy: state.hintPending,
                      ),
                    ],
                  ],
                ),

                // Swallows exactly one tap, then removes itself.
                if (_skipActive)
                  Positioned.fill(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: _skip,
                      child: const SizedBox.expand(),
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

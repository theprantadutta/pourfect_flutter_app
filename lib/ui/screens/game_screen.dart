/// The board screen, and the level-complete sequence that plays over it: the
/// win moment on the board, then the blue result screen.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/ads/ad_service.dart';
import '../../services/analytics/analytics_service.dart';
import '../../engine/move.dart';
import '../../state/game_controller.dart';
import '../../state/game_state.dart';
import '../../state/hint_controller.dart';
import '../../state/monetization_controller.dart';
import '../../state/onboarding.dart';
import '../../state/play_history.dart';
import '../../state/progress_repository.dart';
import '../../state/providers.dart';
import '../../state/review_prompter.dart';
import '../../state/sync_controller.dart';
import '../theme/toy.dart';
import '../widgets/board_view.dart';
import '../widgets/hud.dart';
import '../widgets/level_clock.dart';
import '../widgets/toy_kit.dart';
import '../widgets/tutorial.dart';
import '../widgets/win_overlay.dart';
import '../widgets/win_profile.dart';
import '../widgets/pour_loader.dart';

class GameScreen extends ConsumerStatefulWidget {
  final int levelId;

  /// Returns to the level map.
  final VoidCallback onExit;

  /// Run level 1 as the guided tutorial even if it was done before — the
  /// "How to play" replay in Settings.
  final bool tutorial;

  const GameScreen({
    super.key,
    required this.levelId,
    required this.onExit,
    this.tutorial = false,
  });

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

  /// Held from initState so [dispose] never has to reach through `ref`.
  ///
  /// Reading a provider while the tree is being torn down is exactly when it
  /// can throw, and the one thing dispose must do here — ending the gameplay
  /// session — is the thing that must not be skipped.
  late final GameController _game;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _game = ref.read(gameControllerProvider.notifier);
    _win = AnimationController(vsync: this)..addListener(_onWinTick);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // THE BOARD IS GONE, SO THE SESSION IS OVER. Every route out of here ends
    // in disposal — the back affordance, a system back, a parent rebuild — and
    // this is the only place all of them pass through. Without it a solve
    // still in flight lands on the position the player walked away from,
    // reports success, and is charged for a hint nobody ever saw.
    _game.endSession();
    _win.dispose();
    _guideIdleTimer?.cancel();
    _tipTimer?.cancel();
    _hintTipTimer?.cancel();
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
        // The clock stops FIRST, before anything reads a duration, so the
        // banked time is what was actually played and not however long the
        // phone sat in a pocket.
        _bankPlaytime();
        ref.read(gameControllerProvider.notifier).pauseClock();
        ref
            .read(gameControllerProvider.notifier)
            .reportAbandon(AbandonReason.backgrounded);
        ref.read(analyticsServiceProvider).flush();
      case AppLifecycleState.resumed:
        // Coming back un-latches the terminal event, so finishing this board
        // still reports a completion. Without it, backgrounding permanently
        // suppressed level_complete for the rest of the run and the funnel
        // lost every success that had been interrupted.
        ref.read(gameControllerProvider.notifier).reportResumed();
        final current = ref.read(gameControllerProvider);
        // The guided level is untimed; coming back must not start its clock.
        if (current == null || !_guideActive(current)) {
          ref.read(gameControllerProvider.notifier).resumeClock();
        }

        // A failed initial ad load used to last the whole session. Somebody
        // who launches offline and reconnects should not be stuck without
        // interstitials until they restart the app.
        ref.read(adServiceProvider).preload();

      case AppLifecycleState.inactive:
        break;
    }
  }

  /// Moves the time played so far out of the live clock and into today's row
  /// of the play history.
  ///
  /// Called wherever a stretch of play ends without a win — backgrounding,
  /// leaving, restarting. Without it "time played" would only ever count
  /// levels somebody finished, and the boards they wrestled with longest, the
  /// ones actually worth knowing about, would contribute nothing.
  ///
  /// Banking RESETS the live clock's accumulator, so a stretch can never be
  /// counted twice by two callers on the same exit path.
  void _bankPlaytime() {
    final controller = ref.read(gameControllerProvider.notifier);
    final seconds = controller.takeUnbankedSeconds();
    if (seconds <= 0) return;
    ref.read(playHistoryProvider.notifier).recordPlaytime(seconds: seconds);
  }

  void _exit() {
    _bankPlaytime();
    // Disposal ends the session too, but not until the route animation
    // finishes. Ending it here means a solve that lands during the transition
    // is already known to be undeliverable.
    _game.endSession();
    widget.onExit();
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

    _tip = null;
    _tipTimer?.cancel();
    _hintTipTimer?.cancel();
    // A restart during the guided level starts its script over too.
    _guideSteps = 0;
    _guideBoard = null;
    _restartGuideIdle();

    // Level 2, the first level after the guided one: what the par meter says.
    if (id == 2 && !ref.read(progressProvider).containsKey(2)) {
      _showTip(
        Tip.par,
        'Finish within par for three stars. The bar shows how much you\'ve used.',
      );
    }
    // The first board with five-ball tubes. Nothing else announces the change,
    // and a player counting four to a tube would misread their first pour.
    if (level.level.board.capacity > 4) {
      _showTip(Tip.tallTubes, 'Taller tubes! Each one holds five balls now.');
    }
    // Level 4 onward, a while in without finishing: hints exist.
    if (id >= 4) {
      final session = _game.sessionId;
      _hintTipTimer = Timer(const Duration(seconds: 40), () {
        if (!mounted || !_game.isCurrentSession(session)) return;
        if (ref.read(gameControllerProvider)?.isWon ?? true) return;
        _showTip(Tip.hint, 'Stuck? Hint shows you a good next move.');
      });
    }
  }

  /// Shows [tip] once in the life of the install, for a few seconds.
  Future<void> _showTip(Tip tip, String text) async {
    // Never while the guided level holds the slot: the tip would be marked
    // seen without ever being on screen, and so would never show at all.
    final current = ref.read(gameControllerProvider);
    if (current != null && _guideActive(current)) return;
    if (!await ref.read(onboardingProvider.notifier).claim(tip)) return;
    if (!mounted) return;
    setState(() => _tip = text);
    _tipTimer?.cancel();
    _tipTimer = Timer(const Duration(seconds: 6), () {
      if (mounted) setState(() => _tip = null);
    });
  }

  // ---- the guided first level ----------------------------------------------

  /// Whether this board is the guided tutorial right now.
  bool _guideActive(GameState state) {
    if (_guideEnded || _result != null || state.level.id != 1) return false;
    if (widget.tutorial) return true;
    // Read, not watched: this also runs from the win path, outside build.
    // build() watches the provider so the flags arriving still rebuilds.
    final onboarding = ref.read(onboardingProvider);
    // Not before the flags are read, and never for somebody who already
    // cleared level 1 — an update must not ambush existing players.
    return onboarding.loaded &&
        !onboarding.tutorialDone &&
        !ref.read(progressProvider).containsKey(1);
  }

  /// The move to point at, solved once per board rather than per frame.
  Move? _guidance(GameState state) {
    if (!identical(_guideBoard, state.board)) {
      _guideBoard = state.board;
      _guideMove = guidedMove(state.board);
    }
    return _guideMove;
  }

  void _restartGuideIdle() {
    _guideIdleTimer?.cancel();
    if (_guideIdle) setState(() => _guideIdle = false);
    // Only the guided level has a hand to bring back.
    if (ref.read(gameControllerProvider)?.level.id != 1) return;
    _guideIdleTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) setState(() => _guideIdle = true);
    });
  }

  void _skipGuide() {
    _logTutorial(TutorialOutcome.skip);
    ref.read(onboardingProvider.notifier).finishTutorial();
    setState(() => _guideEnded = true);
    // From here it is an ordinary level, clock and all.
    _game.resumeClock();
  }

  void _logTutorial(TutorialOutcome outcome) {
    ref
        .read(analyticsServiceProvider)
        .log(
          TutorialEvent(
            outcome: outcome,
            step: _guideSteps,
            isReplay: widget.tutorial,
          ),
        );
  }

  /// What the guide says, given where the player is.
  String _guideCaption(GameState state, Move? move) {
    final holding = state.selectedTube;
    if (state.board.tubes.any((t) => t.isComplete) &&
        _guideSteps >= 2 &&
        holding == null) {
      return 'Sorted! Now make every tube a single color.';
    }
    if (holding != null) {
      return holding == move?.from
          ? 'Now tap where they go: onto the same color, or an empty tube.'
          : 'Tap the tube the hand points at to pick those up instead.';
    }
    return switch (_guideSteps) {
      0 => 'Tap a tube to pick up the balls on top.',
      1 => 'That\'s a pour! Keep going.',
      _ => 'Keep going: one color per tube.',
    };
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
    final movesBefore = ref.read(gameControllerProvider)?.movesUsed ?? 0;
    final outcome = ref.read(gameControllerProvider.notifier).tapTube(tube);
    _restartGuideIdle();
    if (outcome == TapOutcome.selected ||
        outcome == TapOutcome.deselected ||
        outcome == TapOutcome.reselected) {
      ref.read(audioServiceProvider).select();
    }

    final state = ref.read(gameControllerProvider);
    if (state != null && state.movesUsed > movesBefore) {
      _guideSteps++;
      if (_tip != null && state.level.id == 2) setState(() => _tip = null);
      // The first time a run goes past par, and only then: undo is free.
      if (state.movesUsed == state.level.minMoves + 1 && !state.isWon) {
        _showTip(
          Tip.undo,
          'Past par? Undo is free — step back as far as you like.',
        );
      }
    }
    if (state != null && state.isWon && _result == null) {
      _beginWinSequence(state.level.id, state.movesUsed);
    }
  }

  /// Records the result, picks the profile this clear has earned, and runs it.
  void _beginWinSequence(int levelId, int movesUsed) {
    final campaign = ref.read(campaignProvider).value;
    final state = ref.read(gameControllerProvider);
    if (campaign == null || state == null) return;

    if (_guideActive(state)) {
      _logTutorial(TutorialOutcome.complete);
      ref.read(onboardingProvider.notifier).finishTutorial();
      _guideEnded = true;
    }
    _tip = null;
    _hintTipTimer?.cancel();

    // The controller stopped the clock on the winning move, so this reads the
    // settled time rather than however long the win animation has been up.
    final elapsedSeconds = state.elapsedSecondsAt(DateTime.now());

    final result = ref
        .read(progressProvider.notifier)
        .record(
          level: state.level,
          levelSetVersion: campaign.levelSetVersion,
          movesUsed: movesUsed,
          elapsedSeconds: elapsedSeconds,
        );

    // The SCORE gets the whole attempt; the history gets only the part it has
    // not already been given. An attempt interrupted by a phone call reaches
    // the history in two instalments, and adding the full elapsed time here
    // would count the first one twice.
    ref
        .read(playHistoryProvider.notifier)
        .recordSolve(
          levelId: levelId,
          seconds: ref
              .read(gameControllerProvider.notifier)
              .takeUnbankedSeconds(),
          moves: movesUsed,
          stars: result.stars,
          points: result.points,
        );

    // Straight out to the server, and nothing waits on it. A failure leaves
    // the level marked dirty; the next successful sync — the next launch at
    // the latest — carries it, because the merge on both sides is monotonic
    // and re-sending is always safe.
    ref.read(syncControllerProvider.notifier)
      ..markDirty(levelId)
      ..syncNow();

    // Length is EARNED, not constant. Three stars, a personal best, or the end
    // of a band gets the full 1820ms; a routine two-star retry on level 60 gets
    // the same beats in 1150ms.
    final profile = WinProfile.forOutcome(
      stars: result.stars,
      isNewBest: result.isNewBest,
      isBandFinal: ref
          .read(campaignBandsProvider)
          .any((band) => band.lastLevel == levelId),
    );

    setState(() {
      _result = result;
      _profile = profile;
    });

    // The rating card is asked for after a win worth celebrating, and
    // `WinProfile.full` already decides which those are — three stars, a
    // personal best, or the end of a band. Re-deriving that test here would be
    // a second place to disagree about what a good win is.
    //
    // Only NOTED here. The ask happens when the player leaves for the hub,
    // because the win sequence is choreographed to the millisecond and is the
    // last thing on earth to interrupt with a dialog.
    if (profile == WinProfile.full) {
      ref.read(reviewPrompterProvider.notifier).noteDelight();
    }

    ref.read(audioServiceProvider).win();
    ref.read(hapticsServiceProvider).levelCompleted();

    _win.duration = profile.duration;
    if (Toy.calm(context)) {
      // Reduced motion keeps the state change and drops the show: straight to
      // the settled result, with no skip layer to spend a tap on.
      _win.value = 1;
      _skipped = true;
    } else {
      _win.forward(from: 0);
    }
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
        elapsed >= _profile.sticker.at &&
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
  /// Buys one extra empty tube for this attempt.
  ///
  /// Same discipline as the hint, and the same reason for it: BANK FIRST, then
  /// deliver. A rewarded video ends by returning from a fullscreen activity,
  /// and coming back to a board that has since been restarted, won or left is
  /// ordinary rather than exceptional — so the credit is granted before
  /// anything is checked, and the fifteen seconds are never spent for nothing.
  ///
  /// Unlike a hint this cannot come back empty-handed: a tube is always
  /// deliverable, so there is no "resolved" to confirm before granting. What
  /// there is instead is a board that may have moved on, which is why the
  /// grant is settled against the SESSION rather than against `mounted`.
  Future<void> _onExtraTube() async {
    final money = ref.read(monetizationProvider.notifier);
    final state = ref.read(gameControllerProvider);
    if (state == null || !state.canOfferExtraTube) return;

    final levelId = state.level.id;
    final session = _game.sessionId;

    // A credit is a tube already paid for by a video that had nowhere to put
    // it. Spent before anything else, so nobody pays twice.
    if (!await money.consumeExtraTubeCredit()) {
      if (!mounted) return;

      // The clock stops for the whole negotiation, prompt and video both.
      // Charging somebody score for the time it takes to watch an ad we asked
      // them to watch is exactly the sort of thing that shows up in reviews.
      _game.pauseClock();

      if (!await _confirmWatchAd(
        title: 'Watch a video for an extra tube?',
        body:
            'One more empty tube for this level. Your stars still depend on '
            'how many moves you take.',
      )) {
        _game.resumeClock();
        return;
      }

      final outcome = await money.offerRewarded(
        RewardedPlacement.extraTube,
        levelId: levelId,
      );
      _game.resumeClock();

      if (outcome != RewardOutcome.earned) {
        if (mounted) {
          _toast(switch (outcome) {
            RewardOutcome.dismissed => 'No tube — the video was not finished.',
            RewardOutcome.unavailable => 'No video available right now.',
            _ => 'Something went wrong. Nothing was used.',
          });
        }
        return;
      }

      // BANKED BEFORE IT IS SPENT, so a crash in between leaves a credit
      // rather than a debt.
      await money.grantExtraTubeCredit();

      if (!_game.isCurrentSession(session)) {
        // The board that asked for this is gone. The credit stays banked and
        // the next tube is free, which is what "your video is saved for the
        // next one" already promises elsewhere.
        if (mounted) _toast('Saved — your next tube is free.');
        return;
      }

      await money.consumeExtraTubeCredit();
    }

    if (!_game.isCurrentSession(session) || !_game.grantExtraTube()) {
      // Could not be delivered after all — hand the credit straight back
      // rather than keeping a payment for nothing.
      await money.grantExtraTubeCredit();
      if (mounted) _toast('Saved — your next tube is free.');
      return;
    }

    // Always rewarded: unlike hints there is no free allowance, so every tube
    // is funded by a video — this one, or one banked earlier.
    ref
        .read(analyticsServiceProvider)
        .log(
          PowerUpUsed(
            levelId: levelId,
            kind: PowerUpKind.extraTube,
            wasRewarded: true,
          ),
        );
  }

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

    // The spell of play this request belongs to. Everything below is settled
    // against it rather than against whether this widget is still alive: the
    // player is owed something because of what they paid and what arrived, not
    // because of which route happens to be on screen.
    final session = _game.sessionId;

    // What the player spent to get here, so it can be given back if the
    // solver cannot deliver. Charging happens before the solve — the ad has to
    // play before the work, or the wait feels like a punishment — so the
    // refund is what keeps that honest.
    var spentFreeHint = false;
    var spentCredit = false;

    // A credit is a hint already paid for by a video that produced nothing.
    // It is spent before anything else, so a player never pays twice for the
    // same hint.
    if (await money.consumeHintCredit()) {
      spentCredit = true;
    } else if (await money.consumeFreeHint()) {
      spentFreeHint = true;
    } else {
      if (!mounted) return;

      // The clock stops for the whole ad negotiation — the prompt and the
      // video both. Charging somebody score for the time it takes to watch an
      // ad we asked them to watch is the sort of thing that shows up in
      // reviews. Backgrounding to the ad activity would stop it anyway on
      // Android, but relying on that leaves the confirm dialog running and
      // gives no cover at all on a platform that reports lifecycle
      // differently.
      _game.pauseClock();

      if (!await _confirmWatchAd()) {
        _game.resumeClock();
        return;
      }

      final outcome = await money.offerRewarded(
        RewardedPlacement.hint,
        levelId: levelId,
      );
      _game.resumeClock();

      if (outcome != RewardOutcome.earned) {
        // Nothing was spent, so there is nothing to settle. Only the toast
        // needs a screen.
        if (mounted) {
          _toast(switch (outcome) {
            RewardOutcome.dismissed => 'No hint — the video was not finished.',
            RewardOutcome.unavailable => 'No video available right now.',
            _ => 'Something went wrong. Nothing was used.',
          });
        }
        return;
      }

      // BANKED WHETHER OR NOT THE SCREEN SURVIVED.
      //
      // A rewarded ad ends by returning from a fullscreen activity, and coming
      // back to a rebuilt or popped route is ordinary rather than exceptional.
      // The `mounted` check that used to sit above this took fifteen seconds
      // of somebody's attention and then gave back nothing, because the credit
      // was granted after it.
      //
      // Banked before it is spent, so a crash in between leaves a credit
      // rather than a debt.
      await money.grantHintCredit();

      // ...and if the board that asked for it is gone, banked is where it
      // stays. Spending it here would buy a hint for a session that ended
      // while the video played, which is a purchase with nothing to deliver
      // it to. Left as a credit, the next hint they ask for is free — which is
      // what "your video is saved for the next one" already promises
      // elsewhere.
      if (!_game.isCurrentSession(session)) {
        if (mounted) {
          _toast('Your video is saved for the next hint.');
        }
        return;
      }

      await money.consumeHintCredit();
      spentCredit = true;
    }

    final wasRewarded = spentCredit;
    final outcome = await hints.request(wasRewarded: wasRewarded);

    // NO `mounted` CHECK HERE, deliberately.
    //
    // Solving runs on an isolate and can take seconds on a late board. Leaving
    // the screen during it is the most ordinary thing a player can do — back
    // out, take a call, put the phone down on a hint that never arrives — and
    // the early return that used to sit on this line skipped every refund
    // branch below it. The free hint, or the video they had already watched,
    // was simply gone, and nothing on screen had said so.
    //
    // What a player is owed does not depend on which widgets are still alive.
    // Settlement is unconditional from here down; only the toasts are guarded,
    // because a toast is the one part that genuinely needs a screen.
    Future<void> refund() async {
      if (spentFreeHint) await money.refundFreeHint();
      if (spentCredit) await money.grantHintCredit();
    }

    // DELIVERY, not merely success, is what a hint is charged for.
    //
    // The session is re-checked HERE as well as inside the service, because
    // this is where the money is decided and it must not depend on the service
    // behaving. A solve that finishes after the player has left resolves
    // perfectly well against the position they abandoned — same board, valid
    // move, `resolved` — and the board carrying it is never shown again,
    // because reopening a level starts a fresh one. Charging for that is
    // charging for nothing.
    final delivered = _game.isCurrentSession(session);

    switch (outcome) {
      case HintOutcome.resolved when !delivered:
        await refund();

      case HintOutcome.unavailable:
        await refund();
        if (!mounted) return;
        _toast(
          wasRewarded
              ? 'No hint for this position — your video is saved for the next one.'
              : 'No hint available for this position.',
        );

      case HintOutcome.resolved:
        // Only after a REWARDED hint. The player has just spent fifteen
        // seconds in a fullscreen ad and comes back to a board they have lost
        // context on; the pulsing destination tube is the answer, but they
        // have to be told to look at it. A free hint needs none of this —
        // they never left the screen and the pulse speaks for itself.
        //
        // Saying nothing here is how a paid reward reads as nothing happening,
        // which is a refund request and a one-star review.
        if (wasRewarded && mounted) {
          _toast('Here is your hint — pour into the glowing tube.');
        }

      case HintOutcome.stale:
      case HintOutcome.cancelled:
      case HintOutcome.notApplicable:
        // The board moved on, or the player cancelled. Either way nothing was
        // delivered, so nothing stays spent.
        await refund();
    }
  }

  /// Asks before a rewarded video plays. Never auto-play an ad.
  ///
  /// Defaults to the hint wording, because that was the only caller for a long
  /// time. A placement that reads differently passes its own — "you have 2
  /// free hints left" is nonsense next to an offer of an extra tube, which has
  /// no free allowance at all.
  Future<bool> _confirmWatchAd({String? title, String? body}) {
    final remaining = ref.read(monetizationProvider).freeHintsRemaining;
    return showToyConfirm(
      context: context,
      title: title ?? 'Watch a video for a hint?',
      body:
          body ??
          (remaining > 0
              ? 'You have $remaining free hints left.'
              : 'Your free hints are used up. A short video earns one more.'),
      cancelLabel: 'Not now',
      confirmLabel: 'Watch',
      confirmColor: Toy.yellow,
    );
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  // ---- build ---------------------------------------------------------------

  /// The "Holding 2 · drop into a bouncing tube" coaching toast is for the
  /// first few levels only. By level four everybody knows; after that it
  /// would be the game talking over the board.
  static const _coachUntilLevel = 3;

  /// What the coaching toast last said, kept so it can fade out intact.
  ({int color, int count})? _coach;

  // ---- the guided first level ----------------------------------------------

  /// The guided level was finished or skipped on this screen.
  bool _guideEnded = false;

  /// tutorial_begin has been logged for this screen.
  bool _guideLogged = false;

  /// Pours the guide has seen, for the analytics step and the captions.
  int _guideSteps = 0;

  /// The board the cached guidance move was solved for, and the move.
  Object? _guideBoard;
  Move? _guideMove;

  /// Past the first two pours the hand only comes back when the player stops
  /// for a few seconds: shown every move, level 1 would play itself.
  bool _guideIdle = false;
  Timer? _guideIdleTimer;

  // ---- one-time tips -------------------------------------------------------

  /// A tip on screen, in the coaching slot, and the timer that clears it.
  String? _tip;
  Timer? _tipTimer;
  Timer? _hintTipTimer;

  @override
  Widget build(BuildContext context) {
    final campaign = ref.watch(campaignProvider);
    final state = ref.watch(gameControllerProvider);

    return campaign.when(
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
        final bands = ref.watch(campaignBandsProvider);
        final band = bands.firstWhere((b) => b.contains(state.level.id));
        final clearedNow = progress.clearedIn(band.firstLevel, band.lastLevel);

        // Where the win sequence is. Both are 0 while playing.
        final raysIn = _profile.rays == null
            ? 0.0
            : ((elapsed - _profile.rays!.at) / _profile.rays!.length).clamp(
                0.0,
                1.0,
              );
        final settled = result == null
            ? 0.0
            : ((elapsed - _profile.settle.at) / _profile.settle.length).clamp(
                0.0,
                1.0,
              );

        ref.watch(onboardingProvider);
        final guided = _guideActive(state);
        final guideMove = guided ? _guidance(state) : null;
        // The guided level is UNTIMED. A new player reading captions on their
        // very first board was watching the clock go red past par and losing
        // most of the level's points for it. It records as time 0, which the
        // whole app already treats as "unknown", never as instant.
        if (guided && state.isClockRunning) {
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => _game.pauseClock(),
          );
        }
        if (guided && !_guideLogged) {
          _guideLogged = true;
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => _logTutorial(TutorialOutcome.begin),
          );
        }
        // The hand: every step of the first two pours, then only when the
        // player pauses.
        final guideTube = !guided || guideMove == null
            ? null
            : (_guideSteps >= 2 && !_guideIdle)
            ? null
            : state.selectedTube == guideMove.from
            ? guideMove.to
            : guideMove.from;

        final selected = state.selectedTube;
        final coaching =
            result == null &&
            !guided &&
            _tip == null &&
            selected != null &&
            state.board[selected].isNotEmpty &&
            state.level.id <= _coachUntilLevel;
        if (coaching) {
          _coach = (
            color: state.board[selected].balls.last,
            count: state.board[selected].topRunLength,
          );
        }

        final playfield = ToyScaffold(
          padding: EdgeInsets.zero,
          backdrop: raysIn > 0
              ? WinRays(color: const Color(0x47FFC233), opacity: raysIn)
              : null,
          child: Column(
            children: [
              // The HUD recedes rather than disappearing during the win
              // moment — the level number still answers "where am I".
              AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                opacity: _winActive ? 0.5 : 1,
                child: BoardHud(
                  levelId: state.level.id,
                  bandName: band.name,
                  movesUsed: state.movesUsed,
                  minMoves: state.level.minMoves,
                  showParMeter: !_winActive,
                  clock: guided
                      ? null
                      : LevelClock(
                          // Read through the notifier rather than closing over
                          // `state`: the ticker outlives this build, and a captured
                          // snapshot would freeze at the time of the last move.
                          elapsedSeconds: () =>
                              ref
                                  .read(gameControllerProvider)
                                  ?.elapsedSecondsAt(DateTime.now()) ??
                              0,
                          parSeconds: state.parSeconds,
                          isRunning: state.isClockRunning,
                        ),
                  onExit: _exit,
                ),
              ),
              SizedBox(
                // Two lines for the caption and tips; one for the coaching toast.
                height: guided || (_tip != null && result == null) ? 84 : 58,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  // One slot, three voices in priority order: the guided
                  // level's caption, a one-time tip, the coaching toast.
                  child: guided
                      ? GuideCaption(
                          text: _guideCaption(state, guideMove),
                          onSkip: _skipGuide,
                        )
                      : _tip != null && result == null
                      ? ToyToast(text: _tip!)
                      // One toast that fades, holding its last words while it
                      // does, rather than a switcher: deselecting and reselecting
                      // the same tube would hand a switcher two identical keys.
                      : AnimatedOpacity(
                          duration: const Duration(milliseconds: 160),
                          opacity: coaching ? 1 : 0,
                          child: _coach == null
                              ? const SizedBox.shrink()
                              : ToyToast(
                                  leading: ToyBall.id(_coach!.color, size: 22),
                                  text:
                                      'Holding ${_coach!.count}'
                                      ' · drop into a bouncing tube',
                                ),
                        ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: BoardView(
                    onTapTube: _onTapTube,
                    onBallLanded: _onBallLanded,
                    guideTube: guideTube,
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
                WinMomentCaption(
                  movesUsed: state.movesUsed,
                  minMoves: state.level.minMoves,
                  opacity: (elapsed / 180).clamp(0.0, 1.0),
                )
              else ...[
                if (state.isStuck && !state.isWon)
                  _StuckBanner(
                    onUndo: () =>
                        ref.read(gameControllerProvider.notifier).undo(),
                  ),
                BoardControls(
                  // Hidden until par is spent — see
                  // GameState.canOfferExtraTube for why that particular
                  // moment, which is about what the server will accept rather
                  // than about difficulty.
                  onExtraTube: state.canOfferExtraTube ? _onExtraTube : null,
                  onUndo: state.canUndo
                      ? () => ref.read(gameControllerProvider.notifier).undo()
                      : null,
                  onRestart: () {
                    // Banked BEFORE the restart, which discards the clock.
                    // Time spent on an attempt somebody threw away is still
                    // time they played.
                    _bankPlaytime();
                    _startLevel(state.level.id);
                  },
                  onHint: _onHint,
                  hintBusy: state.hintPending,
                  hintBadge: _hintBadge(),
                ),
              ],
            ],
          ),
        );

        return Stack(
          fit: StackFit.expand,
          children: [
            // Offstage once the result covers it completely. It used to keep
            // painting underneath — board, rays and confetti, every frame, all
            // invisible — which doubled the GPU work for as long as the result
            // was up. Offstage keeps its state (Replay needs it) and mutes its
            // tickers too.
            Offstage(offstage: settled >= 1, child: playfield),
            if (result != null && _profile.confetti != null)
              WinConfetti(
                t:
                    ((elapsed - _profile.confetti!.at) /
                            _profile.confetti!.length)
                        .clamp(0.0, 1.0),
                seed: state.level.id,
              ),
            if (result != null && settled > 0)
              Opacity(
                opacity: settled,
                child: WinResult(
                  profile: _profile,
                  elapsedMs: elapsed,
                  levelId: state.level.id,
                  board: state.board,
                  stars: result.stars,
                  movesUsed: state.movesUsed,
                  minMoves: state.level.minMoves,
                  previousBest: result.previousBest,
                  isNewBest: result.isNewBest,
                  elapsedSeconds: result.elapsedSeconds,
                  parSeconds: result.parSeconds,
                  points: result.points,
                  previousFastest: result.previousFastest,
                  bandName: band.name,
                  worldNumber: bands.indexOf(band) + 1,
                  bandClearedBefore: (clearedNow - 1).clamp(0, band.length),
                  bandClearedAfter: clearedNow,
                  bandTotal: band.length,
                  onNext: levelSet.byId(state.level.id + 1) == null
                      ? null
                      : () => _advanceFrom(state.level.id, state.level.id + 1),
                  onReplay: () => _startLevel(state.level.id),
                  onLevels: _exit,
                  interactive: !_skipActive,
                ),
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
        );
      },
    );
  }

  /// Free hints plus banked credits: what the Hint button can give without a
  /// video. Zero turns the badge into a ▶.
  int _hintBadge() {
    final money = ref.watch(monetizationProvider);
    return money.freeHintsRemaining + money.hintCredits;
  }
}

/// Surfaced the moment the board has no legal move left.
class _StuckBanner extends StatelessWidget {
  final VoidCallback onUndo;

  const _StuckBanner({required this.onUndo});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
      child: ToyBox(
        color: Toy.tomatoTint,
        radius: Toy.rButton,
        shadow: 3,
        padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'No moves left — step back and try another line.',
                style: Toy.ui(13, weight: FontWeight.w700),
              ),
            ),
            const SizedBox(width: 8),
            Pressable(
              onPressed: onUndo,
              depth: 2,
              child: ToyBox(
                radius: Toy.rChip,
                shadow: 2,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                child: Text('Undo', style: Toy.ui(14, weight: FontWeight.w800)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) =>
      const ToyScaffold(child: Center(child: PourLoader(ballSize: 30)));
}

class _LoadFailed extends StatelessWidget {
  final String message;

  const _LoadFailed({required this.message});

  @override
  Widget build(BuildContext context) => ToyScaffold(
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Could not load levels', style: Toy.display(26)),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Toy.ui(14, weight: FontWeight.w500, color: Toy.inkMuted),
          ),
        ],
      ),
    ),
  );
}

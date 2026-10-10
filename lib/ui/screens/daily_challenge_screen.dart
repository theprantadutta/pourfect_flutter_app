/// Today's challenge, played.
///
/// A separate screen from the campaign board rather than a mode flag on it.
/// The two share every widget that draws or handles the board, and share
/// nothing else: this has no bands, no next level, no star gate and no local
/// progress row, and the campaign has no streak, no rank and no submission.
/// Threading both through one screen would mean a branch at every one of those
/// points, and the branch that eventually goes wrong is the one that records a
/// daily as campaign progress.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/ads/ad_service.dart';
import '../../services/audio/audio_service.dart';
import '../../services/analytics/analytics_service.dart';
import '../../services/api/api_result.dart';
import '../../services/api/daily_api.dart';
import '../../services/api/push_service.dart';
import '../../state/daily_controller.dart';
import '../../state/game_controller.dart';
import '../../state/hint_controller.dart';
import '../../state/monetization_controller.dart';
import '../../state/play_history.dart';
import '../../state/providers.dart';
import '../../state/streak_controller.dart';
import '../format.dart';
import '../theme/toy.dart';
import '../widgets/board_view.dart';
import '../widgets/hud.dart';
import '../widgets/leave_board_prompt.dart';
import '../widgets/level_clock.dart';
import '../widgets/toy_kit.dart';
import '../widgets/pour_loader.dart';
import '../widgets/streak_dialog.dart';
import '../widgets/streak_glyphs.dart';

class DailyChallengeScreen extends ConsumerStatefulWidget {
  final VoidCallback onExit;

  const DailyChallengeScreen({super.key, required this.onExit});

  @override
  ConsumerState<DailyChallengeScreen> createState() =>
      _DailyChallengeScreenState();
}

class _DailyChallengeScreenState extends ConsumerState<DailyChallengeScreen>
    with WidgetsBindingObserver {
  late final GameController _game;
  late final AudioService _audio;

  /// Held from initState for the same reason as [_game]: dispose banks the
  /// time played, and reading a provider during teardown is when it throws.
  late final PlayHistoryController _history;

  /// True once a move has been made on this board. See [_bankPlaytime].
  bool _moved = false;

  /// The challenge THIS SCREEN is playing.
  ///
  /// Captured when the board is handed to the game controller and never
  /// re-read from the shared provider afterwards. The shell refreshes the
  /// daily on every app resume, so a board left open across midnight UTC would
  /// otherwise have tomorrow's challenge underneath it — and the result would
  /// be submitted against a date and an optimum the player never saw.
  DailyChallenge? _playing;

  /// Set when the board is solved and the server has answered.
  DailyResult? _result;
  bool _submitting = false;
  String? _submitError;

  PushPermission? _pushPermission;
  bool _reminderOn = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _game = ref.read(gameControllerProvider.notifier);
    // The quieter music while a board is up; the menu loop again on the way
    // out. Held here because dispose must not read providers.
    _audio = ref.read(audioServiceProvider)..setScene(MusicScene.play);
    _history = ref.read(playHistoryProvider.notifier);
    // Solves each position as it is reached, as on the campaign board, so a
    // hint is instant and a dead end is known before anybody asks.
    ref.read(positionAnalystProvider);
    ref.read(dailyProvider.notifier).ensureLoaded();

    // Read, never requested. Knowing the answer is what lets the offer appear
    // only where it is worth making.
    ref.read(pushServiceProvider).permission().then((permission) {
      if (mounted) setState(() => _pushPermission = permission);
    });
  }

  @override
  void dispose() {
    _audio.setScene(MusicScene.menu);
    WidgetsBinding.instance.removeObserver(this);
    // Same rule as the campaign board: the session ends when the screen does,
    // so nothing in flight can land on a board nobody is looking at.
    //
    // Playtime is NOT banked here. Banking writes provider state, and doing
    // that while the tree is torn down throws: it is banked on the way out
    // instead (see [_leave] and the PopScope in build).
    _game.endSession();
    super.dispose();
  }

  /// The daily is ranked by moves, then TIME, so its clock must stop when the
  /// app does. It never did: a board left in the background for ten minutes
  /// came back ten minutes slower, and an optimal solve sank down the board.
  @override
  void didChangeAppLifecycleState(AppLifecycleState lifecycle) {
    final state = ref.read(gameControllerProvider);
    if (state == null || state.level.id != 0) return;
    switch (lifecycle) {
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        _bankPlaytime();
        _game.pauseClock();
      case AppLifecycleState.resumed:
        _game.resumeClock();
      case AppLifecycleState.inactive:
        break;
    }
  }

  /// Today's board with moves on it, not yet solved: leaving loses them.
  bool get _midGame {
    final live = ref.read(gameControllerProvider);
    return live != null &&
        live.level.id == 0 &&
        live.movesUsed > 0 &&
        !live.isWon &&
        _result == null &&
        !_submitting;
  }

  bool _confirmingLeave = false;

  /// Set once the player has said yes — see the same flag on the game screen.
  bool _leaving = false;

  /// Leaves at once from an untouched or finished board, and asks first from
  /// one with moves on it.
  Future<void> _confirmLeave() async {
    if (!_midGame) return _leave();
    if (_confirmingLeave) return;
    _confirmingLeave = true;
    final running = ref.read(gameControllerProvider)?.isClockRunning ?? false;
    if (running) _game.pauseClock();
    try {
      final leave = await confirmLeaveBoard(
        context,
        lost:
            "Your moves on today's Daily Pour won't be saved. You can start "
            'it again any time today.',
      );
      if (!mounted) return;
      if (leave) {
        setState(() => _leaving = true);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _leave();
        });
      } else if (running) {
        _game.resumeClock();
      }
    } finally {
      _confirmingLeave = false;
    }
  }

  /// Leaves the screen, banking the time played first.
  void _leave() {
    _bankPlaytime();
    widget.onExit();
  }

  /// Logs the time spent on today's board into the play history.
  ///
  /// The daily never did this, so a day spent only on the daily was not a
  /// played day: the streak on the hub read 0 for somebody who had just
  /// finished today's board. Banked as PLAYTIME, not as a solve — the daily is
  /// not a campaign level, and "levels solved" must not count it.
  ///
  /// Only once a move has been made. Opening a daily that is already finished
  /// to look at the result is not playing it.
  void _bankPlaytime() {
    if (!_moved) return;
    final seconds = _game.takeUnbankedSeconds();
    if (seconds > 0) _history.recordPlaytime(seconds: seconds);
  }

  void _startIfReady(DailyChallenge challenge) {
    if (_playing != null) return;
    _playing = challenge;
    // Level set version zero: this board is not part of the campaign and must
    // never be mistaken for one in progress or in analytics.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _game.startLevel(challenge.asLevel, levelSetVersion: 0);
    });
  }

  Future<void> _onTapTube(int tube) async {
    final outcome = _game.tapTube(tube);
    if (outcome == TapOutcome.selected ||
        outcome == TapOutcome.deselected ||
        outcome == TapOutcome.reselected) {
      ref.read(audioServiceProvider).select();
    }

    final state = ref.read(gameControllerProvider);
    if ((state?.movesUsed ?? 0) > 0) _moved = true;
    if (state != null && state.isWon && _result == null && !_submitting) {
      await _submit();
    }
  }

  /// True when the result just reached a streak milestone.
  bool _milestone = false;

  /// Opens the streak, pausing the board's clock while it is up — the video
  /// for a freeze is watched from in there.
  Future<void> _openStreak() async {
    final running = ref.read(gameControllerProvider)?.isClockRunning ?? false;
    if (running) _game.pauseClock();
    try {
      await showStreakDialog(
        context,
        watchVideo: () => ref
            .read(monetizationProvider.notifier)
            .offerRewarded(RewardedPlacement.streakFreeze, levelId: 0),
      );
    } finally {
      if (running && mounted) _game.resumeClock();
    }
  }

  Future<void> _submit() async {
    final state = ref.read(gameControllerProvider);
    final playing = _playing;
    if (state == null || playing == null) return;

    setState(() {
      _submitting = true;
      _submitError = null;
    });

    ref.read(audioServiceProvider).win();
    ref.read(hapticsServiceProvider).levelCompleted();
    _bankPlaytime();

    // Whether this submission is the one that completes the day. A replay of
    // a finished board returns the same streak and must not celebrate twice.
    final firstToday = !playing.isPlayed;

    final result = await ref
        .read(dailyProvider.notifier)
        .submit(
          // The board that was opened, not whatever the shared provider holds
          // now. A refresh while this screen is up must not retarget a result.
          challenge: playing,
          movesUsed: state.movesUsed,
          durationSeconds: state.elapsedSecondsAt(DateTime.now()),
        );

    if (!mounted) return;

    setState(() {
      _submitting = false;
      switch (result) {
        case ApiOk(:final value):
          _result = value;
          _milestone =
              firstToday && kStreakMilestones.contains(value.dailyStreak);
          if (_milestone) ref.read(audioServiceProvider).ui(UiCue.streak);
        case ApiFailure(:final kind):
          // The board IS solved — that happened on this device and nothing can
          // take it back. Only the ranking is missing, and saying so is more
          // honest than a spinner that never resolves.
          _submitError = kind == ApiFailureKind.refused
              ? 'The server would not accept that result.'
              : 'Solved — but the result could not be sent. Try again later.';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final daily = ref.watch(dailyProvider);

    if (daily.challenge != null) _startIfReady(daily.challenge!);

    // Rendered from the challenge THIS screen started, so a background refresh
    // cannot swap the header, the optimum or the date out from under a board
    // the player is halfway through.
    final playing = _playing;

    // The system back gesture pops without passing through [_leave], so the
    // time played is banked here as well. Banking twice is harmless: the
    // second call finds nothing left to hand over.
    return PopScope(
      canPop: _leaving || !_midGame,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          _bankPlaytime();
        } else {
          _confirmLeave();
        }
      },
      child: ToyScaffold(
        surface: ToySurface.daily,
        padding: EdgeInsets.zero,
        child: playing == null
            ? _Unavailable(state: daily, onBack: _leave)
            : _board(playing, daily),
      ),
    );
  }

  Widget _board(DailyChallenge challenge, DailyState daily) {
    // The game controller is shared with the campaign, and the daily board is
    // handed to it a frame after this screen first builds. Until then it
    // still holds the last campaign level: its board, its moves, and, if it
    // was won, today stamped as solved. Only the daily's own state counts.
    final live = ref.watch(gameControllerProvider);
    final state = live?.level.id == 0 ? live : null;

    // Today counts as stamped the moment the board is solved on this device —
    // nothing the server says afterwards can un-solve it — or when the
    // challenge arrived already played.
    final solvedToday =
        challenge.isPlayed || (state?.isWon ?? false) || _result != null;

    // The only streak this device is ever told is the server's answer to a
    // submission. It covers today and the unbroken run of days before it.
    final streak =
        _result?.dailyStreak ??
        (challenge.isPlayed ? daily.result?.dailyStreak : null);

    return Column(
      children: [
        BoardHud(
          levelId: 0,
          // "Daily Pour". The HUD capitalizes the label and appends the value;
          // a daily board has no level id, and "Level 0" reads as a bug.
          titleLabel: 'Daily',
          titleValue: 'Pour',
          titleColor: Colors.white,
          bandName: _dateLabel(challenge.date),
          movesUsed: state?.movesUsed ?? 0,
          minMoves: challenge.minMoves,
          clock: state == null
              ? null
              : LevelClock(
                  elapsedSeconds: () =>
                      ref
                          .read(gameControllerProvider)
                          ?.elapsedSecondsAt(DateTime.now()) ??
                      0,
                  parSeconds: state.parSeconds,
                  isRunning: state.isClockRunning,
                  fontSize: 12,
                  detailed: true,
                ),
          onExit: _confirmLeave,
        ),

        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _WeekStrip(
            today: challenge.date,
            solvedToday: solvedToday,
            streak: streak,
            info: ref.watch(streakProvider),
            onTap: _openStreak,
          ),
        ),
        const SizedBox(height: 14),

        // The white tray the board sits on. Its hard shadow is part of the
        // layout, so the padding under it leaves room for all 5px of it.
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 5),
            child: ToyBox(
              radius: Toy.rHero,
              shadow: 5,
              padding: const EdgeInsets.fromLTRB(10, 14, 10, 12),
              child: state == null
                  ? const SizedBox.expand()
                  : BoardView(
                      onTapTube: _onTapTube,
                      onBallLanded: _onBallLanded,
                    ),
            ),
          ),
        ),

        if (_result != null || _submitError != null)
          _Outcome(
            result: _result,
            milestone: _milestone,
            error: _submitError,
            onDone: _leave,
            onRetry: _submitError == null ? null : _submit,
            onRemindMe: _canOfferReminder ? _enableReminder : null,
            reminderOn: _reminderOn,
          )
        else
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: BoardControls(
              onUndo: (state?.canUndo ?? false) ? _onUndo : null,
              onRestart: _onRestart,
              onHint: _onHint,
              hintBusy: state?.hintPending ?? false,
            ),
          ),
      ],
    );
  }

  void _onBallLanded(double fill, bool completed) {
    ref.read(audioServiceProvider).pour(fill: fill);
    if (completed) {
      // The tube that finishes the board has its own, brighter cue.
      final finished = ref.read(gameControllerProvider)?.isWon ?? false;
      ref.read(audioServiceProvider).tubeComplete(last: finished);
      ref.read(hapticsServiceProvider).tubeCompleted();
    } else {
      ref.read(hapticsServiceProvider).ballLanded();
    }
  }

  void _onUndo() => _game.undo();

  void _onRestart() {
    // Restarts the board being played, not whatever is cached now.
    final playing = _playing;
    if (playing == null) return;
    _game.startLevel(playing.asLevel, levelSetVersion: 0);
  }

  /// Whether offering the reminder is appropriate right now.
  ///
  /// Only after a board has actually been finished, and only if the OS has
  /// never been asked. A second prompt is not available on iOS at all, and
  /// nagging on Android earns an uninstall rather than a reminder.
  bool get _canOfferReminder =>
      _result != null && _pushPermission == PushPermission.notAsked;

  Future<void> _enableReminder() async {
    final on = await ref.read(pushServiceProvider).requestAndRegister();
    ref
        .read(analyticsServiceProvider)
        .log(NotificationPermissionAnswered(placement: 'daily', granted: on));
    if (!mounted) return;
    setState(() {
      _reminderOn = on;
      _pushPermission = on ? PushPermission.granted : PushPermission.denied;
    });
  }

  Future<void> _onHint() async {
    // Free on the daily, and unmetered.
    //
    // The rewarded-video paywall exists to monetise the campaign, where a
    // player has 150 levels to spend hints on. Charging for a hint on the one
    // board a day that also decides a public ranking would make the
    // leaderboard a question of who watched an ad, which is a worse board and
    // a worse product.
    final hints = ref.read(hintServiceProvider);
    final current = ref.read(gameControllerProvider);
    if (current?.hintPending ?? false) {
      hints.cancel();
      return;
    }
    if (current == null || current.hintMove != null) return;

    // Asked first, so a position with no way forward is said out loud
    // instead of the button simply doing nothing.
    final check = await hints.check();
    if (!mounted) return;
    switch (check.availability) {
      case HintAvailability.available:
        await hints.request();
      case HintAvailability.deadEnd:
        final back = check.stepsBack;
        showToyToast(
          context,
          back == null
              ? 'No way to finish from here. Restart to try another line.'
              : 'No way to finish from here. Undo '
                    '${back == 1 ? '1 move' : '$back moves'} to get back on '
                    'track.',
          actionLabel: back == null ? 'Restart' : 'Undo $back',
          onAction: () {
            if (back == null) return _onRestart();
            for (var i = 0; i < back; i++) {
              if (!_game.undo()) break;
            }
          },
          duration: const Duration(seconds: 6),
        );
      case HintAvailability.unavailable:
        showToyToast(context, 'No hint for this position.');
      case HintAvailability.cancelled:
      case HintAvailability.notApplicable:
        break;
    }
  }
}

/// "Sun, Sep 27" — the date the board belongs to, under the title.
String _dateLabel(DateTime date) {
  const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${days[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}';
}

/// What the player sees when there is no board to play.
class _Unavailable extends StatelessWidget {
  final DailyState state;
  final VoidCallback onBack;

  const _Unavailable({required this.state, required this.onBack});

  @override
  Widget build(BuildContext context) {
    // Three different reasons, three different sentences. "Something went
    // wrong" would cover all of them and help with none.
    final (title, detail) = state.loading
        ? ('Loading today’s board', '')
        : state.isOff
        ? (
            'Daily challenges are off in this build',
            'The campaign is unaffected — every level is on this device.',
          )
        : (
            'No board today',
            'Today’s challenge comes from the server and it could not be '
                'reached. The campaign does not need it.',
          );

    final back = Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Row(children: [ToyBackButton(onPressed: onBack)]),
    );

    // While the board is on its way, the pour plays rather than a sentence
    // saying it is loading.
    if (state.loading) {
      return Column(
        children: [
          back,
          const Expanded(
            child: Center(
              child: PourLoader(
                ballSize: 30,
                caption: 'Pouring today’s board…',
                captionColor: Colors.white,
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        back,
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: Toy.display(26, color: Colors.white, shadow: 2),
                ),
                if (detail.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  SizedBox(
                    width: 300,
                    child: Text(
                      detail,
                      textAlign: TextAlign.center,
                      style: Toy.ui(15, color: Colors.white),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                ToyButton.secondary(label: 'Back to levels', onPressed: onBack),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// The seven stamps of this week, Monday first.
///
/// Done days are mint with a tick, today is yellow with the date until it is
/// solved, and the days still to come are blank. Days before today that the
/// server's streak does not cover are drawn dashed: this device is never told
/// which past dailies were played, only how long the unbroken run ending
/// today is, so "not known to be played" is the honest reading of the rest.
class _WeekStrip extends StatefulWidget {
  /// The date of the board being played.
  final DateTime today;
  final bool solvedToday;

  /// The server's streak, including today, once it has said. Null before.
  final int? streak;

  /// The server's calendar, once fetched: which days were played and which a
  /// freeze covered. Null before, when the strip falls back to [streak].
  final StreakInfo? info;

  /// Opens the streak.
  final VoidCallback onTap;

  const _WeekStrip({
    required this.today,
    required this.solvedToday,
    required this.streak,
    required this.info,
    required this.onTap,
  });

  @override
  State<_WeekStrip> createState() => _WeekStripState();
}

class _WeekStripState extends State<_WeekStrip>
    with SingleTickerProviderStateMixin {
  /// Today's stamp landing: scale 1.4 → 1 and −6° → 0 over 260ms. Starts
  /// settled, so a board that opens already solved shows the stamp at rest.
  late final AnimationController _stamp = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
    value: 1,
  );

  @override
  void didUpdateWidget(_WeekStrip old) {
    super.didUpdateWidget(old);
    // The haptic for this moment is the level-complete thunk the screen
    // already plays on the same frame; a second buzz would blur the two.
    if (!old.solvedToday && widget.solvedToday && !Toy.calm(context)) {
      _stamp.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _stamp.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const letters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final today = DateTime.utc(
      widget.today.year,
      widget.today.month,
      widget.today.day,
    );
    final monday = today.subtract(Duration(days: today.weekday - 1));
    final streak =
        widget.streak ?? widget.info?.current ?? (widget.solvedToday ? 1 : 0);

    return Pressable(
      onPressed: widget.onTap,
      semanticLabel: 'Your streak: ${plural(streak, 'day')}. Open',
      child: ToyBox(
        radius: Toy.rControl,
        shadow: 4,
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  StreakFlame(size: 22, lit: streak > 0),
                  const SizedBox(height: 2),
                  Text('$streak', style: Toy.numbers(13)),
                ],
              ),
            ),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  for (var i = 0; i < 7; i++)
                    _day(
                      letters[i],
                      monday.add(Duration(days: i)),
                      today,
                      streak,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _day(String letter, DateTime day, DateTime today, int streak) {
    final ago = today.difference(day).inDays;
    final isToday = ago == 0;
    final info = widget.info;
    // The server's calendar when there is one; before it arrives, the run
    // ending today is all that is known.
    final done = isToday
        ? widget.solvedToday
        : info != null
        ? info.played.contains(day)
        : ago > 0 && ago < streak;
    final frozen = !done && (info?.frozen.contains(day) ?? false);

    final Widget stamp;
    final String state;
    if (frozen) {
      state = 'missed, covered by a freeze';
      stamp = const _Stamp(
        color: Toy.blue,
        child: StreakSnowflake(size: 16, color: Colors.white),
      );
    } else if (done) {
      state = isToday ? 'played today' : 'played';
      stamp = _Stamp(
        color: Toy.mint,
        child: const ToyIcon(ToyGlyph.check, size: 16),
      );
    } else if (isToday) {
      state = 'today, not played yet';
      stamp = _Stamp(
        color: Toy.yellow,
        child: Text('${day.day}', style: Toy.numbers(14)),
      );
    } else if (ago > 0) {
      state = 'not played';
      stamp = const _Stamp(dashed: true);
    } else {
      state = 'still to come';
      stamp = const _Stamp(faint: true);
    }

    final animated = isToday && done
        ? AnimatedBuilder(
            animation: _stamp,
            child: stamp,
            builder: (context, child) {
              final t = Curves.easeOutBack.transform(_stamp.value);
              return Transform.rotate(
                angle: (1 - t) * -6 * math.pi / 180,
                child: Transform.scale(scale: 1.4 - 0.4 * t, child: child),
              );
            },
          )
        : stamp;

    return Semantics(
      label: '${_weekdayName(day.weekday)}, $state',
      excludeSemantics: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            letter,
            style: Toy.ui(10, weight: FontWeight.w800, color: Toy.inkMuted),
          ),
          const SizedBox(height: 3),
          animated,
        ],
      ),
    );
  }

  static String _weekdayName(int weekday) => const [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ][weekday - 1];
}

/// One 32px day stamp.
class _Stamp extends StatelessWidget {
  final Color color;
  final Widget? child;
  final bool dashed;
  final bool faint;

  const _Stamp({
    this.color = Toy.card,
    this.child,
    this.dashed = false,
    this.faint = false,
  });

  @override
  Widget build(BuildContext context) {
    if (dashed) {
      return const SizedBox.square(
        dimension: 32,
        child: CustomPaint(painter: _DashedSquarePainter()),
      );
    }
    return Opacity(
      opacity: faint ? 0.3 : 1,
      child: Container(
        width: 32,
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(Toy.rChip),
          border: Border.all(color: Toy.ink, width: Toy.stroke),
        ),
        child: child,
      ),
    );
  }
}

/// A dashed 32px rounded square at 45% ink: a day with no stamp on it.
class _DashedSquarePainter extends CustomPainter {
  const _DashedSquarePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final outline = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          (Offset.zero & size).deflate(Toy.stroke / 2),
          const Radius.circular(Toy.rChip - 1),
        ),
      );
    final paint = Paint()
      ..color = Toy.ink.withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = Toy.stroke;
    for (final metric in outline.computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += 9) {
        canvas.drawPath(
          metric.extractPath(d, math.min(d + 5, metric.length)),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_DashedSquarePainter old) => false;
}

/// The result of a submitted board.
class _Outcome extends StatelessWidget {
  final DailyResult? result;

  /// The streak just reached one of [kStreakMilestones].
  final bool milestone;

  final String? error;
  final VoidCallback onDone;
  final VoidCallback? onRetry;

  /// Null unless offering a reminder is appropriate — see the screen.
  final VoidCallback? onRemindMe;

  final bool reminderOn;

  const _Outcome({
    required this.result,
    this.milestone = false,
    required this.error,
    required this.onDone,
    required this.onRetry,
    required this.onRemindMe,
    required this.reminderOn,
  });

  @override
  Widget build(BuildContext context) {
    final outcome = result;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: ToyBox(
        radius: Toy.rCard,
        shadow: 4,
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (outcome == null) ...[
              Text(error ?? '', textAlign: TextAlign.center, style: Toy.ui(14)),
              if (onRetry != null) ...[
                const SizedBox(height: 12),
                ToyButton.secondary(
                  label: 'Try again',
                  onPressed: onRetry,
                  height: 44,
                ),
              ],
            ] else ...[
              if (milestone)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const StreakFlame(size: 28),
                    const SizedBox(width: 8),
                    Text(
                      '${outcome.dailyStreak}-day streak!',
                      style: Toy.display(24, color: Toy.tomato),
                    ),
                  ],
                )
              else
                Text(
                  outcome.isPersonalBest ? 'A new best' : 'Solved',
                  style: Toy.display(24),
                ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _Figure(value: '${outcome.moves}', label: 'moves'),
                  _Figure(
                    value: plural(outcome.dailyStreak, 'day'),
                    label: 'streak',
                    warm: outcome.dailyStreak > 1,
                  ),
                  // No name means no board, and no rank. Saying "unranked" is
                  // the honest answer rather than a number the leaderboard
                  // would contradict a moment later.
                  _Figure(
                    value: outcome.rank == null ? '—' : '#${outcome.rank}',
                    label: outcome.rank == null
                        ? 'unranked'
                        : 'of ${outcome.totalPlayers}',
                  ),
                ],
              ),
            ],
            if (reminderOn) ...[
              const SizedBox(height: 12),
              Text(
                'You will get one reminder tomorrow evening.',
                textAlign: TextAlign.center,
                style: Toy.ui(12.5, color: Toy.inkMuted),
              ),
            ] else if (onRemindMe != null) ...[
              const SizedBox(height: 12),
              ToyButton.secondary(
                label: 'Remind me tomorrow',
                onPressed: onRemindMe,
                height: 44,
              ),
            ],
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ToyButton(
                label: 'DONE',
                onPressed: onDone,
                height: 50,
                fontSize: 22,
                shadow: 4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Figure extends StatelessWidget {
  final String value;
  final String label;
  final bool warm;

  const _Figure({required this.value, required this.label, this.warm = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: Toy.numbers(20, color: warm ? Toy.tomato : Toy.ink)),
        const SizedBox(height: 2),
        Text(label, style: Toy.ui(12, color: Toy.inkMuted)),
      ],
    );
  }
}

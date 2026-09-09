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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/api/api_result.dart';
import '../../services/api/daily_api.dart';
import '../../services/api/push_service.dart';
import '../../state/daily_controller.dart';
import '../../state/game_controller.dart';
import '../../state/hint_controller.dart';
import '../../state/providers.dart';
import '../format.dart';
import '../theme/tokens.dart';
import '../theme/typography.dart';
import '../widgets/board_view.dart';
import '../widgets/hud.dart';
import '../widgets/level_clock.dart';
import '../widgets/pressable.dart';

class DailyChallengeScreen extends ConsumerStatefulWidget {
  final VoidCallback onExit;

  const DailyChallengeScreen({super.key, required this.onExit});

  @override
  ConsumerState<DailyChallengeScreen> createState() =>
      _DailyChallengeScreenState();
}

class _DailyChallengeScreenState extends ConsumerState<DailyChallengeScreen> {
  late final GameController _game;

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
    _game = ref.read(gameControllerProvider.notifier);
    ref.read(dailyProvider.notifier).ensureLoaded();

    // Read, never requested. Knowing the answer is what lets the offer appear
    // only where it is worth making.
    ref.read(pushServiceProvider).permission().then((permission) {
      if (mounted) setState(() => _pushPermission = permission);
    });
  }

  @override
  void dispose() {
    // Same rule as the campaign board: the session ends when the screen does,
    // so nothing in flight can land on a board nobody is looking at.
    _game.endSession();
    super.dispose();
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
    if (state != null && state.isWon && _result == null && !_submitting) {
      await _submit();
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
    final tokens = PourfectTokens.of(context);
    final daily = ref.watch(dailyProvider);

    if (daily.challenge != null) _startIfReady(daily.challenge!);

    // Rendered from the challenge THIS screen started, so a background refresh
    // cannot swap the header, the optimum or the date out from under a board
    // the player is halfway through.
    final playing = _playing;

    return Scaffold(
      backgroundColor: tokens.surface,
      body: SafeArea(
        child: playing == null
            ? _Unavailable(state: daily, onBack: widget.onExit)
            : _board(tokens, playing),
      ),
    );
  }

  Widget _board(PourfectTokens tokens, DailyChallenge challenge) {
    final state = ref.watch(gameControllerProvider);

    return Column(
      children: [
        BoardHud(
          levelId: 0,
          // The day of the month, under "DAILY". A daily board has no level
          // id, and heading one "LEVEL 00" reads as a bug.
          titleLabel: 'DAILY',
          titleValue: challenge.date.day.toString().padLeft(2, '0'),
          // The right-hand block carries the move count against the proven
          // optimum, so the label names that rather than repeating the word
          // already at the top left.
          bandName: 'Moves',
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
                  fontSize: 19,
                ),
          onExit: widget.onExit,
        ),

        Expanded(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: tokens.space4),
            child: state == null
                ? const SizedBox.shrink()
                : BoardView(onTapTube: _onTapTube, onBallLanded: _onBallLanded),
          ),
        ),

        if (_result != null || _submitError != null)
          _Outcome(
            result: _result,
            error: _submitError,
            onDone: widget.onExit,
            onRetry: _submitError == null ? null : _submit,
            onRemindMe: _canOfferReminder ? _enableReminder : null,
            reminderOn: _reminderOn,
          )
        else
          BoardControls(
            onUndo: (state?.canUndo ?? false) ? _onUndo : null,
            onRestart: _onRestart,
            onHint: _onHint,
            hintBusy: state?.hintPending ?? false,
          ),
      ],
    );
  }

  void _onBallLanded(double fill, bool completed) {
    ref.read(audioServiceProvider).pour(fill: fill);
    if (completed) {
      ref.read(audioServiceProvider).tubeComplete();
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
    if (ref.read(gameControllerProvider)?.hintPending ?? false) {
      hints.cancel();
      return;
    }
    await hints.request();
  }
}

/// What the player sees when there is no board to play.
class _Unavailable extends StatelessWidget {
  final DailyState state;
  final VoidCallback onBack;

  const _Unavailable({required this.state, required this.onBack});

  @override
  Widget build(BuildContext context) {
    final tokens = PourfectTokens.of(context);

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

    return Padding(
      padding: EdgeInsets.all(tokens.space5),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title, style: titleStyle(tokens).copyWith(fontSize: 18)),
          if (detail.isNotEmpty) ...[
            SizedBox(height: tokens.space2),
            SizedBox(
              width: 300,
              child: Text(
                detail,
                textAlign: TextAlign.center,
                style: bodyStyle(tokens).copyWith(fontSize: 14),
              ),
            ),
          ],
          SizedBox(height: tokens.space4),
          Pressable(
            onPressed: onBack,
            child: Text(
              'Back to levels',
              style: actionStyle(tokens, color: tokens.accent),
            ),
          ),
        ],
      ),
    );
  }
}

/// The result of a submitted board.
class _Outcome extends StatelessWidget {
  final DailyResult? result;
  final String? error;
  final VoidCallback onDone;
  final VoidCallback? onRetry;

  /// Null unless offering a reminder is appropriate — see the screen.
  final VoidCallback? onRemindMe;

  final bool reminderOn;

  const _Outcome({
    required this.result,
    required this.error,
    required this.onDone,
    required this.onRetry,
    required this.onRemindMe,
    required this.reminderOn,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = PourfectTokens.of(context);
    final outcome = result;

    return Padding(
      padding: EdgeInsets.all(tokens.space4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (outcome == null) ...[
            Text(
              error ?? '',
              textAlign: TextAlign.center,
              style: bodyStyle(tokens).copyWith(fontSize: 14),
            ),
            if (onRetry != null) ...[
              SizedBox(height: tokens.space3),
              Pressable(
                onPressed: onRetry,
                child: Text(
                  'Try again',
                  style: actionStyle(tokens, color: tokens.accent),
                ),
              ),
            ],
          ] else ...[
            Text(
              outcome.isPersonalBest ? 'A new best' : 'Solved',
              style: titleStyle(tokens).copyWith(fontSize: 20),
            ),
            SizedBox(height: tokens.space3),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _Figure(value: '${outcome.moves}', label: 'moves'),
                SizedBox(width: tokens.space5),
                _Figure(
                  value: plural(outcome.dailyStreak, 'day'),
                  label: 'streak',
                  warm: outcome.dailyStreak > 1,
                ),
                SizedBox(width: tokens.space5),
                // No name means no board, and no rank. Saying "unranked" is
                // the honest answer rather than a number the leaderboard would
                // contradict a moment later.
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
            SizedBox(height: tokens.space4),
            Text(
              'You will get one reminder tomorrow evening.',
              style: bodyStyle(tokens)
                  .copyWith(fontSize: 12.5, color: tokens.dimText),
            ),
          ] else if (onRemindMe != null) ...[
            SizedBox(height: tokens.space4),
            Pressable(
              onPressed: onRemindMe,
              child: Text(
                'Remind me tomorrow',
                style: actionStyle(tokens, color: tokens.accent),
              ),
            ),
          ],

          SizedBox(height: tokens.space4),
          Pressable(
            onPressed: onDone,
            child: Text(
              'Done',
              style: actionStyle(tokens, color: tokens.textMuted),
            ),
          ),
        ],
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
    final tokens = PourfectTokens.of(context);

    return Column(
      children: [
        Text(
          value,
          style: numericStyle(
            tokens,
            size: 20,
            color: warm ? tokens.accentWarm : tokens.textPrimary,
          ),
        ),
        SizedBox(height: tokens.space1),
        Text(label, style: bodyStyle(tokens).copyWith(fontSize: 12)),
      ],
    );
  }
}

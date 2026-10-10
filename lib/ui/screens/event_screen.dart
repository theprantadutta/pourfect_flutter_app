/// The weekly event: seven boards that climb, one week, one leaderboard.
///
/// [EventScreen] is the week at a glance — the seven boards, the points, the
/// rank and the board. [EventPlayScreen] plays one of them, the way the Daily
/// Pour plays its board: the same game controller, a free hint (a ranked board
/// is not decided by who watched an ad), and the result sent the moment it is
/// solved.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/api/api_result.dart';
import '../../services/api/events_api.dart';
import '../../services/audio/audio_service.dart';
import '../../services/api/leaderboard_api.dart';
import '../../state/event_controller.dart';
import '../../state/game_controller.dart';
import '../../state/hint_controller.dart';
import '../../state/providers.dart';
import '../theme/toy.dart';
import '../transitions.dart';
import '../widgets/board_view.dart';
import '../widgets/hud.dart';
import '../widgets/leave_board_prompt.dart';
import '../widgets/level_clock.dart';
import '../widgets/toy_kit.dart';

/// "ends in 2d 4h", "ends in 3h", "ends in 12m".
String eventEndsIn(DateTime endsAt, {DateTime? now}) {
  final left = endsAt.difference((now ?? DateTime.now()).toUtc());
  if (left.isNegative) return 'ended';
  if (left.inDays >= 1) return 'ends in ${left.inDays}d ${left.inHours % 24}h';
  if (left.inHours >= 1) return 'ends in ${left.inHours}h';
  return 'ends in ${left.inMinutes.clamp(1, 59)}m';
}

class EventScreen extends ConsumerStatefulWidget {
  final VoidCallback onClose;

  const EventScreen({super.key, required this.onClose});

  @override
  ConsumerState<EventScreen> createState() => _EventScreenState();
}

class _EventScreenState extends ConsumerState<EventScreen> {
  Leaderboard? _board;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  Future<void> _refresh() async {
    await ref.read(eventProvider.notifier).refresh();
    final board = await LeaderboardApi(ref.read(apiClientProvider))
        .event(limit: 10);
    if (!mounted) return;
    if (board case ApiOk(:final value)) setState(() => _board = value);
  }

  Future<void> _play(WeeklyEventInfo event, EventBoard board) async {
    await Navigator.of(context).push(
      PourfectPageRoute<void>(
        builder: (route) => EventPlayScreen(
          event: event,
          board: board,
          onExit: () => Navigator.of(route).maybePop(),
        ),
      ),
    );
    if (mounted) unawaited(_refresh());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(eventProvider);
    final event = state.event;
    final columns = MediaQuery.sizeOf(context).width >= 700 ? 7 : 4;

    return Scaffold(
      backgroundColor: Toy.cream,
      body: ToyScaffold(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
        safeBottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ToyHeader(title: 'Weekly event', onBack: widget.onClose),
            const SizedBox(height: 12),
            Expanded(
              child: event == null
                  ? Center(
                      child: state.loading || state.failure == null
                          ? const CircularProgressIndicator(color: Toy.ink)
                          : Text(
                              "Can't reach this week's event right now.",
                              style: Toy.ui(15, color: Toy.inkMuted),
                            ),
                    )
                  : Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: Toy.maxContentWidth,
                        ),
                        child: RefreshIndicator(
                          onRefresh: _refresh,
                          color: Toy.ink,
                          child: ListView(
                            padding: EdgeInsets.fromLTRB(
                              0,
                              2,
                              0,
                              24 + MediaQuery.paddingOf(context).bottom,
                            ),
                            children: [
                              _Summary(event: event),
                              const SizedBox(height: 16),
                              _Tiles(
                                event: event,
                                columns: columns,
                                onPlay: (board) => _play(event, board),
                              ),
                              const SizedBox(height: 18),
                              _Standings(board: _board),
                            ],
                          ),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  final WeeklyEventInfo event;

  const _Summary({required this.event});

  @override
  Widget build(BuildContext context) => ToyBox(
    color: Toy.mint,
    radius: Toy.rHero,
    shadow: 5,
    padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(event.name, style: Toy.display(26, height: 1.05)),
        const SizedBox(height: 2),
        Text(
          '${event.cleared} of ${event.boards.length} boards · '
          '${eventEndsIn(event.endsAt)}',
          style: Toy.ui(14, weight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _Figure(value: '${event.totalPoints}', label: 'points'),
            const SizedBox(width: 10),
            _Figure(
              value: event.rank == null ? '—' : '#${event.rank}',
              label: event.rank != null
                  ? 'of ${event.players}'
                  : event.cleared == 0
                  ? 'play a board to rank'
                  : 'set a name to rank',
            ),
          ],
        ),
      ],
    ),
  );
}

class _Figure extends StatelessWidget {
  final String value;
  final String label;

  const _Figure({required this.value, required this.label});

  @override
  Widget build(BuildContext context) => Expanded(
    child: ToyBox(
      radius: 14,
      shadow: 3,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          Text(value, style: Toy.numbers(20)),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Toy.ui(11.5, color: Toy.inkMuted),
          ),
        ],
      ),
    ),
  );
}

class _Tiles extends StatelessWidget {
  final WeeklyEventInfo event;
  final int columns;
  final void Function(EventBoard) onPlay;

  const _Tiles({
    required this.event,
    required this.columns,
    required this.onPlay,
  });

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      const gap = 10.0;
      final size = (box.maxWidth - gap * (columns - 1)) / columns;
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: [
          for (final board in event.boards)
            SizedBox(
              width: size,
              child: _Tile(
                board: board,
                result: event.results[board.slot],
                onTap: () => onPlay(board),
              ),
            ),
        ],
      );
    },
  );
}

class _Tile extends StatelessWidget {
  final EventBoard board;
  final EventResult? result;
  final VoidCallback onTap;

  const _Tile({required this.board, required this.result, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final done = result != null;
    return Pressable(
      onPressed: onTap,
      semanticLabel: done
          ? 'Board ${board.slot}, ${result!.stars} stars, ${result!.points} points'
          : 'Board ${board.slot}, not played',
      child: ToyBox(
        color: done ? Toy.mint : Toy.card,
        radius: 16,
        shadow: 4,
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Column(
          children: [
            Text('${board.slot}', style: Toy.display(26, height: 1)),
            const SizedBox(height: 4),
            ToyStars(earned: result?.stars ?? 0, size: 12, spacing: 1),
            const SizedBox(height: 4),
            Text(
              done ? '${result!.points} pts' : 'par ${board.minMoves}',
              style: Toy.ui(
                11.5,
                weight: FontWeight.w800,
                color: done ? Toy.ink : Toy.inkMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Standings extends StatelessWidget {
  final Leaderboard? board;

  const _Standings({required this.board});

  @override
  Widget build(BuildContext context) {
    final rows = board?.rows ?? const <LeaderboardRow>[];
    return ToyBox(
      radius: 20,
      shadow: 4,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'This week\'s board',
            style: Toy.ui(16, weight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          if (board == null)
            const Padding(
              padding: EdgeInsets.all(12),
              child: Center(child: CircularProgressIndicator(color: Toy.ink)),
            )
          else if (rows.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text(
                'Nobody on the board yet. Be the first.',
                style: Toy.ui(14, color: Toy.inkMuted),
              ),
            )
          else
            for (final row in rows)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  children: [
                    SizedBox(
                      width: 34,
                      child: Text('#${row.rank}', style: Toy.numbers(14)),
                    ),
                    Expanded(
                      child: Text(
                        row.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Toy.ui(
                          14,
                          weight: row.isYou ? FontWeight.w800 : FontWeight.w600,
                          color: row.isYou ? Toy.tomato : Toy.ink,
                        ),
                      ),
                    ),
                    Text('${row.value}', style: Toy.numbers(14)),
                    Text(
                      ' · ${row.tieBreak ?? 0}/7',
                      style: Toy.ui(12, color: Toy.inkMuted),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}

/// Plays one event board.
class EventPlayScreen extends ConsumerStatefulWidget {
  final WeeklyEventInfo event;
  final EventBoard board;
  final VoidCallback onExit;

  const EventPlayScreen({
    super.key,
    required this.event,
    required this.board,
    required this.onExit,
  });

  @override
  ConsumerState<EventPlayScreen> createState() => _EventPlayScreenState();
}

class _EventPlayScreenState extends ConsumerState<EventPlayScreen>
    with WidgetsBindingObserver {
  late final GameController _game;
  late final AudioService _audio;

  WeeklyEventInfo? _answer;
  bool _submitting = false;
  String? _error;
  bool _leaving = false;
  bool _confirming = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _game = ref.read(gameControllerProvider.notifier);
    // The quieter music while a board is up; the menu loop again on the way
    // out. Held here because dispose must not read providers.
    _audio = ref.read(audioServiceProvider)..setScene(MusicScene.play);
    ref.read(positionAnalystProvider);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _game.startLevel(widget.board.asLevel, levelSetVersion: 0);
    });
  }

  @override
  void dispose() {
    _audio.setScene(MusicScene.menu);
    WidgetsBinding.instance.removeObserver(this);
    _game.endSession();
    super.dispose();
  }

  /// Ranked by points, which include the clock: it stops with the app.
  @override
  void didChangeAppLifecycleState(AppLifecycleState lifecycle) {
    switch (lifecycle) {
      case AppLifecycleState.paused || AppLifecycleState.hidden:
        _game.pauseClock();
      case AppLifecycleState.resumed:
        _game.resumeClock();
      default:
        break;
    }
  }

  bool get _midGame {
    final live = ref.read(gameControllerProvider);
    return live != null &&
        live.level.id == 0 &&
        live.movesUsed > 0 &&
        !live.isWon &&
        _answer == null &&
        !_submitting;
  }

  Future<void> _confirmLeave() async {
    if (!_midGame) return widget.onExit();
    if (_confirming) return;
    _confirming = true;
    final running = ref.read(gameControllerProvider)?.isClockRunning ?? false;
    if (running) _game.pauseClock();
    try {
      final leave = await confirmLeaveBoard(context);
      if (!mounted) return;
      if (leave) {
        setState(() => _leaving = true);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) widget.onExit();
        });
      } else if (running) {
        _game.resumeClock();
      }
    } finally {
      _confirming = false;
    }
  }

  Future<void> _onTapTube(int tube) async {
    final outcome = _game.tapTube(tube);
    if (outcome == TapOutcome.selected ||
        outcome == TapOutcome.deselected ||
        outcome == TapOutcome.reselected) {
      ref.read(audioServiceProvider).select();
    }
    final state = ref.read(gameControllerProvider);
    if (state != null && state.isWon && _answer == null && !_submitting) {
      await _submit();
    }
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

  Future<void> _submit() async {
    final state = ref.read(gameControllerProvider);
    if (state == null) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    ref.read(audioServiceProvider).win();
    ref.read(hapticsServiceProvider).levelCompleted();

    final result = await ref
        .read(eventProvider.notifier)
        .submit(
          event: widget.event,
          slot: widget.board.slot,
          movesUsed: state.movesUsed,
          durationSeconds: state.elapsedSecondsAt(DateTime.now()),
        );
    if (!mounted) return;
    setState(() {
      _submitting = false;
      switch (result) {
        case ApiOk(:final value):
          _answer = value;
        case ApiFailure(:final kind):
          _error = kind == ApiFailureKind.refused
              ? 'The server would not take that result — the event may have ended.'
              : 'Solved — but the result could not be sent. Try again.';
      }
    });
  }

  /// Free, like the daily's: a ranked board must not be decided by who
  /// watched an ad.
  Future<void> _onHint() async {
    final hints = ref.read(hintServiceProvider);
    final current = ref.read(gameControllerProvider);
    if (current?.hintPending ?? false) {
      hints.cancel();
      return;
    }
    if (current == null || current.hintMove != null) return;
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
                    '${back == 1 ? '1 move' : '$back moves'}.',
        );
      default:
        showToyToast(context, 'No hint for this position right now.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final live = ref.watch(gameControllerProvider);
    final state = live?.level.id == 0 ? live : null;
    final answer = _answer;
    final result = answer?.results[widget.board.slot];

    return PopScope(
      canPop: _leaving || !_midGame,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmLeave();
      },
      child: ToyScaffold(
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            BoardHud(
              levelId: 0,
              titleLabel: 'Board',
              titleValue: '${widget.board.slot}',
              bandName:
                  '${widget.event.name} · ${eventEndsIn(widget.event.endsAt)}',
              movesUsed: state?.movesUsed ?? 0,
              minMoves: widget.board.minMoves,
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
            const SizedBox(height: 14),
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
            if (result != null || _error != null || _submitting)
              Padding(
                padding: EdgeInsets.fromLTRB(
                  20,
                  8,
                  20,
                  12 + MediaQuery.paddingOf(context).bottom,
                ),
                child: ToyBox(
                  radius: 20,
                  shadow: 5,
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_submitting)
                        Text(
                          'Sending…',
                          style: Toy.ui(15, weight: FontWeight.w800),
                        )
                      else if (_error != null) ...[
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: Toy.ui(14),
                        ),
                        const SizedBox(height: 10),
                        ToyButton.secondary(
                          label: 'Try again',
                          onPressed: _submit,
                        ),
                      ] else ...[
                        ToyStars(earned: result!.stars, size: 26, spacing: 4),
                        const SizedBox(height: 6),
                        Text(
                          '${result.points} points · ${answer!.totalPoints} this week'
                          '${answer.rank == null ? '' : ' · #${answer.rank}'}',
                          textAlign: TextAlign.center,
                          style: Toy.ui(15, weight: FontWeight.w800),
                        ),
                      ],
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: ToyButton(
                          label: 'DONE',
                          onPressed: _submitting ? null : widget.onExit,
                          height: 50,
                          fontSize: 22,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: BoardControls(
                  onUndo: (state?.canUndo ?? false) ? () => _game.undo() : null,
                  onRestart: () => _game.startLevel(
                    widget.board.asLevel,
                    levelSetVersion: 0,
                  ),
                  onHint: _onHint,
                  hintBusy: state?.hintPending ?? false,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

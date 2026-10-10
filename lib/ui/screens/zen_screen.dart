/// Zen mode: pick a pace, then pour board after board.
///
/// No clock, no stars, no leaderboard. The next board is made while the
/// current one is played, so finishing one and starting the next is a tap.
library;

import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../engine/level.dart';

import '../../services/audio/audio_service.dart';
import '../../state/achievements.dart';
import '../../state/game_controller.dart';
import '../../state/hint_controller.dart';
import '../../state/monetization_controller.dart';
import '../../state/providers.dart';
import '../../state/zen.dart';
import '../theme/toy.dart';
import '../widgets/board_view.dart';
import '../widgets/hud.dart';
import '../widgets/leave_board_prompt.dart';
import '../widgets/toy_kit.dart';

class ZenScreen extends ConsumerStatefulWidget {
  final VoidCallback onExit;

  const ZenScreen({super.key, required this.onExit});

  @override
  ConsumerState<ZenScreen> createState() => _ZenScreenState();
}

class _ZenScreenState extends ConsumerState<ZenScreen> {
  late final GameController _game;
  late final AudioService _audio;
  final _random = Random();

  ZenPace? _pace;
  Level? _level;
  Future<Level>? _next;
  bool _solved = false;
  int _poured = 0;
  bool _leaving = false;
  bool _confirming = false;

  @override
  void initState() {
    super.initState();
    _game = ref.read(gameControllerProvider.notifier);
    // The quieter music while a board is up; the menu loop again on the way
    // out. Held here because dispose must not read providers.
    _audio = ref.read(audioServiceProvider)..setScene(MusicScene.play);
    ref.read(positionAnalystProvider);
  }

  @override
  void dispose() {
    _audio.setScene(MusicScene.menu);
    _game.endSession();
    super.dispose();
  }

  Future<void> _start(ZenPace pace) async {
    setState(() {
      _pace = pace;
      _level = null;
      _solved = false;
    });
    _next = makeZenBoard(pace, _random.nextInt(1 << 30));
    await _advance();
  }

  /// Puts the waiting board on screen and starts making the one after it.
  Future<void> _advance() async {
    final pace = _pace;
    final next = _next;
    if (pace == null || next == null) return;
    final level = await next;
    if (!mounted) return;
    _next = makeZenBoard(pace, _random.nextInt(1 << 30));
    setState(() {
      _level = level;
      _solved = false;
    });
    _game.startLevel(level, levelSetVersion: 0);
  }

  bool get _midGame {
    final live = ref.read(gameControllerProvider);
    return _level != null &&
        live != null &&
        live.movesUsed > 0 &&
        !live.isWon &&
        !_solved;
  }

  Future<void> _confirmLeave() async {
    if (!_midGame) return widget.onExit();
    if (_confirming) return;
    _confirming = true;
    try {
      final leave = await confirmLeaveBoard(
        context,
        lost: "This board's moves won't be saved. Your poured count stays.",
      );
      if (!mounted || !leave) return;
      setState(() => _leaving = true);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onExit();
      });
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
    if (state != null && state.isWon && !_solved) {
      setState(() {
        _solved = true;
        _poured++;
      });
      ref.read(audioServiceProvider).win();
      ref.read(hapticsServiceProvider).levelCompleted();
      unawaited(ref.read(achievementsProvider.notifier).recordZenBoard());
    }
  }

  void _onBallLanded(double fill, bool completed) {
    ref.read(audioServiceProvider).pour(fill: fill);
    if (completed) {
      final finished = ref.read(gameControllerProvider)?.isWon ?? false;
      ref.read(audioServiceProvider).tubeComplete(last: finished);
      ref.read(hapticsServiceProvider).tubeCompleted();
    } else {
      ref.read(hapticsServiceProvider).ballLanded();
    }
  }

  Future<void> _nextBoard() async {
    await ref
        .read(monetizationProvider.notifier)
        .maybeShowZenInterstitial(_poured);
    if (mounted) await _advance();
  }

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
        showToyToast(context, 'No way to finish from here. Undo or restart.');
      default:
        showToyToast(context, 'No hint for this position right now.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final pace = _pace;
    return PopScope(
      canPop: _leaving || !_midGame,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmLeave();
      },
      child: ToyScaffold(
        padding: EdgeInsets.zero,
        child: pace == null ? _picker() : _board(pace),
      ),
    );
  }

  Widget _picker() => Padding(
    padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ToyHeader(title: 'Zen', onBack: widget.onExit),
        const SizedBox(height: 16),
        Text(
          'Endless boards. No clock, no stars, no leaderboard — just pour.',
          style: Toy.ui(15, color: Toy.inkMuted, height: 1.35),
        ),
        const SizedBox(height: 18),
        for (final pace in ZenPace.values) ...[
          Pressable(
            onPressed: () => _start(pace),
            semanticLabel: '${pace.label}, ${pace.colors} colors',
            child: ToyBox(
              color: switch (pace) {
                ZenPace.calm => Toy.mint,
                ZenPace.steady => Toy.yellow,
                ZenPace.deep => Toy.lilac,
              },
              radius: 20,
              shadow: 5,
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(pace.label, style: Toy.display(24, height: 1.05)),
                        Text(
                          '${pace.colors} colors',
                          style: Toy.ui(13, weight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                  const ToyIcon(ToyGlyph.play, size: 22),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
        ],
      ],
    ),
  );

  Widget _board(ZenPace pace) {
    final live = ref.watch(gameControllerProvider);
    final state = live?.level.id == 0 && _level != null ? live : null;
    return Column(
      children: [
        BoardHud(
          levelId: 0,
          titleLabel: 'Zen',
          titleValue: '',
          bandName: '${pace.label} · $_poured poured',
          movesUsed: state?.movesUsed ?? 0,
          minMoves: 0,
          showParMeter: false,
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
                  ? const Center(
                      child: CircularProgressIndicator(color: Toy.ink),
                    )
                  : BoardView(
                      onTapTube: _onTapTube,
                      onBallLanded: _onBallLanded,
                    ),
            ),
          ),
        ),
        if (_solved)
          Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              10,
              20,
              14 + MediaQuery.paddingOf(context).bottom,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _poured == 1 ? 'Poured!' : 'Poured! $_poured so far.',
                    style: Toy.display(22),
                  ),
                ),
                ToyButton(
                  label: 'NEXT',
                  onPressed: _nextBoard,
                  height: 54,
                  radius: 16,
                  shadow: 4,
                  fontSize: 22,
                ),
              ],
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: BoardControls(
              onUndo: (state?.canUndo ?? false) ? () => _game.undo() : null,
              onRestart: () {
                final level = _level;
                if (level != null) {
                  _game.startLevel(level, levelSetVersion: 0);
                }
              },
              onHint: _onHint,
              hintBusy: state?.hintPending ?? false,
            ),
          ),
      ],
    );
  }
}

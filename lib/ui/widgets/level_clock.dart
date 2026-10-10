/// The board clock.
///
/// Ticks itself rather than being fed a value from above, so a screen holding
/// an animating board does not rebuild the whole tree once a second just to
/// advance two digits.
///
/// Quiet by design. It counts UP and once par passes it turns tomato and stops
/// there — no flashing, no countdown. Par costs a fraction of the score and
/// nothing else, and a puzzle people play to unwind should not look like it is
/// timing an exam.
///
/// [LevelClock.detailed] is the form the par meter carries: the time against
/// par (`0:42 / 1:40`) and a chip saying what the clock is worth RIGHT NOW,
/// `+25% pts` down to `−50% pts`, straight from `timeMultiplierFor`. A bare
/// clock gave the player a number with no consequence attached; this says
/// what the next minute costs.
library;

import 'dart:async';

import 'package:flutter/material.dart';

import '../../engine/level.dart' show timeMultiplierFor;
import '../format.dart';
import '../theme/toy.dart';

class LevelClock extends StatefulWidget {
  /// Reads the live elapsed time. A callback rather than a value because the
  /// clock advances between rebuilds of whatever owns it.
  final int Function() elapsedSeconds;

  /// The pace this level is scored against.
  final int parSeconds;

  /// False while the clock is stopped — backgrounded, an ad on screen, or the
  /// level finished. The ticker stops with it.
  final bool isRunning;

  final double fontSize;

  /// Elapsed against par, with the live points chip. The plain form is just
  /// the elapsed time.
  final bool detailed;

  /// Ink while within par. Inherits the surrounding text color when null, so
  /// it matches the subtitle it sits in on any ground.
  final Color? color;

  const LevelClock({
    super.key,
    required this.elapsedSeconds,
    required this.parSeconds,
    required this.isRunning,
    this.fontSize = 13,
    this.color,
    this.detailed = false,
  });

  @override
  State<LevelClock> createState() => _LevelClockState();
}

class _LevelClockState extends State<LevelClock> {
  Timer? _ticker;
  late int _seconds = widget.elapsedSeconds();

  @override
  void initState() {
    super.initState();
    _syncTicker();
  }

  @override
  void didUpdateWidget(LevelClock old) {
    super.didUpdateWidget(old);
    // A pause or resume arrives as a rebuild with a new isRunning, and the
    // elapsed value has to be re-read either way: a resume that kept the old
    // number would show the clock jumping a second later.
    _seconds = widget.elapsedSeconds();
    _syncTicker();
  }

  void _syncTicker() {
    _ticker?.cancel();
    if (!widget.isRunning) return;
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      final now = widget.elapsedSeconds();
      if (now == _seconds || !mounted) return;
      setState(() => _seconds = now);
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final overPar = widget.parSeconds > 0 && _seconds > widget.parSeconds;
    final base = widget.color ?? DefaultTextStyle.of(context).style.color;
    final style = Toy.numbers(
      widget.fontSize,
      weight: FontWeight.w700,
      color: overPar ? Toy.tomato : (base ?? Toy.inkMuted),
    );

    if (!widget.detailed || widget.parSeconds <= 0) {
      return Semantics(
        label: 'Time ${formatSpan(_seconds)}',
        // Its own layer: a tick once a second must not repaint the board.
        child: ExcludeSemantics(
          child: RepaintBoundary(
            child: Text(formatClock(_seconds), style: style),
          ),
        ),
      );
    }

    final percent = clockBonusPercent(
      elapsedSeconds: _seconds,
      parSeconds: widget.parSeconds,
    );
    final chip = percent > 0
        ? Toy.mint
        : percent == 0
        ? Toy.yellow
        : Toy.tomato;
    return Semantics(
      label:
          'Time ${formatSpan(_seconds)} of par ${formatSpan(widget.parSeconds)}, '
          '${percent >= 0 ? 'plus' : 'minus'} ${percent.abs()} percent points',
      child: ExcludeSemantics(
        child: RepaintBoundary(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(formatClock(_seconds), style: style),
              Text(
                ' / ${formatClock(widget.parSeconds)}',
                style: style.copyWith(color: base ?? Toy.inkMuted),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: chip,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: Toy.ink, width: 1.5),
                ),
                child: Text(
                  '${percent > 0
                      ? '+'
                      : percent < 0
                      ? '−'
                      : '±'}'
                  '${percent.abs()}% pts',
                  style: Toy.numbers(
                    widget.fontSize - 1,
                    weight: FontWeight.w800,
                    color: percent < 0 ? Colors.white : Toy.ink,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// What the clock is doing to the score at [elapsedSeconds], as a whole
/// percent: +25 while well under par, 0 at par, down to −50.
int clockBonusPercent({required int elapsedSeconds, required int parSeconds}) {
  final m = timeMultiplierFor(
    parSeconds: parSeconds,
    elapsedSeconds: elapsedSeconds,
  );
  return ((m - 1) * 100).round();
}

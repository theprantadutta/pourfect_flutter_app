/// The board clock.
///
/// Ticks itself rather than being fed a value from above, so a screen holding
/// an animating board does not rebuild the whole tree once a second just to
/// advance two digits.
///
/// Quiet by design. It counts UP, sits inline after the world name in the
/// same muted ink, and once par passes it turns tomato and stops there — no
/// flashing, no countdown. Par costs a fraction of
/// the score and nothing else, and a puzzle people play to unwind should not
/// look like it is timing an exam.
library;

import 'dart:async';

import 'package:flutter/material.dart';

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

    return Semantics(
      label: 'Time ${formatSpan(_seconds)}',
      child: ExcludeSemantics(
        child: Text(
          formatClock(_seconds),
          style: Toy.numbers(
            widget.fontSize,
            weight: FontWeight.w700,
            color: overPar ? Toy.tomato : (base ?? Toy.inkMuted),
          ),
        ),
      ),
    );
  }
}

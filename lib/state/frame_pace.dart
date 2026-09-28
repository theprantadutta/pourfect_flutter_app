/// Decides whether this phone can keep up with its own fast display.
///
/// A 120 Hz panel says nothing about the chip behind it. At 120 Hz a frame has
/// 8.3ms; a phone that needs 11ms to draw a pour drops every other frame, and
/// that stutters worse than a steady 60. So "Auto" asks for the fast rate,
/// watches the frames the app actually draws, and backs off if they do not fit.
///
/// Pure Dart on purpose: the judgement is the interesting part, and it is
/// testable without a device or a frame scheduler.
library;

/// Judges frame timings against the budget they were drawn under.
///
/// Only frames that were actually drawn arrive here, and an idle screen draws
/// none, so the sample is naturally "the app while it was moving". The verdict
/// needs [strikesToCap] consecutive bad windows, so one janky moment — a
/// shader compiling, a network response landing — cannot cost a device its
/// smooth mode.
class FramePaceJudge {
  /// Frames per verdict.
  final int window;

  /// Fraction of a window that may miss the budget before it counts as bad.
  final double tolerance;

  /// Consecutive bad windows before giving up on the high rate.
  final int strikesToCap;

  FramePaceJudge({
    this.window = 180,
    this.tolerance = 0.08,
    this.strikesToCap = 2,
  });

  int _frames = 0;
  int _missed = 0;
  int _strikes = 0;

  /// True once the phone has shown it cannot hold the high rate.
  bool get tooSlow => _strikes >= strikesToCap;

  /// Records one frame. [budgetMicros] is the frame interval the display was
  /// running at when it was drawn — 11,111 at 90 Hz, 8,333 at 120 Hz.
  ///
  /// Returns true on the frame that tips the verdict to [tooSlow].
  bool add({
    required int buildMicros,
    required int rasterMicros,
    required int budgetMicros,
  }) {
    if (tooSlow) return false;
    _frames++;
    if (buildMicros > budgetMicros || rasterMicros > budgetMicros) _missed++;
    if (_frames < window) return false;

    final bad = _missed / _frames > tolerance;
    _strikes = bad ? _strikes + 1 : 0;
    _frames = 0;
    _missed = 0;
    return tooSlow;
  }

  void reset() {
    _frames = 0;
    _missed = 0;
    _strikes = 0;
  }
}

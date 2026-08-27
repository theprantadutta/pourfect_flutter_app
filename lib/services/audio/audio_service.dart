/// Sound playback, behind an interface so it can be muted, faked and swapped.
library;

abstract interface class AudioService {
  /// Generates the sound bank and opens the mixer. Safe to call twice.
  ///
  /// MUST NOT throw and MUST NOT block startup: a device with no working audio
  /// output still has to reach level 1.
  Future<void> init();

  /// A ball settling into a tube. [fill] is how full the destination is
  /// AFTER this ball lands, 0..1 — the pitch rises with it, the way a filling
  /// vessel does.
  void pour({required double fill});

  /// Lifting or setting down a run.
  void select();

  /// A tube just completed.
  void tubeComplete();

  /// A star landing. [index] is 0-2; the third is richer and longer.
  void star(int index);

  /// The win bell.
  void win();

  /// Personal best.
  void newBest();

  Future<void> dispose();
}

/// Silent. Tests, and players who turn sound off.
class NoopAudioService implements AudioService {
  const NoopAudioService();

  @override
  Future<void> init() async {}

  @override
  void pour({required double fill}) {}

  @override
  void select() {}

  @override
  void tubeComplete() {}

  @override
  void star(int index) {}

  @override
  void win() {}

  @override
  void newBest() {}

  @override
  Future<void> dispose() async {}
}

/// Records cue names in order. For tests.
class RecordingAudioService implements AudioService {
  final List<String> cues = [];

  @override
  Future<void> init() async {}

  @override
  void pour({required double fill}) =>
      cues.add('pour(${fill.toStringAsFixed(2)})');

  @override
  void select() => cues.add('select');

  @override
  void tubeComplete() => cues.add('tubeComplete');

  @override
  void star(int index) => cues.add('star$index');

  @override
  void win() => cues.add('win');

  @override
  void newBest() => cues.add('newBest');

  @override
  Future<void> dispose() async {}
}

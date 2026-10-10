/// Sound playback, behind an interface so it can be muted, faked and swapped.
library;

import 'synth.dart' show MusicScene, UiCue;

export 'synth.dart' show MusicScene, UiCue;

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
  /// A tube just completed. [last] is the tube that finishes the board.
  void tubeComplete({bool last = false});

  /// A star landing. [index] is 0-2; the third is richer and longer.
  void star(int index);

  /// The win bell.
  void win();

  /// Personal best.
  void newBest();

  /// A sound from the app around the board. See [UiCue].
  void ui(UiCue cue);

  /// Which music should play. Crossfades.
  void setScene(MusicScene scene);

  /// Re-reads the music switch and volume.
  void refreshMusic();

  /// The app went to the background, or came back.
  void appPaused();
  void appResumed();

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
  void tubeComplete({bool last = false}) {}

  @override
  void star(int index) {}

  @override
  void win() {}

  @override
  void newBest() {}

  @override
  void ui(UiCue cue) {}

  @override
  void setScene(MusicScene scene) {}

  @override
  void refreshMusic() {}

  @override
  void appPaused() {}

  @override
  void appResumed() {}

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
  void tubeComplete({bool last = false}) =>
      cues.add(last ? 'finalTube' : 'tubeComplete');

  @override
  void star(int index) => cues.add('star$index');

  @override
  void win() => cues.add('win');

  @override
  void newBest() => cues.add('newBest');

  @override
  void ui(UiCue cue) => cues.add('ui:${cue.name}');

  /// The scene asked for last.
  MusicScene scene = MusicScene.menu;

  @override
  void setScene(MusicScene scene) => this.scene = scene;

  @override
  void refreshMusic() {}

  @override
  void appPaused() {}

  @override
  void appResumed() {}

  @override
  Future<void> dispose() async {}
}

/// SoLoud-backed audio, configured to share the device politely.
///
/// THE AUDIO SESSION IS THE PART THAT COSTS REVIEWS.
///
/// A large share of puzzle players are listening to music or a podcast while
/// they play. If this game grabs exclusive audio focus, their playback stops —
/// and "this game killed my Spotify" is a one-star review that no amount of
/// polish elsewhere buys back. The policy is therefore:
///
///  * **iOS: the `ambient` category.** Mixes with other audio AND obeys the
///    hardware silent switch — a player who has physically muted their phone in
///    a meeting must get silence, not confidence that we know better.
///  * **Android: never request audio focus.** Focus is a request to make
///    everyone else be quiet. Game cues have no business making that request;
///    we simply mix into whatever is already playing.
///  * **We duck under them, never the reverse.** Cue volumes sit low enough to
///    sit under a podcast rather than fight it.
///
/// Ordering matters: the session is configured AFTER SoLoud initialises,
/// because the native mixer sets its own category on startup and would
/// otherwise overwrite ours.
///
/// WHAT IS AND IS NOT VERIFIED, as of the Android build:
///
///  * VERIFIED — `adb shell dumpsys audio` shows this package in no audio
///    focus entry at all. No focus request is made, so other playback is never
///    interrupted. That is the requirement that costs reviews.
///  * KNOWN GAP — the AAudio stream reports `usage=USAGE_MEDIA` rather than
///    `USAGE_GAME`. SoLoud opens its own stream natively, so the attributes
///    configured here do not reach it. Harmless for mixing.
///  * UNVERIFIED — the iOS silent switch. The `ambient` category below is the
///    right request, but since SoLoud demonstrably bypasses the Android
///    attributes it may also set its own AVAudioSession category. Before any
///    iOS build ships, flip the hardware mute switch and confirm the game goes
///    silent; if it does not, the fix is a category override on the native
///    side rather than another audio_session call.
library;

import 'dart:math' as math;

import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_soloud/flutter_soloud.dart';

import 'audio_service.dart';
import 'synth.dart';

/// Cue levels, tuned to sit UNDER other audio rather than over it.
///
/// The pour is the quietest thing here on purpose: it fires thousands of times
/// a session, and anything that repeats that often has to be felt more than
/// heard.
const double _pourVolume = 0.34;
const double _selectVolume = 0.18;
const double _tubeVolume = 0.42;
const double _starVolume = 0.46;
const double _winVolume = 0.55;

class SoLoudAudioService implements AudioService {
  /// Read live so a settings toggle takes effect on the very next tap.
  final bool Function() enabled;

  SoLoudAudioService({required this.enabled});

  final _random = math.Random();
  bool _ready = false;

  AudioSource? _pour;
  AudioSource? _select;
  AudioSource? _tubeComplete;
  final List<AudioSource> _stars = [];
  AudioSource? _win;
  AudioSource? _newBest;

  @override
  Future<void> init() async {
    if (_ready) return;

    try {
      final soloud = SoLoud.instance;
      if (!soloud.isInitialized) {
        await soloud.init();
      }

      final bank = SoundBank.generate();

      _pour = await soloud.loadMem('pourfect/pour.wav', bank.pour);
      _select = await soloud.loadMem('pourfect/select.wav', bank.select);
      _tubeComplete = await soloud.loadMem(
        'pourfect/tube.wav',
        bank.tubeComplete,
      );
      for (var i = 0; i < bank.stars.length; i++) {
        _stars.add(await soloud.loadMem('pourfect/star$i.wav', bank.stars[i]));
      }
      _win = await soloud.loadMem('pourfect/win.wav', bank.win);
      _newBest = await soloud.loadMem('pourfect/best.wav', bank.newBest);

      await _configureSession();
      _ready = true;
    } catch (error, stack) {
      // A device with no usable audio output still has to reach level 1.
      debugPrint('[audio] init failed, continuing silent: $error\n$stack');
      _ready = false;
    }
  }

  /// Applies the share-the-device policy described at the top of this file.
  Future<void> _configureSession() async {
    final session = await AudioSession.instance;
    await session.configure(
      const AudioSessionConfiguration(
        // `ambient` is the whole iOS answer: mixes with others, and respects
        // the silent switch.
        avAudioSessionCategory: AVAudioSessionCategory.ambient,
        avAudioSessionCategoryOptions:
            AVAudioSessionCategoryOptions.mixWithOthers,
        avAudioSessionMode: AVAudioSessionMode.defaultMode,
        avAudioSessionSetActiveOptions: AVAudioSessionSetActiveOptions.none,
        androidAudioAttributes: AndroidAudioAttributes(
          contentType: AndroidAudioContentType.sonification,
          usage: AndroidAudioUsage.game,
          flags: AndroidAudioFlags.none,
        ),
        // Declared for completeness only. We deliberately never call
        // `setActive(true)`, so no focus request is ever made and nobody
        // else's playback is interrupted.
        androidAudioFocusGainType:
            AndroidAudioFocusGainType.gainTransientMayDuck,
        androidWillPauseWhenDucked: false,
      ),
    );
  }

  bool get _live => _ready && enabled();

  void _play(AudioSource? source, double volume, {double speed = 1}) {
    if (!_live || source == null) return;
    try {
      final handle = SoLoud.instance.play(source, volume: volume);
      if (speed != 1) {
        SoLoud.instance.setRelativePlaySpeed(handle, speed);
      }
    } catch (_) {
      // Never let a cue take gameplay down.
    }
  }

  @override
  void pour({required double fill}) {
    // Pitch rises with how full the destination now is, so a run of four plays
    // as a rising figure rather than the same note four times.
    _play(
      _pour,
      _pourVolume,
      speed: pourSpeedForFill(fill, _random.nextDouble()),
    );
  }

  @override
  void select() =>
      _play(_select, _selectVolume, speed: 0.98 + _random.nextDouble() * 0.04);

  @override
  void tubeComplete() => _play(_tubeComplete, _tubeVolume);

  @override
  void star(int index) {
    if (index < 0 || index >= _stars.length) return;
    _play(_stars[index], _starVolume);
  }

  @override
  void win() => _play(_win, _winVolume);

  @override
  void newBest() => _play(_newBest, _starVolume);

  @override
  Future<void> dispose() async {
    if (!_ready) return;
    _ready = false;
    try {
      await SoLoud.instance.disposeAllSources();
    } catch (_) {}
  }
}

/// Every sound in the game, generated at startup.
///
/// PURE DART, no Flutter — so the whole sound design is unit-testable and can
/// be regenerated from a tool without a device.
///
/// WHY SYNTHESISE. Players hear the pour thousands of times per session and the
/// win chime once per level, so the pour is where the tuning budget goes. A
/// sampled pour has exactly one timbre; played a thousand times it becomes a
/// loop, and the ear locks onto it within a session. Generating it means every
/// hit can differ — and it costs zero bytes against a 25 MB budget.
///
/// The pitch variation is not random noise dressed up as design: a vessel
/// filling with liquid rises in pitch as the air column above it shortens, so
/// [pourClip] is played back faster as the destination tube fills. Pouring a
/// run of four therefore produces a rising figure, the way it would in the
/// physical world. The random jitter on top only stops two identical pours
/// sounding stamped.
library;

import 'dart:math' as math;
import 'dart:typed_data';

const int kSampleRate = 44100;

/// One frequency component of a synthesised tone.
class Partial {
  /// Multiple of the fundamental. Bells are INHARMONIC — their partials are not
  /// whole-number multiples, which is exactly what makes a bell sound like a
  /// bell rather than an organ.
  final double ratio;

  /// Relative loudness.
  final double amplitude;

  /// Decay rate multiplier. Higher partials fade faster in real resonant
  /// bodies; keeping them alive as long as the fundamental is what makes cheap
  /// synthesis sound like a test tone.
  final double decay;

  const Partial(this.ratio, this.amplitude, this.decay);
}

/// Renders an additive tone to mono float samples in -1..1.
Float64List renderTone({
  required double frequency,
  required double seconds,
  required List<Partial> partials,
  double attack = 0.006,
  double noise = 0,
  double noiseDecay = 90,
  int seed = 1,
}) {
  final count = (seconds * kSampleRate).round();
  final out = Float64List(count);
  final random = math.Random(seed);

  for (var i = 0; i < count; i++) {
    final t = i / kSampleRate;

    // Soft attack. An instant onset is a click, and a click heard a thousand
    // times is fatigue — this is the single most important 6ms in the game.
    final onset = t < attack ? t / attack : 1.0;

    var sample = 0.0;
    for (final p in partials) {
      sample +=
          p.amplitude *
          math.exp(-p.decay * t) *
          math.sin(2 * math.pi * frequency * p.ratio * t);
    }

    if (noise > 0) {
      // A whisper of contact transient: the tick of ball meeting glass.
      sample +=
          noise * (random.nextDouble() * 2 - 1) * math.exp(-noiseDecay * t);
    }

    out[i] = sample * onset;
  }

  return _normalise(out);
}

/// Scales to a comfortable peak and applies a short fade-out.
///
/// The tail fade matters: cutting a decaying tone at the buffer edge leaves a
/// discontinuity, which is an audible click on every single playback.
Float64List _normalise(Float64List samples, {double peak = 0.82}) {
  var max = 0.0;
  for (final s in samples) {
    final a = s.abs();
    if (a > max) max = a;
  }
  if (max == 0) return samples;

  final gain = peak / max;
  final fade = math.min(400, samples.length ~/ 8);
  final start = samples.length - fade;

  for (var i = 0; i < samples.length; i++) {
    var v = samples[i] * gain;
    if (i >= start) v *= (samples.length - i) / fade;
    samples[i] = v;
  }
  return samples;
}

/// Encodes mono float samples as a 16-bit PCM WAV.
///
/// SoLoud loads clips from memory, so this never touches the filesystem.
Uint8List encodeWav(Float64List samples, {int sampleRate = kSampleRate}) {
  final dataBytes = samples.length * 2;
  final buffer = ByteData(44 + dataBytes);

  void ascii(int offset, String tag) {
    for (var i = 0; i < tag.length; i++) {
      buffer.setUint8(offset + i, tag.codeUnitAt(i));
    }
  }

  ascii(0, 'RIFF');
  buffer.setUint32(4, 36 + dataBytes, Endian.little);
  ascii(8, 'WAVE');
  ascii(12, 'fmt ');
  buffer.setUint32(16, 16, Endian.little); // PCM chunk size
  buffer.setUint16(20, 1, Endian.little); // format = PCM
  buffer.setUint16(22, 1, Endian.little); // mono
  buffer.setUint32(24, sampleRate, Endian.little);
  buffer.setUint32(28, sampleRate * 2, Endian.little); // byte rate
  buffer.setUint16(32, 2, Endian.little); // block align
  buffer.setUint16(34, 16, Endian.little); // bits per sample
  ascii(36, 'data');
  buffer.setUint32(40, dataBytes, Endian.little);

  for (var i = 0; i < samples.length; i++) {
    final clamped = samples[i].clamp(-1.0, 1.0);
    buffer.setInt16(44 + i * 2, (clamped * 32767).round(), Endian.little);
  }

  return buffer.buffer.asUint8List();
}

/// The library of cues, as ready-to-load WAV bytes.
class SoundBank {
  /// A ball settling into a tube. THE most-heard sound in the game.
  ///
  /// Soft attack, short warm body: a low fundamental with a gentle second
  /// partial and almost nothing above it, so it reads as a soft knock against
  /// glass rather than a UI blip. Played back at a varying rate — see
  /// [pourSpeedForFill].
  final Uint8List pour;

  /// Lifting or setting down a run. Quieter and higher than the pour so it
  /// never competes with it.
  final Uint8List select;

  /// A tube just completed: a quick rising roll, root-fifth-octave, so a
  /// sorted tube lands as a little flourish rather than one more note.
  final Uint8List tubeComplete;

  /// The tube that finishes the board: the same roll, a step brighter and one
  /// note longer, so the final pour is its own beat leading into the win bell.
  final Uint8List finalTube;

  /// Rising triad for the star landings. The third is deliberately richer.
  final List<Uint8List> stars;

  /// The win bell. Inharmonic partials with staggered decays.
  final Uint8List win;

  /// Personal best: a rising two-note figure, distinct from any star.
  final Uint8List newBest;

  const SoundBank({
    required this.pour,
    required this.select,
    required this.tubeComplete,
    required this.finalTube,
    required this.stars,
    required this.win,
    required this.newBest,
  });

  static SoundBank generate() => SoundBank(
    pour: encodeWav(
      renderTone(
        frequency: 196,
        seconds: 0.30,
        attack: 0.007,
        noise: 0.16,
        noiseDecay: 150,
        partials: const [
          Partial(1.0, 1.00, 14),
          Partial(2.0, 0.30, 24),
          Partial(3.02, 0.09, 40),
        ],
      ),
    ),
    select: encodeWav(
      renderTone(
        frequency: 392,
        seconds: 0.16,
        attack: 0.005,
        partials: const [Partial(1.0, 1.0, 34), Partial(2.01, 0.16, 52)],
      ),
    ),
    tubeComplete: encodeWav(_roll(const [294, 440, 588], stagger: 0.055)),
    finalTube: encodeWav(
      _roll(const [392, 494, 587, 784], stagger: 0.06, tail: 1.0),
    ),
    stars: [
      _star(523.25, rich: false, seed: 11),
      _star(659.25, rich: false, seed: 12),
      _star(783.99, rich: true, seed: 13),
    ],
    win: encodeWav(
      renderTone(
        frequency: 528,
        seconds: 1.9,
        attack: 0.004,
        seed: 7,
        // Bell partials. The 2.4 and 2.76 ratios are what stop this sounding
        // like a sine pad — real bells are built on non-integer relationships.
        partials: const [
          Partial(0.50, 0.34, 1.4),
          Partial(1.00, 1.00, 1.9),
          Partial(1.19, 0.42, 2.9),
          Partial(1.50, 0.30, 3.4),
          Partial(2.00, 0.22, 4.2),
          Partial(2.40, 0.14, 5.6),
          Partial(2.76, 0.09, 6.8),
          Partial(3.50, 0.05, 9.0),
        ],
      ),
    ),
    newBest: encodeWav(_twoNote(659.25, 987.77)),
  );

  static Uint8List _star(
    double frequency, {
    required bool rich,
    required int seed,
  }) => encodeWav(
    renderTone(
      frequency: frequency,
      seconds: rich ? 1.05 : 0.55,
      attack: 0.005,
      seed: seed,
      partials: rich
          ? const [
              Partial(1.0, 1.00, 2.6),
              Partial(2.0, 0.38, 3.8),
              Partial(3.0, 0.16, 6.0),
              Partial(4.0, 0.07, 9.0),
            ]
          : const [Partial(1.0, 1.00, 6.0), Partial(2.0, 0.22, 9.0)],
    ),
  );

  /// A quick roll of [notes], each entering [stagger] seconds after the last,
  /// with a warm body that rings for [tail] seconds. Later notes are a touch
  /// louder, so the roll leans upward.
  static Float64List _roll(
    List<double> notes, {
    required double stagger,
    double tail = 0.7,
  }) {
    final step = (stagger * kSampleRate).round();
    final tones = [
      for (var i = 0; i < notes.length; i++)
        renderTone(
          frequency: notes[i],
          seconds: tail,
          attack: 0.006,
          seed: 20 + i,
          partials: const [
            Partial(1.0, 1.00, 6),
            Partial(2.0, 0.26, 10),
            Partial(3.0, 0.08, 16),
          ],
        ),
    ];
    final out = Float64List(step * (notes.length - 1) + tones.last.length);
    for (var i = 0; i < tones.length; i++) {
      final gain = 0.7 + 0.3 * i / math.max(1, notes.length - 1);
      for (var s = 0; s < tones[i].length; s++) {
        out[i * step + s] += tones[i][s] * gain;
      }
    }
    return _normalise(out);
  }

  /// Two tones in one buffer, the second entering partway through.
  static Float64List _twoNote(double a, double b) {
    final first = renderTone(
      frequency: a,
      seconds: 0.95,
      partials: const [Partial(1.0, 1.0, 6.5), Partial(2.0, 0.24, 10)],
    );
    final second = renderTone(
      frequency: b,
      seconds: 0.80,
      partials: const [Partial(1.0, 1.0, 4.2), Partial(2.0, 0.30, 7)],
    );

    final offset = (0.13 * kSampleRate).round();
    final out = Float64List(math.max(first.length, offset + second.length));
    for (var i = 0; i < first.length; i++) {
      out[i] += first[i] * 0.75;
    }
    for (var i = 0; i < second.length; i++) {
      out[offset + i] += second[i] * 0.95;
    }
    return _normalise(out);
  }
}

/// Playback rate for a ball landing in a tube that is [fill] full (0..1).
///
/// A filling vessel rises in pitch as the air column above the liquid shortens.
/// Applying that here means a run of four balls plays as a rising figure
/// instead of the same note four times — the single biggest thing separating
/// this from a stock UI click.
///
/// [jitter] should be a fresh random in 0..1; it adds roughly a quarter-tone of
/// wander so two identical pours never sound stamped from the same die.
double pourSpeedForFill(double fill, double jitter) {
  const low = 0.86;
  const high = 1.30;
  final base = low + (high - low) * fill.clamp(0.0, 1.0);
  return base * (0.985 + 0.03 * jitter);
}

/// How much brighter a pour plays when it comes hard on the heels of the last
/// move. [combo] counts quick moves in a row (0 = none); each lifts the pitch
/// about a quarter-tone, up to six, so a fast streak sounds like momentum.
double comboBoost(int combo) => 1 + 0.025 * combo.clamp(0, 6);

/// The next combo count after a pour [gapMs] milliseconds after the previous
/// one. Balls of the same run land closer together than [sameMoveMs]; a new
/// move inside [streakMs] extends the streak; anything slower ends it.
int nextCombo(
  int combo,
  int gapMs, {
  int sameMoveMs = 260,
  int streakMs = 1600,
}) {
  if (gapMs > streakMs) return 0;
  if (gapMs > sameMoveMs) return math.min(combo + 1, 6);
  return combo;
}

// ---------------------------------------------------------------------------
// The rest of the app: UI cues and music
// ---------------------------------------------------------------------------
//
// THE PALETTE (2026-10-10). One instrument family — soft glass and marimba:
// a sine body, a gentle octave, a faint twelfth, short attacks, nothing harsh
// — and one key, D major pentatonic (D E F# A B), so every cue and the music
// sound like the same toy. The gameplay cues above predate it and sit close
// enough (G, D, C) not to clash.

/// A sound in the app around the board: menus, buttons, rewards.
enum UiCue {
  /// Any button. The most-heard UI cue, so the softest.
  tap,

  /// A switch flipped.
  toggle,

  /// Going back a screen.
  back,

  /// A dialog opening, and closing.
  sheetOpen,
  sheetClose,

  /// A toast appearing.
  toast,

  /// Something did not work. Gentle, never alarming.
  error,

  /// A rewarded video paid out.
  rewardGranted,

  /// A move taken back.
  undo,

  /// A hint revealed.
  hint,

  /// The extra tube appearing.
  extraTube,

  /// A streak milestone.
  streak,

  /// A star chest opening.
  chestOpen,

  /// An achievement unlocked.
  achievement,
}

// D major pentatonic, by octave. Frequencies in Hz.
const double _d4 = 293.66, _e4 = 329.63, _a4 = 440.0, _b4 = 493.88;
const double _d5 = 587.33,
    _e5 = 659.26,
    _fs5 = 739.99,
    _a5 = 880.0,
    _b5 = 987.77;
const double _d6 = 1174.66, _fs6 = 1479.98, _a6 = 1760.0;

const List<Partial> _glass = [
  Partial(1.0, 1.00, 9),
  Partial(2.0, 0.22, 15),
  Partial(3.0, 0.06, 24),
];

const List<Partial> _bell = [
  Partial(1.0, 1.00, 3.2),
  Partial(2.0, 0.30, 5.0),
  Partial(2.76, 0.10, 7.5),
];

Float64List _arp(
  List<double> notes, {
  double stagger = 0.04,
  double length = 0.35,
  List<Partial> partials = _glass,
}) {
  final step = (stagger * kSampleRate).round();
  final tones = [
    for (var i = 0; i < notes.length; i++)
      renderTone(
        frequency: notes[i],
        seconds: length,
        attack: 0.004,
        seed: 40 + i,
        partials: partials,
      ),
  ];
  final out = Float64List(step * (notes.length - 1) + tones.last.length);
  for (var i = 0; i < tones.length; i++) {
    for (var s = 0; s < tones[i].length; s++) {
      out[i * step + s] += tones[i][s];
    }
  }
  return _normalise(out);
}

Float64List _single(
  double f,
  double seconds, {
  List<Partial> partials = _glass,
}) => renderTone(
  frequency: f,
  seconds: seconds,
  attack: 0.004,
  partials: partials,
);

/// Every UI cue, as ready-to-load WAV bytes.
Map<UiCue, Uint8List> generateUiCues() => {
  UiCue.tap: encodeWav(
    renderTone(
      frequency: _a5,
      seconds: 0.07,
      attack: 0.003,
      partials: const [Partial(1.0, 1.0, 55), Partial(2.0, 0.12, 80)],
    ),
  ),
  UiCue.toggle: encodeWav(_arp(const [_fs5, _b5], stagger: 0.05, length: 0.16)),
  UiCue.back: encodeWav(_arp(const [_a5, _e5], stagger: 0.05, length: 0.16)),
  UiCue.sheetOpen: encodeWav(
    _arp(const [_d5, _fs5, _a5], stagger: 0.03, length: 0.22),
  ),
  UiCue.sheetClose: encodeWav(
    _arp(const [_a5, _fs5, _d5], stagger: 0.03, length: 0.2),
  ),
  UiCue.toast: encodeWav(_single(_a5, 0.4, partials: _bell)),
  UiCue.error: encodeWav(_arp(const [_e4, _d4], stagger: 0.09, length: 0.3)),
  UiCue.rewardGranted: encodeWav(
    _arp(
      const [_a5, _b5, _d6, _fs6],
      stagger: 0.05,
      length: 0.55,
      partials: _bell,
    ),
  ),
  UiCue.undo: encodeWav(
    renderTone(
      frequency: _b4,
      seconds: 0.12,
      attack: 0.003,
      partials: const [Partial(1.0, 1.0, 30), Partial(2.0, 0.15, 45)],
    ),
  ),
  UiCue.hint: encodeWav(_arp(const [_e5, _b5], stagger: 0.11, length: 0.4)),
  UiCue.extraTube: encodeWav(_single(_d5, 0.8, partials: _bell)),
  UiCue.streak: encodeWav(
    _arp(
      const [_d4, _a4, _d5, _fs5],
      stagger: 0.07,
      length: 0.9,
      partials: _bell,
    ),
  ),
  UiCue.chestOpen: encodeWav(
    _arp(
      const [_d5, _e5, _fs5, _a5, _b5, _d6],
      stagger: 0.045,
      length: 0.7,
      partials: _bell,
    ),
  ),
  UiCue.achievement: encodeWav(
    _arp(
      const [_d5, _fs5, _a5, _d6, _a6],
      stagger: 0.08,
      length: 1.0,
      partials: _bell,
    ),
  ),
};

/// Which music is playing.
enum MusicScene {
  /// Menus: the fuller loop.
  menu,

  /// A board in play: the same tune, thinner and quieter, out of the way.
  play,
}

/// Music runs at half the cue rate: it is soft and low, and half the samples
/// is half the memory and half the time to make.
const int kMusicSampleRate = 22050;

/// A seamless loop for [scene], as WAV bytes.
///
/// "Pour Song" — 16 bars at 100 BPM in D major, built to be hummed:
///
///  * A section (bars 1-8): D – A – Bm – G, twice, under a bell-and-marimba
///    hook that rises and answers itself.
///  * B section (bars 9-16): Bm – G – D – A – Bm – G – Em – A, the melody
///    climbing to F#6 and resolving on the A that leads back to bar 1.
///  * Underneath: a bouncy plucked bass, sparkly chord arpeggios, soft pads,
///    and gentle percussion (a round kick, a shaker on the off-beats, a soft
///    clap on 2 and 4).
///
/// The gameplay loop is the same song, out of the way: no drums, a lighter
/// hook, the arpeggios thinned. Anything that rings past the end wraps round
/// to the start, so the loop has no seam.
Uint8List renderMusicLoop(MusicScene scene) {
  const rate = kMusicSampleRate;
  const bpm = 100.0;
  const beat = 60 / bpm;
  const bars = 16;
  final length = (bars * 4 * beat * rate).round();
  final out = Float64List(length);
  final menu = scene == MusicScene.menu;
  final noise = math.Random(5);

  void tone(
    double freq,
    double start,
    double seconds,
    double gain,
    List<Partial> partials, {
    double attack = 0.004,
    double vibrato = 0,
  }) {
    final from = (start * rate).round();
    final count = (seconds * rate).round();
    for (var i = 0; i < count; i++) {
      final t = i / rate;
      final onset = t < attack ? t / attack : 1.0;
      final wobble = vibrato == 0
          ? 0.0
          : vibrato * math.sin(2 * math.pi * 5.5 * t);
      var v = 0.0;
      for (final p in partials) {
        v +=
            p.amplitude *
            math.exp(-p.decay * t) *
            math.sin(2 * math.pi * freq * p.ratio * (t + wobble / freq));
      }
      out[(from + i) % length] += v * onset * gain;
    }
  }

  // A round, soft kick: a sine falling from 110 Hz to 48 Hz.
  void kick(double start, double gain) {
    final from = (start * rate).round();
    final count = (0.22 * rate).round();
    var phase = 0.0;
    for (var i = 0; i < count; i++) {
      final t = i / rate;
      final f = 48 + 62 * math.exp(-t * 28);
      phase += 2 * math.pi * f / rate;
      out[(from + i) % length] += math.sin(phase) * math.exp(-t * 16) * gain;
    }
  }

  // Noise with a crude high-pass: a shaker when short, a clap when longer.
  void hit(double start, double seconds, double decay, double gain) {
    final from = (start * rate).round();
    final count = (seconds * rate).round();
    var last = 0.0;
    for (var i = 0; i < count; i++) {
      final t = i / rate;
      final n = noise.nextDouble() * 2 - 1;
      final bright = n - last;
      last = n;
      out[(from + i) % length] += bright * math.exp(-t * decay) * gain;
    }
  }

  // Note names used below, Hz.
  const d2 = 73.42, e2 = 82.41, g2 = 98.0, a2 = 110.0, b2 = 123.47;
  const cs4 = 277.18,
      d4 = 293.66,
      e4 = 329.63,
      fs4 = 369.99,
      g4 = 392.0,
      a4 = 440.0;
  const b4 = 493.88, d5 = 587.33, e5 = 659.26, fs5 = 739.99;
  const g5 = 783.99, a5 = 880.0, b5 = 987.77, cs6 = 1108.73, d6 = 1174.66;
  const e6 = 1318.51, fs6 = 1479.98;

  // Bass root and chord tones (for pads and arpeggios), per bar.
  const roots = [
    d2,
    a2,
    b2,
    g2,
    d2,
    a2,
    g2,
    a2,
    b2,
    g2,
    d2,
    a2,
    b2,
    g2,
    e2,
    a2,
  ];
  const chords = [
    [d4, fs4, a4],
    [cs4, e4, a4],
    [d4, fs4, b4],
    [d4, g4, b4],
    [d4, fs4, a4],
    [cs4, e4, a4],
    [d4, g4, b4],
    [cs4, e4, a4],
    [d4, fs4, b4],
    [d4, g4, b4],
    [d4, fs4, a4],
    [cs4, e4, a4],
    [d4, fs4, b4],
    [d4, g4, b4],
    [e4, g4, b4],
    [cs4, e4, a4],
  ];

  // The hook: (bar, beat, length in beats, note).
  const melody = <(int, double, double, double)>[
    // A
    (0, 0, 1, d5),
    (0, 1, 0.5, fs5),
    (0, 1.5, 0.5, a5),
    (0, 2, 1, a5),
    (0, 3, 1, fs5),
    (1, 0, 1, e5), (1, 1, 0.5, a5), (1, 1.5, 0.5, cs6), (1, 2, 2, b5),
    (2, 0, 1, d6),
    (2, 1, 0.5, b5),
    (2, 1.5, 0.5, a5),
    (2, 2, 1, fs5),
    (2, 3, 1, d5),
    (3, 0, 0.5, e5), (3, 0.5, 0.5, fs5), (3, 1, 1, g5), (3, 2, 2, b5),
    // A'
    (4, 0, 1, d5),
    (4, 1, 0.5, fs5),
    (4, 1.5, 0.5, a5),
    (4, 2, 1, a5),
    (4, 3, 1, fs5),
    (5, 0, 1, e5), (5, 1, 0.5, a5), (5, 1.5, 0.5, cs6), (5, 2, 2, b5),
    (6, 0, 1, b5), (6, 1, 1, a5), (6, 2, 1, g5), (6, 3, 1, fs5),
    (7, 0, 2, e5), (7, 2, 2, a5),
    // B
    (8, 0, 1, fs5), (8, 1, 1, b5), (8, 2, 2, d6),
    (9, 0, 0.5, d6), (9, 0.5, 0.5, b5), (9, 1, 1, g5), (9, 2, 2, b5),
    (10, 0, 1, a5), (10, 1, 1, fs5), (10, 2, 1, d5), (10, 3, 1, fs5),
    (11, 0, 1, e5), (11, 1, 1, a5), (11, 2, 2, cs6),
    (12, 0, 1, b5), (12, 1, 1, d6), (12, 2, 2, fs6),
    (13, 0, 1, e6), (13, 1, 1, d6), (13, 2, 2, b5),
    (14, 0, 1, g5), (14, 1, 1, b5), (14, 2, 1, e6), (14, 3, 1, d6),
    (15, 0, 2, cs6), (15, 2, 2, a5),
  ];

  const bell = [
    Partial(1.0, 1.0, 2.6),
    Partial(2.0, 0.35, 4.5),
    Partial(3.0, 0.12, 7),
    Partial(4.07, 0.05, 10),
  ];
  const marimba = [
    Partial(1.0, 1.0, 7),
    Partial(4.0, 0.22, 18),
    Partial(10.0, 0.04, 40),
  ];
  const padTone = [
    Partial(1.0, 1.0, 0.45),
    Partial(2.0, 0.16, 0.8),
    Partial(3.0, 0.05, 1.2),
  ];
  const bassTone = [
    Partial(1.0, 1.0, 4.0),
    Partial(2.0, 0.45, 7),
    Partial(3.0, 0.12, 11),
  ];
  const sparkle = [Partial(1.0, 1.0, 9), Partial(2.0, 0.3, 14)];

  for (var bar = 0; bar < bars; bar++) {
    final start = bar * 4 * beat;
    final chord = chords[bar];
    final root = roots[bar];

    // Pads: soft, slow-blooming chords.
    for (final f in chord) {
      tone(f, start, 4 * beat + 1.0, menu ? 0.07 : 0.06, padTone, attack: 0.35);
    }

    // Bass: root on 1, the octave bounce on the "and" of 2, root on 3, fifth
    // leading on 4.
    const pattern = [(0.0, 1.0), (1.5, 2.0), (2.0, 1.0), (3.0, 1.5)];
    for (final (b, mult) in pattern) {
      tone(
        root * mult,
        start + b * beat,
        0.5,
        menu ? 0.22 : 0.16,
        bassTone,
        attack: 0.006,
      );
    }

    // Arpeggios: chord tones an octave up, in eighths (every other in play).
    for (var step = 0; step < 8; step++) {
      if (!menu && step.isOdd) continue;
      final f = chord[step % chord.length] * 2;
      tone(
        f,
        start + step * beat / 2,
        0.35,
        step.isEven ? 0.06 : 0.04,
        sparkle,
      );
    }

    if (menu) {
      for (var b = 0; b < 4; b++) {
        final at = start + b * beat;
        if (b == 0 || b == 2) kick(at, 0.32);
        if (b == 1 || b == 3) hit(at, 0.18, 22, 0.05);
        hit(at + beat / 2, 0.06, 70, 0.035);
      }
    }
  }

  // The hook: a bell doubled by a marimba an octave down, for body.
  for (final (bar, b, len, f) in melody) {
    final at = (bar * 4 + b) * beat;
    final seconds = len * beat + 0.5;
    tone(f, at, seconds, menu ? 0.16 : 0.1, bell, vibrato: 0.002);
    tone(f / 2, at, seconds * 0.7, menu ? 0.07 : 0.045, marimba);
  }

  // Normalise, with a gentle soft-clip so the busiest beats never crack.
  var peak = 0.0;
  for (final s in out) {
    if (s.abs() > peak) peak = s.abs();
  }
  // The gameplay loop is mastered lower: with no drums its peaks are
  // softer, and normalising both to one peak would make it the louder one.
  final gain = peak == 0 ? 0.0 : (menu ? 0.62 : 0.34) / peak;
  for (var i = 0; i < out.length; i++) {
    final v = out[i] * gain;
    out[i] = v / (1 + v.abs() * 0.3);
  }
  return encodeWav(out, sampleRate: rate);
}

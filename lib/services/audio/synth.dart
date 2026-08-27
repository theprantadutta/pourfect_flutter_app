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

  /// A tube just completed. Warmer and a fifth above the pour, with a longer
  /// tail — the ear reads it as resolution.
  final Uint8List tubeComplete;

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
    tubeComplete: encodeWav(
      renderTone(
        frequency: 294,
        seconds: 0.75,
        attack: 0.008,
        partials: const [
          Partial(1.0, 1.00, 6),
          Partial(1.5, 0.42, 9),
          Partial(2.0, 0.20, 13),
          Partial(3.0, 0.07, 20),
        ],
      ),
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

// The sound design is pure Dart, so it is testable without a device — which
// matters, because "the pour sounds wrong" is otherwise only discoverable by
// building an APK and listening.

import 'dart:typed_data';

import 'package:pourfect_flutter_app/services/audio/synth.dart';
import 'package:test/test.dart';

void main() {
  group('WAV encoding', () {
    test('writes a valid 16-bit mono header', () {
      final wav = encodeWav(Float64List(100));
      expect(wav.length, 44 + 200);
      expect(String.fromCharCodes(wav.sublist(0, 4)), 'RIFF');
      expect(String.fromCharCodes(wav.sublist(8, 12)), 'WAVE');

      final view = ByteData.sublistView(wav);
      expect(view.getUint16(22, Endian.little), 1, reason: 'mono');
      expect(view.getUint32(24, Endian.little), kSampleRate);
      expect(view.getUint16(34, Endian.little), 16, reason: '16-bit');
    });

    test('clamps rather than wrapping on overload', () {
      // A wrapped sample is a loud crack. Clamping is merely loud.
      final wav = encodeWav(Float64List.fromList([4.0, -4.0]));
      final view = ByteData.sublistView(wav);
      expect(view.getInt16(44, Endian.little), 32767);
      expect(view.getInt16(46, Endian.little), -32767);
    });
  });

  group('tone rendering', () {
    final tone = renderTone(
      frequency: 200,
      seconds: 0.2,
      partials: const [Partial(1, 1, 10)],
    );

    test('produces the requested duration', () {
      expect(tone.length, (0.2 * kSampleRate).round());
    });

    test('starts at silence, so there is no onset click', () {
      // An instant onset is a click, and a click heard a thousand times a
      // session is listening fatigue.
      expect(tone.first.abs(), lessThan(0.02));
    });

    test('ends at silence, so there is no cutoff click', () {
      expect(tone.last.abs(), lessThan(0.02));
    });

    test('never exceeds full scale', () {
      for (final s in tone) {
        expect(s.abs(), lessThanOrEqualTo(1.0));
      }
    });

    test('actually decays', () {
      // Compared as windowed energy, not as single samples: one instant of a
      // sine can sit on a zero crossing at any amplitude, so a point
      // comparison would pass or fail on phase rather than on envelope.
      double energy(double fromSeconds) {
        final start = (fromSeconds * kSampleRate).round();
        final end = start + (0.02 * kSampleRate).round();
        var sum = 0.0;
        for (var i = start; i < end && i < tone.length; i++) {
          sum += tone[i] * tone[i];
        }
        return sum;
      }

      expect(energy(0.12), lessThan(energy(0.01)));
    });

    test('is deterministic for a given seed', () {
      List<double> render() => renderTone(
        frequency: 200,
        seconds: 0.05,
        noise: 0.3,
        seed: 42,
        partials: const [Partial(1, 1, 10)],
      );
      expect(render(), render());
    });
  });

  group('pour pitch', () {
    test('rises as the tube fills', () {
      // A filling vessel rises in pitch as the air column shortens. A run of
      // four therefore plays as a rising figure instead of one note four times.
      var previous = 0.0;
      for (var i = 0; i <= 4; i++) {
        final speed = pourSpeedForFill(i / 4, 0.5);
        expect(speed, greaterThan(previous));
        previous = speed;
      }
    });

    test('stays inside a musical range', () {
      // Beyond about a fifth in either direction it stops sounding like the
      // same object being struck.
      for (var i = 0; i <= 10; i++) {
        for (final jitter in [0.0, 0.5, 1.0]) {
          final speed = pourSpeedForFill(i / 10, jitter);
          expect(speed, inInclusiveRange(0.8, 1.4));
        }
      }
    });

    test('jitter keeps two identical pours from sounding stamped', () {
      expect(pourSpeedForFill(0.5, 0), isNot(pourSpeedForFill(0.5, 1)));
    });

    test('clamps a fill outside 0..1', () {
      expect(pourSpeedForFill(-3, 0.5), pourSpeedForFill(0, 0.5));
      expect(pourSpeedForFill(9, 0.5), pourSpeedForFill(1, 0.5));
    });
  });

  group('sound bank', () {
    final bank = SoundBank.generate();

    test('every cue is a non-empty WAV', () {
      final clips = <String, Uint8List>{
        'pour': bank.pour,
        'select': bank.select,
        'tubeComplete': bank.tubeComplete,
        'win': bank.win,
        'newBest': bank.newBest,
        ...{
          for (var i = 0; i < bank.stars.length; i++) 'star$i': bank.stars[i],
        },
      };

      clips.forEach((name, wav) {
        expect(wav.length, greaterThan(44), reason: '$name is empty');
        expect(
          String.fromCharCodes(wav.sublist(0, 4)),
          'RIFF',
          reason: '$name is not a WAV',
        );
      });
    });

    test('the whole bank is small enough to build at startup', () {
      final total =
          bank.pour.length +
          bank.select.length +
          bank.tubeComplete.length +
          bank.win.length +
          bank.newBest.length +
          bank.stars.fold<int>(0, (sum, s) => sum + s.length);
      // Well under a megabyte of RAM, and zero bytes of APK.
      expect(total, lessThan(1200000));
    });

    test('the third star is richer and longer than the first two', () {
      // Three stars has to feel meaningfully better than two, and the sound is
      // half of that difference.
      expect(bank.stars[2].length, greaterThan(bank.stars[0].length));
      expect(bank.stars[2].length, greaterThan(bank.stars[1].length));
    });

    test('the pour is short — it has to disappear under a fast run', () {
      expect(bank.pour.length, lessThan(bank.tubeComplete.length));
      expect(bank.pour.length, lessThan(bank.win.length));
    });
  });
}

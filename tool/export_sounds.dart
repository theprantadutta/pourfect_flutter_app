// Writes every sound in the game to build/sound_preview/ as WAV files, so the
// sound design can be listened to on a computer, no phone needed:
//
//   dart run tool/export_sounds.dart
import 'dart:io';
import 'dart:typed_data';

import 'package:pourfect_flutter_app/services/audio/synth.dart';

void main() {
  final dir = Directory('build/sound_preview')..createSync(recursive: true);
  void write(String name, Uint8List bytes) =>
      File('${dir.path}/$name.wav').writeAsBytesSync(bytes);

  final bank = SoundBank.generate();
  write('game_pour', bank.pour);
  write('game_select', bank.select);
  write('game_tube_complete', bank.tubeComplete);
  write('game_final_tube', bank.finalTube);
  for (var i = 0; i < bank.stars.length; i++) {
    write('game_star_${i + 1}', bank.stars[i]);
  }
  write('game_win', bank.win);
  write('game_new_best', bank.newBest);
  for (final entry in generateUiCues().entries) {
    write('ui_${entry.key.name}', entry.value);
  }
  final watch = Stopwatch()..start();
  write('music_menu', renderMusicLoop(MusicScene.menu));
  write('music_play', renderMusicLoop(MusicScene.play));
  stdout.writeln(
    'Wrote ${dir.listSync().length} files to ${dir.absolute.path} '
    '(music rendered in ${watch.elapsedMilliseconds} ms)',
  );
}

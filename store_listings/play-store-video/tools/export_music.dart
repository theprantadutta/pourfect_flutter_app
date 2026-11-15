import 'dart:io';
import 'package:pourfect_flutter_app/services/audio/synth.dart';
void main(List<String> args) {
  File(args[0]).writeAsBytesSync(renderMusicLoop(MusicScene.menu));
}

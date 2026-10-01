/// Exports the bundled campaign's BOARDS for the backend.
///
///     dart run tool/export_campaign_boards.dart ../pourfect-dotnet-api/src/Pourfect.Api/SeedData/campaign_boards.json
///
/// The server's `campaign_levels.csv` carries each level's metadata (par, band,
/// difficulty) and was the only copy it needed: the boards ship in the APK.
/// The admin dashboard draws boards, and the world generator dedupes against
/// every board already served, so the server now keeps the 150 too. Re-run
/// this, like re-copying the CSV, whenever `levels.bin` is re-baked.
library;

import 'dart:convert';
import 'dart:io';

import 'package:pourfect_flutter_app/engine/level_set.dart';

Future<void> main(List<String> args) async {
  if (args.length != 1) {
    stderr.writeln(
      'usage: dart run tool/export_campaign_boards.dart <out.json>',
    );
    exit(64);
  }
  final set = LevelSetCodec.decode(
    await File('assets/levels/levels.bin').readAsBytes(),
  );
  final json = {
    'level_set_version': set.levelSetVersion,
    'levels': [
      for (final l in set.levels)
        {
          'id': l.id,
          'capacity': l.level.board.capacity,
          'tubes': [for (final t in l.level.board.tubes) t.balls],
        },
    ],
  };
  await File(args.single).writeAsString(jsonEncode(json));
  stdout.writeln('wrote ${set.levels.length} boards to ${args.single}');
}

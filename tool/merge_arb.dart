// Builds lib/l10n/app_<locale>.arb from the per-area sources in
// lib/l10n/src/<locale>/*.arb.
//
// Why split at all: every screen's strings live in their own file
// (src/en/settings.arb, src/en/home.arb, ...), so translating or extracting
// one area never touches another's file, and parallel work merges cleanly.
// gen-l10n wants ONE file per locale, so this stitches them together.
//
//   dart run tool/merge_arb.dart && flutter gen-l10n
//
// Fails on a key defined twice, or on a translation of a key that English
// does not have (a typo there is a string that silently never shows).
import 'dart:convert';
import 'dart:io';

void main() {
  final src = Directory('lib/l10n/src');
  if (!src.existsSync()) {
    stderr.writeln('no lib/l10n/src');
    exit(1);
  }
  final locales = src.listSync().whereType<Directory>().toList()
    ..sort((a, b) => a.path.compareTo(b.path));

  Map<String, Object?> merge(Directory dir) {
    final out = <String, Object?>{};
    final files =
        dir
            .listSync()
            .whereType<File>()
            .where((f) => f.path.endsWith('.arb'))
            .toList()
          ..sort((a, b) => a.path.compareTo(b.path));
    for (final file in files) {
      final map = jsonDecode(file.readAsStringSync()) as Map<String, Object?>;
      for (final MapEntry(:key, :value) in map.entries) {
        if (key.startsWith('@@')) continue;
        if (out.containsKey(key)) {
          stderr.writeln('duplicate key "$key" in ${file.path}');
          exit(1);
        }
        out[key] = value;
      }
    }
    return out;
  }

  final english = merge(Directory('lib/l10n/src/en'));
  final englishKeys = english.keys.where((k) => !k.startsWith('@')).toSet();
  const encoder = JsonEncoder.withIndent('  ');

  for (final dir in locales) {
    final locale = dir.uri.pathSegments.where((s) => s.isNotEmpty).last;
    final merged = locale == 'en' ? english : merge(dir);
    if (locale != 'en') {
      for (final key in merged.keys.where((k) => !k.startsWith('@'))) {
        if (!englishKeys.contains(key)) {
          stderr.writeln('$locale has "$key", which English does not');
          exit(1);
        }
      }
    }
    final file = File('lib/l10n/app_$locale.arb');
    file.writeAsStringSync(
      '${encoder.convert({'@@locale': locale, ...merged})}\n',
    );
    final count = merged.keys.where((k) => !k.startsWith('@')).length;
    stdout.writeln('app_$locale.arb: $count messages');
  }
}

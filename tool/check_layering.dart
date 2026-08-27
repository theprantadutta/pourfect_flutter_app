// Enforces Pourfect's layering rules. Run in CI and before every commit:
//
//   dart run tool/check_layering.dart
//
// Two rules, both of which decay silently the moment they stop being checked —
// a single convenient import is all it takes, and by the time anyone notices,
// untangling it is a refactor rather than a one-line fix.
//
//   1. engine/ is PURE DART. No Flutter, no Riverpod, no dart:ui. This is what
//      keeps the solver runnable from `tool/` at build time, testable under
//      plain `dart test` with no device, and cheap to run on an isolate.
//
//   2. ui/ may import engine VALUE TYPES but not engine LOGIC. Widgets are
//      welcome to talk about a Board, a Tube, a Move or a Level — re-wrapping
//      those in parallel UI DTOs would be pure ceremony. What a widget must not
//      do is decide the game: rules, solving, generation and difficulty belong
//      in state/, where they are testable without pumping a widget tree.

import 'dart:io';

/// Packages that must never appear anywhere under lib/engine/.
const _forbiddenInEngine = <String>[
  'package:flutter/',
  'package:flutter_riverpod/',
  'package:riverpod/',
  'package:flutter_test/',
  'dart:ui',
];

/// Engine files that hold game DECISIONS. `ui/` must not import these.
const _engineLogicFiles = <String>[
  'rules.dart',
  'solver.dart',
  'generator.dart',
  'difficulty.dart',
  'canonical.dart',
];

/// Engine files that are plain data. `ui/` may import these freely.
const _engineValueFiles = <String>[
  'board.dart',
  'move.dart',
  'level.dart',
  'engine_types.dart',
];

final _importPattern = RegExp(
  r'''^\s*(?:import|export)\s+['"]([^'"]+)['"]''',
  multiLine: true,
);

void main(List<String> args) {
  final violations = <String>[
    ..._checkEngineIsPureDart(),
    ..._checkUiAvoidsEngineLogic(),
  ];

  if (violations.isEmpty) {
    stdout.writeln(
      'Layering OK — engine is pure Dart, ui/ holds no game logic.',
    );
    return;
  }

  stderr.writeln('Layering violations (${violations.length}):\n');
  for (final v in violations) {
    stderr.writeln('  $v');
  }
  stderr.writeln(
    '\nSee the header of tool/check_layering.dart for why each rule exists.',
  );
  exit(1);
}

List<String> _checkEngineIsPureDart() {
  final violations = <String>[];

  for (final file in _dartFilesIn('lib/engine')) {
    for (final import in _importsOf(file)) {
      for (final forbidden in _forbiddenInEngine) {
        if (import.startsWith(forbidden)) {
          violations.add(
            '${_rel(file)} imports "$import" — engine/ must stay pure Dart so '
            'it runs under `dart test` and on a background isolate.',
          );
        }
      }
    }
  }

  return violations;
}

List<String> _checkUiAvoidsEngineLogic() {
  final violations = <String>[];

  for (final file in _dartFilesIn('lib/ui')) {
    for (final import in _importsOf(file)) {
      if (!import.contains('engine/')) continue;

      final basename = import.split('/').last;
      if (_engineValueFiles.contains(basename)) continue;

      if (_engineLogicFiles.contains(basename)) {
        violations.add(
          '${_rel(file)} imports engine logic "$basename" — move the decision '
          'into state/ and let the widget render the result.',
        );
      } else {
        violations.add(
          '${_rel(file)} imports "$import", which is not a known engine value '
          'type. Add it to _engineValueFiles here if it is plain data.',
        );
      }
    }
  }

  return violations;
}

Iterable<File> _dartFilesIn(String path) {
  final dir = Directory(path);
  if (!dir.existsSync()) return const [];
  return dir
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'));
}

Iterable<String> _importsOf(File file) =>
    _importPattern.allMatches(file.readAsStringSync()).map((m) => m.group(1)!);

String _rel(File file) => file.path.replaceAll(r'\', '/');

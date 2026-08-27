/// The engine's UI-facing surface: value types only.
///
/// `ui/` imports THIS file, never the engine's logic files. Widgets legitimately
/// need to talk about a [Board], a [Tube], a [Move] and a [Level] — re-wrapping
/// those into parallel UI DTOs would be pure ceremony. What widgets must not do
/// is reach for `rules.dart`, `solver.dart`, `generator.dart`, `difficulty.dart`
/// or `canonical.dart`: game decisions belong in `state/`, where they are
/// testable without pumping a widget tree.
///
/// `tool/check_layering.dart` enforces the split.
library;

export 'board.dart';
export 'level.dart';
export 'level_set.dart';
export 'move.dart';

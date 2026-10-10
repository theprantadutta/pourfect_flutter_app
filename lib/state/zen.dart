/// Zen mode: endless boards, made on the phone, with nothing at stake.
///
/// For the player who has finished everything else (or just wants to pour):
/// no clock, no stars, no leaderboard — a count of boards poured, and the next
/// board already waiting. Boards come from the same generator and solver as
/// the campaign, so every one is proven solvable; they are made off the UI
/// thread, because the solver can take a moment on a big board.
library;

import 'dart:isolate';
import 'dart:math';

import '../engine/generator.dart';
import '../engine/level.dart';

/// Levels cleared before Zen opens. A constant, so it is one line to change.
const int kZenUnlockLevel = 30;

/// How busy a Zen board is.
enum ZenPace {
  calm('Calm', 4, 0, 45),
  steady('Steady', 6, 25, 65),
  deep('Deep', 8, 45, 90);

  final String label;
  final int colors;
  final double minScore;
  final double maxScore;

  const ZenPace(this.label, this.colors, this.minScore, this.maxScore);
}

/// One solver-verified Zen board for [pace], made on a background isolate.
///
/// [seed] makes it reproducible in tests; real play passes a fresh random.
Future<Level> makeZenBoard(ZenPace pace, int seed) =>
    Isolate.run(() => _make(pace.colors, pace.minScore, pace.maxScore, seed));

Level _make(int colors, double minScore, double maxScore, int seed) {
  final generator = LevelGenerator(random: Random(seed));
  GeneratedLevel generated;
  try {
    generated = generator.generate(
      LevelSpec(colorCount: colors),
      minScore: minScore,
      maxScore: maxScore,
      maxAttempts: 400,
    );
  } on StateError {
    // The window was too tight for this seed: any proven-solvable board of
    // the right size will do. Zen is about pouring, not about a score.
    generated = generator.generate(LevelSpec(colorCount: colors));
  }
  // Id 0 and level set 0, like the daily: never mistaken for the campaign.
  return generated.toLevel(0);
}

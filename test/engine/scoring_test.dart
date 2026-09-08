// Par times and points.
//
// The rule these pin is a product decision the whole feature rests on: THE
// CLOCK NEVER TOUCHES STARS. Stars are a moves rating and always have been,
// every star already saved was earned without a clock, and folding time into
// them would silently change what a player's existing record means. Time moves
// the score and nothing else.

import 'package:pourfect_flutter_app/engine/board.dart';
import 'package:pourfect_flutter_app/engine/level.dart';
import 'package:test/test.dart';

void main() {
  group('par is derived from the solved optimum', () {
    test('a longer level gets a longer par', () {
      expect(parSecondsFor(20), greaterThan(parSecondsFor(10)));
      expect(parSecondsFor(60), greaterThan(parSecondsFor(20)));
    });

    test(
      'par is generous — five seconds a move, plus a thinking allowance',
      () {
        // The game is played in bed. Par is the pace of somebody who knows what
        // they are doing and is not hurrying, not a speedrun target.
        expect(parSecondsFor(14), 100);
        expect(parSecondsFor(0), 30);
      },
    );

    test('every level has a par, including a trivial one', () {
      for (final minMoves in [1, 2, 5, 14, 38, 61, 200]) {
        expect(parSecondsFor(minMoves), greaterThan(0), reason: '$minMoves');
      }
    });
  });

  group('the time multiplier', () {
    test('is exactly 1.0 at par', () {
      expect(timeMultiplierFor(parSeconds: 100, elapsedSeconds: 100), 1.0);
    });

    test('rewards a faster solve, up to a ceiling', () {
      final quick = timeMultiplierFor(parSeconds: 100, elapsedSeconds: 80);
      expect(quick, greaterThan(1.0));
      expect(quick, lessThanOrEqualTo(kMaxTimeMultiplier));
    });

    test(
      'a forged one-second solve is worth no more than an honest fast one',
      () {
        // THE CHEAT BOUND. The elapsed time arrives from the client, so the
        // ceiling — not a plausibility check — is what makes lying about it
        // pointless. Both of these hit the same cap.
        expect(
          timeMultiplierFor(parSeconds: 300, elapsedSeconds: 1),
          kMaxTimeMultiplier,
        );
        expect(
          timeMultiplierFor(parSeconds: 300, elapsedSeconds: 200),
          kMaxTimeMultiplier,
        );
      },
    );

    test('a very slow solve still banks the floor, never zero', () {
      // Somebody who wandered off mid-level and came back an hour later has
      // still finished the level. Finishing is always worth something — the
      // same rule the one-star floor follows.
      expect(
        timeMultiplierFor(parSeconds: 100, elapsedSeconds: 100000),
        kMinTimeMultiplier,
      );
      expect(kMinTimeMultiplier, greaterThan(0));
    });

    test('nonsense input does not produce nonsense output', () {
      expect(timeMultiplierFor(parSeconds: 0, elapsedSeconds: 50), 1.0);
      expect(
        timeMultiplierFor(parSeconds: 100, elapsedSeconds: 0),
        kMaxTimeMultiplier,
      );
      expect(
        timeMultiplierFor(parSeconds: 100, elapsedSeconds: -5),
        kMaxTimeMultiplier,
      );
    });
  });

  group('points', () {
    test('an optimal solve at par scores the level base', () {
      expect(
        pointsFor(
          minMoves: 10,
          movesUsed: 10,
          elapsedSeconds: parSecondsFor(10),
        ),
        kPointsPerOptimalMove * 10,
      );
    });

    test('a harder level is worth more, solved just as cleanly', () {
      final easy = pointsFor(
        minMoves: 10,
        movesUsed: 10,
        elapsedSeconds: parSecondsFor(10),
      );
      final hard = pointsFor(
        minMoves: 40,
        movesUsed: 40,
        elapsedSeconds: parSecondsFor(40),
      );
      expect(hard, greaterThan(easy));
    });

    test('taking longer than par scores less — the point of the feature', () {
      final onPace = pointsFor(
        minMoves: 20,
        movesUsed: 20,
        elapsedSeconds: parSecondsFor(20),
      );
      final slow = pointsFor(
        minMoves: 20,
        movesUsed: 20,
        elapsedSeconds: parSecondsFor(20) * 3,
      );
      expect(slow, lessThan(onPace));
    });

    test('extra moves score less, independently of the clock', () {
      final par = parSecondsFor(20);
      expect(
        pointsFor(minMoves: 20, movesUsed: 30, elapsedSeconds: par),
        lessThan(pointsFor(minMoves: 20, movesUsed: 20, elapsedSeconds: par)),
      );
    });

    test('a finished level always scores something', () {
      expect(
        pointsFor(minMoves: 20, movesUsed: 400, elapsedSeconds: 100000),
        greaterThan(0),
      );
    });

    test('an unfinished level scores nothing', () {
      expect(pointsFor(minMoves: 20, movesUsed: 0, elapsedSeconds: 60), 0);
    });
  });

  group('stars are untouched by the clock', () {
    // If this ever fails, somebody folded time into the star rating and every
    // star saved before the clock shipped now means something different.
    test('the star rating takes no time argument at all', () {
      expect(starsFor(minMoves: 10, movesUsed: 10), 3);
      expect(starsFor(minMoves: 10, movesUsed: 15), 2);
      expect(starsFor(minMoves: 10, movesUsed: 40), 1);
    });

    test('two runs differing only in time earn identical stars', () {
      final level = Level(
        id: 1,
        board: Board.fromLists([
          [0, 0, 0],
          [1, 1, 1, 1],
          [0],
        ], capacity: 4),
        minMoves: 10,
        difficultyScore: 20,
        forcedMoveRatio: 1,
      );

      expect(level.stars(10), level.stars(10));
      expect(
        level.points(movesUsed: 10, elapsedSeconds: 30),
        greaterThan(level.points(movesUsed: 10, elapsedSeconds: 3000)),
        reason: 'the score must move even though the stars do not',
      );
    });
  });
}

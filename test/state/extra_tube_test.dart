// The extra tube: when it may be offered, and what it must not break.
//
// Two invariants carry the whole feature, and neither is visible by reading
// `grantExtraTube` on its own.
//
// An assisted solve must still be SUBMITTABLE. The server rejects anything
// below the proven optimum as impossible, and an extra tube genuinely can make
// a board solvable in fewer moves than the original optimum — so an assisted
// clear is recorded at par + 1 at least (two stars at most), whenever in the
// attempt the tube was bought.
//
// Undo must stay free and unlimited. The tube is added to every board in the
// history as well as the live one, because otherwise a single undo hands back
// the old tube count and destroys what somebody watched a video for.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pourfect_flutter_app/engine/board.dart';
import 'package:pourfect_flutter_app/services/ads/ad_service.dart';
import 'package:pourfect_flutter_app/engine/level.dart';
import 'package:pourfect_flutter_app/state/game_controller.dart';
import 'package:pourfect_flutter_app/state/game_state.dart';
import 'package:pourfect_flutter_app/state/providers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// A board that takes exactly [minMoves] to solve, per the level metadata.
  ///
  /// The numbers do not have to be a real generated level — nothing here
  /// solves anything. What matters is the relationship between `minMoves` and
  /// the moves spent, because that is what the gate reads.
  Level levelWith({required int minMoves}) => Level(
    id: 1,
    minMoves: minMoves,
    difficultyScore: 20,
    forcedMoveRatio: 0.1,
    board: Board.fromLists([
      [0, 1, 0, 1],
      [1, 0, 1, 0],
      [],
    ], capacity: 4),
  );

  ProviderContainer harness() {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    return container;
  }

  GameController started(ProviderContainer container, Level level) {
    final game = container.read(gameControllerProvider.notifier);
    game.startLevel(level, levelSetVersion: 1);
    return game;
  }

  group('when it may be offered', () {
    test('not early to a player who can still move', () {
      final container = harness();
      started(container, levelWith(minMoves: 6));

      final state = container.read(gameControllerProvider)!;
      expect(state.movesUsed, isZero);
      expect(state.isStuck, isFalse);
      expect(state.canOfferExtraTube(), isFalse);
    });

    test('offered on the exact move par is reached, and not before', () {
      final container = harness();
      started(container, levelWith(minMoves: 2));
      final game = container.read(gameControllerProvider.notifier);

      // A tap to select and a tap to pour is ONE move.
      game.tapTube(0);
      game.tapTube(2);
      expect(container.read(gameControllerProvider)!.movesUsed, 1);
      expect(
        container.read(gameControllerProvider)!.canOfferExtraTube(),
        isFalse,
        reason: 'offered one move short of par',
      );

      game.tapTube(1);
      game.tapTube(0);
      expect(container.read(gameControllerProvider)!.movesUsed, 2);
      expect(
        container.read(gameControllerProvider)!.canOfferExtraTube(),
        isTrue,
      );
    });

    test('offered before par in a proven dead end', () {
      // Owner's call, 2026-10-10: help goes to whoever is stuck, at any move.
      final container = harness();
      started(container, levelWith(minMoves: 6));

      final state = container.read(gameControllerProvider)!;
      expect(state.canOfferExtraTube(deadEnd: true), isTrue);
    });

    test('offered before par with no legal move left', () {
      final container = harness();
      started(
        container,
        Level(
          id: 1,
          minMoves: 6,
          difficultyScore: 20,
          forcedMoveRatio: 0.1,
          board: Board.fromLists([
            [0, 1],
            [1, 0],
          ], capacity: 2),
        ),
      );

      final state = container.read(gameControllerProvider)!;
      expect(state.isStuck, isTrue);
      expect(state.canOfferExtraTube(), isTrue);
    });

    test('at most $kMaxExtraTubes in one attempt', () {
      final container = harness();
      started(container, levelWith(minMoves: 1));

      final game = container.read(gameControllerProvider.notifier);
      game.tapTube(0);
      game.tapTube(2);

      for (var i = 0; i < kMaxExtraTubes; i++) {
        expect(game.grantExtraTube(), isTrue);
      }
      final state = container.read(gameControllerProvider)!;
      expect(state.extraTubesUsed, kMaxExtraTubes);
      expect(state.canOfferExtraTube(deadEnd: true), isFalse);
      expect(game.grantExtraTube(), isFalse);
    });

    test('a restart takes the tubes back and offers them again', () {
      // Per attempt, not per level: restarting hands back the board as it was
      // generated, so it hands back the offer too.
      final container = harness();
      final level = levelWith(minMoves: 1);
      started(container, level);

      final game = container.read(gameControllerProvider.notifier);
      game.tapTube(0);
      game.tapTube(2);
      game.grantExtraTube();

      final granted = container.read(gameControllerProvider)!;
      expect(granted.board.tubeCount, level.board.tubeCount + 1);

      game.restart();

      final afterRestart = container.read(gameControllerProvider)!;
      expect(afterRestart.board.tubeCount, level.board.tubeCount);
      expect(afterRestart.extraTubesUsed, isZero);
    });
  });

  group('an assisted clear', () {
    test('is recorded at par + 1 at least, so it earns two stars at most', () {
      // THE RULE THAT KEEPS AN ASSISTED SOLVE LEGAL. The server rejects a count
      // under the proven optimum, and a spare tube can beat it.
      final container = harness();
      started(container, levelWith(minMoves: 6));
      final game = container.read(gameControllerProvider.notifier);
      expect(game.grantExtraTube(), isTrue);

      final state = container.read(gameControllerProvider)!;
      expect(state.movesUsed, isZero);
      expect(state.recordedMoves, state.level.minMoves + 1);
      expect(state.stars, lessThanOrEqualTo(2));
    });

    test('keeps its own count once it is already past par', () {
      final container = harness();
      started(container, levelWith(minMoves: 1));
      final game = container.read(gameControllerProvider.notifier);
      game.tapTube(0);
      game.tapTube(2);
      game.tapTube(1);
      game.tapTube(0);
      game.grantExtraTube();

      final state = container.read(gameControllerProvider)!;
      expect(state.recordedMoves, state.movesUsed);
    });

    test('an unassisted attempt records exactly what it played', () {
      final container = harness();
      started(container, levelWith(minMoves: 6));
      final state = container.read(gameControllerProvider)!;
      expect(state.recordedMoves, state.movesUsed);
    });
  });

  group('the ad inventory matches what the game can show', () {
    test('every reachable placement has a feature behind it', () {
      // The check that would have caught two dead units burning a load request
      // per session. levelSkip is deliberately unreachable — see
      // RewardedPlacement.isReachable — and hint and extraTube both have
      // gameplay that can reach them.
      expect(RewardedPlacement.hint.isReachable, isTrue);
      expect(RewardedPlacement.extraTube.isReachable, isTrue);
      expect(RewardedPlacement.streakFreeze.isReachable, isTrue);
      expect(RewardedPlacement.chestDouble.isReachable, isTrue);
      expect(
        RewardedPlacement.levelSkip.isReachable,
        isFalse,
        reason:
            'preloading a placement nothing can show makes the fill rate '
            'for the whole account meaningless',
      );
    });
  });

  group('what it must not break', () {
    test('undo does not take the tube away', () {
      // THE BUG THIS EXISTS TO STOP. The undo stack holds whole boards, so
      // without rewriting it one undo restores a board with the old tube count
      // and silently destroys what the player watched a video for.
      final container = harness();
      final level = levelWith(minMoves: 1);
      started(container, level);

      final game = container.read(gameControllerProvider.notifier);
      game.tapTube(0);
      game.tapTube(2);
      game.grantExtraTube();

      final expected = level.board.tubeCount + 1;
      expect(container.read(gameControllerProvider)!.board.tubeCount, expected);

      // All the way back to the start.
      while (container.read(gameControllerProvider)!.canUndo) {
        game.undo();
      }

      expect(
        container.read(gameControllerProvider)!.board.tubeCount,
        expected,
        reason: 'undoing past the grant took back a tube that was paid for',
      );
    });

    test('undo is still free and unlimited after a grant', () {
      final container = harness();
      started(container, levelWith(minMoves: 1));

      final game = container.read(gameControllerProvider.notifier);
      game.tapTube(0);
      game.tapTube(2);
      final movesBefore = container.read(gameControllerProvider)!.movesUsed;

      final boardBefore = container.read(gameControllerProvider)!.undoStack;
      game.grantExtraTube();

      expect(container.read(gameControllerProvider)!.canUndo, isTrue);
      expect(game.undo(), isTrue);
      final after = container.read(gameControllerProvider)!;
      // The BOARD goes back, as far as the player likes...
      expect(after.undoStack.length, boardBefore.length - 1);
      // ...but moves spent before the grant are not handed back. See
      // GameState.movesFloor.
      expect(after.movesUsed, movesBefore);
    });

    test('undoing past the grant cannot finish under par', () {
      // Undo used to take the count back to zero with the spare tube still
      // in place, and a clear then scored three stars in fewer moves than
      // the board allows. The floor still holds the count at the grant.
      final container = harness();
      started(container, levelWith(minMoves: 1));

      final game = container.read(gameControllerProvider.notifier);
      game.tapTube(0);
      game.tapTube(2);
      final atGrant = container.read(gameControllerProvider)!.movesUsed;
      expect(game.grantExtraTube(), isTrue);

      while (game.undo()) {}
      final state = container.read(gameControllerProvider)!;
      expect(state.canUndo, isFalse);
      expect(state.movesUsed, atGrant);
      expect(state.movesUsed, greaterThanOrEqualTo(state.level.minMoves));
    });

    test('the granted tube is empty and appended, never inserted', () {
      // Every live index — the selection, a pending hint, the pour animation —
      // points at a tube by position. Inserting anywhere but the end silently
      // repoints all of them.
      final container = harness();
      final level = levelWith(minMoves: 1);
      started(container, level);

      final game = container.read(gameControllerProvider.notifier);
      game.tapTube(0);
      game.tapTube(2);

      final before = container.read(gameControllerProvider)!.board;
      game.grantExtraTube();
      final after = container.read(gameControllerProvider)!.board;

      for (var i = 0; i < before.tubeCount; i++) {
        expect(after[i].balls, before[i].balls, reason: 'tube $i moved');
      }
      expect(after[after.tubeCount - 1].balls, isEmpty);
      expect(after.capacity, before.capacity);
    });

    test('granting does not count as a move', () {
      // It is help, not play. Counting it would push the player further past
      // par for the privilege of asking.
      final container = harness();
      started(container, levelWith(minMoves: 1));

      final game = container.read(gameControllerProvider.notifier);
      game.tapTube(0);
      game.tapTube(2);
      final moves = container.read(gameControllerProvider)!.movesUsed;

      game.grantExtraTube();

      expect(container.read(gameControllerProvider)!.movesUsed, moves);
    });
  });
}

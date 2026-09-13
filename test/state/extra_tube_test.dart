// The extra tube: when it may be offered, and what it must not break.
//
// Two invariants carry the whole feature, and neither is visible by reading
// `grantExtraTube` on its own.
//
// An assisted solve must still be SUBMITTABLE. The server rejects anything
// below the proven optimum as impossible, and an extra tube genuinely can make
// a board solvable in fewer moves than the original optimum — so the offer is
// gated on par already being spent, and the floor never has to be relaxed or
// lied to.
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
    board: Board.fromLists(
      [
        [0, 1, 0, 1],
        [1, 0, 1, 0],
        [],
      ],
      capacity: 4,
    ),
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
    test('not before par has been spent', () async {
      // THE RULE THAT KEEPS AN ASSISTED SOLVE LEGAL. A tube handed over on
      // move two can produce a clear under the proven optimum, which the
      // server rejects outright — the win would simply never reach the
      // account.
      final container = harness();
      final game = started(container, levelWith(minMoves: 6));

      expect(container.read(gameControllerProvider)!.movesUsed, isZero);
      expect(
        container.read(gameControllerProvider)!.canOfferExtraTube,
        isFalse,
        reason: 'offered before the floor could no longer be breached',
      );
      expect(game, isNotNull);
    });

    test('offered on the exact move par is reached, and not before', () {
      // The boundary itself, because off-by-one here is the difference between
      // an assisted clear the server accepts and one it silently rejects.
      final container = harness();
      started(container, levelWith(minMoves: 2));
      final game = container.read(gameControllerProvider.notifier);

      // A tap to select and a tap to pour is ONE move.
      game.tapTube(0);
      game.tapTube(2);
      expect(container.read(gameControllerProvider)!.movesUsed, 1);
      expect(
        container.read(gameControllerProvider)!.canOfferExtraTube,
        isFalse,
        reason: 'offered one move short of par',
      );

      game.tapTube(1);
      game.tapTube(0);
      expect(container.read(gameControllerProvider)!.movesUsed, 2);
      expect(container.read(gameControllerProvider)!.canOfferExtraTube, isTrue);
    });

    test('never twice in one attempt', () {
      // A second tube makes almost any board in this campaign fall apart on
      // its own, and a curve that can be bought past is a curve tuned for
      // nothing.
      final container = harness();
      started(container, levelWith(minMoves: 1));

      final game = container.read(gameControllerProvider.notifier);
      game.tapTube(0);
      game.tapTube(2);

      expect(game.grantExtraTube(), isTrue);
      expect(container.read(gameControllerProvider)!.canOfferExtraTube, isFalse);
      expect(game.grantExtraTube(), isFalse);
    });

    test('a restart takes the tube back and offers it again', () {
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
      expect(afterRestart.extraTubeUsed, isFalse);
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
      expect(
        RewardedPlacement.levelSkip.isReachable,
        isFalse,
        reason: 'preloading a placement nothing can show makes the fill rate '
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

      game.grantExtraTube();

      expect(container.read(gameControllerProvider)!.canUndo, isTrue);
      expect(game.undo(), isTrue);
      expect(
        container.read(gameControllerProvider)!.movesUsed,
        movesBefore - 1,
      );
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

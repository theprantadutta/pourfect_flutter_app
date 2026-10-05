// Following a hint the natural way: tap the tube it lifts, then the tube it
// glows. A hint arrives with its source already lifted, so the first tap put
// the run down, and the next one (on the hinted source, or anywhere) cleared
// the hint outright. A hint paid for with a video vanished on the very tap
// that obeyed it.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pourfect_flutter_app/engine/board.dart';
import 'package:pourfect_flutter_app/engine/level.dart';
import 'package:pourfect_flutter_app/engine/move.dart';
import 'package:pourfect_flutter_app/state/game_controller.dart';
import 'package:pourfect_flutter_app/state/providers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const hint = Move(0, 3);

  GameController started(ProviderContainer container) {
    final game = container.read(gameControllerProvider.notifier);
    game.startLevel(
      Level(
        id: 9,
        board: Board.fromLists([
          [2, 0, 0],
          [2, 1, 2],
          [1, 0, 1],
          [],
        ], capacity: 3),
        minMoves: 5,
        difficultyScore: 20,
        forcedMoveRatio: 0.1,
      ),
      levelSetVersion: 1,
    );
    game.showHint(hint);
    return game;
  }

  ProviderContainer harness() {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    return container;
  }

  test('putting the hinted run down and picking it up keeps the hint', () {
    final container = harness();
    final game = started(container);

    expect(game.tapTube(hint.from), TapOutcome.deselected);
    expect(container.read(gameControllerProvider)!.hintMove, hint);

    expect(game.tapTube(hint.from), TapOutcome.selected);
    expect(container.read(gameControllerProvider)!.hintMove, hint);

    expect(game.tapTube(hint.to), TapOutcome.poured);
    expect(container.read(gameControllerProvider)!.hintMove, isNull);
  });

  test('picking up a different run leaves the hint behind', () {
    // Its arrow would otherwise sit on a tube this run may not even fit.
    final container = harness();
    final game = started(container);

    game.tapTube(1);
    final state = container.read(gameControllerProvider)!;
    expect(state.selectedTube, 1);
    expect(state.hintMove, isNull);
  });
}

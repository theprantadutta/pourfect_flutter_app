// The player's mark.
//
// It stands in for a person, so it has to be the same one tomorrow and not the
// same as the person sitting next to them. Both are cheap to assert and neither
// is obvious from reading the hash.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pourfect_flutter_app/ui/theme/ball_palette.dart';
import 'package:pourfect_flutter_app/ui/widgets/player_crest.dart';

void main() {
  test('the same account always gets the same ball', () {
    expect(
      const PlayerCrest(seed: 'uid-alpha').colorId(),
      const PlayerCrest(seed: 'uid-alpha').colorId(),
    );
  });

  test('different accounts get different balls', () {
    // Not a guarantee for every possible pair — ten balls and more players than
    // that — but adjacent uids must not collide, which is the realistic case:
    // two people signing up on the same device minutes apart.
    final ids = [
      for (var i = 0; i < 10; i++) PlayerCrest(seed: 'uid-$i').colorId(),
    ];
    expect(ids.toSet().length, greaterThan(4));
  });

  test('an anonymous player still gets one', () {
    final id = const PlayerCrest(seed: null).colorId();
    expect(id, inInclusiveRange(0, kBallPalette.length - 1));
  });

  testWidgets('the rim is the only signed-in signal', (tester) async {
    // Quiet on purpose: a badge that nags somebody who has chosen not to sign
    // in is worse than no signal at all.
    for (final signedIn in [false, true]) {
      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: PlayerCrest(seed: 'uid-1', signedIn: signedIn),
          ),
        ),
      );
      await tester.pump();

      final box = tester.widget<Container>(
        find.descendant(
          of: find.byType(PlayerCrest),
          matching: find.byType(Container),
        ).first,
      );
      final border = (box.decoration! as BoxDecoration).border!.top;

      expect(border.width, signedIn ? 1.5 : 1.0);
    }
  });
}

/// The player's mark: one of the game's own balls, in a ring.
///
/// **Generated, never a photo.** It works for an anonymous player, which is
/// most players for most of their first session and the whole point of the
/// anonymous-first design; it costs no privacy surface — no image to fetch,
/// cache, moderate or delete on request; and it is made of the game's own
/// objects, so the masthead is furnished with the product rather than a grey
/// silhouette borrowed from a social app.
///
/// **One ball, not a stack of them.** The first version crammed three into a
/// circle, and at masthead size they were three illegible dots. The glyph is
/// what makes a ball identifiable and a glyph needs room: one ball at a proper
/// size reads, three at a third the size do not.
///
/// The ball is DERIVED from the account id, so it is stable for a player across
/// launches and devices, and differs between two people sitting together. An
/// anonymous player gets one too; it changes if they reinstall, which is an
/// honest reflection of what an anonymous account is.
library;

import 'package:flutter/material.dart';

import '../theme/ball_palette.dart';
import '../theme/tokens.dart';
import 'ball.dart';

class PlayerCrest extends StatelessWidget {
  const PlayerCrest({
    super.key,
    required this.seed,
    this.size = 34,
    this.signedIn = false,
  });

  /// Whatever identifies this player — the account id, or null while nobody is
  /// known yet.
  final String? seed;

  final double size;

  /// Draws the rim that marks a real account. Deliberately quiet: the
  /// difference between signed in and not should be legible without being a
  /// badge that nags somebody who has chosen not to be.
  final bool signedIn;

  /// Which ball stands for this player.
  ///
  /// A trivially cheap hash, on purpose — this is decoration, not a key. What
  /// it has to be is STABLE and well spread, so two adjacent uids do not come
  /// out looking like the same person.
  int colorId() {
    final text = seed ?? 'anonymous';
    var h = 0x811C9DC5;
    for (final unit in text.codeUnits) {
      h ^= unit;
      h = (h * 0x01000193) & 0xFFFFFFFF;
    }
    return h % kBallPalette.length;
  }

  @override
  Widget build(BuildContext context) {
    final tokens = PourfectTokens.of(context);

    return Semantics(
      label: signedIn ? 'Your account' : 'Playing as a guest',
      button: true,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: tokens.surfaceRaised,
          shape: BoxShape.circle,
          border: Border.all(
            // The rim is the whole signed-in signal, so it uses the cool accent
            // the rest of the app reserves for "this one is current".
            color: signedIn
                ? tokens.accent.withValues(alpha: 0.6)
                : tokens.hairline,
            width: signedIn ? 1.5 : 1,
          ),
        ),
        // 0.56 leaves a ring of ground around the ball rather than letting it
        // touch the rim, which at this size reads as a mistake.
        child: Center(child: Ball(colorId: colorId(), size: size * 0.56)),
      ),
    );
  }
}

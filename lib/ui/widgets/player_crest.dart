/// The player's mark: a small tube holding their own arrangement of balls.
///
/// **Generated, never a photo.** Three reasons, in order of weight. It works
/// for an anonymous player, which is most players for most of their first
/// session and the whole point of the anonymous-first design. It costs no
/// privacy surface — no image to fetch, cache, moderate or delete on request.
/// And it is made of the game's own objects, so the hub is furnished with balls
/// and tubes rather than with a grey silhouette borrowed from a social app.
///
/// The arrangement is DERIVED from the account id, so it is stable for a player
/// across launches and devices, and different between two players sitting next
/// to each other. An anonymous player gets one too — it simply changes if they
/// reinstall, which is the honest reflection of what an anonymous account is.
library;

import 'package:flutter/material.dart';

import '../theme/ball_palette.dart';
import '../theme/tokens.dart';
import 'ball.dart';

class PlayerCrest extends StatelessWidget {
  const PlayerCrest({
    super.key,
    required this.seed,
    this.size = 44,
    this.signedIn = false,
  });

  /// Whatever identifies this player — the account id, or null while nobody is
  /// known yet.
  final String? seed;

  final double size;

  /// Draws the rim that marks a real account. Deliberately quiet: the
  /// difference between signed in and not should be legible without being a
  /// badge that nags somebody who has chosen not to.
  final bool signedIn;

  /// Three colors from the palette, chosen by the seed.
  ///
  /// A trivially cheap hash, on purpose — this is decoration, not a key. What
  /// it must be is STABLE and well spread, so two adjacent uids do not come out
  /// looking like the same player.
  List<int> _colors() {
    final text = seed ?? 'anonymous';
    var h = 0x811C9DC5;
    for (final unit in text.codeUnits) {
      h ^= unit;
      h = (h * 0x01000193) & 0xFFFFFFFF;
    }

    final picked = <int>[];
    var cursor = h;
    while (picked.length < 3) {
      final index = cursor % kBallPalette.length;
      if (!picked.contains(index)) picked.add(index);
      cursor = (cursor ~/ 7) + 1 + picked.length;
    }
    return picked;
  }

  /// Test seam. The arrangement has to be stable for a player and different
  /// between players, and that is worth asserting without pumping a tree.
  @visibleForTesting
  List<int> debugColorsForTest() => _colors();

  @override
  Widget build(BuildContext context) {
    final tokens = PourfectTokens.of(context);
    final colors = _colors();
    final ball = size * 0.26;

    return Semantics(
      label: signedIn ? 'Your account' : 'Playing as a guest',
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: tokens.surfaceRaised,
          shape: BoxShape.circle,
          border: Border.all(
            color: signedIn ? tokens.accent.withValues(alpha: 0.55)
                            : tokens.hairline,
            width: signedIn ? 1.5 : 1,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final index in colors)
                Padding(
                  padding: EdgeInsets.symmetric(vertical: size * 0.012),
                  child: Ball(
                    colorId: index,
                    size: ball,
                    boldGlyph: false,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

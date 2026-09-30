/// The pieces of first-run teaching that draw: the guided level's caption and
/// the one-time bubble on the hub. What to say and when lives in
/// `state/onboarding.dart` and the screens; these only draw it.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/toy.dart';
import 'toy_kit.dart';

/// One line of guidance during the guided level, with a way out.
///
/// White card, not the ink toast: the ink toast is the game remarking on
/// something, this is the game teaching, and the two should not look alike
/// when a tip and a caption can follow each other on the same level.
class GuideCaption extends StatelessWidget {
  final String text;
  final VoidCallback onSkip;

  const GuideCaption({super.key, required this.text, required this.onSkip});

  @override
  Widget build(BuildContext context) => ToyBox(
    radius: Toy.rControl,
    shadow: 3,
    padding: const EdgeInsets.fromLTRB(14, 8, 6, 8),
    child: Row(
      children: [
        Expanded(
          child: AnimatedSwitcher(
            duration: Toy.calm(context)
                ? Duration.zero
                : const Duration(milliseconds: 180),
            child: Text(
              text,
              key: ValueKey(text),
              maxLines: 2,
              style: Toy.ui(15, weight: FontWeight.w700, height: 1.25),
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Always there. A tutorial you cannot leave is a toll booth.
        Semantics(
          button: true,
          label: 'Skip the tutorial',
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onSkip,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Text(
                'Skip',
                style: Toy.ui(13, weight: FontWeight.w800, color: Toy.inkMuted),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

/// A speech bubble with a tail pointing down at what it is about — the hub's
/// dock, after the first win. Tapping it dismisses it.
class TipBubble extends StatelessWidget {
  final String text;
  final VoidCallback onDismiss;

  const TipBubble({super.key, required this.text, required this.onDismiss});

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: '$text. Dismiss',
    child: GestureDetector(
      onTap: onDismiss,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            decoration: BoxDecoration(
              color: Toy.ink,
              borderRadius: BorderRadius.circular(Toy.rControl),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    text,
                    style: Toy.ui(
                      14,
                      weight: FontWeight.w700,
                      color: Colors.white,
                      height: 1.3,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                const ToyIcon(ToyGlyph.close, size: 14, color: Toy.inkDim),
              ],
            ),
          ),
          // The tail.
          Transform.rotate(
            angle: math.pi / 4,
            child: Transform.translate(
              offset: const Offset(-7, -7),
              child: Container(width: 14, height: 14, color: Toy.ink),
            ),
          ),
        ],
      ),
    ),
  );
}

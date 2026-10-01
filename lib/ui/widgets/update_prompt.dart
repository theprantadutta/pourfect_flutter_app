/// "A new Pourfect is ready": the app's own ask before Play's update screen.
///
/// Ours rather than Play's because it can say what will actually happen, in
/// the game's voice: Google Play downloads it, installs it, and opens the game
/// again, with nothing to find afterwards. That last part is the reason this
/// exists; the old flexible flow ended on a Restart bar most players missed.
library;

import 'package:flutter/material.dart';

import '../theme/toy.dart';
import 'ball.dart';
import 'toy_kit.dart';

/// Asks the player. True for **Update now**, false for **Not now**.
///
/// [mandatory] removes **Not now** and the ways around it (tapping outside,
/// back), for a build the game no longer supports.
Future<bool> showUpdatePrompt(
  BuildContext context, {
  bool mandatory = false,
}) async {
  final choice = await showToyDialog<bool>(
    context: context,
    barrierDismissible: !mandatory,
    builder: (context) => PopScope(
      canPop: !mandatory,
      child: ToyDialogCard(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const ExcludeSemantics(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Ball(colorId: 1, size: 28),
                  SizedBox(width: 8),
                  Ball(colorId: 4, size: 28),
                  SizedBox(width: 8),
                  Ball(colorId: 7, size: 28),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Text(
              mandatory ? 'Time to update' : 'A new Pourfect is ready',
              textAlign: TextAlign.center,
              style: Toy.display(26, height: 1.1),
            ),
            const SizedBox(height: 8),
            Text(
              mandatory
                  ? 'This version of Pourfect is no longer supported. Google '
                        'Play will download the update and open the game '
                        'again. Your stars are safe.'
                  : 'Google Play will download it and open the game again '
                        'when it is done. Your stars are safe.',
              textAlign: TextAlign.center,
              style: Toy.ui(
                14,
                weight: FontWeight.w500,
                color: Toy.inkMuted,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 18),
            ToyButton(
              label: 'Update now',
              height: 56,
              fontSize: 22,
              onPressed: () => Navigator.of(context).pop(true),
            ),
            if (!mandatory) ...[
              const SizedBox(height: 10),
              ToyButton.secondary(
                label: 'Not now',
                onPressed: () => Navigator.of(context).pop(false),
              ),
            ],
          ],
        ),
      ),
    ),
  );
  return choice ?? false;
}

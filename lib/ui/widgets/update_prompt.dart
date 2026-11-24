/// "A new Pourfect is ready": the app's own ask before Play's update screen.
///
/// Ours rather than Play's because it can say what will actually happen, in
/// the game's voice: Google Play downloads it, installs it, and opens the game
/// again, with nothing to find afterwards. That last part is the reason this
/// exists; the old flexible flow ended on a Restart bar most players missed.
library;

import 'package:material_ui/material_ui.dart';

import '../../l10n/l10n.dart';
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
              mandatory
                  ? context.l10n.settingsUpdateMandatoryTitle
                  : context.l10n.settingsUpdateTitle,
              textAlign: TextAlign.center,
              style: Toy.display(26, height: 1.1),
            ),
            const SizedBox(height: 8),
            Text(
              mandatory
                  ? context.l10n.settingsUpdateMandatoryBody
                  : context.l10n.settingsUpdateBody,
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
              label: context.l10n.settingsUpdateNow,
              height: 56,
              fontSize: 22,
              onPressed: () => Navigator.of(context).pop(true),
            ),
            if (!mandatory) ...[
              const SizedBox(height: 10),
              ToyButton.secondary(
                label: context.l10n.commonNotNow,
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

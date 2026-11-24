/// What the hub shows in place of the next level once a player has cleared
/// everything this phone holds.
///
/// It used to show nothing: the next-level card simply vanished after level
/// 150, leaving the stats and the daily with a hole between them, which reads
/// as the game breaking at exactly the moment a player has been most loyal.
///
/// The copy is honest about the one thing a player can do. More levels arrive
/// on their own when the phone is online, so the card says that rather than
/// promising a date, and it never implies they have to pay or sign in.
library;

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/l10n.dart';
import '../../state/campaign_worlds.dart';
import '../theme/toy.dart';
import 'ball.dart';
import 'toy_kit.dart';

class MoreLevelsCard extends ConsumerWidget {
  const MoreLevelsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final worlds = ref.watch(campaignWorldsProvider);
    final l10n = context.l10n;

    final (title, body) = switch (worlds) {
      CampaignWorldsState(updateRequired: true) => (
        l10n.hubMoreUpdateTitle,
        l10n.hubMoreUpdateBody,
      ),
      CampaignWorldsState(fetch: WorldsFetch.fetching) => (
        l10n.hubMoreDownloadingTitle,
        l10n.hubMoreDownloadingBody,
      ),
      CampaignWorldsState(fetch: WorldsFetch.failed) => (
        l10n.hubMoreAllDoneTitle,
        l10n.hubMoreOfflineBody,
      ),
      _ => (l10n.hubMoreAllDoneTitle, l10n.hubMoreOnlineBody),
    };

    final retry = worlds.fetch == WorldsFetch.failed && !worlds.updateRequired;

    return ToyBox(
      radius: Toy.rHero,
      shadow: 5,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          const ExcludeSemantics(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Ball(colorId: 0, size: 30),
                SizedBox(width: 8),
                Ball(colorId: 3, size: 30),
                SizedBox(width: 8),
                Ball(colorId: 6, size: 30),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Toy.display(26, height: 1.1),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            textAlign: TextAlign.center,
            style: Toy.ui(
              14,
              weight: FontWeight.w500,
              color: Toy.inkMuted,
              height: 1.4,
            ),
          ),
          if (retry) ...[
            const SizedBox(height: 14),
            ToyButton.secondary(
              label: l10n.hubMoreCheckAgain,
              onPressed: () => ref
                  .read(campaignWorldsProvider.notifier)
                  .maybeFetch(force: true),
            ),
          ],
        ],
      ),
    );
  }
}

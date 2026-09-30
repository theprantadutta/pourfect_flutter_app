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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/campaign_worlds.dart';
import '../theme/toy.dart';
import 'ball.dart';
import 'toy_kit.dart';

class MoreLevelsCard extends ConsumerWidget {
  const MoreLevelsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final worlds = ref.watch(campaignWorldsProvider);

    final (title, body) = switch (worlds) {
      CampaignWorldsState(updateRequired: true) => (
        'Update for more levels',
        'A new world is out, and it needs the latest Pourfect. Update from '
            'the Play Store to keep pouring.',
      ),
      CampaignWorldsState(fetch: WorldsFetch.fetching) => (
        'New levels on the way',
        'The next world is downloading. It only takes a moment.',
      ),
      CampaignWorldsState(fetch: WorldsFetch.failed) => (
        'You poured them all!',
        'Connect to the internet and more levels download in the '
            'background. Today\'s Daily Pour is waiting in the meantime.',
      ),
      _ => (
        'You poured them all!',
        'More levels download in the background whenever you\'re online. '
            'Today\'s Daily Pour is waiting in the meantime.',
      ),
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
              label: 'Check again',
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

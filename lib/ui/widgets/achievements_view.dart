/// The Badges tab on Your Stats: every achievement, earned or on its way.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/achievements.dart';
import '../theme/toy.dart';
import 'toy_kit.dart';

class AchievementsView extends ConsumerWidget {
  const AchievementsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(achievementsProvider);
    final columns = MediaQuery.sizeOf(context).width >= 700 ? 3 : 2;
    final earned = kAchievements.where((a) => state.unlocked.contains(a.id));

    return ListView(
      padding: EdgeInsets.fromLTRB(
        0,
        14,
        0,
        24 + MediaQuery.paddingOf(context).bottom,
      ),
      children: [
        Text(
          '${earned.length} of ${kAchievements.length} unlocked',
          style: Toy.ui(15, weight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, box) {
            const gap = 12.0;
            final width = (box.maxWidth - gap * (columns - 1)) / columns;
            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                for (final a in kAchievements)
                  SizedBox(
                    width: width,
                    child: _Badge(
                      achievement: a,
                      unlocked: state.unlocked.contains(a.id),
                      progress: a.progress(state.facts),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  final Achievement achievement;
  final bool unlocked;
  final int progress;

  const _Badge({
    required this.achievement,
    required this.unlocked,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final target = achievement.target;
    final shown = progress.clamp(0, target);
    return Semantics(
      label:
          '${achievement.title}: ${achievement.description} '
          '${unlocked ? 'Unlocked' : '$shown of $target'}',
      excludeSemantics: true,
      child: ToyBox(
        color: unlocked ? Toy.yellow : Toy.card,
        radius: 18,
        shadow: unlocked ? 4 : 3,
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  unlocked ? Icons.emoji_events_rounded : Icons.lock_rounded,
                  size: 22,
                  color: unlocked ? Toy.ink : Toy.inkDim,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    achievement.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Toy.ui(14.5, weight: FontWeight.w800),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              achievement.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Toy.ui(12.5, color: unlocked ? Toy.ink : Toy.inkMuted),
            ),
            const SizedBox(height: 8),
            if (unlocked)
              Text('Unlocked', style: Toy.ui(12, weight: FontWeight.w800))
            else if (target > 1) ...[
              ToyProgressBar(value: shown / target, fill: Toy.mint, height: 10),
              const SizedBox(height: 4),
              Text(
                '$shown / $target',
                style: Toy.numbers(12, color: Toy.inkMuted),
              ),
            ] else
              Text('Not yet', style: Toy.ui(12, color: Toy.inkMuted)),
          ],
        ),
      ),
    );
  }
}

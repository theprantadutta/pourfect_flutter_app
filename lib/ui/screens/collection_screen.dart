/// Ball skins and tube themes: try them on, wear one, and see how the rest are
/// unlocked (a star chest, a streak, or the Skin pack).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/ads/ad_ids.dart';
import '../../services/api/cosmetics_api.dart';
import '../../services/iap/billing_service.dart';
import '../../state/cosmetics_controller.dart';
import '../../state/providers.dart';
import '../theme/cosmetics.dart';
import '../theme/toy.dart';
import '../widgets/ball.dart';
import '../widgets/board_view.dart';
import '../widgets/settings_rows.dart';
import '../widgets/toy_kit.dart';

class CollectionScreen extends ConsumerStatefulWidget {
  final VoidCallback onClose;

  const CollectionScreen({super.key, required this.onClose});

  @override
  ConsumerState<CollectionScreen> createState() => _CollectionScreenState();
}

class _CollectionScreenState extends ConsumerState<CollectionScreen> {
  bool _buying = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(cosmeticsProvider.notifier).refresh();
    });
  }

  Future<void> _wear(CosmeticItem item) async {
    if (!item.owned) {
      showToyToast(context, 'Unlock it with: ${item.unlockHint}.');
      return;
    }
    final ok = await ref
        .read(cosmeticsProvider.notifier)
        .equip(
          ballSkin: item.isBallSkin ? item.id : null,
          tubeTheme: item.isBallSkin ? null : item.id,
        );
    if (!mounted || ok) return;
    showToyToast(context, 'Could not change it right now. Try again later.');
  }

  Future<void> _buyPack() async {
    setState(() => _buying = true);
    final outcome = await ref.read(cosmeticsProvider.notifier).buySkinPack();
    if (!mounted) return;
    setState(() => _buying = false);
    final message = switch (outcome) {
      PurchaseOutcome.purchased => 'Thank you! The pack unlocks in a moment.',
      PurchaseOutcome.alreadyOwned => 'Already yours. Restoring it now.',
      PurchaseOutcome.pending =>
        'Payment pending. The pack unlocks once it clears.',
      PurchaseOutcome.cancelled => null,
      PurchaseOutcome.unavailable =>
        'The store is not available on this device right now.',
      PurchaseOutcome.failed =>
        'The purchase did not go through. You have not been charged.',
    };
    if (message != null) showToyToast(context, message);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(cosmeticsProvider);
    final price = ref
        .watch(billingServiceProvider)
        .productFor(IapIds.skinPack)
        ?.price;
    final balls = state.items.where((i) => i.isBallSkin).toList();
    final tubes = state.items.where((i) => !i.isBallSkin).toList();
    final columns = MediaQuery.sizeOf(context).width >= 700 ? 4 : 2;

    return Scaffold(
      backgroundColor: Toy.cream,
      body: ToyScaffold(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
        safeBottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ToyHeader(title: 'Collection', onBack: widget.onClose),
            const SizedBox(height: 12),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: Toy.maxContentWidth),
                  child: ListView(
                    padding: EdgeInsets.fromLTRB(
                      0,
                      2,
                      0,
                      24 + MediaQuery.paddingOf(context).bottom,
                    ),
                    children: [
                      _Preview(
                        skin: BallSkin.byId(state.ballSkin),
                        theme: TubeTheme.byId(state.tubeTheme),
                      ),
                      const SizedBox(height: 16),
                      _SkinPackCard(
                        owned: state.skinPackOwned,
                        price: price,
                        busy: _buying,
                        onBuy: _buyPack,
                      ),
                      if (state.items.isEmpty) ...[
                        const SizedBox(height: 16),
                        Text(
                          'Connect to the internet to see your collection.',
                          textAlign: TextAlign.center,
                          style: Toy.ui(14, color: Toy.inkMuted),
                        ),
                      ] else ...[
                        const SectionHeader(label: 'Ball skins'),
                        _Grid(
                          columns: columns,
                          children: [
                            for (final item in balls)
                              _Card(
                                item: item,
                                worn: item.id == state.ballSkin,
                                onTap: () => _wear(item),
                                preview: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    for (final c in const [0, 3, 6])
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 2,
                                        ),
                                        child: Ball(
                                          colorId: c,
                                          size: 30,
                                          skin: BallSkin.byId(item.id),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        const SectionHeader(label: 'Tube themes'),
                        _Grid(
                          columns: columns,
                          children: [
                            for (final item in tubes)
                              _Card(
                                item: item,
                                worn: item.id == state.tubeTheme,
                                onTap: () => _wear(item),
                                preview: _MiniTube(
                                  theme: TubeTheme.byId(item.id),
                                  skin: BallSkin.byId(state.ballSkin),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Three tubes in what is being worn.
class _Preview extends StatelessWidget {
  final BallSkin skin;
  final TubeTheme theme;

  const _Preview({required this.skin, required this.theme});

  @override
  Widget build(BuildContext context) => ToyBox(
    radius: Toy.rHero,
    shadow: 5,
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
    child: Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _MiniTube(
              theme: theme,
              skin: skin,
              balls: const [0, 1, 0],
              big: true,
            ),
            _MiniTube(
              theme: theme,
              skin: skin,
              balls: const [2, 2, 2],
              big: true,
            ),
            _MiniTube(theme: theme, skin: skin, balls: const [1, 4], big: true),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          '${skin.label} balls · ${theme.label} tubes',
          style: Toy.ui(14, weight: FontWeight.w800),
        ),
      ],
    ),
  );
}

class _MiniTube extends StatelessWidget {
  final TubeTheme theme;
  final BallSkin skin;
  final List<int> balls;
  final bool big;

  const _MiniTube({
    required this.theme,
    required this.skin,
    this.balls = const [3, 5],
    this.big = false,
  });

  @override
  Widget build(BuildContext context) {
    final ball = big ? 30.0 : 22.0;
    final width = ball + 12;
    final height = ball * (big ? 4 : 3) + 12;
    final radius = BorderRadius.vertical(
      top: const Radius.circular(10),
      bottom: Radius.circular(width / 2),
    );
    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: theme.glass,
              borderRadius: radius,
              border: Border.all(color: Toy.ink, width: 2.5),
              boxShadow: Toy.hard(3),
            ),
          ),
          if (theme != TubeTheme.toy)
            ClipRRect(
              borderRadius: radius,
              child: CustomPaint(
                painter: TubePatternPainter(theme, scale: 0.7),
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                for (final c in balls.reversed)
                  Padding(
                    padding: const EdgeInsets.only(top: 1),
                    child: Ball(colorId: c, size: ball, skin: skin),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Grid extends StatelessWidget {
  final int columns;
  final List<Widget> children;

  const _Grid({required this.columns, required this.children});

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      const gap = 12.0;
      final width = (box.maxWidth - gap * (columns - 1)) / columns;
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: [
          for (final child in children) SizedBox(width: width, child: child),
        ],
      );
    },
  );
}

class _Card extends StatelessWidget {
  final CosmeticItem item;
  final bool worn;
  final VoidCallback onTap;
  final Widget preview;

  const _Card({
    required this.item,
    required this.worn,
    required this.onTap,
    required this.preview,
  });

  @override
  Widget build(BuildContext context) => Pressable(
    onPressed: onTap,
    semanticLabel: worn
        ? '${item.name}, worn'
        : item.owned
        ? '${item.name}, tap to wear'
        : '${item.name}, locked: ${item.unlockHint}',
    child: ToyBox(
      radius: 18,
      shadow: worn ? 5 : 3,
      color: worn ? Toy.mint : Toy.card,
      padding: const EdgeInsets.fromLTRB(10, 12, 10, 10),
      child: Column(
        children: [
          SizedBox(
            height: 80,
            child: Center(
              child: Opacity(opacity: item.owned ? 1 : 0.45, child: preview),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            item.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Toy.ui(14, weight: FontWeight.w800),
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!item.owned) ...[
                const ToyIcon(ToyGlyph.lock, size: 12),
                const SizedBox(width: 4),
              ],
              Flexible(
                child: Text(
                  worn
                      ? 'Wearing'
                      : item.owned
                      ? 'Tap to wear'
                      : item.unlockHint,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Toy.ui(12, color: worn ? Toy.ink : Toy.inkMuted),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

class _SkinPackCard extends StatelessWidget {
  final bool owned;
  final String? price;
  final bool busy;
  final VoidCallback onBuy;

  const _SkinPackCard({
    required this.owned,
    required this.price,
    required this.busy,
    required this.onBuy,
  });

  @override
  Widget build(BuildContext context) => ToyBox(
    color: Toy.lilac,
    radius: 20,
    shadow: 4,
    padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Skin pack',
                style: Toy.display(22, color: Colors.white, height: 1.1),
              ),
              const SizedBox(height: 2),
              Text(
                'Marble, Pearl and Checker balls, Wood and Lilac tubes.',
                style: Toy.ui(13, color: Colors.white, weight: FontWeight.w700),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        if (owned)
          ToyChip(
            color: Toy.card,
            child: Text('OWNED', style: Toy.ui(13, weight: FontWeight.w800)),
          )
        else
          ToyButton(
            label: busy ? '…' : (price ?? 'Soon'),
            onPressed: busy || price == null ? null : onBuy,
            color: Toy.yellow,
            textColor: Toy.ink,
            height: 44,
            radius: 14,
            shadow: 3,
            fontSize: 16,
            compact: true,
          ),
      ],
    ),
  );
}

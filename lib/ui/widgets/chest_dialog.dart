/// Star chests on the journey: the strip that counts toward the next one, the
/// painted chest, and the dialog that opens it.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/ads/ad_service.dart';
import '../../services/audio/audio_service.dart';
import '../../state/providers.dart';
import '../../services/api/chest_api.dart';
import '../../state/chest_controller.dart';
import '../../state/monetization_controller.dart';
import '../../state/progress_repository.dart';
import '../theme/cosmetics.dart';
import '../theme/toy.dart';
import 'toy_kit.dart';

/// A toy chest: yellow body, tomato lid, ink outlines. [open] from 0 (shut)
/// to 1 (lid thrown back).
class ToyChest extends StatelessWidget {
  final double size;
  final double open;

  const ToyChest({super.key, this.size = 48, this.open = 0});

  @override
  Widget build(BuildContext context) {
    final t = open.clamp(0.0, 1.0);
    // An open lid stands up above the body, so the box grows to hold it
    // rather than letting it paint over whatever sits above.
    return SizedBox(
      width: size,
      height: size * (0.9 + 0.55 * t),
      child: CustomPaint(painter: _ChestPainter(t, headroom: size * 0.55 * t)),
    );
  }
}

class _ChestPainter extends CustomPainter {
  final double open;
  final double headroom;

  const _ChestPainter(this.open, {this.headroom = 0});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.translate(0, headroom);
    final w = size.width;
    final h = size.height - headroom;
    final stroke = Paint()
      ..color = Toy.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(2, w * 0.06)
      ..strokeJoin = StrokeJoin.round;

    // Glow behind an open chest.
    if (open > 0) {
      canvas.drawCircle(
        Offset(w * 0.5, h * 0.42),
        w * 0.42 * open,
        Paint()..color = Toy.yellow.withValues(alpha: 0.35 * open),
      );
    }

    final body = RRect.fromLTRBR(
      w * 0.08,
      h * 0.42,
      w * 0.92,
      h * 0.95,
      Radius.circular(w * 0.08),
    );
    canvas.drawRRect(body, Paint()..color = Toy.yellow);
    canvas.drawRRect(body, stroke);
    // The band and the lock.
    canvas.drawLine(
      Offset(w * 0.5, h * 0.42),
      Offset(w * 0.5, h * 0.95),
      stroke,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(w * 0.5, h * 0.58),
          width: w * 0.18,
          height: h * 0.16,
        ),
        Radius.circular(w * 0.04),
      ),
      Paint()..color = Toy.card,
    );

    // The lid hinges at its back edge and swings up and back.
    canvas.save();
    canvas.translate(w * 0.08, h * 0.42);
    canvas.rotate(-open * 1.25);
    final lid = RRect.fromLTRBAndCorners(
      0,
      -h * 0.3,
      w * 0.84,
      0,
      topLeft: Radius.circular(w * 0.2),
      topRight: Radius.circular(w * 0.2),
      bottomLeft: Radius.circular(w * 0.04),
      bottomRight: Radius.circular(w * 0.04),
    );
    canvas.drawRRect(lid, Paint()..color = Toy.tomato);
    canvas.drawRRect(lid, stroke);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_ChestPainter old) =>
      old.open != open || old.headroom != headroom;
}

/// Under the World card: how far to the next chest, or OPEN when one is
/// ready. Nothing in a build without a server — chests open once per
/// account, which needs one.
class ChestStrip extends ConsumerWidget {
  const ChestStrip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chests = ref.watch(chestProvider);
    ref.watch(progressProvider);
    final controller = ref.read(chestProvider.notifier);
    if (chests.server == null) return const SizedBox.shrink();

    final stars = ref.read(progressProvider.notifier).totalStars;
    final ready = controller.ready;
    final nextAt = ((stars ~/ kStarsPerChest) + 1) * kStarsPerChest;
    final into = stars % kStarsPerChest;

    return Pressable(
      onPressed: ready == null
          ? null
          : () => showChestDialog(context, index: ready),
      semanticLabel: ready == null
          ? 'Next star chest at $nextAt stars'
          : 'Open star chest',
      child: ToyBox(
        radius: 18,
        shadow: 4,
        padding: const EdgeInsets.fromLTRB(10, 8, 12, 8),
        child: Row(
          children: [
            ToyChest(size: 40, open: ready == null ? 0 : 0.15),
            const SizedBox(width: 10),
            Expanded(
              child: ready != null
                  ? Text(
                      'A star chest is ready!',
                      style: Toy.ui(15, weight: FontWeight.w800),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Next chest at $nextAt ★',
                          style: Toy.ui(13, weight: FontWeight.w800),
                        ),
                        const SizedBox(height: 4),
                        ToyProgressBar(
                          value: into / kStarsPerChest,
                          fill: Toy.yellow,
                          height: 12,
                        ),
                      ],
                    ),
            ),
            if (ready != null) ...[
              const SizedBox(width: 8),
              ToyButton(
                label: 'OPEN',
                onPressed: () => showChestDialog(context, index: ready),
                color: Toy.yellow,
                textColor: Toy.ink,
                height: 40,
                radius: 13,
                shadow: 3,
                fontSize: 18,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

Future<void> showChestDialog(BuildContext context, {required int index}) =>
    showToyDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _ChestCard(index: index),
    );

class _ChestCard extends ConsumerStatefulWidget {
  final int index;

  const _ChestCard({required this.index});

  @override
  ConsumerState<_ChestCard> createState() => _ChestCardState();
}

class _ChestCardState extends ConsumerState<_ChestCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _lid = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );

  ChestReward? _reward;
  ChestReward? _bonus;
  ChestFailure? _failure;
  bool _opening = true;
  bool _doubling = false;

  @override
  void initState() {
    super.initState();
    // After the first frame: opening changes provider state, which is not
    // allowed while the dialog is still being built.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _open();
    });
  }

  @override
  void dispose() {
    _lid.dispose();
    super.dispose();
  }

  Future<void> _open() async {
    final (reward, failure) = await ref
        .read(chestProvider.notifier)
        .open(widget.index);
    if (!mounted) return;
    setState(() {
      _opening = false;
      _reward = reward;
      _failure = failure;
    });
    if (reward != null) {
      ref.read(audioServiceProvider).ui(UiCue.chestOpen);
      if (Toy.calm(context)) {
        _lid.value = 1;
      } else {
        await _lid.animateTo(1, curve: Curves.easeOutBack);
      }
    }
  }

  Future<void> _double() async {
    setState(() => _doubling = true);
    final outcome = await ref
        .read(monetizationProvider.notifier)
        .offerRewarded(RewardedPlacement.chestDouble, levelId: 0);
    if (!mounted) return;
    if (outcome == RewardOutcome.earned) {
      final bonus = await ref.read(chestProvider.notifier).double(widget.index);
      if (!mounted) return;
      setState(() => _bonus = bonus);
      if (bonus == null) {
        showToyToast(context, 'Could not double it this time.');
      }
    } else {
      showToyToast(
        context,
        outcome == RewardOutcome.unavailable
            ? 'No video available right now.'
            : 'Not doubled — the video was not finished.',
      );
    }
    if (mounted) setState(() => _doubling = false);
  }

  @override
  Widget build(BuildContext context) {
    final reward = _reward;
    final bonus = _bonus;

    final String title = _opening
        ? 'Opening…'
        : reward != null
        ? 'Star chest ${widget.index}'
        : switch (_failure) {
            ChestFailure.notYet => 'Almost there',
            ChestFailure.alreadyOpen => 'Already open',
            _ => 'Could not open it',
          };

    final String? note = reward != null
        ? null
        : switch (_failure) {
            ChestFailure.notYet =>
              'Your newest stars are still on their way to the server. '
                  'Try again in a moment.',
            ChestFailure.alreadyOpen =>
              'This chest was opened on another device.',
            null => null,
            _ => 'Check your connection and try again.',
          };

    final hints = (reward?.hints ?? 0) + (bonus?.hints ?? 0);
    final tubes = (reward?.extraTubes ?? 0) + (bonus?.extraTubes ?? 0);

    return ToyDialogCard(
      headerColor: Toy.yellow,
      header: Text(title, style: Toy.display(24, height: 1.05)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: AnimatedBuilder(
              animation: _lid,
              builder: (context, _) => ToyChest(size: 120, open: _lid.value),
            ),
          ),
          const SizedBox(height: 12),
          if (reward != null) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _RewardChip(label: '+$hints', caption: 'hints'),
                const SizedBox(width: 12),
                _RewardChip(
                  label: '+$tubes',
                  caption: tubes == 1 ? 'extra tube' : 'extra tubes',
                ),
              ],
            ),
            if (reward.cosmeticId case final id?) ...[
              const SizedBox(height: 10),
              ToyChip(
                color: Toy.lilac,
                child: Text(
                  'Unlocked: ${_cosmeticName(id)}',
                  textAlign: TextAlign.center,
                  style: Toy.ui(
                    14,
                    weight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              'Saved for when you need them. Hint and + Tube use these first.',
              textAlign: TextAlign.center,
              style: Toy.ui(12.5, color: Toy.inkMuted, height: 1.3),
            ),
            const SizedBox(height: 14),
            if (bonus == null)
              ToyButton(
                label: _doubling ? 'Loading video…' : 'Double it with a video',
                onPressed: _doubling ? null : _double,
                color: Toy.blue,
                height: 48,
                radius: 16,
                shadow: 4,
                fontSize: 17,
              ),
            const SizedBox(height: 10),
          ] else if (note != null) ...[
            Text(
              note,
              textAlign: TextAlign.center,
              style: Toy.ui(14, color: Toy.inkMuted, height: 1.35),
            ),
            const SizedBox(height: 14),
          ],
          if (!_opening)
            ToyButton.secondary(
              label: reward != null ? 'Collect' : 'Close',
              onPressed: _doubling ? null : () => Navigator.of(context).pop(),
            ),
        ],
      ),
    );
  }
}

/// "Glossy ball skin", from an id the app knows.
String _cosmeticName(String id) {
  for (final skin in BallSkin.values) {
    if (skin.id == id) return '${skin.label} ball skin';
  }
  for (final theme in TubeTheme.values) {
    if (theme.id == id) return '${theme.label} tubes';
  }
  return 'a new look';
}

class _RewardChip extends StatelessWidget {
  final String label;
  final String caption;

  const _RewardChip({required this.label, required this.caption});

  @override
  Widget build(BuildContext context) => ToyBox(
    color: Toy.mint,
    radius: 16,
    shadow: 3,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: Toy.display(26)),
        Text(caption, style: Toy.ui(12, weight: FontWeight.w800)),
      ],
    ),
  );
}

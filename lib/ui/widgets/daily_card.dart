/// The way in to today's challenge, with the player's rank stuck on it.
///
/// The only blue on the hub, because blue is the daily's color everywhere
/// else — the challenge screen stands on a blue ground, so the card is a
/// preview of where it goes. It sits UNDER the hero card and is shorter than
/// it: a daily competing with PLAY would put a first-time player back to
/// choosing between two things they do not yet understand.
///
/// The clock is on the card rather than behind it. A challenge that is merely
/// "open" says nothing about whether to play it now; the countdown is the
/// whole reason a daily works.
///
/// **The caller hides it entirely when there is no backend.** A build with no
/// server configured gets the game it already had rather than a card that
/// never works. Every other state — loading, played, unreachable — still
/// draws the card, so the hub does not change shape under the player.
library;

import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/toy.dart';
import 'toy_kit.dart';

class DailyCard extends StatelessWidget {
  /// Null while today's board is still being fetched.
  final bool? played;

  /// Stars already earned today, if it has been played.
  final int? stars;

  /// True when a backend exists but today's board could not be had.
  final bool unavailable;

  /// The player's campaign position, or null for every reason there is none:
  /// offline, no stars yet, or hidden from the boards by choice.
  final int? rank;

  final VoidCallback onOpenDaily;
  final VoidCallback onOpenLeaderboard;

  const DailyCard({
    super.key,
    required this.played,
    required this.stars,
    required this.unavailable,
    required this.rank,
    required this.onOpenDaily,
    required this.onOpenLeaderboard,
  });

  @override
  Widget build(BuildContext context) {
    final white = Toy.ui(13, color: Colors.white);

    // Unavailable still opens the challenge screen, which owns the retry.
    // A dead card would leave the player no way to ask again.
    final Widget detail = switch ((unavailable, played)) {
      (true, _) => Text("can't reach today's board", style: white),
      (_, true) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('solved', style: white),
          const SizedBox(width: 6),
          ToyStars(earned: stars ?? 0, size: 14, spacing: 1),
          const SizedBox(width: 6),
          Flexible(
            child: _Countdown(prefix: 'next in ', style: white),
          ),
        ],
      ),
      // Loading and not-yet-played both have a live clock: it counts to the
      // server's rollover, not to anything the fetch decides.
      _ => _Countdown(prefix: 'ends in ', style: white),
    };

    return Pressable(
      onPressed: onOpenDaily,
      semanticLabel: "Today's challenge",
      child: ToyBox(
        color: Toy.blue,
        radius: 22,
        shadow: 5,
        padding: const EdgeInsets.fromLTRB(16, 12, 14, 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // No number after it. The server has no daily index to
                  // report, and a count invented on the client would disagree
                  // with the challenge screen the moment either one changed.
                  Text(
                    'Daily Pour',
                    style: Toy.display(21, color: Colors.white, height: 1.1),
                  ),
                  const SizedBox(height: 2),
                  detail,
                ],
              ),
            ),
            const SizedBox(width: 10),
            _RankSticker(rank: rank, onPressed: onOpenLeaderboard),
          ],
        ),
      ),
    );
  }
}

/// RANK, tilted, and its own tap target: the card opens the challenge and the
/// sticker opens the boards, as the two figures did on the old hub.
class _RankSticker extends StatelessWidget {
  final int? rank;
  final VoidCallback onPressed;

  const _RankSticker({required this.rank, required this.onPressed});

  @override
  Widget build(BuildContext context) => Pressable(
    onPressed: onPressed,
    semanticLabel: rank == null ? 'Leaderboard' : 'Leaderboard, rank $rank',
    child: ToySticker(
      color: Toy.yellow,
      angle: 4,
      shadow: 0,
      radius: 14,
      padding: const EdgeInsets.fromLTRB(12, 5, 12, 6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('RANK', style: Toy.ui(11, weight: FontWeight.w800)),
          // An em dash is the honest answer to every reason there is no
          // position, and it keeps the sticker the same size either way.
          Text(rank == null ? '—' : '#$rank', style: Toy.display(22)),
        ],
      ),
    ),
  );
}

/// How long today's board has left, ticking.
///
/// Counts to the next UTC midnight, because that is when the SERVER rolls the
/// board over. A local-midnight countdown would hit zero at the wrong moment
/// for everybody outside UTC and read as broken.
///
/// Its own widget so the per-second rebuild is confined to eight characters
/// rather than dragging the hub through a frame.
class _Countdown extends StatefulWidget {
  final String prefix;
  final TextStyle style;

  const _Countdown({required this.prefix, required this.style});

  @override
  State<_Countdown> createState() => _CountdownState();
}

class _CountdownState extends State<_Countdown> {
  Timer? _tick;
  late Duration _left = _remaining();

  static Duration _remaining() {
    final now = DateTime.now().toUtc();
    final midnight = DateTime.utc(now.year, now.month, now.day + 1);
    return midnight.difference(now);
  }

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _left = _remaining());
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String two(int v) => v.toString().padLeft(2, '0');
    final clock =
        '${two(_left.inHours)}:${two(_left.inMinutes % 60)}'
        ':${two(_left.inSeconds % 60)}';

    // Its own layer, so a tick once a second repaints eight characters and
    // not the hub around them.
    return RepaintBoundary(
      child: Text.rich(
        TextSpan(
          text: widget.prefix,
          children: [
            TextSpan(
              text: clock,
              style: Toy.numbers(13, color: widget.style.color ?? Toy.ink),
            ),
          ],
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: widget.style,
      ),
    );
  }
}

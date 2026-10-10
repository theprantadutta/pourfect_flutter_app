/// The Daily Pour streak, opened from the daily screen's week strip or the
/// hub's flame: how long it is, the freezes protecting it, and a calendar.
///
/// Every number is the server's (see `streakProvider`). The only thing done
/// here is the video for a freeze, and even then the freeze is the server's
/// to add.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/ads/ad_service.dart';
import '../../services/api/daily_api.dart';
import '../../state/streak_controller.dart';
import '../theme/toy.dart';
import 'streak_glyphs.dart';
import 'toy_kit.dart';

/// Shows the streak. [watchVideo] runs a rewarded video for a freeze and says
/// how it went; the caller owns it because the caller knows what to pause.
Future<void> showStreakDialog(
  BuildContext context, {
  required Future<RewardOutcome> Function() watchVideo,
}) {
  unawaited(
    ProviderScope.containerOf(context).read(streakProvider.notifier).refresh(),
  );
  return showToyDialog<void>(
    context: context,
    builder: (_) => _StreakCard(watchVideo: watchVideo),
  );
}

class _StreakCard extends ConsumerStatefulWidget {
  final Future<RewardOutcome> Function() watchVideo;

  const _StreakCard({required this.watchVideo});

  @override
  ConsumerState<_StreakCard> createState() => _StreakCardState();
}

class _StreakCardState extends ConsumerState<_StreakCard> {
  /// The first day of the month on show. Null until the server's "today" is
  /// known, which is what decides the current month (UTC, like the daily).
  DateTime? _month;

  /// Months fetched for the calendar, by their first day.
  final Map<DateTime, StreakInfo> _months = {};

  bool _watching = false;

  Future<void> _show(DateTime month) async {
    setState(() => _month = month);
    if (_months.containsKey(month)) return;
    final info = await ref.read(streakProvider.notifier).month(month);
    if (!mounted || info == null) return;
    setState(() => _months[month] = info);
  }

  Future<void> _earnFreeze() async {
    if (_watching) return;
    setState(() => _watching = true);
    try {
      final outcome = await widget.watchVideo();
      if (!mounted) return;
      if (outcome != RewardOutcome.earned) {
        showToyToast(context, switch (outcome) {
          RewardOutcome.dismissed => 'No freeze — the video was not finished.',
          RewardOutcome.unavailable => 'No video available right now.',
          _ => 'Something went wrong. Try again later.',
        });
        return;
      }
      final added = await ref.read(streakProvider.notifier).earnFreeze();
      if (!mounted) return;
      showToyToast(
        context,
        added
            ? 'Freeze added. A missed day is covered.'
            : 'No room for another freeze today.',
      );
    } finally {
      if (mounted) setState(() => _watching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final info = ref.watch(streakProvider);

    if (info != null && _month == null) {
      final first = DateTime.utc(info.today.year, info.today.month);
      // Scheduled, not run inline: it calls setState.
      scheduleMicrotask(() {
        if (mounted && _month == null) _show(first);
      });
    }

    return ToyDialogCard(
      headerColor: Toy.tomato,
      header: _Header(info: info, onClose: () => Navigator.of(context).pop()),
      child: info == null
          ? const SizedBox(
              height: 160,
              child: Center(child: CircularProgressIndicator(color: Toy.ink)),
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Freezes(info: info),
                const SizedBox(height: 12),
                if (info.canEarnFreeze)
                  ToyButton(
                    label: _watching
                        ? 'Loading video…'
                        : 'Watch a video for a freeze',
                    color: Toy.blue,
                    height: 50,
                    radius: 16,
                    shadow: 4,
                    fontSize: 17,
                    onPressed: _watching ? null : _earnFreeze,
                  )
                else
                  Text(
                    info.freezes >= info.maxFreezes
                        ? 'Freezes full. Each one covers a day you miss.'
                        : 'One freeze from a video a day. Back tomorrow.',
                    textAlign: TextAlign.center,
                    style: Toy.ui(13, color: Toy.inkMuted),
                  ),
                const SizedBox(height: 16),
                if (_month case final month?)
                  _Calendar(
                    month: month,
                    info: _merged(month, info),
                    today: info.today,
                    canGoForward: month.isBefore(
                      DateTime.utc(info.today.year, info.today.month),
                    ),
                    onPrevious: () =>
                        _show(DateTime.utc(month.year, month.month - 1)),
                    onNext: () =>
                        _show(DateTime.utc(month.year, month.month + 1)),
                  ),
              ],
            ),
    );
  }

  /// The month's own fetch, with the live streak's days laid over it so a
  /// result submitted while the dialog is open shows at once.
  ({Set<DateTime> played, Set<DateTime> frozen}) _merged(
    DateTime month,
    StreakInfo live,
  ) {
    final fetched = _months[month];
    return (
      played: {...?fetched?.played, ...live.played},
      frozen: {...?fetched?.frozen, ...live.frozen},
    );
  }
}

class _Header extends StatelessWidget {
  final StreakInfo? info;
  final VoidCallback onClose;

  const _Header({required this.info, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final current = info?.current ?? 0;
    return Row(
      children: [
        StreakFlame(size: 40, lit: current > 0),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                info == null
                    ? 'Your streak'
                    : current == 0
                    ? 'No streak yet'
                    : current == 1
                    ? '1-day streak'
                    : '$current-day streak',
                style: Toy.display(24, color: Colors.white, height: 1.05),
              ),
              if (info != null)
                Text(
                  current == 0
                      ? 'Play today\'s Daily Pour to start one.'
                      : 'Best: ${info!.best} days',
                  style: Toy.ui(
                    13,
                    color: Colors.white,
                    weight: FontWeight.w700,
                  ),
                ),
            ],
          ),
        ),
        Pressable(
          onPressed: onClose,
          semanticLabel: 'Close',
          child: const Padding(
            padding: EdgeInsets.all(6),
            child: ToyIcon(ToyGlyph.close, size: 18, color: Colors.white),
          ),
        ),
      ],
    );
  }
}

class _Freezes extends StatelessWidget {
  final StreakInfo info;

  const _Freezes({required this.info});

  @override
  Widget build(BuildContext context) {
    final next = info.nextWeeklyFreezeOn;
    final days = next.difference(info.today).inDays;
    final when = days <= 1 ? 'tomorrow' : 'in $days days';

    return Semantics(
      label: '${info.freezes} of ${info.maxFreezes} streak freezes',
      excludeSemantics: true,
      child: Row(
        children: [
          for (var i = 0; i < info.maxFreezes; i++) ...[
            ToyBox(
              width: 38,
              height: 38,
              radius: 11,
              shadow: 3,
              color: i < info.freezes ? Toy.blue : Toy.track,
              child: Center(
                child: StreakSnowflake(
                  size: 20,
                  color: i < info.freezes ? Colors.white : Toy.inkDim,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Streak freezes',
                  style: Toy.ui(15, weight: FontWeight.w800),
                ),
                Text(
                  info.freezes >= info.maxFreezes
                      ? 'Each covers a missed day.'
                      : 'A free one every Monday, $when.',
                  style: Toy.ui(12, color: Toy.inkMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Calendar extends StatelessWidget {
  final DateTime month;
  final ({Set<DateTime> played, Set<DateTime> frozen}) info;
  final DateTime today;
  final bool canGoForward;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  const _Calendar({
    required this.month,
    required this.info,
    required this.today,
    required this.canGoForward,
    required this.onPrevious,
    required this.onNext,
  });

  static const _months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  @override
  Widget build(BuildContext context) {
    final daysInMonth = DateTime.utc(month.year, month.month + 1, 0).day;
    final lead = month.weekday - 1; // Monday first.

    Widget arrow(bool back, VoidCallback? onPressed) => Pressable(
      onPressed: onPressed,
      semanticLabel: back ? 'Previous month' : 'Next month',
      child: Opacity(
        opacity: onPressed == null ? 0.25 : 1,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Transform.flip(
            flipX: !back,
            child: const ToyIcon(ToyGlyph.back, size: 16),
          ),
        ),
      ),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            arrow(true, onPrevious),
            Expanded(
              child: Text(
                '${_months[month.month - 1]} ${month.year}',
                textAlign: TextAlign.center,
                style: Toy.ui(15, weight: FontWeight.w800),
              ),
            ),
            arrow(false, canGoForward ? onNext : null),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            for (final l in const ['M', 'T', 'W', 'T', 'F', 'S', 'S'])
              Expanded(
                child: Text(
                  l,
                  textAlign: TextAlign.center,
                  style: Toy.ui(
                    11,
                    weight: FontWeight.w800,
                    color: Toy.inkMuted,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        for (var week = 0; week * 7 < lead + daysInMonth; week++)
          Row(
            children: [
              for (var col = 0; col < 7; col++)
                Expanded(child: _cell(week * 7 + col - lead + 1, daysInMonth)),
            ],
          ),
        const SizedBox(height: 8),
        const _Legend(),
      ],
    );
  }

  Widget _cell(int day, int daysInMonth) {
    if (day < 1 || day > daysInMonth) return const SizedBox(height: 36);
    final date = DateTime.utc(month.year, month.month, day);
    final played = info.played.contains(date);
    final frozen = info.frozen.contains(date);
    final isToday = date == today;
    final future = date.isAfter(today);

    final Color fill;
    final Widget content;
    final String label;
    if (played) {
      fill = Toy.mint;
      content = const ToyIcon(ToyGlyph.check, size: 13);
      label = 'played';
    } else if (frozen) {
      fill = Toy.blue;
      content = const StreakSnowflake(size: 14, color: Colors.white);
      label = 'frozen';
    } else {
      fill = isToday ? Toy.yellow : Toy.card;
      content = Text(
        '$day',
        style: Toy.numbers(12, color: future ? Toy.inkDim : Toy.ink),
      );
      label = isToday
          ? 'today, not played yet'
          : (future ? 'to come' : 'not played');
    }

    return Semantics(
      label: '${_months[month.month - 1]} $day, $label',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.all(2.5),
        child: AspectRatio(
          aspectRatio: 1,
          child: Opacity(
            opacity: future ? 0.45 : 1,
            child: Container(
              decoration: BoxDecoration(
                color: fill,
                borderRadius: BorderRadius.circular(9),
                border: Border.all(
                  color: Toy.ink,
                  width: played || frozen || isToday ? 2 : 1,
                ),
              ),
              alignment: Alignment.center,
              child: content,
            ),
          ),
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    Widget item(Color color, Widget icon, String label) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(5),
            border: Border.all(color: Toy.ink, width: 1.5),
          ),
          alignment: Alignment.center,
          child: icon,
        ),
        const SizedBox(width: 5),
        Text(label, style: Toy.ui(12, color: Toy.inkMuted)),
      ],
    );

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 14,
      runSpacing: 6,
      children: [
        item(Toy.mint, const ToyIcon(ToyGlyph.check, size: 9), 'Played'),
        item(
          Toy.blue,
          const StreakSnowflake(size: 11, color: Colors.white),
          'Frozen',
        ),
        item(Toy.yellow, const SizedBox.shrink(), 'Today'),
      ],
    );
  }
}

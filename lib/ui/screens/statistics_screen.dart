/// Everything the game knows about how this player plays.
///
/// Two tabs. **Overview** answers the questions somebody actually asks, in
/// order: how far have I got, how am I doing against the clock, how often do
/// I play. **Levels** is for the completionist: every world, then every single
/// level they have solved.
///
/// Two rules run through the whole screen.
///
///  * **A missing number is a dash, never a zero.** Every level cleared before
///    the clock shipped has no time on record, and printing 0:00 there would
///    be an invented fact about somebody's own play.
///  * **Nothing here scolds.** Over par is stated plainly, in ink on a plain
///    chip; only good news gets a color. A statistics screen that tells a
///    player off for being slow at a relaxing puzzle is a screen they visit
///    once.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../engine/level_set.dart';
import '../../state/level_repository.dart';
import '../../state/play_history.dart';
import '../../state/progress_repository.dart';
import '../../state/providers.dart';
import '../format.dart';
import '../theme/ball_palette.dart';
import '../theme/toy.dart';
import '../widgets/toy_kit.dart';

class StatisticsScreen extends ConsumerStatefulWidget {
  final VoidCallback onBack;

  const StatisticsScreen({super.key, required this.onBack});

  @override
  ConsumerState<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends ConsumerState<StatisticsScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final levels = ref.watch(campaignProvider).asData?.value;
    final progress = ref.watch(progressProvider);
    final progressController = ref.read(progressProvider.notifier);
    ref.watch(playHistoryProvider);
    final history = ref.read(playHistoryProvider.notifier);

    return ToyScaffold(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ToyHeader(title: 'Your Stats', onBack: widget.onBack),
          if (progress.isEmpty)
            Expanded(child: _Empty(onBack: widget.onBack))
          else ...[
            const SizedBox(height: 12),
            // Ink, not tomato: here the tabs only switch a view.
            ToyTabs(
              labels: const ['Overview', 'Levels'],
              index: _tab,
              onChanged: (i) => setState(() => _tab = i),
              selectedColor: Toy.ink,
              height: 34,
              fontSize: 14,
            ),
            Expanded(
              child: _tab == 0
                  ? _Overview(
                      key: const PageStorageKey('stats-overview'),
                      progress: progress,
                      controller: progressController,
                      history: history,
                      levels: levels,
                    )
                  : _Levels(
                      key: const PageStorageKey('stats-levels'),
                      progress: progress,
                      levels: levels,
                    ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Says a par ratio the way a person would, not as a bare decimal.
String _paceLabel(double ratio) {
  final percent = ((ratio - 1) * 100).round();
  if (percent == 0) return 'on par';
  return percent < 0 ? '${-percent}% under' : '$percent% over';
}

/// Good news on the Levels tab: the moss ball's green.
final _underParGreen = Color(0xFF000000 | kBallPalette[5].rgb);

/// A day with no play in the 30-day chart: a stub, not a gap.
const _emptyDay = Color(0xFFE8DCC6);

// ---- empty ------------------------------------------------------------------

/// What a player with no clears sees. An empty screen is an invitation, not a
/// report that there is nothing to report.
class _Empty extends StatelessWidget {
  final VoidCallback onBack;

  const _Empty({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 28),
        child: ToyBox(
          padding: const EdgeInsets.fromLTRB(18, 22, 18, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (final id in const [0, 3, 2]) ...[
                    ToyBall.id(id, size: 30),
                    if (id != 2) const SizedBox(width: 6),
                  ],
                ],
              ),
              const SizedBox(height: 14),
              Text(
                'Nothing to show yet',
                textAlign: TextAlign.center,
                style: Toy.display(24, height: 1.1),
              ),
              const SizedBox(height: 8),
              Text(
                'Solve a level and this fills up: your times against par, '
                'your best solves, and the days you played.',
                textAlign: TextAlign.center,
                style: Toy.ui(
                  14,
                  weight: FontWeight.w500,
                  color: Toy.inkMuted,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 18),
              ToyButton(
                label: 'Back to levels',
                onPressed: onBack,
                height: 52,
                radius: 16,
                shadow: 4,
                fontSize: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---- overview ---------------------------------------------------------------

class _Overview extends StatelessWidget {
  final Map<int, LevelProgress> progress;
  final ProgressController controller;
  final PlayHistoryController history;
  final LevelSet? levels;

  const _Overview({
    super.key,
    required this.progress,
    required this.controller,
    required this.history,
    required this.levels,
  });

  @override
  Widget build(BuildContext context) {
    final moves = progress.values.fold(0, (sum, p) => sum + p.bestMoves);

    return ListView(
      // Top room for the tilted blocks' corners, bottom room for the last
      // card's hard shadow: the viewport clips both.
      padding: const EdgeInsets.only(top: 14, bottom: 28),
      children: [
        _Trophies(
          solved: progress.length,
          stars: controller.totalStars,
          points: controller.totalPoints,
          seconds: history.totalSeconds,
        ),
        const SizedBox(height: 12),
        _FactStrip(
          furthest: controller.furthestUnlocked,
          bestSolveMoves: moves,
        ),
        const SizedBox(height: 14),
        _AgainstTheClock(
          progress: progress,
          controller: controller,
          levels: levels,
        ),
        const SizedBox(height: 14),
        _Activity(history: history),
      ],
    );
  }
}

/// A count that runs up from zero the first time it is shown. Calm mode shows
/// the final figure straight away.
class _RunUp extends StatelessWidget {
  final int value;
  final String Function(int) format;
  final TextStyle style;

  const _RunUp({required this.value, required this.format, required this.style});

  @override
  Widget build(BuildContext context) {
    final calm = Toy.calm(context);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.toDouble()),
      duration: calm ? Duration.zero : const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (context, v, _) => Text(
        format(v.round()),
        maxLines: 1,
        semanticsLabel: format(value),
        style: style,
      ),
    );
  }
}

/// The four headline figures, as colored blocks. Two of them tilt — the
/// screen's whole tilt budget.
class _Trophies extends StatelessWidget {
  final int solved;
  final int stars;
  final int points;
  final int seconds;

  const _Trophies({
    required this.solved,
    required this.stars,
    required this.points,
    required this.seconds,
  });

  @override
  Widget build(BuildContext context) {
    final number = Toy.display(32, height: 1.05);

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _Block(
                color: Toy.yellow,
                label: 'levels solved',
                value: _RunUp(value: solved, format: formatCount, style: number),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _Block(
                color: Toy.pink,
                angle: 1.5,
                label: 'stars',
                value: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _RunUp(value: stars, format: formatCount, style: number),
                    const SizedBox(width: 6),
                    const ToyStar(size: 26, fill: Toy.ink, outlined: false),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _Block(
                color: Toy.mint,
                angle: -1,
                label: 'points',
                value: _RunUp(value: points, format: formatCount, style: number),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _Block(
                color: Toy.lilac,
                label: 'played',
                value: _RunUp(value: seconds, format: formatSpan, style: number),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Block extends StatelessWidget {
  final Color color;
  final String label;
  final Widget value;

  /// Degrees.
  final double angle;

  const _Block({
    required this.color,
    required this.label,
    required this.value,
    this.angle = 0,
  });

  @override
  Widget build(BuildContext context) {
    final block = ToyBox(
      color: color,
      radius: 18,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: value,
          ),
          Text(label, style: Toy.ui(12, weight: FontWeight.w700)),
        ],
      ),
    );
    return angle == 0
        ? block
        : Transform.rotate(angle: angle * math.pi / 180, child: block);
  }
}

/// The two lifetime figures the blocks have no room for.
class _FactStrip extends StatelessWidget {
  final int furthest;
  final int bestSolveMoves;

  const _FactStrip({required this.furthest, required this.bestSolveMoves});

  @override
  Widget build(BuildContext context) {
    Widget fact(String value, String label) => Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(value, style: Toy.numbers(18)),
            ),
            const SizedBox(height: 2),
            Text(label, style: Toy.ui(12, color: Toy.inkMuted)),
          ],
        ),
      ),
    );

    return ToyBox(
      radius: 18,
      shadow: 3,
      child: IntrinsicHeight(
        child: Row(
          children: [
            fact('Level $furthest', 'now on'),
            const VerticalDivider(
              width: 1.5,
              thickness: 1.5,
              color: Toy.divider,
              indent: 10,
              endIndent: 10,
            ),
            fact(formatCount(bestSolveMoves), 'moves in best solves'),
          ],
        ),
      ),
    );
  }
}

// ---- against the clock ------------------------------------------------------

class _AgainstTheClock extends StatelessWidget {
  final Map<int, LevelProgress> progress;
  final ProgressController controller;
  final LevelSet? levels;

  const _AgainstTheClock({
    required this.progress,
    required this.controller,
    required this.levels,
  });

  @override
  Widget build(BuildContext context) {
    final set = levels;
    final timed = progress.values.where((p) => p.hasTime).length;
    const label = Text(
      'AGAINST THE CLOCK',
      style: TextStyle(
        fontFamily: Toy.uiFamily,
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.5,
        color: Toy.inkMuted,
      ),
    );

    if (set == null || timed == 0) {
      return ToyBox(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            label,
            const SizedBox(height: 8),
            Text(
              'No times on record yet. Levels you cleared before the clock '
              'arrived have no time — replay one and it starts counting.',
              style: Toy.ui(
                13,
                weight: FontWeight.w500,
                color: Toy.inkMuted,
                height: 1.35,
              ),
            ),
          ],
        ),
      );
    }

    final ratio = controller.averageParRatio(set);
    final under = controller.levelsUnderPar(set);
    final fastest = controller.fastestClear;
    final slowest = controller.slowestClear;

    return ToyBox(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _Donut(under: under, of: timed),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    label,
                    const SizedBox(height: 7),
                    _ClockLine(
                      'Fastest',
                      fastest == null
                          ? '—'
                          : '${formatClock(fastest.bestTimeSeconds)} · '
                                'L${fastest.levelId}',
                    ),
                    const SizedBox(height: 7),
                    _ClockLine(
                      'Longest',
                      slowest == null
                          ? '—'
                          : '${formatClock(slowest.bestTimeSeconds)} · '
                                'L${slowest.levelId}',
                    ),
                    const SizedBox(height: 7),
                    _ClockLine(
                      'Avg pace',
                      ratio == null ? '—' : _paceLabel(ratio),
                      good: ratio != null && ratio <= 1,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (timed < progress.length) ...[
            const SizedBox(height: 12),
            Text(
              '${progress.length - timed} of your solved levels were cleared '
              'before the clock and have no time recorded.',
              style: Toy.ui(12, weight: FontWeight.w500, color: Toy.inkMuted),
            ),
          ],
        ],
      ),
    );
  }
}

class _ClockLine extends StatelessWidget {
  final String label;
  final String value;

  /// Good news: at or under par. Gets the mint chip; anything else is plain
  /// ink — see the library comment.
  final bool good;

  const _ClockLine(this.label, this.value, {this.good = false});

  @override
  Widget build(BuildContext context) {
    final valueText = Text(
      value,
      maxLines: 1,
      style: Toy.numbers(13),
    );
    return Row(
      children: [
        Text(label, style: Toy.ui(13)),
        const SizedBox(width: 8),
        Expanded(
          child: Align(
            alignment: Alignment.centerRight,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: good
                  ? ToyChip(
                      color: Toy.mint,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 1,
                      ),
                      child: valueText,
                    )
                  : valueText,
            ),
          ),
        ),
      ],
    );
  }
}

/// Levels under par out of levels timed, as a ring.
class _Donut extends StatelessWidget {
  final int under;
  final int of;

  const _Donut({required this.under, required this.of});

  @override
  Widget build(BuildContext context) {
    final fraction = of == 0 ? 0.0 : under / of;
    final calm = Toy.calm(context);

    return Semantics(
      label: '$under of $of timed levels under par',
      excludeSemantics: true,
      child: SizedBox.square(
        dimension: 96,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: fraction),
          duration: calm ? Duration.zero : const Duration(milliseconds: 900),
          curve: Curves.easeOutCubic,
          builder: (context, t, child) => CustomPaint(
            painter: _DonutPainter(fraction: t),
            child: child,
          ),
          child: Center(
            child: SizedBox(
              width: 46,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text('$under/$of', style: Toy.numbers(18)),
                  ),
                  const SizedBox(height: 2),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'UNDER PAR',
                      style: Toy.ui(
                        9,
                        weight: FontWeight.w800,
                        color: Toy.inkMuted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  final double fraction;

  const _DonutPainter({required this.fraction});

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final outer = size.width / 2;
    const inner = 31.0;
    final ringMid = (outer + inner) / 2;
    final ringWidth = outer - inner;
    final rect = Rect.fromCircle(center: c, radius: ringMid);

    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = ringWidth;
    canvas
      ..drawCircle(c, ringMid, ring..color = Toy.track)
      ..drawArc(
        rect,
        -math.pi / 2,
        2 * math.pi * fraction.clamp(0.0, 1.0),
        false,
        ring..color = Toy.mint,
      )
      ..drawCircle(c, inner, Paint()..color = Toy.card);

    final stroke = Paint()
      ..color = Toy.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = Toy.stroke;
    canvas
      ..drawCircle(c, outer - Toy.stroke / 2, stroke)
      ..drawCircle(c, inner, stroke);
  }

  @override
  bool shouldRepaint(_DonutPainter old) => old.fraction != fraction;
}

// ---- activity ---------------------------------------------------------------

class _Activity extends StatelessWidget {
  final PlayHistoryController history;

  const _Activity({required this.history});

  @override
  Widget build(BuildContext context) {
    final streak = history.currentStreak();
    final days = history.recentDays(30);
    final footer = Toy.ui(12, color: Toy.inkMuted);

    Widget foot(String text, Alignment alignment) => Flexible(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: alignment,
        child: Text(text, style: footer),
      ),
    );

    return ToyBox(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'LAST 30 DAYS',
                  style: TextStyle(
                    fontFamily: Toy.uiFamily,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                    color: Toy.inkMuted,
                  ),
                ),
              ),
              if (streak > 0)
                ToyChip(
                  color: Toy.yellow,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  child: Text(
                    '$streak day streak',
                    style: Toy.numbers(12),
                  ),
                )
              else
                ToyChip(
                  color: Toy.card,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  child: Text(
                    'no streak',
                    style: Toy.ui(12, weight: FontWeight.w800),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          _ActivityChart(days: days),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              foot(
                '${plural(history.daysPlayed, 'day')} played',
                Alignment.centerLeft,
              ),
              const SizedBox(width: 8),
              foot(
                '${plural(history.totalSolves, 'level')} finished',
                Alignment.center,
              ),
              const SizedBox(width: 8),
              foot(
                'best ${plural(history.longestStreak, 'day')}',
                Alignment.centerRight,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Thirty bars, one per day, heights scaled to the busiest of them.
///
/// A day with no play is a short stub rather than a gap, so the shape of a
/// habit — three on, one off, three on — stays readable. Today is tomato;
/// every other played day is mint. Tapping a bar says what it stands for.
class _ActivityChart extends StatelessWidget {
  final List<DayRecord> days;

  const _ActivityChart({required this.days});

  static const _height = 70.0;
  static const _stub = 3.0;

  /// Played days never draw shorter than this, so a one-level day is not
  /// mistaken for an empty one beside a twelve-level peak.
  static const _minPlayed = 8.0;

  @override
  Widget build(BuildContext context) {
    final peak = days.fold(0, (max, d) => d.solved > max ? d.solved : max);

    return Container(
      height: _height,
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Toy.ink, width: Toy.stroke)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < days.length; i++)
            Expanded(
              child: _Bar(
                day: days[i],
                isToday: i == days.length - 1,
                height: days[i].solved == 0 || peak == 0
                    ? _stub
                    : math.max(
                        _minPlayed,
                        days[i].solved / peak * (_height - Toy.stroke - 2),
                      ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  final DayRecord day;
  final bool isToday;
  final double height;

  const _Bar({required this.day, required this.isToday, required this.height});

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  String get _dayLabel {
    if (isToday) return 'Today';
    final parts = day.date.split('-');
    final m = parts.length == 3 ? int.tryParse(parts[1]) : null;
    final d = parts.length == 3 ? int.tryParse(parts[2]) : null;
    if (m == null || d == null || m < 1 || m > 12) return day.date;
    return '${_months[m - 1]} $d';
  }

  @override
  Widget build(BuildContext context) {
    final played = day.solved > 0;
    final message = played
        ? '$_dayLabel · ${plural(day.solved, 'level')}'
        : '$_dayLabel · no play';

    return Tooltip(
      message: message,
      triggerMode: TooltipTriggerMode.tap,
      preferBelow: false,
      decoration: BoxDecoration(
        color: Toy.ink,
        borderRadius: BorderRadius.circular(Toy.rChip),
      ),
      textStyle: Toy.ui(12, weight: FontWeight.w700, color: Colors.white),
      // The hit target is the whole column, not the thin bar.
      child: Container(
        height: 70,
        color: Colors.transparent,
        alignment: Alignment.bottomCenter,
        padding: const EdgeInsets.symmetric(horizontal: 1.5),
        child: Container(
          height: height,
          decoration: BoxDecoration(
            color: !played
                ? _emptyDay
                : isToday
                ? Toy.tomato
                : Toy.mint,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
          ),
        ),
      ),
    );
  }
}

// ---- levels tab -------------------------------------------------------------

class _Levels extends StatelessWidget {
  final Map<int, LevelProgress> progress;
  final LevelSet? levels;

  const _Levels({super.key, required this.progress, required this.levels});

  @override
  Widget build(BuildContext context) {
    final set = levels;
    final bands = campaignBands();

    return CustomScrollView(
      slivers: [
        const SliverToBoxAdapter(child: SizedBox(height: 14)),
        SliverList.separated(
          itemCount: bands.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, i) =>
              _WorldRow(band: bands[i], progress: progress, levels: set),
        ),
        if (set != null) ...[
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          _PerLevel(progress: progress, levels: set),
        ],
        const SliverToBoxAdapter(child: SizedBox(height: 28)),
      ],
    );
  }
}

/// One world's ball: the same color and glyph for the same band everywhere
/// on this screen.
const _worldBalls = [3, 1, 9, 7];

class _WorldRow extends StatelessWidget {
  final BandInfo band;
  final Map<int, LevelProgress> progress;
  final LevelSet? levels;

  const _WorldRow({
    required this.band,
    required this.progress,
    required this.levels,
  });

  @override
  Widget build(BuildContext context) {
    var cleared = 0;
    var timed = 0;
    var ratioSum = 0.0;
    var points = 0;

    for (var id = band.firstLevel; id <= band.lastLevel; id++) {
      final p = progress[id];
      if (p == null) continue;
      cleared++;
      points += p.bestPoints;

      final level = levels?.byId(id);
      if (!p.hasTime || level == null || level.level.parSeconds <= 0) continue;
      timed++;
      ratioSum += p.bestTimeSeconds / level.level.parSeconds;
    }

    final pace = timed == 0 ? null : ratioSum / timed;
    final ballId = _worldBalls[band.index % _worldBalls.length];
    final ballColor = Color(0xFF000000 | kBallPalette[ballId].rgb);
    final untouched = cleared == 0;

    final (chipText, chipColor) = untouched
        ? ('ahead', Toy.card)
        : pace == null
        ? ('no times', Toy.card)
        : pace <= 1
        ? (_paceLabel(pace), _underParGreen)
        : (_paceLabel(pace), Toy.cream);

    final row = ToyBox(
      radius: 16,
      shadow: 3,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Row(
        children: [
          ToyBall.id(ballId, size: 28),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Expanded(
                      child: Text(
                        band.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Toy.ui(14, weight: FontWeight.w800),
                      ),
                    ),
                    Text(
                      '$cleared / ${band.length}',
                      style: Toy.numbers(
                        12,
                        color: Toy.inkMuted,
                        weight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: Toy.track,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Toy.ink, width: 1.5),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: cleared / band.length,
                      heightFactor: 1,
                      child: ColoredBox(color: ballColor),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              ToyChip(
                color: chipColor,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                child: Text(
                  chipText,
                  style: Toy.numbers(11, weight: FontWeight.w800),
                ),
              ),
              if (points > 0) ...[
                const SizedBox(height: 3),
                Text(
                  '${formatCount(points)} pts',
                  style: Toy.numbers(
                    11,
                    color: Toy.inkMuted,
                    weight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );

    return Semantics(
      label:
          '${band.name}: $cleared of ${band.length} solved'
          '${pace == null ? '' : ', pace ${_paceLabel(pace)}'}'
          '${points > 0 ? ', ${formatCount(points)} points' : ''}',
      excludeSemantics: true,
      child: untouched ? Opacity(opacity: 0.55, child: row) : row,
    );
  }
}

// ---- per level --------------------------------------------------------------

/// Column widths shared by the ink header and every row, so they line up.
const _colLevel = 34.0;
const _colStars = 56.0;
const _colTime = 46.0;
const _colPoints = 48.0;
const _colGap = 6.0;

/// Every solved level, newest id last, in one card with an ink header.
///
/// A sliver list rather than a Column: 150 rows built eagerly inside a scroll
/// view is 150 rows of layout the player will never look at. The card itself
/// is a [DecoratedSliver] so the stroke and hard shadow wrap the lazy list.
class _PerLevel extends StatelessWidget {
  final Map<int, LevelProgress> progress;
  final LevelSet levels;

  const _PerLevel({required this.progress, required this.levels});

  @override
  Widget build(BuildContext context) {
    final ids = progress.keys.toList()..sort();
    const inset = Toy.stroke;

    return DecoratedSliver(
      decoration: Toy.box(),
      sliver: SliverPadding(
        padding: const EdgeInsets.all(inset),
        sliver: SliverMainAxisGroup(
          slivers: [
            const SliverToBoxAdapter(child: _TableHeader()),
            SliverList.builder(
              itemCount: ids.length,
              itemBuilder: (context, index) {
                final id = ids[index];
                return _LevelRow(
                  progress: progress[id]!,
                  level: levels.byId(id),
                  divider: index > 0,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _TableHeader extends StatelessWidget {
  const _TableHeader();

  @override
  Widget build(BuildContext context) {
    final style = Toy.ui(
      10,
      weight: FontWeight.w800,
      color: Toy.cream,
      letterSpacing: 1,
    );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: const BoxDecoration(
        color: Toy.ink,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(Toy.rCard - Toy.stroke),
        ),
      ),
      child: Row(
        children: [
          SizedBox(width: _colLevel, child: Text('LVL', style: style)),
          const SizedBox(width: _colGap),
          SizedBox(width: _colStars, child: Text('STARS', style: style)),
          const SizedBox(width: _colGap),
          Expanded(child: Text('MOVES', style: style)),
          const SizedBox(width: _colGap),
          SizedBox(width: _colTime, child: Text('TIME', style: style)),
          const SizedBox(width: _colGap),
          SizedBox(
            width: _colPoints,
            child: Text('PTS', textAlign: TextAlign.right, style: style),
          ),
        ],
      ),
    );
  }
}

class _LevelRow extends StatelessWidget {
  final LevelProgress progress;
  final CampaignLevel? level;
  final bool divider;

  const _LevelRow({
    required this.progress,
    required this.level,
    required this.divider,
  });

  @override
  Widget build(BuildContext context) {
    final minMoves = level?.level.minMoves ?? 0;
    final par = level?.level.parSeconds ?? 0;
    final underPar =
        progress.hasTime && par > 0 && progress.bestTimeSeconds <= par;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: divider
            ? const Border(top: BorderSide(color: Toy.divider, width: 1.5))
            : null,
      ),
      child: Row(
        children: [
          SizedBox(
            width: _colLevel,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                width: 26,
                height: 26,
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: Toy.mint,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Toy.ink, width: Toy.strokeThin),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text('${progress.levelId}', style: Toy.numbers(12)),
                ),
              ),
            ),
          ),
          const SizedBox(width: _colGap),
          SizedBox(
            width: _colStars,
            child: Align(
              alignment: Alignment.centerLeft,
              child: ToyStars(
                earned: progress.stars,
                size: 14,
                spacing: 1,
                fill: Toy.tomato,
                outlined: false,
              ),
            ),
          ),
          const SizedBox(width: _colGap),
          Expanded(
            child: Text(
              minMoves > 0
                  ? '${progress.bestMoves} / $minMoves'
                  : '${progress.bestMoves}',
              semanticsLabel: minMoves > 0
                  ? '${progress.bestMoves} moves, best possible $minMoves'
                  : plural(progress.bestMoves, 'move'),
              style: Toy.numbers(13, weight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: _colGap),
          SizedBox(
            width: _colTime,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                progress.hasTime ? formatClock(progress.bestTimeSeconds) : '—',
                // Under par is the one time worth drawing the eye to.
                style: Toy.numbers(
                  13,
                  color: underPar ? Toy.ink : Toy.inkMuted,
                  weight: underPar ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(width: _colGap),
          SizedBox(
            width: _colPoints,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Text(
                progress.bestPoints > 0
                    ? formatCount(progress.bestPoints)
                    : '—',
                style: Toy.numbers(13),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

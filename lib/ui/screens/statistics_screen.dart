/// Everything the game knows about how this player plays.
///
/// Four questions, in the order somebody actually asks them: how far have I
/// got, how am I doing against the clock, how often do I play, and — for the
/// completionist — what does every single level look like.
///
/// Two rules run through the whole screen.
///
///  * **A missing number is a dash, never a zero.** Every level cleared before
///    the clock shipped has no time on record, and printing 0:00 there would
///    be an invented fact about somebody's own play.
///  * **Nothing here scolds.** Over par is stated plainly and in the same grey
///    as everything else; only good news gets the warm accent. A statistics
///    screen that tells a player off for being slow at a relaxing puzzle is a
///    screen they visit once.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../engine/level_set.dart';
import '../../state/level_repository.dart';
import '../../state/play_history.dart';
import '../../state/progress_repository.dart';
import '../../state/providers.dart';
import '../format.dart';
import '../theme/tokens.dart';
import '../theme/typography.dart';
import '../widgets/pressable.dart';

class StatisticsScreen extends ConsumerWidget {
  final VoidCallback onBack;

  const StatisticsScreen({super.key, required this.onBack});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = PourfectTokens.of(context);
    final levels = ref.watch(campaignProvider).asData?.value;
    final progress = ref.watch(progressProvider);
    final progressController = ref.read(progressProvider.notifier);
    ref.watch(playHistoryProvider);
    final history = ref.read(playHistoryProvider.notifier);

    return Scaffold(
      backgroundColor: tokens.surface,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _Header(onBack: onBack)),

            if (progress.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _Empty(onBack: onBack),
              )
            else ...[
              SliverToBoxAdapter(
                child: _Lifetime(
                  progress: progress,
                  controller: progressController,
                  history: history,
                ),
              ),
              SliverToBoxAdapter(
                child: _AgainstTheClock(
                  progress: progress,
                  controller: progressController,
                  levels: levels,
                ),
              ),
              SliverToBoxAdapter(child: _Activity(history: history)),
              if (levels != null)
                SliverToBoxAdapter(
                  child: _PerBand(progress: progress, levels: levels),
                ),
              if (levels != null)
                _PerLevel(progress: progress, levels: levels)
              else
                const SliverToBoxAdapter(child: SizedBox.shrink()),
              SliverToBoxAdapter(child: SizedBox(height: tokens.space5)),
            ],
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final VoidCallback onBack;

  const _Header({required this.onBack});

  @override
  Widget build(BuildContext context) {
    final tokens = PourfectTokens.of(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        tokens.space4,
        tokens.space3,
        tokens.space4,
        tokens.space3,
      ),
      child: Row(
        children: [
          Pressable(
            onPressed: onBack,
            semanticLabel: 'Back',
            child: Padding(
              padding: EdgeInsets.only(right: tokens.space3),
              child: Icon(
                Icons.chevron_left_rounded,
                size: 26,
                color: tokens.textMuted,
              ),
            ),
          ),
          Text('Statistics', style: titleStyle(tokens).copyWith(fontSize: 22)),
        ],
      ),
    );
  }
}

/// What a player with no clears sees. An empty screen is an invitation, not a
/// report that there is nothing to report.
class _Empty extends StatelessWidget {
  final VoidCallback onBack;

  const _Empty({required this.onBack});

  @override
  Widget build(BuildContext context) {
    final tokens = PourfectTokens.of(context);

    return Padding(
      padding: EdgeInsets.all(tokens.space5),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Nothing to show yet',
            style: titleStyle(tokens).copyWith(fontSize: 18),
          ),
          SizedBox(height: tokens.space2),
          SizedBox(
            width: 280,
            child: Text(
              'Solve a level and this fills up: your times against par, your '
              'best solves, and the days you played.',
              textAlign: TextAlign.center,
              style: bodyStyle(tokens).copyWith(fontSize: 14),
            ),
          ),
          SizedBox(height: tokens.space4),
          Pressable(
            onPressed: onBack,
            child: Text(
              'Back to levels',
              style: actionStyle(tokens, color: tokens.accent),
            ),
          ),
        ],
      ),
    );
  }
}

// ---- lifetime ---------------------------------------------------------------

class _Lifetime extends StatelessWidget {
  final Map<int, LevelProgress> progress;
  final ProgressController controller;
  final PlayHistoryController history;

  const _Lifetime({
    required this.progress,
    required this.controller,
    required this.history,
  });

  @override
  Widget build(BuildContext context) {
    final moves = progress.values.fold(0, (sum, p) => sum + p.bestMoves);

    return _Section(
      title: 'Lifetime',
      child: _Grid(
        cells: [
          _Cell('Levels solved', formatCount(progress.length)),
          _Cell('Stars', formatCount(controller.totalStars)),
          _Cell('Points', formatCount(controller.totalPoints)),
          _Cell('Time played', formatSpan(history.totalSeconds)),
          _Cell('Moves in best solves', formatCount(moves)),
          _Cell('Now on', 'Level ${controller.furthestUnlocked}'),
        ],
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
    final tokens = PourfectTokens.of(context);
    final set = levels;
    final timed = progress.values.where((p) => p.hasTime).length;

    if (set == null || timed == 0) {
      return _Section(
        title: 'Against the clock',
        child: Text(
          'No times on record yet. Levels you cleared before the clock '
          'arrived have no time — replay one and it starts counting.',
          style: bodyStyle(tokens).copyWith(fontSize: 13),
        ),
      );
    }

    final ratio = controller.averageParRatio(set);
    final fastest = controller.fastestClear;
    final slowest = controller.slowestClear;

    return _Section(
      title: 'Against the clock',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Grid(
            cells: [
              _Cell(
                'Average pace',
                ratio == null ? '—' : _paceLabel(ratio),
                warm: ratio != null && ratio <= 1,
              ),
              _Cell(
                'Levels under par',
                '${controller.levelsUnderPar(set)} of $timed',
              ),
              _Cell(
                'Fastest solve',
                fastest == null ? '—' : formatClock(fastest.bestTimeSeconds),
                note: fastest == null ? null : 'level ${fastest.levelId}',
                warm: true,
              ),
              _Cell(
                'Longest solve',
                slowest == null ? '—' : formatClock(slowest.bestTimeSeconds),
                note: slowest == null ? null : 'level ${slowest.levelId}',
              ),
            ],
          ),
          if (timed < progress.length) ...[
            SizedBox(height: tokens.space3),
            Text(
              '${progress.length - timed} of your solved levels were cleared '
              'before the clock and have no time recorded.',
              style: bodyStyle(tokens)
                  .copyWith(fontSize: 12, color: tokens.dimText),
            ),
          ],
        ],
      ),
    );
  }

  /// Says the ratio the way a person would, not as a bare decimal.
  static String _paceLabel(double ratio) {
    final percent = ((ratio - 1) * 100).round();
    if (percent == 0) return 'on par';
    return percent < 0 ? '${-percent}% under' : '$percent% over';
  }
}

// ---- activity ---------------------------------------------------------------

class _Activity extends StatelessWidget {
  final PlayHistoryController history;

  const _Activity({required this.history});

  @override
  Widget build(BuildContext context) {
    final tokens = PourfectTokens.of(context);
    final streak = history.currentStreak();
    final days = history.recentDays(30);

    return _Section(
      title: 'Activity',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Grid(
            cells: [
              _Cell(
                'Current streak',
                streak == 0 ? '—' : plural(streak, 'day'),
                warm: streak > 1,
              ),
              _Cell('Longest streak', plural(history.longestStreak, 'day')),
              _Cell('Days played', formatCount(history.daysPlayed)),
              _Cell('Levels finished', formatCount(history.totalSolves)),
            ],
          ),
          SizedBox(height: tokens.space4),
          _ActivityChart(days: days),
          SizedBox(height: tokens.space2),
          Text(
            'Last 30 days',
            style: bodyStyle(tokens)
                .copyWith(fontSize: 12, color: tokens.dimText),
          ),
        ],
      ),
    );
  }
}

/// Thirty bars, one per day, heights scaled to the busiest of them.
///
/// A day with no play is a hairline baseline rather than a gap, so the shape
/// of a habit — three on, one off, three on — stays readable.
class _ActivityChart extends StatelessWidget {
  final List<DayRecord> days;

  const _ActivityChart({required this.days});

  @override
  Widget build(BuildContext context) {
    final tokens = PourfectTokens.of(context);
    final peak = days.fold(0, (max, d) => d.solved > max ? d.solved : max);

    return SizedBox(
      height: 56,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final day in days)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 1.5),
                child: Container(
                  height: peak == 0
                      ? 2
                      : (2 + (day.solved / peak) * 54).clamp(2.0, 56.0),
                  decoration: BoxDecoration(
                    color: day.solved == 0
                        ? tokens.hairline
                        : tokens.accent.withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ---- per band ---------------------------------------------------------------

class _PerBand extends StatelessWidget {
  final Map<int, LevelProgress> progress;
  final LevelSet levels;

  const _PerBand({required this.progress, required this.levels});

  @override
  Widget build(BuildContext context) {
    final tokens = PourfectTokens.of(context);

    return _Section(
      title: 'By section',
      child: Column(
        children: [
          for (final band in campaignBands()) ...[
            _BandRow(band: band, progress: progress, levels: levels),
            if (band.index != campaignBands().length - 1)
              Divider(color: tokens.hairline, height: tokens.space4),
          ],
        ],
      ),
    );
  }
}

class _BandRow extends StatelessWidget {
  final BandInfo band;
  final Map<int, LevelProgress> progress;
  final LevelSet levels;

  const _BandRow({
    required this.band,
    required this.progress,
    required this.levels,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = PourfectTokens.of(context);

    var cleared = 0;
    var timed = 0;
    var ratioSum = 0.0;
    var points = 0;

    for (var id = band.firstLevel; id <= band.lastLevel; id++) {
      final p = progress[id];
      if (p == null) continue;
      cleared++;
      points += p.bestPoints;

      final level = levels.byId(id);
      if (!p.hasTime || level == null || level.level.parSeconds <= 0) continue;
      timed++;
      ratioSum += p.bestTimeSeconds / level.level.parSeconds;
    }

    final pace = timed == 0 ? null : ratioSum / timed;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(band.name, style: bodyStyle(tokens).copyWith(fontSize: 14)),
              SizedBox(height: tokens.space1),
              Text(
                '$cleared of ${band.length} solved',
                style: bodyStyle(tokens)
                    .copyWith(fontSize: 12, color: tokens.dimText),
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              pace == null ? '—' : _AgainstTheClock._paceLabel(pace),
              style: numericStyle(
                tokens,
                size: 14,
                color: pace != null && pace <= 1
                    ? tokens.accentWarm
                    : tokens.textNumeric,
              ),
            ),
            SizedBox(height: tokens.space1),
            Text(
              '${formatCount(points)} pts',
              style: bodyStyle(tokens)
                  .copyWith(fontSize: 12, color: tokens.dimText),
            ),
          ],
        ),
      ],
    );
  }
}

// ---- per level --------------------------------------------------------------

/// Every solved level, newest id last. A sliver list rather than a Column:
/// 150 rows built eagerly inside a scroll view is 150 rows of layout the
/// player will never look at.
class _PerLevel extends StatelessWidget {
  final Map<int, LevelProgress> progress;
  final LevelSet levels;

  const _PerLevel({required this.progress, required this.levels});

  @override
  Widget build(BuildContext context) {
    final ids = progress.keys.toList()..sort();

    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(
          child: _SectionHeading(
            title: 'Every level',
            subtitle: 'Your best on each one',
          ),
        ),
        SliverList.builder(
          itemCount: ids.length,
          itemBuilder: (context, index) {
            final id = ids[index];
            return _LevelRow(
              progress: progress[id]!,
              level: levels.byId(id),
              isLast: index == ids.length - 1,
            );
          },
        ),
      ],
    );
  }
}

class _LevelRow extends StatelessWidget {
  final LevelProgress progress;
  final CampaignLevel? level;
  final bool isLast;

  const _LevelRow({
    required this.progress,
    required this.level,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = PourfectTokens.of(context);
    final minMoves = level?.level.minMoves ?? 0;
    final par = level?.level.parSeconds ?? 0;
    final underPar =
        progress.hasTime && par > 0 && progress.bestTimeSeconds <= par;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: tokens.space4,
        vertical: tokens.space3,
      ),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isLast ? Colors.transparent : tokens.hairline,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 38,
            child: Text(
              '${progress.levelId}',
              style: numericStyle(tokens, size: 14, color: tokens.textNumeric),
            ),
          ),
          SizedBox(width: 46, child: _Pips(earned: progress.stars)),
          Expanded(
            child: Text(
              minMoves > 0
                  ? '${progress.bestMoves} / $minMoves moves'
                  : '${progress.bestMoves} moves',
              style: bodyStyle(tokens)
                  .copyWith(fontSize: 12.5, color: tokens.textMuted),
            ),
          ),
          SizedBox(
            width: 58,
            child: Text(
              progress.hasTime ? formatClock(progress.bestTimeSeconds) : '—',
              textAlign: TextAlign.right,
              style: numericStyle(
                tokens,
                size: 13,
                color: underPar ? tokens.accentWarm : tokens.textNumeric,
              ),
            ),
          ),
          SizedBox(
            width: 64,
            child: Text(
              progress.bestPoints > 0 ? formatCount(progress.bestPoints) : '—',
              textAlign: TextAlign.right,
              style: numericStyle(tokens, size: 13, color: tokens.textMuted),
            ),
          ),
        ],
      ),
    );
  }
}

class _Pips extends StatelessWidget {
  final int earned;

  const _Pips({required this.earned});

  @override
  Widget build(BuildContext context) {
    final tokens = PourfectTokens.of(context);

    return Row(
      children: [
        for (var i = 0; i < 3; i++)
          Padding(
            padding: const EdgeInsets.only(right: 3),
            child: Transform.rotate(
              angle: 0.785398,
              child: Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: i < earned ? tokens.accentWarm : Colors.transparent,
                  border: i < earned
                      ? null
                      : Border.all(color: tokens.hairlineStrong),
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ---- shared furniture -------------------------------------------------------

class _Section extends StatelessWidget {
  final String title;
  final Widget child;

  const _Section({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final tokens = PourfectTokens.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionHeading(title: title),
        Padding(
          padding: EdgeInsets.fromLTRB(
            tokens.space4,
            0,
            tokens.space4,
            tokens.space4,
          ),
          child: child,
        ),
      ],
    );
  }
}

class _SectionHeading extends StatelessWidget {
  final String title;
  final String? subtitle;

  const _SectionHeading({required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    final tokens = PourfectTokens.of(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        tokens.space4,
        tokens.space4,
        tokens.space4,
        tokens.space3,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(title, style: titleStyle(tokens).copyWith(fontSize: 16)),
          if (subtitle != null) ...[
            SizedBox(width: tokens.space2),
            Text(
              subtitle!,
              style: bodyStyle(tokens)
                  .copyWith(fontSize: 12, color: tokens.dimText),
            ),
          ],
          SizedBox(width: tokens.space2),
          Expanded(child: Divider(color: tokens.hairline)),
        ],
      ),
    );
  }
}

/// One figure and what it is.
class _Cell {
  final String label;
  final String value;
  final String? note;
  final bool warm;

  const _Cell(this.label, this.value, {this.note, this.warm = false});
}

/// Two columns of figures. A Wrap rather than a GridView so a long value
/// pushes its own row taller instead of being clipped.
class _Grid extends StatelessWidget {
  final List<_Cell> cells;

  const _Grid({required this.cells});

  @override
  Widget build(BuildContext context) {
    final tokens = PourfectTokens.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = (constraints.maxWidth - tokens.space4) / 2;
        return Wrap(
          spacing: tokens.space4,
          runSpacing: tokens.space4,
          children: [
            for (final cell in cells)
              SizedBox(
                width: width,
                child: _CellView(cell: cell),
              ),
          ],
        );
      },
    );
  }
}

class _CellView extends StatelessWidget {
  final _Cell cell;

  const _CellView({required this.cell});

  @override
  Widget build(BuildContext context) {
    final tokens = PourfectTokens.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          cell.value,
          style: numericStyle(
            tokens,
            size: 22,
            color: cell.warm ? tokens.accentWarm : tokens.textPrimary,
          ),
        ),
        SizedBox(height: tokens.space1),
        Text(
          cell.note == null ? cell.label : '${cell.label}, ${cell.note}',
          style: bodyStyle(tokens).copyWith(fontSize: 12.5),
        ),
      ],
    );
  }
}

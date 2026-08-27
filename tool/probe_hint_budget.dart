// Measures what a HINT actually costs, so `kHintNodeCap` is set from evidence.
//
//   dart run tool/probe_hint_budget.dart
//
// Why this exists. Generation peaks around 600k nodes, but that is the cost of
// solving a level from its STARTING position. A hint is requested mid-play,
// from a position the player has already made progress in, which should be
// cheaper — but "should be" is not a number, and picking the budget by halving
// the generation figure would be a guess.
//
// The stakes are asymmetric and expensive: a hint is gated behind a rewarded
// video. "No hint available" AFTER a player has watched an ad is a refund
// request and a one-star review. The budget has to cover essentially every real
// request, so it is set from p99 with headroom rather than from the median.
//
// The probe walks the optimal path of the hardest levels in the shipped
// campaign and solves from EVERY state along it, which is exactly the
// population of positions a real hint request is drawn from.

import 'dart:io';

import 'package:pourfect_flutter_app/engine/level_set.dart';
import 'package:pourfect_flutter_app/engine/rules.dart';
import 'package:pourfect_flutter_app/engine/solver.dart';

const _campaignAssetPath = 'assets/levels/levels.bin';

/// Deliberately far above any expected cost: the probe must MEASURE the true
/// node count, never clip it. A clipped sample would understate the budget.
const _probeCap = 8000000;

/// How many of the hardest levels to walk.
const _levelsToProbe = 20;

void main(List<String> args) {
  final file = File(_campaignAssetPath);
  if (!file.existsSync()) {
    stderr.writeln(
      'missing $_campaignAssetPath — run tool/generate_levels.dart',
    );
    exit(1);
  }

  final levelSet = LevelSetCodec.decode(file.readAsBytesSync());
  final hardest = levelSet.levels.toList()
    ..sort(
      (a, b) => b.level.difficultyScore.compareTo(a.level.difficultyScore),
    );
  final probeSet = hardest.take(_levelsToProbe).toList();

  stdout.writeln(
    'Probing the $_levelsToProbe hardest levels '
    '(${probeSet.last.level.difficultyScore.toStringAsFixed(1)} - '
    '${probeSet.first.level.difficultyScore.toStringAsFixed(1)} difficulty)\n',
  );

  const solver = Solver(nodeCap: _probeCap);
  final samples = <_Sample>[];
  var undecided = 0;

  for (final campaignLevel in probeSet) {
    final level = campaignLevel.level;
    final outcome = solver.solve(level.board);
    if (outcome is! Solved) {
      stderr.writeln('  level ${level.id}: could not solve, skipping');
      continue;
    }

    // Walk the optimal path, solving from every position the player could
    // plausibly ask for a hint in. The final won state is excluded — there is
    // nothing to hint.
    var board = level.board;
    for (var step = 0; step < outcome.moves.length; step++) {
      final watch = Stopwatch()..start();
      final fromHere = solver.solve(board);
      watch.stop();

      if (fromHere is! Solved) {
        undecided++;
      } else {
        samples.add(
          _Sample(
            levelId: level.id,
            progress: step / outcome.moves.length,
            nodes: fromHere.nodesExplored,
            micros: watch.elapsedMicroseconds,
          ),
        );
      }

      board = applyMove(board, outcome.moves[step]).board;
    }

    stdout.writeln(
      '  level ${level.id} (${level.colorCount}c/${level.emptyTubeCount}e, '
      '${outcome.moveCount} moves) walked',
    );
  }

  if (samples.isEmpty) {
    stderr.writeln('no samples collected');
    exit(1);
  }

  _report(samples, undecided);
}

void _report(List<_Sample> samples, int undecided) {
  final nodes = samples.map((s) => s.nodes).toList()..sort();
  final micros = samples.map((s) => s.micros).toList()..sort();

  int pct(List<int> sorted, double q) =>
      sorted[(q * (sorted.length - 1)).round()];

  stdout
    ..writeln('\n${'=' * 68}')
    ..writeln(
      'HINT COST — ${samples.length} states sampled'
      '${undecided > 0 ? ", $undecided undecided" : ""}',
    )
    ..writeln('=' * 68)
    ..writeln(
      'nodes    p50 ${_n(pct(nodes, .50))}   '
      'p95 ${_n(pct(nodes, .95))}   '
      'p99 ${_n(pct(nodes, .99))}   '
      'max ${_n(nodes.last)}',
    )
    ..writeln(
      'desktop  p50 ${_ms(pct(micros, .50))}   '
      'p95 ${_ms(pct(micros, .95))}   '
      'p99 ${_ms(pct(micros, .99))}   '
      'max ${_ms(micros.last)}',
    );

  // The claim under test: does a hint get cheaper as the player progresses?
  stdout.writeln('\nCost by progress through the level:');
  const buckets = [
    (0.0, 0.05, 'start (0-5%)'),
    (0.05, 0.25, 'early (5-25%)'),
    (0.25, 0.50, 'mid   (25-50%)'),
    (0.50, 0.75, 'late  (50-75%)'),
    (0.75, 1.01, 'end   (75-100%)'),
  ];

  for (final (lo, hi, label) in buckets) {
    final inBucket = samples
        .where((s) => s.progress >= lo && s.progress < hi)
        .toList();
    if (inBucket.isEmpty) continue;
    final bucketNodes = inBucket.map((s) => s.nodes).toList()..sort();
    stdout.writeln(
      '  ${label.padRight(16)} n=${inBucket.length.toString().padLeft(4)}  '
      'p50 ${_n(pct(bucketNodes, .50)).padLeft(9)}  '
      'p99 ${_n(pct(bucketNodes, .99)).padLeft(9)}  '
      'max ${_n(bucketNodes.last).padLeft(9)}',
    );
  }

  // Budget from p99, doubled. p99 rather than p95 because the failure mode is
  // a player who already paid with their attention; doubled because this is
  // measured on desktop against the levels we ship TODAY, and a future content
  // update should not quietly start failing hints.
  final recommended = pct(nodes, .99) * 2;
  stdout
    ..writeln('\n${'-' * 68}')
    ..writeln('Current kHintNodeCap: ${_n(kHintNodeCap)}')
    ..writeln('Recommended:          ${_n(recommended)}  (p99 x 2)')
    ..writeln(
      kHintNodeCap >= recommended
          ? 'VERDICT: current budget is adequate.'
          : 'VERDICT: RAISE kHintNodeCap to ${_n(recommended)}. At the current '
                'cap,\n         ${_missRate(nodes, kHintNodeCap)} of hint '
                'requests on these levels would fail.',
    )
    ..writeln('-' * 68)
    ..writeln(
      '\nNOTE: whatever the budget, the hint flow must confirm the hint\n'
      'RESOLVED before consuming a rewarded-ad grant. Check first, then\n'
      'grant — never the other way round.',
    );
}

String _missRate(List<int> sortedNodes, int cap) {
  final over = sortedNodes.where((n) => n > cap).length;
  final pct = over / sortedNodes.length * 100;
  return '${pct.toStringAsFixed(1)}%';
}

String _n(int value) {
  if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(2)}M';
  if (value >= 1000) return '${(value / 1000).toStringAsFixed(0)}k';
  return '$value';
}

String _ms(int micros) => '${(micros / 1000).toStringAsFixed(1)}ms';

final class _Sample {
  final int levelId;

  /// 0.0 at the starting position, approaching 1.0 near the win.
  final double progress;
  final int nodes;
  final int micros;

  const _Sample({
    required this.levelId,
    required this.progress,
    required this.nodes,
    required this.micros,
  });
}

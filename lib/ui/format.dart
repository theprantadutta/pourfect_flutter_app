/// Number and duration formatting, shared so the same value never reads two
/// different ways on two screens.
library;

/// A running clock: `1:07`, or `1:02:44` once it passes an hour.
///
/// No leading zero on the leading unit — `1:07`, not `01:07`. The board HUD
/// carries this beside the move count, and a fixed-width zero there reads as a
/// countdown timer on an exam paper.
String formatClock(int seconds) {
  if (seconds < 0) seconds = 0;
  final h = seconds ~/ 3600;
  final m = (seconds % 3600) ~/ 60;
  final s = seconds % 60;

  final ss = s.toString().padLeft(2, '0');
  if (h == 0) return '$m:$ss';
  return '$h:${m.toString().padLeft(2, '0')}:$ss';
}

/// A span of time being reported rather than counted: `4h 12m`, `12m 30s`,
/// `44s`. Used for lifetime totals, where `13:11:04` is unreadable.
String formatSpan(int seconds) {
  if (seconds <= 0) return '0s';
  final h = seconds ~/ 3600;
  final m = (seconds % 3600) ~/ 60;
  final s = seconds % 60;

  if (h > 0) return m == 0 ? '${h}h' : '${h}h ${m}m';
  if (m > 0) return s == 0 ? '${m}m' : '${m}m ${s}s';
  return '${s}s';
}

/// Thousands separators, so a five-figure score is readable at a glance.
String formatCount(int value) {
  final digits = value.abs().toString();
  final buffer = StringBuffer(value < 0 ? '-' : '');
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
    buffer.write(digits[i]);
  }
  return buffer.toString();
}

/// A time against its par, as the player would say it: `18% under par`,
/// `on par`, `40% over par`.
String formatParDelta({required int seconds, required int parSeconds}) {
  if (parSeconds <= 0 || seconds <= 0) return '';
  final ratio = seconds / parSeconds;
  final percent = ((ratio - 1) * 100).round();
  if (percent == 0) return 'on par';
  return percent < 0 ? '${-percent}% under par' : '$percent% over par';
}

/// `1 day`, `4 days`. English only, which is all the app ships today.
String plural(int count, String singular, [String? plural]) =>
    '$count ${count == 1 ? singular : (plural ?? '${singular}s')}';

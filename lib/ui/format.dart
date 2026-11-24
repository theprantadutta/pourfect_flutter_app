/// Number and duration formatting, shared so the same value never reads two
/// different ways on two screens.
library;

import 'package:intl/intl.dart';

import '../l10n/l10n.dart';

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
  final l10n = appL10n();
  if (seconds <= 0) return l10n.hubSpanSeconds(0);
  final h = seconds ~/ 3600;
  final m = (seconds % 3600) ~/ 60;
  final s = seconds % 60;

  if (h > 0) {
    return m == 0 ? l10n.hubSpanHours(h) : l10n.hubSpanHoursMinutes(h, m);
  }
  if (m > 0) {
    return s == 0 ? l10n.hubSpanMinutes(m) : l10n.hubSpanMinutesSeconds(m, s);
  }
  return l10n.hubSpanSeconds(s);
}

/// Thousands separators, so a five-figure score is readable at a glance:
/// `12,480` in English, `12.480` in German, in the device's language.
String formatCount(int value) {
  final locale = appL10n().localeName;
  return NumberFormat.decimalPattern(
    NumberFormat.localeExists(locale) ? locale : 'en_US',
  ).format(value);
}

/// A time against its par, as the player would say it: `18% under par`,
/// `on par`, `40% over par`.
String formatParDelta({required int seconds, required int parSeconds}) {
  if (parSeconds <= 0 || seconds <= 0) return '';
  final ratio = seconds / parSeconds;
  final percent = ((ratio - 1) * 100).round();
  final l10n = appL10n();
  if (percent == 0) return l10n.hubParOn;
  return percent < 0 ? l10n.hubParUnder(-percent) : l10n.hubParOver(percent);
}

/// `1 day`, `4 days`. ENGLISH ONLY: the noun comes in as an English word.
/// Kept for screens not yet moved to translated strings; new code uses an ICU
/// plural in the ARB files instead.
String plural(int count, String singular, [String? plural]) =>
    '$count ${count == 1 ? singular : (plural ?? '${singular}s')}';

/// The locale [DateFormat] should use for [l10n]: its own when intl has date
/// symbols loaded for it (material_ui's localizations load them in the app),
/// else US English, which intl always has. A bare widget test lands there.
///
/// Uninitialized intl THROWS from `localeExists` for anything but US English
/// (a LocaleDataException) rather than answering false, hence the catch.
String _dateLocale(AppLocalizations l10n) {
  try {
    if (DateFormat.localeExists(l10n.localeName)) return l10n.localeName;
  } on Exception {
    // Date symbols not loaded: fall through to the one locale intl carries.
  }
  return 'en_US';
}

/// `Sun, Sep 27`: a day with its weekday, short.
String formatShortDate(AppLocalizations l10n, DateTime date) =>
    DateFormat.MMMEd(_dateLocale(l10n)).format(date);

/// `September 2026`.
String formatMonthYear(AppLocalizations l10n, DateTime date) =>
    DateFormat.yMMMM(_dateLocale(l10n)).format(date);

/// `September 27`.
String formatMonthDay(AppLocalizations l10n, DateTime date) =>
    DateFormat.MMMMd(_dateLocale(l10n)).format(date);

/// `Monday` for [weekday] 1 ([DateTime.monday]) through `Sunday` for 7.
String formatWeekday(AppLocalizations l10n, int weekday) =>
    DateFormat.EEEE(_dateLocale(l10n))
        .format(_aMonday.add(Duration(days: weekday - 1)));

/// The seven one-letter weekday initials, Monday first: `M T W T F S S`.
List<String> weekdayInitials(AppLocalizations l10n) {
  final format = DateFormat.EEEEE(_dateLocale(l10n));
  return [
    for (var i = 0; i < 7; i++) format.format(_aMonday.add(Duration(days: i))),
  ];
}

/// 1 January 2024 was a Monday.
final DateTime _aMonday = DateTime.utc(2024);

/// A campaign world's name for the player.
///
/// The engine names the four bundled worlds in English, and those names are
/// ids (the engine may not import translations). Worlds past level 150 are
/// named by the server and pass through as they came.
String worldDisplayName(AppLocalizations l10n, String name) => switch (name) {
  'First Pours' => l10n.journeyBandFirstPours,
  'Finding Rhythm' => l10n.journeyBandFindingRhythm,
  'Deep Water' => l10n.journeyBandDeepWater,
  'Mastery' => l10n.journeyBandMastery,
  _ => name,
};

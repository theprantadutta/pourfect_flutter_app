// The day log behind streaks and the activity chart.
//
// A streak is the one number on the statistics screen a player will feel
// strongly about, so the rules it follows are worth pinning: local calendar
// days, not UTC; today being unplayed does not break it; a single missed day
// does.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pourfect_flutter_app/state/play_history.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  late ProviderContainer container;
  setUp(() => container = ProviderContainer());
  tearDown(() => container.dispose());

  PlayHistoryController controller() =>
      container.read(playHistoryProvider.notifier);

  /// Seeds days relative to [today], oldest first — `seed(today, [0, 1, 3])`
  /// means played today, yesterday and three days ago.
  void seed(DateTime today, List<int> daysAgo) {
    controller().debugSeed({
      for (final ago in daysAgo)
        dayKey(today.subtract(Duration(days: ago))): DayRecord(
          date: dayKey(today.subtract(Duration(days: ago))),
          solved: 1,
          seconds: 90,
          points: 1000,
          moves: 12,
        ),
    });
  }

  group('day keys', () {
    test('round-trip through parse', () {
      final day = DateTime(2026, 9, 8);
      expect(parseDayKey(dayKey(day)), day);
    });

    test('pad to a sortable key', () {
      expect(dayKey(DateTime(2026, 1, 5)), '2026-01-05');
      // Sorting the keys as strings has to sort them as dates, because that is
      // how the history is trimmed.
      final keys = [
        dayKey(DateTime(2026, 10, 1)),
        dayKey(DateTime(2026, 9, 30)),
        dayKey(DateTime(2026, 2, 9)),
      ]..sort();
      expect(keys, [
        dayKey(DateTime(2026, 2, 9)),
        dayKey(DateTime(2026, 9, 30)),
        dayKey(DateTime(2026, 10, 1)),
      ]);
    });

    test('a corrupt key is skipped, not fatal', () {
      expect(parseDayKey('not-a-date'), isNull);
      expect(parseDayKey('2026-09'), isNull);
    });
  });

  group('current streak', () {
    final today = DateTime(2026, 9, 8);

    test('is zero with nothing logged', () {
      expect(controller().currentStreak(now: today), 0);
    });

    test('counts consecutive days back from today', () {
      seed(today, [0, 1, 2, 3]);
      expect(controller().currentStreak(now: today), 4);
    });

    test('survives today not being played yet', () {
      // Somebody who played every day for a week and has not opened the app
      // this morning still has a streak. A streak that died at midnight would
      // read as broken through the whole of the following day.
      seed(today, [1, 2, 3]);
      expect(controller().currentStreak(now: today), 3);
    });

    test('a missed day ends it', () {
      seed(today, [0, 1, 3, 4, 5]);
      expect(controller().currentStreak(now: today), 2);
    });

    test('a gap of two days leaves nothing live', () {
      seed(today, [2, 3, 4]);
      expect(controller().currentStreak(now: today), 0);
    });
  });

  group('longest streak', () {
    final today = DateTime(2026, 9, 8);

    test('finds the best run anywhere in the history', () {
      seed(today, [0, 1, 20, 21, 22, 23, 40]);
      expect(controller().longestStreak, 4);
    });

    test('is one for a single day played', () {
      seed(today, [5]);
      expect(controller().longestStreak, 1);
    });

    test('is zero with nothing logged', () {
      expect(controller().longestStreak, 0);
    });
  });

  group('recording', () {
    final today = DateTime(2026, 9, 8, 14, 30);

    test('several solves in a day land on one row', () {
      controller()
        ..recordSolve(
          levelId: 1,
          seconds: 60,
          moves: 10,
          stars: 3,
          points: 1000,
          now: today,
        )
        ..recordSolve(
          levelId: 2,
          seconds: 90,
          moves: 14,
          stars: 2,
          points: 800,
          now: today,
        );

      final day = container.read(playHistoryProvider)[dayKey(today)]!;
      expect(day.solved, 2);
      expect(day.seconds, 150);
      expect(day.points, 1800);
    });

    test('time on an unfinished level counts as play, not as a solve', () {
      // Otherwise "time played" only ever counts successes, and the boards
      // somebody wrestled with longest contribute nothing at all.
      controller().recordPlaytime(seconds: 240, now: today);

      final day = container.read(playHistoryProvider)[dayKey(today)]!;
      expect(day.seconds, 240);
      expect(day.solved, 0);
      expect(controller().totalSeconds, 240);
      expect(controller().totalSolves, 0);
    });

    test('a zero-second stretch writes nothing at all', () {
      controller().recordPlaytime(seconds: 0, now: today);
      expect(container.read(playHistoryProvider), isEmpty);
    });

    test('days played counts days, not solves', () {
      seed(DateTime(2026, 9, 8), [0, 1, 5]);
      expect(controller().daysPlayed, 3);
    });
  });

  group('the chart window', () {
    final today = DateTime(2026, 9, 8);

    test('is exactly as long as asked, oldest first', () {
      seed(today, [0, 3]);
      final days = controller().recentDays(30, now: today);

      expect(days, hasLength(30));
      expect(days.first.date, dayKey(today.subtract(const Duration(days: 29))));
      expect(days.last.date, dayKey(today));
    });

    test('fills the gaps rather than leaving them out', () {
      // The shape of a habit — three on, one off, three on — is only readable
      // if the empty days take up their own space.
      seed(today, [0, 2]);
      final days = controller().recentDays(4, now: today);

      expect(days.map((d) => d.solved).toList(), [0, 1, 0, 1]);
    });
  });

  group('the history stays bounded', () {
    test('trims to the newest days once it overflows', () {
      final today = DateTime(2026, 9, 8);
      controller().debugSeed({
        for (var ago = 0; ago < kMaxHistoryDays + 50; ago++)
          dayKey(today.subtract(Duration(days: ago))): DayRecord(
            date: dayKey(today.subtract(Duration(days: ago))),
            solved: 1,
          ),
      });

      // The trim happens on write, so provoke one.
      controller().recordPlaytime(seconds: 30, now: today);
      final kept = container.read(playHistoryProvider);

      expect(kept.length, kMaxHistoryDays);
      expect(kept.containsKey(dayKey(today)), isTrue);
      expect(
        kept.containsKey(
          dayKey(today.subtract(Duration(days: kMaxHistoryDays + 10))),
        ),
        isFalse,
        reason: 'the oldest days should be the ones dropped',
      );
    });
  });
}

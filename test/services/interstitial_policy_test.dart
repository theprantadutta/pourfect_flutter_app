// The interstitial rules, tested hard.
//
// This is the highest-consequence logic in the app that nobody will ever notice
// working. An over-eager interstitial turns a relaxing game into a one-star
// review, and the failure is invisible in development because nobody plays
// thirty levels in a row at their desk. So the rules are pure Dart and pinned
// here rather than discovered in production.

import 'package:pourfect_flutter_app/services/ads/interstitial_policy.dart';
import 'package:test/test.dart';

final _now = DateTime(2026, 8, 28, 12);

AdDecision decide(
  InterstitialPolicy policy, {
  required int level,
  bool adsRemoved = false,
  bool loaded = true,
  DateTime? now,
}) => policy.decide(
  levelId: level,
  adsRemoved: adsRemoved,
  isLoaded: loaded,
  now: now ?? _now,
);

void main() {
  const fresh = InterstitialPolicy();

  group('the early campaign is never interrupted', () {
    test('no ad before level 10, under any circumstances', () {
      // Where retention is won or lost. A player who has not yet decided
      // whether they like the game must never be shown an ad.
      for (
        var level = 1;
        level < InterstitialPolicy.firstEligibleLevel;
        level++
      ) {
        final decision = decide(fresh, level: level);
        expect(decision.allowed, isFalse, reason: 'level $level');
        expect(decision.reason, AdBlockReason.tooEarly);
      }
    });

    test('level 10 is the first that may show one', () {
      expect(decide(fresh, level: 10).allowed, isTrue);
    });
  });

  group('purchasing removes them', () {
    test('a paying player is never shown an interstitial', () {
      for (final level in [10, 50, 150]) {
        final decision = decide(fresh, level: level, adsRemoved: true);
        expect(decision.allowed, isFalse);
        expect(decision.reason, AdBlockReason.purchased);
      }
    });

    test('purchase beats every other rule', () {
      // Checked first, so a paying player never even reaches the frequency
      // logic. If this ever inverts, somebody who paid sees an ad.
      final decision = decide(
        fresh,
        level: 150,
        adsRemoved: true,
        loaded: true,
      );
      expect(decision.reason, AdBlockReason.purchased);
    });
  });

  group('frequency caps', () {
    test('waits the required number of levels', () {
      final after = fresh.recordShown(levelId: 10, now: _now);
      final later = _now.add(const Duration(hours: 1));

      for (var level = 11; level < 14; level++) {
        final decision = decide(after, level: level, now: later);
        expect(decision.allowed, isFalse, reason: 'level $level');
        expect(decision.reason, AdBlockReason.tooSoonByLevels);
      }
      expect(decide(after, level: 14, now: later).allowed, isTrue);
    });

    test('waits the cooldown even when enough levels have passed', () {
      // The level gate alone is not enough: a strong player can clear four
      // levels in ninety seconds, and would then be hit with a second ad.
      final after = fresh.recordShown(levelId: 10, now: _now);
      final soon = _now.add(const Duration(seconds: 90));

      final decision = decide(after, level: 20, now: soon);
      expect(decision.allowed, isFalse);
      expect(decision.reason, AdBlockReason.tooSoonByTime);
    });

    test('both gates must pass', () {
      final after = fresh.recordShown(levelId: 10, now: _now);
      final past = _now.add(InterstitialPolicy.cooldown);

      // Time satisfied, levels not.
      expect(decide(after, level: 12, now: past).allowed, isFalse);
      // Levels satisfied, time not.
      expect(
        decide(
          after,
          level: 20,
          now: _now.add(const Duration(seconds: 5)),
        ).allowed,
        isFalse,
      );
      // Both.
      expect(decide(after, level: 20, now: past).allowed, isTrue);
    });

    test('a replayed level cannot trigger another ad', () {
      // Replaying level 10 gives a level delta of zero, which must not pass.
      final after = fresh.recordShown(levelId: 10, now: _now);
      final later = _now.add(const Duration(hours: 2));
      expect(decide(after, level: 10, now: later).allowed, isFalse);
    });

    test('going BACKWARDS cannot trigger one either', () {
      // Replaying an earlier level makes the delta negative. A naive
      // "difference is not small" check would let that through.
      final after = fresh.recordShown(levelId: 40, now: _now);
      final later = _now.add(const Duration(hours: 2));
      final decision = decide(after, level: 12, now: later);
      expect(decision.allowed, isFalse);
      expect(decision.reason, AdBlockReason.tooSoonByLevels);
    });
  });

  group('inventory', () {
    test('reports not-ready separately from policy refusal', () {
      // "We had no ad" is an inventory problem; "we chose not to" is a policy
      // decision. Conflating them makes the funnel unreadable.
      final decision = decide(fresh, level: 20, loaded: false);
      expect(decision.allowed, isFalse);
      expect(decision.reason, AdBlockReason.notReady);
    });

    test('readiness is checked last, so the reason is the interesting one', () {
      final decision = decide(fresh, level: 3, loaded: false);
      expect(
        decision.reason,
        AdBlockReason.tooEarly,
        reason: 'policy refusal should be reported over missing inventory',
      );
    });
  });

  group('a realistic session', () {
    test('a long session stays within a humane ad load', () {
      // Play levels 1-60 back to back at 45 seconds each. Counts how many
      // interstitials a real player would actually see.
      var policy = const InterstitialPolicy();
      var clock = _now;
      var shown = 0;

      for (var level = 1; level <= 60; level++) {
        clock = clock.add(const Duration(seconds: 45));
        if (decide(policy, level: level, now: clock).allowed) {
          shown++;
          policy = policy.recordShown(levelId: level, now: clock);
        }
      }

      // Roughly one ad every four levels after level 10, capped further by the
      // three-minute cooldown. Anything approaching one per level would be the
      // behaviour we are explicitly avoiding.
      expect(shown, lessThanOrEqualTo(13));
      expect(
        shown,
        greaterThan(0),
        reason: 'the caps should not block ALL ads',
      );
    });

    test('a fast player is protected by the cooldown, not just the levels', () {
      // 15 seconds per level — a player who already knows the solutions.
      var policy = const InterstitialPolicy();
      var clock = _now;
      var shown = 0;

      for (var level = 1; level <= 60; level++) {
        clock = clock.add(const Duration(seconds: 15));
        if (decide(policy, level: level, now: clock).allowed) {
          shown++;
          policy = policy.recordShown(levelId: level, now: clock);
        }
      }

      // Fifty eligible levels in 12.5 minutes; the cooldown alone caps this
      // near four regardless of how fast they go.
      expect(shown, lessThanOrEqualTo(6));
    });

    test('a paying player sees none at all across the whole campaign', () {
      var policy = const InterstitialPolicy();
      var clock = _now;

      for (var level = 1; level <= 150; level++) {
        clock = clock.add(const Duration(minutes: 2));
        final decision = decide(
          policy,
          level: level,
          adsRemoved: true,
          now: clock,
        );
        expect(decision.allowed, isFalse, reason: 'level $level');
      }
    });
  });

  group('recordShown', () {
    test('carries both gates forward', () {
      final after = fresh.recordShown(levelId: 22, now: _now);
      expect(after.lastShownAtLevel, 22);
      expect(after.lastShownAt, _now);
    });

    test('a fresh policy has no history', () {
      expect(fresh.lastShownAtLevel, isNull);
      expect(fresh.lastShownAt, isNull);
    });
  });
}

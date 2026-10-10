// Achievements: what each one asks for.

import 'package:flutter_test/flutter_test.dart';
import 'package:pourfect_flutter_app/state/achievements.dart';

Achievement _a(String id) => kAchievements.firstWhere((a) => a.id == id);

void main() {
  test('the ids are exactly the ones the server allowlists', () {
    // Mirrors AchievementCatalogue.Names in the API. An id the server does
    // not know is silently not recorded, so drift here loses unlocks.
    expect(kAchievements.map((a) => a.id).toSet(), {
      'first_pour',
      'par_10',
      'par_50',
      'clean_clear',
      'speedy',
      'levels_100',
      'stars_300',
      'world_perfect',
      'streak_7',
      'streak_30',
      'chests_5',
      'hard_5',
      'event_full',
      'zen_25',
    });
  });

  test('counting achievements unlock at their target, not before', () {
    expect(
      _a('par_10').earnedBy(const AchievementFacts(parClears: 9)),
      isFalse,
    );
    expect(
      _a('par_10').earnedBy(const AchievementFacts(parClears: 10)),
      isTrue,
    );
    expect(
      _a('streak_7').earnedBy(const AchievementFacts(bestStreak: 7)),
      isTrue,
    );
    expect(
      _a('event_full').earnedBy(const AchievementFacts(eventBoardsCleared: 6)),
      isFalse,
    );
  });

  test('the moment achievements look only at the clear that just happened', () {
    expect(
      _a('clean_clear')
          .earnedBy(const AchievementFacts(lastClearWithoutUndo: true)),
      isTrue,
    );
    expect(_a('clean_clear').earnedBy(const AchievementFacts()), isFalse);
    expect(
      _a('speedy').earnedBy(const AchievementFacts(lastClearSeconds: 29)),
      isTrue,
    );
    expect(
      _a('speedy').earnedBy(const AchievementFacts(lastClearSeconds: 30)),
      isFalse,
    );
    // Zero is an untimed run (the guided level), never an instant one.
    expect(
      _a('speedy').earnedBy(const AchievementFacts(lastClearSeconds: 0)),
      isFalse,
    );
  });
}

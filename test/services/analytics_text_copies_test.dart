import 'package:flutter_test/flutter_test.dart';
import 'package:pourfect_flutter_app/services/analytics/analytics_service.dart';
import 'package:pourfect_flutter_app/services/analytics/firebase_analytics_service.dart';

/// Google Analytics left the number-valued `level_id` dimension "(not set)"
/// for two weeks while text dimensions filled in. The sink now adds a text
/// copy of the numbers reports split by.
void main() {
  test('level_id and stars also go out as text', () {
    const event = LevelComplete(
      levelId: 25,
      levelSetVersion: 3,
      moves: 14,
      minMoves: 14,
      stars: 3,
      durationSeconds: 16,
      hintsUsed: 0,
      undosUsed: 0,
    );
    final sent = withTextCopies(event.parameters);

    expect(sent['level'], '25');
    expect(sent['star_count'], '3');
    // The numbers stay as they were, for anything already built on them.
    expect(sent['level_id'], 25);
    expect(sent['stars'], 3);
  });

  test('the rating ask says where it happened', () {
    expect(
      const ReviewPromptShown(levelsSolved: 4).parameters['placement'],
      'hub',
    );
    expect(
      const ReviewPromptShown(
        levelsSolved: 4,
        placement: 'next_level',
      ).parameters['placement'],
      'next_level',
    );
  });

  test('events without those numbers are left alone', () {
    const event = AudioSettingsSnapshot(
      sound: true,
      music: true,
      soundVolume: 1,
      musicVolume: 0.5,
    );
    expect(withTextCopies(event.parameters), event.parameters);
  });
}

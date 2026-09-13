// When to ask for a rating, and — mostly — when not to.
//
// Calling Play's API is one line. Every rule below is the actual feature, and
// each exists because breaking it costs the thing the ask was for: a player
// asked at a bad moment leaves the one-star review they would never otherwise
// have written.
//
// Play never reports whether a card appeared, on purpose, so nothing here can
// assert "they rated". What it asserts is the decision — asked, or not.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pourfect_flutter_app/services/review/review_service.dart';
import 'package:pourfect_flutter_app/state/progress_repository.dart';
import 'package:pourfect_flutter_app/state/providers.dart';
import 'package:pourfect_flutter_app/state/review_prompter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeReview implements ReviewService {
  FakeReview({this.available = true});

  bool available;
  int requests = 0;

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<void> request() async => requests++;
}

/// A review service that throws, the way a device with a broken Play Services
/// can.
class BrokenReview implements ReviewService {
  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<void> request() async => throw StateError('no play services');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  ({ProviderContainer container, FakeReview review}) harness({
    int solved = 20,
    int askCount = 0,
    DateTime? lastAsked,
    ReviewService? service,
  }) {
    SharedPreferences.setMockInitialValues({
      'pourfect.review.ask_count': askCount,
      if (lastAsked != null)
        'pourfect.review.last_asked': lastAsked.toIso8601String(),
    });

    final review = service is FakeReview ? service : FakeReview();

    final container = ProviderContainer(
      overrides: [
        reviewServiceProvider.overrideWithValue(service ?? review),
        progressProvider.overrideWith(() => _StubProgress(solved)),
      ],
    );
    addTearDown(container.dispose);
    return (container: container, review: review);
  }

  group('it only asks somebody who is enjoying themselves', () {
    test('a delightful win followed by a pause asks', () async {
      final built = harness();
      final prompter = built.container.read(reviewPrompterProvider.notifier);

      prompter.noteDelight();
      await prompter.maybeAsk();

      expect(built.review.requests, 1);
    });

    test('leaving without a delightful win asks nothing', () async {
      // The ask fires on every return to the hub, so this is the common case
      // by a wide margin: a player who quit level 12 halfway through must not
      // be handed a rating card for their trouble.
      final built = harness();

      await built.container.read(reviewPrompterProvider.notifier).maybeAsk();

      expect(built.review.requests, isZero);
    });

    test('a player five minutes in is not asked', () async {
      // Play gives an app very few chances to show the card. Spending one on
      // somebody who has not decided whether they like the game yet buys a
      // rating from a stranger.
      final built = harness(solved: kMinSolvedBeforeReview - 1);
      final prompter = built.container.read(reviewPrompterProvider.notifier);

      prompter.noteDelight();
      await prompter.maybeAsk();

      expect(built.review.requests, isZero);
    });
  });

  group('it does not nag', () {
    test('one good moment earns at most one ask', () async {
      // Bouncing in and out of the hub after a three-star clear must not ask
      // on every return.
      final built = harness();
      final prompter = built.container.read(reviewPrompterProvider.notifier);

      prompter.noteDelight();
      await prompter.maybeAsk();
      await prompter.maybeAsk();
      await prompter.maybeAsk();

      expect(built.review.requests, 1);
    });

    test('a recent ask is not repeated', () async {
      final built = harness(
        askCount: 1,
        lastAsked: DateTime.now().subtract(const Duration(days: 3)),
      );
      final prompter = built.container.read(reviewPrompterProvider.notifier);

      prompter.noteDelight();
      await prompter.maybeAsk();

      expect(built.review.requests, isZero);
    });

    test('an old ask is allowed again', () async {
      final built = harness(
        askCount: 1,
        lastAsked: DateTime.now().subtract(kReviewCooldown * 2),
      );
      final prompter = built.container.read(reviewPrompterProvider.notifier);

      prompter.noteDelight();
      await prompter.maybeAsk();

      expect(built.review.requests, 1);
    });

    test('a player who has declined enough times is left alone', () async {
      final built = harness(
        askCount: kMaxReviewAsks,
        lastAsked: DateTime.now().subtract(kReviewCooldown * 5),
      );
      final prompter = built.container.read(reviewPrompterProvider.notifier);

      prompter.noteDelight();
      await prompter.maybeAsk();

      expect(built.review.requests, isZero);
    });

    test('the cap survives a restart', () async {
      // THE LAZY-PROVIDER TRAP, in the shape that already cost this codebase a
      // paywall: build() and the first question happen in the same breath, so
      // a decision taken before the stored count lands is taken against zero
      // and asks somebody who was asked yesterday. Reading the prompter and
      // immediately asking is exactly that race.
      final built = harness(
        askCount: kMaxReviewAsks,
        lastAsked: DateTime.now().subtract(const Duration(days: 1)),
      );

      final prompter = built.container.read(reviewPrompterProvider.notifier);
      prompter.noteDelight();
      await prompter.maybeAsk();

      expect(
        built.review.requests,
        isZero,
        reason: 'asked before the stored cap had been read back',
      );
    });
  });

  group('the platform', () {
    test('nothing is asked where there is no store', () async {
      final built = harness(service: FakeReview(available: false));
      final prompter = built.container.read(reviewPrompterProvider.notifier);

      prompter.noteDelight();
      await prompter.maybeAsk();

      expect(built.review.requests, isZero);
    });

    test('a broken Play Services does not take the app down with it', () async {
      // This runs on a path the player never asked for, immediately after
      // their best score of the night. An exception escaping here would turn
      // "no rating card available" into a crash on top of that.
      final built = harness(service: BrokenReview());
      final prompter = built.container.read(reviewPrompterProvider.notifier);

      prompter.noteDelight();
      await expectLater(prompter.maybeAsk(), completes);
    });

    test('an ask is recorded even though Play never says what happened',
        () async {
      // Play returns success whether or not a card appeared, deliberately, so
      // apps cannot detect and retry. The record is therefore of the ATTEMPT,
      // written before the call — anything that interrupts a system overlay
      // would otherwise lose it and ask again next time.
      final built = harness();
      final prompter = built.container.read(reviewPrompterProvider.notifier);

      prompter.noteDelight();
      await prompter.maybeAsk();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('pourfect.review.ask_count'), 1);
      expect(prefs.getString('pourfect.review.last_asked'), isNotNull);
    });
  });
}

/// Progress with a fixed number of solved levels.
class _StubProgress extends ProgressController {
  _StubProgress(this.solved);

  final int solved;

  @override
  Map<int, LevelProgress> build() => {
        for (var id = 1; id <= solved; id++)
          id: LevelProgress(
            levelId: id,
            stars: 3,
            bestMoves: 10,
            levelSetVersion: 1,
          ),
      };
}

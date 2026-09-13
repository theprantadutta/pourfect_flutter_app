import 'package:flutter/foundation.dart';
import 'package:in_app_review/in_app_review.dart';

import 'review_service.dart';

/// The real one, on Play's In-App Review API.
class PlayReviewService implements ReviewService {
  PlayReviewService({InAppReview? review})
    : _review = review ?? InAppReview.instance;

  final InAppReview _review;

  @override
  Future<bool> isAvailable() async {
    try {
      return await _review.isAvailable();
    } catch (error) {
      // A device with no Play Store, or a Play Services version too old to
      // answer. Neither is a fault worth surfacing — there is simply no card
      // to show.
      debugPrint('[review] availability check failed: $error');
      return false;
    }
  }

  @override
  Future<void> request() async {
    try {
      await _review.requestReview();
    } catch (error) {
      // SWALLOWED ON PURPOSE, and this is the one place that matters.
      //
      // This is called at the end of a good run, on a path the player did not
      // ask for and cannot see. An exception escaping here would turn "we
      // could not show a rating card" into a crash on top of somebody's best
      // score of the night. There is nothing to retry and nothing to tell them.
      debugPrint('[review] request failed: $error');
    }
  }
}

/// Used where there is no store: tests, and any desktop build.
class NoopReviewService implements ReviewService {
  const NoopReviewService();

  @override
  Future<bool> isAvailable() async => false;

  @override
  Future<void> request() async {}
}

/// Asking for a Play rating, behind an interface so the policy that decides
/// WHEN is testable without a Play Store.
///
/// **Rating count and average are the only marketing this game has.** Every
/// install comes from Play organic search, Play weights ratings in ranking, and
/// nothing here ever asked for one — so the app's rating was whatever the
/// minority who rate unprompted chose to leave, which skews negative because
/// annoyance motivates a review and contentment does not.
///
/// **Google forbids asking a question first.** No "Enjoying Pourfect?" dialog
/// with a Yes/No that routes happy players to the store and unhappy ones to a
/// feedback form. That pattern is explicitly against the In-App Review
/// guidelines — "don't ask the user any questions before or while displaying
/// the rating card, including questions about their opinion" — and it is also
/// rating manipulation. The only honest implementation is to pick a good
/// moment and call the API.
///
/// **The card may not appear, and the app can never find out.** Play enforces
/// its own quota and returns success either way, deliberately, so that apps
/// cannot detect and retry. So everything here is written to behave identically
/// whether the card showed or not: nothing is gated on it, nothing is retried
/// because of it, and "we asked" is recorded on the attempt rather than on any
/// outcome.
library;

/// The platform review flow.
abstract class ReviewService {
  /// Whether a review card could be requested at all. False on a device with no
  /// Play Store, and on desktop.
  Future<bool> isAvailable();

  /// Asks the platform to show its rating card.
  ///
  /// Returns when the flow is over. Never throws, and never reports whether the
  /// player actually rated — Play does not say.
  Future<void> request();
}

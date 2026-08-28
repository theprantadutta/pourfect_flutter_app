/// When an interstitial is allowed to appear.
///
/// PURE DART, no plugin — so the rules that decide whether a player gets
/// interrupted are unit-testable without an ad SDK, a device, or a network.
/// That matters more here than anywhere else in the app: an over-eager
/// interstitial is the single fastest way to turn a relaxing game into a
/// one-star review, and the failure is invisible in development because nobody
/// plays thirty levels in a row at their desk.
///
/// Our audience skews toward low-eCPM regions, so volume and retention are
/// worth far more than frequency. Every rule below is deliberately conservative.
library;

/// Where an interstitial was considered. Recorded on the analytics event so a
/// placement that annoys people is identifiable rather than guessed at.
enum InterstitialPlacement { levelComplete }

/// Why an interstitial was withheld. Returned rather than a bare bool so the
/// funnel can show WHICH rule is suppressing ads, not just that few showed.
enum AdBlockReason {
  /// The player bought Remove Ads.
  purchased,

  /// Too early in the campaign — they have not decided if they like the game.
  tooEarly,

  /// Not enough levels since the last one.
  tooSoonByLevels,

  /// Not enough time since the last one.
  tooSoonByTime,

  /// Nothing loaded.
  notReady,
}

/// A decision, with its reason.
class AdDecision {
  final bool allowed;
  final AdBlockReason? reason;

  const AdDecision.allow() : allowed = true, reason = null;

  const AdDecision.block(AdBlockReason this.reason) : allowed = false;
}

class InterstitialPolicy {
  /// No interstitial before this level, ever.
  ///
  /// The first levels are where retention is won or lost. A player who has not
  /// yet decided whether they like the game must never be interrupted, and
  /// nine levels is roughly the point where somebody has chosen to stay.
  static const int firstEligibleLevel = 10;

  /// Levels that must pass between interstitials.
  static const int minLevelsBetween = 4;

  /// Wall-clock cooldown, independent of levels.
  ///
  /// The level gate alone is not enough: the early campaign is fast, and a
  /// strong player can clear four levels in ninety seconds. Both gates have to
  /// pass, so a fast run is not punished with a stream of ads.
  static const Duration cooldown = Duration(minutes: 3);

  /// Level of the last interstitial, or null if none this install.
  final int? lastShownAtLevel;

  /// When the last one was shown.
  final DateTime? lastShownAt;

  const InterstitialPolicy({this.lastShownAtLevel, this.lastShownAt});

  /// Decides whether an interstitial may show after finishing [levelId].
  ///
  /// NOTE the caller contract: this is only ever consulted after a level is
  /// COMPLETED. There is deliberately no path that can show an interstitial on
  /// restart, on quitting a level, or mid-play — that is enforced by where this
  /// is called from, and `game_screen` has exactly one call site.
  AdDecision decide({
    required int levelId,
    required bool adsRemoved,
    required bool isLoaded,
    required DateTime now,
  }) {
    if (adsRemoved) return const AdDecision.block(AdBlockReason.purchased);
    if (levelId < firstEligibleLevel) {
      return const AdDecision.block(AdBlockReason.tooEarly);
    }

    final lastLevel = lastShownAtLevel;
    if (lastLevel != null && levelId - lastLevel < minLevelsBetween) {
      return const AdDecision.block(AdBlockReason.tooSoonByLevels);
    }

    final last = lastShownAt;
    if (last != null && now.difference(last) < cooldown) {
      return const AdDecision.block(AdBlockReason.tooSoonByTime);
    }

    // Readiness is checked LAST so the reason reported is the interesting one.
    // "we had no ad" is an inventory problem; "we chose not to" is a policy
    // decision, and conflating them hides which is which in the funnel.
    if (!isLoaded) return const AdDecision.block(AdBlockReason.notReady);

    return const AdDecision.allow();
  }

  /// The policy after an interstitial has been shown at [levelId].
  InterstitialPolicy recordShown({
    required int levelId,
    required DateTime now,
  }) => InterstitialPolicy(lastShownAtLevel: levelId, lastShownAt: now);
}

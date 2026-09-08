/// Ads, behind an interface so the network can be swapped or mediated later
/// without touching a line of game code.
///
/// THE RULE THAT GOVERNS THIS WHOLE FILE: a reward is granted only after the
/// thing the player was promised actually happens. Watching a video and then
/// being told "no hint available" is a refund request and a one-star review,
/// so [showRewarded] reports what really occurred and the caller decides.
library;

/// What a rewarded placement is for. Separate values because each gets its own
/// AdMob unit once live, which is the only way to see per-placement revenue.
enum RewardedPlacement {
  hint,
  extraTube,
  levelSkip;

  /// snake_case name for analytics.
  String get eventName => switch (this) {
    RewardedPlacement.hint => 'hint',
    RewardedPlacement.extraTube => 'extra_tube',
    RewardedPlacement.levelSkip => 'level_skip',
  };
}

/// The outcome of offering a rewarded video.
enum RewardOutcome {
  /// Watched to the end and the reward callback fired. The ONLY value that may
  /// unlock anything.
  earned,

  /// Closed early. No reward, and no complaint — they chose to leave.
  dismissed,

  /// Nothing was available to show. Must be surfaced as "try again shortly",
  /// never as a silent no-op.
  unavailable,

  /// The SDK reported a failure mid-show.
  failed,
}

abstract interface class AdService {
  /// Initialises the SDK. Must never throw and never block startup: a device
  /// with no Play Services still has to reach level 1.
  Future<void> init();

  /// True when an interstitial is loaded and could be shown right now.
  bool get isInterstitialReady;

  /// Shows an interstitial. Returns whether one was actually displayed.
  ///
  /// Callers must consult `InterstitialPolicy` FIRST — this method does not
  /// decide whether an ad is appropriate, only whether one can be shown.
  Future<bool> showInterstitial();

  /// Offers a rewarded video for [placement].
  Future<RewardOutcome> showRewarded(RewardedPlacement placement);

  /// Pre-loads so the next placement is instant.
  void preload();

  /// True when the SDK says this player must be given a way back into the
  /// consent form.
  ///
  /// Required where the form is required: somebody who consented has to be
  /// able to change their mind, and burying that is the kind of thing that
  /// gets ad serving limited rather than merely criticised.
  bool get privacyOptionsRequired;

  /// Re-opens the consent form and applies whatever the player chose.
  ///
  /// Applying it is part of the job, not the caller's problem: withdrawing
  /// consent has to discard inventory that was requested under the old answer,
  /// and granting it has to start requesting again without waiting for a
  /// relaunch.
  Future<void> showPrivacyOptions();

  Future<void> dispose();
}

/// Shows nothing, ever. Tests, and players who bought Remove Ads.
class NoopAdService implements AdService {
  const NoopAdService();

  @override
  Future<void> init() async {}

  @override
  bool get isInterstitialReady => false;

  @override
  Future<bool> showInterstitial() async => false;

  @override
  Future<RewardOutcome> showRewarded(RewardedPlacement placement) async =>
      RewardOutcome.unavailable;

  @override
  void preload() {}

  @override
  bool get privacyOptionsRequired => false;

  @override
  Future<void> showPrivacyOptions() async {}

  @override
  Future<void> dispose() async {}
}

/// Records calls and returns a scripted outcome. For tests.
class FakeAdService implements AdService {
  final List<String> calls = [];

  bool interstitialReady;
  RewardOutcome rewardOutcome;

  FakeAdService({
    this.interstitialReady = true,
    this.rewardOutcome = RewardOutcome.earned,
  });

  @override
  Future<void> init() async => calls.add('init');

  @override
  bool get isInterstitialReady => interstitialReady;

  @override
  Future<bool> showInterstitial() async {
    calls.add('interstitial');
    return interstitialReady;
  }

  @override
  Future<RewardOutcome> showRewarded(RewardedPlacement placement) async {
    calls.add('rewarded:${placement.eventName}');
    return rewardOutcome;
  }

  @override
  void preload() => calls.add('preload');

  @override
  bool privacyOptionsRequired = false;

  @override
  Future<void> showPrivacyOptions() async => calls.add('privacy_options');

  @override
  Future<void> dispose() async {}
}

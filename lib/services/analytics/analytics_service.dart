/// Analytics: the event catalogue and the swappable sink.
///
/// This exists to answer ONE question: where do players drop off, per level.
/// With no user-acquisition budget, every install comes from Play organic
/// search, and Play weights retention heavily — so a level that quietly costs
/// us 8% of players is the most expensive thing in the product, and it is
/// invisible without a per-level funnel. That is why analytics ships WITH the
/// UI rather than after it.
///
/// Events are a sealed hierarchy rather than a wide method interface: the
/// catalogue is then readable in one place, parameter names cannot drift
/// between call sites, and a fake sink for tests is four lines.
library;

/// A single analytics event.
sealed class AnalyticsEvent {
  const AnalyticsEvent();

  /// snake_case name as it appears in the analytics backend.
  String get name;

  /// Event parameters. Values must be `String`, `int` or `double` —
  /// Firebase rejects anything else, silently dropping the event.
  Map<String, Object> get parameters;
}

/// Which kind of board an event belongs to.
///
/// The daily, the weekly event and Zen all run on the same game controller as
/// the campaign, and every one of them used to report as level_set_version 0
/// with its own made-up level id. Mixed into the campaign funnel, a daily's
/// board looked like a campaign level nobody ever finished. `mode` keeps them
/// apart: filter on mode = campaign for the per-level funnel.
enum PlayMode { campaign, daily, event, zen }

/// A player opened a level. The denominator of every funnel.
final class LevelStart extends AnalyticsEvent {
  final int levelId;
  final int levelSetVersion;
  final int colorCount;
  final int minMoves;

  /// True when the player has played this level before — a retry, not a first
  /// look. Mixing the two would hide exactly the levels people bounce off.
  final bool isRetry;

  final PlayMode mode;

  const LevelStart({
    required this.levelId,
    required this.levelSetVersion,
    required this.colorCount,
    required this.minMoves,
    required this.isRetry,
    this.mode = PlayMode.campaign,
  });

  @override
  String get name => 'level_start';

  @override
  Map<String, Object> get parameters => {
    'level_id': levelId,
    'level_set_version': levelSetVersion,
    'color_count': colorCount,
    'min_moves': minMoves,
    'is_retry': isRetry ? 1 : 0,
    'mode': mode.name,
  };
}

/// A player finished a level.
final class LevelComplete extends AnalyticsEvent {
  final int levelId;
  final int levelSetVersion;
  final int moves;
  final int minMoves;
  final int stars;
  final int durationSeconds;
  final int hintsUsed;
  final int undosUsed;
  final PlayMode mode;

  const LevelComplete({
    required this.levelId,
    required this.levelSetVersion,
    required this.moves,
    required this.minMoves,
    required this.stars,
    required this.durationSeconds,
    required this.hintsUsed,
    required this.undosUsed,
    this.mode = PlayMode.campaign,
  });

  @override
  String get name => 'level_complete';

  @override
  Map<String, Object> get parameters => {
    'level_id': levelId,
    'level_set_version': levelSetVersion,
    'moves': moves,
    'min_moves': minMoves,
    'stars': stars,
    'duration_seconds': durationSeconds,
    'hints_used': hintsUsed,
    'undos_used': undosUsed,
    // Efficiency relative to optimal. Makes "levels people only just scrape
    // through" queryable without recomputing the ratio in the console.
    'move_ratio': minMoves == 0 ? 0.0 : moves / minMoves,
    'mode': mode.name,
  };
}

/// How a level ended without being completed.
enum AbandonReason {
  /// Explicit back-press or menu exit.
  exited,

  /// The app went to the background and did not come back to this level.
  ///
  /// THE DOMINANT PATH, and the one naive implementations miss. Most people who
  /// give up do not press back — they close the app or get a call. A funnel
  /// that only counts clean exits undercounts abandonment on exactly the hard
  /// levels it exists to find.
  backgrounded,

  /// The player hit restart.
  restarted,

  /// The board reached a dead state and the player left rather than undoing.
  deadEnd,
}

/// A player left a level unfinished.
final class LevelAbandon extends AnalyticsEvent {
  final int levelId;
  final int levelSetVersion;
  final int moves;
  final int minMoves;
  final int durationSeconds;
  final AbandonReason reason;

  /// How far through the optimal solution they got, 0-1. A player who quits at
  /// 5% bounced off the presentation; one who quits at 80% hit a wall. Those
  /// need different fixes, so the funnel has to tell them apart.
  final double progress;

  final PlayMode mode;

  const LevelAbandon({
    required this.levelId,
    required this.levelSetVersion,
    required this.moves,
    required this.minMoves,
    required this.durationSeconds,
    required this.reason,
    required this.progress,
    this.mode = PlayMode.campaign,
  });

  /// The inverse of [parameters], for the abandon that has to survive the
  /// process being killed while backgrounded (see `pending_abandon.dart`).
  /// Null for anything unreadable: a stored abandon from an older build is
  /// dropped rather than sent half-filled.
  static LevelAbandon? fromParameters(Map<String, Object?> json) {
    try {
      return LevelAbandon(
        levelId: json['level_id']! as int,
        levelSetVersion: json['level_set_version']! as int,
        moves: json['moves']! as int,
        minMoves: json['min_moves']! as int,
        durationSeconds: json['duration_seconds']! as int,
        reason: AbandonReason.values.byName(json['reason']! as String),
        progress: (json['progress']! as num).toDouble(),
        mode: PlayMode.values.byName(json['mode']! as String),
      );
    } catch (_) {
      return null;
    }
  }

  @override
  String get name => 'level_abandon';

  @override
  Map<String, Object> get parameters => {
    'level_id': levelId,
    'level_set_version': levelSetVersion,
    'moves': moves,
    'min_moves': minMoves,
    'duration_seconds': durationSeconds,
    'reason': reason.name,
    'progress': progress,
    'mode': mode.name,
  };
}

final class HintUsed extends AnalyticsEvent {
  final int levelId;
  final int movesBefore;

  /// False when the solver could not decide in its budget. Should be rare; if
  /// it is not, `kHintNodeCap` needs raising.
  final bool resolved;

  /// True when the hint was paid for with a rewarded video.
  final bool wasRewarded;

  const HintUsed({
    required this.levelId,
    required this.movesBefore,
    required this.resolved,
    required this.wasRewarded,
  });

  @override
  String get name => 'hint_used';

  @override
  Map<String, Object> get parameters => {
    'level_id': levelId,
    'moves_before': movesBefore,
    'resolved': resolved ? 1 : 0,
    'was_rewarded': wasRewarded ? 1 : 0,
  };
}

final class UndoUsed extends AnalyticsEvent {
  final int levelId;
  final int movesBefore;

  /// True when the board had no legal move left. A spike here on one level
  /// means that level traps people.
  final bool fromDeadEnd;

  const UndoUsed({
    required this.levelId,
    required this.movesBefore,
    required this.fromDeadEnd,
  });

  @override
  String get name => 'undo_used';

  @override
  Map<String, Object> get parameters => {
    'level_id': levelId,
    'moves_before': movesBefore,
    'from_dead_end': fromDeadEnd ? 1 : 0,
  };
}

enum PowerUpKind { extraTube, levelSkip }

final class PowerUpUsed extends AnalyticsEvent {
  final int levelId;
  final PowerUpKind kind;
  final bool wasRewarded;

  const PowerUpUsed({
    required this.levelId,
    required this.kind,
    required this.wasRewarded,
  });

  @override
  String get name => 'power_up_used';

  @override
  Map<String, Object> get parameters => {
    'level_id': levelId,
    'power_up': kind.name,
    'was_rewarded': wasRewarded ? 1 : 0,
  };
}

enum AdFormat { rewarded, interstitial }

final class AdShown extends AnalyticsEvent {
  final AdFormat format;
  final String placement;
  final int levelId;

  const AdShown({
    required this.format,
    required this.placement,
    required this.levelId,
  });

  @override
  String get name => 'ad_shown';

  @override
  Map<String, Object> get parameters => {
    'format': format.name,
    'placement': placement,
    'level_id': levelId,
  };
}

final class AdCompleted extends AnalyticsEvent {
  final AdFormat format;
  final String placement;
  final int levelId;

  /// Whether the reward was actually granted. The gap between [AdShown] and a
  /// granted [AdCompleted] is the number to watch: it is players who spent
  /// their attention and got nothing.
  final bool rewardGranted;

  const AdCompleted({
    required this.format,
    required this.placement,
    required this.levelId,
    required this.rewardGranted,
  });

  @override
  String get name => 'ad_completed';

  @override
  Map<String, Object> get parameters => {
    'format': format.name,
    'placement': placement,
    'level_id': levelId,
    'reward_granted': rewardGranted ? 1 : 0,
  };
}

/// How the guided first level ended, or that it began.
enum TutorialOutcome { begin, complete, skip }

/// The guided first level. `tutorial_begin` and `tutorial_complete` are GA4's
/// recommended names, so Firebase draws the funnel without configuration; a
/// skip carries the step it happened at, which is the part worth tuning.
final class TutorialEvent extends AnalyticsEvent {
  final TutorialOutcome outcome;

  /// Guidance steps shown so far (pours pointed at).
  final int step;

  /// Replayed from Settings rather than a first run.
  final bool isReplay;

  const TutorialEvent({
    required this.outcome,
    required this.step,
    required this.isReplay,
  });

  @override
  String get name => 'tutorial_${outcome.name}';

  @override
  Map<String, Object> get parameters => {
    'step': step,
    'is_replay': isReplay ? 1 : 0,
  };
}

final class IapViewed extends AnalyticsEvent {
  final String productId;
  final String placement;

  const IapViewed({required this.productId, required this.placement});

  @override
  String get name => 'iap_viewed';

  @override
  Map<String, Object> get parameters => {
    'product_id': productId,
    'placement': placement,
  };
}

final class IapPurchased extends AnalyticsEvent {
  final String productId;
  final String placement;

  /// The store's price and ISO currency, when the store gave one. Sent as
  /// GA's `value` and `currency`, so the event carries what it was worth.
  ///
  /// Deliberately NOT GA's `purchase` event. Firebase already logs
  /// `in_app_purchase` from the store itself, and that is what fills the
  /// revenue cards; a second revenue event for the same sale would count it
  /// twice.
  final double? price;
  final String? currency;

  const IapPurchased({
    required this.productId,
    required this.placement,
    this.price,
    this.currency,
  });

  @override
  String get name => 'iap_purchased';

  @override
  Map<String, Object> get parameters => {
    'product_id': productId,
    'placement': placement,
    if (price case final price?)
      if (currency case final currency?) ...{
        'value': price,
        'currency': currency,
      },
  };
}

/// The player's sound choices, once per launch: how many keep music and
/// sound on is the number the sound design is judged by.
final class AudioSettingsSnapshot extends AnalyticsEvent {
  final bool sound;
  final bool music;
  final double soundVolume;
  final double musicVolume;

  const AudioSettingsSnapshot({
    required this.sound,
    required this.music,
    required this.soundVolume,
    required this.musicVolume,
  });

  @override
  String get name => 'audio_settings';

  @override
  Map<String, Object> get parameters => {
    'sound': sound ? 1 : 0,
    'music': music ? 1 : 0,
    'sound_volume': soundVolume,
    'music_volume': musicVolume,
  };
}

/// The player took the win screen's "Try for 3★" and restarted the level.
final class RetryForStars extends AnalyticsEvent {
  final int levelId;

  /// Stars on the clear that prompted it: 1 or 2.
  final int fromStars;

  const RetryForStars({required this.levelId, required this.fromStars});

  @override
  String get name => 'retry_for_stars';

  @override
  Map<String, Object> get parameters => {
    'level_id': levelId,
    'from_stars': fromStars,
  };
}

/// The next clear of a level after "Try for 3★": did the retry pay off?
final class RetryForStarsResult extends AnalyticsEvent {
  final int levelId;
  final int stars;

  const RetryForStarsResult({required this.levelId, required this.stars});

  @override
  String get name => 'retry_for_stars_result';

  @override
  Map<String, Object> get parameters => {
    'level_id': levelId,
    'stars': stars,
    'earned_three': stars >= 3 ? 1 : 0,
  };
}

/// The player opened a notification. The dashboard counts the same open from
/// the server's side; this one lands in the funnel beside what they did next.
final class NotificationOpened extends AnalyticsEvent {
  final String kind;
  final String destination;

  const NotificationOpened({required this.kind, required this.destination});

  @override
  String get name => 'notification_opened';

  @override
  Map<String, Object> get parameters => {
    'kind': kind,
    'destination': destination,
  };
}

/// What the player answered when notifications were offered, and where.
final class NotificationPermissionAnswered extends AnalyticsEvent {
  /// soft_ask (the hub card), daily (after a daily) or settings.
  final String placement;
  final bool granted;

  const NotificationPermissionAnswered({
    required this.placement,
    required this.granted,
  });

  @override
  String get name => 'notification_permission';

  @override
  Map<String, Object> get parameters => {
    'placement': placement,
    'granted': granted ? 1 : 0,
  };
}

/// A screen came into view. Firebase's own screen tracking only sees Android
/// activities, so every Flutter screen used to report as `MainActivity`.
/// The Firebase sink sends this through `logScreenView`, which is what fills
/// the Pages and screens report.
final class ScreenView extends AnalyticsEvent {
  final String screenName;

  const ScreenView(this.screenName);

  @override
  String get name => 'screen_view';

  @override
  Map<String, Object> get parameters => {'screen_name': screenName};
}

/// How an account was signed in to or created.
enum SignInMethod { google, apple, email }

/// A player signed in to an account that already existed. GA's recommended
/// `login`.
final class Login extends AnalyticsEvent {
  final SignInMethod method;

  const Login(this.method);

  @override
  String get name => 'login';

  @override
  Map<String, Object> get parameters => {'method': method.name};
}

/// A player turned their anonymous progress into an account. GA's
/// recommended `sign_up`.
final class SignUp extends AnalyticsEvent {
  final SignInMethod method;

  const SignUp(this.method);

  @override
  String get name => 'sign_up';

  @override
  Map<String, Object> get parameters => {'method': method.name};
}

/// The store's rating sheet was asked for. Whether it actually appeared is
/// the store's secret, so this counts asks, not ratings.
final class ReviewPromptShown extends AnalyticsEvent {
  /// Campaign levels solved at the time, so the ask can be judged by how far
  /// in it came.
  final int levelsSolved;

  const ReviewPromptShown({required this.levelsSolved});

  @override
  String get name => 'review_prompt';

  @override
  Map<String, Object> get parameters => {'levels_solved': levelsSolved};
}

/// Today's Daily Pour was solved and the server took the result.
///
/// `level_complete` with mode = daily already counts the solve. This carries
/// the part only the server knows: the streak it produced.
final class DailyComplete extends AnalyticsEvent {
  final int streak;

  /// False for a replay of a board already finished today.
  final bool firstToday;

  const DailyComplete({required this.streak, required this.firstToday});

  @override
  String get name => 'daily_complete';

  @override
  Map<String, Object> get parameters => {
    'streak': streak,
    'first_today': firstToday ? 1 : 0,
  };
}

/// A streak freeze was earned with a video.
final class StreakFreezeEarned extends AnalyticsEvent {
  const StreakFreezeEarned();

  @override
  String get name => 'streak_freeze_earned';

  @override
  Map<String, Object> get parameters => const {};
}

/// The `levels_solved` user property: campaign levels solved, in bands of
/// ten. A raw count would make every player their own segment; bands make
/// "players past level 50" a filter instead of a query.
String levelsSolvedBand(int solved) {
  if (solved <= 0) return '0';
  final low = (solved - 1) ~/ 10 * 10 + 1;
  return '$low-${low + 9}';
}

/// Where events go.
///
/// Deliberately narrow and swappable — the same shape as the ad abstraction, so
/// changing provider or adding a second sink never touches game code.
abstract interface class AnalyticsService {
  /// Records [event]. MUST NOT throw and MUST NOT block gameplay: analytics is
  /// never allowed to be the reason a tap feels slow or a level fails to open.
  Future<void> log(AnalyticsEvent event);

  /// Sets a user property: a fact about the player that every later event
  /// can be split by, such as how far in they are. Same rules as [log]: never
  /// throws, never blocks. A null [value] clears it.
  Future<void> setUserProperty(String name, String? value);

  /// Flushes anything buffered. Called when the app backgrounds.
  Future<void> flush();
}

/// Drops everything. Used in tests and wherever analytics is disabled.
/// Whether `Firebase.initializeApp` actually succeeded.
///
/// Catching the initialisation failure is only half a fallback: constructing
/// `FirebaseAnalyticsService` touches `FirebaseAnalytics.instance`, which
/// throws when there is no default app — OUTSIDE the try that caught the
/// original failure. So the app survived startup and then died on its first
/// gameplay event instead.
///
/// Set once, in main(), and read when choosing an implementation.
bool firebaseReady = false;

final class NoopAnalyticsService implements AnalyticsService {
  const NoopAnalyticsService();

  @override
  Future<void> log(AnalyticsEvent event) async {}

  @override
  Future<void> setUserProperty(String name, String? value) async {}

  @override
  Future<void> flush() async {}
}

/// Records events in memory. For tests and for the debug overlay.
final class RecordingAnalyticsService implements AnalyticsService {
  final List<AnalyticsEvent> events = [];
  final Map<String, String?> userProperties = {};

  @override
  Future<void> log(AnalyticsEvent event) async => events.add(event);

  @override
  Future<void> setUserProperty(String name, String? value) async =>
      userProperties[name] = value;

  @override
  Future<void> flush() async {}

  List<T> ofType<T extends AnalyticsEvent>() => events.whereType<T>().toList();
}

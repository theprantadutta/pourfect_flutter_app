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

/// A player opened a level. The denominator of every funnel.
final class LevelStart extends AnalyticsEvent {
  final int levelId;
  final int levelSetVersion;
  final int colorCount;
  final int minMoves;

  /// True when the player has played this level before — a retry, not a first
  /// look. Mixing the two would hide exactly the levels people bounce off.
  final bool isRetry;

  const LevelStart({
    required this.levelId,
    required this.levelSetVersion,
    required this.colorCount,
    required this.minMoves,
    required this.isRetry,
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

  const LevelComplete({
    required this.levelId,
    required this.levelSetVersion,
    required this.moves,
    required this.minMoves,
    required this.stars,
    required this.durationSeconds,
    required this.hintsUsed,
    required this.undosUsed,
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

  const LevelAbandon({
    required this.levelId,
    required this.levelSetVersion,
    required this.moves,
    required this.minMoves,
    required this.durationSeconds,
    required this.reason,
    required this.progress,
  });

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

  const IapPurchased({required this.productId, required this.placement});

  @override
  String get name => 'iap_purchased';

  @override
  Map<String, Object> get parameters => {
    'product_id': productId,
    'placement': placement,
  };
}

/// Where events go.
///
/// Deliberately narrow and swappable — the same shape as the ad abstraction, so
/// changing provider or adding a second sink never touches game code.
abstract interface class AnalyticsService {
  /// Records [event]. MUST NOT throw and MUST NOT block gameplay: analytics is
  /// never allowed to be the reason a tap feels slow or a level fails to open.
  Future<void> log(AnalyticsEvent event);

  /// Flushes anything buffered. Called when the app backgrounds, which is the
  /// last moment a pending `level_abandon` can still be sent.
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
  Future<void> flush() async {}
}

/// Records events in memory. For tests and for the debug overlay.
final class RecordingAnalyticsService implements AnalyticsService {
  final List<AnalyticsEvent> events = [];

  @override
  Future<void> log(AnalyticsEvent event) async => events.add(event);

  @override
  Future<void> flush() async {}

  List<T> ofType<T extends AnalyticsEvent>() => events.whereType<T>().toList();
}

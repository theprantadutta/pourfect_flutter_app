/// The state of one level in progress.
library;

import 'package:flutter/foundation.dart';

import '../engine/board.dart';
import '../engine/level.dart';
import '../engine/move.dart';
import '../engine/rules.dart';

/// A pour that just happened, in the form the board view needs to animate it.
///
/// Slots rather than pixels: the state layer must not know how big a ball is.
/// The view turns these into positions through `BoardGeometry`.
@immutable
class PourEvent {
  /// Increments on every pour, so the view can tell a NEW pour from a rebuild
  /// carrying the same one. Without it, any unrelated setState would replay
  /// the last animation.
  final int sequence;

  final Move move;

  /// How many balls travel.
  final int ballsMoved;

  final ColorId color;

  /// Slot of the topmost source ball before the move (0 = bottom). The first
  /// ball leaves from here, the next from one below, and so on.
  final int sourceTopSlot;

  /// Slot the FIRST arriving ball lands in. Later balls stack above it.
  final int destBaseSlot;

  /// True when this pour finished the destination tube — the cue for the
  /// settle-and-glow flourish and the stronger haptic.
  final bool completedDestination;

  const PourEvent({
    required this.sequence,
    required this.move,
    required this.ballsMoved,
    required this.color,
    required this.sourceTopSlot,
    required this.destBaseSlot,
    required this.completedDestination,
  });
}

/// Everything about the level currently being played.
@immutable
class GameState {
  final Level level;
  final int levelSetVersion;

  /// The live board.
  final Board board;

  /// Boards before each move, newest last. Unlimited within a level.
  ///
  /// UNDO IS FREE AND ALWAYS WILL BE. It is a retention feature, not a
  /// monetisation one: a player who cannot take back a misclick stops playing,
  /// and that costs far more than a rewarded video earns.
  final List<Board> undoStack;

  final int movesUsed;

  /// Tube whose top run is currently lifted, or null.
  final int? selectedTube;

  /// The most recent pour, for the view to animate. Never cleared on rebuild —
  /// the view de-duplicates on [PourEvent.sequence].
  final PourEvent? pour;

  /// Move the hint is currently pointing at, if one is on screen.
  final Move? hintMove;

  /// True while the solver isolate is working. The board STAYS INTERACTIVE
  /// during this; see the hint controller.
  final bool hintPending;

  final int hintsUsed;
  final int undosUsed;

  /// When this attempt began, for the funnel's duration figure.
  final DateTime startedAt;

  /// Play time banked from earlier running stretches of this attempt.
  ///
  /// The clock is NOT `now - startedAt`. It stops whenever the player is not
  /// actually playing: app backgrounded, a rewarded video on screen, the
  /// settings sheet open, the level finished. A scored clock that keeps
  /// running through an ad break would charge the player points for watching
  /// the ad, which is the sort of thing that gets a game uninstalled.
  final Duration elapsedBefore;

  /// When the current running stretch began, or null while the clock is
  /// stopped.
  final DateTime? runningSince;

  /// Seconds of this attempt already written into the play history.
  ///
  /// The scoring clock and the history are counted separately on purpose. The
  /// score wants the WHOLE attempt, so `elapsedBefore` only ever grows; the
  /// history wants each second exactly once, and an attempt can reach it in
  /// several instalments as the player backgrounds and returns. This is the
  /// high-water mark of what has already been handed over.
  final int bankedSeconds;

  /// True if the player has opened this level before in this session.
  final bool isRetry;

  const GameState({
    required this.level,
    required this.levelSetVersion,
    required this.board,
    required this.undoStack,
    required this.movesUsed,
    required this.selectedTube,
    required this.pour,
    required this.hintMove,
    required this.hintPending,
    required this.hintsUsed,
    required this.undosUsed,
    required this.startedAt,
    required this.elapsedBefore,
    required this.runningSince,
    required this.bankedSeconds,
    required this.isRetry,
  });

  /// A fresh attempt at [level].
  factory GameState.fresh({
    required Level level,
    required int levelSetVersion,
    required DateTime now,
    bool isRetry = false,
  }) => GameState(
    level: level,
    levelSetVersion: levelSetVersion,
    board: level.board,
    undoStack: const [],
    movesUsed: 0,
    selectedTube: null,
    pour: null,
    hintMove: null,
    hintPending: false,
    hintsUsed: 0,
    undosUsed: 0,
    startedAt: now,
    elapsedBefore: Duration.zero,
    runningSince: now,
    bankedSeconds: 0,
    isRetry: isRetry,
  );

  bool get isWon => board.isWon;

  /// True while the clock is counting.
  bool get isClockRunning => runningSince != null;

  /// Play time as of [now], excluding every stretch the clock was stopped.
  Duration elapsedAt(DateTime now) {
    final since = runningSince;
    if (since == null) return elapsedBefore;
    final live = now.difference(since);
    // A device clock that jumps backwards (timezone, NTP, manual change) must
    // not hand back time the player already spent.
    return live.isNegative ? elapsedBefore : elapsedBefore + live;
  }

  /// Play time in whole seconds, the unit everything downstream stores.
  int elapsedSecondsAt(DateTime now) => elapsedAt(now).inSeconds;

  /// The pace this level is scored against.
  int get parSeconds => level.parSeconds;

  /// Seconds played but not yet written to the play history.
  int unbankedSecondsAt(DateTime now) {
    final unbanked = elapsedSecondsAt(now) - bankedSeconds;
    return unbanked > 0 ? unbanked : 0;
  }

  /// Points this attempt would score if it finished at [now].
  int pointsAt(DateTime now) =>
      level.points(movesUsed: movesUsed, elapsedSeconds: elapsedSecondsAt(now));

  /// No legal move remains and the level is unfinished. The UI must surface
  /// this immediately and offer undo or restart — leaving a player stuck on a
  /// dead board wondering what they missed is how a relaxing game earns a
  /// one-star review.
  bool get isStuck => isDead(board);

  bool get canUndo => undoStack.isNotEmpty;

  /// Stars this attempt would earn if finished now.
  int get stars => level.stars(movesUsed);

  /// Rough progress through the optimal solution, 0-1. Reported on abandon so
  /// "bounced immediately" and "hit a wall near the end" stay distinguishable.
  double get progress {
    if (level.minMoves <= 0) return 0;
    return (movesUsed / level.minMoves).clamp(0.0, 1.0);
  }

  /// Destinations the selected tube may pour into. Empty when nothing is held.
  ///
  /// Tubes NOT in this list dim to 40% — see `PourfectTokens`.
  List<int> get legalTargets => selectedTube == null
      ? const []
      : legalDestinationsFrom(board, selectedTube!);

  GameState copyWith({
    Board? board,
    List<Board>? undoStack,
    int? movesUsed,
    int? Function()? selectedTube,
    PourEvent? Function()? pour,
    Move? Function()? hintMove,
    bool? hintPending,
    int? hintsUsed,
    int? undosUsed,
    Duration? elapsedBefore,
    DateTime? Function()? runningSince,
    int? bankedSeconds,
  }) => GameState(
    level: level,
    levelSetVersion: levelSetVersion,
    board: board ?? this.board,
    undoStack: undoStack ?? this.undoStack,
    movesUsed: movesUsed ?? this.movesUsed,
    selectedTube: selectedTube == null ? this.selectedTube : selectedTube(),
    pour: pour == null ? this.pour : pour(),
    hintMove: hintMove == null ? this.hintMove : hintMove(),
    hintPending: hintPending ?? this.hintPending,
    hintsUsed: hintsUsed ?? this.hintsUsed,
    undosUsed: undosUsed ?? this.undosUsed,
    startedAt: startedAt,
    elapsedBefore: elapsedBefore ?? this.elapsedBefore,
    runningSince: runningSince == null ? this.runningSince : runningSince(),
    bankedSeconds: bankedSeconds ?? this.bankedSeconds,
    isRetry: isRetry,
  );
}

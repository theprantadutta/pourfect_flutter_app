/// Today's challenge: fetching it, playing it, submitting it.
///
/// The one feature here that genuinely needs a server. Boards are generated
/// backend-side from a seed that never ships to a device, because this repo is
/// public and generation is deterministic — shipping the pool would publish
/// every board for the next year alongside its proven optimal solution, and
/// the anti-cheat floor cannot tell an honest optimum from a looked-up one.
///
/// So "no network, no daily" is the correct behaviour rather than a gap to
/// paper over. What matters is that its absence costs nothing else: the
/// campaign never waits on this, and a failure here shows as a card that says
/// so rather than as an error anywhere near a level.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/api/api_result.dart';
import '../services/api/daily_api.dart';
import 'providers.dart';

@immutable
class DailyState {
  final DailyChallenge? challenge;

  /// The last submission's answer, for the completion card.
  final DailyResult? result;

  final bool loading;

  /// Why there is no challenge, when there is none. Null while all is well.
  final ApiFailureKind? failure;

  const DailyState({
    this.challenge,
    this.result,
    this.loading = false,
    this.failure,
  });

  /// True when a backend exists but today's board could not be had.
  bool get isUnavailable =>
      challenge == null &&
      failure != null &&
      failure != ApiFailureKind.notConfigured;

  /// True when this build has no backend at all, which is not a failure.
  bool get isOff => failure == ApiFailureKind.notConfigured;

  DailyState copyWith({
    DailyChallenge? challenge,
    DailyResult? result,
    bool? loading,
    ApiFailureKind? failure,
    bool clearFailure = false,
  }) => DailyState(
    challenge: challenge ?? this.challenge,
    result: result ?? this.result,
    loading: loading ?? this.loading,
    failure: clearFailure ? null : (failure ?? this.failure),
  );
}

class DailyController extends Notifier<DailyState> {
  Future<void>? _inFlight;

  @override
  DailyState build() => const DailyState();

  DailyApi get _api => DailyApi(ref.read(apiClientProvider));

  /// Fetches today's board if it is not already here.
  Future<void> ensureLoaded() {
    if (state.challenge != null) return Future.value();
    return refresh();
  }

  Future<void> refresh() {
    return _inFlight ??= _load().whenComplete(() => _inFlight = null);
  }

  Future<void> _load() async {
    if (await ref.read(authServiceProvider).ensureSession() == null) {
      state = const DailyState(failure: ApiFailureKind.notConfigured);
      return;
    }

    state = state.copyWith(loading: true, clearFailure: true);

    switch (await _api.today()) {
      case ApiOk(:final value):
        state = DailyState(challenge: value);
      case ApiFailure(:final kind):
        state = DailyState(loading: false, failure: kind);
        debugPrint('[daily] unavailable: $kind');
    }
  }

  /// Submits a solved board and keeps what the server says about it.
  ///
  /// The server recomputes the stars from the move count against its own
  /// optimum and never trusts a client-sent star count, so what comes back is
  /// the authority — including the streak and the rank, neither of which this
  /// device could work out.
  Future<ApiResult<DailyResult>> submit({
    required int movesUsed,
    required int durationSeconds,
  }) async {
    final challenge = state.challenge;
    if (challenge == null) {
      return const ApiFailure(
        ApiFailureKind.refused,
        detail: 'no challenge loaded',
      );
    }

    final result = await _api.submit(
      date: challenge.date,
      movesUsed: movesUsed,
      durationSeconds: durationSeconds,
    );

    if (result case ApiOk(:final value)) {
      state = state.copyWith(
        result: value,
        // The card the player is about to see should agree with the board
        // list they go back to.
        challenge: DailyChallenge(
          date: challenge.date,
          board: challenge.board,
          minMoves: challenge.minMoves,
          colorCount: challenge.colorCount,
          emptyTubeCount: challenge.emptyTubeCount,
          yourAttempt: DailyAttempt(
            moves: value.moves,
            stars: value.stars,
            durationSeconds: durationSeconds,
            completedAt: DateTime.now().toUtc(),
          ),
        ),
      );
    }

    return result;
  }
}

final dailyProvider = NotifierProvider<DailyController, DailyState>(
  DailyController.new,
);

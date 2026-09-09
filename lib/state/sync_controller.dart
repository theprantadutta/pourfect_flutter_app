/// When progress is pushed, and what happens when it cannot be.
///
/// THE RULE ABOVE ALL OTHERS: this never blocks play, never shows an error,
/// and never delays a level from opening. The campaign is bundled in the APK
/// and the progress a player can see is the progress on their own device. This
/// backs that up and lights up the leaderboards; a failure is silence.
///
/// The shape is deliberately simple, and the simplicity comes from the merge
/// being monotonic on both sides. Because neither side can ever move a result
/// backwards, a sync that is skipped, duplicated, delivered late or delivered
/// out of order all converge on the same answer — so there is no queue to
/// persist, no ordering to preserve, and no conflict to resolve. Re-sending
/// everything is always correct.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/api/api_result.dart';
import '../services/api/progress_api.dart';
import 'monetization_controller.dart';
import 'progress_repository.dart';
import 'providers.dart';

enum SyncStatus {
  /// No backend in this build, or no session. Not an error.
  off,

  idle,
  syncing,

  /// The last attempt could not reach the server. It will be retried.
  unreachable,
}

@immutable
class SyncState {
  final SyncStatus status;
  final DateTime? lastSucceededAt;

  /// Levels changed since the last successful push.
  final int pending;

  const SyncState({
    this.status = SyncStatus.off,
    this.lastSucceededAt,
    this.pending = 0,
  });

  SyncState copyWith({
    SyncStatus? status,
    DateTime? lastSucceededAt,
    int? pending,
  }) => SyncState(
    status: status ?? this.status,
    lastSucceededAt: lastSucceededAt ?? this.lastSucceededAt,
    pending: pending ?? this.pending,
  );
}

class SyncController extends Notifier<SyncState> {
  /// Levels whose local result has not been accepted by the server yet.
  final Set<int> _dirty = {};

  /// True until a full push has succeeded in this install.
  ///
  /// The first sync of a session sends EVERYTHING rather than only what
  /// changed. It is at most 150 rows of five integers, it is what reconciles a
  /// device that has been offline for a week, and it is the only thing that
  /// can recover a phone whose dirty set was lost with the process.
  bool _needsFullPush = true;

  Future<void>? _inFlight;

  @override
  SyncState build() => const SyncState();

  ProgressApi get _api => ProgressApi(ref.read(apiClientProvider));

  /// Marks a level as needing to reach the server.
  void markDirty(int levelId) {
    _dirty.add(levelId);
    state = state.copyWith(pending: _dirty.length);
  }

  /// Pushes and reconciles.
  ///
  /// Safe to call at any time and from anywhere: concurrent calls collapse
  /// into the one already running, and there is nothing to lose by calling it
  /// more often than necessary.
  Future<void> syncNow() {
    return _inFlight ??= _run().whenComplete(() => _inFlight = null);
  }

  Future<void> _run() async {
    final auth = ref.read(authServiceProvider);
    final session = await auth.ensureSession();
    if (session == null) {
      // No backend configured, no network at first launch, or Firebase never
      // initialised. All of them are ordinary and none of them is worth
      // telling the player about.
      state = state.copyWith(status: SyncStatus.off);
      return;
    }

    // The entitlement the server knows about, applied before anything else.
    // Somebody who paid and then reinstalled should be ad-free from the first
    // level rather than after their first purchase round trip.
    if (session.adsRemoved) {
      ref.read(monetizationProvider.notifier).applyServerEntitlement(true);
    }

    final progress = ref.read(progressProvider.notifier);

    // Waits for the LOCAL restore first. Pushing before it lands would send a
    // partial campaign, and while the server's merge would not lose anything,
    // the response would then be reconciled against a map that is still
    // filling in — a needless second round of writes on every launch.
    await progress.restored;

    final local = ref.read(progressProvider);
    final rows = _needsFullPush
        ? local.values.toList()
        : [for (final id in _dirty) ?local[id]];

    state = state.copyWith(status: SyncStatus.syncing);

    // An empty local campaign still syncs. A fresh install on a phone whose
    // owner already has progress has nothing to push and everything to pull,
    // and that is the case where sync matters most.
    final result = await _api.sync(rows);

    switch (result) {
      case ApiOk(:final value):
        progress.mergeFromServer(value.progress);
        _dirty.clear();
        _needsFullPush = false;
        state = SyncState(
          status: SyncStatus.idle,
          lastSucceededAt: DateTime.now(),
          pending: 0,
        );

        if (value.rejected > 0) {
          // Not shown to the player — there is nothing they can do — but never
          // swallowed either. A rejection means the server and the app
          // disagree about the campaign, which is a content problem worth
          // finding before it is a support thread.
          debugPrint(
            '[sync] server rejected ${value.rejected} of '
            '${value.accepted + value.rejected} rows',
          );
        }

      case ApiFailure(:final kind):
        // Nothing is discarded on failure. The dirty set stands and the full
        // push flag stands, so the next attempt carries everything this one
        // could not.
        state = state.copyWith(
          status: kind == ApiFailureKind.notConfigured
              ? SyncStatus.off
              : SyncStatus.unreachable,
        );
        debugPrint('[sync] failed: $kind');
    }
  }

  /// Pulls the server's view without pushing anything.
  ///
  /// For a fresh install, where there is nothing local worth sending and the
  /// question is only what the account already has.
  Future<bool> pullOnly() async {
    if (await ref.read(authServiceProvider).ensureSession() == null) {
      return false;
    }

    final result = await _api.snapshot();
    if (result case ApiOk(:final value)) {
      await ref.read(progressProvider.notifier).restored;
      return ref.read(progressProvider.notifier).mergeFromServer(value);
    }
    return false;
  }

  /// Forgets what this device believes the server has.
  ///
  /// Used after a progress reset, so the next sync is a full push rather than
  /// an empty one that would look like "nothing to say".
  void reset() {
    _dirty.clear();
    _needsFullPush = true;
    state = const SyncState();
  }
}

final syncControllerProvider = NotifierProvider<SyncController, SyncState>(
  SyncController.new,
);

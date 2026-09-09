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
import 'package:shared_preferences/shared_preferences.dart';

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

  /// True while a progress reset has not reached the server.
  ///
  /// Persisted, because the moment it protects against is a relaunch: without
  /// it, a reset performed offline is undone by the first sync of the next
  /// session, which is exactly the shape the defect had.
  static const _resetPendingKey = 'pourfect.sync.reset_pending';
  bool _resetPending = false;
  bool _restoredResetFlag = false;

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
    await _restoreResetFlag();

    // A RESET THAT HAS NOT LANDED BLOCKS EVERYTHING. Merging the server's
    // snapshot now would restore precisely what the player asked to erase, and
    // pushing an empty campaign says nothing the server can act on.
    if (_resetPending) {
      if (!await _deliverReset()) {
        state = state.copyWith(status: SyncStatus.unreachable);
        return;
      }

      // The pass ENDS here, even though the reset succeeded. A push and merge
      // in the same breath would reconcile against a snapshot the server
      // computed before the erase, putting back exactly what was just removed.
      // The next trigger — a level completion, an app resume — reconciles
      // against the empty campaign that now exists.
      state = state.copyWith(
        status: SyncStatus.idle,
        lastSucceededAt: DateTime.now(),
      );
      return;
    }

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
    //
    // Both directions, and they are not symmetric. A grant means somebody who
    // paid and then reinstalled is ad-free from the first level rather than
    // after their first purchase round trip. A revocation is acted on ONLY
    // when the session says the purchase was voided — a bare "not entitled" is
    // also what a pending purchase and a fresh install look like, and taking
    // the entitlement away on that would strip a paying player mid-session.
    if (session.adsRemoved) {
      await ref
          .read(monetizationProvider.notifier)
          .applyServerEntitlement(granted: true);
    } else if (session.adsRevoked) {
      await ref
          .read(monetizationProvider.notifier)
          .applyServerEntitlement(granted: false, revoked: true);
    }

    final progress = ref.read(progressProvider.notifier);

    // Waits for the LOCAL restore first. Pushing before it lands would send a
    // partial campaign, and while the server's merge would not lose anything,
    // the response would then be reconciled against a map that is still
    // filling in — a needless second round of writes on every launch.
    await progress.restored;

    final local = ref.read(progressProvider);

    // WHAT THIS REQUEST CARRIES, captured before the await.
    //
    // The acknowledgement below removes exactly these ids and nothing else. It
    // used to clear the whole dirty set on success, which quietly discarded
    // every level finished WHILE the request was in flight — their results
    // were never in the payload, so the server had not heard of them and now
    // nothing would tell it until a full push after a restart.
    final submitted = _needsFullPush ? local.keys.toSet() : {..._dirty};
    final submittedFullPush = _needsFullPush;

    final rows = [for (final id in submitted) ?local[id]];

    state = state.copyWith(status: SyncStatus.syncing);

    // An empty local campaign still syncs. A fresh install on a phone whose
    // owner already has progress has nothing to push and everything to pull,
    // and that is the case where sync matters most.
    final result = await _api.sync(rows);

    switch (result) {
      case ApiOk(:final value):
        progress.mergeFromServer(value.progress);

        // Only the submitted revisions are acknowledged. Anything that became
        // dirty during the request stays dirty and goes out next.
        _dirty.removeAll(submitted);
        if (submittedFullPush) _needsFullPush = false;

        state = SyncState(
          status: SyncStatus.idle,
          lastSucceededAt: DateTime.now(),
          pending: _dirty.length,
        );

        // Anything left dirty is carried by the NEXT trigger, which is never
        // far away: every level completion syncs, and so does every app
        // resume. What matters is that it is still there to carry — it used to
        // be cleared as though it had been submitted, and then nothing
        // mentioned it to the server until a full push after a restart.

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

  /// Reads the persisted flag once, and never over the top of a live one.
  ///
  /// The order matters: a reset performed a moment ago sets the flag in memory
  /// and writes it asynchronously, so a read that raced the write would find
  /// `false` and cheerfully merge the server's copy of everything the player
  /// had just erased.
  Future<void> _restoreResetFlag() async {
    if (_restoredResetFlag || _resetPending) return;
    _restoredResetFlag = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      _resetPending = prefs.getBool(_resetPendingKey) ?? false;
    } catch (_) {}
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

  /// Erases the campaign on the server as well as on this device.
  ///
  /// Local progress is already gone by the time this is called — the settings
  /// screen wipes it first so the screen behind the confirmation is honest
  /// immediately. What this adds is the half that used to be missing: the
  /// server still held every star, and the next sync merged them straight
  /// back. The confirmation said "erase every star and start from level 1"
  /// and the app undid it on the next app resume.
  ///
  /// **A reset that could not be delivered is remembered, and blocks merging
  /// until it lands.** Otherwise an offline reset is not a reset at all, it is
  /// a pause: the flag survives a relaunch precisely because that is when the
  /// old progress would otherwise come back.
  Future<bool> reset() async {
    _dirty.clear();
    _needsFullPush = true;
    _resetPending = true;
    // Nothing may read the persisted flag over the top of this one.
    _restoredResetFlag = true;
    await _persistResetPending(true);
    state = const SyncState();

    // Delivered through the ordinary sync path rather than inline, so there is
    // ONE place a reset reaches the server — the one that also knows to end
    // the pass rather than reconcile against a snapshot the server computed
    // before the erase.
    await syncNow();
    return !_resetPending;
  }

  /// Sends the reset, clearing the pending flag only if the server took it.
  Future<bool> _deliverReset() async {
    if (await ref.read(authServiceProvider).ensureSession() == null) {
      // No backend, or no session. A build with no server has nothing to
      // reset remotely and the local wipe is the whole action; the flag is
      // dropped so it does not block sync forever.
      if (!ref.read(apiClientProvider).isConfigured) {
        _resetPending = false;
        await _persistResetPending(false);
        return true;
      }
      return false;
    }

    final result = await _api.reset();
    if (result.isOk) {
      _resetPending = false;
      await _persistResetPending(false);
      return true;
    }

    debugPrint('[sync] reset not delivered; blocking merges until it is');
    return false;
  }

  Future<void> _persistResetPending(bool pending) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_resetPendingKey, pending);
    } catch (_) {}
  }
}

final syncControllerProvider = NotifierProvider<SyncController, SyncState>(
  SyncController.new,
);

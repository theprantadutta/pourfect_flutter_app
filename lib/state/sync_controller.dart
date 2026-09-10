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
  /// Level id to the revision at which it became dirty.
  final Map<int, int> _dirty = {};

  /// Bumped by anything that makes an outstanding response obsolete for a
  /// reason of our own — a reset, or adopting one from another device. The
  /// account side of the same question lives in AuthService.accountEpoch.
  int _epoch = 0;

  /// The reset the local campaign was recorded under.
  ///
  /// Sent with every push and compared by the server. A device that has been
  /// offline across a reset is still holding pre-reset progress; without this
  /// its next upload restores every star the player erased, which is exactly
  /// what the audit reproduced against PostgreSQL.
  static const _resetGenerationKey = 'pourfect.sync.reset_generation';
  int _resetGeneration = 0;

  /// Monotonic, process-local. Only ever compared for equality.
  int _revision = 0;

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

  /// Whose reset metadata is currently in memory, and whether any is.
  ///
  /// Null is a real account here — a build with no backend — so "loaded
  /// nothing yet" needs its own flag rather than being inferred from null.
  String? _loadedAccount;
  bool _loadedAny = false;

  @override
  SyncState build() => const SyncState();

  ProgressApi get _api => ProgressApi(ref.read(apiClientProvider));

  /// Marks a level as needing to reach the server.
  ///
  /// Records a REVISION, not just the id. A level improved while its previous
  /// result is in flight is dirty again at a higher revision, and the
  /// acknowledgement below only clears entries still sitting at the revision
  /// it actually sent — so the better run survives instead of being marked as
  /// delivered by a response that never carried it.
  void markDirty(int levelId) {
    _dirty[levelId] = ++_revision;
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

  /// Sends the whole campaign, not just what is marked dirty.
  ///
  /// For the moment somebody signs in. Linking preserves the uid, so this is
  /// the same server row and nothing needs migrating — but a player who has
  /// just asked for their progress to be saved deserves better than "it will
  /// go up next time you finish a level".
  Future<void> pushEverything() {
    _needsFullPush = true;
    return syncNow();
  }

  Future<void> _run() async {
    // Captured before anything awaits, and compared again before anything is
    // written. See [_supersededSince].
    final startedAt = _Stamp(
      account: ref.read(authServiceProvider).accountEpoch,
      local: _epoch,
    );

    // THE ACCOUNT IS RESOLVED BEFORE ITS METADATA IS READ.
    //
    // This used to be the other way round, and the order was the bug. On a
    // cold start AuthService has no session yet, so accountId was null, the
    // per-account preference keys resolved to their unscoped fallbacks, and a
    // one-shot "already restored" flag was set — permanently, for the wrong
    // account. A pending reset was never delivered and a stored generation was
    // never read, so the first sync of every launch uploaded generation 0 and
    // the server rejected legitimate progress as stale.
    final auth = ref.read(authServiceProvider);
    final session = await auth.ensureSession();

    if (session == null) {
      // No backend configured, no network at first launch, or Firebase never
      // initialised. All of them are ordinary and none of them is worth
      // telling the player about.
      //
      // A build with no server still has to finish a local reset, or the flag
      // blocks sync forever in an app that has nothing to sync with.
      if (!ref.read(apiClientProvider).isConfigured) {
        await _loadAccountState(null);
        if (_resetPending) await _deliverReset();
      }

      state = state.copyWith(status: SyncStatus.off);
      return;
    }

    await _loadAccountState(session.userId);
    if (_supersededSince(startedAt)) return;

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
    final ids = _needsFullPush ? local.keys.toSet() : _dirty.keys.toSet();

    // The revision each id was at when it went out. A null means the id was
    // not dirty at all (a full push sends everything), and anything that
    // becomes dirty during the request will therefore not match either.
    final submitted = <int, int?>{for (final id in ids) id: _dirty[id]};
    final submittedFullPush = _needsFullPush;

    final rows = [for (final id in ids) ?local[id]];

    state = state.copyWith(status: SyncStatus.syncing);

    // An empty local campaign still syncs. A fresh install on a phone whose
    // owner already has progress has nothing to push and everything to pull,
    // and that is the case where sync matters most.
    final result = await _api.sync(rows, resetGeneration: _resetGeneration);

    // THE ANSWER MAY NO LONGER BE ABOUT US.
    //
    // Everything below writes into the local campaign, and this request was
    // issued for a particular account under a particular reset. If the player
    // signed out, switched account, deleted the account or reset their
    // progress while it was in flight, this snapshot describes a world that
    // no longer exists — merging it puts back exactly what was just erased.
    // All three were reproduced.
    if (_supersededSince(startedAt)) {
      debugPrint('[sync] discarded a response for a superseded account/reset');
      return;
    }

    switch (result) {
      case ApiOk(:final value):
        // Another device reset this account while we were away. Our campaign
        // is a pre-reset copy, and re-uploading it is exactly how erased
        // progress comes back — so the reset is adopted here instead.
        if (value.resetGeneration > _resetGeneration) {
          // The owner is the account this whole pass was for, captured before
          // any of it awaited.
          await _adoptRemoteReset(
            value.resetGeneration,
            value.progress,
            session.userId,
          );
          return;
        }

        progress.mergeFromServer(value.progress);

        // Only the submitted REVISIONS are acknowledged. A level whose
        // revision moved while the request was in flight is a different
        // result from the one the server just took, so it stays dirty.
        submitted.forEach((id, revision) {
          if (_dirty[id] == revision) _dirty.remove(id);
        });
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

  /// True when the account or the local campaign moved on since [stamp].
  bool _supersededSince(_Stamp stamp) =>
      ref.read(authServiceProvider).accountEpoch != stamp.account ||
      _epoch != stamp.local;

  /// Invalidates every response still in flight.
  ///
  /// Called by anything that erases or replaces the local campaign. The
  /// requests themselves cannot be cancelled — they are already with the
  /// server — so what changes is that their answers are dropped on arrival.
  void invalidateInFlight() => _epoch++;

  /// Takes on a reset performed somewhere else.
  ///
  /// The local campaign predates it, so keeping it and pushing would undo
  /// somebody's reset from the other device. Erasing is the honest reading of
  /// what they asked for: the account was reset, and this device is part of
  /// the account.
  /// Takes on a reset performed somewhere else, for ONE account.
  ///
  /// Every step here writes: a preference, the whole local campaign, then the
  /// server's rows. That is three awaits, and the account can change across
  /// any of them — the reproduction switches accounts while the erase is
  /// mid-save, and the merge afterwards put account A's level 1 into account
  /// B, which then uploaded it under B's token.
  ///
  /// So [owner] is captured by the caller and everything is measured against
  /// it: the preference key comes from the owner rather than from mutable
  /// shared state read after an await, and each mutation is preceded by a
  /// check that this adoption is still the current one.
  Future<void> _adoptRemoteReset(
    int generation,
    List<LevelProgress> serverRows,
    String? owner,
  ) async {
    debugPrint('[sync] adopting reset generation $generation from the server');

    // Supersedes everything already in flight — including, deliberately, any
    // other adoption. The stamp is taken AFTER, so this one does not read as
    // superseded by its own increment.
    _epoch++;
    final mine = _Stamp(
      account: ref.read(authServiceProvider).accountEpoch,
      local: _epoch,
    );

    await _persistResetGeneration(generation, owner);
    if (_supersededSince(mine)) {
      debugPrint('[sync] abandoned an adoption for a superseded account');
      return;
    }

    _dirty.clear();
    _needsFullPush = false;
    _resetGeneration = generation;

    final progress = ref.read(progressProvider.notifier);
    await progress.resetAll();

    // Re-checked before the merge. The erase is safe to have happened either
    // way — the switch wipes local progress too — but the MERGE is not: these
    // rows belong to the account this adoption started for.
    if (_supersededSince(mine)) {
      debugPrint('[sync] not merging an adoption into a different account');
      return;
    }

    // THEN TAKE WHAT THE SERVER ACTUALLY HAS.
    //
    // Erasing was only half of it. The rows in this very response were
    // recorded under the NEW generation — they are play that happened after
    // the reset, on some other device — and dropping them left the player
    // staring at an empty campaign they had just filled. It came back on the
    // next sync, so it was temporary, but "temporary" here means a player
    // opening the app to find their progress gone.
    //
    // The same response, so the rows and the generation are consistent with
    // each other; a separate pull could straddle another change.
    if (serverRows.isNotEmpty) {
      progress.mergeFromServer(serverRows);
    }

    state = SyncState(status: SyncStatus.idle, lastSucceededAt: DateTime.now());
  }

  /// Writes under [owner]'s key, not whoever happens to be signed in now.
  ///
  /// `_loadedAccount` is mutable shared state and a switch rewrites it, so
  /// reading it after an await stores one account's generation against
  /// another's name.
  Future<void> _persistResetGeneration(int generation, String? owner) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_keyFor(_resetGenerationKey, owner), generation);
    } catch (_) {}
  }


  /// Loads the reset metadata belonging to [accountId].
  ///
  /// Once per ACCOUNT, not once per controller. Namespacing the preference
  /// keys was not enough on its own: `_resetPending`, `_resetGeneration` and
  /// the restored flag all lived in one controller that outlives a sign-out,
  /// so account A's undelivered reset stayed in memory and the next sync
  /// delivered it against account B's token — reproduced through the real
  /// switching path, with B receiving a destructive reset nobody asked for.
  ///
  /// A reset that could not be delivered stays on disk under A's key, so it is
  /// still waiting when A signs back in.
  Future<void> _loadAccountState(String? accountId) async {
    if (_loadedAccount == accountId && _loadedAny) return;

    _loadedAccount = accountId;
    _loadedAny = true;

    // Cleared before the read, so a failure to read cannot leave the previous
    // account's values standing.
    _resetPending = false;
    _resetGeneration = 0;

    try {
      final prefs = await SharedPreferences.getInstance();
      _resetPending =
          prefs.getBool(_keyFor(_resetPendingKey, accountId)) ?? false;
      _resetGeneration =
          prefs.getInt(_keyFor(_resetGenerationKey, accountId)) ?? 0;

      // A RESET MADE BEFORE THIS DEVICE KNEW WHOSE IT WAS.
      //
      // Reset offline on a launch that never managed to authenticate: there
      // was no account to file it under, so it went to the unscoped key. It
      // still has to happen. The first account to resolve on this device IS
      // the account that asked for it — nobody else has been here — so it is
      // adopted, and CLEARED as part of adopting, which is what stops a later
      // account inheriting somebody else's erase.
      if (!_resetPending &&
          accountId != null &&
          (prefs.getBool(_resetPendingKey) ?? false)) {
        debugPrint('[sync] adopting an unowned pending reset for $accountId');

        _resetPending = true;
        await prefs.setBool(_keyFor(_resetPendingKey, accountId), true);
        await prefs.remove(_resetPendingKey);
      }
    } catch (_) {}
  }

  /// Forgets which account's metadata is loaded, so the next pass reloads.
  void forgetAccountState() {
    _loadedAccount = null;
    _loadedAny = false;
    _resetPending = false;
    _resetGeneration = 0;
  }

  static String _keyFor(String base, String? accountId) =>
      accountId == null ? base : '$base.$accountId';

  /// Pulls the server's view without pushing anything.
  ///
  /// For a fresh install, where there is nothing local worth sending and the
  /// question is only what the account already has.
  Future<bool> pullOnly() async {
    // The same stamp the push path takes, for the same reason. This writes
    // into the local campaign too, and it is now on the account-switch path,
    // so it is at least as exposed: holding a progress GET, deleting the
    // account, then releasing it put the deleted campaign straight back.
    final startedAt = _Stamp(
      account: ref.read(authServiceProvider).accountEpoch,
      local: _epoch,
    );

    if (await ref.read(authServiceProvider).ensureSession() == null) {
      return false;
    }
    if (_supersededSince(startedAt)) return false;

    final result = await _api.snapshot();
    if (_supersededSince(startedAt)) {
      debugPrint('[sync] discarded a pull for a superseded account/reset');
      return false;
    }

    if (result case ApiOk(:final value)) {
      await ref.read(progressProvider.notifier).restored;

      // Re-checked after the restore, which is its own await and its own
      // chance for the account to have gone.
      if (_supersededSince(startedAt)) return false;

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
    // WHOSE reset this is, resolved before the flag is set. A reset recorded
    // against the wrong account is delivered against the wrong account.
    //
    // From the KNOWN identity, not from a usable session. Offline with an
    // expired login, `ensureSession` returns null while the account is not in
    // the slightest doubt — and treating that as "no account" filed the reset
    // under the unscoped key, so it was dropped as soon as the real account's
    // metadata loaded and every erased star came back.
    final owner = await ref.read(authServiceProvider).knownAccountId();

    _dirty.clear();
    _needsFullPush = true;
    _resetPending = true;

    // Claim ownership so nothing reloads over the top of a flag set a moment
    // ago and still being written.
    _loadedAccount = owner;
    _loadedAny = true;

    await _persistResetPending(true);
    state = const SyncState();

    // EVERY RESPONSE STILL IN FLIGHT IS NOW OBSOLETE. Each was computed by the
    // server before the erase, so merging one restores what was just deleted.
    // Reproduced: hold a sync response, reset, release it, and every star is
    // back.
    invalidateInFlight();

    // Waits for the running pass rather than JOINING it. `syncNow` collapses
    // concurrent callers into whatever is already going, and what is already
    // going was started before the reset existed — so it would neither deliver
    // the reset nor be allowed to merge. The reset needs a pass of its own.
    final running = _inFlight;
    if (running != null) {
      await running;
    }

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

    // WHOSE reset is this, and is that still who we are?
    //
    // A reset is destructive and unauthenticated by nothing but the bearer
    // token attached to it. Delivering account A's undelivered reset with
    // account B's token erases a campaign nobody asked to erase, which is
    // exactly what the switching reproduction showed.
    final owner = _loadedAccount;
    final current = await ref.read(authServiceProvider).knownAccountId();

    if (owner != current) {
      debugPrint('[sync] not delivering a reset owned by another account');
      return false;
    }

    final result = await _api.reset();

    // Re-checked after the await. The answer is here; the player may not be.
    if (ref.read(authServiceProvider).accountId != owner) {
      debugPrint('[sync] discarded a reset answer for a superseded account');
      return false;
    }

    if (result case ApiOk(:final value)) {
      _resetPending = false;
      // Adopt the generation the reset created. Every later upload carries it,
      // so a device still on the old one cannot put the erased stars back.
      _resetGeneration = value;
      await _persistResetPending(false);
      await _persistResetGeneration(value, owner);
      return true;
    }

    debugPrint('[sync] reset not delivered; blocking merges until it is');
    return false;
  }

  Future<void> _persistResetPending(bool pending) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyFor(_resetPendingKey, _loadedAccount), pending);
    } catch (_) {}
  }
}

final syncControllerProvider = NotifierProvider<SyncController, SyncState>(
  SyncController.new,
);

/// What the account and the local campaign looked like when a pass began.
@immutable
class _Stamp {
  const _Stamp({required this.account, required this.local});

  final int account;
  final int local;
}

/// Signing in, signing out, and deleting the account.
///
/// The identity operations themselves live in [Identity]; what this adds is
/// everything that has to happen AROUND them, and that is where the bugs are:
///
/// **A changed identity means a changed token, so the session is re-exchanged
/// immediately.** Our backend learns that somebody signed in only from the
/// `sign_in_provider` claim in the next token it sees. Without a forced
/// re-exchange the server would go on believing the account is anonymous — the
/// row would say so, `is_anonymous` in the session would say so, and the UI
/// would keep offering a sign-in the player has already done.
///
/// **A sign-in is followed by a full sync push.** The uid is preserved by
/// linking, so the server row is the same row and nothing needs migrating —
/// but the player just told us their progress matters, and the honest response
/// is to make sure it is actually up there rather than waiting for the next
/// level completion.
///
/// **Deletion goes to the server FIRST.** The database is the act of record.
/// If Firebase deletion fails afterwards the data is already gone and the
/// worst case is an orphaned login that provisions a fresh empty account. The
/// other order risks destroying the login while the row survives, leaving
/// somebody unable to reach or delete their own data — which is the thing the
/// endpoint exists to guarantee.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/api/api_result.dart';
import '../services/api/identity.dart';
import 'play_history.dart';
import 'progress_repository.dart';
import 'providers.dart';
import 'sync_controller.dart';

@immutable
class AccountState {
  const AccountState({
    this.busy = false,
    this.signedIn = false,
    this.email,
    this.available = false,
    this.userId,
    this.handle,
    this.showOnLeaderboards = true,
  });

  /// An identity operation is in flight. The UI disables its buttons on this
  /// rather than tracking its own flag, so two taps cannot start two sign-ins.
  final bool busy;

  /// True once the account is no longer anonymous.
  final bool signedIn;

  final String? email;

  /// False in a build with no Firebase, where the whole section is hidden
  /// rather than shown broken.
  final bool available;

  /// The leaderboard handle, or null before the session has loaded.
  ///
  /// Every account has one from the moment the server creates it, so a null
  /// here means "not known yet", never "has no name".
  final String? handle;

  /// Whether this player is published on leaderboards.
  ///
  /// Defaults TRUE to match the server's column, so the switch does not flick
  /// from off to on as the session lands.
  final bool showOnLeaderboards;

  /// The account the session belongs to, or null before one is known.
  ///
  /// Here rather than read off `AuthService.current` at the point of use: the
  /// service is behind a plain Provider and cannot tell a widget it changed,
  /// so every screen that read it drew whatever happened to be in memory
  /// during its first build and never corrected itself. Screens watch this.
  final String? userId;

  AccountState copyWith({
    bool? busy,
    bool? signedIn,
    String? email,
    bool? available,
    String? userId,
    String? handle,
    bool? showOnLeaderboards,
  }) => AccountState(
    busy: busy ?? this.busy,
    signedIn: signedIn ?? this.signedIn,
    email: email ?? this.email,
    available: available ?? this.available,
    userId: userId ?? this.userId,
    handle: handle ?? this.handle,
    showOnLeaderboards: showOnLeaderboards ?? this.showOnLeaderboards,
  );
}

class AccountController extends Notifier<AccountState> {
  @override
  AccountState build() {
    final identity = ref.read(identityProvider);
    final auth = ref.read(authServiceProvider);
    final snapshot = identity.current;

    // Registered FIRST, so it is set before the cancellations below run.
    // Both sources here outlive this controller — a ValueNotifier on a service
    // and a disk read already in flight — and writing `state` after disposal
    // is an error Riverpod throws rather than ignores.
    var gone = false;
    ref.onDispose(() => gone = true);

    // WATCHED, NOT SAMPLED — both of them.
    //
    // This used to read `identity.current` once and keep the answer forever.
    // Firebase restores its user asynchronously while the first frame is
    // already on screen, so on a cold start the sample is null, `signedIn` was
    // false, and nothing ever said otherwise. A player who had signed in with
    // Google reopened the app and was shown as a guest — "my account is gone
    // after the app restarted" — while the credential and the session sat
    // intact on the device.
    final identitySub = identity.changes.listen((snapshot) {
      if (gone) return;
      state = state.copyWith(
        signedIn: snapshot != null && !snapshot.isAnonymous,
        email: snapshot?.email,
      );
    });
    ref.onDispose(identitySub.cancel);

    void adoptSession() {
      if (gone) return;
      final session = auth.sessions.value;
      if (session == null) return;

      state = state.copyWith(
        userId: session.userId,
        handle: session.displayName,
        showOnLeaderboards: session.showOnLeaderboards,
        // PROMOTES ONLY. The server's `is_anonymous` is authoritative about
        // being signed IN, but a session can lag behind a sign-in it has not
        // been re-exchanged for yet, and demoting on that would flicker the
        // UI back to guest between the sign-in and its refresh. Signing out
        // and deletion clear the whole state explicitly, and the identity
        // stream above is what reports a genuine drop.
        signedIn: session.isAnonymous ? null : true,
      );
    }

    auth.sessions.addListener(adoptSession);
    ref.onDispose(() => auth.sessions.removeListener(adoptSession));

    // THE SESSION IS ON DISK AND NOTHING WAS READING IT. `ensureSession` only
    // ran when a sync happened to start, which is a Firebase round trip away,
    // so the identity on screen was blank for the first seconds of every
    // launch and stale for the rest of it. This is a local file read.
    auth.restore().then((_) => adoptSession());

    return AccountState(
      available: identity.isReady,
      signedIn: snapshot != null && !snapshot.isAnonymous,
      email: snapshot?.email,
      userId: auth.current?.userId,
      handle: auth.current?.displayName,
      showOnLeaderboards: auth.current?.showOnLeaderboards ?? true,
    );
  }

  /// Renames the leaderboard handle.
  ///
  /// The session is updated from the SERVER's answer rather than from what was
  /// typed, because the server trims and could in principle refuse — and the
  /// name on screen afterwards should be the name on the board.
  Future<String?> renameHandle(String name) async {
    final result = await ref.read(usersApiProvider).setDisplayName(name);

    return switch (result) {
      ApiOk(:final value) => await () async {
        await ref.read(authServiceProvider).update(displayName: value);
        state = state.copyWith(handle: value);
        return null;
      }(),
      ApiFailure(:final kind, :final detail) => kind == ApiFailureKind.refused
          ? (detail ?? 'That name was not accepted.')
          : 'Could not reach the server. Try again in a moment.',
    };
  }

  /// Puts the player on the public boards, or takes them off.
  ///
  /// **Nothing is assumed.** The switch moves only once the server has
  /// confirmed, and a failure leaves it exactly where it was. Drawing it in
  /// the new position on a request that never landed tells somebody they are
  /// hidden while they are still listed, which is the single worst thing a
  /// control like this can do.
  Future<bool> setLeaderboardVisibility(bool visible) async {
    final result =
        await ref.read(usersApiProvider).setLeaderboardVisibility(visible);

    if (result case ApiOk(:final value)) {
      await ref.read(authServiceProvider).update(showOnLeaderboards: value);
      state = state.copyWith(showOnLeaderboards: value);
      return true;
    }
    return false;
  }

  Future<IdentityResult> continueWithGoogle() =>
      _run((identity) => identity.continueWithGoogle());

  Future<IdentityResult> createAccount(String email, String password) =>
      _run((identity) => identity.createWithEmail(email.trim(), password));

  Future<IdentityResult> signIn(String email, String password) =>
      _run((identity) => identity.signInWithEmail(email.trim(), password));

  /// Always reports success to the caller.
  ///
  /// "No account with that address" is exactly the answer a stranger probing
  /// for registered emails wants, so the screen says the same thing either way
  /// and only the log distinguishes them.
  Future<IdentityResult> sendPasswordReset(String email) async {
    final identity = ref.read(identityProvider);
    final result = await identity.sendPasswordReset(email.trim());

    if (!result.isOk) {
      debugPrint('[account] password reset: ${result.outcome}');
    }
    return const IdentityResult.ok();
  }

  /// Runs an identity operation, then makes the rest of the app agree with it.
  Future<IdentityResult> _run(
    Future<IdentityResult> Function(Identity) operation,
  ) async {
    if (state.busy) {
      // A second tap while the first is still going would start a second
      // Firebase flow and race the session re-exchange below.
      return const IdentityResult(IdentityOutcome.unavailable);
    }

    state = state.copyWith(busy: true);
    try {
      final identity = ref.read(identityProvider);

      // Captured BEFORE, because what happens afterwards depends entirely on
      // whether this was a link or a switch, and only the uid can say.
      final before = identity.current?.uid;

      final result = await operation(identity);
      if (!result.isOk) return result;

      return await _adoptCurrentIdentity(previousUid: before);
    } finally {
      state = state.copyWith(busy: false);
    }
  }

  /// Makes the session, the server and the UI agree with the identity.
  ///
  /// **Linking and switching are different operations and this is where the
  /// difference lives.** Linking a credential to the anonymous account keeps
  /// the uid, so the existing session is still about the right player and only
  /// needs refreshing to carry the new provider. Signing into an account that
  /// already exists REPLACES the uid, and then the cached session belongs to
  /// somebody else — reusing its token writes one player's progress into
  /// another player's row. Reproduced: sign in as a second account, fail the
  /// exchange, and the next write still carried `Bearer jwt-uid-1`.
  Future<IdentityResult> _adoptCurrentIdentity({String? previousUid}) async {
    final identity = ref.read(identityProvider);
    final snapshot = identity.current;
    final auth = ref.read(authServiceProvider);

    final switched = previousUid != null &&
        snapshot != null &&
        snapshot.uid != previousUid;

    if (switched) {
      // No token, no session, new epoch — before anything can be sent. Every
      // response still in flight for the old account is now discarded rather
      // than merged into this one.
      await auth.abandonAccount();

      final sync = ref.read(syncControllerProvider.notifier);
      sync.invalidateInFlight();
      // The previous account's reset metadata must not stay in memory. Its
      // preference keys are scoped, but the controller outlives the account,
      // and an undelivered reset left in these fields is delivered against
      // whoever signs in next.
      sync.forgetAccountState();
      await ref.read(progressProvider.notifier).resetAll();
    }

    state = state.copyWith(
      signedIn: snapshot != null && !snapshot.isAnonymous,
      email: snapshot?.email,
    );

    // FORCED. The cached session still looks fresh — it has not expired, it is
    // simply describing a player who no longer exists in the same form. Only a
    // new token carries the new sign_in_provider.
    final session = await auth.ensureSession(forceRefresh: true);

    if (session == null) {
      // NOTHING IS SYNCED. The identity changed and we could not get a session
      // for it; pushing now would either use no token at all or, worse, the
      // previous account's. The Firebase sign-in itself stands, so the next
      // ordinary trigger will try the exchange again.
      debugPrint('[account] signed in, but no session yet; not syncing');
      return const IdentityResult(IdentityOutcome.sessionUnavailable);
    }

    if (switched) {
      // The local campaign was erased above, so there is nothing to push and
      // everything to pull: this device now belongs to a different player.
      await ref.read(syncControllerProvider.notifier).pullOnly();
      return const IdentityResult.ok();
    }

    // The uid did not change, so this is the same server row and there is
    // nothing to migrate. It is a push because somebody who has just signed in
    // has said their progress matters, and "it will go up next time you finish
    // a level" is not a good enough answer to that.
    await ref.read(syncControllerProvider.notifier).pushEverything();
    return const IdentityResult.ok();
  }

  /// Signs into the account a credential already belongs to.
  ///
  /// The other half of [IdentityOutcome.credentialBelongsToAnotherAccount],
  /// and the reason that outcome is not a dead end. Firebase cannot merge two
  /// uids, so this ABANDONS whatever the anonymous account had on this device
  /// and adopts the existing one instead — which is why it is a separate call
  /// that the screen only makes after saying so.
  Future<IdentityResult> useExistingGoogleAccount() =>
      _run((identity) => identity.signInToExistingGoogleAccount());

  /// Deletes the account: the server row first, then the Firebase identity.
  ///
  /// The order is the whole point. The database is the act of record, so if
  /// the Firebase delete fails afterwards the personal data is already gone
  /// and the worst case is an orphaned login that provisions a fresh empty
  /// account on next launch. Reversed, a failure would destroy the login while
  /// the row survived — leaving somebody permanently unable to reach or delete
  /// their own data, which is precisely what this exists to prevent.
  ///
  /// Local progress is wiped too. Somebody asking to be deleted does not mean
  /// "delete the copy on the server but keep the one on my phone".
  Future<AccountDeletion> deleteAccount() async {
    if (state.busy) return AccountDeletion.busy;
    state = state.copyWith(busy: true);

    try {
      final client = ref.read(apiClientProvider);
      final session = await ref.read(authServiceProvider).ensureSession();

      if (session == null) {
        // NO SESSION IS NOT NO ACCOUNT.
        //
        // An expired session with Firebase unreachable looks identical to
        // having nothing on the server, and this used to wipe locally, sign
        // out and report success — destroying the very credentials needed to
        // retry, while the account and everything in it stayed on the server.
        // The one case where there is genuinely nothing to delete is a build
        // with no backend at all.
        if (!client.isConfigured) {
          await _wipeLocally();
          return AccountDeletion.deleted;
        }

        debugPrint('[account] deletion needs a session; keeping credentials');
        return AccountDeletion.notAuthenticated;
      }

      final result = await ref.read(usersApiProvider).deleteAccount();
      if (!result.isOk) {
        debugPrint('[account] server deletion refused');
        return AccountDeletion.serverRefused;
      }

      // The row is gone. Anything still in flight for it describes an account
      // that no longer exists, and merging one puts the deleted progress
      // straight back — reproduced by holding a sync response across the
      // delete.
      ref.read(syncControllerProvider.notifier).invalidateInFlight();

      final removed = await ref.read(identityProvider).deleteAccount();

      // EXPECTED, not a failure. `DeleteAccountCommandHandler` removes the
      // Firebase user itself once the row is gone, so by the time this runs
      // there is usually nothing left to delete and Firebase says so. The
      // client asks anyway — belt and braces, because the server's call is
      // best-effort and logs a warning when it fails — but the outcome is a
      // deletion that already happened, not one that went wrong. Confirmed on
      // device: `[identity] user-not-found -> IdentityOutcome.noSuchAccount`
      // on a delete that completed perfectly.
      if (removed.outcome == IdentityOutcome.noSuchAccount) {
        await _wipeLocally();
        return AccountDeletion.deleted;
      }

      if (removed.outcome == IdentityOutcome.needsRecentLogin) {
        // The row is already gone, so this is not a failure of the deletion —
        // it is a leftover login. Signing out detaches it; it can never reach
        // the deleted row again, and the next launch provisions a fresh one.
        await _wipeLocally();
        return AccountDeletion.deleted;
      }

      await _wipeLocally();
      return AccountDeletion.deleted;
    } finally {
      state = state.copyWith(busy: false);
    }
  }

  Future<void> _wipeLocally() async {
    // Ordered: invalidate first, so nothing that lands during the wipe is
    // still considered current.
    ref.read(syncControllerProvider.notifier).invalidateInFlight();

    await ref.read(identityProvider).signOut();
    await ref.read(authServiceProvider).forget();
    await ref.read(progressProvider.notifier).resetAll();

    // The campaign is not the only thing keyed to the account. A streak and a
    // best-times history left standing behind a deleted account is a
    // statistics screen describing somebody who asked to be forgotten.
    await ref.read(playHistoryProvider.notifier).resetAll();

    state = const AccountState(available: true);
  }

  /// Signs out, returning the app to an anonymous account.
  ///
  /// The local campaign is untouched — it lives on the device and belongs to
  /// whoever is holding the phone. What changes is which server row it syncs
  /// into next, and because the merge is monotonic, pushing local progress
  /// into a fresh anonymous row cannot take anything away from anybody.
  Future<void> signOut() async {
    if (state.busy) return;
    state = state.copyWith(busy: true);

    try {
      await ref.read(identityProvider).signOut();
      await ref.read(authServiceProvider).forget();

      state = const AccountState(available: true);

      // Re-anchors on a new anonymous account straight away, rather than
      // leaving the app sessionless until something happens to need one.
      await ref.read(authServiceProvider).ensureSession(forceRefresh: true);
    } finally {
      state = state.copyWith(busy: false);
    }
  }
}

/// How a deletion attempt ended.
enum AccountDeletion {
  deleted,

  /// The server was reached and refused. Retryable.
  serverRefused,

  /// There was no session to delete with, and the account was NOT touched.
  /// Distinct from [serverRefused] because the fix is different: sign in
  /// again rather than wait for the network.
  notAuthenticated,

  busy,
}

final accountProvider = NotifierProvider<AccountController, AccountState>(
  AccountController.new,
);

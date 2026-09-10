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

import '../services/api/identity.dart';
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

  AccountState copyWith({
    bool? busy,
    bool? signedIn,
    String? email,
    bool? available,
  }) => AccountState(
    busy: busy ?? this.busy,
    signedIn: signedIn ?? this.signedIn,
    email: email ?? this.email,
    available: available ?? this.available,
  );
}

class AccountController extends Notifier<AccountState> {
  @override
  AccountState build() {
    final identity = ref.read(identityProvider);
    final snapshot = identity.current;

    return AccountState(
      available: identity.isReady,
      signedIn: snapshot != null && !snapshot.isAnonymous,
      email: snapshot?.email,
    );
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
      final result = await operation(identity);
      if (!result.isOk) return result;

      await _adoptCurrentIdentity();
      return result;
    } finally {
      state = state.copyWith(busy: false);
    }
  }

  /// Re-exchanges the session and pushes, so the server and the UI agree.
  Future<void> _adoptCurrentIdentity() async {
    final identity = ref.read(identityProvider);
    final snapshot = identity.current;

    state = state.copyWith(
      signedIn: snapshot != null && !snapshot.isAnonymous,
      email: snapshot?.email,
    );

    // FORCED. The cached session still looks fresh — it has not expired, it is
    // simply describing a player who no longer exists in the same form. Only a
    // new token carries the new sign_in_provider.
    await ref.read(authServiceProvider).ensureSession(forceRefresh: true);

    // The uid did not change, so this is the same server row and there is
    // nothing to migrate. It is a push because somebody who has just signed in
    // has said their progress matters, and "it will go up next time you finish
    // a level" is not a good enough answer to that.
    await ref.read(syncControllerProvider.notifier).pushEverything();
  }

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
      final session = await ref.read(authServiceProvider).ensureSession();
      if (session == null) {
        // No session means nothing of theirs is on the server to delete. The
        // local wipe below is then the whole of it, and reporting failure
        // would strand somebody with no way to finish.
        await _wipeLocally();
        return AccountDeletion.deleted;
      }

      final result = await ref.read(usersApiProvider).deleteAccount();
      if (!result.isOk) {
        debugPrint('[account] server deletion refused');
        return AccountDeletion.serverRefused;
      }

      final removed = await ref.read(identityProvider).deleteAccount();
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
    await ref.read(identityProvider).signOut();
    await ref.read(authServiceProvider).forget();
    await ref.read(progressProvider.notifier).resetAll();
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
enum AccountDeletion { deleted, serverRefused, busy }

final accountProvider = NotifierProvider<AccountController, AccountState>(
  AccountController.new,
);

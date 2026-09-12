/// The Firebase identity behind a session, and the ways it can change.
///
/// Separate from [AuthService] on purpose. That one owns the exchange with our
/// own backend — a token in, a session out. This owns who the player IS to
/// Firebase, which is a different question with entirely different failure
/// modes, and the only part that needs a real Firebase project to run.
///
/// **Signing in is an UPGRADE, never a migration.** Firebase keeps the same
/// uid when an anonymous account links a credential, so the server row, the
/// stars hanging off it and the leaderboard name all survive untouched. That
/// is the whole reason the game can start anonymous with no sign-in wall and
/// still offer real accounts later.
///
/// **The exception is the one that loses progress**, and it has to be named
/// rather than swallowed: linking fails with `credential-already-in-use` when
/// the Google account or email already belongs to a different Firebase user.
/// There is no merge — Firebase cannot combine two uids — so the only way
/// forward is to sign in to the existing account and abandon what the
/// anonymous one had. That is a decision for the player, so it surfaces as
/// [IdentityOutcome.credentialBelongsToAnotherAccount] rather than being
/// retried quietly.
library;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../analytics/analytics_service.dart' show firebaseReady;
import 'app_env.dart';

/// How an identity operation ended.
enum IdentityOutcome {
  ok,

  /// The player backed out of the Google sheet. Not an error, and must never
  /// be shown as one.
  cancelled,

  /// The credential is already a different Firebase account. Continuing means
  /// abandoning the progress on the current anonymous one.
  credentialBelongsToAnotherAccount,

  /// Email/password specifics, each of which needs its own sentence in the UI.
  emailAlreadyInUse,
  emailMalformed,
  passwordTooWeak,
  wrongPassword,
  noSuchAccount,
  tooManyAttempts,

  /// Firebase wants a fresh sign-in before it will do something destructive.
  needsRecentLogin,

  /// Firebase accepted the sign-in but our own backend would not issue a
  /// session for it. The identity stands; the sync does not.
  sessionUnavailable,

  /// Offline, or Firebase itself is unhappy.
  unavailable,
}

/// The result of an identity operation.
@immutable
class IdentityResult {
  const IdentityResult(this.outcome, {this.message});

  const IdentityResult.ok() : outcome = IdentityOutcome.ok, message = null;

  final IdentityOutcome outcome;

  /// Firebase's own message, for the log. Never shown to a player — the UI
  /// maps [outcome] to its own wording.
  final String? message;

  bool get isOk => outcome == IdentityOutcome.ok;
}

/// Who the player currently is.
@immutable
class IdentitySnapshot {
  const IdentitySnapshot({
    required this.uid,
    required this.isAnonymous,
    this.email,
    this.displayName,
  });

  final String uid;
  final bool isAnonymous;
  final String? email;
  final String? displayName;
}

/// The seam. Everything above the service talks to this, so the whole account
/// flow is testable without a Firebase project, an emulator or a network.
abstract class Identity {
  /// False when Firebase never initialised — a build with no configuration.
  bool get isReady;

  IdentitySnapshot? get current;

  /// Fires whenever the signed-in user changes, INCLUDING the restore that
  /// Firebase performs shortly after launch.
  ///
  /// [current] is a sample, and a sample taken during startup is taken too
  /// early. Anything that has to keep agreeing with the identity listens here
  /// instead of asking once.
  Stream<IdentitySnapshot?> get changes;

  /// Links Google to the current anonymous account, or signs in with it.
  Future<IdentityResult> continueWithGoogle();

  /// Signs into the Google account a credential already belongs to.
  ///
  /// On the interface, not just the concrete class, because
  /// [IdentityOutcome.credentialBelongsToAnotherAccount] is otherwise a dead
  /// end: it used to be reachable only by a method nothing could call, so the
  /// ordinary returning player on a new phone was told what had happened and
  /// given no way through it. **Abandons the anonymous account's progress** —
  /// Firebase cannot merge two uids — so callers must say so first.
  Future<IdentityResult> signInToExistingGoogleAccount();

  /// Creates an email account, linking it to the current anonymous one.
  Future<IdentityResult> createWithEmail(String email, String password);

  Future<IdentityResult> signInWithEmail(String email, String password);

  Future<IdentityResult> sendPasswordReset(String email);

  /// Signs out. The next token request starts a fresh anonymous account.
  Future<void> signOut();

  /// Deletes the Firebase user. The server row must already be gone.
  Future<IdentityResult> deleteAccount();
}

/// The real one, on Firebase.
class FirebaseIdentity implements Identity {
  FirebaseIdentity({FirebaseAuth? firebaseAuth, GoogleSignIn? googleSignIn})
    : _auth = firebaseAuth,
      _google = googleSignIn;

  final FirebaseAuth? _auth;
  final GoogleSignIn? _google;

  FirebaseAuth get _firebase => _auth ?? FirebaseAuth.instance;

  @override
  bool get isReady => firebaseReady;

  @override
  IdentitySnapshot? get current {
    if (!isReady) return null;
    final user = _firebase.currentUser;
    if (user == null) return null;

    return IdentitySnapshot(
      uid: user.uid,
      isAnonymous: user.isAnonymous,
      email: user.email,
      displayName: user.displayName,
    );
  }

  @override
  Stream<IdentitySnapshot?> get changes {
    if (!isReady) return const Stream<IdentitySnapshot?>.empty();
    return _firebase.authStateChanges().map(_snapshotOf);
  }

  static IdentitySnapshot? _snapshotOf(User? user) => user == null
      ? null
      : IdentitySnapshot(
          uid: user.uid,
          isAnonymous: user.isAnonymous,
          email: user.email,
          displayName: user.displayName,
        );

  @override
  Future<IdentityResult> continueWithGoogle() async {
    if (!isReady) return const IdentityResult(IdentityOutcome.unavailable);

    try {
      final google = _google ?? GoogleSignIn.instance;

      // serverClientId is the OAuth WEB client id. Without it Android signs in
      // and hands back an account with a NULL idToken, which looks like
      // success right up until there is nothing to give Firebase.
      await google.initialize(serverClientId: AppEnv.googleWebClientId);

      final account = await google.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null) {
        debugPrint('[identity] Google returned no ID token');
        return const IdentityResult(IdentityOutcome.unavailable);
      }

      return await _linkOrSignIn(
        GoogleAuthProvider.credential(idToken: idToken),
      );
    } on GoogleSignInException catch (error) {
      if (error.code == GoogleSignInExceptionCode.canceled) {
        return const IdentityResult(IdentityOutcome.cancelled);
      }
      debugPrint('[identity] google sign-in failed: ${error.code}');
      return IdentityResult(
        IdentityOutcome.unavailable,
        message: error.description,
      );
    } catch (error) {
      debugPrint('[identity] google sign-in failed: $error');
      return IdentityResult(
        IdentityOutcome.unavailable,
        message: '$error',
      );
    }
  }

  /// Links when the player is anonymous, signs in when they are not.
  ///
  /// The order matters. Linking is what preserves the uid and therefore every
  /// star already earned; signing in would create or switch to a different
  /// account and silently leave that progress behind.
  Future<IdentityResult> _linkOrSignIn(AuthCredential credential) async {
    final user = _firebase.currentUser;

    try {
      if (user != null && user.isAnonymous) {
        await user.linkWithCredential(credential);
      } else {
        await _firebase.signInWithCredential(credential);
      }
      return const IdentityResult.ok();
    } on FirebaseAuthException catch (error) {
      // The credential is already somebody. Firebase cannot merge two uids, so
      // this is the player's call, not ours.
      if (error.code == 'credential-already-in-use' ||
          error.code == 'email-already-in-use' ||
          error.code == 'account-exists-with-different-credential') {
        return IdentityResult(
          IdentityOutcome.credentialBelongsToAnotherAccount,
          message: error.message,
        );
      }
      return _mapError(error);
    }
  }

  /// Signs in to the account the credential already belongs to.
  ///
  /// Deliberately a SEPARATE call from [continueWithGoogle], because it throws
  /// away the anonymous account's progress and nothing should be able to reach
  /// it without the player having been told that.
  ///
  /// It runs the Google chooser again rather than reusing the credential from
  /// the failed link. A one-time OAuth credential cannot be replayed, and
  /// asking again is also the last point at which somebody can back out.
  @override
  Future<IdentityResult> signInToExistingGoogleAccount() async {
    if (!isReady) return const IdentityResult(IdentityOutcome.unavailable);

    try {
      final google = _google ?? GoogleSignIn.instance;
      await google.initialize(serverClientId: AppEnv.googleWebClientId);

      final account = await google.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null) {
        return const IdentityResult(IdentityOutcome.unavailable);
      }

      // signIn, never link. Linking is what already failed, and it is the
      // wrong verb here: the destination account exists and this device is
      // joining it.
      await _firebase.signInWithCredential(
        GoogleAuthProvider.credential(idToken: idToken),
      );
      return const IdentityResult.ok();
    } on GoogleSignInException catch (error) {
      if (error.code == GoogleSignInExceptionCode.canceled) {
        return const IdentityResult(IdentityOutcome.cancelled);
      }
      return IdentityResult(
        IdentityOutcome.unavailable,
        message: error.description,
      );
    } on FirebaseAuthException catch (error) {
      return _mapError(error);
    }
  }

  @override
  Future<IdentityResult> createWithEmail(String email, String password) async {
    if (!isReady) return const IdentityResult(IdentityOutcome.unavailable);

    final user = _firebase.currentUser;
    final credential = EmailAuthProvider.credential(
      email: email,
      password: password,
    );

    try {
      if (user != null && user.isAnonymous) {
        // Linking, not creating, so the uid and the progress under it survive.
        await user.linkWithCredential(credential);
      } else {
        await _firebase.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
      }

      // Sent, but nothing is gated on it. An unverified address can still play
      // and still sync; refusing to would punish somebody for a mail that went
      // to spam.
      await _sendVerification();
      return const IdentityResult.ok();
    } on FirebaseAuthException catch (error) {
      if (error.code == 'credential-already-in-use' ||
          error.code == 'email-already-in-use') {
        return IdentityResult(
          IdentityOutcome.emailAlreadyInUse,
          message: error.message,
        );
      }
      return _mapError(error);
    }
  }

  Future<void> _sendVerification() async {
    try {
      final user = _firebase.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
      }
    } catch (error) {
      // Never fatal. The account exists either way.
      debugPrint('[identity] verification email not sent: $error');
    }
  }

  @override
  Future<IdentityResult> signInWithEmail(String email, String password) async {
    if (!isReady) return const IdentityResult(IdentityOutcome.unavailable);

    try {
      await _firebase.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return const IdentityResult.ok();
    } on FirebaseAuthException catch (error) {
      return _mapError(error);
    }
  }

  @override
  Future<IdentityResult> sendPasswordReset(String email) async {
    if (!isReady) return const IdentityResult(IdentityOutcome.unavailable);

    try {
      await _firebase.sendPasswordResetEmail(email: email);
      return const IdentityResult.ok();
    } on FirebaseAuthException catch (error) {
      return _mapError(error);
    }
  }

  @override
  Future<void> signOut() async {
    if (!isReady) return;
    try {
      await (_google ?? GoogleSignIn.instance).signOut();
    } catch (error) {
      debugPrint('[identity] google sign out failed: $error');
    }
    try {
      await _firebase.signOut();
    } catch (error) {
      debugPrint('[identity] sign out failed: $error');
    }
  }

  @override
  Future<IdentityResult> deleteAccount() async {
    if (!isReady) return const IdentityResult(IdentityOutcome.unavailable);

    try {
      await _firebase.currentUser?.delete();
      return const IdentityResult.ok();
    } on FirebaseAuthException catch (error) {
      return _mapError(error);
    }
  }

  /// Firebase codes to outcomes.
  ///
  /// `invalid-credential` is the modern catch-all: with email enumeration
  /// protection on (the default for new projects) Firebase deliberately stops
  /// distinguishing a wrong password from an address that was never
  /// registered, precisely so a stranger cannot probe for who has an account.
  /// Reporting it as "wrong password" is therefore the honest mapping — it is
  /// what the player can act on, and claiming "no such account" would be a
  /// guess.
  static IdentityResult _mapError(FirebaseAuthException error) {
    final outcome = switch (error.code) {
      'invalid-email' => IdentityOutcome.emailMalformed,
      'weak-password' => IdentityOutcome.passwordTooWeak,
      'email-already-in-use' => IdentityOutcome.emailAlreadyInUse,
      'wrong-password' || 'invalid-credential' => IdentityOutcome.wrongPassword,
      'user-not-found' => IdentityOutcome.noSuchAccount,
      'too-many-requests' => IdentityOutcome.tooManyAttempts,
      'requires-recent-login' => IdentityOutcome.needsRecentLogin,
      _ => IdentityOutcome.unavailable,
    };

    debugPrint('[identity] ${error.code} -> $outcome');
    return IdentityResult(outcome, message: error.message);
  }
}

/// Used by builds with no Firebase, and by tests that do not care.
class OfflineIdentity implements Identity {
  const OfflineIdentity();

  @override
  bool get isReady => false;

  @override
  IdentitySnapshot? get current => null;

  @override
  Stream<IdentitySnapshot?> get changes =>
      const Stream<IdentitySnapshot?>.empty();

  @override
  Future<IdentityResult> continueWithGoogle() async =>
      const IdentityResult(IdentityOutcome.unavailable);

  @override
  Future<IdentityResult> signInToExistingGoogleAccount() async =>
      const IdentityResult(IdentityOutcome.unavailable);

  @override
  Future<IdentityResult> createWithEmail(String email, String password) async =>
      const IdentityResult(IdentityOutcome.unavailable);

  @override
  Future<IdentityResult> signInWithEmail(String email, String password) async =>
      const IdentityResult(IdentityOutcome.unavailable);

  @override
  Future<IdentityResult> sendPasswordReset(String email) async =>
      const IdentityResult(IdentityOutcome.unavailable);

  @override
  Future<void> signOut() async {}

  @override
  Future<IdentityResult> deleteAccount() async =>
      const IdentityResult(IdentityOutcome.unavailable);
}

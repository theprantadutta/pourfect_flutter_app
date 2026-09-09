/// Getting, and keeping, a session with the backend.
///
/// Three rules govern everything here.
///
/// **It never blocks play.** Nothing in the game waits on a session. The
/// campaign is bundled in the APK and the progress the player can see is the
/// progress on their own device; this exists to back that up and to unlock the
/// things that genuinely need a server. A failure is silence, not a dialog.
///
/// **Players start anonymous, with no sign-in wall.** First-launch friction is
/// a measurable D1 killer and nothing about a ball-sort puzzle needs a real
/// identity. Firebase keeps the SAME uid when an anonymous account later links
/// a credential, so signing in with Google or Apple is not a migration — the
/// row already exists and only `isAnonymous` changes.
///
/// **An anonymous uid does not survive an uninstall.** So while
/// [Session.isAnonymous] is true, server-side progress protects against local
/// app-data loss and NOT against changing phones. Nothing in the UI may
/// describe it as stronger than that.
library;

import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../analytics/analytics_service.dart';
import 'api_client.dart';
import 'api_result.dart';
import 'session.dart';

/// Supplies a Firebase ID token, signing in anonymously if nobody is.
///
/// A seam, so the whole auth path is testable without a Firebase project, an
/// emulator or a network. Returns null when no token could be obtained.
typedef IdTokenProvider = Future<String?> Function({bool forceRefresh});

/// The real one.
Future<String?> firebaseIdToken({bool forceRefresh = false}) async {
  if (!firebaseReady) return null;

  try {
    final auth = FirebaseAuth.instance;
    final user = auth.currentUser ?? (await auth.signInAnonymously()).user;
    return await user?.getIdToken(forceRefresh);
  } catch (error) {
    debugPrint('[auth] firebase token failed: $error');
    return null;
  }
}

class AuthService {
  final ApiClient Function() _resolveClient;
  final SessionStore _store;
  final IdTokenProvider _idToken;
  final String Function() _appVersion;
  final DateTime Function() _now;

  AuthService({
    required ApiClient Function() client,
    SessionStore? store,
    IdTokenProvider idTokenProvider = firebaseIdToken,
    String Function()? appVersion,
    DateTime Function()? now,
  }) : _resolveClient = client,
       _store = store ?? SessionStore(),
       _idToken = idTokenProvider,
       _appVersion = appVersion ?? (() => ''),
       _now = now ?? DateTime.now;

  Session? _session;

  /// The exchange currently in flight, if any.
  ///
  /// Single-flight, and it has to be. Five services wake up at launch and all
  /// want a token; without this they each sign in, each exchange, and four of
  /// the five sessions are thrown away — five round trips and five rows of
  /// server work for one player opening the app.
  Future<Session?>? _inFlight;

  /// Whatever session is already in memory. Never triggers a network call, so
  /// it is safe to read from a widget build.
  Session? get current => _session;

  /// Loads a stored session into memory, without contacting anything.
  ///
  /// Called at startup so the first sync can go out immediately rather than
  /// after a Firebase round trip. A session read from disk may be expired; the
  /// freshness check at use time is what decides.
  Future<Session?> restore() async {
    if (!_resolveClient().isConfigured) return null;
    _session ??= await _store.load();
    return _session;
  }

  /// Returns a usable session, obtaining one if necessary.
  ///
  /// [forceRefresh] re-exchanges even when the cached session still looks
  /// fresh. That is what a 401 means: the server has rejected a token we
  /// believed in, so our belief is what has to be discarded.
  Future<Session?> ensureSession({bool forceRefresh = false}) {
    // Asked of the CLIENT, not of the build-time constant. The constant is
    // what configures the client, but a service that reads it directly cannot
    // be pointed at a stub — and "what happens with no backend" is a path
    // worth testing rather than assuming.
    if (!_resolveClient().isConfigured) return Future.value(null);

    final cached = _session;
    if (!forceRefresh && cached != null && cached.isFreshAt(_now())) {
      return Future.value(cached);
    }

    return _inFlight ??= _exchange(forceRefresh: forceRefresh).whenComplete(() {
      _inFlight = null;
    });
  }

  Future<Session?> _exchange({required bool forceRefresh}) async {
    _session ??= await _store.load();

    // Re-checked inside the single-flight. Several callers can queue behind
    // one exchange; the ones that arrive after it finished must not start
    // another.
    final cached = _session;
    if (!forceRefresh && cached != null && cached.isFreshAt(_now())) {
      return cached;
    }

    final idToken = await _idToken(forceRefresh: forceRefresh);
    if (idToken == null) {
      debugPrint('[auth] no Firebase token; staying offline this session');
      return null;
    }

    final response = await _resolveClient().postAnonymous(
      '/api/v1/auth/device',
      {
        'id_token': idToken,
        'platform': defaultTargetPlatform == TargetPlatform.iOS
            ? 'ios'
            : 'android',
        'app_version': _appVersion(),
        // Sent on EVERY auth, not only when push permission is granted. The
        // evening reminder needs a local-time anchor, and a player who declines
        // notifications never reaches the code path that would have supplied one
        // — so an account with no offset is skipped rather than guessed at, and
        // that would be every account.
        'time_zone_offset_minutes': _now().timeZoneOffset.inMinutes,
      },
    );

    switch (response) {
      case ApiOk(:final value):
        final session = Session.fromAuthResponse(value, _now());
        if (session == null) {
          debugPrint('[auth] auth response was missing a token');
          return null;
        }
        _session = session;
        await _store.save(session);
        return session;

      case ApiFailure(:final kind, :final detail):
        // A rejected ID token is worth clearing for: it means the Firebase
        // account is gone, or was never ours. Anything else is transient and
        // the stored session may still be good once the network is back.
        if (kind == ApiFailureKind.unauthorized ||
            kind == ApiFailureKind.refused) {
          await forget();
        }
        debugPrint('[auth] exchange failed: $kind${detail ?? ''}');
        return null;
    }
  }

  /// The bearer token for a request, or null when there is no session.
  Future<String?> bearerToken({bool forceRefresh = false}) async =>
      (await ensureSession(forceRefresh: forceRefresh))?.accessToken;

  /// Records a change the server has confirmed, so the cached session does not
  /// contradict what the player can see.
  Future<void> update({String? displayName, bool? adsRemoved}) async {
    final session = _session;
    if (session == null) return;
    _session = session.copyWith(
      displayName: displayName,
      adsRemoved: adsRemoved,
    );
    await _store.save(_session!);
  }

  /// Drops the session locally. Does not delete anything on the server.
  Future<void> forget() async {
    _session = null;
    await _store.clear();
  }

  /// Forgets the session AND the Firebase identity behind it.
  ///
  /// For account deletion only. Signing out of Firebase without deleting the
  /// server row would strand the row behind a uid nobody can produce again.
  Future<void> signOutCompletely() async {
    await forget();
    if (!firebaseReady) return;
    try {
      await FirebaseAuth.instance.signOut();
    } catch (error) {
      debugPrint('[auth] sign out failed: $error');
    }
  }
}

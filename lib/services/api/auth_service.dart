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

  int _accountEpoch = 0;

  /// Bumped whenever the account this service speaks for stops being the one
  /// it spoke for a moment ago.
  ///
  /// Anything asynchronous that touches account-scoped data captures this
  /// before it starts and checks it before applying what came back. Without
  /// it, a progress response for the account somebody just signed out of gets
  /// merged into the account they signed in to — which was reproduced as
  /// deleted progress reappearing, and as a write for uid-1 landing while the
  /// player was uid-2.
  int get accountEpoch => _accountEpoch;

  /// The Firebase uid the current session was issued for, if any.
  String? get accountId => _session?.userId;

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

    // Single-flight, still. Five services wake at launch and all want a token;
    // without this they each sign in and four of five sessions are thrown
    // away — five round trips for one player opening the app.
    final running = _inFlight;
    if (running != null) return running;

    // The cleanup clears only the future it belongs to.
    //
    // `_inFlight = null` in a shared callback is wrong once anything else can
    // replace the pointer: an abandoned exchange finishing later would null
    // out the pointer to the NEW account's exchange, and the next caller would
    // start a third. Comparing identity first makes the callback harmless when
    // it is late.
    late final Future<Session?> mine;
    mine = _exchange(
      forceRefresh: forceRefresh,
      epoch: _accountEpoch,
    ).whenComplete(() {
      if (identical(_inFlight, mine)) _inFlight = null;
    });

    return _inFlight = mine;
  }

  /// Exchanges a Firebase token for one of ours, for ONE account.
  ///
  /// [epoch] is the account this work belongs to. Every step that touches
  /// shared state re-checks it, because each `await` here is a place the
  /// player can have signed out, switched account or deleted it in the
  /// meantime — and this request is then about somebody who is no longer the
  /// current player.
  ///
  /// Dropping `_inFlight` does NOT cancel an HTTP request. That was the bug:
  /// abandoning an account advanced the epoch and cleared the pointer, and the
  /// old request carried on to assign `_session` and write it to disk. Holding
  /// A's response, abandoning A, authenticating B, then releasing A put both
  /// memory and SessionStore back to A — a successful switch silently undone.
  Future<Session?> _exchange({
    required bool forceRefresh,
    required int epoch,
  }) async {
    if (_accountEpoch != epoch) return null;

    // Loaded only when it is still this account's turn, and assigned only if
    // nothing has replaced it in the meantime.
    if (_session == null) {
      final stored = await _store.load();
      if (_accountEpoch != epoch) return null;
      _session ??= stored;
    }

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

    // The answer is here, and it may be about somebody who is no longer the
    // player. Nothing below may touch shared state if so — not the session,
    // not the disk, and not `forget`, which would clear a NEWER account's
    // session on behalf of an older one's failure.
    if (_accountEpoch != epoch) {
      debugPrint('[auth] discarded a superseded exchange');
      return null;
    }

    switch (response) {
      case ApiOk(:final value):
        final session = Session.fromAuthResponse(value, _now());
        if (session == null) {
          debugPrint('[auth] auth response was missing a token');
          return null;
        }
        _session = session;
        await _store.save(session);

        // Re-checked after the write, too. If the account changed while the
        // save was in flight, this session is stale on disk and the current
        // one has to win — so put it back.
        if (_accountEpoch != epoch) {
          final current = _session;
          if (current != null) await _store.save(current);
          return null;
        }
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
  ///
  /// Also bumps [accountEpoch]. Forgetting a session is precisely the moment
  /// every account-scoped request already in flight stopped being about the
  /// current account, and the results of those must be discarded rather than
  /// applied to whoever comes next.
  Future<void> forget() async {
    _session = null;
    _accountEpoch++;
    // An exchange running for the account being forgotten must not be handed
    // to the next caller as though it were theirs. It will return null on its
    // own epoch check; this stops anyone waiting on it in the meantime.
    _inFlight = null;
    await _store.clear();
  }

  /// Abandons the current account entirely: no cached session, no cached
  /// token, and a new epoch.
  ///
  /// For a genuine identity CHANGE, as distinct from linking a credential to
  /// the account that already exists. Linking keeps the uid, so the session
  /// stays valid and only needs refreshing; switching does not, and reusing
  /// the old token then authenticates as the previous player. Reproduced
  /// exactly that way: sign into a second account, fail the exchange, and the
  /// next progress write still carried the first account's bearer token.
  Future<void> abandonAccount() async {
    // forget() drops the in-flight exchange too; the old identity's request
    // cannot become the new identity's session.
    await forget();
  }

  /// Applies an authoritative entitlement change to the cached session.
  ///
  /// The session is a snapshot taken at sign-in, and it outlives the facts it
  /// describes. A purchase refunded after it was issued leaves `adsRemoved`
  /// true inside it, and the next sync reads that stale true and hands the
  /// entitlement back — which is exactly what happened. Anything that learns
  /// an entitlement changed has to correct the snapshot too.
  Future<void> recordEntitlement({required bool adsRemoved}) async {
    final session = _session;
    if (session == null || session.adsRemoved == adsRemoved) return;

    _session = session.copyWith(adsRemoved: adsRemoved);
    await _store.save(_session!);
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

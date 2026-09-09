/// The one push this game sends, and how a player opts into it.
///
/// **Permission is never asked for at launch.** A prompt on first run is a
/// measurable D1 killer, and this game's only acquisition channel weights
/// retention heavily — so the ask happens at the one moment it is obviously
/// worth something: just after somebody finishes a daily challenge, when
/// "remind me tomorrow" is a sentence about the thing they have just chosen to
/// do. That also matches what the reminder job will actually send: it only
/// targets players who have finished a daily before.
///
/// A registered token is worth nothing on its own. The evening reminder picks
/// players by their LOCAL time, which comes from the timezone offset the auth
/// handshake sends on every sign-in — precisely so that an account has an
/// anchor even if push is declined forever.
library;

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../analytics/analytics_service.dart';
import 'api_client.dart';
import 'api_result.dart';

enum PushPermission {
  /// Never asked. The only state in which asking is appropriate.
  notAsked,

  granted,

  /// Declined, or restricted by the OS. Never asked again — a second prompt is
  /// not available on iOS anyway, and nagging on Android earns an uninstall.
  denied,
}

class PushService {
  final ApiClient Function() _resolveClient;

  /// Seams, so the whole path is testable without a Firebase project.
  final Future<PushPermission> Function() _readPermission;
  final Future<PushPermission> Function() _request;
  final Future<String?> Function() _readToken;

  PushService({
    required ApiClient Function() client,
    Future<PushPermission> Function()? readPermission,
    Future<PushPermission> Function()? requestPermission,
    Future<String?> Function()? readToken,
  }) : _resolveClient = client,
       _readPermission = readPermission ?? _firebasePermission,
       _request = requestPermission ?? _firebaseRequest,
       _readToken = readToken ?? _firebaseToken;

  PushPermission? _cached;

  /// What the OS currently says, without asking for anything.
  Future<PushPermission> permission() async =>
      _cached ??= await _readPermission();

  /// Registers the token if permission is ALREADY granted.
  ///
  /// Called on launch. Tokens rotate — a reinstall, a restore, an OS decision
  /// — so re-registering the current one every session is what keeps the
  /// stored row pointing at a device that still exists. The server keys on the
  /// token rather than on the pair, so a phone handed to somebody else moves
  /// the row instead of leaving the previous owner receiving notifications on
  /// a device that is no longer theirs.
  Future<bool> registerIfPermitted() async {
    if (await permission() != PushPermission.granted) return false;
    return _register();
  }

  /// Asks, and registers if the answer is yes.
  ///
  /// Returns whether push is now on. Only ever called from a deliberate action
  /// — never on launch, and never twice.
  Future<bool> requestAndRegister() async {
    if (await permission() == PushPermission.denied) return false;

    _cached = await _request();
    if (_cached != PushPermission.granted) return false;

    return _register();
  }

  Future<bool> _register() async {
    final token = await _readToken();
    if (token == null || token.isEmpty) return false;

    final result = await _resolveClient().post('/api/v1/notifications/token', {
      'token': token,
      'platform': defaultTargetPlatform == TargetPlatform.iOS
          ? 'ios'
          : 'android',
    });

    if (result case ApiFailure(:final kind)) {
      // Silent. A token that could not be registered means one missed
      // reminder, and the next launch tries again.
      debugPrint('[push] registration deferred: $kind');
      return false;
    }
    return true;
  }

  // ---- the real Firebase, behind the seams ---------------------------------

  static Future<PushPermission> _firebasePermission() async {
    if (!firebaseReady) return PushPermission.denied;
    try {
      final settings = await FirebaseMessaging.instance
          .getNotificationSettings();
      return _translate(settings.authorizationStatus);
    } catch (error) {
      debugPrint('[push] could not read permission: $error');
      return PushPermission.denied;
    }
  }

  static Future<PushPermission> _firebaseRequest() async {
    if (!firebaseReady) return PushPermission.denied;
    try {
      final settings = await FirebaseMessaging.instance.requestPermission();
      return _translate(settings.authorizationStatus);
    } catch (error) {
      debugPrint('[push] permission request failed: $error');
      return PushPermission.denied;
    }
  }

  static Future<String?> _firebaseToken() async {
    if (!firebaseReady) return null;
    try {
      return await FirebaseMessaging.instance.getToken();
    } catch (error) {
      debugPrint('[push] no token: $error');
      return null;
    }
  }

  static PushPermission _translate(AuthorizationStatus status) =>
      switch (status) {
        AuthorizationStatus.authorized ||
        AuthorizationStatus.provisional => PushPermission.granted,
        AuthorizationStatus.notDetermined => PushPermission.notAsked,
        _ => PushPermission.denied,
      };
}

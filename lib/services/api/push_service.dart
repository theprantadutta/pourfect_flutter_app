/// Push permission, the FCM token, the player's two switches, and opens.
///
/// **Permission is never asked for at launch.** A prompt on first run is a
/// measurable D1 killer, and this game's only acquisition channel weights
/// retention heavily. It is asked at moments it is obviously worth something:
/// a one-time card on the hub after the third level cleared, "Remind me
/// tomorrow" after a daily, and the switch in Settings.
///
/// A registered token is worth nothing on its own. The evening reminder picks
/// players by their LOCAL time, which comes from the timezone offset the auth
/// handshake sends on every sign-in — precisely so that an account has an
/// anchor even if push is declined forever.
library;

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../analytics/analytics_service.dart';
import '../notifications/notification_service.dart';
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

  /// Whether "denied" from the OS can still mean "never asked". True on
  /// Android — see [permission].
  final bool _deniedMayMeanUnasked;

  PushService({
    required ApiClient Function() client,
    Future<PushPermission> Function()? readPermission,
    Future<PushPermission> Function()? requestPermission,
    Future<String?> Function()? readToken,
    bool? deniedMayMeanUnasked,
  }) : _resolveClient = client,
       _readPermission = readPermission ?? _firebasePermission,
       _request = requestPermission ?? _firebaseRequest,
       _readToken = readToken ?? _firebaseToken,
       _deniedMayMeanUnasked =
           deniedMayMeanUnasked ??
           defaultTargetPlatform == TargetPlatform.android;

  PushPermission? _cached;

  /// Set once this install has shown the system prompt.
  static const _promptedKey = 'pourfect.push.system_prompted.v1';

  /// What the OS currently says, without asking for anything.
  ///
  /// **On Android, "denied" is ambiguous, and reading it literally is the bug
  /// that kept every Android 13+ player from ever being asked.** Android has
  /// no "not determined": a fresh install that has never seen the prompt
  /// reports exactly what a player who refused it reports. Treated as a
  /// refusal, the app never raised the prompt and only ever offered to open
  /// the system settings — so almost nobody turned notifications on, and the
  /// server had no token to send to. Until this install has shown the prompt
  /// once, "denied" therefore reads as [PushPermission.notAsked].
  Future<PushPermission> permission() async =>
      _cached ??= await _effectivePermission();

  Future<PushPermission> _effectivePermission() async {
    final raw = await _readPermission();
    if (raw != PushPermission.denied || !_deniedMayMeanUnasked) return raw;
    return await _promptedBefore() ? raw : PushPermission.notAsked;
  }

  Future<bool> _promptedBefore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_promptedKey) ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<void> _markPrompted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_promptedKey, true);
    } catch (_) {}
  }

  /// Reads the OS again. Somebody may have switched notifications on in the
  /// system settings since the last look.
  Future<PushPermission> refreshPermission() async {
    _cached = null;
    return permission();
  }

  /// The player's switches as the server holds them, or null offline.
  Future<NotificationPreferences?> fetchPreferences() async {
    final result = await _resolveClient().get(
      '/api/v1/users/notification-preferences',
    );
    return switch (result) {
      ApiOk(:final value) => NotificationPreferences.fromJson(value),
      ApiFailure() => null,
    };
  }

  /// Sets both switches. Null when the server did not take it, so the switch
  /// does not claim a state the server does not hold.
  Future<NotificationPreferences?> savePreferences(
    NotificationPreferences prefs,
  ) async {
    final result = await _resolveClient().put(
      '/api/v1/users/notification-preferences',
      prefs.toJson(),
    );
    return switch (result) {
      ApiOk(:final value) => NotificationPreferences.fromJson(value),
      ApiFailure(:final kind) => () {
        debugPrint('[push] preferences not saved: $kind');
        return null;
      }(),
    };
  }

  /// Tells the server the player opened notification [id]. Fire and forget:
  /// a lost open costs a dashboard number, never the player anything.
  Future<void> reportOpened(String id) async {
    final result = await _resolveClient().post('/api/v1/notifications/opened', {
      'id': id,
    });
    if (result case ApiFailure(:final kind)) {
      debugPrint('[push] open not reported: $kind');
    }
  }

  /// Opens this app's page in the system notification settings: the only
  /// way back for somebody who declined, since Android asks once.
  Future<bool> openSystemSettings() async {
    try {
      return await const MethodChannel('pourfect/notification_settings')
              .invokeMethod<bool>('open') ??
          false;
    } catch (error) {
      debugPrint('[push] could not open settings: $error');
      return false;
    }
  }

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

    await _markPrompted();
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

  /// Asks for permission, by the route that actually raises the dialog.
  ///
  /// **On Android this does NOT go through FirebaseMessaging.** Its
  /// `requestPermission` does not reliably raise the Android 13+ system
  /// prompt: on a fresh install targeting API 33+ it can return without ever
  /// asking, leaving the player silently denied while every notification is
  /// dropped and nothing appears in the log to say why. The
  /// flutter_local_notifications request is the documented Android path.
  ///
  /// It stays on the Firebase path everywhere else, where that call is the
  /// correct one and raises the iOS prompt properly.
  static Future<PushPermission> _firebaseRequest() async {
    if (!firebaseReady) return PushPermission.denied;

    if (defaultTargetPlatform == TargetPlatform.android) {
      final granted = await NotificationService.shared
          .requestAndroidPermission();

      // Null means the plugin could not answer — fall through to Firebase
      // rather than reporting a denial nobody actually made.
      if (granted != null) {
        return granted ? PushPermission.granted : PushPermission.denied;
      }
    }

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

/// The player's two notification switches.
@immutable
class NotificationPreferences {
  /// Daily Pour reminders: morning, evening, and the win-back.
  final bool reminders;

  /// New worlds and announcements.
  final bool news;

  const NotificationPreferences({required this.reminders, required this.news});

  factory NotificationPreferences.fromJson(Map<String, Object?> json) =>
      NotificationPreferences(
        reminders: json['reminders'] as bool? ?? true,
        news: json['news'] as bool? ?? true,
      );

  Map<String, Object?> toJson() => {'reminders': reminders, 'news': news};

  NotificationPreferences copyWith({bool? reminders, bool? news}) =>
      NotificationPreferences(
        reminders: reminders ?? this.reminders,
        news: news ?? this.news,
      );
}

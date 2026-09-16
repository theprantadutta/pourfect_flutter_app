/// Notifications that actually arrive, and do something when tapped.
///
/// `PushService` beside this owns permission and the FCM token — who we are
/// allowed to notify, and where to send it. This owns everything that happens
/// once a message reaches the device, and every piece of it exists because the
/// platform does not do it for you:
///
/// **A notification channel, created by us.** On Android 8+ every notification
/// belongs to a channel, and the channel — not the notification — owns
/// importance, sound and vibration. Without one created here, FCM posts to a
/// fallback channel whose importance the player can never have been asked
/// about, and our icon and accent are ignored.
///
/// **Foreground display, done by hand.** FCM shows NOTHING while the app is in
/// the foreground on Android; `onMessage` fires and the rest is the app's
/// problem. A daily reminder that silently does nothing while somebody has the
/// game open is the exact case most likely to be seen and reported as broken.
///
/// **Taps that go somewhere.** A reminder about today's challenge that opens
/// the hub has wasted the one moment the player agreed to be interrupted for.
///
/// The small icon is `ic_notification` and never the launcher icon. Android
/// discards a status-bar icon's color entirely and keeps only its alpha, so a
/// full-color icon arrives as a featureless white blob — and on API 26+
/// `@mipmap/ic_launcher` resolves to the adaptive-icon XML, which flattens to a
/// solid white square. See the app-icon section of CLAUDE.md.
library;

import 'dart:async';
import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../analytics/analytics_service.dart' show firebaseReady;

/// What a notification is about, and therefore where a tap should land.
///
/// Deliberately small. The backend sends exactly one kind today — the daily
/// challenge reminder — and a taxonomy invented ahead of the messages that
/// would use it is a taxonomy that will be wrong by the time they arrive.
enum PourfectNotification {
  dailyChallenge('daily_reminder'),

  /// Anything the app does not recognise. Still SHOWN — a message from a newer
  /// backend than this build is not a reason to drop it silently — but it
  /// opens the hub rather than guessing at a destination.
  unknown('unknown');

  const PourfectNotification(this.key);

  final String key;

  /// Reads the kind off an FCM payload.
  ///
  /// **`kind`, not `type`, and `daily_reminder`, not `daily_challenge`.**
  /// Those are the server's words — `NotificationJobService` sends
  /// `["kind"] = "daily_reminder"` — and the server is the live half of this
  /// contract, so the client matches it rather than the other way round.
  ///
  /// This was wrong in the first draft of this file, read `type`, and would
  /// have sent every single reminder tap to [unknown]: no error, no log, the
  /// notification simply opening the hub and the whole point of the
  /// interruption quietly lost.
  static PourfectNotification fromData(Map<String, dynamic> data) {
    final raw = data['kind'];
    for (final value in PourfectNotification.values) {
      if (value.key == raw) return value;
    }
    return PourfectNotification.unknown;
  }
}

/// Channel, display and taps.
class NotificationService {
  /// The one the app uses.
  ///
  /// A singleton because the thing underneath is: the plugin registers ONE set
  /// of platform callbacks, so a second instance would quietly take over the
  /// tap handler and the first one's stream would go silent. Tests construct
  /// their own with an injected plugin and never touch this.
  static final NotificationService shared = NotificationService();

  NotificationService({
    FlutterLocalNotificationsPlugin? plugin,
    bool Function()? firebaseIsReady,
  }) : _plugin = plugin ?? FlutterLocalNotificationsPlugin(),
       _firebaseIsReady = firebaseIsReady ?? (() => firebaseReady);

  final FlutterLocalNotificationsPlugin _plugin;
  final bool Function() _firebaseIsReady;

  /// One channel, because there is one kind of message.
  ///
  /// **Renaming or re-importing a channel does nothing to an install that
  /// already has it.** Android freezes a channel's settings the first time it
  /// is created and ignores every later change, so the id is effectively
  /// permanent and a change of mind means a NEW id — which resets whatever the
  /// player had configured. Worth getting right once.
  static const _channelId = 'pourfect.reminders';
  static const _channelName = 'Reminders';
  static const _channelDescription =
      'The daily challenge, and nothing else. At most one a day.';

  /// White-on-transparent, tinted by Android. NOT the launcher icon.
  static const _smallIcon = 'ic_notification';

  final _taps = StreamController<PourfectNotification>.broadcast();

  /// Notifications the player opened, in order.
  ///
  /// A broadcast stream rather than a callback so the app can listen once at
  /// the root and route, without this service knowing what a route is.
  Stream<PourfectNotification> get taps => _taps.stream;

  var _started = false;

  /// Creates the channel and starts listening. Safe to call more than once.
  Future<void> start() async {
    if (_started) return;
    _started = true;

    await _initialisePlugin();
    await _createChannel();

    if (!_firebaseIsReady()) return;
    _listenForMessages();

    // A notification that LAUNCHED the app is not delivered through
    // `onMessageOpenedApp` — it is waiting here instead, and an app that only
    // listens to the stream drops exactly the taps that mattered most,
    // because the player was not already in the game.
    try {
      final initial = await FirebaseMessaging.instance.getInitialMessage();
      if (initial != null) {
        _taps.add(PourfectNotification.fromData(initial.data));
      }
    } catch (error) {
      debugPrint('[notify] could not read the launch message: $error');
    }
  }

  Future<void> _initialisePlugin() async {
    try {
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings(_smallIcon),
          iOS: DarwinInitializationSettings(
            // FALSE, all three. Asking here would fire the iOS permission
            // dialog at startup, before the player has any idea what they
            // would be agreeing to. Permission is requested from the daily
            // challenge screen, after they have finished one — the only
            // moment in this app where a reminder makes obvious sense.
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
        ),
        onDidReceiveNotificationResponse: _onTapped,
      );
    } catch (error) {
      debugPrint('[notify] plugin init failed: $error');
    }
  }

  Future<void> _createChannel() async {
    if (defaultTargetPlatform != TargetPlatform.android) return;

    try {
      await _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(
            const AndroidNotificationChannel(
              _channelId,
              _channelName,
              description: _channelDescription,
              // HIGH, not max. High posts to the shade with sound; max adds a
              // heads-up banner over whatever the player is doing, which for a
              // once-a-day reminder about a puzzle is an imposition.
              importance: Importance.high,
            ),
          );
    } catch (error) {
      debugPrint('[notify] could not create the channel: $error');
    }
  }

  void _listenForMessages() {
    // FOREGROUND. Android shows nothing itself here — `onMessage` fires and
    // displaying it is the app's job, which is why this service exists at all.
    FirebaseMessaging.onMessage.listen(showForeground);

    // Tapped while the app was alive but backgrounded.
    FirebaseMessaging.onMessageOpenedApp.listen(
      (message) => _taps.add(PourfectNotification.fromData(message.data)),
    );
  }

  /// Displays a message that arrived while the app was open.
  @visibleForTesting
  Future<void> showForeground(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    try {
      await _plugin.show(
        // The message id, so the same reminder redelivered replaces its own
        // row instead of stacking a second copy in the shade.
        id: message.messageId.hashCode,
        title: notification.title,
        body: notification.body,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: _channelDescription,
            importance: Importance.high,
            priority: Priority.high,
            icon: _smallIcon,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        payload: jsonEncode(message.data),
      );
    } catch (error) {
      debugPrint('[notify] could not show a message: $error');
    }
  }

  void _onTapped(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null || payload.isEmpty) {
      _taps.add(PourfectNotification.unknown);
      return;
    }

    try {
      final data = (jsonDecode(payload) as Map).cast<String, dynamic>();
      _taps.add(PourfectNotification.fromData(data));
    } catch (error) {
      // A payload we cannot read is still a tap, and a tap still means the
      // player wants to be somewhere. The hub is the honest fallback.
      debugPrint('[notify] unreadable payload: $error');
      _taps.add(PourfectNotification.unknown);
    }
  }

  /// Asks Android for POST_NOTIFICATIONS, the way that actually works.
  ///
  /// **Not `FirebaseMessaging.requestPermission` on Android.** That does not
  /// reliably raise the Android 13+ system dialog: on a fresh install
  /// targeting API 33+ it can return without ever prompting, leaving the
  /// player silently in a denied state while every notification is dropped
  /// with nothing in the log to say so. The local-notifications plugin's own
  /// request is the documented Android path, and it is idempotent — already
  /// granted or already denied both return immediately.
  ///
  /// Returns null off Android, where the caller should use the Firebase path.
  Future<bool?> requestAndroidPermission() async {
    if (defaultTargetPlatform != TargetPlatform.android) return null;

    try {
      return await _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();
    } catch (error) {
      debugPrint('[notify] permission request failed: $error');
      return false;
    }
  }

  void dispose() => _taps.close();
}

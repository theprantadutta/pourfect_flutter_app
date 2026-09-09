/// The signed-in session, and where it is kept between launches.
///
/// Persisted so a relaunch can sync immediately instead of waiting on a
/// Firebase round trip first. The token is a bearer credential for THIS API
/// and nothing else — it grants a player access to their own progress rows,
/// which is worth roughly nothing to anybody else — so ordinary preferences
/// storage is the right place for it. Reaching for the keystore here would
/// suggest it guards something it does not.
library;

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_config.dart';

@immutable
class Session {
  final String accessToken;
  final DateTime expiresAt;
  final String userId;

  /// The leaderboard name, or null when the player has not opted in.
  final String? displayName;

  /// The entitlement as the SERVER sees it.
  ///
  /// Returned at sign-in so somebody who paid and then reinstalled is ad-free
  /// from the first level rather than after their first purchase sync.
  final bool adsRemoved;

  /// True while the account has no real credential behind it.
  ///
  /// The honest signal that this player's progress does NOT survive an
  /// uninstall or a new device — an anonymous Firebase uid does not travel.
  /// Nothing in the UI may promise otherwise while this is true.
  final bool isAnonymous;

  /// anonymous, google, apple, or unknown.
  final String authProvider;

  const Session({
    required this.accessToken,
    required this.expiresAt,
    required this.userId,
    required this.displayName,
    required this.adsRemoved,
    required this.isAnonymous,
    required this.authProvider,
  });

  /// Whether this can still be used, with room to spare.
  ///
  /// The margin is the point. Treating a token as good until the exact second
  /// it expires turns every disagreement between the phone's clock and the
  /// server's into a 401 the player experiences as a failed sync.
  bool isFreshAt(DateTime now) =>
      now.isBefore(expiresAt.subtract(kSessionRefreshMargin));

  Session copyWith({String? displayName, bool? adsRemoved}) => Session(
    accessToken: accessToken,
    expiresAt: expiresAt,
    userId: userId,
    displayName: displayName ?? this.displayName,
    adsRemoved: adsRemoved ?? this.adsRemoved,
    isAnonymous: isAnonymous,
    authProvider: authProvider,
  );

  Map<String, Object?> toJson() => {
    'token': accessToken,
    'expires_at': expiresAt.toIso8601String(),
    'user_id': userId,
    'display_name': displayName,
    'ads_removed': adsRemoved,
    'is_anonymous': isAnonymous,
    'auth_provider': authProvider,
  };

  static Session? fromJson(Map<String, Object?> json) {
    final token = json['token'];
    final expires = DateTime.tryParse(json['expires_at'] as String? ?? '');
    final userId = json['user_id'];
    if (token is! String || token.isEmpty || expires == null) return null;
    if (userId is! String || userId.isEmpty) return null;

    return Session(
      accessToken: token,
      expiresAt: expires,
      userId: userId,
      displayName: json['display_name'] as String?,
      adsRemoved: json['ads_removed'] as bool? ?? false,
      isAnonymous: json['is_anonymous'] as bool? ?? true,
      authProvider: json['auth_provider'] as String? ?? 'unknown',
    );
  }

  /// Builds a session from the `auth/device` response.
  static Session? fromAuthResponse(Map<String, Object?> body, DateTime now) {
    final token = body['access_token'];
    final userId = body['user_id'];
    final seconds = (body['expires_in_seconds'] as num?)?.toInt();
    if (token is! String || token.isEmpty) return null;
    if (userId is! String || userId.isEmpty) return null;

    return Session(
      accessToken: token,
      // A server that sends no lifetime is treated as sending a short one.
      // Assuming a long life for a token whose expiry we do not know produces
      // a client that is confidently, permanently unauthorised.
      expiresAt: now.add(Duration(seconds: seconds ?? 3600)),
      userId: userId,
      displayName: body['display_name'] as String?,
      adsRemoved: body['ads_removed'] as bool? ?? false,
      isAnonymous: body['is_anonymous'] as bool? ?? true,
      authProvider: body['auth_provider'] as String? ?? 'unknown',
    );
  }
}

class SessionStore {
  static const _key = 'pourfect.session.v1';

  Future<Session?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return null;

    try {
      return Session.fromJson(jsonDecode(raw) as Map<String, Object?>);
    } catch (error) {
      // A corrupt session costs one silent re-authentication, which is
      // invisible. Throwing here would cost the launch.
      debugPrint('[auth] stored session unreadable: $error');
      return null;
    }
  }

  Future<void> save(Session session) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(session.toJson()));
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}

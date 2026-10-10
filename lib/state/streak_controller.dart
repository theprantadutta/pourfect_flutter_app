/// The Daily Pour streak: how long it is, its freezes, and its calendar.
///
/// Everything here is the SERVER's answer. Freezes are spent and handed out by
/// days passing (see the API's StreakFreezeRule), which this device cannot
/// see happen, so it never works a streak out for itself — it asks.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/api/api_result.dart';
import '../services/api/daily_api.dart';
import 'account_controller.dart';
import 'providers.dart';

/// Streak lengths worth a celebration.
const kStreakMilestones = {3, 7, 14, 30, 50, 100, 200, 365};

class StreakController extends Notifier<StreakInfo?> {
  Future<void>? _inFlight;

  @override
  StreakInfo? build() {
    // A different account has a different streak.
    ref.listen(accountProvider.select((a) => a.userId), (previous, next) {
      if (previous != next) {
        state = null;
        unawaited(refresh());
      }
    });
    return null;
  }

  DailyApi get _api => DailyApi(ref.read(apiClientProvider));

  /// Re-reads the streak. Safe to call often: concurrent calls share one
  /// request.
  Future<void> refresh() =>
      _inFlight ??= _load().whenComplete(() => _inFlight = null);

  Future<void> _load() async {
    if (!ref.read(apiClientProvider).isConfigured) return;
    if (await ref.read(authServiceProvider).ensureSession() == null) return;

    switch (await _api.streak()) {
      case ApiOk(:final value):
        state = value;
      case ApiFailure(:final kind):
        // Kept as it was. A streak that vanished on a dropped connection
        // would read as a streak lost.
        debugPrint('[streak] unavailable: $kind');
    }
  }

  /// The calendar for the month starting [month] (any day in it will do).
  /// Not stored: only the sheet that asked for it needs it.
  Future<StreakInfo?> month(DateTime month) async {
    final from = DateTime.utc(month.year, month.month);
    final to = DateTime.utc(month.year, month.month + 1, 0);
    return switch (await _api.streak(from: from, to: to)) {
      ApiOk(:final value) => value,
      ApiFailure() => null,
    };
  }

  /// Claims the freeze a finished rewarded video paid for.
  ///
  /// True when the server added one. The caller has already shown the video;
  /// a refusal here means there was no room after all (another device took
  /// today's), which is not worth an error beyond saying so.
  Future<bool> earnFreeze() async {
    switch (await _api.earnFreeze()) {
      case ApiOk(:final value):
        state = value;
        return true;
      case ApiFailure(:final kind):
        debugPrint('[streak] freeze not added: $kind');
        unawaited(refresh());
        return false;
    }
  }
}

final streakProvider = NotifierProvider<StreakController, StreakInfo?>(
  StreakController.new,
);

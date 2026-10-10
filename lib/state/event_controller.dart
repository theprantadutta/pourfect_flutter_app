/// The weekly event: this week's seven boards and the player's results.
///
/// Like the Daily Pour, it genuinely needs the server — the boards are
/// generated there from a seed that never ships. No server, no event, and
/// nothing else is affected by that.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/api/api_result.dart';
import '../services/api/events_api.dart';
import 'account_controller.dart';
import 'providers.dart';

@immutable
class EventState {
  final WeeklyEventInfo? event;
  final bool loading;

  /// Why there is no event, when there is none.
  final ApiFailureKind? failure;

  const EventState({this.event, this.loading = false, this.failure});

  /// No backend in this build: the event card is not shown at all.
  bool get isOff => failure == ApiFailureKind.notConfigured;
}

class EventController extends Notifier<EventState> {
  Future<void>? _inFlight;

  @override
  EventState build() {
    ref.listen(accountProvider.select((a) => a.userId), (previous, next) {
      if (previous != next) unawaited(refresh());
    });
    return const EventState();
  }

  EventsApi get _api => EventsApi(ref.read(apiClientProvider));

  Future<void> refresh() =>
      _inFlight ??= _load().whenComplete(() => _inFlight = null);

  Future<void> _load() async {
    if (!ref.read(apiClientProvider).isConfigured ||
        await ref.read(authServiceProvider).ensureSession() == null) {
      state = const EventState(failure: ApiFailureKind.notConfigured);
      return;
    }
    state = EventState(event: state.event, loading: true);
    switch (await _api.current()) {
      case ApiOk(:final value):
        state = EventState(event: value);
      case ApiFailure(:final kind):
        // Kept: a dropped connection must not wipe the results on screen.
        state = EventState(event: state.event, failure: kind);
        debugPrint('[event] unavailable: $kind');
    }
  }

  /// Submits a finished board of the event it was PLAYED in.
  Future<ApiResult<WeeklyEventInfo>> submit({
    required WeeklyEventInfo event,
    required int slot,
    required int movesUsed,
    required int durationSeconds,
  }) async {
    final result = await _api.submit(
      weekStart: event.weekStart,
      slot: slot,
      movesUsed: movesUsed,
      durationSeconds: durationSeconds,
    );
    if (result case ApiOk(:final value)) {
      if (state.event == null || state.event!.weekStart == value.weekStart) {
        state = EventState(event: value);
      }
    }
    return result;
  }
}

final eventProvider = NotifierProvider<EventController, EventState>(
  EventController.new,
);

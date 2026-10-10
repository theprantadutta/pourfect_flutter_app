/// Star chests: one every 30 stars, worth 2 hints and an extra tube.
///
/// The device decides when a chest LOOKS ready (its own star total, which is
/// ahead of the server's until a sync lands), the server decides whether it
/// opens (once per account), and the credits it holds land in the same banks
/// rewarded videos fill — so a chest's hints are spent exactly like any other.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/api/api_result.dart';
import '../services/api/chest_api.dart';
import 'account_controller.dart';
import 'cosmetics_controller.dart';
import 'monetization_controller.dart';
import 'progress_repository.dart';
import 'providers.dart';
import 'sync_controller.dart';

/// Stars between chests. The server's rule; repeated so the journey can draw
/// progress before it has asked.
const kStarsPerChest = 30;

@immutable
class ChestState {
  /// What the server last said, or null before it has.
  final ChestStatus? server;

  /// A chest is being opened or doubled right now.
  final bool busy;

  const ChestState({this.server, this.busy = false});

  ChestState copyWith({ChestStatus? server, bool? busy}) =>
      ChestState(server: server ?? this.server, busy: busy ?? this.busy);
}

/// Why a chest did not open.
enum ChestFailure {
  /// The server's stars have not caught up yet (a sync is still on its way).
  notYet,

  /// Already open on this account — another device got there first.
  alreadyOpen,

  /// No network, no backend, or the server failed.
  unavailable,
}

class ChestController extends Notifier<ChestState> {
  @override
  ChestState build() {
    ref.listen(accountProvider.select((a) => a.userId), (previous, next) {
      if (previous != next) {
        state = const ChestState();
        unawaited(refresh());
      }
    });
    return const ChestState();
  }

  ChestApi get _api => ChestApi(ref.read(apiClientProvider));

  bool get _configured => ref.read(apiClientProvider).isConfigured;

  /// Chests this device's star total has earned.
  int get earned =>
      ref.read(progressProvider.notifier).totalStars ~/ kStarsPerChest;

  /// The lowest chest that is earned and not yet open, or null.
  int? get ready {
    final server = state.server;
    if (!_configured || server == null) return null;
    for (var i = 1; i <= earned; i++) {
      if (!server.opened.containsKey(i)) return i;
    }
    return null;
  }

  Future<void> refresh() async {
    if (!_configured) return;
    if (await ref.read(authServiceProvider).ensureSession() == null) return;
    switch (await _api.status()) {
      case ApiOk(:final value):
        state = state.copyWith(server: value);
      case ApiFailure(:final kind):
        debugPrint('[chests] unavailable: $kind');
    }
  }

  /// Opens chest [index] and banks what it holds.
  Future<(ChestReward?, ChestFailure?)> open(int index) async {
    if (state.busy) return (null, ChestFailure.unavailable);
    state = state.copyWith(busy: true);
    try {
      // The stars that earned it may not have reached the server yet.
      await ref.read(syncControllerProvider.notifier).syncNow();

      switch (await _api.open(index)) {
        case ApiOk(:final value):
          await _bank(value);
          _markOpened(index, doubled: false);
          // A chest that unlocked a skin: the collection should list it.
          if (value.cosmeticId != null) {
            unawaited(ref.read(cosmeticsProvider.notifier).refresh());
          }
          return (value, null);
        case ApiFailure(:final statusCode):
          // Re-read what is actually open before saying why not.
          await refresh();
          return (
            null,
            switch (statusCode) {
              403 => ChestFailure.notYet,
              409 => ChestFailure.alreadyOpen,
              _ => ChestFailure.unavailable,
            },
          );
      }
    } finally {
      state = state.copyWith(busy: false);
    }
  }

  /// A finished rewarded video: doubles chest [index]'s credits.
  Future<ChestReward?> double(int index) async {
    switch (await _api.double(index)) {
      case ApiOk(:final value):
        await _bank(value);
        _markOpened(index, doubled: true);
        return value;
      case ApiFailure(:final kind):
        debugPrint('[chests] not doubled: $kind');
        return null;
    }
  }

  Future<void> _bank(ChestReward reward) async {
    final money = ref.read(monetizationProvider.notifier);
    for (var i = 0; i < reward.hints; i++) {
      await money.grantHintCredit();
    }
    for (var i = 0; i < reward.extraTubes; i++) {
      await money.grantExtraTubeCredit();
    }
  }

  void _markOpened(int index, {required bool doubled}) {
    final server = state.server;
    if (server == null) return;
    state = state.copyWith(
      server: ChestStatus(
        totalStars: server.totalStars,
        starsPerChest: server.starsPerChest,
        opened: {...server.opened, index: doubled},
      ),
    );
  }
}

final chestProvider = NotifierProvider<ChestController, ChestState>(
  ChestController.new,
);

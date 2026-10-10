/// Ball skins and tube themes: which the player owns, which they wear.
///
/// Ownership comes from the server (chests, streaks, the Skin pack — see the
/// API's `CosmeticCatalogue`). What is WORN is cached on the device as well,
/// so the board is drawn in the player's skin from the first frame instead of
/// flashing the default while the server is asked.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/ads/ad_ids.dart';
import '../services/api/api_result.dart';
import '../services/api/cosmetics_api.dart';
import '../services/iap/billing_service.dart';
import 'account_controller.dart';
import 'providers.dart';

@immutable
class CosmeticsState {
  /// Everything, owned or not. Empty until the server has answered.
  final List<CosmeticItem> items;

  /// The worn ids. Defaults until told otherwise.
  final String ballSkin;
  final String tubeTheme;

  final bool skinPackOwned;

  const CosmeticsState({
    this.items = const [],
    this.ballSkin = 'classic',
    this.tubeTheme = 'toy',
    this.skinPackOwned = false,
  });

  bool owns(String id) => items.any((i) => i.id == id && i.owned);

  CosmeticsState copyWith({
    List<CosmeticItem>? items,
    String? ballSkin,
    String? tubeTheme,
    bool? skinPackOwned,
  }) => CosmeticsState(
    items: items ?? this.items,
    ballSkin: ballSkin ?? this.ballSkin,
    tubeTheme: tubeTheme ?? this.tubeTheme,
    skinPackOwned: skinPackOwned ?? this.skinPackOwned,
  );
}

class CosmeticsController extends Notifier<CosmeticsState> {
  static const _ballKey = 'pourfect.cosmetics.ball';
  static const _tubeKey = 'pourfect.cosmetics.tube';

  @override
  CosmeticsState build() {
    ref.listen(accountProvider.select((a) => a.userId), (previous, next) {
      if (previous != next) unawaited(refresh());
    });
    unawaited(_restore());
    return const CosmeticsState();
  }

  CosmeticsApi get _api => CosmeticsApi(ref.read(apiClientProvider));

  Future<void> _restore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ball = prefs.getString(_ballKey);
      final tube = prefs.getString(_tubeKey);
      if (ball != null || tube != null) {
        state = state.copyWith(ballSkin: ball, tubeTheme: tube);
      }
    } catch (_) {}
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_ballKey, state.ballSkin);
      await prefs.setString(_tubeKey, state.tubeTheme);
    } catch (_) {}
  }

  Future<void> refresh() async {
    if (!ref.read(apiClientProvider).isConfigured) return;
    if (await ref.read(authServiceProvider).ensureSession() == null) return;
    switch (await _api.list()) {
      case ApiOk(:final value):
        _apply(value);
      case ApiFailure(:final kind):
        debugPrint('[cosmetics] unavailable: $kind');
    }
  }

  void _apply(CosmeticsInfo info) {
    state = CosmeticsState(
      items: info.items,
      ballSkin: info.ballSkin,
      tubeTheme: info.tubeTheme,
      skinPackOwned: info.skinPackOwned,
    );
    unawaited(_persist());
  }

  /// Wears [ballSkin] and/or [tubeTheme]. Shown at once; put back if the
  /// server says no.
  Future<bool> equip({String? ballSkin, String? tubeTheme}) async {
    final before = state;
    state = state.copyWith(ballSkin: ballSkin, tubeTheme: tubeTheme);
    switch (await _api.equip(ballSkin: ballSkin, tubeTheme: tubeTheme)) {
      case ApiOk(:final value):
        _apply(value);
        return true;
      case ApiFailure(:final kind):
        debugPrint('[cosmetics] not equipped: $kind');
        state = before;
        return false;
    }
  }

  /// Opens the store for the Skin pack. The pack's skins appear once the
  /// purchase is verified (see the monetization controller), not here.
  Future<PurchaseOutcome> buySkinPack() => ref
      .read(billingServiceProvider)
      .buy(
        IapIds.skinPack,
        accountId: ref.read(authServiceProvider).current?.userId,
      );
}

final cosmeticsProvider = NotifierProvider<CosmeticsController, CosmeticsState>(
  CosmeticsController.new,
);

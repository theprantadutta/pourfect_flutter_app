/// Haptics, behind an interface so it can be muted and faked.
///
/// Touch is doing real work in this game: it is the difference between a ball
/// that "lands" and a rectangle that changes colour. The tiers below are
/// deliberately distinct — a completed tube must feel different from an
/// ordinary pour, because that is the moment the game is rewarding.
library;

import 'package:flutter/services.dart';

abstract interface class HapticsService {
  /// Lifting or putting down a run, and moving the selection.
  void selection();

  /// A ball settling into a tube.
  void ballLanded();

  /// A tube just filled with a single colour — the payoff moment.
  void tubeCompleted();

  /// The level is finished.
  void levelCompleted();

  /// The board has no legal move left.
  void stuck();
}

/// Platform haptics, respecting a mute toggle.
class PlatformHapticsService implements HapticsService {
  /// Read live, not captured, so toggling in settings takes effect on the very
  /// next tap rather than the next level.
  final bool Function() enabled;

  const PlatformHapticsService({required this.enabled});

  @override
  void selection() {
    if (enabled()) HapticFeedback.selectionClick();
  }

  @override
  void ballLanded() {
    if (enabled()) HapticFeedback.lightImpact();
  }

  @override
  void tubeCompleted() {
    if (enabled()) HapticFeedback.mediumImpact();
  }

  @override
  void levelCompleted() {
    if (enabled()) HapticFeedback.heavyImpact();
  }

  @override
  void stuck() {
    if (enabled()) HapticFeedback.vibrate();
  }
}

/// Silent. Tests, and players who turn haptics off.
class NoopHapticsService implements HapticsService {
  const NoopHapticsService();

  @override
  void selection() {}

  @override
  void ballLanded() {}

  @override
  void tubeCompleted() {}

  @override
  void levelCompleted() {}

  @override
  void stuck() {}
}

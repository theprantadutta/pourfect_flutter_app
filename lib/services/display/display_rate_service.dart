/// The display's refresh rate: asking for the fast one, and reading back what
/// the screen is actually doing.
///
/// Flutter's engine never asks Android for more than its default mode, so a
/// 90 or 120 Hz phone renders Pourfect at 60 Hz unless we opt in. Every pour,
/// squash and win flourish is smoother when we do. `refresh_rate` makes the
/// platform calls (`Surface.setFrameRate` and friends) that the engine skips.
///
/// Behind an interface for the same reason as audio and haptics: tests and the
/// widget tree never touch the platform channel, and a device the plugin does
/// not understand degrades to "nothing to change", never to a crash.
library;

import 'package:flutter/foundation.dart';
import 'package:refresh_rate/refresh_rate.dart';

/// What the screen can do and what it is doing right now.
@immutable
class DisplayRate {
  /// What the display is refreshing at, in Hz. Zero when unknown.
  final double current;

  /// The highest rate the panel supports. Zero when unknown.
  final double max;
  final List<double> supported;

  /// Battery Saver caps the panel whatever we ask for. Worth saying so, rather
  /// than letting the setting look broken.
  final bool lowPower;

  const DisplayRate({
    required this.current,
    required this.max,
    required this.supported,
    required this.lowPower,
  });

  static const unknown = DisplayRate(
    current: 0,
    max: 0,
    supported: [],
    lowPower: false,
  );

  bool get isKnown => max > 0;

  /// A panel that only does one rate has nothing to unlock.
  bool get canGoHigh => max > 61 || supported.length > 1;

  @override
  bool operator ==(Object other) =>
      other is DisplayRate &&
      other.current == current &&
      other.max == max &&
      other.lowPower == lowPower &&
      listEquals(other.supported, supported);

  @override
  int get hashCode =>
      Object.hash(current, max, lowPower, Object.hashAll(supported));
}

abstract interface class DisplayRateService {
  /// Asks for the display's highest rate when [high], or for 60 Hz when not,
  /// then reads back what the screen is doing.
  ///
  /// Safe to call repeatedly: the plugin skips native writes that would not
  /// change anything.
  Future<DisplayRate> apply({required bool high});

  /// Re-reads the display without changing anything.
  Future<DisplayRate> read();
}

/// The real thing, via `refresh_rate`.
class PluginDisplayRateService implements DisplayRateService {
  const PluginDisplayRateService();

  @override
  Future<DisplayRate> apply({required bool high}) async {
    try {
      // Not preferDefault() for the low end: that only withdraws our vote,
      // and a phone whose system setting is already 90 Hz (the A24's is)
      // stays there. Asking for exactly 60 is what makes "60 Hz" true.
      final result = high
          ? await RefreshRate.preferMax()
          : await RefreshRate.matchContent(60);
      debugPrint(
        '[display] ${high ? 'max' : '60 Hz'} requested: ${result.status.name}',
      );
    } catch (e) {
      // An unsupported device is not a failure worth bothering anybody about.
      debugPrint('[display] could not set the refresh rate: $e');
    }
    return read();
  }

  @override
  Future<DisplayRate> read() async {
    try {
      final info = await RefreshRate.refresh();
      return DisplayRate(
        current: info.currentRate,
        max: info.maxRate,
        supported: [...info.supportedRates]..sort(),
        lowPower: info.isLowPowerMode ?? false,
      );
    } catch (e) {
      debugPrint('[display] could not read the display: $e');
      return DisplayRate.unknown;
    }
  }
}

/// Tests, and any build where the platform side is missing.
class NoopDisplayRateService implements DisplayRateService {
  const NoopDisplayRateService();

  @override
  Future<DisplayRate> apply({required bool high}) async => DisplayRate.unknown;

  @override
  Future<DisplayRate> read() async => DisplayRate.unknown;
}

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pourfect_flutter_app/l10n/l10n.dart';

/// A "=1" branch compiles to the "one" plural category, which in Portuguese
/// also covers 0 and in Russian also covers 21, 31... Zero and 21 must never
/// read as "1".
void main() {
  for (final code in ['pt', 'ru', 'es', 'de', 'tr', 'en']) {
    final l = lookupAppLocalizations(Locale(code));
    test('$code: counts 0 and 21 are not shown as 1', () {
      for (final n in [0, 21]) {
        for (final s in [
          l.playHudMovesLabel(n),
          l.statsStreakChip(n),
          l.dailyStreakDays(n),
          l.playHintAdFreeLeft(n),
          l.hubStreakDays(n),
        ]) {
          expect(s, isNot(matches(RegExp(r'(^|\D)1(\D|$)'))), reason: '$code n=$n: $s');
        }
      }
    });
  }
}

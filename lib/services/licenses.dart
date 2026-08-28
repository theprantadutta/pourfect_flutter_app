/// Registers the bundled font licences with Flutter's licence page.
///
/// Both faces ship under the SIL Open Font License 1.1, which REQUIRES the
/// licence text to travel with the software. Flutter surfaces registered
/// licences through `showLicensePage`, so this is what makes us compliant
/// rather than just attributed.
///
/// Deliberately fault-tolerant: a missing file logs and moves on instead of
/// crashing at startup. Shipping without the text is a licence problem to fix
/// before release, not a reason a player cannot open the game — and
/// `assets/fonts/ATTRIBUTION.md` records exactly which files are expected.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Licence files expected in `assets/licenses/`, and the packages they cover.
const _fontLicenses = <String, List<String>>{
  'assets/licenses/OFL-JetBrainsMono.txt': ['JetBrains Mono'],
  'assets/licenses/OFL-Manrope.txt': ['Manrope'],
};

/// Adds every bundled font licence to the registry.
///
/// Call once during startup. The registry is lazy — nothing is read until the
/// player actually opens the licence page.
void registerFontLicenses() {
  LicenseRegistry.addLicense(() async* {
    for (final entry in _fontLicenses.entries) {
      try {
        final text = await rootBundle.loadString(entry.key);
        if (text.trim().isEmpty) continue;
        yield LicenseEntryWithLineBreaks(entry.value, text);
      } catch (_) {
        // Not bundled yet. See assets/fonts/ATTRIBUTION.md.
        debugPrint('[licenses] missing ${entry.key} — required before release');
      }
    }
  });
}

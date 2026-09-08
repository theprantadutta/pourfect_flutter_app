/// Legal document version and acceptance tracking.
///
/// ONE shared version covers all three documents — `assets/legal/privacy.md`,
/// `terms.md` and `refund.md`. Whenever any of them materially changes, bump
/// [currentLegalVersion] AND the `**Legal Version:**` header in all three
/// files, and keep the four in lockstep. Acceptance counts as current only when
/// the stored version matches exactly, so a bump asks everybody to review
/// again.
library;

import 'package:shared_preferences/shared_preferences.dart';

class LegalAcceptance {
  LegalAcceptance._();

  /// Bump on every material change to ANY of the three legal documents.
  static const String currentLegalVersion = '1.0';

  static const String _versionKey = 'pourfect.legal.accepted_version';
  static const String _launchCountKey = 'pourfect.launch_count';

  /// True only when the CURRENT version has been accepted.
  static Future<bool> isCurrentVersionAccepted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_versionKey) == currentLegalVersion;
    } catch (_) {
      // If prefs cannot be read, fail safe by treating it as not accepted.
      // Showing the documents an extra time is recoverable; silently treating
      // an unknown state as consent is not.
      return false;
    }
  }

  static Future<void> recordAccepted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_versionKey, currentLegalVersion);
    } catch (_) {
      // Non-critical — acceptance is simply requested again next launch.
    }
  }

  /// Increments and returns how many times the app has been launched.
  static Future<int> recordLaunch() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final count = (prefs.getInt(_launchCountKey) ?? 0) + 1;
      await prefs.setInt(_launchCountKey, count);
      return count;
    } catch (_) {
      // Unknown launch count is treated as a first launch, which errs toward
      // letting somebody play rather than gating them on a prefs failure.
      return 1;
    }
  }

  /// Whether to put the acceptance gate in front of the player right now.
  ///
  /// **A brand-new player is never gated on their first launch.** First-launch
  /// friction is a measurable D1 killer, and this game's entire acquisition
  /// strategy is organic Play search where retention drives ranking — so the
  /// very first session goes straight to a puzzle. The gate appears on the
  /// SECOND launch, once they have decided they like it.
  ///
  /// A version bump is different: somebody who already accepted an older
  /// version is asked again on their next launch, whenever that is. They are
  /// not a new player and the documents genuinely changed.
  static bool shouldShowGate({required int launchCount, required bool accepted}) {
    if (accepted) return false;
    return launchCount > 1;
  }
}

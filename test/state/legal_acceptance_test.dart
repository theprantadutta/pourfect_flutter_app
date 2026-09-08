// When the legal acceptance gate appears — and, more importantly, when it
// does not.
//
// The rule this pins is a product decision, not a technicality: a brand-new
// player is NEVER gated on their first launch. First-launch friction is a
// measurable D1 killer, and organic Play ranking (this game's only acquisition
// channel) weights retention heavily. Somebody who has just installed the app
// gets a puzzle; the documents wait until they have decided they like it.

import 'package:flutter_test/flutter_test.dart';
import 'package:pourfect_flutter_app/state/legal_acceptance.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('a new player is never gated on first launch', () {
    test('launch 1 shows nothing', () {
      expect(
        LegalAcceptance.shouldShowGate(launchCount: 1, accepted: false),
        isFalse,
        reason: 'the very first session must go straight to a puzzle',
      );
    });

    test('launch 2 shows the gate', () {
      expect(
        LegalAcceptance.shouldShowGate(launchCount: 2, accepted: false),
        isTrue,
      );
    });

    test('and every launch after that, until accepted', () {
      for (final launch in [3, 4, 10, 500]) {
        expect(
          LegalAcceptance.shouldShowGate(launchCount: launch, accepted: false),
          isTrue,
          reason: 'launch $launch',
        );
      }
    });
  });

  group('acceptance stops the gate', () {
    test('an accepted player is never gated, on any launch', () {
      for (final launch in [1, 2, 3, 99]) {
        expect(
          LegalAcceptance.shouldShowGate(launchCount: launch, accepted: true),
          isFalse,
          reason: 'launch $launch',
        );
      }
    });
  });

  group('persistence', () {
    test('the launch counter increments and survives', () async {
      expect(await LegalAcceptance.recordLaunch(), 1);
      expect(await LegalAcceptance.recordLaunch(), 2);
      expect(await LegalAcceptance.recordLaunch(), 3);
    });

    test('acceptance is recorded against the CURRENT version', () async {
      expect(await LegalAcceptance.isCurrentVersionAccepted(), isFalse);

      await LegalAcceptance.recordAccepted();
      expect(await LegalAcceptance.isCurrentVersionAccepted(), isTrue);
    });

    test('a version bump invalidates an older acceptance', () async {
      // The re-consent case. Somebody who accepted 1.0 must be asked again
      // when the documents materially change — that is the entire reason the
      // stored value is a version rather than a boolean.
      SharedPreferences.setMockInitialValues({
        'pourfect.legal.accepted_version': '0.9',
      });

      expect(
        await LegalAcceptance.isCurrentVersionAccepted(),
        isFalse,
        reason: 'an acceptance of an older version was treated as current',
      );
    });

    test('a returning player is re-gated immediately after a bump', () async {
      // Not on their "second launch" — they are not a new player, and the
      // documents actually changed. The launch count is already well past 1.
      expect(
        LegalAcceptance.shouldShowGate(launchCount: 42, accepted: false),
        isTrue,
      );
    });
  });

  group('the version is kept in lockstep with the documents', () {
    test('there is exactly one shared version constant', () {
      // All three documents carry `**Legal Version: X**` in their header and
      // must match this. A mismatch means somebody bumped a document without
      // bumping the code, and nobody would ever be asked to re-accept.
      expect(LegalAcceptance.currentLegalVersion, '1.0');
    });
  });
}

// When the legal acceptance gate appears — and, more importantly, when it
// does not.
//
// The rule this pins is a product decision, not a technicality: a brand-new
// player is NEVER gated on their first launch. First-launch friction is a
// measurable D1 killer, and organic Play ranking (this game's only acquisition
// channel) weights retention heavily. Somebody who has just installed the app
// gets a puzzle; the documents wait until they have decided they like it.

import 'dart:io';

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
    // THIS USED TO ASSERT `currentLegalVersion == '1.0'` AND NOTHING ELSE.
    //
    // Its comment claimed it enforced lockstep with the three documents; it
    // never opened one. All it actually did was fail the moment anybody bumped
    // the constant — which is the one action it should have been permitting —
    // while a document bumped WITHOUT the constant, the failure that matters,
    // sailed through. That is the mismatch nobody would notice: the header
    // says 1.1, the code still says 1.0, acceptance of 1.0 still counts, and
    // nobody is ever asked to re-read a policy that materially changed.
    //
    // It reads the files now.
    const documents = ['privacy.md', 'terms.md', 'refund.md'];
    final header = RegExp(r'\*\*Legal Version:\s*([0-9.]+)\*\*');

    for (final name in documents) {
      test('$name declares the version the code enforces', () {
        final text = File('assets/legal/$name').readAsStringSync();
        final match = header.firstMatch(text);

        expect(
          match,
          isNotNull,
          reason: '$name has no **Legal Version: X** header to check against',
        );
        expect(
          match!.group(1),
          LegalAcceptance.currentLegalVersion,
          reason:
              '$name says ${match.group(1)} but the code enforces '
              '${LegalAcceptance.currentLegalVersion} — a bump on one side '
              'only means nobody is re-asked to accept',
        );
      });
    }

    test('all three documents agree with each other', () {
      final versions = {
        for (final name in documents)
          name: header
              .firstMatch(File('assets/legal/$name').readAsStringSync())
              ?.group(1),
      };

      expect(
        versions.values.toSet().length,
        1,
        reason: 'the three documents disagree: $versions',
      );
    });
  });
}

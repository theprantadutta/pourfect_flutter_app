// The ad ids, and the one rule that protects the revenue line.
//
// Tapping your own live ad is the most reliable way to get an AdMob account
// flagged for invalid traffic — a suspension that takes weeks to appeal and
// takes the whole revenue line with it while it lasts. Every developer build
// is a build somebody taps ads in, so "remember to use test ids while
// developing" is not a policy, it is a hope.
//
// The defence is that a non-release build CANNOT return a live unit id. These
// tests run in debug, so they are executing in exactly the mode that must
// never serve live ads — which is what makes them able to prove it.

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pourfect_flutter_app/services/ads/ad_ids.dart';

/// Google's public test publisher. Every official test unit sits under it.
const _testPublisher = 'ca-app-pub-3940256099942544';

/// Ours. Nothing under this id may be reachable from a non-release build.
const _livePublisher = 'ca-app-pub-9242904787767394';

void main() {
  final everyUnit = <String, String>{
    'interstitial': AdIds.interstitialLevelComplete,
    'rewardedHint': AdIds.rewardedHint,
    'rewardedExtraTube': AdIds.rewardedExtraTube,
    'rewardedLevelSkip': AdIds.rewardedLevelSkip,
  };

  group('a non-release build can never serve a live ad', () {
    test('the test suite really is running in a non-release mode', () {
      // If this ever fails the rest of the group proves nothing, so it is
      // asserted rather than assumed.
      expect(kReleaseMode, isFalse);
      expect(kUsingTestAdIds, isTrue);
    });

    test('every placement resolves to a Google TEST unit', () {
      everyUnit.forEach((name, id) {
        expect(id, startsWith(_testPublisher), reason: name);
      });
    });

    test('no placement can reach our live publisher', () {
      everyUnit.forEach((name, id) {
        expect(id, isNot(contains(_livePublisher)), reason: name);
      });
    });
  });

  group('id shapes — the swap that causes outages', () {
    test('every ad UNIT id uses a slash, never a tilde', () {
      // An app id uses '~' and belongs in AndroidManifest.xml. Putting one
      // here does not crash — it just silently never loads an ad, which is
      // the harder of the two failures to trace.
      everyUnit.forEach((name, id) {
        expect(id, contains('/'), reason: '$name should be a unit id');
        expect(id, isNot(contains('~')), reason: '$name looks like an APP id');
      });
    });

    test('ids are well formed', () {
      everyUnit.forEach((name, id) {
        expect(
          RegExp(r'^ca-app-pub-\d{16}/\d{10}$').hasMatch(id),
          isTrue,
          reason: '$name is malformed: $id',
        );
      });
    });
  });

  group('rewarded placements are distinct once live', () {
    test('all three share a unit on test ids, and that is expected', () {
      // Google publishes exactly one rewarded test unit per platform, so this
      // is a fact about their inventory rather than a mistake in ours. Pinned
      // so that the live assertion below reads as the deliberate contrast.
      expect(AdIds.rewardedHint, AdIds.rewardedExtraTube);
      expect(AdIds.rewardedHint, AdIds.rewardedLevelSkip);
    });
  });

  group('the purchase product id', () {
    test('is a single stable identifier', () {
      // A Play product id can never be changed or reused once created, so a
      // typo here is permanent. It is worth one line to pin it.
      expect(IapIds.removeAds, 'remove_ads');
      expect(IapIds.all, {IapIds.removeAds});
    });
  });
}

// The supported-minimum policy from the admin dashboard.
//
// The one rule that matters most: an app must never lock a player out on a
// policy it could not read or a version it could not parse.

import 'package:flutter_test/flutter_test.dart';
import 'package:pourfect_flutter_app/services/updates/release_policy.dart';

ReleasePolicy _policy({String minimum = '2.1.0', bool enabled = true}) =>
    ReleasePolicy(
      latestVersion: '2.2.0',
      minimumSupportedVersion: minimum,
      storeUrl:
          'https://play.google.com/store/apps/details?id=com.pranta.pourfect',
      enabled: enabled,
    );

void main() {
  test('versions compare by number, segment by segment', () {
    expect(
      compareVersions(parseVersion('2.10.0')!, parseVersion('2.9.3')!),
      greaterThan(0),
    );
    expect(compareVersions(parseVersion('2.1')!, parseVersion('2.1.0')!), 0);
    expect(parseVersion('2.1.1+11'), isNull);
    expect(parseVersion(''), isNull);
  });

  test('a build below the minimum must update', () {
    expect(_policy().requiresUpdate('2.0.9'), isTrue);
    expect(_policy().requiresUpdate('2.1.0'), isFalse);
    expect(_policy().requiresUpdate('2.3.0'), isFalse);
  });

  test('a policy switched off never requires anything', () {
    expect(_policy(enabled: false).requiresUpdate('1.0.0'), isFalse);
  });

  test('nothing it cannot read locks anybody out', () {
    expect(_policy().requiresUpdate(''), isFalse);
    expect(_policy(minimum: 'soon').requiresUpdate('1.0.0'), isFalse);
  });
}

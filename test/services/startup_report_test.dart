// The block a bug report can be answered from.
//
// Its value is entirely in the lines that fire when something is WRONG, so
// those are what is pinned. A report that prints six healthy-looking lines and
// stays quiet about the refused URL is worse than no report, because it looks
// like evidence.

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pourfect_flutter_app/services/api/app_env.dart';
import 'package:pourfect_flutter_app/services/diagnostics/diagnostics.dart';

/// Captures what the report writes, by replacing Flutter's print hook.
List<String> capture(void Function() body) {
  final lines = <String>[];
  final original = debugPrint;
  debugPrint = (message, {wrapWidth}) => lines.add(message ?? '');
  try {
    body();
  } finally {
    debugPrint = original;
  }
  return lines;
}

StartupReport report({
  String api = 'https://pourfect.pranta.dev',
  String? refused,
  bool firebaseReady = true,
  bool googleClientSet = true,
  String? sha1 = 'AA:BB:CC',
}) => StartupReport(
  buildMode: 'release',
  version: '1.0.1+2',
  packageName: 'com.pranta.pourfect',
  apiBaseUrl: api,
  apiUrlRefusedBecause: refused,
  firebaseReady: firebaseReady,
  firebaseProjectId: 'pourfect-c64ea',
  googleWebClientIdPresent: googleClientSet,
  signingSha1: sha1,
);

void main() {
  test('a healthy build reports what it resolved', () {
    final lines = capture(report().write).join('\n');

    expect(lines, contains('1.0.1+2'));
    expect(lines, contains('release'));
    expect(lines, contains('com.pranta.pourfect'));
    expect(lines, contains('https://pourfect.pranta.dev'));
    expect(lines, contains('AA:BB:CC'));
  });

  test('the signing certificate is always reported', () {
    // THE LINE THIS WHOLE REPORT EXISTS FOR. Google sign-in failing only in
    // release, with no error anywhere, is a certificate that is not registered
    // against the package — and the failure arrives as a cancellation, which
    // is indistinguishable from the player pressing back. One line ends it.
    final lines = capture(report(sha1: '1E:6C:CC:D3').write).join('\n');

    expect(lines, contains('signing SHA-1'));
    expect(lines, contains('1E:6C:CC:D3'));
  });

  test('an unavailable fingerprint says so rather than printing null', () {
    final lines = capture(report(sha1: null).write).join('\n');

    expect(lines, contains('unavailable'));
    expect(lines, isNot(contains('null')));
  });

  test('a REFUSED api url reports the reason, not just the absence', () {
    // `apiBaseUrl` goes empty when a release URL fails the guard, and an empty
    // string alone reads as "not configured" — which sends somebody to the
    // wrong file. The reason is the actionable half.
    final lines = capture(
      report(api: '', refused: 'not https').write,
    ).join('\n');

    expect(lines, contains('REFUSED'));
    expect(lines, contains('not https'));
  });

  test('no backend at all is stated plainly', () {
    final lines = capture(report(api: '').write).join('\n');

    expect(lines, contains('backend features off'));
  });

  test('a missing Google client id explains what it breaks', () {
    // Without it the plugin signs in, hands back an account, and the ID token
    // is null — success right up until there is nothing to give Firebase.
    // Naming the symptom is what makes the line worth reading.
    final lines = capture(report(googleClientSet: false).write).join('\n');

    expect(lines, contains('MISSING'));
    expect(lines, contains('null ID token'));
  });

  test('Firebase being down is shouted, not mentioned', () {
    final lines = capture(report(firebaseReady: false).write).join('\n');

    expect(lines, contains('NOT READY'));
  });

  group('the release URL guard', () {
    test('the real production host is accepted', () {
      // Worth pinning as a fact rather than an assumption: if this ever starts
      // failing, a release build silently loses its backend entirely.
      expect(
        AppEnv.releaseUrlProblem('https://pourfect.pranta.dev'),
        isNull,
      );
    });

    test('the development host would be refused in release', () {
      expect(
        AppEnv.releaseUrlProblem('http://192.168.0.141:8394'),
        isNotNull,
      );
    });
  });
}

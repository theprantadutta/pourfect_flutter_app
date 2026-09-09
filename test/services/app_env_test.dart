// Reading `.env`.
//
// Hand-parsed rather than pulled in as a package: it is `KEY=value` with
// comments, and this codebase has already dropped a dependency over 257 KB of
// unused icons. What a hand parser needs in exchange is a test that covers the
// shapes a human actually types.

import 'package:flutter_test/flutter_test.dart';
import 'package:pourfect_flutter_app/services/api/app_env.dart';

void main() {
  group('parsing', () {
    test('reads plain assignments', () {
      final values = AppEnv.parse('''
DEV_API_BACKEND_URL=http://192.168.0.141:8394
PROD_API_BACKEND_URL=https://api.example.com
''');

      expect(values['DEV_API_BACKEND_URL'], 'http://192.168.0.141:8394');
      expect(values['PROD_API_BACKEND_URL'], 'https://api.example.com');
    });

    test('ignores comments and blank lines', () {
      final values = AppEnv.parse('''
# Backend. Development uses the machine's LAN address.

DEV_API_BACKEND_URL=http://10.0.0.2:8394
   # indented comment
''');

      expect(values, {'DEV_API_BACKEND_URL': 'http://10.0.0.2:8394'});
    });

    test('keeps a value containing an equals sign intact', () {
      // Client ids and query strings both have them, and splitting on every
      // `=` truncates exactly the values worth getting right.
      final values = AppEnv.parse('X=a=b=c');
      expect(values['X'], 'a=b=c');
    });

    test('strips surrounding quotes', () {
      // A URL somebody pasted in quotes should work, rather than producing a
      // hostname with a quote character in it.
      expect(AppEnv.parse('A="https://x.test"')['A'], 'https://x.test');
      expect(AppEnv.parse("B='https://y.test'")['B'], 'https://y.test');
    });

    test('tolerates whitespace and trailing carriage returns', () {
      // Windows checkouts, which is where this project lives.
      final values = AppEnv.parse('  KEY = value \r\nOTHER=2\r\n');
      expect(values['KEY'], 'value');
      expect(values['OTHER'], '2');
    });

    test('skips a line with no key', () {
      expect(AppEnv.parse('=orphan\nGOOD=1'), {'GOOD': '1'});
    });

    test('an empty value is empty, not missing', () {
      // `.env.example` ships every key blank, and a blank backend URL is what
      // switches the backend off rather than something to fall over on.
      final values = AppEnv.parse('GOOGLE_WEB_CLIENT_ID=');
      expect(values.containsKey('GOOGLE_WEB_CLIENT_ID'), isTrue);
      expect(values['GOOGLE_WEB_CLIENT_ID'], '');
    });
  });

  group('what the app asks for', () {
    tearDown(() => AppEnv.debugSet(const {}));

    test('an unset backend URL means the backend is off', () {
      AppEnv.debugSet(const {'DEV_API_BACKEND_URL': ''});

      expect(AppEnv.apiBaseUrl, '');
      expect(
        AppEnv.backendConfigured,
        isFalse,
        reason: 'a build with no URL must not think it has a server',
      );
    });

    test('a debug build reads the development URL', () {
      // The release/debug split follows the same rule the ad ids do: a
      // constant somebody remembers to flip is a constant somebody forgets to
      // flip. Tests run in debug, so this is the development side.
      AppEnv.debugSet(const {
        'DEV_API_BACKEND_URL': 'http://192.168.0.141:8394',
        'PROD_API_BACKEND_URL': 'https://api.example.com',
      });

      expect(AppEnv.apiBaseUrl, 'http://192.168.0.141:8394');
      expect(AppEnv.backendConfigured, isTrue);
    });

    test('the Google web client id is exposed for sign-in', () {
      // Android returns no ID TOKEN without it: sign-in appears to succeed and
      // hands back an account with a null token.
      AppEnv.debugSet(const {'GOOGLE_WEB_CLIENT_ID': '123.apps.example'});
      expect(AppEnv.googleWebClientId, '123.apps.example');
    });

    test('an absent key reads as empty rather than throwing', () {
      AppEnv.debugSet(const {});
      expect(AppEnv.get('NOTHING_HERE'), '');
    });
  });
}

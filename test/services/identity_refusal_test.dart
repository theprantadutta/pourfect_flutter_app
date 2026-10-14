import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:pourfect_flutter_app/services/api/identity.dart';

/// Play Services refusing the build and a player backing out both arrive as
/// a "cancel". Only the status tells them apart, and confusing them is how a
/// broken sign-in said nothing at all.
void main() {
  GoogleSignInException cancel({String? description, Object? details}) =>
      GoogleSignInException(
        code: GoogleSignInExceptionCode.canceled,
        description: description,
        details: details,
      );

  test('DEVELOPER_ERROR is a refusal, not a cancel', () {
    expect(
      FirebaseIdentity.refusedByPlay(
        cancel(description: '[16] Account reauth failed. DEVELOPER_ERROR'),
      ),
      isTrue,
    );
  });

  test('a bare status 10 is a refusal', () {
    expect(
      FirebaseIdentity.refusedByPlay(cancel(description: 'ApiException: 10')),
      isTrue,
    );
  });

  test('a genuine cancel is a cancel', () {
    expect(FirebaseIdentity.refusedByPlay(cancel()), isFalse);
    expect(
      FirebaseIdentity.refusedByPlay(
        cancel(description: 'activity is cancelled by the user.'),
      ),
      isFalse,
    );
  });

  test('other numbers containing 10 are not mistaken for it', () {
    expect(
      FirebaseIdentity.refusedByPlay(cancel(description: 'status 100, 2010')),
      isFalse,
    );
  });
}

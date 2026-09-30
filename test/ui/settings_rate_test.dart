// Settings → Rate Pourfect, asked for by the 1.0.0 testers.
//
// It opens the store LISTING. The in-app card is quota-bound and may silently
// not appear, which from a button somebody pressed on purpose reads as a
// broken button.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pourfect_flutter_app/services/review/review_service.dart';
import 'package:pourfect_flutter_app/state/providers.dart';
import 'package:pourfect_flutter_app/ui/screens/settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _RecordingReview implements ReviewService {
  _RecordingReview({this.opens = true});

  final bool opens;
  int listingOpens = 0;
  int cardRequests = 0;

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<void> request() async => cardRequests++;

  @override
  Future<bool> openStoreListing() async {
    listingOpens++;
    return opens;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<void> tapSettingsRow(WidgetTester tester, String title) async {
    await tester.scrollUntilVisible(
      find.text(title),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text(title));
    await tester.pumpAndSettle();
  }

  Future<_RecordingReview> pumpSettings(
    WidgetTester tester, {
    bool storeOpens = true,
  }) async {
    final review = _RecordingReview(opens: storeOpens);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [reviewServiceProvider.overrideWithValue(review)],
        child: MaterialApp(home: SettingsScreen(onClose: () {})),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    return review;
  }

  testWidgets('Rate opens the store listing, never the quota-bound card', (
    tester,
  ) async {
    // The in-app card can silently not appear. From a button somebody pressed
    // on purpose, that reads as a broken button.
    final review = await pumpSettings(tester);
    await tapSettingsRow(tester, 'Rate Pourfect');

    expect(review.listingOpens, 1);
    expect(review.cardRequests, 0);
  });

  testWidgets('a store that will not open says so', (tester) async {
    await pumpSettings(tester, storeOpens: false);
    await tapSettingsRow(tester, 'Rate Pourfect');

    expect(find.text('Could not open the store.'), findsOneWidget);
  });
}

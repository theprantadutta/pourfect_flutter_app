import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pourfect_flutter_app/l10n/l10n.dart';
import 'package:pourfect_flutter_app/ui/format.dart';

/// Capitals follow the language: Turkish dotted i becomes İ, not I.
void main() {
  AppLocalizations l(String code) => lookupAppLocalizations(Locale(code));

  test('Turkish keeps the dot on i', () {
    expect(upperIn(l('tr'), 'Hissiyat'), 'HİSSİYAT');
    expect(upperIn(l('tr'), 'Işık'), 'IŞIK');
    expect(upperIn(l('tr'), 'Eki'), 'EKİ');
  });

  test('other languages are unchanged', () {
    expect(upperIn(l('en'), 'Feel'), 'FEEL');
    expect(upperIn(l('de'), 'Spielgefühl'), 'SPIELGEFÜHL');
    expect(upperIn(l('ru'), 'Мир'), 'МИР');
    expect(upperIn(l('ja'), 'はじめの一歩'), 'はじめの一歩');
  });
}

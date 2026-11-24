import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pourfect_flutter_app/l10n/l10n.dart';

/// Which of our languages a phone's locale lands on.
void main() {
  Locale resolve(String tag) {
    final parts = tag.split('-');
    String? script, country;
    for (final p in parts.skip(1)) {
      if (p.length == 4) {
        script = p;
      } else {
        country = p;
      }
    }
    return resolveSupportedLocale(
      Locale.fromSubtags(
        languageCode: parts.first,
        scriptCode: script,
        countryCode: country,
      ),
    );
  }

  test('a language we have is used, whatever its country', () {
    expect(resolve('pt-PT').languageCode, 'pt');
    expect(resolve('es-AR').languageCode, 'es');
    expect(resolve('en-IN').languageCode, 'en');
  });

  test('a language we lack falls back to English', () {
    expect(resolve('fr-FR'), const Locale('en'));
    expect(resolveSupportedLocale(null), const Locale('en'));
  });

  test('Taiwan, Hong Kong and explicit Hant get Traditional Chinese', () {
    // Only meaningful once the zh_Hant translation exists.
    final hasHant = AppLocalizations.supportedLocales.any(
      (l) => l.languageCode == 'zh' && l.scriptCode == 'Hant',
    );
    if (!hasHant) return;
    for (final tag in ['zh-TW', 'zh-HK', 'zh-Hant-TW', 'zh-Hant']) {
      expect(resolve(tag).scriptCode, 'Hant', reason: tag);
    }
    for (final tag in ['zh-CN', 'zh-SG', 'zh-Hans-CN', 'zh']) {
      expect(resolve(tag).scriptCode, isNull, reason: tag);
    }
  });
}

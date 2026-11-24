/// Translations: how code reaches them.
///
/// In a widget: `context.l10n.commonCancel`. Outside one (the state layer,
/// scheduled notifications): `appL10n().someKey`, which uses the device's
/// language.
///
/// Both fall back to ENGLISH rather than throwing. A widget test that pumps a
/// bare MaterialApp without the delegates then still renders the English text
/// it expects, instead of every such test needing the setup copied in.
///
/// Strings live in `lib/l10n/src/LOCALE/AREA.arb`. After editing:
///   dart run tool/merge_arb.dart && flutter gen-l10n
library;

import 'dart:ui' show Locale, PlatformDispatcher;

import 'package:flutter/widgets.dart';

import 'generated/app_localizations.dart';

export 'generated/app_localizations.dart';

final AppLocalizations _english = lookupAppLocalizations(const Locale('en'));

extension L10nContext on BuildContext {
  /// The strings for this widget's locale, or English when no localizations
  /// are in scope (a bare widget test).
  AppLocalizations get l10n =>
      Localizations.of<AppLocalizations>(this, AppLocalizations) ?? _english;
}

/// The supported locale closest to [wanted]: same language and country,
/// else same language, else English.
Locale resolveSupportedLocale(Locale? wanted) {
  const supported = AppLocalizations.supportedLocales;
  if (wanted == null) return const Locale('en');
  // Chinese: phones often say only "zh-TW" or "zh-HK", with no script. Taiwan,
  // Hong Kong and Macau read Traditional; everywhere else Simplified.
  if (wanted.languageCode == 'zh') {
    final traditional =
        wanted.scriptCode == 'Hant' ||
        (wanted.scriptCode == null &&
            const {'TW', 'HK', 'MO'}.contains(wanted.countryCode));
    final pick = traditional
        ? const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant')
        : const Locale('zh');
    if (supported.contains(pick)) return pick;
  }
  for (final l in supported) {
    if (l.languageCode == wanted.languageCode &&
        l.countryCode == wanted.countryCode) {
      return l;
    }
  }
  for (final l in supported) {
    if (l.languageCode == wanted.languageCode) return l;
  }
  return const Locale('en');
}

/// Strings for code with no BuildContext, in the device's language.
AppLocalizations appL10n() => lookupAppLocalizations(
  resolveSupportedLocale(PlatformDispatcher.instance.locale),
);

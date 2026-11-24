// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonClose => 'Close';

  @override
  String get commonBack => 'Back';

  @override
  String get commonOk => 'OK';

  @override
  String get commonSave => 'Save';

  @override
  String get commonRetry => 'Try again';

  @override
  String get commonNotNow => 'Not now';

  @override
  String commonLevelN(int level) {
    return 'Level $level';
  }
}

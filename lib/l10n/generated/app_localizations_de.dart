// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get accountGoogleFailed =>
      'Die Google-Anmeldung hat auf diesem Handy nicht geklappt. Versuch es nochmal oder nutze unten deine E-Mail.';

  @override
  String get accountAppleFailed =>
      'Die Apple-Anmeldung hat auf diesem Handy nicht geklappt. Prüfe, ob du in den Einstellungen mit deinem Apple Account angemeldet bist, oder nutze unten deine E-Mail.';

  @override
  String get accountExistsNoLocal =>
      'Mit dieser E-Mail hast du schon ein Konto. Melde dich dort an, dann lädt dieses Handy die Sterne, die darin gespeichert sind.';

  @override
  String accountExistsWithLocal(int solved) {
    String _temp0 = intl.Intl.pluralLogic(
      solved,
      locale: localeName,
      other:
          'Mit dieser E-Mail hast du schon ein Konto. Auf diesem Handy sind $solved gelöste Level, die nicht im Konto sind, und beides lässt sich nicht zusammenführen – bei der Anmeldung werden sie durch den Stand des Kontos ersetzt.',
      one:
          'Mit dieser E-Mail hast du schon ein Konto. Auf diesem Handy ist $solved gelöstes Level, das nicht im Konto ist, und beides lässt sich nicht zusammenführen – bei der Anmeldung wird es durch den Stand des Kontos ersetzt.',
    );
    return '$_temp0';
  }

  @override
  String get accountEmailInUse =>
      'Mit dieser E-Mail gibt es schon ein Konto. Melde dich lieber an.';

  @override
  String get accountEmailMalformed =>
      'Das sieht nicht nach einer E-Mail-Adresse aus.';

  @override
  String get accountPasswordWeak =>
      'Dieses Passwort ist zu leicht zu erraten. Nimm ein längeres.';

  @override
  String get accountWrongPassword =>
      'E-Mail und Passwort passen nicht zusammen.';

  @override
  String get accountTooManyAttempts =>
      'Zu viele Versuche. Warte ein paar Minuten und versuch es dann nochmal.';

  @override
  String get accountNeedsRecentLogin =>
      'Bitte melde dich zuerst noch einmal an.';

  @override
  String get accountMethodNotEnabled =>
      'Die Anmeldung per E-Mail ist gerade nicht verfügbar. Versuch es mit „Weiter mit Google“.';

  @override
  String get accountSessionUnavailable =>
      'Angemeldet, aber dein Fortschritt ist noch nicht auf dem Server gespeichert. Er wird synchronisiert, sobald die Verbindung wieder da ist.';

  @override
  String get accountUnavailable =>
      'Der Server ist nicht erreichbar. Dein Fortschritt ist auf diesem Gerät weiterhin sicher.';

  @override
  String get accountUseThatAccount => 'Dieses Konto nutzen';

  @override
  String get accountExistingTitle => 'Du hast schon ein Konto';

  @override
  String get accountExistingBodyEmpty =>
      'Dieses Handy lädt die Sterne, die dort schon gespeichert sind.';

  @override
  String accountExistingBodyLocal(int cleared) {
    String _temp0 = intl.Intl.pluralLogic(
      cleared,
      locale: localeName,
      other:
          'Auf diesem Handy sind $cleared gelöste Level, die nicht in diesem Konto sind. Beides lässt sich nicht kombinieren, deshalb werden sie durch den Stand des Kontos ersetzt.',
      one:
          'Auf diesem Handy ist $cleared gelöstes Level, das nicht in diesem Konto ist. Beides lässt sich nicht kombinieren, deshalb wird es durch den Stand des Kontos ersetzt.',
    );
    return '$_temp0';
  }

  @override
  String get accountSignIn => 'Anmelden';

  @override
  String get accountSignInCancelled =>
      'Anmeldung abgebrochen. Nichts wurde geändert.';

  @override
  String get accountSignedInToast =>
      'Angemeldet. Deine Sterne kommen jetzt mit auf ein neues Handy.';

  @override
  String get accountResetNeedsEmail =>
      'Gib zuerst deine E-Mail ein und tippe dann auf „Passwort vergessen?“.';

  @override
  String get accountResetSent =>
      'Falls es zu dieser E-Mail ein Konto gibt, ist ein Link zum Zurücksetzen unterwegs.';

  @override
  String get accountYourAccount => 'Dein Konto';

  @override
  String accountRankValue(int rank) {
    return '#$rank';
  }

  @override
  String accountStreakValue(int days) {
    return '$days T.';
  }

  @override
  String get accountCardTravels =>
      'Diese Karte gehört zu deinem Konto, so geht es auf einem neuen Handy genau da weiter, wo du aufgehört hast.';

  @override
  String get accountYourNameHeader => 'Dein Name';

  @override
  String get accountChangeName => 'Namen ändern';

  @override
  String get accountChangeNameDetail => 'So siehst du in den Listen aus';

  @override
  String get accountShowOnBoards => 'In Bestenlisten zeigen';

  @override
  String get accountShowOnBoardsDetail =>
      'Aus blendet Name und Rang aus. Sterne zählen weiter.';

  @override
  String get accountYourPlayHeader => 'Dein Spiel';

  @override
  String get accountStatistics => 'Statistik';

  @override
  String get accountStatisticsDetail =>
      'Deine Zeiten, Aktivität und alle Level';

  @override
  String get accountSessionHeader => 'Sitzung';

  @override
  String get accountDeleteHint =>
      'Um dein Konto zu löschen, geh zu Einstellungen → Gefahrenzone.';

  @override
  String get accountVisibilityFailed =>
      'Der Server ist nicht erreichbar, daher hat sich nichts geändert.';

  @override
  String get accountSignOutTitle => 'Abmelden?';

  @override
  String get accountSignOutBody =>
      'Dein Fortschritt bleibt auf diesem Handy. Du kannst dich jederzeit wieder anmelden und woanders weiterspielen.';

  @override
  String get accountStaySignedIn => 'Angemeldet bleiben';

  @override
  String get accountSignOut => 'Abmelden';

  @override
  String get accountSignOutDetail => 'Dein Fortschritt bleibt auf diesem Handy';

  @override
  String get accountSaveTitle => 'Fortschritt sichern';

  @override
  String get accountSaveIntro =>
      'Deine Sterne, deine Serie und dein Name in der Bestenliste ziehen mit deinem Konto um, so geht es auf einem neuen Handy da weiter, wo du aufgehört hast.';

  @override
  String get accountContinueApple => 'Mit Apple fortfahren';

  @override
  String get accountContinueGoogle => 'Weiter mit Google';

  @override
  String get accountOr => 'ODER';

  @override
  String get accountEmailLabel => 'E-Mail';

  @override
  String get accountEmailEmpty => 'Gib deine E-Mail ein.';

  @override
  String get accountPasswordLabel => 'Passwort';

  @override
  String get accountPasswordHelper => 'Mindestens 8 Zeichen';

  @override
  String get accountPasswordEmpty => 'Gib ein Passwort ein.';

  @override
  String get accountPasswordShort => 'Mindestens 8 Zeichen.';

  @override
  String get accountShowPassword => 'Passwort anzeigen';

  @override
  String get accountHidePassword => 'Passwort verbergen';

  @override
  String get accountCreate => 'Konto erstellen';

  @override
  String get accountSwitchToSignIn => 'Schon ein Konto? Anmelden';

  @override
  String get accountSwitchToSignInSemantic => 'Stattdessen anmelden';

  @override
  String get accountSwitchToCreate => 'Noch kein Konto? Erstell eins';

  @override
  String get accountSwitchToCreateSemantic => 'Stattdessen ein Konto erstellen';

  @override
  String get accountForgotPassword => 'Passwort vergessen?';

  @override
  String get accountForgotPasswordSemantic => 'Passwort zurücksetzen';

  @override
  String get accountNaming => 'Name wird vergeben…';

  @override
  String get accountSignedInLabel => 'Angemeldet';

  @override
  String accountPouringSince(String month, int year) {
    return 'DABEI SEIT $month $year';
  }

  @override
  String get accountPlayerCardTag => 'SPIELERKARTE';

  @override
  String get accountStatSolved => 'GELÖST';

  @override
  String get accountStatStars => 'STERNE';

  @override
  String get accountStatStreak => 'SERIE';

  @override
  String get accountStatRank => 'RANG';

  @override
  String accountStarsValue(int stars) {
    return '$stars★';
  }

  @override
  String get accountSyncing => 'Synchronisiere…';

  @override
  String get accountSyncingDetail => 'Fortschritt wird im Konto gespeichert';

  @override
  String get accountWaitingToSync => 'Wartet auf Sync';

  @override
  String get accountWaitingOffline => 'Wird gespeichert, sobald du online bist';

  @override
  String get accountWaitingPending =>
      'Deine neuesten Level kommen als Nächstes';

  @override
  String get accountSyncedDetail => 'Fortschritt im Konto gespeichert';

  @override
  String get accountSynced => 'Synchronisiert';

  @override
  String get accountSyncedJustNow => 'Gerade synchronisiert';

  @override
  String accountSyncedMinutesAgo(int minutes) {
    return 'Sync vor $minutes Min.';
  }

  @override
  String accountSyncedHoursAgo(int hours) {
    return 'Sync vor $hours Std.';
  }

  @override
  String accountSyncedDaysAgo(int days) {
    return 'Sync vor $days T.';
  }

  @override
  String get accountCrestSignedIn => 'Dein Konto';

  @override
  String get accountCrestGuest => 'Du spielst als Gast';

  @override
  String get accountRenameRefused => 'Dieser Name wurde nicht akzeptiert.';

  @override
  String get accountRenameOffline =>
      'Der Server ist nicht erreichbar. Versuch es gleich nochmal.';

  @override
  String get ranksTitle => 'Ranglisten';

  @override
  String get ranksTabToday => 'Heute';

  @override
  String get ranksTabCampaign => 'Kampagne';

  @override
  String get ranksLoading => 'Bestenliste wird geladen…';

  @override
  String get ranksEmptyDailyTitle => 'Heute hat noch niemand das Rätsel gelöst';

  @override
  String get ranksEmptyDailyDetail => 'Sei der oder die Erste.';

  @override
  String get ranksEmptyCampaignTitle => 'Noch keine Spieler in der Rangliste';

  @override
  String get ranksEmptyCampaignDetail => 'Hier entscheiden die Sterne.';

  @override
  String get ranksYourSpot => 'Dein Platz';

  @override
  String ranksPlayerCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString Spieler in dieser Liste',
      one: '1 Spieler in dieser Liste',
    );
    return '$_temp0';
  }

  @override
  String ranksMoves(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Züge',
      one: '$count Zug',
    );
    return '$_temp0';
  }

  @override
  String ranksStars(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Sterne',
      one: '$count Stern',
    );
    return '$_temp0';
  }

  @override
  String ranksLevels(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Level',
      one: '$count Level',
    );
    return '$_temp0';
  }

  @override
  String ranksInTime(String time) {
    return 'in $time';
  }

  @override
  String get ranksOpenSpot => 'Frei';

  @override
  String ranksNameYou(String name) {
    return '$name (du)';
  }

  @override
  String ranksPlaceOpen(int place) {
    return 'Platz $place, frei';
  }

  @override
  String ranksPlaceSemantic(int rank, String name, String score) {
    return 'Platz $rank, $name, $score';
  }

  @override
  String ranksScoreWithTieBreak(String score, String tieBreak) {
    return '$score, $tieBreak';
  }

  @override
  String get ranksOffTitle => 'Bestenlisten sind in dieser Version aus';

  @override
  String get ranksOffDetail => 'Die Kampagne ist davon nicht betroffen.';

  @override
  String get ranksLoadFailed => 'Liste konnte nicht geladen werden';

  @override
  String get ranksOffline =>
      'Du scheinst offline zu sein. Alle Level lassen sich auch ohne Verbindung spielen.';

  @override
  String get ranksTimeout => 'Der Server hat zu lange gebraucht.';

  @override
  String get ranksServerError =>
      'Bei uns ist etwas schiefgelaufen. Dein Fortschritt ist sicher.';

  @override
  String get ranksHiddenTitle => 'Du bist ausgeblendet';

  @override
  String get ranksHiddenDetail =>
      'Deine Sterne und deine Serie zählen weiter – du erscheinst nur nicht hier. Den Schalter findest du in den Einstellungen.';

  @override
  String get statsTitle => 'Deine Statistik';

  @override
  String get statsTabOverview => 'Überblick';

  @override
  String get statsTabLevels => 'Level';

  @override
  String get statsTabBadges => 'Abzeichen';

  @override
  String get statsPaceOnPar => 'im Par';

  @override
  String statsPaceUnder(int percent) {
    return '$percent% drunter';
  }

  @override
  String statsPaceOver(int percent) {
    return '$percent% drüber';
  }

  @override
  String get statsEmptyTitle => 'Noch nichts zu sehen';

  @override
  String get statsEmptyBody =>
      'Löse ein Level, dann füllt sich das hier: deine Zeiten im Vergleich zum Par, deine besten Lösungen und die Tage, an denen du gespielt hast.';

  @override
  String get statsBackToLevels => 'Zurück zu den Leveln';

  @override
  String get statsLevelsSolved => 'Level gelöst';

  @override
  String get statsStars => 'Sterne';

  @override
  String get statsPoints => 'Punkte';

  @override
  String get statsPlayed => 'gespielt';

  @override
  String get statsNowOn => 'aktuell';

  @override
  String get statsBestSolveMoves => 'Züge in Bestlösungen';

  @override
  String get statsAgainstClock => 'GEGEN DIE UHR';

  @override
  String get statsNoTimes =>
      'Noch keine Zeiten erfasst. Level, die du vor Einführung der Uhr gelöst hast, haben keine Zeit – spiel eins nochmal, dann zählt sie mit.';

  @override
  String get statsFastest => 'Schnellste';

  @override
  String get statsLongest => 'Längste';

  @override
  String get statsAvgPace => 'Ø Tempo';

  @override
  String statsClockValue(String time, int level) {
    return '$time · L$level';
  }

  @override
  String statsUntimed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count deiner gelösten Level wurden vor der Uhr gelöst und haben keine Zeit.',
      one:
          '$count deiner gelösten Level wurde vor der Uhr gelöst und hat keine Zeit.',
    );
    return '$_temp0';
  }

  @override
  String statsUnderParSemantic(int under, int total) {
    return '$under von $total Leveln mit Zeit unter Par';
  }

  @override
  String get statsUnderParTag => 'UNTER PAR';

  @override
  String get statsLast30Days => 'LETZTE 30 TAGE';

  @override
  String statsStreakChip(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count-Tage-Serie',
      one: '1 Tag Serie',
    );
    return '$_temp0';
  }

  @override
  String get statsNoStreak => 'keine Serie';

  @override
  String statsDaysPlayed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Tage gespielt',
      one: '$count Tag gespielt',
    );
    return '$_temp0';
  }

  @override
  String statsLevelsFinished(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Level gelöst',
      one: '$count Level gelöst',
    );
    return '$_temp0';
  }

  @override
  String statsBestStreak(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Rekord $count Tage',
      one: 'Rekord $count Tag',
    );
    return '$_temp0';
  }

  @override
  String get statsToday => 'Heute';

  @override
  String statsMonthShort(String month) {
    String _temp0 = intl.Intl.selectLogic(month, {
      'jan': 'Jan.',
      'feb': 'Feb.',
      'mar': 'März',
      'apr': 'Apr.',
      'may': 'Mai',
      'jun': 'Juni',
      'jul': 'Juli',
      'aug': 'Aug.',
      'sep': 'Sep.',
      'oct': 'Okt.',
      'nov': 'Nov.',
      'dec': 'Dez.',
      'other': '$month',
    });
    return '$_temp0';
  }

  @override
  String statsMonthDay(String month, int day) {
    return '$day. $month';
  }

  @override
  String statsBarLevels(String day, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$day · $count Level',
      one: '$day · $count Level',
    );
    return '$_temp0';
  }

  @override
  String statsBarNoPlay(String day) {
    return '$day · nicht gespielt';
  }

  @override
  String get statsWorldAhead => 'kommt noch';

  @override
  String get statsWorldNoTimes => 'keine Zeiten';

  @override
  String statsWorldPoints(int points) {
    final intl.NumberFormat pointsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String pointsString = pointsNumberFormat.format(points);

    return '$pointsString Pkt.';
  }

  @override
  String statsWorldSolvedSemantic(String name, int cleared, int total) {
    return '$name: $cleared von $total gelöst';
  }

  @override
  String statsWorldPaceSemantic(String pace) {
    return 'Tempo $pace';
  }

  @override
  String statsWorldPointsSemantic(int points) {
    final intl.NumberFormat pointsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String pointsString = pointsNumberFormat.format(points);

    return '$pointsString Punkte';
  }

  @override
  String get statsColLevel => 'LVL';

  @override
  String get statsColStars => 'STERNE';

  @override
  String get statsColMoves => 'ZÜGE';

  @override
  String get statsColTime => 'ZEIT';

  @override
  String get statsColPoints => 'PKT';

  @override
  String statsMovesBestPossible(int moves, int best) {
    return '$moves Züge, bestmöglich $best';
  }

  @override
  String statsMoves(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Züge',
      one: '$count Zug',
    );
    return '$_temp0';
  }

  @override
  String badgeUnlockedCount(int earned, int total) {
    return '$earned von $total freigeschaltet';
  }

  @override
  String get badgeUnlocked => 'Freigeschaltet';

  @override
  String get badgeNotYet => 'Noch nicht';

  @override
  String badgeProgress(int shown, int target) {
    return '$shown von $target';
  }

  @override
  String badgeSemantic(String title, String description, String status) {
    return '$title: $description $status';
  }

  @override
  String get badgeFirstPourTitle => 'Erster Guss';

  @override
  String get badgeFirstPourDesc => 'Löse dein erstes Level.';

  @override
  String get badgePar10Title => 'Im Par';

  @override
  String get badgePar10Desc => 'Löse 10 Level genau im Par.';

  @override
  String get badgePar50Title => 'Par-Profi';

  @override
  String get badgePar50Desc => 'Löse 50 Level genau im Par.';

  @override
  String get badgeCleanClearTitle => 'Ohne Rückzieher';

  @override
  String get badgeCleanClearDesc =>
      'Löse ein Level, ohne einen Zug zurückzunehmen.';

  @override
  String get badgeSpeedyTitle => 'Fix gegossen';

  @override
  String get badgeSpeedyDesc => 'Löse ein Level in unter 30 Sekunden.';

  @override
  String get badgeLevels100Title => 'Hunderter';

  @override
  String get badgeLevels100Desc => 'Löse 100 Level.';

  @override
  String get badgeStars300Title => 'Sternensammler';

  @override
  String get badgeStars300Desc => 'Sammle 300 Sterne.';

  @override
  String get badgeWorldPerfectTitle => 'Makellose Welt';

  @override
  String get badgeWorldPerfectDesc =>
      'Hol drei Sterne in jedem Level einer Welt.';

  @override
  String get badgeStreak7Title => 'Eine Woche dabei';

  @override
  String get badgeStreak7Desc => 'Erreiche eine 7-Tage-Serie beim Tagesrätsel.';

  @override
  String get badgeStreak30Title => 'Ein Monat dabei';

  @override
  String get badgeStreak30Desc =>
      'Erreiche eine 30-Tage-Serie beim Tagesrätsel.';

  @override
  String get badgeChests5Title => 'Schatzjäger';

  @override
  String get badgeChests5Desc => 'Öffne 5 Sternentruhen.';

  @override
  String get badgeHard5Title => 'Harte Nuss';

  @override
  String get badgeHard5Desc => 'Löse 5 SCHWER-Level.';

  @override
  String get badgeEventFullTitle => 'Volle Woche';

  @override
  String get badgeEventFullDesc =>
      'Löse alle sieben Rätsel eines Wochen-Events.';

  @override
  String get badgeZen25Title => 'Zen-Garten';

  @override
  String get badgeZen25Desc => 'Löse 25 Rätsel im Zen-Modus.';

  @override
  String get commonCancel => 'Abbrechen';

  @override
  String get commonClose => 'Schließen';

  @override
  String get commonBack => 'Zurück';

  @override
  String get commonOk => 'OK';

  @override
  String get commonSave => 'Speichern';

  @override
  String get commonRetry => 'Nochmal';

  @override
  String get commonNotNow => 'Jetzt nicht';

  @override
  String commonLevelN(int level) {
    return 'Level $level';
  }

  @override
  String get hubAccountYours => 'Dein Konto';

  @override
  String get hubAccountSave => 'Fortschritt sichern';

  @override
  String get hubPlayerFallback => 'Spieler';

  @override
  String get hubSettings => 'Einstellungen';

  @override
  String get hubTagline => 'FÜLLEN · ORDNEN · RUHEN';

  @override
  String hubStatChipSemantic(String value, String label) {
    return '$value $label. Statistik';
  }

  @override
  String get hubStatSolved => 'gelöst';

  @override
  String get hubStatStars => 'Sterne';

  @override
  String get hubStatStreak => 'Serie';

  @override
  String hubStreakDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Tage',
      one: '1 Tag',
    );
    return '$_temp0';
  }

  @override
  String hubRankNumber(int rank) {
    return '#$rank';
  }

  @override
  String hubEventSemantic(int cleared, int total) {
    return 'Wochen-Event, $cleared von $total Rätseln';
  }

  @override
  String hubEventProgress(int cleared, int total, String timeLeft) {
    return '$cleared/$total · $timeLeft';
  }

  @override
  String hubEventProgressRanked(
    int cleared,
    int total,
    int rank,
    String timeLeft,
  ) {
    return '$cleared/$total · #$rank · $timeLeft';
  }

  @override
  String get hubZen => 'Zen';

  @override
  String get hubZenSemantic => 'Zen-Modus';

  @override
  String hubZenLockedSemantic(int level) {
    return 'Zen-Modus wird ab Level $level freigeschaltet';
  }

  @override
  String get hubZenOpen => 'Endlos, ohne Uhr';

  @override
  String hubZenLocked(int level, int remaining) {
    return 'Level $level · noch $remaining';
  }

  @override
  String get hubDockJourney => 'Reise';

  @override
  String get hubDockRankings => 'Ranglisten';

  @override
  String get hubDockStats => 'Statistik';

  @override
  String get hubTip =>
      'Super! Unter „Reise“ findest du alle Level, und jeden Tag gibt es ein neues Tagesrätsel.';

  @override
  String hubHeroWorld(int world) {
    return 'Welt $world';
  }

  @override
  String hubHeroWorldBand(int world, String band) {
    return 'Welt $world · $band';
  }

  @override
  String hubHeroPar(int par) {
    return 'Par $par';
  }

  @override
  String get hubPlay => 'SPIELEN';

  @override
  String hubPlaySemantic(int level) {
    return 'Level $level spielen';
  }

  @override
  String get hubMoreUpdateTitle => 'Update für mehr Level';

  @override
  String get hubMoreUpdateBody =>
      'Eine neue Welt ist da, und sie braucht das neueste Pourfect. Aktualisiere das Spiel, um weiterzuspielen.';

  @override
  String get hubMoreDownloadingTitle => 'Neue Level unterwegs';

  @override
  String get hubMoreDownloadingBody =>
      'Die nächste Welt wird geladen. Das dauert nur einen Moment.';

  @override
  String get hubMoreAllDoneTitle => 'Du hast alle gelöst!';

  @override
  String get hubMoreOfflineBody =>
      'Verbinde dich mit dem Internet, dann laden weitere Level im Hintergrund. Bis dahin wartet das heutige Tagesrätsel auf dich.';

  @override
  String get hubMoreOnlineBody =>
      'Weitere Level laden im Hintergrund, sobald du online bist. Bis dahin wartet das heutige Tagesrätsel auf dich.';

  @override
  String get hubMoreCheckAgain => 'Erneut prüfen';

  @override
  String hubAchievementOne(String title) {
    return 'Erfolg freigeschaltet: $title';
  }

  @override
  String hubAchievementMany(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Erfolge freigeschaltet!',
    );
    return '$_temp0';
  }

  @override
  String get hubUpdateReady => 'Ein Update ist bereit zur Installation.';

  @override
  String get hubUpdateRestart => 'Neustart';

  @override
  String hubSpanSeconds(int seconds) {
    return '$seconds s';
  }

  @override
  String hubSpanMinutes(int minutes) {
    return '$minutes Min.';
  }

  @override
  String hubSpanMinutesSeconds(int minutes, int seconds) {
    return '$minutes Min. $seconds s';
  }

  @override
  String hubSpanHours(int hours) {
    return '$hours Std.';
  }

  @override
  String hubSpanHoursMinutes(int hours, int minutes) {
    return '$hours Std. $minutes Min.';
  }

  @override
  String get hubParOn => 'genau im Par';

  @override
  String hubParUnder(int percent) {
    return '$percent% unter Par';
  }

  @override
  String hubParOver(int percent) {
    return '$percent% über Par';
  }

  @override
  String get dailyTitle => 'Tagesrätsel';

  @override
  String get dailyCardSemantic => 'Heutige Herausforderung';

  @override
  String get dailyCardUnavailable => 'heutiges Rätsel nicht erreichbar';

  @override
  String get dailyCardSolved => 'gelöst';

  @override
  String dailyCardNextIn(String time) {
    return 'nächstes in $time';
  }

  @override
  String dailyCardEndsIn(String time) {
    return 'endet in $time';
  }

  @override
  String dailyStreakDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count-Tage-Serie',
    );
    return '$_temp0';
  }

  @override
  String dailyStreakMilestone(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count-Tage-Serie!',
    );
    return '$_temp0';
  }

  @override
  String get dailyRankSemantic => 'Bestenliste';

  @override
  String dailyRankSemanticRanked(int rank) {
    return 'Bestenliste, Rang $rank';
  }

  @override
  String get dailyRankSticker => 'RANG';

  @override
  String get dailyLeaveLost =>
      'Deine Züge im heutigen Tagesrätsel werden nicht gespeichert. Du kannst es heute jederzeit neu starten.';

  @override
  String get dailySubmitRefused =>
      'Der Server hat dieses Ergebnis nicht angenommen.';

  @override
  String get dailySubmitFailed =>
      'Gelöst – aber das Ergebnis konnte nicht gesendet werden. Versuch es später nochmal.';

  @override
  String get dailyHudLabel => 'Tagesrätsel';

  @override
  String get dailyHudValue => '';

  @override
  String get dailyDeadEndRestart =>
      'Von hier aus geht es nicht mehr weiter. Starte neu und probier einen anderen Weg.';

  @override
  String dailyDeadEndUndo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Von hier aus geht es nicht mehr weiter. Nimm $count Züge zurück, um wieder auf Kurs zu kommen.',
      one: 'Von hier aus geht es nicht mehr weiter. Nimm 1 Zug zurück, um wieder auf Kurs zu kommen.',
    );
    return '$_temp0';
  }

  @override
  String get dailyActionRestart => 'Neustart';

  @override
  String dailyActionUndo(int count) {
    return '$count zurück';
  }

  @override
  String get dailyNoHint => 'Kein Tipp für diese Stellung.';

  @override
  String get dailyLoadingTitle => 'Heutiges Rätsel wird geladen';

  @override
  String get dailyOffTitle => 'Tagesrätsel sind in dieser Version aus';

  @override
  String get dailyOffDetail =>
      'Die Kampagne ist nicht betroffen – alle Level sind auf diesem Gerät.';

  @override
  String get dailyNoBoardTitle => 'Heute kein Rätsel';

  @override
  String get dailyNoBoardDetail =>
      'Die heutige Herausforderung kommt vom Server, und der war nicht erreichbar. Die Kampagne braucht ihn nicht.';

  @override
  String get dailyLoaderCaption => 'Heutiges Rätsel wird eingeschenkt…';

  @override
  String get dailyBackToLevels => 'Zurück zu den Leveln';

  @override
  String dailyWeekSemantic(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Tage',
      one: '1 Tag',
    );
    return 'Deine Serie: $_temp0. Öffnen';
  }

  @override
  String dailyDaySemantic(String weekday, String state) {
    return '$weekday, $state';
  }

  @override
  String get dailyDayFrozen => 'verpasst, durch Serienschutz gedeckt';

  @override
  String get dailyDayPlayedToday => 'heute gespielt';

  @override
  String get dailyDayPlayed => 'gespielt';

  @override
  String get dailyDayToday => 'heute, noch nicht gespielt';

  @override
  String get dailyDayMissed => 'nicht gespielt';

  @override
  String get dailyDayFuture => 'kommt noch';

  @override
  String get dailyOutcomeBest => 'Neuer Rekord';

  @override
  String get dailyOutcomeSolved => 'Gelöst';

  @override
  String get dailyFigureMoves => 'Züge';

  @override
  String get dailyFigureStreak => 'Serie';

  @override
  String get dailyUnranked => 'ohne Rang';

  @override
  String dailyOfPlayers(int count) {
    return 'von $count';
  }

  @override
  String get dailyReminderOn => 'Du bekommst morgen Abend eine Erinnerung.';

  @override
  String get dailyRemindMe => 'Morgen erinnern';

  @override
  String get dailyDone => 'FERTIG';

  @override
  String get dailyFreezeVideoUnfinished =>
      'Kein Serienschutz – das Video wurde nicht zu Ende geschaut.';

  @override
  String get dailyFreezeNoVideo => 'Gerade ist kein Video verfügbar.';

  @override
  String get dailyFreezeError =>
      'Etwas ist schiefgelaufen. Versuch es später nochmal.';

  @override
  String get dailyFreezeAdded =>
      'Serienschutz erhalten. Ein verpasster Tag ist gedeckt.';

  @override
  String get dailyFreezeNoRoom =>
      'Heute ist kein weiterer Serienschutz möglich.';

  @override
  String get dailyFreezeLoadingVideo => 'Video wird geladen…';

  @override
  String get dailyFreezeWatch => 'Video für Serienschutz ansehen';

  @override
  String get dailyFreezesFull =>
      'Serienschutz voll. Jeder deckt einen verpassten Tag.';

  @override
  String get dailyFreezeTomorrow =>
      'Ein Serienschutz per Video pro Tag. Morgen wieder.';

  @override
  String get dailyStreakTitle => 'Deine Serie';

  @override
  String get dailyStreakNone => 'Noch keine Serie';

  @override
  String get dailyStreakStart =>
      'Spiel das heutige Tagesrätsel, um eine zu starten.';

  @override
  String dailyStreakBest(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Rekord: $count Tage',
      one: 'Rekord: 1 Tag',
    );
    return '$_temp0';
  }

  @override
  String dailyFreezesSemantic(int count, int max) {
    return '$count von $max Serienschutz';
  }

  @override
  String get dailyFreezesTitle => 'Serienschutz';

  @override
  String get dailyFreezesEach => 'Jeder deckt einen verpassten Tag.';

  @override
  String dailyFreezeWeekly(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Jeden Montag einer gratis, in $days Tagen.',
      one: 'Jeden Montag einer gratis, morgen.',
    );
    return '$_temp0';
  }

  @override
  String get dailyCalendarPrevious => 'Vorheriger Monat';

  @override
  String get dailyCalendarNext => 'Nächster Monat';

  @override
  String dailyCalendarCellSemantic(String date, String state) {
    return '$date, $state';
  }

  @override
  String get dailyCalendarPlayed => 'gespielt';

  @override
  String get dailyCalendarFrozen => 'geschützt';

  @override
  String get dailyCalendarFuture => 'kommt noch';

  @override
  String get dailyLegendPlayed => 'Gespielt';

  @override
  String get dailyLegendFrozen => 'Geschützt';

  @override
  String get dailyLegendToday => 'Heute';

  @override
  String get eventTitle => 'Wochen-Event';

  @override
  String get eventUnreachable =>
      'Das Event dieser Woche ist gerade nicht erreichbar.';

  @override
  String get eventEnded => 'beendet';

  @override
  String eventEndsIn(String timeLeft) {
    return 'endet in $timeLeft';
  }

  @override
  String eventTimeLeftDaysHours(int days, int hours) {
    return '$days T. $hours Std.';
  }

  @override
  String eventTimeLeftHours(int hours) {
    return '$hours Std.';
  }

  @override
  String eventTimeLeftMinutes(int minutes) {
    return '$minutes Min.';
  }

  @override
  String eventSummary(int cleared, int total, String endsIn) {
    return '$cleared von $total Rätseln · $endsIn';
  }

  @override
  String get eventFigurePoints => 'Punkte';

  @override
  String eventRankOf(int count) {
    return 'von $count';
  }

  @override
  String get eventRankPlay => 'spiel ein Rätsel für einen Rang';

  @override
  String get eventRankSetName => 'wähl einen Namen für einen Rang';

  @override
  String eventTileSemanticDone(int slot, int stars, int points) {
    String _temp0 = intl.Intl.pluralLogic(
      stars,
      locale: localeName,
      other: '$stars Sterne',
      one: '1 Stern',
    );
    return 'Rätsel $slot, $_temp0, $points Punkte';
  }

  @override
  String eventTileSemanticNew(int slot) {
    return 'Rätsel $slot, nicht gespielt';
  }

  @override
  String eventTilePoints(int points) {
    return '$points P.';
  }

  @override
  String get eventStandingsTitle => 'Rangliste der Woche';

  @override
  String get eventStandingsEmpty =>
      'Noch niemand in der Liste. Sei der oder die Erste.';

  @override
  String eventStandingsCleared(int cleared) {
    return ' · $cleared/7';
  }

  @override
  String get eventSubmitRefused =>
      'Der Server hat das Ergebnis nicht angenommen – vielleicht ist das Event vorbei.';

  @override
  String get eventSubmitFailed =>
      'Gelöst – aber das Ergebnis konnte nicht gesendet werden. Versuch es nochmal.';

  @override
  String eventDeadEndUndo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Von hier aus geht es nicht mehr weiter. Nimm $count Züge zurück.',
      one: 'Von hier aus geht es nicht mehr weiter. Nimm 1 Zug zurück.',
    );
    return '$_temp0';
  }

  @override
  String get eventNoHint => 'Gerade kein Tipp für diese Stellung.';

  @override
  String get eventHudLabel => 'Rätsel';

  @override
  String eventHudBand(String event, String endsIn) {
    return '$event · $endsIn';
  }

  @override
  String get eventSending => 'Wird gesendet…';

  @override
  String eventResult(int points, int total) {
    return '$points Punkte · $total diese Woche';
  }

  @override
  String eventResultRanked(int points, int total, int rank) {
    return '$points Punkte · $total diese Woche · #$rank';
  }

  @override
  String get journeyTitle => 'Reise';

  @override
  String journeyStarsSemantic(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Sterne',
      one: '1 Stern',
    );
    return '$_temp0';
  }

  @override
  String journeyWorldCardSemantic(
    int world,
    int worlds,
    String name,
    int solved,
    int total,
  ) {
    return 'Welt $world von $worlds, $name, $solved von $total gelöst';
  }

  @override
  String journeyWorldOf(int world, int worlds) {
    return 'WELT $world VON $worlds';
  }

  @override
  String journeyRibbonSemantic(int world, String name, int solved, int total) {
    return 'Welt $world, $name, $solved von $total gelöst. Dorthin scrollen';
  }

  @override
  String journeyRibbonLabel(int world, String name) {
    return 'WELT $world · $name';
  }

  @override
  String get journeyYouPin => 'DU';

  @override
  String journeyBandCaps(int world, int count) {
    return 'WELT $world · $count';
  }

  @override
  String get journeyBandFirstPours => 'Erste Schritte';

  @override
  String get journeyBandFindingRhythm => 'Den Rhythmus finden';

  @override
  String get journeyBandDeepWater => 'Tiefe Wasser';

  @override
  String get journeyBandMastery => 'Meisterschaft';

  @override
  String get notifSoftAskTitle => 'Lust auf einen Stups?';

  @override
  String get notifSoftAskBody =>
      'Ein kurzer Hinweis, wenn das heutige Tagesrätsel da ist oder dein nächstes Level wartet. Nie mehr als zwei am Tag, und du kannst sie in den Einstellungen jederzeit ausschalten.';

  @override
  String get notifSoftAskBodyDenied =>
      'Benachrichtigungen für Pourfect sind aus. Schalte sie in den Einstellungen deines Handys ein, um einen Hinweis zu bekommen, wenn das Tagesrätsel da ist oder eine neue Welt erscheint. Nie mehr als zwei am Tag.';

  @override
  String get notifSoftAskOpenSettings => 'Einstellungen öffnen';

  @override
  String get notifSoftAskYes => 'Ja, gern';

  @override
  String get notifChannelName => 'Erinnerungen';

  @override
  String get notifChannelDescription =>
      'Das Tagesrätsel, dein nächstes Level und neue Welten. Nie mehr als zwei am Tag.';

  @override
  String get playHudLevel => 'Level';

  @override
  String playHudTitle(String label, String value) {
    return '$label $value';
  }

  @override
  String get playHudHard => 'SCHWER ×1,5';

  @override
  String get playHudHardLabel => 'Schweres Level, eineinhalbfache Punkte';

  @override
  String get playHudMoves => 'ZÜGE';

  @override
  String playHudMovesLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Züge',
      one: '1 Zug',
    );
    return '$_temp0';
  }

  @override
  String playParLeftFor3Stars(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Noch $count Züge für 3 Sterne',
      one: 'Noch 1 Zug für 3 Sterne',
    );
    return '$_temp0';
  }

  @override
  String get playParSpent => 'Par erreicht · ab jetzt 2 Sterne';

  @override
  String playParLeftFor2Stars(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Noch $count Züge für 2 Sterne',
      one: 'Noch 1 Zug für 2 Sterne',
    );
    return '$_temp0';
  }

  @override
  String get playParOneStarFromHere => 'Ab jetzt 1 Stern · Hauptsache fertig';

  @override
  String get playParAnyFinish => 'Jeder Abschluss bringt 1 Stern';

  @override
  String playParMeterLabel(int stars, int used, int par, String words) {
    return 'Tempo für $stars Sterne, $used von Par $par Zügen. $words';
  }

  @override
  String playHudBusyLabel(String label) {
    return '$label, wird berechnet. Tippen zum Abbrechen';
  }

  @override
  String get playHudUndo => 'Zurück';

  @override
  String get playHudHint => 'Tipp';

  @override
  String get playHudRestart => 'Neustart';

  @override
  String get playExtraTubeLabel => 'Video für eine Extra-Röhre ansehen';

  @override
  String get playExtraTubeChip => '+ Röhre';

  @override
  String playStarsOfTotal(int earned, int total) {
    return '$earned von $total Sternen';
  }

  @override
  String get playDismiss => 'Schließen';

  @override
  String get playLeaveTitleSoSoon => 'Schon so früh weg?';

  @override
  String get playLeaveTitleMissYou => 'Die Kugeln werden dich vermissen';

  @override
  String get playLeaveTitleAbandon => 'Wirklich aufgeben?';

  @override
  String get playLeaveTitleMidPour => 'Mittendrin aufhören?';

  @override
  String get playLeaveBody =>
      'Deine Züge und deine Zeit in diesem Rätsel werden nicht gespeichert.';

  @override
  String get playLeaveKeepPouring => 'Weiterspielen';

  @override
  String get playLeaveConfirm => 'Verlassen';

  @override
  String get playTutorialSkipLabel => 'Tutorial überspringen';

  @override
  String get playTutorialSkip => 'Überspringen';

  @override
  String playTipBubbleLabel(String text) {
    return '$text. Schließen';
  }

  @override
  String get playTipPar =>
      'Schaffst du es im Par, gibt es drei Sterne. Der Balken zeigt, wie viel du verbraucht hast.';

  @override
  String get playTipTallTubes => 'Höhere Röhren! Jede fasst jetzt fünf Kugeln.';

  @override
  String get playTipHint =>
      'Festgefahren? „Tipp“ zeigt dir einen guten nächsten Zug.';

  @override
  String get playTipUndo =>
      'Über Par? „Zurück“ ist gratis – geh so weit zurück, wie du willst.';

  @override
  String get playGuideSorted =>
      'Sortiert! Jetzt bekommt jede Röhre nur eine Farbe.';

  @override
  String get playGuideDrop =>
      'Tippe jetzt, wohin sie sollen: auf dieselbe Farbe oder in eine leere Röhre.';

  @override
  String get playGuideWrongTube =>
      'Tippe auf die Röhre, auf die die Hand zeigt, um stattdessen diese Kugeln zu nehmen.';

  @override
  String get playGuideFirstTap =>
      'Tippe auf eine Röhre, um die oberen Kugeln zu nehmen.';

  @override
  String get playGuideFirstPour => 'Das war ein Zug! Mach weiter.';

  @override
  String get playGuideKeepGoing => 'Weiter so: eine Farbe pro Röhre.';

  @override
  String playCoachHolding(int count) {
    return '$count in der Hand · ab in eine hüpfende Röhre';
  }

  @override
  String get playExtraTubeAdTitle => 'Video für eine Extra-Röhre ansehen?';

  @override
  String get playExtraTubeAdBody =>
      'Eine zusätzliche leere Röhre für dieses Level. Mit Extra-Röhre gibt es höchstens zwei Sterne.';

  @override
  String get playExtraTubeNotFinished =>
      'Keine Röhre – das Video wurde nicht zu Ende geschaut.';

  @override
  String get playExtraTubeSaved =>
      'Gespeichert – deine nächste Röhre ist gratis.';

  @override
  String get playNoVideo => 'Gerade ist kein Video verfügbar.';

  @override
  String get playRewardFailed =>
      'Etwas ist schiefgelaufen. Nichts wurde verbraucht.';

  @override
  String get playHintShowing =>
      'Dein Tipp wird schon angezeigt: Gieß in die leuchtende Röhre.';

  @override
  String get playHintNoneNothingUsed =>
      'Kein Tipp für diese Stellung. Nichts wurde verbraucht.';

  @override
  String get playHintNotFinished =>
      'Kein Tipp – das Video wurde nicht zu Ende geschaut.';

  @override
  String get playHintVideoSaved =>
      'Dein Video ist für den nächsten Tipp gespeichert.';

  @override
  String get playHintNoneVideoSaved =>
      'Kein Tipp für diese Stellung – dein Video ist für den nächsten gespeichert.';

  @override
  String get playHintNone => 'Für diese Stellung gibt es keinen Tipp.';

  @override
  String get playHintHere =>
      'Hier ist dein Tipp – gieß in die leuchtende Röhre.';

  @override
  String get playDeadEndRestart =>
      'Von hier aus geht es nicht mehr weiter. Starte neu und probier einen anderen Weg.';

  @override
  String get playDeadEndRestartTube =>
      'Von hier aus geht es nicht mehr weiter. Starte neu und probier einen anderen Weg. Oder tippe auf + Röhre für eine Ersatzröhre.';

  @override
  String playDeadEndUndo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Von hier aus geht es nicht mehr weiter. Nimm $count Züge zurück, um wieder auf Kurs zu kommen.',
      one: 'Von hier aus geht es nicht mehr weiter. Nimm 1 Zug zurück, um wieder auf Kurs zu kommen.',
    );
    return '$_temp0';
  }

  @override
  String playDeadEndUndoTube(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Von hier aus geht es nicht mehr weiter. Nimm $count Züge zurück, um wieder auf Kurs zu kommen. Oder tippe auf + Röhre für eine Ersatzröhre.',
      one: 'Von hier aus geht es nicht mehr weiter. Nimm 1 Zug zurück, um wieder auf Kurs zu kommen. Oder tippe auf + Röhre für eine Ersatzröhre.',
    );
    return '$_temp0';
  }

  @override
  String playDeadEndUndoAction(int count) {
    return '$count zurück';
  }

  @override
  String get playHintAdTitle => 'Video für einen Tipp ansehen?';

  @override
  String playHintAdFreeLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Du hast noch $count Gratis-Tipps.',
      one: 'Du hast noch 1 Gratis-Tipp.',
    );
    return '$_temp0';
  }

  @override
  String get playHintAdNoneLeft =>
      'Deine Gratis-Tipps sind aufgebraucht. Ein kurzes Video bringt dir einen neuen.';

  @override
  String get playWatch => 'Ansehen';

  @override
  String get playLoadFailed => 'Level konnten nicht geladen werden';

  @override
  String get playTubeSorted => 'SORTIERT!';

  @override
  String get playWinTitlePerfect => 'Einfach\nperfekt!';

  @override
  String get playWinTitleNice => 'Richtig\ngut!';

  @override
  String get playWinTitlePoured => 'Geschafft!';

  @override
  String get playWinLastPour => 'Letzter Zug…';

  @override
  String playWinMovesPar(int count, int par) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ZÜGE · PAR $par',
      one: '1 ZUG · PAR $par',
    );
    return '$_temp0';
  }

  @override
  String playWinLevelBand(int level, String band) {
    return 'Level $level · $band';
  }

  @override
  String get playWinNewBest => 'REKORD!';

  @override
  String playWinMovesChip(int par) {
    return 'Züge · Par $par';
  }

  @override
  String get playWinUntimed => 'ohne Zeit';

  @override
  String get playWinFastest => 'schnellste Zeit!';

  @override
  String get playWinTime => 'Zeit';

  @override
  String get playWinUnderPar => 'UNTER PAR!';

  @override
  String get playWinPoints => 'Punkte';

  @override
  String playWinWorldBand(int world, String band) {
    return 'WELT $world · $band';
  }

  @override
  String get playWinTryAssisted =>
      'Für drei Sterne musst du ohne Extra-Röhre lösen.';

  @override
  String playWinTryShort(int par, int took, int short) {
    String _temp0 = intl.Intl.pluralLogic(
      short,
      locale: localeName,
      other: 'Par $par, du brauchtest $took. $short Züge fehlen zu 3★.',
      one: 'Par $par, du brauchtest $took. Ein Zug fehlt zu 3★.',
    );
    return '$_temp0';
  }

  @override
  String playWinTryInReach(int par) {
    return 'Par $par. Drei Sterne sind drin.';
  }

  @override
  String get playWinTryButton => '3★ HOLEN';

  @override
  String get playWinTryButtonLabel => 'Level für drei Sterne nochmal spielen';

  @override
  String get playWinReplayLabel => 'Level nochmal spielen';

  @override
  String get playWinHomeLabel => 'Zurück zum Startbildschirm';

  @override
  String get playWinNextLevel => 'NÄCHSTES LEVEL';

  @override
  String get playWinBackToLevels => 'ZU DEN LEVELN';

  @override
  String playChestNextAtLabel(int stars) {
    return 'Nächste Sternentruhe bei $stars Sternen';
  }

  @override
  String get playChestOpenLabel => 'Sternentruhe öffnen';

  @override
  String get playChestReady => 'Eine Sternentruhe ist bereit!';

  @override
  String playChestNextAt(int stars) {
    return 'Nächste Truhe bei $stars ★';
  }

  @override
  String get playChestOpen => 'ÖFFNEN';

  @override
  String get playChestDoubleFailed => 'Verdoppeln hat diesmal nicht geklappt.';

  @override
  String get playChestDoubleNotFinished =>
      'Nicht verdoppelt – das Video wurde nicht zu Ende geschaut.';

  @override
  String get playChestOpening => 'Wird geöffnet…';

  @override
  String playChestTitle(int index) {
    return 'Sternentruhe $index';
  }

  @override
  String get playChestNotYetTitle => 'Fast geschafft';

  @override
  String get playChestAlreadyOpenTitle => 'Schon geöffnet';

  @override
  String get playChestFailedTitle => 'Öffnen fehlgeschlagen';

  @override
  String get playChestNotYetNote =>
      'Deine neuesten Sterne sind noch auf dem Weg zum Server. Versuch es gleich nochmal.';

  @override
  String get playChestAlreadyOpenNote =>
      'Diese Truhe wurde auf einem anderen Gerät geöffnet.';

  @override
  String get playChestFailedNote =>
      'Prüfe deine Verbindung und versuch es nochmal.';

  @override
  String playChestRewardCount(int count) {
    return '+$count';
  }

  @override
  String playChestHintsCaption(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Tipps',
      one: 'Tipp',
    );
    return '$_temp0';
  }

  @override
  String playChestTubesCaption(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Extra-Röhren',
      one: 'Extra-Röhre',
    );
    return '$_temp0';
  }

  @override
  String playChestUnlocked(String name) {
    return 'Freigeschaltet: $name';
  }

  @override
  String playChestBallSkinName(String skin) {
    return 'Kugel-Skin $skin';
  }

  @override
  String playChestTubeThemeName(String theme) {
    return 'Röhren-Design $theme';
  }

  @override
  String get playChestNewLook => 'ein neuer Look';

  @override
  String get playChestSavedNote =>
      'Aufgehoben für später. „Tipp“ und „+ Röhre“ nutzen diese zuerst.';

  @override
  String get playChestLoadingVideo => 'Video wird geladen…';

  @override
  String get playChestDouble => 'Mit Video verdoppeln';

  @override
  String get playChestCollect => 'Einsammeln';

  @override
  String playClockLabel(String time) {
    return 'Zeit $time';
  }

  @override
  String playClockDetailLabel(
    String time,
    String par,
    String sign,
    int percent,
  ) {
    String _temp0 = intl.Intl.selectLogic(sign, {
      'plus': 'plus',
      'other': 'minus',
    });
    return 'Zeit $time von Par $par, $_temp0 $percent Prozent Punkte';
  }

  @override
  String playClockBonusChip(String sign, int percent) {
    return '$sign$percent% Pkt.';
  }

  @override
  String get playLoading => 'Wird geladen';

  @override
  String get playWorking => 'Wird berechnet';

  @override
  String get playZenTitle => 'Zen';

  @override
  String get playZenIntro =>
      'Endlose Rätsel. Keine Uhr, keine Sterne, keine Bestenliste – einfach sortieren.';

  @override
  String get playZenPaceCalm => 'Ruhig';

  @override
  String get playZenPaceSteady => 'Gleichmäßig';

  @override
  String get playZenPaceDeep => 'Tief';

  @override
  String playZenPaceColors(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Farben',
      one: '1 Farbe',
    );
    return '$_temp0';
  }

  @override
  String playZenPaceLabel(String pace, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$pace, $count Farben',
      one: '$pace, 1 Farbe',
    );
    return '$_temp0';
  }

  @override
  String playZenBandPoured(String pace, int count) {
    return '$pace · $count gelöst';
  }

  @override
  String playZenPoured(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Geschafft! Schon $count.',
      one: 'Geschafft!',
    );
    return '$_temp0';
  }

  @override
  String get playZenNext => 'WEITER';

  @override
  String get playZenLeaveBody =>
      'Die Züge in diesem Rätsel werden nicht gespeichert. Dein Zähler bleibt.';

  @override
  String get playZenDeadEnd =>
      'Von hier aus geht es nicht mehr weiter. Nimm Züge zurück oder starte neu.';

  @override
  String get playZenNoHint => 'Gerade kein Tipp für diese Stellung.';

  @override
  String get settingsTitle => 'Einstellungen';

  @override
  String get settingsSectionFeel => 'Spielgefühl';

  @override
  String get settingsSectionVisibility => 'Sichtbarkeit';

  @override
  String get settingsSectionLeaderboard => 'Bestenliste';

  @override
  String get settingsSectionNotifications => 'Benachrichtigungen';

  @override
  String get settingsSectionSupport => 'Hilfe';

  @override
  String get settingsSectionAccount => 'Konto & Info';

  @override
  String get settingsSectionDanger => 'Gefahrenzone';

  @override
  String get settingsSoundTitle => 'Soundeffekte';

  @override
  String get settingsSoundDetail => 'Züge, Buttons und Belohnungen';

  @override
  String get settingsSoundVolume => 'Lautstärke Effekte';

  @override
  String get settingsMusicTitle => 'Musik';

  @override
  String get settingsMusicDetail => 'Spielt nie über deine eigene Musik';

  @override
  String get settingsMusicVolume => 'Lautstärke Musik';

  @override
  String get settingsHapticsTitle => 'Vibration';

  @override
  String get settingsHapticsDetail => 'Ein Ticken bei jeder landenden Kugel';

  @override
  String get settingsSmoothMotionTitle => 'Flüssige Bewegung';

  @override
  String get settingsSmoothMotionAuto => 'Auto';

  @override
  String get settingsSmoothMotion60 => '60 Hz';

  @override
  String get settingsSmoothMotionMax => 'Max';

  @override
  String get settingsMotionUnknown =>
      'Auto nutzt die höchste Rate deines Bildschirms, wenn das Handy mithält';

  @override
  String settingsMotionFixed(String max) {
    return 'Dieser Bildschirm läuft nur mit $max Hz';
  }

  @override
  String settingsMotionBatterySaver(String current) {
    return 'Der Energiesparmodus hält ihn bei $current Hz';
  }

  @override
  String settingsMotionAutoStuttered(String current, String max) {
    return 'Läuft mit $current Hz · bei $max Hz hat dieses Handy geruckelt';
  }

  @override
  String settingsMotionAuto(String current) {
    return 'Läuft mit $current Hz · wechselt auf 60 Hz, wenn es ruckelt';
  }

  @override
  String settingsMotionPinnedByPhone(String current) {
    return 'Die Anzeigeeinstellung deines Handys hält ihn bei $current Hz';
  }

  @override
  String settingsMotionStandard(String current, String max) {
    return 'Läuft mit $current Hz · dieser Bildschirm schafft $max Hz';
  }

  @override
  String settingsMotionMax(String current) {
    return 'Läuft mit $current Hz, so schnell wie dieser Bildschirm kann';
  }

  @override
  String get settingsBoldSymbolsTitle => 'Kräftige Symbole';

  @override
  String get settingsBoldSymbolsDetail =>
      'Deutlichere Formen bei Farbenblindheit';

  @override
  String get settingsRenameTitle => 'Namen ändern';

  @override
  String get settingsRenameDetail => 'So siehst du in den Listen aus';

  @override
  String get settingsShowOnBoardsTitle => 'In Bestenlisten zeigen';

  @override
  String get settingsShowOnBoardsDetail =>
      'Aus blendet Name und Rang aus. Sterne zählen weiter.';

  @override
  String get settingsHowToPlayTitle => 'Spielanleitung';

  @override
  String get settingsHowToPlayDetail =>
      'Das erste Level mit Anleitung nochmal spielen';

  @override
  String get settingsQuestionsTitle => 'Fragen';

  @override
  String get settingsQuestionsDetail => 'Sterne, Tipps, die Uhr und mehr';

  @override
  String get settingsRateTitle => 'Pourfect bewerten';

  @override
  String get settingsRateDetail => 'Sag anderen, was du denkst';

  @override
  String get settingsCollectionTitle => 'Sammlung';

  @override
  String get settingsCollectionDetail => 'Kugel-Skins und Röhren-Designs';

  @override
  String get settingsRestoreTitle => 'Käufe wiederherstellen';

  @override
  String get settingsRestoreDetail => 'Werbung entfernen oder Skin-Paket';

  @override
  String get settingsRestoreDone => 'Käufe wiederhergestellt, falls vorhanden.';

  @override
  String get settingsRemoveAdsTitle => 'Werbung entfernen';

  @override
  String get settingsRemoveAdsDetail =>
      'Keine Werbung zwischen Leveln. Tipp-Videos bleiben.';

  @override
  String get settingsAdsRemoved => 'Werbung entfernt – danke';

  @override
  String get settingsPurchaseThanks =>
      'Danke! Werbung zwischen Leveln ist jetzt aus.';

  @override
  String get settingsPurchaseAlreadyOwned =>
      'Bereits gekauft – Werbung ist aus.';

  @override
  String get settingsPurchasePending =>
      'Zahlung ausstehend. Die Werbung verschwindet, sobald sie durch ist.';

  @override
  String get settingsStoreUnavailable =>
      'Der Store ist auf diesem Gerät gerade nicht verfügbar.';

  @override
  String get settingsPurchaseFailed =>
      'Der Kauf hat nicht geklappt. Dir wurde nichts berechnet.';

  @override
  String get settingsStoreOpenFailed =>
      'Der Store konnte nicht geöffnet werden.';

  @override
  String get settingsBrowserOpenFailed =>
      'Der Browser konnte nicht geöffnet werden.';

  @override
  String get settingsSignedIn => 'Angemeldet';

  @override
  String get settingsSignedInDetail => 'Dein Fortschritt zieht mit dir um';

  @override
  String get settingsSaveProgressTitle => 'Fortschritt sichern';

  @override
  String get settingsSaveProgressDetail =>
      'Behalte deine Sterne beim Handywechsel';

  @override
  String get settingsPrivacyPolicy => 'Datenschutzerklärung';

  @override
  String get settingsTermsAndLicenses => 'Bedingungen & Lizenzen';

  @override
  String get settingsTermsOfUse => 'Nutzungsbedingungen';

  @override
  String get settingsRefundPolicy => 'Erstattungsrichtlinie';

  @override
  String get settingsOpenSourceLicenses => 'Open-Source-Lizenzen';

  @override
  String get settingsAdPrivacyTitle => 'Datenschutz bei Werbung';

  @override
  String get settingsAdPrivacyDetail => 'Deine Einwilligung zur Werbung ändern';

  @override
  String get settingsResetRowTitle => 'Fortschritt zurücksetzen';

  @override
  String get settingsResetRowDetail =>
      'Alle Sterne löschen und bei Level 1 beginnen';

  @override
  String get settingsResetTitle => 'Fortschritt zurücksetzen?';

  @override
  String get settingsResetNothing => 'Es gibt noch nichts zurückzusetzen.';

  @override
  String settingsResetBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Damit werden alle Sterne und Bestwerte aus $count gelösten Leveln gelöscht, und alles nach Level 1 wird wieder gesperrt. Das lässt sich nicht rückgängig machen.',
      one: 'Damit werden alle Sterne und Bestwerte aus 1 gelösten Level gelöscht, und alles nach Level 1 wird wieder gesperrt. Das lässt sich nicht rückgängig machen.',
    );
    return '$_temp0';
  }

  @override
  String get settingsKeepIt => 'Behalten';

  @override
  String get settingsResetConfirm => 'Alles löschen';

  @override
  String get settingsResetDone => 'Fortschritt zurückgesetzt.';

  @override
  String get settingsSignOutTitle => 'Abmelden?';

  @override
  String get settingsSignOutBody =>
      'Dein Fortschritt bleibt auf diesem Handy. Du kannst dich jederzeit wieder anmelden und woanders weiterspielen.';

  @override
  String get settingsSignOutStay => 'Angemeldet bleiben';

  @override
  String get settingsSignOutConfirm => 'Abmelden';

  @override
  String get settingsServerUnreachable =>
      'Der Server ist nicht erreichbar, daher hat sich nichts geändert.';

  @override
  String get settingsDeleteRowTitle => 'Konto löschen';

  @override
  String get settingsDeleteRowDetail => 'Dein Konto und alles darin entfernen';

  @override
  String get settingsDeleteTitle => 'Konto löschen?';

  @override
  String get settingsDeleteBody =>
      'Damit werden dein Konto, deine Sterne, deine Serie und dein Eintrag in der Bestenliste entfernt, auf diesem Handy und auf unserem Server. Das lässt sich nicht rückgängig machen.\n\n„Werbung entfernen“ ist davon nicht betroffen – der Kauf gehört zu dem Store-Konto, mit dem du ihn getätigt hast, und wird wiederhergestellt, wenn du wieder spielst.';

  @override
  String get settingsDeleteConfirm => 'Alles löschen';

  @override
  String get settingsDeleteServerRefused =>
      'Der Server ist nicht erreichbar. Nichts wurde gelöscht – versuch es nochmal, wenn du wieder online bist.';

  @override
  String get settingsDeleteNotAuthenticated =>
      'Wir konnten nicht bestätigen, dass du es bist. Melde dich erneut an und lösche dann dein Konto – bisher wurde nichts gelöscht.';

  @override
  String settingsFooterVersion(String version) {
    return 'Pourfect $version';
  }

  @override
  String settingsFooterVersionBoards(int count, String version) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Pourfect $version · mit $count nachweislich lösbaren Rätseln',
      one: 'Pourfect $version · mit 1 nachweislich lösbaren Rätsel',
    );
    return '$_temp0';
  }

  @override
  String get settingsNamingYou => 'Name wird vergeben…';

  @override
  String get settingsYourName => 'Dein Name';

  @override
  String get settingsGuest => 'Du spielst als Gast';

  @override
  String get settingsStatSolved => 'GELÖST';

  @override
  String get settingsStatStars => 'STERNE';

  @override
  String get settingsNotifyTurnOnTitle => 'Benachrichtigungen einschalten';

  @override
  String get settingsNotifyDeniedDetail =>
      'In den Handy-Einstellungen aus. Tippen zum Öffnen.';

  @override
  String get settingsNotifyNotYetDetail =>
      'Pourfect darf dich noch nicht benachrichtigen';

  @override
  String get settingsRemindersTitle => 'Tagesrätsel-Erinnerungen';

  @override
  String get settingsRemindersDetail =>
      'Morgens und abends, nie mehr als zwei am Tag';

  @override
  String get settingsNewsTitle => 'Spiel-News';

  @override
  String get settingsNewsDetail => 'Neue Welten und Ankündigungen';

  @override
  String settingsToggleOn(String title) {
    return '$title, an';
  }

  @override
  String settingsToggleOff(String title) {
    return '$title, aus';
  }

  @override
  String get settingsFaqSectionPlaying => 'Spielen';

  @override
  String get settingsFaqSectionStuck => 'Festgefahren?';

  @override
  String get settingsFaqSectionProgress => 'Dein Fortschritt';

  @override
  String get settingsFaqSectionAds => 'Werbung & Sound';

  @override
  String get settingsFaqHowToPlayQ => 'Wie spiele ich?';

  @override
  String get settingsFaqHowToPlayA =>
      'Tippe auf eine Röhre, um ihre oberen Kugeln zu nehmen, und dann auf eine andere Röhre, um sie hineinzugießen. Kugeln landen nur auf derselben Farbe oder in einer leeren Röhre. Sortiere jede Röhre auf eine Farbe, dann ist das Level geschafft. Unter Einstellungen → Spielanleitung kannst du das erste Level mit Anleitung nochmal spielen.';

  @override
  String get settingsFaqStarsQ => 'Was bedeuten die Sterne?';

  @override
  String get settingsFaqStarsA =>
      'Sterne zählen nur Züge, sonst nichts. Schaffst du es im Par oder mit weniger Zügen, gibt es drei Sterne, mit höchstens dem Eineinhalbfachen des Pars zwei, und jeder Abschluss bringt einen. Par ist die kleinste Zahl an Zügen, mit der sich das Level lösen lässt.';

  @override
  String get settingsFaqClockQ => 'Kostet mich die Uhr Sterne?';

  @override
  String get settingsFaqClockA =>
      'Nie. Die Zeit ändert nur deine Punkte. Unterbiete die Zeitvorgabe für Bonuspunkte oder lass dir so viel Zeit, wie du willst, und behalte jeden Stern.';

  @override
  String get settingsFaqSolvableQ => 'Ist jedes Level lösbar?';

  @override
  String get settingsFaqSolvableA =>
      'Ja. Jedes Rätsel wurde gelöst, bevor es ins Spiel kam, und das Par stammt aus dieser Lösung, ist also immer erreichbar.';

  @override
  String get settingsFaqDailyQ => 'Was ist das Tagesrätsel?';

  @override
  String get settingsFaqDailyA =>
      'Jeden Tag ein neues Rätsel mit eigener Bestenliste. Dafür brauchst du eine Internetverbindung. Die Kampagnenlevel nicht.';

  @override
  String get settingsFaqUndoQ => 'Ist „Zurück“ begrenzt?';

  @override
  String get settingsFaqUndoA =>
      'Nein. „Zurück“ ist gratis und unbegrenzt, in jedem Level.';

  @override
  String get settingsFaqHintsQ => 'Wie funktionieren Tipps?';

  @override
  String settingsFaqHintsA(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Deine ersten $count Tipps sind gratis. Danach bringt dir ein kurzes Video einen neuen. Wird kein Tipp gefunden, zählt das Video trotzdem für deinen nächsten.',
      one: 'Dein erster Tipp ist gratis. Danach bringt dir ein kurzes Video einen neuen. Wird kein Tipp gefunden, zählt das Video trotzdem für deinen nächsten.',
    );
    return '$_temp0';
  }

  @override
  String get settingsFaqTubeQ => 'Was ist der Button „+ Röhre“?';

  @override
  String get settingsFaqTubeA =>
      'Wenn deine Züge das Par erreichen oder ein Tipp zeigt, dass es nicht mehr weitergeht, kannst du ein Video für eine zusätzliche leere Röhre ansehen, bis zu zwei pro Versuch. „Zurück“ nimmt sie dir nicht weg. Mit Extra-Röhre gibt es höchstens zwei Sterne.';

  @override
  String get settingsFaqHardQ => 'Was sind SCHWER-Level?';

  @override
  String get settingsFaqHardA =>
      'Das härteste Level von je zehn trägt ein rotes SCHWER-Abzeichen. Es spielt sich wie jedes andere Level und bringt die eineinhalbfachen Punkte.';

  @override
  String get settingsFaqChestsQ => 'Was sind Sternentruhen?';

  @override
  String get settingsFaqChestsA =>
      'Alle 30 Sterne öffnet sich auf deiner Reise eine Truhe: zwei Tipps und eine Extra-Röhre, aufgehoben für später. Jede dritte Truhe schaltet außerdem einen Kugel-Skin frei.';

  @override
  String get settingsFaqFreezeQ => 'Was ist ein Serienschutz?';

  @override
  String get settingsFaqFreezeA =>
      'Verpasst du einen Tag beim Tagesrätsel, deckt ihn ein Serienschutz, und deine Serie läuft weiter. Du bekommst jeden Montag einen gratis, kannst dir pro Tag einen per Video verdienen und bis zu zwei aufheben.';

  @override
  String get settingsFaqAccountQ => 'Brauche ich ein Konto?';

  @override
  String get settingsFaqAccountA =>
      'Nein. Du spielst als Gast, und dein Fortschritt wird auf diesem Handy gespeichert. Wenn du dich anmeldest, behältst du deine Sterne beim Wechsel auf ein neues Handy.';

  @override
  String get settingsFaqOfflineQ => 'Kann ich offline spielen?';

  @override
  String get settingsFaqOfflineA =>
      'Ja, die ganze Kampagne. Das Tagesrätsel und die Bestenlisten brauchen eine Verbindung, und dein Fortschritt wird synchronisiert, sobald du wieder online bist.';

  @override
  String get settingsFaqNameQ =>
      'Wie ändere ich meinen Namen in der Bestenliste?';

  @override
  String get settingsFaqNameA =>
      'Einstellungen → Namen ändern. Dort kannst du dich auch aus den Listen ausblenden; deine Sterne zählen trotzdem.';

  @override
  String get settingsFaqRemoveAdsQ => 'Was bringt „Werbung entfernen“?';

  @override
  String get settingsFaqRemoveAdsA =>
      'Es schaltet die Werbung zwischen den Leveln ab. Videos für Tipps und Röhren bleiben, denn die siehst du nur, wenn du selbst darum bittest.';

  @override
  String get settingsFaqReinstallQ =>
      'Ich habe neu installiert. Wo ist „Werbung entfernen“ hin?';

  @override
  String get settingsFaqReinstallA =>
      'Der Kauf gehört zu dem Store-Konto, mit dem du ihn getätigt hast, und kommt meist von selbst zurück. Falls nicht, tippe auf Einstellungen → Käufe wiederherstellen.';

  @override
  String get settingsFaqMusicQ => 'Stoppt das Spiel meine Musik?';

  @override
  String get settingsFaqMusicA =>
      'Nein. Pourfect spielt seine Sounds neben deiner Musik oder deinem Podcast. Sound und Vibration kannst du in den Einstellungen ausschalten.';

  @override
  String get settingsLegalTitle => 'Bevor es losgeht';

  @override
  String get settingsLegalIntro =>
      'Pourfect ist kostenlos, funktioniert offline und braucht kein Konto. Bitte lies und akzeptiere zuerst Folgendes.';

  @override
  String settingsLegalAcceptTerms(String document) {
    return 'Ich akzeptiere die $document';
  }

  @override
  String settingsLegalReadPrivacy(String document) {
    return 'Ich habe die $document gelesen';
  }

  @override
  String settingsLegalAlsoCovers(String document, String version) {
    return 'Damit akzeptierst du auch unsere $document (Version $version).';
  }

  @override
  String get settingsLegalPrivacyPolicy => 'Datenschutzerklärung';

  @override
  String get settingsLegalTermsOfService => 'Nutzungsbedingungen';

  @override
  String get settingsLegalRefundPolicy => 'Erstattungsrichtlinie';

  @override
  String settingsLegalReadDocument(String document) {
    return '$document lesen';
  }

  @override
  String get settingsLegalAccept => 'LOS GEHT\'S!';

  @override
  String get settingsLegalReadAgain =>
      'Du kannst das alles jederzeit in den Einstellungen nachlesen.';

  @override
  String get settingsLegalLoadFailed =>
      'Dieses Dokument konnte auf diesem Gerät nicht geladen werden.\n\nDu kannst es vor dem Akzeptieren unter legal.pranta.dev lesen.';

  @override
  String get settingsUpdateTitle => 'Ein neues Pourfect ist da';

  @override
  String get settingsUpdateBody =>
      'Google Play lädt es herunter und öffnet das Spiel danach wieder. Deine Sterne sind sicher.';

  @override
  String get settingsUpdateMandatoryTitle => 'Zeit für ein Update';

  @override
  String get settingsUpdateMandatoryBody =>
      'Diese Version von Pourfect wird nicht mehr unterstützt. Google Play lädt das Update herunter und öffnet das Spiel danach wieder. Deine Sterne sind sicher.';

  @override
  String get settingsUpdateNow => 'Jetzt updaten';

  @override
  String get settingsRenameHello => 'HALLO';

  @override
  String get settingsRenameMyNameIs => 'ICH HEISSE';

  @override
  String get settingsRenameHint =>
      'Andere sehen diesen Namen in den Bestenlisten';

  @override
  String get settingsRenameSave => 'SPEICHERN';

  @override
  String settingsCollectionUnlockWith(String how) {
    return 'Freischalten mit: $how.';
  }

  @override
  String get settingsCollectionChangeFailed =>
      'Das ging gerade nicht. Versuch es später nochmal.';

  @override
  String get settingsPackThanks =>
      'Danke! Das Paket wird gleich freigeschaltet.';

  @override
  String get settingsPackAlreadyOwned =>
      'Gehört dir schon. Wird jetzt wiederhergestellt.';

  @override
  String get settingsPackPending =>
      'Zahlung ausstehend. Das Paket wird freigeschaltet, sobald sie durch ist.';

  @override
  String get settingsCollectionOffline =>
      'Verbinde dich mit dem Internet, um deine Sammlung zu sehen.';

  @override
  String get settingsCollectionBallSkins => 'Kugel-Skins';

  @override
  String get settingsCollectionTubeThemes => 'Röhren-Designs';

  @override
  String settingsCollectionPreview(String skin, String theme) {
    return 'Kugeln $skin · Röhren $theme';
  }

  @override
  String settingsCollectionItemWorn(String name) {
    return '$name, aktiv';
  }

  @override
  String settingsCollectionItemTapToWear(String name) {
    return '$name, tippen zum Auswählen';
  }

  @override
  String settingsCollectionItemLocked(String name, String how) {
    return '$name, gesperrt: $how';
  }

  @override
  String get settingsCollectionWearing => 'Aktiv';

  @override
  String get settingsCollectionTapToWear => 'Auswählen';

  @override
  String settingsUnlockChest(int number) {
    return 'Sternentruhe $number';
  }

  @override
  String settingsUnlockStreak(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days-Tage-Serie',
    );
    return '$_temp0';
  }

  @override
  String get settingsUnlockFree => 'Gratis';

  @override
  String get settingsSkinPack => 'Skin-Paket';

  @override
  String get settingsSkinPackDetail =>
      'Kugeln Marmor, Perle und Karo, Röhren Holz und Flieder.';

  @override
  String get settingsOwned => 'GEKAUFT';

  @override
  String get settingsSoon => 'Bald';

  @override
  String get settingsSkinClassic => 'Klassisch';

  @override
  String get settingsSkinGlossy => 'Glanz';

  @override
  String get settingsSkinStriped => 'Zuckerstange';

  @override
  String get settingsSkinGlow => 'Leuchten';

  @override
  String get settingsSkinSpeckled => 'Streusel';

  @override
  String get settingsSkinMarble => 'Marmor';

  @override
  String get settingsSkinPearl => 'Perle';

  @override
  String get settingsSkinChecker => 'Karo';

  @override
  String get settingsTubeToy => 'Spielzeug';

  @override
  String get settingsTubeFrost => 'Frost';

  @override
  String get settingsTubeWood => 'Holz';

  @override
  String get settingsTubeLilac => 'Flieder';
}

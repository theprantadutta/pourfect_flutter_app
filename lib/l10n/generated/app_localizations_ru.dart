// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get accountGoogleFailed =>
      'Вход через Google не сработал на этом телефоне. Попробуй ещё раз или войди по почте ниже.';

  @override
  String get accountAppleFailed =>
      'Вход через Apple не сработал на этом телефоне. Проверь, что ты вошёл в Аккаунт Apple в Настройках, или войди по почте ниже.';

  @override
  String get accountExistsNoLocal =>
      'У тебя уже есть аккаунт с этой почтой. Войди в него, и телефон загрузит сохранённые там звёзды.';

  @override
  String accountExistsWithLocal(int solved) {
    String _temp0 = intl.Intl.pluralLogic(
      solved,
      locale: localeName,
      other:
          'У тебя уже есть аккаунт с этой почтой. На телефоне есть $solved решённого уровня, которых нет в аккаунте, а объединить их нельзя — при входе они заменятся тем, что хранится в аккаунте.',
      many:
          'У тебя уже есть аккаунт с этой почтой. На телефоне есть $solved решённых уровней, которых нет в аккаунте, а объединить их нельзя — при входе они заменятся тем, что хранится в аккаунте.',
      few:
          'У тебя уже есть аккаунт с этой почтой. На телефоне есть $solved решённых уровня, которых нет в аккаунте, а объединить их нельзя — при входе они заменятся тем, что хранится в аккаунте.',
      one:
          'У тебя уже есть аккаунт с этой почтой. На телефоне есть $solved решённый уровень, которого нет в аккаунте, а объединить их нельзя — при входе он заменится тем, что хранится в аккаунте.',
    );
    return '$_temp0';
  }

  @override
  String get accountEmailInUse =>
      'Аккаунт с этой почтой уже есть. Попробуй войти в него.';

  @override
  String get accountEmailMalformed => 'Это не похоже на адрес почты.';

  @override
  String get accountPasswordWeak =>
      'Этот пароль слишком легко угадать. Попробуй подлиннее.';

  @override
  String get accountWrongPassword => 'Почта и пароль не совпадают.';

  @override
  String get accountTooManyAttempts =>
      'Слишком много попыток. Подожди пару минут и попробуй снова.';

  @override
  String get accountNeedsRecentLogin => 'Сначала войди ещё раз.';

  @override
  String get accountMethodNotEnabled =>
      'Вход по почте сейчас недоступен. Попробуй «Продолжить с Google».';

  @override
  String get accountSessionUnavailable =>
      'Вход выполнен, но прогресс ещё не сохранён на сервере. Он синхронизируется, когда появится связь.';

  @override
  String get accountUnavailable =>
      'Не удалось связаться с сервером. Твой прогресс по-прежнему в безопасности на этом устройстве.';

  @override
  String get accountUseThatAccount => 'Войти в него';

  @override
  String get accountExistingTitle => 'У тебя уже есть аккаунт';

  @override
  String get accountExistingBodyEmpty =>
      'Телефон загрузит звёзды, которые уже сохранены в нём.';

  @override
  String accountExistingBodyLocal(int cleared) {
    String _temp0 = intl.Intl.pluralLogic(
      cleared,
      locale: localeName,
      other:
          'На телефоне есть $cleared решённого уровня, которых нет в том аккаунте. Объединить их нельзя, поэтому они заменятся тем, что уже хранится в аккаунте.',
      many:
          'На телефоне есть $cleared решённых уровней, которых нет в том аккаунте. Объединить их нельзя, поэтому они заменятся тем, что уже хранится в аккаунте.',
      few:
          'На телефоне есть $cleared решённых уровня, которых нет в том аккаунте. Объединить их нельзя, поэтому они заменятся тем, что уже хранится в аккаунте.',
      one:
          'На телефоне есть $cleared решённый уровень, которого нет в том аккаунте. Объединить их нельзя, поэтому он заменится тем, что уже хранится в аккаунте.',
    );
    return '$_temp0';
  }

  @override
  String get accountSignIn => 'Войти';

  @override
  String get accountSignInCancelled => 'Вход отменён. Ничего не изменилось.';

  @override
  String get accountSignedInToast =>
      'Вход выполнен. Теперь звёзды перейдут с тобой на новый телефон.';

  @override
  String get accountResetNeedsEmail =>
      'Сначала введи почту, потом нажми «Забыл пароль?».';

  @override
  String get accountResetSent =>
      'Если на эту почту есть аккаунт, ссылка для сброса уже в пути.';

  @override
  String get accountYourAccount => 'Твой аккаунт';

  @override
  String accountRankValue(int rank) {
    return '#$rank';
  }

  @override
  String accountStreakValue(int days) {
    return '$days д';
  }

  @override
  String get accountCardTravels =>
      'Эта карточка привязана к аккаунту, так что на новом телефоне ты продолжишь с того же места.';

  @override
  String get accountYourNameHeader => 'Твоё имя';

  @override
  String get accountChangeName => 'Сменить имя';

  @override
  String get accountChangeNameDetail => 'Как тебя видят в рейтингах';

  @override
  String get accountShowOnBoards => 'Показывать меня в рейтингах';

  @override
  String get accountShowOnBoardsDetail =>
      'Скрывает имя и место. Звёзды всё равно идут в зачёт.';

  @override
  String get accountYourPlayHeader => 'Твоя игра';

  @override
  String get accountStatistics => 'Статистика';

  @override
  String get accountStatisticsDetail => 'Время, активность и все уровни';

  @override
  String get accountSessionHeader => 'Сеанс';

  @override
  String get accountDeleteHint =>
      'Чтобы удалить аккаунт, открой Настройки → Опасная зона.';

  @override
  String get accountVisibilityFailed =>
      'Не удалось связаться с сервером, ничего не изменилось.';

  @override
  String get accountSignOutTitle => 'Выйти?';

  @override
  String get accountSignOutBody =>
      'Прогресс останется на этом телефоне. Войди снова в любой момент, чтобы продолжить на другом устройстве.';

  @override
  String get accountStaySignedIn => 'Остаться';

  @override
  String get accountSignOut => 'Выйти';

  @override
  String get accountSignOutDetail => 'Прогресс останется на телефоне';

  @override
  String get accountSaveTitle => 'Сохрани прогресс';

  @override
  String get accountSaveIntro =>
      'Звёзды, серия и имя в рейтинге привязаны к аккаунту, так что на новом телефоне ты продолжишь с того же места.';

  @override
  String get accountContinueApple => 'Продолжить с Apple';

  @override
  String get accountContinueGoogle => 'Продолжить с Google';

  @override
  String get accountOr => 'ИЛИ';

  @override
  String get accountEmailLabel => 'Почта';

  @override
  String get accountEmailEmpty => 'Введи почту.';

  @override
  String get accountPasswordLabel => 'Пароль';

  @override
  String get accountPasswordHelper => 'Не меньше 8 символов';

  @override
  String get accountPasswordEmpty => 'Введи пароль.';

  @override
  String get accountPasswordShort => 'Не меньше 8 символов.';

  @override
  String get accountShowPassword => 'Показать пароль';

  @override
  String get accountHidePassword => 'Скрыть пароль';

  @override
  String get accountCreate => 'Создать аккаунт';

  @override
  String get accountSwitchToSignIn => 'Уже есть аккаунт? Войти';

  @override
  String get accountSwitchToSignInSemantic => 'Войти в существующий аккаунт';

  @override
  String get accountSwitchToCreate => 'Нет аккаунта? Создай его';

  @override
  String get accountSwitchToCreateSemantic => 'Создать новый аккаунт';

  @override
  String get accountForgotPassword => 'Забыл пароль?';

  @override
  String get accountForgotPasswordSemantic => 'Сбросить пароль';

  @override
  String get accountNaming => 'Придумываем имя…';

  @override
  String get accountSignedInLabel => 'Вход выполнен';

  @override
  String accountPouringSince(String month, int year) {
    return 'В ИГРЕ С $month $year';
  }

  @override
  String get accountPlayerCardTag => 'КАРТОЧКА';

  @override
  String get accountStatSolved => 'РЕШЕНО';

  @override
  String get accountStatStars => 'ЗВЁЗДЫ';

  @override
  String get accountStatStreak => 'СЕРИЯ';

  @override
  String get accountStatRank => 'МЕСТО';

  @override
  String accountStarsValue(int stars) {
    return '$stars★';
  }

  @override
  String get accountSyncing => 'Синхронизация…';

  @override
  String get accountSyncingDetail => 'Сохраняем прогресс в аккаунт';

  @override
  String get accountWaitingToSync => 'Ждёт синхронизации';

  @override
  String get accountWaitingOffline => 'Сохранится, когда появится сеть';

  @override
  String get accountWaitingPending => 'Новые уровни отправятся следующими';

  @override
  String get accountSyncedDetail => 'Прогресс сохранён в аккаунте';

  @override
  String get accountSynced => 'Синхронизировано';

  @override
  String get accountSyncedJustNow => 'Синхронизировано только что';

  @override
  String accountSyncedMinutesAgo(int minutes) {
    return 'Синхр. $minutes мин назад';
  }

  @override
  String accountSyncedHoursAgo(int hours) {
    return 'Синхр. $hours ч назад';
  }

  @override
  String accountSyncedDaysAgo(int days) {
    return 'Синхр. $days д назад';
  }

  @override
  String get accountCrestSignedIn => 'Твой аккаунт';

  @override
  String get accountCrestGuest => 'Игра в гостевом режиме';

  @override
  String get accountRenameRefused => 'Это имя не подошло.';

  @override
  String get accountRenameOffline =>
      'Не удалось связаться с сервером. Попробуй чуть позже.';

  @override
  String get ranksTitle => 'Рейтинг';

  @override
  String get ranksTabToday => 'Сегодня';

  @override
  String get ranksTabCampaign => 'Кампания';

  @override
  String get ranksLoading => 'Загружаем рейтинг…';

  @override
  String get ranksEmptyDailyTitle => 'Сегодня ещё никто не прошёл задачу';

  @override
  String get ranksEmptyDailyDetail => 'Будь первым.';

  @override
  String get ranksEmptyCampaignTitle => 'В рейтинге пока никого';

  @override
  String get ranksEmptyCampaignDetail => 'Здесь всё решают звёзды.';

  @override
  String get ranksYourSpot => 'Твоё место';

  @override
  String ranksPlayerCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString игрока в рейтинге',
      many: '$countString игроков в рейтинге',
      few: '$countString игрока в рейтинге',
      one: '$countString игрок в рейтинге',
    );
    return '$_temp0';
  }

  @override
  String ranksMoves(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count хода',
      many: '$count ходов',
      few: '$count хода',
      one: '$count ход',
    );
    return '$_temp0';
  }

  @override
  String ranksStars(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count звезды',
      many: '$count звёзд',
      few: '$count звезды',
      one: '$count звезда',
    );
    return '$_temp0';
  }

  @override
  String ranksLevels(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count уровня',
      many: '$count уровней',
      few: '$count уровня',
      one: '$count уровень',
    );
    return '$_temp0';
  }

  @override
  String ranksInTime(String time) {
    return 'за $time';
  }

  @override
  String get ranksOpenSpot => 'Свободно';

  @override
  String ranksNameYou(String name) {
    return '$name (ты)';
  }

  @override
  String ranksPlaceOpen(int place) {
    return '$place место, свободно';
  }

  @override
  String ranksPlaceSemantic(int rank, String name, String score) {
    return '$rank место, $name, $score';
  }

  @override
  String ranksScoreWithTieBreak(String score, String tieBreak) {
    return '$score, $tieBreak';
  }

  @override
  String get ranksOffTitle => 'В этой сборке рейтинги выключены';

  @override
  String get ranksOffDetail => 'На кампанию это не влияет.';

  @override
  String get ranksLoadFailed => 'Не удалось загрузить рейтинг';

  @override
  String get ranksOffline => 'Похоже, нет сети. Все уровни играются и без неё.';

  @override
  String get ranksTimeout => 'Сервер слишком долго не отвечал.';

  @override
  String get ranksServerError =>
      'Что-то сломалось на нашей стороне. Твой прогресс в безопасности.';

  @override
  String get ranksHiddenTitle => 'Ты скрыт';

  @override
  String get ranksHiddenDetail =>
      'Звёзды и серия всё равно идут в зачёт — просто тебя здесь не видно. Переключатель в Настройках.';

  @override
  String get statsTitle => 'Статистика';

  @override
  String get statsTabOverview => 'Обзор';

  @override
  String get statsTabLevels => 'Уровни';

  @override
  String get statsTabBadges => 'Награды';

  @override
  String get statsPaceOnPar => 'в пар';

  @override
  String statsPaceUnder(int percent) {
    return 'на $percent% быстрее';
  }

  @override
  String statsPaceOver(int percent) {
    return 'на $percent% дольше';
  }

  @override
  String get statsEmptyTitle => 'Пока пусто';

  @override
  String get statsEmptyBody =>
      'Реши уровень, и здесь появится время против пара, лучшие решения и дни, когда ты играл.';

  @override
  String get statsBackToLevels => 'К уровням';

  @override
  String get statsLevelsSolved => 'уровней решено';

  @override
  String get statsStars => 'звёзд';

  @override
  String get statsPoints => 'очков';

  @override
  String get statsPlayed => 'в игре';

  @override
  String get statsNowOn => 'сейчас';

  @override
  String get statsBestSolveMoves => 'ходов в лучших решениях';

  @override
  String get statsAgainstClock => 'НА ВРЕМЯ';

  @override
  String get statsNoTimes =>
      'Времени пока нет. У уровней, пройденных до появления часов, время не записано — перепройди любой, и отсчёт начнётся.';

  @override
  String get statsFastest => 'Быстрее всего';

  @override
  String get statsLongest => 'Дольше всего';

  @override
  String get statsAvgPace => 'Ср. темп';

  @override
  String statsClockValue(String time, int level) {
    return '$time · У$level';
  }

  @override
  String statsUntimed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count из твоих решённых уровней пройдены до появления часов, и время для них не записано.',
      many:
          '$count из твоих решённых уровней пройдены до появления часов, и время для них не записано.',
      few:
          '$count из твоих решённых уровней пройдены до появления часов, и время для них не записано.',
      one:
          '$count из твоих решённых уровней пройден до появления часов, и время для него не записано.',
    );
    return '$_temp0';
  }

  @override
  String statsUnderParSemantic(int under, int total) {
    return '$under из $total уровней со временем быстрее пара';
  }

  @override
  String get statsUnderParTag => 'БЫСТРЕЕ';

  @override
  String get statsLast30Days => 'ПОСЛЕДНИЕ 30 ДНЕЙ';

  @override
  String statsStreakChip(int count) {
    return 'Серия: $count д';
  }

  @override
  String get statsNoStreak => 'нет серии';

  @override
  String statsDaysPlayed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count дня в игре',
      many: '$count дней в игре',
      few: '$count дня в игре',
      one: '$count день в игре',
    );
    return '$_temp0';
  }

  @override
  String statsLevelsFinished(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count уровня пройдено',
      many: '$count уровней пройдено',
      few: '$count уровня пройдено',
      one: '$count уровень пройден',
    );
    return '$_temp0';
  }

  @override
  String statsBestStreak(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'рекорд $count дня',
      many: 'рекорд $count дней',
      few: 'рекорд $count дня',
      one: 'рекорд $count день',
    );
    return '$_temp0';
  }

  @override
  String get statsToday => 'Сегодня';

  @override
  String statsMonthShort(String month) {
    String _temp0 = intl.Intl.selectLogic(month, {
      'jan': 'янв',
      'feb': 'фев',
      'mar': 'мар',
      'apr': 'апр',
      'may': 'мая',
      'jun': 'июн',
      'jul': 'июл',
      'aug': 'авг',
      'sep': 'сен',
      'oct': 'окт',
      'nov': 'ноя',
      'dec': 'дек',
      'other': '$month',
    });
    return '$_temp0';
  }

  @override
  String statsMonthDay(String month, int day) {
    return '$day $month';
  }

  @override
  String statsBarLevels(String day, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$day · $count уровня',
      many: '$day · $count уровней',
      few: '$day · $count уровня',
      one: '$day · $count уровень',
    );
    return '$_temp0';
  }

  @override
  String statsBarNoPlay(String day) {
    return '$day · без игры';
  }

  @override
  String get statsWorldAhead => 'впереди';

  @override
  String get statsWorldNoTimes => 'нет времени';

  @override
  String statsWorldPoints(int points) {
    final intl.NumberFormat pointsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String pointsString = pointsNumberFormat.format(points);

    return '$pointsString очк.';
  }

  @override
  String statsWorldSolvedSemantic(String name, int cleared, int total) {
    return '$name: решено $cleared из $total';
  }

  @override
  String statsWorldPaceSemantic(String pace) {
    return 'темп: $pace';
  }

  @override
  String statsWorldPointsSemantic(int points) {
    final intl.NumberFormat pointsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String pointsString = pointsNumberFormat.format(points);

    return 'очков: $pointsString';
  }

  @override
  String get statsColLevel => 'УР.';

  @override
  String get statsColStars => 'ЗВЁЗДЫ';

  @override
  String get statsColMoves => 'ХОДЫ';

  @override
  String get statsColTime => 'ВРЕМЯ';

  @override
  String get statsColPoints => 'ОЧК.';

  @override
  String statsMovesBestPossible(int moves, int best) {
    return 'Ходов: $moves, лучший результат: $best';
  }

  @override
  String statsMoves(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count хода',
      many: '$count ходов',
      few: '$count хода',
      one: '$count ход',
    );
    return '$_temp0';
  }

  @override
  String badgeUnlockedCount(int earned, int total) {
    return 'Открыто $earned из $total';
  }

  @override
  String get badgeUnlocked => 'Открыто';

  @override
  String get badgeNotYet => 'Пока нет';

  @override
  String badgeProgress(int shown, int target) {
    return '$shown из $target';
  }

  @override
  String badgeSemantic(String title, String description, String status) {
    return '$title: $description $status';
  }

  @override
  String get badgeFirstPourTitle => 'Первый ход';

  @override
  String get badgeFirstPourDesc => 'Пройди первый уровень.';

  @override
  String get badgePar10Title => 'В пар';

  @override
  String get badgePar10Desc => 'Пройди 10 уровней ровно в пар.';

  @override
  String get badgePar50Title => 'Мастер пара';

  @override
  String get badgePar50Desc => 'Пройди 50 уровней ровно в пар.';

  @override
  String get badgeCleanClearTitle => 'Без отмен';

  @override
  String get badgeCleanClearDesc =>
      'Пройди уровень, ни разу не нажав «Отменить».';

  @override
  String get badgeSpeedyTitle => 'Шустрый';

  @override
  String get badgeSpeedyDesc => 'Пройди уровень быстрее чем за 30 секунд.';

  @override
  String get badgeLevels100Title => 'Сотня';

  @override
  String get badgeLevels100Desc => 'Пройди 100 уровней.';

  @override
  String get badgeStars300Title => 'Звездочёт';

  @override
  String get badgeStars300Desc => 'Собери 300 звёзд.';

  @override
  String get badgeWorldPerfectTitle => 'Безупречный мир';

  @override
  String get badgeWorldPerfectDesc =>
      'Получи три звезды на каждом уровне одного мира.';

  @override
  String get badgeStreak7Title => 'Неделя подряд';

  @override
  String get badgeStreak7Desc => 'Набери серию «Задачи дня» в 7 дней.';

  @override
  String get badgeStreak30Title => 'Месяц подряд';

  @override
  String get badgeStreak30Desc => 'Набери серию «Задачи дня» в 30 дней.';

  @override
  String get badgeChests5Title => 'Кладоискатель';

  @override
  String get badgeChests5Desc => 'Открой 5 звёздных сундуков.';

  @override
  String get badgeHard5Title => 'Крепкий орешек';

  @override
  String get badgeHard5Desc => 'Пройди 5 уровней с меткой СЛОЖНО.';

  @override
  String get badgeEventFullTitle => 'Вся неделя';

  @override
  String get badgeEventFullDesc => 'Пройди все семь полей события недели.';

  @override
  String get badgeZen25Title => 'Сад Zen';

  @override
  String get badgeZen25Desc => 'Пройди 25 полей в режиме Zen.';

  @override
  String get commonCancel => 'Отмена';

  @override
  String get commonClose => 'Закрыть';

  @override
  String get commonBack => 'Назад';

  @override
  String get commonOk => 'ОК';

  @override
  String get commonSave => 'Сохранить';

  @override
  String get commonRetry => 'Ещё раз';

  @override
  String get commonNotNow => 'Не сейчас';

  @override
  String commonLevelN(int level) {
    return 'Уровень $level';
  }

  @override
  String get hubAccountYours => 'Твой аккаунт';

  @override
  String get hubAccountSave => 'Сохрани прогресс';

  @override
  String get hubPlayerFallback => 'Игрок';

  @override
  String get hubSettings => 'Настройки';

  @override
  String get hubTagline => 'ЛЕЙ · СОРТИРУЙ · ДЫШИ';

  @override
  String hubStatChipSemantic(String value, String label) {
    return '$value $label. Статистика';
  }

  @override
  String get hubStatSolved => 'решено';

  @override
  String get hubStatStars => 'звёзд';

  @override
  String get hubStatStreak => 'серия';

  @override
  String hubStreakDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count дня',
      many: '$count дней',
      few: '$count дня',
      one: '$count день',
    );
    return '$_temp0';
  }

  @override
  String hubRankNumber(int rank) {
    return '#$rank';
  }

  @override
  String hubEventSemantic(int cleared, int total) {
    return 'Событие недели, $cleared из $total полей';
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
  String get hubZenSemantic => 'Режим Zen';

  @override
  String hubZenLockedSemantic(int level) {
    return 'Режим Zen откроется на уровне $level';
  }

  @override
  String get hubZenOpen => 'Без конца и без часов';

  @override
  String hubZenLocked(int level, int remaining) {
    return 'Уровень $level · осталось $remaining';
  }

  @override
  String get hubDockJourney => 'Путь';

  @override
  String get hubDockRankings => 'Рейтинг';

  @override
  String get hubDockStats => 'Статистика';

  @override
  String get hubTip =>
      'Отлично! В «Пути» собраны все уровни, а каждый день ждёт новая «Задача дня».';

  @override
  String hubHeroWorld(int world) {
    return 'Мир $world';
  }

  @override
  String hubHeroWorldBand(int world, String band) {
    return 'Мир $world · $band';
  }

  @override
  String hubHeroPar(int par) {
    return 'пар $par';
  }

  @override
  String get hubPlay => 'ИГРАТЬ';

  @override
  String hubPlaySemantic(int level) {
    return 'Играть уровень $level';
  }

  @override
  String get hubMoreUpdateTitle => 'Обнови игру ради новых уровней';

  @override
  String get hubMoreUpdateBody =>
      'Вышел новый мир, и ему нужна свежая версия Pourfect. Обнови игру, чтобы играть дальше.';

  @override
  String get hubMoreDownloadingTitle => 'Новые уровни уже в пути';

  @override
  String get hubMoreDownloadingBody =>
      'Следующий мир загружается. Это займёт всего минуту.';

  @override
  String get hubMoreAllDoneTitle => 'Ты прошёл всё!';

  @override
  String get hubMoreOfflineBody =>
      'Подключись к интернету, и новые уровни загрузятся в фоне. А пока тебя ждёт сегодняшняя «Задача дня».';

  @override
  String get hubMoreOnlineBody =>
      'Новые уровни загружаются в фоне, когда ты в сети. А пока тебя ждёт сегодняшняя «Задача дня».';

  @override
  String get hubMoreCheckAgain => 'Проверить снова';

  @override
  String hubAchievementOne(String title) {
    return 'Награда получена: $title';
  }

  @override
  String hubAchievementMany(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Получено $count награды!',
      many: 'Получено $count наград!',
      few: 'Получено $count награды!',
      one: 'Получена $count награда!',
    );
    return '$_temp0';
  }

  @override
  String get hubUpdateReady => 'Обновление готово к установке.';

  @override
  String get hubUpdateRestart => 'Перезапуск';

  @override
  String hubSpanSeconds(int seconds) {
    return '$seconds с';
  }

  @override
  String hubSpanMinutes(int minutes) {
    return '$minutes мин';
  }

  @override
  String hubSpanMinutesSeconds(int minutes, int seconds) {
    return '$minutes мин $seconds с';
  }

  @override
  String hubSpanHours(int hours) {
    return '$hours ч';
  }

  @override
  String hubSpanHoursMinutes(int hours, int minutes) {
    return '$hours ч $minutes мин';
  }

  @override
  String get hubParOn => 'ровно в пар';

  @override
  String hubParUnder(int percent) {
    return 'на $percent% быстрее пара';
  }

  @override
  String hubParOver(int percent) {
    return 'на $percent% дольше пара';
  }

  @override
  String get dailyTitle => 'Задача дня';

  @override
  String get dailyCardSemantic => 'Сегодняшняя задача';

  @override
  String get dailyCardUnavailable => 'задача дня недоступна';

  @override
  String get dailyCardSolved => 'решено';

  @override
  String dailyCardNextIn(String time) {
    return 'следующая через $time';
  }

  @override
  String dailyCardEndsIn(String time) {
    return 'осталось $time';
  }

  @override
  String dailyStreakDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Серия: $count дня',
      many: 'Серия: $count дней',
      few: 'Серия: $count дня',
      one: 'Серия: $count день',
    );
    return '$_temp0';
  }

  @override
  String dailyStreakMilestone(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count дня подряд!',
      many: '$count дней подряд!',
      few: '$count дня подряд!',
      one: '$count день подряд!',
    );
    return '$_temp0';
  }

  @override
  String get dailyRankSemantic => 'Рейтинг';

  @override
  String dailyRankSemanticRanked(int rank) {
    return 'Рейтинг, место $rank';
  }

  @override
  String get dailyRankSticker => 'МЕСТО';

  @override
  String get dailyLeaveLost =>
      'Ходы в сегодняшней «Задаче дня» не сохранятся. Начать заново можно в любой момент сегодня.';

  @override
  String get dailySubmitRefused => 'Сервер не принял этот результат.';

  @override
  String get dailySubmitFailed =>
      'Решено — но результат не удалось отправить. Попробуй позже.';

  @override
  String get dailyHudLabel => 'Задача';

  @override
  String get dailyHudValue => 'дня';

  @override
  String get dailyDeadEndRestart =>
      'Отсюда уже не решить. Начни заново и попробуй другой путь.';

  @override
  String dailyDeadEndUndo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Отсюда уже не решить. Отмени $count хода, чтобы вернуться на верный путь.',
      many:
          'Отсюда уже не решить. Отмени $count ходов, чтобы вернуться на верный путь.',
      few:
          'Отсюда уже не решить. Отмени $count хода, чтобы вернуться на верный путь.',
      one:
          'Отсюда уже не решить. Отмени $count ход, чтобы вернуться на верный путь.',
    );
    return '$_temp0';
  }

  @override
  String get dailyActionRestart => 'Заново';

  @override
  String dailyActionUndo(int count) {
    return 'Отменить $count';
  }

  @override
  String get dailyNoHint => 'Для этой позиции подсказки нет.';

  @override
  String get dailyLoadingTitle => 'Загружаем задачу дня';

  @override
  String get dailyOffTitle => 'В этой сборке задачи дня выключены';

  @override
  String get dailyOffDetail =>
      'На кампанию это не влияет — все уровни уже на устройстве.';

  @override
  String get dailyNoBoardTitle => 'Сегодня задачи нет';

  @override
  String get dailyNoBoardDetail =>
      'Задача дня приходит с сервера, а связаться с ним не удалось. Кампании он не нужен.';

  @override
  String get dailyLoaderCaption => 'Наливаем сегодняшнюю задачу…';

  @override
  String get dailyBackToLevels => 'К уровням';

  @override
  String dailyWeekSemantic(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count дня',
      many: '$count дней',
      few: '$count дня',
      one: '$count день',
    );
    return 'Твоя серия: $_temp0. Открыть';
  }

  @override
  String dailyDaySemantic(String weekday, String state) {
    return '$weekday, $state';
  }

  @override
  String get dailyDayFrozen => 'пропущен, спасён заморозкой';

  @override
  String get dailyDayPlayedToday => 'сыграно сегодня';

  @override
  String get dailyDayPlayed => 'сыграно';

  @override
  String get dailyDayToday => 'сегодня, ещё не сыграно';

  @override
  String get dailyDayMissed => 'не сыграно';

  @override
  String get dailyDayFuture => 'ещё впереди';

  @override
  String get dailyOutcomeBest => 'Новый рекорд';

  @override
  String get dailyOutcomeSolved => 'Решено';

  @override
  String get dailyFigureMoves => 'ходов';

  @override
  String get dailyFigureStreak => 'серия';

  @override
  String get dailyUnranked => 'без места';

  @override
  String dailyOfPlayers(int count) {
    return 'из $count';
  }

  @override
  String get dailyReminderOn => 'Завтра вечером придёт одно напоминание.';

  @override
  String get dailyRemindMe => 'Напомнить завтра';

  @override
  String get dailyDone => 'ГОТОВО';

  @override
  String get dailyFreezeVideoUnfinished =>
      'Без заморозки — видео не досмотрено.';

  @override
  String get dailyFreezeNoVideo => 'Сейчас нет доступных видео.';

  @override
  String get dailyFreezeError => 'Что-то пошло не так. Попробуй позже.';

  @override
  String get dailyFreezeAdded =>
      'Заморозка добавлена. Пропущенный день спасён.';

  @override
  String get dailyFreezeNoRoom => 'Сегодня больше заморозок не добавить.';

  @override
  String get dailyFreezeLoadingVideo => 'Загружаем видео…';

  @override
  String get dailyFreezeWatch => 'Заморозка за видео';

  @override
  String get dailyFreezesFull =>
      'Заморозок максимум. Каждая спасает один пропущенный день.';

  @override
  String get dailyFreezeTomorrow =>
      'Одна заморозка за видео в день. Возвращайся завтра.';

  @override
  String get dailyStreakTitle => 'Твоя серия';

  @override
  String get dailyStreakNone => 'Серии пока нет';

  @override
  String get dailyStreakStart =>
      'Реши сегодняшнюю «Задачу дня», чтобы её начать.';

  @override
  String dailyStreakBest(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Рекорд: $count дня',
      many: 'Рекорд: $count дней',
      few: 'Рекорд: $count дня',
      one: 'Рекорд: $count день',
    );
    return '$_temp0';
  }

  @override
  String dailyFreezesSemantic(int count, int max) {
    return 'Заморозки серии: $count из $max';
  }

  @override
  String get dailyFreezesTitle => 'Заморозки серии';

  @override
  String get dailyFreezesEach => 'Каждая спасает пропущенный день.';

  @override
  String dailyFreezeWeekly(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Бесплатная каждый понедельник, следующая через $days дня.',
      many: 'Бесплатная каждый понедельник, следующая через $days дней.',
      few: 'Бесплатная каждый понедельник, следующая через $days дня.',
      one: 'Бесплатная каждый понедельник, следующая через $days день.',
    );
    return '$_temp0';
  }

  @override
  String get dailyCalendarPrevious => 'Предыдущий месяц';

  @override
  String get dailyCalendarNext => 'Следующий месяц';

  @override
  String dailyCalendarCellSemantic(String date, String state) {
    return '$date, $state';
  }

  @override
  String get dailyCalendarPlayed => 'сыграно';

  @override
  String get dailyCalendarFrozen => 'заморожено';

  @override
  String get dailyCalendarFuture => 'впереди';

  @override
  String get dailyLegendPlayed => 'Сыграно';

  @override
  String get dailyLegendFrozen => 'Заморозка';

  @override
  String get dailyLegendToday => 'Сегодня';

  @override
  String get eventTitle => 'Событие недели';

  @override
  String get eventUnreachable => 'Событие этой недели сейчас недоступно.';

  @override
  String get eventEnded => 'завершено';

  @override
  String eventEndsIn(String timeLeft) {
    return 'осталось $timeLeft';
  }

  @override
  String eventTimeLeftDaysHours(int days, int hours) {
    return '$days д $hours ч';
  }

  @override
  String eventTimeLeftHours(int hours) {
    return '$hours ч';
  }

  @override
  String eventTimeLeftMinutes(int minutes) {
    return '$minutes мин';
  }

  @override
  String eventSummary(int cleared, int total, String endsIn) {
    return '$cleared из $total полей · $endsIn';
  }

  @override
  String get eventFigurePoints => 'очков';

  @override
  String eventRankOf(int count) {
    return 'из $count';
  }

  @override
  String get eventRankPlay => 'сыграй, чтобы попасть в рейтинг';

  @override
  String get eventRankSetName => 'укажи имя для рейтинга';

  @override
  String eventTileSemanticDone(int slot, int stars, int points) {
    String _temp0 = intl.Intl.pluralLogic(
      stars,
      locale: localeName,
      other: '$stars звезды',
      many: '$stars звёзд',
      few: '$stars звезды',
      one: '$stars звезда',
    );
    return 'Поле $slot, $_temp0, очков: $points';
  }

  @override
  String eventTileSemanticNew(int slot) {
    return 'Поле $slot, не сыграно';
  }

  @override
  String eventTilePoints(int points) {
    return '$points очк.';
  }

  @override
  String get eventStandingsTitle => 'Рейтинг недели';

  @override
  String get eventStandingsEmpty => 'В рейтинге пока никого. Будь первым.';

  @override
  String eventStandingsCleared(int cleared) {
    return ' · $cleared/7';
  }

  @override
  String get eventSubmitRefused =>
      'Сервер не принял результат — возможно, событие уже закончилось.';

  @override
  String get eventSubmitFailed =>
      'Решено — но результат не удалось отправить. Попробуй ещё раз.';

  @override
  String eventDeadEndUndo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Отсюда уже не решить. Отмени $count хода.',
      many: 'Отсюда уже не решить. Отмени $count ходов.',
      few: 'Отсюда уже не решить. Отмени $count хода.',
      one: 'Отсюда уже не решить. Отмени $count ход.',
    );
    return '$_temp0';
  }

  @override
  String get eventNoHint => 'Для этой позиции сейчас нет подсказки.';

  @override
  String get eventHudLabel => 'Поле';

  @override
  String eventHudBand(String event, String endsIn) {
    return '$event · $endsIn';
  }

  @override
  String get eventSending => 'Отправляем…';

  @override
  String eventResult(int points, int total) {
    return '$points очк. · $total за неделю';
  }

  @override
  String eventResultRanked(int points, int total, int rank) {
    return '$points очк. · $total за неделю · #$rank';
  }

  @override
  String get journeyTitle => 'Путь';

  @override
  String journeyStarsSemantic(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count звезды',
      many: '$count звёзд',
      few: '$count звезды',
      one: '$count звезда',
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
    return 'Мир $world из $worlds, $name, решено $solved из $total';
  }

  @override
  String journeyWorldOf(int world, int worlds) {
    return 'МИР $world ИЗ $worlds';
  }

  @override
  String journeyRibbonSemantic(int world, String name, int solved, int total) {
    return 'Мир $world, $name, решено $solved из $total. Перейти к нему';
  }

  @override
  String journeyRibbonLabel(int world, String name) {
    return 'МИР $world · $name';
  }

  @override
  String get journeyYouPin => 'ТЫ';

  @override
  String journeyBandCaps(int world, int count) {
    return 'МИР $world · $count';
  }

  @override
  String get journeyBandFirstPours => 'Первые шаги';

  @override
  String get journeyBandFindingRhythm => 'Поймать ритм';

  @override
  String get journeyBandDeepWater => 'Глубокие воды';

  @override
  String get journeyBandMastery => 'Мастерство';

  @override
  String get notifSoftAskTitle => 'Напоминать тебе?';

  @override
  String get notifSoftAskBody =>
      'Подскажем, когда выйдет новая «Задача дня» или тебя ждёт следующий уровень. Не больше двух в день, а выключить можно в любой момент в Настройках.';

  @override
  String get notifSoftAskBodyDenied =>
      'Уведомления для Pourfect выключены. Включи их в настройках телефона, чтобы узнавать о новой «Задаче дня» и новых мирах. Не больше двух в день.';

  @override
  String get notifSoftAskOpenSettings => 'Открыть настройки';

  @override
  String get notifSoftAskYes => 'Да, давай';

  @override
  String get notifChannelName => 'Напоминания';

  @override
  String get notifChannelDescription =>
      '«Задача дня», следующий уровень и новые миры. Не больше двух в день.';

  @override
  String get playHudLevel => 'Уровень';

  @override
  String playHudTitle(String label, String value) {
    return '$label $value';
  }

  @override
  String get playHudHard => 'СЛОЖНО ×1,5';

  @override
  String get playHudHardLabel => 'Сложный уровень, очки в полтора раза больше';

  @override
  String get playHudMoves => 'ХОДЫ';

  @override
  String playHudMovesLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count хода',
      many: '$count ходов',
      few: '$count хода',
      one: '$count ход',
    );
    return '$_temp0';
  }

  @override
  String playParLeftFor3Stars(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Ещё $count хода до 3 звёзд',
      many: 'Ещё $count ходов до 3 звёзд',
      few: 'Ещё $count хода до 3 звёзд',
      one: 'Ещё $count ход до 3 звёзд',
    );
    return '$_temp0';
  }

  @override
  String get playParSpent => 'Пар исчерпан · дальше 2 звезды';

  @override
  String playParLeftFor2Stars(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Ещё $count хода до 2 звёзд',
      many: 'Ещё $count ходов до 2 звёзд',
      few: 'Ещё $count хода до 2 звёзд',
      one: 'Ещё $count ход до 2 звёзд',
    );
    return '$_temp0';
  }

  @override
  String get playParOneStarFromHere => 'Дальше 1 звезда · за любое решение';

  @override
  String get playParAnyFinish => 'Любое решение даёт 1 звезду';

  @override
  String playParMeterLabel(int stars, int used, int par, String words) {
    return 'Темп на $stars зв., $used из $par ходов пара. $words';
  }

  @override
  String playHudBusyLabel(String label) {
    return '$label, в процессе. Нажми, чтобы отменить';
  }

  @override
  String get playHudUndo => 'Отменить';

  @override
  String get playHudHint => 'Подсказка';

  @override
  String get playHudRestart => 'Заново';

  @override
  String get playExtraTubeLabel => 'Посмотреть видео ради лишней колбы';

  @override
  String get playExtraTubeChip => '+ Колба';

  @override
  String playStarsOfTotal(int earned, int total) {
    return '$earned из $total звёзд';
  }

  @override
  String get playDismiss => 'Закрыть';

  @override
  String get playLeaveTitleSoSoon => 'Уже уходишь?';

  @override
  String get playLeaveTitleMissYou => 'Шарики будут скучать';

  @override
  String get playLeaveTitleAbandon => 'Бросить партию?';

  @override
  String get playLeaveTitleMidPour => 'Уходишь на полпути?';

  @override
  String get playLeaveBody => 'Ходы и время на этом поле не сохранятся.';

  @override
  String get playLeaveKeepPouring => 'Играть дальше';

  @override
  String get playLeaveConfirm => 'Выйти';

  @override
  String get playTutorialSkipLabel => 'Пропустить обучение';

  @override
  String get playTutorialSkip => 'Пропустить';

  @override
  String playTipBubbleLabel(String text) {
    return '$text. Закрыть';
  }

  @override
  String get playTipPar =>
      'Уложись в пар — получишь три звезды. Полоска показывает, сколько ходов ты потратил.';

  @override
  String get playTipTallTubes =>
      'Колбы выше! Теперь в каждую влезает пять шариков.';

  @override
  String get playTipHint => 'Застрял? Подсказка покажет хороший ход.';

  @override
  String get playTipUndo =>
      'Вышел за пар? Отмена бесплатна — возвращайся сколько хочешь.';

  @override
  String get playGuideSorted =>
      'Готово! Теперь сделай каждую колбу одного цвета.';

  @override
  String get playGuideDrop =>
      'Теперь нажми, куда их перелить: на тот же цвет или в пустую колбу.';

  @override
  String get playGuideWrongTube =>
      'Нажми на колбу, куда указывает рука, чтобы взять шарики оттуда.';

  @override
  String get playGuideFirstTap => 'Нажми на колбу, чтобы взять верхние шарики.';

  @override
  String get playGuideFirstPour => 'Вот и первый ход! Продолжай.';

  @override
  String get playGuideKeepGoing => 'Продолжай: один цвет в каждой колбе.';

  @override
  String playCoachHolding(int count) {
    return 'В руке: $count · перелей в прыгающую колбу';
  }

  @override
  String get playExtraTubeAdTitle => 'Посмотреть видео ради лишней колбы?';

  @override
  String get playExtraTubeAdBody =>
      'Ещё одна пустая колба на этот уровень. С лишней колбой уровень даёт не больше двух звёзд.';

  @override
  String get playExtraTubeNotFinished => 'Без колбы — видео не досмотрено.';

  @override
  String get playExtraTubeSaved => 'Сохранено — следующая колба бесплатно.';

  @override
  String get playNoVideo => 'Сейчас нет доступных видео.';

  @override
  String get playRewardFailed => 'Что-то пошло не так. Ничего не потрачено.';

  @override
  String get playHintShowing =>
      'Подсказка уже на поле: перелей в светящуюся колбу.';

  @override
  String get playHintNoneNothingUsed =>
      'Для этой позиции подсказки нет. Ничего не потрачено.';

  @override
  String get playHintNotFinished => 'Без подсказки — видео не досмотрено.';

  @override
  String get playHintVideoSaved => 'Видео засчитано для следующей подсказки.';

  @override
  String get playHintNoneVideoSaved =>
      'Для этой позиции подсказки нет — видео засчитано для следующей.';

  @override
  String get playHintNone => 'Для этой позиции подсказки нет.';

  @override
  String get playHintHere => 'Вот подсказка — перелей в светящуюся колбу.';

  @override
  String get playDeadEndRestart =>
      'Отсюда уже не решить. Начни заново и попробуй другой путь.';

  @override
  String get playDeadEndRestartTube =>
      'Отсюда уже не решить. Начни заново и попробуй другой путь. Или нажми «+ Колба», чтобы взять запасную.';

  @override
  String playDeadEndUndo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Отсюда уже не решить. Отмени $count хода, чтобы вернуться на верный путь.',
      many:
          'Отсюда уже не решить. Отмени $count ходов, чтобы вернуться на верный путь.',
      few:
          'Отсюда уже не решить. Отмени $count хода, чтобы вернуться на верный путь.',
      one:
          'Отсюда уже не решить. Отмени $count ход, чтобы вернуться на верный путь.',
    );
    return '$_temp0';
  }

  @override
  String playDeadEndUndoTube(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Отсюда уже не решить. Отмени $count хода, чтобы вернуться на верный путь. Или нажми «+ Колба», чтобы взять запасную.',
      many:
          'Отсюда уже не решить. Отмени $count ходов, чтобы вернуться на верный путь. Или нажми «+ Колба», чтобы взять запасную.',
      few:
          'Отсюда уже не решить. Отмени $count хода, чтобы вернуться на верный путь. Или нажми «+ Колба», чтобы взять запасную.',
      one:
          'Отсюда уже не решить. Отмени $count ход, чтобы вернуться на верный путь. Или нажми «+ Колба», чтобы взять запасную.',
    );
    return '$_temp0';
  }

  @override
  String playDeadEndUndoAction(int count) {
    return 'Отменить $count';
  }

  @override
  String get playHintAdTitle => 'Посмотреть видео ради подсказки?';

  @override
  String playHintAdFreeLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Осталось $count бесплатной подсказки.',
      many: 'Осталось $count бесплатных подсказок.',
      few: 'Осталось $count бесплатные подсказки.',
      one: 'Осталась $count бесплатная подсказка.',
    );
    return '$_temp0';
  }

  @override
  String get playHintAdNoneLeft =>
      'Бесплатные подсказки закончились. Короткое видео даст ещё одну.';

  @override
  String get playWatch => 'Смотреть';

  @override
  String get playLoadFailed => 'Не удалось загрузить уровни';

  @override
  String get playTubeSorted => 'ГОТОВО!';

  @override
  String get playWinTitlePerfect => 'Просто\nидеально!';

  @override
  String get playWinTitleNice => 'Хорошо\nвышло!';

  @override
  String get playWinTitlePoured => 'Готово!';

  @override
  String get playWinLastPour => 'Последний ход…';

  @override
  String playWinMovesPar(int count, int par) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ХОДА · ПАР $par',
      many: '$count ХОДОВ · ПАР $par',
      few: '$count ХОДА · ПАР $par',
      one: '$count ХОД · ПАР $par',
    );
    return '$_temp0';
  }

  @override
  String playWinLevelBand(int level, String band) {
    return 'Уровень $level · $band';
  }

  @override
  String get playWinNewBest => 'РЕКОРД!';

  @override
  String playWinMovesChip(int par) {
    return 'ходов · пар $par';
  }

  @override
  String get playWinUntimed => 'без времени';

  @override
  String get playWinFastest => 'лучшее время!';

  @override
  String get playWinTime => 'время';

  @override
  String get playWinUnderPar => 'БЫСТРЕЕ ПАРА!';

  @override
  String get playWinPoints => 'очков';

  @override
  String playWinWorldBand(int world, String band) {
    return 'МИР $world · $band';
  }

  @override
  String get playWinTryAssisted => 'Три звезды — только без лишней колбы.';

  @override
  String playWinTryShort(int par, int took, int short) {
    String _temp0 = intl.Intl.pluralLogic(
      short,
      locale: localeName,
      other: 'Пар $par, у тебя $took. $short хода до 3★.',
      many: 'Пар $par, у тебя $took. $short ходов до 3★.',
      few: 'Пар $par, у тебя $took. $short хода до 3★.',
      one: 'Пар $par, у тебя $took. $short ход до 3★.',
    );
    return '$_temp0';
  }

  @override
  String playWinTryInReach(int par) {
    return 'Пар $par. Три звезды совсем рядом.';
  }

  @override
  String get playWinTryButton => 'НА 3★';

  @override
  String get playWinTryButtonLabel => 'Перепройти уровень на три звезды';

  @override
  String get playWinReplayLabel => 'Перепройти уровень';

  @override
  String get playWinHomeLabel => 'На главный экран';

  @override
  String get playWinNextLevel => 'ДАЛЬШЕ';

  @override
  String get playWinBackToLevels => 'К УРОВНЯМ';

  @override
  String playChestNextAtLabel(int stars) {
    return 'Следующий звёздный сундук на $stars звёздах';
  }

  @override
  String get playChestOpenLabel => 'Открыть звёздный сундук';

  @override
  String get playChestReady => 'Звёздный сундук готов!';

  @override
  String playChestNextAt(int stars) {
    return 'Следующий сундук: $stars ★';
  }

  @override
  String get playChestOpen => 'ОТКРЫТЬ';

  @override
  String get playChestDoubleFailed => 'В этот раз удвоить не вышло.';

  @override
  String get playChestDoubleNotFinished =>
      'Без удвоения — видео не досмотрено.';

  @override
  String get playChestOpening => 'Открываем…';

  @override
  String playChestTitle(int index) {
    return 'Звёздный сундук $index';
  }

  @override
  String get playChestNotYetTitle => 'Почти готово';

  @override
  String get playChestAlreadyOpenTitle => 'Уже открыт';

  @override
  String get playChestFailedTitle => 'Не удалось открыть';

  @override
  String get playChestNotYetNote =>
      'Новые звёзды ещё в пути на сервер. Попробуй чуть позже.';

  @override
  String get playChestAlreadyOpenNote =>
      'Этот сундук открыли на другом устройстве.';

  @override
  String get playChestFailedNote => 'Проверь подключение и попробуй снова.';

  @override
  String playChestRewardCount(int count) {
    return '+$count';
  }

  @override
  String playChestHintsCaption(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'подсказки',
      many: 'подсказок',
      few: 'подсказки',
      one: 'подсказка',
    );
    return '$_temp0';
  }

  @override
  String playChestTubesCaption(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'лишней колбы',
      many: 'лишних колб',
      few: 'лишние колбы',
      one: 'лишняя колба',
    );
    return '$_temp0';
  }

  @override
  String playChestUnlocked(String name) {
    return 'Открыто: $name';
  }

  @override
  String playChestBallSkinName(String skin) {
    return 'скин шариков «$skin»';
  }

  @override
  String playChestTubeThemeName(String theme) {
    return 'колбы «$theme»';
  }

  @override
  String get playChestNewLook => 'новый облик';

  @override
  String get playChestSavedNote =>
      'Отложено на потом. «Подсказка» и «+ Колба» тратят их в первую очередь.';

  @override
  String get playChestLoadingVideo => 'Загружаем видео…';

  @override
  String get playChestDouble => 'Удвоить за видео';

  @override
  String get playChestCollect => 'Забрать';

  @override
  String playClockLabel(String time) {
    return 'Время $time';
  }

  @override
  String playClockDetailLabel(
    String time,
    String par,
    String sign,
    int percent,
  ) {
    String _temp0 = intl.Intl.selectLogic(sign, {
      'plus': 'плюс',
      'other': 'минус',
    });
    return 'Время $time при паре $par, $_temp0 $percent процентов очков';
  }

  @override
  String playClockBonusChip(String sign, int percent) {
    return '$sign$percent% очк.';
  }

  @override
  String get playLoading => 'Загрузка';

  @override
  String get playWorking => 'Работаем';

  @override
  String get playZenTitle => 'Zen';

  @override
  String get playZenIntro =>
      'Бесконечные поля. Без часов, звёзд и рейтинга — просто переливай.';

  @override
  String get playZenPaceCalm => 'Спокойный';

  @override
  String get playZenPaceSteady => 'Размеренный';

  @override
  String get playZenPaceDeep => 'Глубокий';

  @override
  String playZenPaceColors(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count цвета',
      many: '$count цветов',
      few: '$count цвета',
      one: '$count цвет',
    );
    return '$_temp0';
  }

  @override
  String playZenPaceLabel(String pace, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$pace, $count цвета',
      many: '$pace, $count цветов',
      few: '$pace, $count цвета',
      one: '$pace, $count цвет',
    );
    return '$_temp0';
  }

  @override
  String playZenBandPoured(String pace, int count) {
    return '$pace · решено $count';
  }

  @override
  String playZenPoured(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Готово! Уже $count поля.',
      many: 'Готово! Уже $count полей.',
      few: 'Готово! Уже $count поля.',
      one: 'Готово! Уже $count поле.',
    );
    return '$_temp0';
  }

  @override
  String get playZenNext => 'ДАЛЬШЕ';

  @override
  String get playZenLeaveBody =>
      'Ходы на этом поле не сохранятся. Счёт решённых полей останется.';

  @override
  String get playZenDeadEnd =>
      'Отсюда уже не решить. Отмени ход или начни заново.';

  @override
  String get playZenNoHint => 'Для этой позиции сейчас нет подсказки.';

  @override
  String get settingsTitle => 'Настройки';

  @override
  String get settingsSectionFeel => 'Ощущения';

  @override
  String get settingsSectionVisibility => 'Видимость';

  @override
  String get settingsSectionLeaderboard => 'Рейтинг';

  @override
  String get settingsSectionNotifications => 'Уведомления';

  @override
  String get settingsSectionSupport => 'Поддержка';

  @override
  String get settingsSectionAccount => 'Аккаунт и об игре';

  @override
  String get settingsSectionDanger => 'Опасная зона';

  @override
  String get settingsSoundTitle => 'Звуковые эффекты';

  @override
  String get settingsSoundDetail => 'Переливания, кнопки и награды';

  @override
  String get settingsSoundVolume => 'Громкость эффектов';

  @override
  String get settingsMusicTitle => 'Музыка';

  @override
  String get settingsMusicDetail => 'Не играет поверх твоей музыки';

  @override
  String get settingsMusicVolume => 'Громкость музыки';

  @override
  String get settingsHapticsTitle => 'Вибрация';

  @override
  String get settingsHapticsDetail => 'Лёгкий отклик, когда шарик падает';

  @override
  String get settingsSmoothMotionTitle => 'Плавность';

  @override
  String get settingsSmoothMotionAuto => 'Авто';

  @override
  String get settingsSmoothMotion60 => '60 Гц';

  @override
  String get settingsSmoothMotionMax => 'Макс';

  @override
  String get settingsMotionUnknown =>
      '«Авто» включит самую высокую частоту экрана, если телефон справится';

  @override
  String settingsMotionFixed(String max) {
    return 'Этот экран работает только на $max Гц';
  }

  @override
  String settingsMotionBatterySaver(String current) {
    return 'Энергосбережение держит частоту на $current Гц';
  }

  @override
  String settingsMotionAutoStuttered(String current, String max) {
    return 'Сейчас $current Гц · на $max Гц телефон подтормаживал';
  }

  @override
  String settingsMotionAuto(String current) {
    return 'Сейчас $current Гц · при рывках снизится до 60 Гц';
  }

  @override
  String settingsMotionPinnedByPhone(String current) {
    return 'Настройки экрана телефона держат $current Гц';
  }

  @override
  String settingsMotionStandard(String current, String max) {
    return 'Сейчас $current Гц · экран умеет $max Гц';
  }

  @override
  String settingsMotionMax(String current) {
    return 'Сейчас $current Гц — максимум для этого экрана';
  }

  @override
  String get settingsBoldSymbolsTitle => 'Чёткие символы';

  @override
  String get settingsBoldSymbolsDetail =>
      'Более заметные фигуры при дальтонизме';

  @override
  String get settingsRenameTitle => 'Сменить имя';

  @override
  String get settingsRenameDetail => 'Как тебя видят в рейтингах';

  @override
  String get settingsShowOnBoardsTitle => 'Показывать меня в рейтингах';

  @override
  String get settingsShowOnBoardsDetail =>
      'Скрывает имя и место. Звёзды всё равно идут в зачёт.';

  @override
  String get settingsHowToPlayTitle => 'Как играть';

  @override
  String get settingsHowToPlayDetail =>
      'Снова пройти первый уровень с подсказками';

  @override
  String get settingsQuestionsTitle => 'Вопросы';

  @override
  String get settingsQuestionsDetail => 'Звёзды, подсказки, часы и другое';

  @override
  String get settingsRateTitle => 'Оценить Pourfect';

  @override
  String get settingsRateDetail => 'Расскажи другим игрокам, что думаешь';

  @override
  String get settingsCollectionTitle => 'Коллекция';

  @override
  String get settingsCollectionDetail => 'Скины шариков и темы колб';

  @override
  String get settingsRestoreTitle => 'Восстановить покупки';

  @override
  String get settingsRestoreDetail => '«Без рекламы» или набор скинов';

  @override
  String get settingsRestoreDone => 'Покупки восстановлены, если они были.';

  @override
  String get settingsRemoveAdsTitle => 'Без рекламы';

  @override
  String get settingsRemoveAdsDetail =>
      'Нет рекламы между уровнями. Видео за подсказки остаются.';

  @override
  String get settingsAdsRemoved => 'Реклама отключена — спасибо';

  @override
  String get settingsPurchaseThanks =>
      'Спасибо! Реклама между уровнями отключена.';

  @override
  String get settingsPurchaseAlreadyOwned => 'Уже куплено — реклама отключена.';

  @override
  String get settingsPurchasePending =>
      'Платёж обрабатывается. Реклама отключится, когда он пройдёт.';

  @override
  String get settingsStoreUnavailable =>
      'Магазин сейчас недоступен на этом устройстве.';

  @override
  String get settingsPurchaseFailed => 'Покупка не прошла. Деньги не списаны.';

  @override
  String get settingsStoreOpenFailed => 'Не удалось открыть магазин.';

  @override
  String get settingsBrowserOpenFailed => 'Не удалось открыть браузер.';

  @override
  String get settingsSignedIn => 'Вход выполнен';

  @override
  String get settingsSignedInDetail => 'Прогресс всегда с тобой';

  @override
  String get settingsSaveProgressTitle => 'Сохрани прогресс';

  @override
  String get settingsSaveProgressDetail =>
      'Звёзды останутся при смене телефона';

  @override
  String get settingsPrivacyPolicy => 'Политика конфиденциальности';

  @override
  String get settingsTermsAndLicenses => 'Условия и лицензии';

  @override
  String get settingsTermsOfUse => 'Условия использования';

  @override
  String get settingsRefundPolicy => 'Политика возврата';

  @override
  String get settingsOpenSourceLicenses => 'Лицензии open source';

  @override
  String get settingsAdPrivacyTitle => 'Настройки рекламы';

  @override
  String get settingsAdPrivacyDetail => 'Изменить согласие на рекламу';

  @override
  String get settingsResetRowTitle => 'Сбросить прогресс';

  @override
  String get settingsResetRowDetail => 'Стереть все звёзды и начать с 1 уровня';

  @override
  String get settingsResetTitle => 'Сбросить прогресс?';

  @override
  String get settingsResetNothing => 'Пока нечего сбрасывать.';

  @override
  String settingsResetBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Все звёзды и рекорды на $count решённых уровнях будут стёрты, а всё после 1 уровня снова закроется. Это нельзя отменить.',
      many:
          'Все звёзды и рекорды на $count решённых уровнях будут стёрты, а всё после 1 уровня снова закроется. Это нельзя отменить.',
      few:
          'Все звёзды и рекорды на $count решённых уровнях будут стёрты, а всё после 1 уровня снова закроется. Это нельзя отменить.',
      one:
          'Все звёзды и рекорды на $count решённом уровне будут стёрты, а всё после 1 уровня снова закроется. Это нельзя отменить.',
    );
    return '$_temp0';
  }

  @override
  String get settingsKeepIt => 'Оставить';

  @override
  String get settingsResetConfirm => 'Стереть всё';

  @override
  String get settingsResetDone => 'Прогресс сброшен.';

  @override
  String get settingsSignOutTitle => 'Выйти?';

  @override
  String get settingsSignOutBody =>
      'Прогресс останется на этом телефоне. Войди снова в любой момент, чтобы продолжить на другом устройстве.';

  @override
  String get settingsSignOutStay => 'Остаться';

  @override
  String get settingsSignOutConfirm => 'Выйти';

  @override
  String get settingsServerUnreachable =>
      'Не удалось связаться с сервером, ничего не изменилось.';

  @override
  String get settingsDeleteRowTitle => 'Удалить аккаунт';

  @override
  String get settingsDeleteRowDetail =>
      'Удалить аккаунт и всё, что с ним связано';

  @override
  String get settingsDeleteTitle => 'Удалить аккаунт?';

  @override
  String get settingsDeleteBody =>
      'Аккаунт, звёзды, серия и запись в рейтинге будут удалены — и на этом телефоне, и на нашем сервере. Это нельзя отменить.\n\nПокупку «Без рекламы» это не затронет — она привязана к аккаунту магазина, с которого ты её купил, и восстановится, если ты снова начнёшь играть.';

  @override
  String get settingsDeleteConfirm => 'Удалить всё';

  @override
  String get settingsDeleteServerRefused =>
      'Не удалось связаться с сервером. Ничего не удалено — попробуй снова, когда появится сеть.';

  @override
  String get settingsDeleteNotAuthenticated =>
      'Не удалось подтвердить, что это ты. Войди снова, затем удали аккаунт — пока ничего не удалено.';

  @override
  String settingsFooterVersion(String version) {
    return 'Pourfect $version';
  }

  @override
  String settingsFooterVersionBoards(int count, String version) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Pourfect $version · $count поля с доказанным решением',
      many: 'Pourfect $version · $count полей с доказанным решением',
      few: 'Pourfect $version · $count поля с доказанным решением',
      one: 'Pourfect $version · $count поле с доказанным решением',
    );
    return '$_temp0';
  }

  @override
  String get settingsNamingYou => 'Придумываем имя…';

  @override
  String get settingsYourName => 'Твоё имя';

  @override
  String get settingsGuest => 'Игра в гостевом режиме';

  @override
  String get settingsStatSolved => 'РЕШЕНО';

  @override
  String get settingsStatStars => 'ЗВЁЗДЫ';

  @override
  String get settingsNotifyTurnOnTitle => 'Включить уведомления';

  @override
  String get settingsNotifyDeniedDetail =>
      'Выключены в настройках телефона. Нажми, чтобы открыть.';

  @override
  String get settingsNotifyNotYetDetail =>
      'Pourfect пока не может присылать уведомления';

  @override
  String get settingsRemindersTitle => 'Напоминания о задаче дня';

  @override
  String get settingsRemindersDetail =>
      'Утром и вечером, не больше двух в день';

  @override
  String get settingsNewsTitle => 'Новости игры';

  @override
  String get settingsNewsDetail => 'Новые миры и анонсы';

  @override
  String settingsToggleOn(String title) {
    return '$title, вкл.';
  }

  @override
  String settingsToggleOff(String title) {
    return '$title, выкл.';
  }

  @override
  String get settingsFaqSectionPlaying => 'Игра';

  @override
  String get settingsFaqSectionStuck => 'Застрял?';

  @override
  String get settingsFaqSectionProgress => 'Твой прогресс';

  @override
  String get settingsFaqSectionAds => 'Реклама и звук';

  @override
  String get settingsFaqHowToPlayQ => 'Как играть?';

  @override
  String get settingsFaqHowToPlayA =>
      'Нажми на колбу, чтобы взять верхние шарики, затем на другую колбу, чтобы перелить их туда. Шарики ложатся только на тот же цвет или в пустую колбу. Собери в каждой колбе один цвет — и уровень пройден. Настройки → Как играть снова запустит первый уровень с подсказками.';

  @override
  String get settingsFaqStarsQ => 'Что значат звёзды?';

  @override
  String get settingsFaqStarsA =>
      'Звёзды считают только ходы. Уложись в пар или меньше — три звезды, не больше чем в полтора пара — две, а любое решение даёт одну. Пар — наименьшее число ходов, за которое можно решить уровень.';

  @override
  String get settingsFaqClockQ => 'Часы отнимают звёзды?';

  @override
  String get settingsFaqClockA =>
      'Никогда. Время влияет только на очки. Обгони пар по времени и получи бонус или играй сколько хочешь — все звёзды останутся.';

  @override
  String get settingsFaqSolvableQ => 'Каждый уровень можно решить?';

  @override
  String get settingsFaqSolvableA =>
      'Да. Каждое поле было решено до выхода, и пар взят из этого решения, так что он всегда достижим.';

  @override
  String get settingsFaqDailyQ => 'Что такое «Задача дня»?';

  @override
  String get settingsFaqDailyA =>
      'Новое поле каждый день, со своим рейтингом. Для неё нужен интернет. Уровням кампании — нет.';

  @override
  String get settingsFaqUndoQ => 'Отмена ограничена?';

  @override
  String get settingsFaqUndoA =>
      'Нет. Отмена бесплатна и не ограничена на любом уровне.';

  @override
  String get settingsFaqHintsQ => 'Как работают подсказки?';

  @override
  String settingsFaqHintsA(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Первые $count подсказки бесплатны. Дальше короткое видео даёт ещё одну. Если подсказку найти не удалось, видео засчитается для следующей.',
      many:
          'Первые $count подсказок бесплатны. Дальше короткое видео даёт ещё одну. Если подсказку найти не удалось, видео засчитается для следующей.',
      few:
          'Первые $count подсказки бесплатны. Дальше короткое видео даёт ещё одну. Если подсказку найти не удалось, видео засчитается для следующей.',
      one:
          'Первая $count подсказка бесплатна. Дальше короткое видео даёт ещё одну. Если подсказку найти не удалось, видео засчитается для следующей.',
    );
    return '$_temp0';
  }

  @override
  String get settingsFaqTubeQ => 'Что за кнопка «+ Колба»?';

  @override
  String get settingsFaqTubeA =>
      'Когда ходы достигают пара или подсказка показывает, что решения нет, можно посмотреть видео и получить лишнюю пустую колбу — до двух за попытку. Отмена её не заберёт. С лишней колбой уровень даёт не больше двух звёзд.';

  @override
  String get settingsFaqHardQ => 'Что за уровни СЛОЖНО?';

  @override
  String get settingsFaqHardA =>
      'Самый трудный уровень в каждом десятке носит красную метку СЛОЖНО. Он играется как обычный, но приносит в полтора раза больше очков.';

  @override
  String get settingsFaqChestsQ => 'Что такое звёздные сундуки?';

  @override
  String get settingsFaqChestsA =>
      'Каждые 30 звёзд открывают сундук на твоём Пути: две подсказки и лишняя колба, отложенные на потом. Каждый третий сундук ещё и открывает скин шариков.';

  @override
  String get settingsFaqFreezeQ => 'Что такое заморозка серии?';

  @override
  String get settingsFaqFreezeA =>
      'Пропустил день «Задачи дня» — заморозка его покроет, и серия не прервётся. Одна бесплатная каждый понедельник, ещё одну можно получить за видео раз в день, а хранить можно две.';

  @override
  String get settingsFaqAccountQ => 'Нужен ли аккаунт?';

  @override
  String get settingsFaqAccountA =>
      'Нет. Ты играешь как гость, и прогресс хранится на этом телефоне. Если войти, звёзды сохранятся при переходе на новый телефон.';

  @override
  String get settingsFaqOfflineQ => 'Можно играть без интернета?';

  @override
  String get settingsFaqOfflineA =>
      'Да, всю кампанию. «Задаче дня» и рейтингам нужна сеть, а прогресс синхронизируется, когда ты снова онлайн.';

  @override
  String get settingsFaqNameQ => 'Как сменить имя в рейтинге?';

  @override
  String get settingsFaqNameA =>
      'Настройки → Сменить имя. Там же можно скрыть себя из рейтингов — звёзды всё равно идут в зачёт.';

  @override
  String get settingsFaqRemoveAdsQ => 'Что даёт «Без рекламы»?';

  @override
  String get settingsFaqRemoveAdsA =>
      'Отключает рекламу между уровнями. Видео за подсказки и колбы остаются, ведь ты видишь их, только когда сам попросишь.';

  @override
  String get settingsFaqReinstallQ =>
      'Я переустановил игру. Куда пропало «Без рекламы»?';

  @override
  String get settingsFaqReinstallA =>
      'Покупка привязана к аккаунту магазина, с которого ты её сделал, и обычно возвращается сама. Если нет — нажми Настройки → Восстановить покупки.';

  @override
  String get settingsFaqMusicQ => 'Игра остановит мою музыку?';

  @override
  String get settingsFaqMusicA =>
      'Нет. Pourfect играет звуки поверх твоей музыки или подкаста. Звук и вибрацию можно выключить в Настройках.';

  @override
  String get settingsLegalTitle => 'Перед игрой';

  @override
  String get settingsLegalIntro =>
      'Pourfect бесплатна, работает без интернета и не требует аккаунта. Сначала прочитай и прими эти документы.';

  @override
  String settingsLegalAcceptTerms(String document) {
    return 'Я принимаю $document';
  }

  @override
  String settingsLegalReadPrivacy(String document) {
    return 'Я прочитал(а): $document';
  }

  @override
  String settingsLegalAlsoCovers(String document, String version) {
    return 'Согласие также распространяется на документ «$document» (версия $version).';
  }

  @override
  String get settingsLegalPrivacyPolicy => 'Политика конфиденциальности';

  @override
  String get settingsLegalTermsOfService => 'Условия использования';

  @override
  String get settingsLegalRefundPolicy => 'Политика возврата';

  @override
  String settingsLegalReadDocument(String document) {
    return 'Прочитать: $document';
  }

  @override
  String get settingsLegalAccept => 'ПОЕХАЛИ!';

  @override
  String get settingsLegalReadAgain =>
      'Прочитать их снова можно в любой момент в Настройках.';

  @override
  String get settingsLegalLoadFailed =>
      'Не удалось загрузить документ на этом устройстве.\n\nПрочитать его можно на legal.pranta.dev до того, как принять.';

  @override
  String get settingsUpdateTitle => 'Новая версия Pourfect готова';

  @override
  String get settingsUpdateBody =>
      'Google Play скачает её и снова откроет игру, когда всё будет готово. Твои звёзды в безопасности.';

  @override
  String get settingsUpdateMandatoryTitle => 'Пора обновиться';

  @override
  String get settingsUpdateMandatoryBody =>
      'Эта версия Pourfect больше не поддерживается. Google Play скачает обновление и снова откроет игру. Твои звёзды в безопасности.';

  @override
  String get settingsUpdateNow => 'Обновить';

  @override
  String get settingsRenameHello => 'ПРИВЕТ';

  @override
  String get settingsRenameMyNameIs => 'МЕНЯ ЗОВУТ';

  @override
  String get settingsRenameHint => 'Другие игроки увидят это в рейтингах';

  @override
  String get settingsRenameSave => 'СОХРАНИТЬ';

  @override
  String settingsCollectionUnlockWith(String how) {
    return 'Как открыть: $how.';
  }

  @override
  String get settingsCollectionChangeFailed =>
      'Сейчас не получилось сменить. Попробуй позже.';

  @override
  String get settingsPackThanks => 'Спасибо! Набор откроется через мгновение.';

  @override
  String get settingsPackAlreadyOwned => 'Уже твоё. Восстанавливаем.';

  @override
  String get settingsPackPending =>
      'Платёж обрабатывается. Набор откроется, когда он пройдёт.';

  @override
  String get settingsCollectionOffline =>
      'Подключись к интернету, чтобы увидеть коллекцию.';

  @override
  String get settingsCollectionBallSkins => 'Скины шариков';

  @override
  String get settingsCollectionTubeThemes => 'Темы колб';

  @override
  String settingsCollectionPreview(String skin, String theme) {
    return 'Шарики «$skin» · колбы «$theme»';
  }

  @override
  String settingsCollectionItemWorn(String name) {
    return '$name, надето';
  }

  @override
  String settingsCollectionItemTapToWear(String name) {
    return '$name, нажми, чтобы надеть';
  }

  @override
  String settingsCollectionItemLocked(String name, String how) {
    return '$name, закрыто: $how';
  }

  @override
  String get settingsCollectionWearing => 'Надето';

  @override
  String get settingsCollectionTapToWear => 'Надеть';

  @override
  String settingsUnlockChest(int number) {
    return 'Звёздный сундук $number';
  }

  @override
  String settingsUnlockStreak(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Серия $days дня',
      many: 'Серия $days дней',
      few: 'Серия $days дня',
      one: 'Серия $days день',
    );
    return '$_temp0';
  }

  @override
  String get settingsUnlockFree => 'Бесплатно';

  @override
  String get settingsSkinPack => 'Набор скинов';

  @override
  String get settingsSkinPackDetail =>
      'Шарики «Мрамор», «Жемчуг» и «Клетка», колбы «Дерево» и «Сирень».';

  @override
  String get settingsOwned => 'КУПЛЕНО';

  @override
  String get settingsSoon => 'Скоро';

  @override
  String get settingsSkinClassic => 'Классика';

  @override
  String get settingsSkinGlossy => 'Глянец';

  @override
  String get settingsSkinStriped => 'Леденец';

  @override
  String get settingsSkinGlow => 'Сияние';

  @override
  String get settingsSkinSpeckled => 'Посыпка';

  @override
  String get settingsSkinMarble => 'Мрамор';

  @override
  String get settingsSkinPearl => 'Жемчуг';

  @override
  String get settingsSkinChecker => 'Клетка';

  @override
  String get settingsTubeToy => 'Игрушка';

  @override
  String get settingsTubeFrost => 'Иней';

  @override
  String get settingsTubeWood => 'Дерево';

  @override
  String get settingsTubeLilac => 'Сирень';
}

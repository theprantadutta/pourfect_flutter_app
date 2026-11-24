// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get accountGoogleFailed =>
      '이 휴대폰에서 Google 로그인이 되지 않았어요. 다시 시도하거나 아래에서 이메일을 사용해 주세요.';

  @override
  String get accountAppleFailed =>
      '이 휴대폰에서 Apple 로그인이 되지 않았어요. 설정에서 Apple 계정에 로그인되어 있는지 확인하거나 아래에서 이메일을 사용해 주세요.';

  @override
  String get accountExistsNoLocal =>
      '이 이메일로 만든 계정이 이미 있어요. 그 계정으로 로그인하면 저장된 별을 이 휴대폰으로 불러와요.';

  @override
  String accountExistsWithLocal(int solved) {
    String _temp0 = intl.Intl.pluralLogic(
      solved,
      locale: localeName,
      other:
          '이 이메일로 만든 계정이 이미 있어요. 이 휴대폰에는 그 계정에 없는 클리어한 레벨이 $solved개 있는데, 둘은 합칠 수 없어요. 로그인하면 그 계정에 저장된 기록으로 바뀌어요.',
    );
    return '$_temp0';
  }

  @override
  String get accountEmailInUse => '이 이메일로 만든 계정이 이미 있어요. 로그인해 보세요.';

  @override
  String get accountEmailMalformed => '올바른 이메일 주소가 아닌 것 같아요.';

  @override
  String get accountPasswordWeak => '비밀번호가 너무 쉬워요. 더 길게 만들어 보세요.';

  @override
  String get accountWrongPassword => '이메일과 비밀번호가 일치하지 않아요.';

  @override
  String get accountTooManyAttempts => '시도 횟수가 너무 많아요. 몇 분 뒤에 다시 시도해 주세요.';

  @override
  String get accountNeedsRecentLogin => '먼저 다시 로그인해 주세요.';

  @override
  String get accountMethodNotEnabled =>
      '지금은 이메일 로그인을 사용할 수 없어요. Google로 계속하기를 이용해 보세요.';

  @override
  String get accountSessionUnavailable =>
      '로그인했지만 진행 상황이 아직 서버에 저장되지 않았어요. 연결이 돌아오면 동기화돼요.';

  @override
  String get accountUnavailable => '서버에 연결할 수 없어요. 진행 상황은 이 기기에 안전하게 남아 있어요.';

  @override
  String get accountUseThatAccount => '그 계정 사용';

  @override
  String get accountExistingTitle => '이미 계정이 있어요';

  @override
  String get accountExistingBodyEmpty => '그 계정에 저장된 별을 이 휴대폰으로 불러와요.';

  @override
  String accountExistingBodyLocal(int cleared) {
    String _temp0 = intl.Intl.pluralLogic(
      cleared,
      locale: localeName,
      other:
          '이 휴대폰에는 그 계정에 없는 클리어한 레벨이 $cleared개 있어요. 둘은 합칠 수 없어서, 그 계정에 이미 저장된 기록으로 바뀌어요.',
    );
    return '$_temp0';
  }

  @override
  String get accountSignIn => '로그인';

  @override
  String get accountSignInCancelled => '로그인을 취소했어요. 바뀐 건 없어요.';

  @override
  String get accountSignedInToast => '로그인했어요. 이제 새 휴대폰에서도 별이 함께해요.';

  @override
  String get accountResetNeedsEmail => '먼저 이메일을 입력한 뒤 비밀번호를 잊으셨나요?를 눌러 주세요.';

  @override
  String get accountResetSent => '이 이메일로 된 계정이 있다면 재설정 링크를 보내 드렸어요.';

  @override
  String get accountYourAccount => '내 계정';

  @override
  String accountRankValue(int rank) {
    return '$rank위';
  }

  @override
  String accountStreakValue(int days) {
    return '$days일';
  }

  @override
  String get accountCardTravels =>
      '이 카드는 계정과 함께 움직여요. 새 휴대폰에서도 하던 곳부터 바로 이어서 할 수 있어요.';

  @override
  String get accountYourNameHeader => '내 이름';

  @override
  String get accountChangeName => '이름 바꾸기';

  @override
  String get accountChangeNameDetail => '순위표에 보이는 이름이에요';

  @override
  String get accountShowOnBoards => '순위표에 나를 표시';

  @override
  String get accountShowOnBoardsDetail => '끄면 이름과 순위가 숨겨져요. 별은 그대로 쌓여요.';

  @override
  String get accountYourPlayHeader => '내 플레이';

  @override
  String get accountStatistics => '통계';

  @override
  String get accountStatisticsDetail => '기록, 활동, 모든 레벨';

  @override
  String get accountSessionHeader => '세션';

  @override
  String get accountDeleteHint => '계정을 삭제하려면 설정 → 위험 구역으로 가세요.';

  @override
  String get accountVisibilityFailed => '서버에 연결할 수 없어서 바뀐 건 없어요.';

  @override
  String get accountSignOutTitle => '로그아웃할까요?';

  @override
  String get accountSignOutBody =>
      '진행 상황은 이 휴대폰에 남아요. 언제든 다시 로그인하면 다른 기기에서 이어서 할 수 있어요.';

  @override
  String get accountStaySignedIn => '로그인 유지';

  @override
  String get accountSignOut => '로그아웃';

  @override
  String get accountSignOutDetail => '진행 상황은 이 휴대폰에 남아요';

  @override
  String get accountSaveTitle => '진행 상황 저장';

  @override
  String get accountSaveIntro =>
      '별, 연속 기록, 순위표 이름이 계정과 함께 움직여요. 새 휴대폰에서도 하던 곳부터 이어서 할 수 있어요.';

  @override
  String get accountContinueApple => 'Apple로 계속하기';

  @override
  String get accountContinueGoogle => 'Google로 계속하기';

  @override
  String get accountOr => '또는';

  @override
  String get accountEmailLabel => '이메일';

  @override
  String get accountEmailEmpty => '이메일을 입력해 주세요.';

  @override
  String get accountPasswordLabel => '비밀번호';

  @override
  String get accountPasswordHelper => '8자 이상';

  @override
  String get accountPasswordEmpty => '비밀번호를 입력해 주세요.';

  @override
  String get accountPasswordShort => '8자 이상 입력해 주세요.';

  @override
  String get accountShowPassword => '비밀번호 보기';

  @override
  String get accountHidePassword => '비밀번호 숨기기';

  @override
  String get accountCreate => '계정 만들기';

  @override
  String get accountSwitchToSignIn => '이미 계정이 있나요? 로그인';

  @override
  String get accountSwitchToSignInSemantic => '대신 로그인하기';

  @override
  String get accountSwitchToCreate => '계정이 없나요? 만들기';

  @override
  String get accountSwitchToCreateSemantic => '대신 계정 만들기';

  @override
  String get accountForgotPassword => '비밀번호를 잊으셨나요?';

  @override
  String get accountForgotPasswordSemantic => '비밀번호 재설정';

  @override
  String get accountNaming => '이름 짓는 중…';

  @override
  String get accountSignedInLabel => '로그인됨';

  @override
  String accountPouringSince(String month, int year) {
    return '$year년 $month부터 플레이';
  }

  @override
  String get accountPlayerCardTag => '플레이어 카드';

  @override
  String get accountStatSolved => '클리어';

  @override
  String get accountStatStars => '별';

  @override
  String get accountStatStreak => '연속';

  @override
  String get accountStatRank => '순위';

  @override
  String accountStarsValue(int stars) {
    return '$stars★';
  }

  @override
  String get accountSyncing => '동기화 중…';

  @override
  String get accountSyncingDetail => '진행 상황을 계정에 저장하는 중';

  @override
  String get accountWaitingToSync => '동기화 대기 중';

  @override
  String get accountWaitingOffline => '다시 온라인이 되면 저장돼요';

  @override
  String get accountWaitingPending => '최근 레벨을 곧 올려요';

  @override
  String get accountSyncedDetail => '진행 상황이 계정에 저장됐어요';

  @override
  String get accountSynced => '동기화됨';

  @override
  String get accountSyncedJustNow => '방금 동기화됨';

  @override
  String accountSyncedMinutesAgo(int minutes) {
    return '$minutes분 전 동기화됨';
  }

  @override
  String accountSyncedHoursAgo(int hours) {
    return '$hours시간 전 동기화됨';
  }

  @override
  String accountSyncedDaysAgo(int days) {
    return '$days일 전 동기화됨';
  }

  @override
  String get accountCrestSignedIn => '내 계정';

  @override
  String get accountCrestGuest => '게스트로 플레이 중';

  @override
  String get accountRenameRefused => '이 이름은 사용할 수 없어요.';

  @override
  String get accountRenameOffline => '서버에 연결할 수 없어요. 잠시 후 다시 시도해 주세요.';

  @override
  String get ranksTitle => '랭킹';

  @override
  String get ranksTabToday => '오늘';

  @override
  String get ranksTabCampaign => '캠페인';

  @override
  String get ranksLoading => '순위표를 불러오는 중…';

  @override
  String get ranksEmptyDailyTitle => '오늘 퍼즐을 끝낸 사람이 아직 없어요';

  @override
  String get ranksEmptyDailyDetail => '첫 번째가 되어 보세요.';

  @override
  String get ranksEmptyCampaignTitle => '아직 순위에 오른 플레이어가 없어요';

  @override
  String get ranksEmptyCampaignDetail => '여기는 별 개수로 순위가 정해져요.';

  @override
  String get ranksYourSpot => '내 순위';

  @override
  String ranksPlayerCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '이 순위표에 $countString명',
    );
    return '$_temp0';
  }

  @override
  String ranksMoves(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count수',
    );
    return '$_temp0';
  }

  @override
  String ranksStars(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '별 $count개',
    );
    return '$_temp0';
  }

  @override
  String ranksLevels(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count레벨',
    );
    return '$_temp0';
  }

  @override
  String ranksInTime(String time) {
    return '$time 소요';
  }

  @override
  String get ranksOpenSpot => '빈자리';

  @override
  String ranksNameYou(String name) {
    return '$name (나)';
  }

  @override
  String ranksPlaceOpen(int place) {
    return '$place위, 비어 있음';
  }

  @override
  String ranksPlaceSemantic(int rank, String name, String score) {
    return '$rank위, $name, $score';
  }

  @override
  String ranksScoreWithTieBreak(String score, String tieBreak) {
    return '$score, $tieBreak';
  }

  @override
  String get ranksOffTitle => '이 빌드에서는 순위표가 꺼져 있어요';

  @override
  String get ranksOffDetail => '캠페인은 영향이 없어요.';

  @override
  String get ranksLoadFailed => '순위표를 불러오지 못했어요';

  @override
  String get ranksOffline => '오프라인인 것 같아요. 모든 레벨은 연결 없이도 플레이할 수 있어요.';

  @override
  String get ranksTimeout => '서버 응답이 너무 오래 걸렸어요.';

  @override
  String get ranksServerError => '저희 쪽에 문제가 생겼어요. 진행 상황은 안전해요.';

  @override
  String get ranksHiddenTitle => '숨김 상태예요';

  @override
  String get ranksHiddenDetail =>
      '별과 연속 기록은 그대로 쌓여요. 여기에만 보이지 않아요. 설정에서 바꿀 수 있어요.';

  @override
  String get statsTitle => '내 통계';

  @override
  String get statsTabOverview => '개요';

  @override
  String get statsTabLevels => '레벨';

  @override
  String get statsTabBadges => '배지';

  @override
  String get statsPaceOnPar => '기준과 같음';

  @override
  String statsPaceUnder(int percent) {
    return '$percent% 빠름';
  }

  @override
  String statsPaceOver(int percent) {
    return '$percent% 느림';
  }

  @override
  String get statsEmptyTitle => '아직 보여 줄 기록이 없어요';

  @override
  String get statsEmptyBody =>
      '레벨을 클리어하면 여기가 채워져요. 기준 시간 대비 기록, 최고 기록, 플레이한 날들이 보여요.';

  @override
  String get statsBackToLevels => '레벨로 돌아가기';

  @override
  String get statsLevelsSolved => '클리어한 레벨';

  @override
  String get statsStars => '별';

  @override
  String get statsPoints => '점수';

  @override
  String get statsPlayed => '플레이 시간';

  @override
  String get statsNowOn => '현재 위치';

  @override
  String get statsBestSolveMoves => '최고 기록의 총 수';

  @override
  String get statsAgainstClock => '시간 기록';

  @override
  String get statsNoTimes =>
      '아직 기록된 시간이 없어요. 시계가 생기기 전에 클리어한 레벨은 시간이 없어요. 한 번 다시 플레이하면 기록이 시작돼요.';

  @override
  String get statsFastest => '최단';

  @override
  String get statsLongest => '최장';

  @override
  String get statsAvgPace => '평균 페이스';

  @override
  String statsClockValue(String time, int level) {
    return '$time · Lv.$level';
  }

  @override
  String statsUntimed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '클리어한 레벨 중 $count개는 시계가 생기기 전에 클리어해서 시간 기록이 없어요.',
    );
    return '$_temp0';
  }

  @override
  String statsUnderParSemantic(int under, int total) {
    return '시간이 기록된 레벨 $total개 중 $under개가 기준 시간 이내';
  }

  @override
  String get statsUnderParTag => '기준 이내';

  @override
  String get statsLast30Days => '최근 30일';

  @override
  String statsStreakChip(int count) {
    return '$count일 연속';
  }

  @override
  String get statsNoStreak => '연속 기록 없음';

  @override
  String statsDaysPlayed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count일 플레이',
    );
    return '$_temp0';
  }

  @override
  String statsLevelsFinished(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count레벨 완료',
    );
    return '$_temp0';
  }

  @override
  String statsBestStreak(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '최고 $count일',
    );
    return '$_temp0';
  }

  @override
  String get statsToday => '오늘';

  @override
  String statsMonthShort(String month) {
    String _temp0 = intl.Intl.selectLogic(month, {
      'jan': '1월',
      'feb': '2월',
      'mar': '3월',
      'apr': '4월',
      'may': '5월',
      'jun': '6월',
      'jul': '7월',
      'aug': '8월',
      'sep': '9월',
      'oct': '10월',
      'nov': '11월',
      'dec': '12월',
      'other': '$month',
    });
    return '$_temp0';
  }

  @override
  String statsMonthDay(String month, int day) {
    return '$month $day일';
  }

  @override
  String statsBarLevels(String day, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$day · $count레벨',
    );
    return '$_temp0';
  }

  @override
  String statsBarNoPlay(String day) {
    return '$day · 플레이 없음';
  }

  @override
  String get statsWorldAhead => '예정';

  @override
  String get statsWorldNoTimes => '기록 없음';

  @override
  String statsWorldPoints(int points) {
    final intl.NumberFormat pointsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String pointsString = pointsNumberFormat.format(points);

    return '$pointsString점';
  }

  @override
  String statsWorldSolvedSemantic(String name, int cleared, int total) {
    return '$name: $total개 중 $cleared개 클리어';
  }

  @override
  String statsWorldPaceSemantic(String pace) {
    return '페이스 $pace';
  }

  @override
  String statsWorldPointsSemantic(int points) {
    final intl.NumberFormat pointsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String pointsString = pointsNumberFormat.format(points);

    return '$pointsString점';
  }

  @override
  String get statsColLevel => '레벨';

  @override
  String get statsColStars => '별';

  @override
  String get statsColMoves => '이동';

  @override
  String get statsColTime => '시간';

  @override
  String get statsColPoints => '점수';

  @override
  String statsMovesBestPossible(int moves, int best) {
    return '$moves수, 최소 $best수';
  }

  @override
  String statsMoves(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count수',
    );
    return '$_temp0';
  }

  @override
  String badgeUnlockedCount(int earned, int total) {
    return '$total개 중 $earned개 달성';
  }

  @override
  String get badgeUnlocked => '달성';

  @override
  String get badgeNotYet => '미달성';

  @override
  String badgeProgress(int shown, int target) {
    return '$target 중 $shown';
  }

  @override
  String badgeSemantic(String title, String description, String status) {
    return '$title: $description $status';
  }

  @override
  String get badgeFirstPourTitle => '첫 따르기';

  @override
  String get badgeFirstPourDesc => '첫 레벨을 클리어하세요.';

  @override
  String get badgePar10Title => '파 달성';

  @override
  String get badgePar10Desc => '레벨 10개를 정확히 파로 클리어하세요.';

  @override
  String get badgePar50Title => '파 마스터';

  @override
  String get badgePar50Desc => '레벨 50개를 정확히 파로 클리어하세요.';

  @override
  String get badgeCleanClearTitle => '되돌리기 없이';

  @override
  String get badgeCleanClearDesc => '되돌리기 없이 레벨을 클리어하세요.';

  @override
  String get badgeSpeedyTitle => '재빠른 손';

  @override
  String get badgeSpeedyDesc => '30초 안에 레벨을 클리어하세요.';

  @override
  String get badgeLevels100Title => '백전노장';

  @override
  String get badgeLevels100Desc => '레벨 100개를 클리어하세요.';

  @override
  String get badgeStars300Title => '별 수집가';

  @override
  String get badgeStars300Desc => '별 300개를 모으세요.';

  @override
  String get badgeWorldPerfectTitle => '완벽한 월드';

  @override
  String get badgeWorldPerfectDesc => '한 월드의 모든 레벨에서 별 3개를 받으세요.';

  @override
  String get badgeStreak7Title => '일주일 연속';

  @override
  String get badgeStreak7Desc => '오늘의 퍼즐 7일 연속 기록을 달성하세요.';

  @override
  String get badgeStreak30Title => '한 달 연속';

  @override
  String get badgeStreak30Desc => '오늘의 퍼즐 30일 연속 기록을 달성하세요.';

  @override
  String get badgeChests5Title => '보물 사냥꾼';

  @override
  String get badgeChests5Desc => '별 상자를 5개 여세요.';

  @override
  String get badgeHard5Title => '만만치 않아';

  @override
  String get badgeHard5Desc => '하드 레벨 5개를 클리어하세요.';

  @override
  String get badgeEventFullTitle => '꽉 찬 한 주';

  @override
  String get badgeEventFullDesc => '주간 이벤트의 보드 7개를 모두 클리어하세요.';

  @override
  String get badgeZen25Title => 'Zen 정원';

  @override
  String get badgeZen25Desc => 'Zen 모드에서 보드 25개를 완성하세요.';

  @override
  String get commonCancel => '취소';

  @override
  String get commonClose => '닫기';

  @override
  String get commonBack => '뒤로';

  @override
  String get commonOk => '확인';

  @override
  String get commonSave => '저장';

  @override
  String get commonRetry => '다시 시도';

  @override
  String get commonNotNow => '나중에';

  @override
  String commonLevelN(int level) {
    return '레벨 $level';
  }

  @override
  String get hubAccountYours => '내 계정';

  @override
  String get hubAccountSave => '진행 상황 저장';

  @override
  String get hubPlayerFallback => '플레이어';

  @override
  String get hubSettings => '설정';

  @override
  String get hubTagline => '따르고 · 정렬하고 · 쉬어요';

  @override
  String hubStatChipSemantic(String value, String label) {
    return '$label $value. 통계';
  }

  @override
  String get hubStatSolved => '클리어';

  @override
  String get hubStatStars => '별';

  @override
  String get hubStatStreak => '연속';

  @override
  String hubStreakDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count일',
    );
    return '$_temp0';
  }

  @override
  String hubRankNumber(int rank) {
    return '$rank위';
  }

  @override
  String hubEventSemantic(int cleared, int total) {
    return '주간 이벤트, 보드 $total개 중 $cleared개';
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
    return '$cleared/$total · $rank위 · $timeLeft';
  }

  @override
  String get hubZen => 'Zen';

  @override
  String get hubZenSemantic => 'Zen 모드';

  @override
  String hubZenLockedSemantic(int level) {
    return 'Zen 모드는 레벨 $level에서 열려요';
  }

  @override
  String get hubZenOpen => '끝없이, 시간 제한 없이';

  @override
  String hubZenLocked(int level, int remaining) {
    return '레벨 $level · $remaining개 남음';
  }

  @override
  String get hubDockJourney => '여정';

  @override
  String get hubDockRankings => '랭킹';

  @override
  String get hubDockStats => '통계';

  @override
  String get hubTip => '잘했어요! 여정에서 모든 레벨을 볼 수 있고, 매일 새로운 오늘의 퍼즐도 기다리고 있어요.';

  @override
  String hubHeroWorld(int world) {
    return '월드 $world';
  }

  @override
  String hubHeroWorldBand(int world, String band) {
    return '월드 $world · $band';
  }

  @override
  String hubHeroPar(int par) {
    return '파 $par';
  }

  @override
  String get hubPlay => '플레이';

  @override
  String hubPlaySemantic(int level) {
    return '레벨 $level 플레이';
  }

  @override
  String get hubMoreUpdateTitle => '업데이트하고 더 플레이하기';

  @override
  String get hubMoreUpdateBody =>
      '새 월드가 나왔어요. 최신 Pourfect가 필요해요. 게임을 업데이트하고 계속 따라 보세요.';

  @override
  String get hubMoreDownloadingTitle => '새 레벨이 오고 있어요';

  @override
  String get hubMoreDownloadingBody => '다음 월드를 내려받는 중이에요. 금방 끝나요.';

  @override
  String get hubMoreAllDoneTitle => '전부 다 따랐어요!';

  @override
  String get hubMoreOfflineBody =>
      '인터넷에 연결하면 레벨이 백그라운드에서 더 내려받아져요. 그동안 오늘의 퍼즐이 기다리고 있어요.';

  @override
  String get hubMoreOnlineBody =>
      '온라인일 때마다 레벨이 백그라운드에서 더 내려받아져요. 그동안 오늘의 퍼즐이 기다리고 있어요.';

  @override
  String get hubMoreCheckAgain => '다시 확인';

  @override
  String hubAchievementOne(String title) {
    return '업적 달성: $title';
  }

  @override
  String hubAchievementMany(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '업적 $count개 달성!',
    );
    return '$_temp0';
  }

  @override
  String get hubUpdateReady => '업데이트를 설치할 준비가 됐어요.';

  @override
  String get hubUpdateRestart => '재시작';

  @override
  String hubSpanSeconds(int seconds) {
    return '$seconds초';
  }

  @override
  String hubSpanMinutes(int minutes) {
    return '$minutes분';
  }

  @override
  String hubSpanMinutesSeconds(int minutes, int seconds) {
    return '$minutes분 $seconds초';
  }

  @override
  String hubSpanHours(int hours) {
    return '$hours시간';
  }

  @override
  String hubSpanHoursMinutes(int hours, int minutes) {
    return '$hours시간 $minutes분';
  }

  @override
  String get hubParOn => '기준 시간과 같음';

  @override
  String hubParUnder(int percent) {
    return '기준 시간보다 $percent% 빠름';
  }

  @override
  String hubParOver(int percent) {
    return '기준 시간보다 $percent% 느림';
  }

  @override
  String get dailyTitle => '오늘의 퍼즐';

  @override
  String get dailyCardSemantic => '오늘의 도전';

  @override
  String get dailyCardUnavailable => '오늘 보드를 불러올 수 없어요';

  @override
  String get dailyCardSolved => '완료';

  @override
  String dailyCardNextIn(String time) {
    return '다음까지 $time';
  }

  @override
  String dailyCardEndsIn(String time) {
    return '종료까지 $time';
  }

  @override
  String dailyStreakDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count일 연속',
    );
    return '$_temp0';
  }

  @override
  String dailyStreakMilestone(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count일 연속!',
    );
    return '$_temp0';
  }

  @override
  String get dailyRankSemantic => '순위표';

  @override
  String dailyRankSemanticRanked(int rank) {
    return '순위표, $rank위';
  }

  @override
  String get dailyRankSticker => '순위';

  @override
  String get dailyLeaveLost =>
      '오늘의 퍼즐에서 둔 수는 저장되지 않아요. 오늘 안에 언제든 다시 시작할 수 있어요.';

  @override
  String get dailySubmitRefused => '서버에서 이 결과를 받지 않았어요.';

  @override
  String get dailySubmitFailed => '클리어했지만 결과를 보내지 못했어요. 나중에 다시 시도해 주세요.';

  @override
  String get dailyHudLabel => '오늘의';

  @override
  String get dailyHudValue => '퍼즐';

  @override
  String get dailyDeadEndRestart => '여기서는 끝낼 방법이 없어요. 다시 시작해서 다른 길로 가 보세요.';

  @override
  String dailyDeadEndUndo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '여기서는 끝낼 방법이 없어요. $count수 되돌리면 다시 풀 수 있어요.',
    );
    return '$_temp0';
  }

  @override
  String get dailyActionRestart => '다시 시작';

  @override
  String dailyActionUndo(int count) {
    return '$count수 되돌리기';
  }

  @override
  String get dailyNoHint => '이 상황에 맞는 힌트가 없어요.';

  @override
  String get dailyLoadingTitle => '오늘의 보드를 불러오는 중';

  @override
  String get dailyOffTitle => '이 빌드에서는 오늘의 퍼즐이 꺼져 있어요';

  @override
  String get dailyOffDetail => '캠페인은 영향이 없어요. 모든 레벨이 이 기기에 있어요.';

  @override
  String get dailyNoBoardTitle => '오늘은 보드가 없어요';

  @override
  String get dailyNoBoardDetail =>
      '오늘의 도전은 서버에서 받아 오는데, 서버에 연결할 수 없었어요. 캠페인은 서버 없이도 할 수 있어요.';

  @override
  String get dailyLoaderCaption => '오늘의 보드를 따르는 중…';

  @override
  String get dailyBackToLevels => '레벨로 돌아가기';

  @override
  String dailyWeekSemantic(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count일',
    );
    return '연속 기록: $_temp0. 열기';
  }

  @override
  String dailyDaySemantic(String weekday, String state) {
    return '$weekday, $state';
  }

  @override
  String get dailyDayFrozen => '놓쳤지만 보호권으로 지킴';

  @override
  String get dailyDayPlayedToday => '오늘 플레이함';

  @override
  String get dailyDayPlayed => '플레이함';

  @override
  String get dailyDayToday => '오늘, 아직 안 함';

  @override
  String get dailyDayMissed => '플레이 안 함';

  @override
  String get dailyDayFuture => '아직 오지 않음';

  @override
  String get dailyOutcomeBest => '최고 기록 경신';

  @override
  String get dailyOutcomeSolved => '완료';

  @override
  String get dailyFigureMoves => '이동';

  @override
  String get dailyFigureStreak => '연속';

  @override
  String get dailyUnranked => '순위 없음';

  @override
  String dailyOfPlayers(int count) {
    return '$count명 중';
  }

  @override
  String get dailyReminderOn => '내일 저녁에 알림을 한 번 보내 드릴게요.';

  @override
  String get dailyRemindMe => '내일 알려 주세요';

  @override
  String get dailyDone => '완료';

  @override
  String get dailyFreezeVideoUnfinished => '보호권을 받지 못했어요. 영상을 끝까지 보지 않았어요.';

  @override
  String get dailyFreezeNoVideo => '지금은 볼 수 있는 영상이 없어요.';

  @override
  String get dailyFreezeError => '문제가 생겼어요. 나중에 다시 시도해 주세요.';

  @override
  String get dailyFreezeAdded => '보호권을 받았어요. 놓친 하루를 지켜 줘요.';

  @override
  String get dailyFreezeNoRoom => '오늘은 보호권을 더 받을 수 없어요.';

  @override
  String get dailyFreezeLoadingVideo => '영상 불러오는 중…';

  @override
  String get dailyFreezeWatch => '영상 보고 보호권 받기';

  @override
  String get dailyFreezesFull => '보호권이 가득 찼어요. 하나당 놓친 하루를 지켜 줘요.';

  @override
  String get dailyFreezeTomorrow => '영상 보호권은 하루에 하나예요. 내일 또 만나요.';

  @override
  String get dailyStreakTitle => '연속 기록';

  @override
  String get dailyStreakNone => '아직 연속 기록이 없어요';

  @override
  String get dailyStreakStart => '오늘의 퍼즐을 풀고 연속 기록을 시작해 보세요.';

  @override
  String dailyStreakBest(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '최고: $count일',
    );
    return '$_temp0';
  }

  @override
  String dailyFreezesSemantic(int count, int max) {
    return '연속 보호권 $max개 중 $count개';
  }

  @override
  String get dailyFreezesTitle => '연속 보호권';

  @override
  String get dailyFreezesEach => '하나당 놓친 하루를 지켜 줘요.';

  @override
  String dailyFreezeWeekly(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '매주 월요일 하나씩 무료, $days일 뒤에 받아요.',
      one: '매주 월요일 하나씩 무료, 내일 받아요.',
    );
    return '$_temp0';
  }

  @override
  String get dailyCalendarPrevious => '이전 달';

  @override
  String get dailyCalendarNext => '다음 달';

  @override
  String dailyCalendarCellSemantic(String date, String state) {
    return '$date, $state';
  }

  @override
  String get dailyCalendarPlayed => '플레이함';

  @override
  String get dailyCalendarFrozen => '보호됨';

  @override
  String get dailyCalendarFuture => '예정';

  @override
  String get dailyLegendPlayed => '플레이';

  @override
  String get dailyLegendFrozen => '보호';

  @override
  String get dailyLegendToday => '오늘';

  @override
  String get eventTitle => '주간 이벤트';

  @override
  String get eventUnreachable => '지금은 이번 주 이벤트를 불러올 수 없어요.';

  @override
  String get eventEnded => '종료됨';

  @override
  String eventEndsIn(String timeLeft) {
    return '$timeLeft 후 종료';
  }

  @override
  String eventTimeLeftDaysHours(int days, int hours) {
    return '$days일 $hours시간';
  }

  @override
  String eventTimeLeftHours(int hours) {
    return '$hours시간';
  }

  @override
  String eventTimeLeftMinutes(int minutes) {
    return '$minutes분';
  }

  @override
  String eventSummary(int cleared, int total, String endsIn) {
    return '보드 $total개 중 $cleared개 · $endsIn';
  }

  @override
  String get eventFigurePoints => '점수';

  @override
  String eventRankOf(int count) {
    return '$count명 중';
  }

  @override
  String get eventRankPlay => '보드를 하나 풀면 순위가 생겨요';

  @override
  String get eventRankSetName => '이름을 정하면 순위가 생겨요';

  @override
  String eventTileSemanticDone(int slot, int stars, int points) {
    String _temp0 = intl.Intl.pluralLogic(
      stars,
      locale: localeName,
      other: '별 $stars개',
    );
    return '보드 $slot, $_temp0, $points점';
  }

  @override
  String eventTileSemanticNew(int slot) {
    return '보드 $slot, 플레이 안 함';
  }

  @override
  String eventTilePoints(int points) {
    return '$points점';
  }

  @override
  String get eventStandingsTitle => '이번 주 순위표';

  @override
  String get eventStandingsEmpty => '아직 순위표에 아무도 없어요. 첫 번째가 되어 보세요.';

  @override
  String eventStandingsCleared(int cleared) {
    return ' · $cleared/7';
  }

  @override
  String get eventSubmitRefused => '서버에서 이 결과를 받지 않았어요. 이벤트가 끝났을 수도 있어요.';

  @override
  String get eventSubmitFailed => '클리어했지만 결과를 보내지 못했어요. 다시 시도해 주세요.';

  @override
  String eventDeadEndUndo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '여기서는 끝낼 방법이 없어요. $count수 되돌려 보세요.',
    );
    return '$_temp0';
  }

  @override
  String get eventNoHint => '지금은 이 상황에 맞는 힌트가 없어요.';

  @override
  String get eventHudLabel => '보드';

  @override
  String eventHudBand(String event, String endsIn) {
    return '$event · $endsIn';
  }

  @override
  String get eventSending => '보내는 중…';

  @override
  String eventResult(int points, int total) {
    return '$points점 · 이번 주 $total점';
  }

  @override
  String eventResultRanked(int points, int total, int rank) {
    return '$points점 · 이번 주 $total점 · $rank위';
  }

  @override
  String get journeyTitle => '여정';

  @override
  String journeyStarsSemantic(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '별 $count개',
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
    return '월드 $worlds개 중 $world번째, $name, $total개 중 $solved개 클리어';
  }

  @override
  String journeyWorldOf(int world, int worlds) {
    return '월드 $world / $worlds';
  }

  @override
  String journeyRibbonSemantic(int world, String name, int solved, int total) {
    return '월드 $world, $name, $total개 중 $solved개 클리어. 이동하기';
  }

  @override
  String journeyRibbonLabel(int world, String name) {
    return '월드 $world · $name';
  }

  @override
  String get journeyYouPin => '나';

  @override
  String journeyBandCaps(int world, int count) {
    return '월드 $world · $count';
  }

  @override
  String get journeyBandFirstPours => '첫걸음';

  @override
  String get journeyBandFindingRhythm => '리듬 찾기';

  @override
  String get journeyBandDeepWater => '깊은 물';

  @override
  String get journeyBandMastery => '마스터';

  @override
  String get notifSoftAskTitle => '알림을 받아 볼까요?';

  @override
  String get notifSoftAskBody =>
      '오늘의 퍼즐이 나오거나 다음 레벨이 기다릴 때 알려 드려요. 하루 두 번을 넘지 않고, 설정에서 언제든 끌 수 있어요.';

  @override
  String get notifSoftAskBodyDenied =>
      'Pourfect 알림이 꺼져 있어요. 휴대폰 설정에서 켜면 오늘의 퍼즐이 나오거나 새 월드가 열릴 때 알려 드려요. 하루 두 번을 넘지 않아요.';

  @override
  String get notifSoftAskOpenSettings => '설정 열기';

  @override
  String get notifSoftAskYes => '좋아요';

  @override
  String get notifChannelName => '리마인더';

  @override
  String get notifChannelDescription =>
      '오늘의 퍼즐, 다음 레벨, 새 월드 소식. 하루 두 번을 넘지 않아요.';

  @override
  String get playHudLevel => '레벨';

  @override
  String playHudTitle(String label, String value) {
    return '$label $value';
  }

  @override
  String get playHudHard => '하드 ×1.5';

  @override
  String get playHudHardLabel => '하드 레벨, 점수 1.5배';

  @override
  String get playHudMoves => '이동';

  @override
  String playHudMovesLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count수',
    );
    return '$_temp0';
  }

  @override
  String playParLeftFor3Stars(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '별 3개까지 $count수 남음',
    );
    return '$_temp0';
  }

  @override
  String get playParSpent => '파 소진 · 이제부터 별 2개';

  @override
  String playParLeftFor2Stars(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '별 2개까지 $count수 남음',
    );
    return '$_temp0';
  }

  @override
  String get playParOneStarFromHere => '이제부터 별 1개 · 완료만 하면 돼요';

  @override
  String get playParAnyFinish => '완료하면 별 1개';

  @override
  String playParMeterLabel(int stars, int used, int par, String words) {
    return '별 $stars개 페이스, 파 $par수 중 $used수 사용. $words';
  }

  @override
  String playHudBusyLabel(String label) {
    return '$label, 처리 중. 탭하면 취소';
  }

  @override
  String get playHudUndo => '되돌리기';

  @override
  String get playHudHint => '힌트';

  @override
  String get playHudRestart => '다시 시작';

  @override
  String get playExtraTubeLabel => '영상 보고 튜브 하나 더 받기';

  @override
  String get playExtraTubeChip => '+ 튜브';

  @override
  String playStarsOfTotal(int earned, int total) {
    return '별 $total개 중 $earned개';
  }

  @override
  String get playDismiss => '닫기';

  @override
  String get playLeaveTitleSoSoon => '벌써 가려고요?';

  @override
  String get playLeaveTitleMissYou => '공들이 보고 싶어 할 거예요';

  @override
  String get playLeaveTitleAbandon => '그만 따를까요?';

  @override
  String get playLeaveTitleMidPour => '따르다 말고 가요?';

  @override
  String get playLeaveBody => '이 보드에서 둔 수와 시간은 저장되지 않아요.';

  @override
  String get playLeaveKeepPouring => '계속하기';

  @override
  String get playLeaveConfirm => '나가기';

  @override
  String get playTutorialSkipLabel => '튜토리얼 건너뛰기';

  @override
  String get playTutorialSkip => '건너뛰기';

  @override
  String playTipBubbleLabel(String text) {
    return '$text. 닫기';
  }

  @override
  String get playTipPar => '파 이내로 끝내면 별 3개예요. 막대가 얼마나 썼는지 보여 줘요.';

  @override
  String get playTipTallTubes => '더 큰 튜브! 이제 튜브마다 공이 5개 들어가요.';

  @override
  String get playTipHint => '막혔나요? 힌트가 좋은 다음 수를 알려 줘요.';

  @override
  String get playTipUndo => '파를 넘겼나요? 되돌리기는 무료예요. 원하는 만큼 되돌려 보세요.';

  @override
  String get playGuideSorted => '정렬 완료! 이제 모든 튜브를 한 가지 색으로 맞춰요.';

  @override
  String get playGuideDrop => '이제 옮길 곳을 탭하세요. 같은 색 위나 빈 튜브에요.';

  @override
  String get playGuideWrongTube => '손이 가리키는 튜브를 탭해서 그 공을 집어 보세요.';

  @override
  String get playGuideFirstTap => '튜브를 탭해서 맨 위의 공을 집어요.';

  @override
  String get playGuideFirstPour => '잘 따랐어요! 계속해 보세요.';

  @override
  String get playGuideKeepGoing => '계속해요. 튜브 하나에 한 가지 색이에요.';

  @override
  String playCoachHolding(int count) {
    return '$count개 집음 · 통통 튀는 튜브에 넣어요';
  }

  @override
  String get playExtraTubeAdTitle => '영상 보고 튜브를 하나 더 받을까요?';

  @override
  String get playExtraTubeAdBody =>
      '이 레벨에서 빈 튜브가 하나 더 생겨요. 추가 튜브로 클리어하면 별은 최대 2개예요.';

  @override
  String get playExtraTubeNotFinished => '튜브를 받지 못했어요. 영상을 끝까지 보지 않았어요.';

  @override
  String get playExtraTubeSaved => '저장했어요. 다음 튜브는 무료예요.';

  @override
  String get playNoVideo => '지금은 볼 수 있는 영상이 없어요.';

  @override
  String get playRewardFailed => '문제가 생겼어요. 아무것도 사용되지 않았어요.';

  @override
  String get playHintShowing => '힌트가 표시되어 있어요. 빛나는 튜브에 따르세요.';

  @override
  String get playHintNoneNothingUsed => '이 상황에 맞는 힌트가 없어요. 아무것도 사용되지 않았어요.';

  @override
  String get playHintNotFinished => '힌트를 받지 못했어요. 영상을 끝까지 보지 않았어요.';

  @override
  String get playHintVideoSaved => '본 영상은 다음 힌트에 쓰도록 저장했어요.';

  @override
  String get playHintNoneVideoSaved =>
      '이 상황에 맞는 힌트가 없어요. 본 영상은 다음 힌트에 쓰도록 저장했어요.';

  @override
  String get playHintNone => '이 상황에서는 쓸 수 있는 힌트가 없어요.';

  @override
  String get playHintHere => '힌트예요. 빛나는 튜브에 따르세요.';

  @override
  String get playDeadEndRestart => '여기서는 끝낼 방법이 없어요. 다시 시작해서 다른 길로 가 보세요.';

  @override
  String get playDeadEndRestartTube =>
      '여기서는 끝낼 방법이 없어요. 다시 시작해서 다른 길로 가 보세요. 또는 + 튜브를 탭해 여분 튜브를 받으세요.';

  @override
  String playDeadEndUndo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '여기서는 끝낼 방법이 없어요. $count수 되돌리면 다시 풀 수 있어요.',
    );
    return '$_temp0';
  }

  @override
  String playDeadEndUndoTube(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '여기서는 끝낼 방법이 없어요. $count수 되돌리면 다시 풀 수 있어요. 또는 + 튜브를 탭해 여분 튜브를 받으세요.',
    );
    return '$_temp0';
  }

  @override
  String playDeadEndUndoAction(int count) {
    return '$count수 되돌리기';
  }

  @override
  String get playHintAdTitle => '영상 보고 힌트를 받을까요?';

  @override
  String playHintAdFreeLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '무료 힌트가 $count개 남았어요.',
    );
    return '$_temp0';
  }

  @override
  String get playHintAdNoneLeft => '무료 힌트를 모두 썼어요. 짧은 영상을 보면 하나 더 받아요.';

  @override
  String get playWatch => '보기';

  @override
  String get playLoadFailed => '레벨을 불러오지 못했어요';

  @override
  String get playTubeSorted => '완성!';

  @override
  String get playWinTitlePerfect => '완벽한\n따르기!';

  @override
  String get playWinTitleNice => '멋진\n따르기!';

  @override
  String get playWinTitlePoured => '완료!';

  @override
  String get playWinLastPour => '마지막 한 번…';

  @override
  String playWinMovesPar(int count, int par) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count수 · 파 $par',
    );
    return '$_temp0';
  }

  @override
  String playWinLevelBand(int level, String band) {
    return '레벨 $level · $band';
  }

  @override
  String get playWinNewBest => '최고 기록!';

  @override
  String playWinMovesChip(int par) {
    return '이동 · 파 $par';
  }

  @override
  String get playWinUntimed => '시간 없음';

  @override
  String get playWinFastest => '최단 기록!';

  @override
  String get playWinTime => '시간';

  @override
  String get playWinUnderPar => '기준 시간 이내!';

  @override
  String get playWinPoints => '점수';

  @override
  String playWinWorldBand(int world, String band) {
    return '월드 $world · $band';
  }

  @override
  String get playWinTryAssisted => '별 3개는 추가 튜브 없이 클리어해야 받아요.';

  @override
  String playWinTryShort(int par, int took, int short) {
    String _temp0 = intl.Intl.pluralLogic(
      short,
      locale: localeName,
      other: '파 $par, $took수로 클리어. 별 3개까지 $short수 모자랐어요.',
    );
    return '$_temp0';
  }

  @override
  String playWinTryInReach(int par) {
    return '파 $par. 별 3개가 눈앞이에요.';
  }

  @override
  String get playWinTryButton => '3★ 도전';

  @override
  String get playWinTryButtonLabel => '별 3개를 위해 이 레벨 다시 하기';

  @override
  String get playWinReplayLabel => '이 레벨 다시 하기';

  @override
  String get playWinHomeLabel => '홈 화면으로 돌아가기';

  @override
  String get playWinNextLevel => '다음 레벨';

  @override
  String get playWinBackToLevels => '레벨로 돌아가기';

  @override
  String playChestNextAtLabel(int stars) {
    return '별 $stars개에서 다음 별 상자';
  }

  @override
  String get playChestOpenLabel => '별 상자 열기';

  @override
  String get playChestReady => '별 상자를 열 수 있어요!';

  @override
  String playChestNextAt(int stars) {
    return '다음 상자: $stars ★';
  }

  @override
  String get playChestOpen => '열기';

  @override
  String get playChestDoubleFailed => '이번에는 두 배로 받지 못했어요.';

  @override
  String get playChestDoubleNotFinished => '두 배를 받지 못했어요. 영상을 끝까지 보지 않았어요.';

  @override
  String get playChestOpening => '여는 중…';

  @override
  String playChestTitle(int index) {
    return '별 상자 $index';
  }

  @override
  String get playChestNotYetTitle => '거의 다 왔어요';

  @override
  String get playChestAlreadyOpenTitle => '이미 열었어요';

  @override
  String get playChestFailedTitle => '열지 못했어요';

  @override
  String get playChestNotYetNote =>
      '최근에 받은 별이 아직 서버로 가는 중이에요. 잠시 후 다시 시도해 주세요.';

  @override
  String get playChestAlreadyOpenNote => '이 상자는 다른 기기에서 열었어요.';

  @override
  String get playChestFailedNote => '연결을 확인하고 다시 시도해 주세요.';

  @override
  String playChestRewardCount(int count) {
    return '+$count';
  }

  @override
  String playChestHintsCaption(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '힌트',
    );
    return '$_temp0';
  }

  @override
  String playChestTubesCaption(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '추가 튜브',
    );
    return '$_temp0';
  }

  @override
  String playChestUnlocked(String name) {
    return '획득: $name';
  }

  @override
  String playChestBallSkinName(String skin) {
    return '$skin 공 스킨';
  }

  @override
  String playChestTubeThemeName(String theme) {
    return '$theme 튜브';
  }

  @override
  String get playChestNewLook => '새로운 모습';

  @override
  String get playChestSavedNote => '필요할 때 쓰도록 보관해요. 힌트와 + 튜브가 이것부터 사용해요.';

  @override
  String get playChestLoadingVideo => '영상 불러오는 중…';

  @override
  String get playChestDouble => '영상 보고 두 배로 받기';

  @override
  String get playChestCollect => '받기';

  @override
  String playClockLabel(String time) {
    return '시간 $time';
  }

  @override
  String playClockDetailLabel(
    String time,
    String par,
    String sign,
    int percent,
  ) {
    String _temp0 = intl.Intl.selectLogic(sign, {
      'plus': '플러스',
      'other': '마이너스',
    });
    return '시간 $time, 기준 시간 $par, $_temp0 $percent퍼센트 점수';
  }

  @override
  String playClockBonusChip(String sign, int percent) {
    return '$sign$percent% 점수';
  }

  @override
  String get playLoading => '불러오는 중';

  @override
  String get playWorking => '처리 중';

  @override
  String get playZenTitle => 'Zen';

  @override
  String get playZenIntro => '끝없는 보드. 시간도, 별도, 순위표도 없이 그냥 따르기만 하세요.';

  @override
  String get playZenPaceCalm => '잔잔하게';

  @override
  String get playZenPaceSteady => '꾸준하게';

  @override
  String get playZenPaceDeep => '깊게';

  @override
  String playZenPaceColors(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count가지 색',
    );
    return '$_temp0';
  }

  @override
  String playZenPaceLabel(String pace, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$pace, $count가지 색',
    );
    return '$_temp0';
  }

  @override
  String playZenBandPoured(String pace, int count) {
    return '$pace · $count개 완성';
  }

  @override
  String playZenPoured(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '완성! 지금까지 $count개.',
      one: '완성!',
    );
    return '$_temp0';
  }

  @override
  String get playZenNext => '다음';

  @override
  String get playZenLeaveBody => '이 보드에서 둔 수는 저장되지 않아요. 완성한 개수는 그대로예요.';

  @override
  String get playZenDeadEnd => '여기서는 끝낼 방법이 없어요. 되돌리거나 다시 시작하세요.';

  @override
  String get playZenNoHint => '지금은 이 상황에 맞는 힌트가 없어요.';

  @override
  String get settingsTitle => '설정';

  @override
  String get settingsSectionFeel => '느낌';

  @override
  String get settingsSectionVisibility => '보기';

  @override
  String get settingsSectionLeaderboard => '순위표';

  @override
  String get settingsSectionNotifications => '알림';

  @override
  String get settingsSectionSupport => '지원';

  @override
  String get settingsSectionAccount => '계정 및 정보';

  @override
  String get settingsSectionDanger => '위험 구역';

  @override
  String get settingsSoundTitle => '효과음';

  @override
  String get settingsSoundDetail => '따르기, 버튼, 보상 소리';

  @override
  String get settingsSoundVolume => '효과음 볼륨';

  @override
  String get settingsMusicTitle => '음악';

  @override
  String get settingsMusicDetail => '내 음악을 끊지 않아요';

  @override
  String get settingsMusicVolume => '음악 볼륨';

  @override
  String get settingsHapticsTitle => '진동';

  @override
  String get settingsHapticsDetail => '공이 떨어질 때마다 톡';

  @override
  String get settingsSmoothMotionTitle => '부드러운 화면';

  @override
  String get settingsSmoothMotionAuto => '자동';

  @override
  String get settingsSmoothMotion60 => '60Hz';

  @override
  String get settingsSmoothMotionMax => '최대';

  @override
  String get settingsMotionUnknown => '자동은 휴대폰이 따라올 수 있으면 화면의 최고 주사율을 써요';

  @override
  String settingsMotionFixed(String max) {
    return '이 화면은 ${max}Hz로만 작동해요';
  }

  @override
  String settingsMotionBatterySaver(String current) {
    return '절전 모드 때문에 ${current}Hz로 고정돼 있어요';
  }

  @override
  String settingsMotionAutoStuttered(String current, String max) {
    return '${current}Hz로 작동 중 · 이 휴대폰은 ${max}Hz에서 끊겼어요';
  }

  @override
  String settingsMotionAuto(String current) {
    return '${current}Hz로 작동 중 · 끊기면 60Hz로 낮춰요';
  }

  @override
  String settingsMotionPinnedByPhone(String current) {
    return '휴대폰 디스플레이 설정 때문에 ${current}Hz로 유지돼요';
  }

  @override
  String settingsMotionStandard(String current, String max) {
    return '${current}Hz로 작동 중 · 이 화면은 ${max}Hz까지 가능해요';
  }

  @override
  String settingsMotionMax(String current) {
    return '${current}Hz로 작동 중, 이 화면의 최고 속도예요';
  }

  @override
  String get settingsBoldSymbolsTitle => '굵은 기호';

  @override
  String get settingsBoldSymbolsDetail => '색약·색맹을 위해 모양을 더 뚜렷하게';

  @override
  String get settingsRenameTitle => '이름 바꾸기';

  @override
  String get settingsRenameDetail => '순위표에 보이는 이름이에요';

  @override
  String get settingsShowOnBoardsTitle => '순위표에 나를 표시';

  @override
  String get settingsShowOnBoardsDetail => '끄면 이름과 순위가 숨겨져요. 별은 그대로 쌓여요.';

  @override
  String get settingsHowToPlayTitle => '플레이 방법';

  @override
  String get settingsHowToPlayDetail => '안내가 있는 첫 레벨 다시 하기';

  @override
  String get settingsQuestionsTitle => '자주 묻는 질문';

  @override
  String get settingsQuestionsDetail => '별, 힌트, 시계 등';

  @override
  String get settingsRateTitle => 'Pourfect 평가하기';

  @override
  String get settingsRateDetail => '다른 플레이어에게 의견을 들려주세요';

  @override
  String get settingsCollectionTitle => '컬렉션';

  @override
  String get settingsCollectionDetail => '공 스킨과 튜브 테마';

  @override
  String get settingsRestoreTitle => '구매 복원';

  @override
  String get settingsRestoreDetail => '광고 제거 또는 스킨 팩';

  @override
  String get settingsRestoreDone => '구매 내역이 있다면 복원했어요.';

  @override
  String get settingsRemoveAdsTitle => '광고 제거';

  @override
  String get settingsRemoveAdsDetail => '레벨 사이 광고가 사라져요. 힌트 영상은 남아요.';

  @override
  String get settingsAdsRemoved => '광고 제거됨, 감사해요';

  @override
  String get settingsPurchaseThanks => '감사해요. 레벨 사이 광고가 꺼졌어요.';

  @override
  String get settingsPurchaseAlreadyOwned => '이미 구매했어요. 광고가 꺼져 있어요.';

  @override
  String get settingsPurchasePending => '결제 대기 중이에요. 결제가 완료되면 광고가 꺼져요.';

  @override
  String get settingsStoreUnavailable => '지금은 이 기기에서 스토어를 이용할 수 없어요.';

  @override
  String get settingsPurchaseFailed => '구매가 완료되지 않았어요. 요금은 청구되지 않았어요.';

  @override
  String get settingsStoreOpenFailed => '스토어를 열 수 없어요.';

  @override
  String get settingsBrowserOpenFailed => '브라우저를 열 수 없어요.';

  @override
  String get settingsSignedIn => '로그인됨';

  @override
  String get settingsSignedInDetail => '진행 상황이 함께 움직여요';

  @override
  String get settingsSaveProgressTitle => '진행 상황 저장';

  @override
  String get settingsSaveProgressDetail => '휴대폰을 바꿔도 별을 지켜요';

  @override
  String get settingsPrivacyPolicy => '개인정보처리방침';

  @override
  String get settingsTermsAndLicenses => '약관 및 라이선스';

  @override
  String get settingsTermsOfUse => '이용약관';

  @override
  String get settingsRefundPolicy => '환불 정책';

  @override
  String get settingsOpenSourceLicenses => '오픈소스 라이선스';

  @override
  String get settingsAdPrivacyTitle => '광고 개인정보 옵션';

  @override
  String get settingsAdPrivacyDetail => '광고 관련 동의 내용 변경';

  @override
  String get settingsResetRowTitle => '진행 상황 초기화';

  @override
  String get settingsResetRowDetail => '모든 별을 지우고 레벨 1부터 시작';

  @override
  String get settingsResetTitle => '진행 상황을 초기화할까요?';

  @override
  String get settingsResetNothing => '아직 초기화할 기록이 없어요.';

  @override
  String settingsResetBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '클리어한 레벨 $count개의 별과 최고 기록이 모두 지워지고, 레벨 1 이후가 다시 잠겨요. 되돌릴 수 없어요.',
    );
    return '$_temp0';
  }

  @override
  String get settingsKeepIt => '그대로 두기';

  @override
  String get settingsResetConfirm => '모두 지우기';

  @override
  String get settingsResetDone => '진행 상황을 초기화했어요.';

  @override
  String get settingsSignOutTitle => '로그아웃할까요?';

  @override
  String get settingsSignOutBody =>
      '진행 상황은 이 휴대폰에 남아요. 언제든 다시 로그인하면 다른 기기에서 이어서 할 수 있어요.';

  @override
  String get settingsSignOutStay => '로그인 유지';

  @override
  String get settingsSignOutConfirm => '로그아웃';

  @override
  String get settingsServerUnreachable => '서버에 연결할 수 없어서 바뀐 건 없어요.';

  @override
  String get settingsDeleteRowTitle => '계정 삭제';

  @override
  String get settingsDeleteRowDetail => '계정과 모든 데이터를 삭제';

  @override
  String get settingsDeleteTitle => '계정을 삭제할까요?';

  @override
  String get settingsDeleteBody =>
      '계정, 별, 연속 기록, 순위표 기록이 이 휴대폰과 서버에서 모두 삭제돼요. 되돌릴 수 없어요.\n\n광고 제거는 영향을 받지 않아요. 구매한 스토어 계정에 속해 있어서, 다시 플레이하면 복원돼요.';

  @override
  String get settingsDeleteConfirm => '모두 삭제';

  @override
  String get settingsDeleteServerRefused =>
      '서버에 연결할 수 없어요. 아무것도 삭제되지 않았어요. 다시 온라인이 되면 시도해 주세요.';

  @override
  String get settingsDeleteNotAuthenticated =>
      '본인 확인을 할 수 없어요. 다시 로그인한 뒤 계정을 삭제해 주세요. 아직 아무것도 삭제되지 않았어요.';

  @override
  String settingsFooterVersion(String version) {
    return 'Pourfect $version';
  }

  @override
  String settingsFooterVersionBoards(int count, String version) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Pourfect $version · 풀 수 있음이 증명된 보드 $count개',
    );
    return '$_temp0';
  }

  @override
  String get settingsNamingYou => '이름 짓는 중…';

  @override
  String get settingsYourName => '내 이름';

  @override
  String get settingsGuest => '게스트로 플레이 중';

  @override
  String get settingsStatSolved => '클리어';

  @override
  String get settingsStatStars => '별';

  @override
  String get settingsNotifyTurnOnTitle => '알림 켜기';

  @override
  String get settingsNotifyDeniedDetail => '휴대폰 설정에서 꺼져 있어요. 탭해서 열어요.';

  @override
  String get settingsNotifyNotYetDetail => '아직 Pourfect가 알림을 보낼 수 없어요';

  @override
  String get settingsRemindersTitle => '오늘의 퍼즐 알림';

  @override
  String get settingsRemindersDetail => '아침과 저녁, 하루 두 번을 넘지 않아요';

  @override
  String get settingsNewsTitle => '게임 소식';

  @override
  String get settingsNewsDetail => '새 월드와 공지';

  @override
  String settingsToggleOn(String title) {
    return '$title, 켜짐';
  }

  @override
  String settingsToggleOff(String title) {
    return '$title, 꺼짐';
  }

  @override
  String get settingsFaqSectionPlaying => '플레이';

  @override
  String get settingsFaqSectionStuck => '막혔나요?';

  @override
  String get settingsFaqSectionProgress => '진행 상황';

  @override
  String get settingsFaqSectionAds => '광고 및 소리';

  @override
  String get settingsFaqHowToPlayQ => '어떻게 플레이하나요?';

  @override
  String get settingsFaqHowToPlayA =>
      '튜브를 탭해 맨 위의 공을 집고, 다른 튜브를 탭해 따르세요. 공은 같은 색 위나 빈 튜브에만 들어가요. 모든 튜브를 한 가지 색으로 정렬하면 레벨 클리어예요. 설정 → 플레이 방법에서 안내가 있는 첫 레벨을 다시 할 수 있어요.';

  @override
  String get settingsFaqStarsQ => '별은 무엇을 뜻하나요?';

  @override
  String get settingsFaqStarsA =>
      '별은 오직 이동 수로만 정해져요. 파 이하로 끝내면 별 3개, 파의 1.5배 이내면 별 2개, 어떻게든 끝내면 별 1개예요. 파는 그 레벨을 풀 수 있는 최소 이동 수예요.';

  @override
  String get settingsFaqClockQ => '시간 때문에 별이 깎이나요?';

  @override
  String get settingsFaqClockA =>
      '절대 아니에요. 시간은 점수에만 영향을 줘요. 기준 시간보다 빠르면 보너스 점수를 받고, 천천히 해도 별은 모두 그대로예요.';

  @override
  String get settingsFaqSolvableQ => '모든 레벨을 풀 수 있나요?';

  @override
  String get settingsFaqSolvableA =>
      '네. 모든 보드는 출시 전에 풀어 봤고, 파는 그 풀이에서 나와요. 그래서 언제나 달성할 수 있어요.';

  @override
  String get settingsFaqDailyQ => '오늘의 퍼즐은 무엇인가요?';

  @override
  String get settingsFaqDailyA =>
      '매일 나오는 새 보드로, 전용 순위표가 있어요. 인터넷 연결이 필요해요. 캠페인 레벨은 필요 없어요.';

  @override
  String get settingsFaqUndoQ => '되돌리기에 제한이 있나요?';

  @override
  String get settingsFaqUndoA => '아니요. 되돌리기는 모든 레벨에서 무료이고 무제한이에요.';

  @override
  String get settingsFaqHintsQ => '힌트는 어떻게 쓰나요?';

  @override
  String settingsFaqHintsA(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '처음 $count번의 힌트는 무료예요. 그다음부터는 짧은 영상을 보면 하나씩 받아요. 힌트를 찾지 못해도 본 영상은 다음 힌트에 쓰여요.',
      one: '첫 힌트는 무료예요. 그다음부터는 짧은 영상을 보면 하나씩 받아요. 힌트를 찾지 못해도 본 영상은 다음 힌트에 쓰여요.',
    );
    return '$_temp0';
  }

  @override
  String get settingsFaqTubeQ => '+ 튜브 버튼은 무엇인가요?';

  @override
  String get settingsFaqTubeA =>
      '이동 수가 파에 닿거나 힌트로 끝낼 방법이 없다고 나오면, 영상을 보고 빈 튜브를 하나 더 받을 수 있어요. 한 번 도전에 최대 두 개까지예요. 되돌리기를 해도 사라지지 않아요. 추가 튜브로 클리어하면 별은 최대 2개예요.';

  @override
  String get settingsFaqHardQ => '하드 레벨은 무엇인가요?';

  @override
  String get settingsFaqHardA =>
      '10레벨마다 가장 어려운 레벨에 빨간 하드 배지가 붙어요. 플레이는 다른 레벨과 같고, 점수는 1.5배예요.';

  @override
  String get settingsFaqChestsQ => '별 상자는 무엇인가요?';

  @override
  String get settingsFaqChestsA =>
      '별 30개마다 여정에서 상자가 하나 열려요. 힌트 두 개와 추가 튜브 하나가 들어 있고, 필요할 때 쓰도록 보관돼요. 세 번째 상자마다 공 스킨도 하나 열려요.';

  @override
  String get settingsFaqFreezeQ => '연속 보호권은 무엇인가요?';

  @override
  String get settingsFaqFreezeA =>
      '오늘의 퍼즐을 하루 놓쳐도 보호권이 그날을 지켜 줘서 연속 기록이 이어져요. 매주 월요일 하나씩 무료로 받고, 영상을 보면 하루에 하나 받을 수 있으며, 최대 두 개까지 가질 수 있어요.';

  @override
  String get settingsFaqAccountQ => '계정이 꼭 필요한가요?';

  @override
  String get settingsFaqAccountA =>
      '아니요. 게스트로 플레이하고 진행 상황은 이 휴대폰에 저장돼요. 로그인하면 새 휴대폰으로 옮겨도 별이 그대로 남아요.';

  @override
  String get settingsFaqOfflineQ => '오프라인으로 플레이할 수 있나요?';

  @override
  String get settingsFaqOfflineA =>
      '네, 캠페인 전체를 할 수 있어요. 오늘의 퍼즐과 순위표는 연결이 필요하고, 진행 상황은 다시 온라인이 되면 동기화돼요.';

  @override
  String get settingsFaqNameQ => '순위표 이름은 어떻게 바꾸나요?';

  @override
  String get settingsFaqNameA =>
      '설정 → 이름 바꾸기에서 바꿀 수 있어요. 거기서 순위표에서 나를 숨길 수도 있고, 별은 그대로 쌓여요.';

  @override
  String get settingsFaqRemoveAdsQ => '광고 제거는 무엇을 해 주나요?';

  @override
  String get settingsFaqRemoveAdsA =>
      '레벨 사이 광고를 꺼 줘요. 힌트와 튜브 영상은 남아 있어요. 직접 요청할 때만 보이기 때문이에요.';

  @override
  String get settingsFaqReinstallQ => '다시 설치했어요. 광고 제거는 어디 갔나요?';

  @override
  String get settingsFaqReinstallA =>
      '광고 제거는 구매한 스토어 계정에 속해 있어서 보통 자동으로 돌아와요. 그렇지 않다면 설정 → 구매 복원을 탭하세요.';

  @override
  String get settingsFaqMusicQ => '게임이 내 음악을 멈추나요?';

  @override
  String get settingsFaqMusicA =>
      '아니요. Pourfect는 음악이나 팟캐스트와 함께 소리를 내요. 소리와 진동은 설정에서 끌 수 있어요.';

  @override
  String get settingsLegalTitle => '따르기 전에';

  @override
  String get settingsLegalIntro =>
      'Pourfect는 무료이고, 오프라인에서도 되며, 계정이 필요 없어요. 먼저 아래 내용을 읽고 동의해 주세요.';

  @override
  String settingsLegalAcceptTerms(String document) {
    return '$document에 동의해요';
  }

  @override
  String settingsLegalReadPrivacy(String document) {
    return '$document을 읽었어요';
  }

  @override
  String settingsLegalAlsoCovers(String document, String version) {
    return '동의하면 $document(버전 $version)에도 동의하게 돼요.';
  }

  @override
  String get settingsLegalPrivacyPolicy => '개인정보처리방침';

  @override
  String get settingsLegalTermsOfService => '서비스 약관';

  @override
  String get settingsLegalRefundPolicy => '환불 정책';

  @override
  String settingsLegalReadDocument(String document) {
    return '$document 읽기';
  }

  @override
  String get settingsLegalAccept => '시작해요!';

  @override
  String get settingsLegalReadAgain => '설정에서 언제든 다시 읽을 수 있어요.';

  @override
  String get settingsLegalLoadFailed =>
      '이 기기에서 문서를 불러올 수 없어요.\n\n동의하기 전에 legal.pranta.dev에서 읽을 수 있어요.';

  @override
  String get settingsUpdateTitle => '새 Pourfect가 준비됐어요';

  @override
  String get settingsUpdateBody =>
      'Google Play가 업데이트를 내려받고, 끝나면 게임을 다시 열어요. 별은 안전해요.';

  @override
  String get settingsUpdateMandatoryTitle => '업데이트할 시간이에요';

  @override
  String get settingsUpdateMandatoryBody =>
      '이 버전의 Pourfect는 더 이상 지원되지 않아요. Google Play가 업데이트를 내려받고 게임을 다시 열어요. 별은 안전해요.';

  @override
  String get settingsUpdateNow => '지금 업데이트';

  @override
  String get settingsRenameHello => '안녕하세요';

  @override
  String get settingsRenameMyNameIs => '제 이름은';

  @override
  String get settingsRenameHint => '다른 플레이어에게 순위표에서 보이는 이름이에요';

  @override
  String get settingsRenameSave => '저장';

  @override
  String settingsCollectionUnlockWith(String how) {
    return '잠금 해제 방법: $how.';
  }

  @override
  String get settingsCollectionChangeFailed => '지금은 바꿀 수 없어요. 나중에 다시 시도해 주세요.';

  @override
  String get settingsPackThanks => '감사해요! 팩이 곧 열려요.';

  @override
  String get settingsPackAlreadyOwned => '이미 가지고 있어요. 지금 복원할게요.';

  @override
  String get settingsPackPending => '결제 대기 중이에요. 결제가 완료되면 팩이 열려요.';

  @override
  String get settingsCollectionOffline => '컬렉션을 보려면 인터넷에 연결하세요.';

  @override
  String get settingsCollectionBallSkins => '공 스킨';

  @override
  String get settingsCollectionTubeThemes => '튜브 테마';

  @override
  String settingsCollectionPreview(String skin, String theme) {
    return '$skin 공 · $theme 튜브';
  }

  @override
  String settingsCollectionItemWorn(String name) {
    return '$name, 사용 중';
  }

  @override
  String settingsCollectionItemTapToWear(String name) {
    return '$name, 탭해서 사용';
  }

  @override
  String settingsCollectionItemLocked(String name, String how) {
    return '$name, 잠김: $how';
  }

  @override
  String get settingsCollectionWearing => '사용 중';

  @override
  String get settingsCollectionTapToWear => '탭해서 사용';

  @override
  String settingsUnlockChest(int number) {
    return '별 상자 $number';
  }

  @override
  String settingsUnlockStreak(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days일 연속',
    );
    return '$_temp0';
  }

  @override
  String get settingsUnlockFree => '무료';

  @override
  String get settingsSkinPack => '스킨 팩';

  @override
  String get settingsSkinPackDetail => '마블, 진주, 체커 공과 나무, 라일락 튜브.';

  @override
  String get settingsOwned => '보유';

  @override
  String get settingsSoon => '곧 출시';

  @override
  String get settingsSkinClassic => '클래식';

  @override
  String get settingsSkinGlossy => '반짝반짝';

  @override
  String get settingsSkinStriped => '캔디 줄무늬';

  @override
  String get settingsSkinGlow => '글로우';

  @override
  String get settingsSkinSpeckled => '스프링클';

  @override
  String get settingsSkinMarble => '마블';

  @override
  String get settingsSkinPearl => '진주';

  @override
  String get settingsSkinChecker => '체커';

  @override
  String get settingsTubeToy => '장난감';

  @override
  String get settingsTubeFrost => '서리';

  @override
  String get settingsTubeWood => '나무';

  @override
  String get settingsTubeLilac => '라일락';
}

// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get accountGoogleFailed => '这台手机无法完成 Google 登录。请重试，或使用下方的邮箱登录。';

  @override
  String get accountAppleFailed =>
      '这台手机无法完成 Apple 登录。请检查是否已在“设置”中登录 Apple 账户，或使用下方的邮箱登录。';

  @override
  String get accountExistsNoLocal => '这个邮箱已经有账号了。登录后，这台手机会载入账号里保存的星星。';

  @override
  String accountExistsWithLocal(int solved) {
    String _temp0 = intl.Intl.pluralLogic(
      solved,
      locale: localeName,
      other: '这个邮箱已经有账号了。这台手机上有 $solved 个已通关的关卡不在该账号中，两者无法合并——登录后将被该账号中的内容替换。',
    );
    return '$_temp0';
  }

  @override
  String get accountEmailInUse => '这个邮箱已经注册过账号了，试试直接登录吧。';

  @override
  String get accountEmailMalformed => '这看起来不像邮箱地址。';

  @override
  String get accountPasswordWeak => '这个密码太容易被猜到了，换个长一点的吧。';

  @override
  String get accountWrongPassword => '邮箱和密码不匹配。';

  @override
  String get accountTooManyAttempts => '尝试次数过多，请等几分钟再试。';

  @override
  String get accountNeedsRecentLogin => '请先重新登录。';

  @override
  String get accountMethodNotEnabled => '邮箱登录暂时不可用。试试“使用 Google 账号继续”。';

  @override
  String get accountSessionUnavailable => '已登录，但进度还没保存到服务器。网络恢复后会自动同步。';

  @override
  String get accountUnavailable => '无法连接服务器。你的进度仍安全地保存在这台设备上。';

  @override
  String get accountUseThatAccount => '使用该账号';

  @override
  String get accountExistingTitle => '你已经有账号了';

  @override
  String get accountExistingBodyEmpty => '这台手机会载入该账号里已保存的星星。';

  @override
  String accountExistingBodyLocal(int cleared) {
    String _temp0 = intl.Intl.pluralLogic(
      cleared,
      locale: localeName,
      other: '这台手机上有 $cleared 个已通关的关卡不在该账号中。两者无法合并，它们将被该账号已有的内容替换。',
    );
    return '$_temp0';
  }

  @override
  String get accountSignIn => '登录';

  @override
  String get accountSignInCancelled => '已取消登录，一切未变。';

  @override
  String get accountSignedInToast => '已登录。换新手机，星星也会跟着你。';

  @override
  String get accountResetNeedsEmail => '请先输入邮箱，再点“忘记密码？”。';

  @override
  String get accountResetSent => '如果该邮箱有账号，重置链接已在路上。';

  @override
  String get accountYourAccount => '我的账号';

  @override
  String accountRankValue(int rank) {
    return '#$rank';
  }

  @override
  String accountStreakValue(int days) {
    return '$days天';
  }

  @override
  String get accountCardTravels => '这张卡片跟随你的账号，换了新手机也能从上次的地方继续。';

  @override
  String get accountYourNameHeader => '你的名字';

  @override
  String get accountChangeName => '修改名字';

  @override
  String get accountChangeNameDetail => '你在排行榜上的显示名';

  @override
  String get accountShowOnBoards => '在排行榜上显示我';

  @override
  String get accountShowOnBoardsDetail => '关闭后隐藏名字和排名，星星照常计算。';

  @override
  String get accountYourPlayHeader => '你的游戏';

  @override
  String get accountStatistics => '统计';

  @override
  String get accountStatisticsDetail => '你的用时、活跃度和每一关';

  @override
  String get accountSessionHeader => '会话';

  @override
  String get accountDeleteHint => '如需删除账号，请前往“设置”→“危险区域”。';

  @override
  String get accountVisibilityFailed => '无法连接服务器，设置未更改。';

  @override
  String get accountSignOutTitle => '要退出登录吗？';

  @override
  String get accountSignOutBody => '你的进度会保留在这台手机上。随时可以重新登录，在别的设备上继续。';

  @override
  String get accountStaySignedIn => '保持登录';

  @override
  String get accountSignOut => '退出登录';

  @override
  String get accountSignOutDetail => '你的进度会保留在这台手机上';

  @override
  String get accountSaveTitle => '保存你的进度';

  @override
  String get accountSaveIntro => '你的星星、连续天数和排行榜名字都跟随账号，换了新手机也能从上次的地方继续。';

  @override
  String get accountContinueApple => '通过 Apple 继续';

  @override
  String get accountContinueGoogle => '使用 Google 账号继续';

  @override
  String get accountOr => '或';

  @override
  String get accountEmailLabel => '邮箱';

  @override
  String get accountEmailEmpty => '请输入邮箱。';

  @override
  String get accountPasswordLabel => '密码';

  @override
  String get accountPasswordHelper => '至少 8 个字符';

  @override
  String get accountPasswordEmpty => '请输入密码。';

  @override
  String get accountPasswordShort => '至少 8 个字符。';

  @override
  String get accountShowPassword => '显示密码';

  @override
  String get accountHidePassword => '隐藏密码';

  @override
  String get accountCreate => '创建账号';

  @override
  String get accountSwitchToSignIn => '已有账号？登录';

  @override
  String get accountSwitchToSignInSemantic => '改为登录';

  @override
  String get accountSwitchToCreate => '还没有账号？创建一个';

  @override
  String get accountSwitchToCreateSemantic => '改为创建账号';

  @override
  String get accountForgotPassword => '忘记密码？';

  @override
  String get accountForgotPasswordSemantic => '重置密码';

  @override
  String get accountNaming => '正在起名…';

  @override
  String get accountSignedInLabel => '已登录';

  @override
  String accountPouringSince(String month, int year) {
    return '$year年$month起开始倒球';
  }

  @override
  String get accountPlayerCardTag => '玩家卡';

  @override
  String get accountStatSolved => '通关';

  @override
  String get accountStatStars => '星星';

  @override
  String get accountStatStreak => '连续';

  @override
  String get accountStatRank => '排名';

  @override
  String accountStarsValue(int stars) {
    return '$stars★';
  }

  @override
  String get accountSyncing => '同步中…';

  @override
  String get accountSyncingDetail => '正在把进度保存到账号';

  @override
  String get accountWaitingToSync => '等待同步';

  @override
  String get accountWaitingOffline => '联网后自动保存';

  @override
  String get accountWaitingPending => '最新的关卡即将上传';

  @override
  String get accountSyncedDetail => '进度已保存到账号';

  @override
  String get accountSynced => '已同步';

  @override
  String get accountSyncedJustNow => '刚刚已同步';

  @override
  String accountSyncedMinutesAgo(int minutes) {
    return '$minutes分钟前已同步';
  }

  @override
  String accountSyncedHoursAgo(int hours) {
    return '$hours小时前已同步';
  }

  @override
  String accountSyncedDaysAgo(int days) {
    return '$days天前已同步';
  }

  @override
  String get accountCrestSignedIn => '我的账号';

  @override
  String get accountCrestGuest => '以游客身份游玩';

  @override
  String get accountRenameRefused => '这个名字未被接受。';

  @override
  String get accountRenameOffline => '无法连接服务器，请稍后再试。';

  @override
  String get ranksTitle => '排行榜';

  @override
  String get ranksTabToday => '今日';

  @override
  String get ranksTabCampaign => '闯关';

  @override
  String get ranksLoading => '正在获取排行榜…';

  @override
  String get ranksEmptyDailyTitle => '今天还没有人完成';

  @override
  String get ranksEmptyDailyDetail => '来做第一个吧。';

  @override
  String get ranksEmptyCampaignTitle => '还没有上榜玩家';

  @override
  String get ranksEmptyCampaignDetail => '这里按星星排名。';

  @override
  String get ranksYourSpot => '你的位置';

  @override
  String ranksPlayerCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '本榜共 $countString 位玩家',
    );
    return '$_temp0';
  }

  @override
  String ranksMoves(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 步',
    );
    return '$_temp0';
  }

  @override
  String ranksStars(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 颗星',
    );
    return '$_temp0';
  }

  @override
  String ranksLevels(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 关',
    );
    return '$_temp0';
  }

  @override
  String ranksInTime(String time) {
    return '用时 $time';
  }

  @override
  String get ranksOpenSpot => '虚位以待';

  @override
  String ranksNameYou(String name) {
    return '$name（你）';
  }

  @override
  String ranksPlaceOpen(int place) {
    return '第 $place 名，空缺';
  }

  @override
  String ranksPlaceSemantic(int rank, String name, String score) {
    return '第 $rank 名，$name，$score';
  }

  @override
  String ranksScoreWithTieBreak(String score, String tieBreak) {
    return '$score，$tieBreak';
  }

  @override
  String get ranksOffTitle => '此版本未开启排行榜';

  @override
  String get ranksOffDetail => '闯关模式不受影响。';

  @override
  String get ranksLoadFailed => '无法加载排行榜';

  @override
  String get ranksOffline => '你好像离线了。所有关卡无需联网也能玩。';

  @override
  String get ranksTimeout => '服务器响应超时。';

  @override
  String get ranksServerError => '我们这边出了点问题。你的进度是安全的。';

  @override
  String get ranksHiddenTitle => '你已隐藏';

  @override
  String get ranksHiddenDetail => '你的星星和连续天数照常计算——只是不在这里显示。开关在“设置”里。';

  @override
  String get statsTitle => '我的统计';

  @override
  String get statsTabOverview => '概览';

  @override
  String get statsTabLevels => '关卡';

  @override
  String get statsTabBadges => '徽章';

  @override
  String get statsPaceOnPar => '持平';

  @override
  String statsPaceUnder(int percent) {
    return '快 $percent%';
  }

  @override
  String statsPaceOver(int percent) {
    return '慢 $percent%';
  }

  @override
  String get statsEmptyTitle => '暂无数据';

  @override
  String get statsEmptyBody => '通关一关后，这里就会填满：你与标准用时的对比、最佳成绩，以及你玩过的日子。';

  @override
  String get statsBackToLevels => '返回关卡';

  @override
  String get statsLevelsSolved => '已通关';

  @override
  String get statsStars => '星星';

  @override
  String get statsPoints => '积分';

  @override
  String get statsPlayed => '游戏时长';

  @override
  String get statsNowOn => '当前进度';

  @override
  String get statsBestSolveMoves => '最佳成绩总步数';

  @override
  String get statsAgainstClock => '计时挑战';

  @override
  String get statsNoTimes => '还没有用时记录。计时功能上线前通关的关卡没有用时——重玩一关就会开始计时。';

  @override
  String get statsFastest => '最快';

  @override
  String get statsLongest => '最慢';

  @override
  String get statsAvgPace => '平均节奏';

  @override
  String statsClockValue(String time, int level) {
    return '$time · 第$level关';
  }

  @override
  String statsUntimed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '你有 $count 个已通关的关卡是在计时功能上线前完成的，没有用时记录。',
    );
    return '$_temp0';
  }

  @override
  String statsUnderParSemantic(int under, int total) {
    return '$total 个计时关卡中有 $under 个快于标准';
  }

  @override
  String get statsUnderParTag => '快于标准';

  @override
  String get statsLast30Days => '最近 30 天';

  @override
  String statsStreakChip(int count) {
    return '连续 $count 天';
  }

  @override
  String get statsNoStreak => '未连续';

  @override
  String statsDaysPlayed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '玩了 $count 天',
    );
    return '$_temp0';
  }

  @override
  String statsLevelsFinished(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '完成 $count 关',
    );
    return '$_temp0';
  }

  @override
  String statsBestStreak(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '最长 $count 天',
    );
    return '$_temp0';
  }

  @override
  String get statsToday => '今天';

  @override
  String statsMonthShort(String month) {
    String _temp0 = intl.Intl.selectLogic(month, {
      'jan': '1月',
      'feb': '2月',
      'mar': '3月',
      'apr': '4月',
      'may': '5月',
      'jun': '6月',
      'jul': '7月',
      'aug': '8月',
      'sep': '9月',
      'oct': '10月',
      'nov': '11月',
      'dec': '12月',
      'other': '$month',
    });
    return '$_temp0';
  }

  @override
  String statsMonthDay(String month, int day) {
    return '$month$day日';
  }

  @override
  String statsBarLevels(String day, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$day · $count 关',
    );
    return '$_temp0';
  }

  @override
  String statsBarNoPlay(String day) {
    return '$day · 未游玩';
  }

  @override
  String get statsWorldAhead => '未开始';

  @override
  String get statsWorldNoTimes => '无用时';

  @override
  String statsWorldPoints(int points) {
    final intl.NumberFormat pointsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String pointsString = pointsNumberFormat.format(points);

    return '$pointsString 分';
  }

  @override
  String statsWorldSolvedSemantic(String name, int cleared, int total) {
    return '$name：已通关 $cleared/$total';
  }

  @override
  String statsWorldPaceSemantic(String pace) {
    return '节奏 $pace';
  }

  @override
  String statsWorldPointsSemantic(int points) {
    final intl.NumberFormat pointsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String pointsString = pointsNumberFormat.format(points);

    return '$pointsString 积分';
  }

  @override
  String get statsColLevel => '关卡';

  @override
  String get statsColStars => '星星';

  @override
  String get statsColMoves => '步数';

  @override
  String get statsColTime => '用时';

  @override
  String get statsColPoints => '积分';

  @override
  String statsMovesBestPossible(int moves, int best) {
    return '$moves 步，最少 $best 步';
  }

  @override
  String statsMoves(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 步',
    );
    return '$_temp0';
  }

  @override
  String badgeUnlockedCount(int earned, int total) {
    return '已解锁 $earned/$total';
  }

  @override
  String get badgeUnlocked => '已解锁';

  @override
  String get badgeNotYet => '未达成';

  @override
  String badgeProgress(int shown, int target) {
    return '$shown/$target';
  }

  @override
  String badgeSemantic(String title, String description, String status) {
    return '$title：$description $status';
  }

  @override
  String get badgeFirstPourTitle => '初次倾倒';

  @override
  String get badgeFirstPourDesc => '通关你的第一关。';

  @override
  String get badgePar10Title => '恰好标准';

  @override
  String get badgePar10Desc => '以恰好标准步数通关 10 关。';

  @override
  String get badgePar50Title => '标准大师';

  @override
  String get badgePar50Desc => '以恰好标准步数通关 50 关。';

  @override
  String get badgeCleanClearTitle => '落子无悔';

  @override
  String get badgeCleanClearDesc => '不使用撤销通关一关。';

  @override
  String get badgeSpeedyTitle => '快手';

  @override
  String get badgeSpeedyDesc => '在 30 秒内通关一关。';

  @override
  String get badgeLevels100Title => '百关达人';

  @override
  String get badgeLevels100Desc => '通关 100 关。';

  @override
  String get badgeStars300Title => '集星狂人';

  @override
  String get badgeStars300Desc => '收集 300 颗星。';

  @override
  String get badgeWorldPerfectTitle => '完美世界';

  @override
  String get badgeWorldPerfectDesc => '一个世界的每一关都拿到三星。';

  @override
  String get badgeStreak7Title => '一周不断';

  @override
  String get badgeStreak7Desc => '“每日一题”连续完成 7 天。';

  @override
  String get badgeStreak30Title => '一月不断';

  @override
  String get badgeStreak30Desc => '“每日一题”连续完成 30 天。';

  @override
  String get badgeChests5Title => '寻宝人';

  @override
  String get badgeChests5Desc => '打开 5 个星星宝箱。';

  @override
  String get badgeHard5Title => '硬骨头';

  @override
  String get badgeHard5Desc => '通关 5 个“困难”关卡。';

  @override
  String get badgeEventFullTitle => '全勤一周';

  @override
  String get badgeEventFullDesc => '通关每周活动的全部七个关卡。';

  @override
  String get badgeZen25Title => '禅意花园';

  @override
  String get badgeZen25Desc => '在 Zen 模式中完成 25 局。';

  @override
  String get commonCancel => '取消';

  @override
  String get commonClose => '关闭';

  @override
  String get commonBack => '返回';

  @override
  String get commonOk => '好';

  @override
  String get commonSave => '保存';

  @override
  String get commonRetry => '重试';

  @override
  String get commonNotNow => '以后再说';

  @override
  String commonLevelN(int level) {
    return '第 $level 关';
  }

  @override
  String get hubAccountYours => '我的账号';

  @override
  String get hubAccountSave => '保存你的进度';

  @override
  String get hubPlayerFallback => '玩家';

  @override
  String get hubSettings => '设置';

  @override
  String get hubTagline => '倾倒 · 排序 · 放松';

  @override
  String hubStatChipSemantic(String value, String label) {
    return '$label $value。统计';
  }

  @override
  String get hubStatSolved => '通关';

  @override
  String get hubStatStars => '星星';

  @override
  String get hubStatStreak => '连续';

  @override
  String hubStreakDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 天',
    );
    return '$_temp0';
  }

  @override
  String hubRankNumber(int rank) {
    return '#$rank';
  }

  @override
  String hubEventSemantic(int cleared, int total) {
    return '每周活动，$cleared/$total 关';
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
  String get hubZenSemantic => 'Zen 模式';

  @override
  String hubZenLockedSemantic(int level) {
    return 'Zen 模式在第 $level 关解锁';
  }

  @override
  String get hubZenOpen => '无尽模式，不计时';

  @override
  String hubZenLocked(int level, int remaining) {
    return '第 $level 关 · 还差 $remaining 关';
  }

  @override
  String get hubDockJourney => '旅程';

  @override
  String get hubDockRankings => '排行';

  @override
  String get hubDockStats => '统计';

  @override
  String get hubTip => '真棒！“旅程”里有全部关卡，每天还有新的“每日一题”等你来玩。';

  @override
  String hubHeroWorld(int world) {
    return '世界 $world';
  }

  @override
  String hubHeroWorldBand(int world, String band) {
    return '世界 $world · $band';
  }

  @override
  String hubHeroPar(int par) {
    return '标准 $par';
  }

  @override
  String get hubPlay => '开始';

  @override
  String hubPlaySemantic(int level) {
    return '开始第 $level 关';
  }

  @override
  String get hubMoreUpdateTitle => '更新以获取更多关卡';

  @override
  String get hubMoreUpdateBody => '新世界已上线，需要最新版 Pourfect。更新游戏，继续倒吧。';

  @override
  String get hubMoreDownloadingTitle => '新关卡即将到来';

  @override
  String get hubMoreDownloadingBody => '下一个世界正在下载，马上就好。';

  @override
  String get hubMoreAllDoneTitle => '全部倒完啦！';

  @override
  String get hubMoreOfflineBody => '连上网络后，更多关卡会在后台下载。在此期间，今天的“每日一题”正等着你。';

  @override
  String get hubMoreOnlineBody => '只要联网，更多关卡就会在后台下载。在此期间，今天的“每日一题”正等着你。';

  @override
  String get hubMoreCheckAgain => '再检查一次';

  @override
  String hubAchievementOne(String title) {
    return '成就解锁：$title';
  }

  @override
  String hubAchievementMany(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '解锁了 $count 个成就！',
    );
    return '$_temp0';
  }

  @override
  String get hubUpdateReady => '更新已就绪，可以安装了。';

  @override
  String get hubUpdateRestart => '重启';

  @override
  String hubSpanSeconds(int seconds) {
    return '$seconds秒';
  }

  @override
  String hubSpanMinutes(int minutes) {
    return '$minutes分';
  }

  @override
  String hubSpanMinutesSeconds(int minutes, int seconds) {
    return '$minutes分$seconds秒';
  }

  @override
  String hubSpanHours(int hours) {
    return '$hours小时';
  }

  @override
  String hubSpanHoursMinutes(int hours, int minutes) {
    return '$hours小时$minutes分';
  }

  @override
  String get hubParOn => '与标准持平';

  @override
  String hubParUnder(int percent) {
    return '比标准快 $percent%';
  }

  @override
  String hubParOver(int percent) {
    return '比标准慢 $percent%';
  }

  @override
  String get dailyTitle => '每日一题';

  @override
  String get dailyCardSemantic => '今日挑战';

  @override
  String get dailyCardUnavailable => '无法获取今天的题目';

  @override
  String get dailyCardSolved => '已完成';

  @override
  String dailyCardNextIn(String time) {
    return '$time 后更新';
  }

  @override
  String dailyCardEndsIn(String time) {
    return '$time 后结束';
  }

  @override
  String dailyStreakDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '连续 $count 天',
    );
    return '$_temp0';
  }

  @override
  String dailyStreakMilestone(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '连续 $count 天！',
    );
    return '$_temp0';
  }

  @override
  String get dailyRankSemantic => '排行榜';

  @override
  String dailyRankSemanticRanked(int rank) {
    return '排行榜，第 $rank 名';
  }

  @override
  String get dailyRankSticker => '排名';

  @override
  String get dailyLeaveLost => '今天“每日一题”的步数不会保存。今天内随时可以重新开始。';

  @override
  String get dailySubmitRefused => '服务器未接受这个成绩。';

  @override
  String get dailySubmitFailed => '已完成——但成绩没能发送，请稍后再试。';

  @override
  String get dailyHudLabel => '每日';

  @override
  String get dailyHudValue => '一题';

  @override
  String get dailyDeadEndRestart => '从这里无法完成了。重新开始，换个思路试试。';

  @override
  String dailyDeadEndUndo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '从这里无法完成了。撤销 $count 步即可回到正轨。',
    );
    return '$_temp0';
  }

  @override
  String get dailyActionRestart => '重新开始';

  @override
  String dailyActionUndo(int count) {
    return '撤销 $count 步';
  }

  @override
  String get dailyNoHint => '当前局面没有提示。';

  @override
  String get dailyLoadingTitle => '正在加载今天的题目';

  @override
  String get dailyOffTitle => '此版本未开启每日挑战';

  @override
  String get dailyOffDetail => '闯关模式不受影响——所有关卡都在这台设备上。';

  @override
  String get dailyNoBoardTitle => '今天没有题目';

  @override
  String get dailyNoBoardDetail => '今日挑战来自服务器，但目前无法连接。闯关模式不需要联网。';

  @override
  String get dailyLoaderCaption => '正在倒出今天的题目…';

  @override
  String get dailyBackToLevels => '返回关卡';

  @override
  String dailyWeekSemantic(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 天',
    );
    return '你的连续天数：$_temp0。打开';
  }

  @override
  String dailyDaySemantic(String weekday, String state) {
    return '$weekday，$state';
  }

  @override
  String get dailyDayFrozen => '未玩，已用冻结保护';

  @override
  String get dailyDayPlayedToday => '今天已玩';

  @override
  String get dailyDayPlayed => '已玩';

  @override
  String get dailyDayToday => '今天，还没玩';

  @override
  String get dailyDayMissed => '未玩';

  @override
  String get dailyDayFuture => '尚未到来';

  @override
  String get dailyOutcomeBest => '新纪录';

  @override
  String get dailyOutcomeSolved => '完成';

  @override
  String get dailyFigureMoves => '步数';

  @override
  String get dailyFigureStreak => '连续';

  @override
  String get dailyUnranked => '未上榜';

  @override
  String dailyOfPlayers(int count) {
    return '共 $count 人';
  }

  @override
  String get dailyReminderOn => '明晚会提醒你一次。';

  @override
  String get dailyRemindMe => '明天提醒我';

  @override
  String get dailyDone => '完成';

  @override
  String get dailyFreezeVideoUnfinished => '视频没看完，未获得冻结。';

  @override
  String get dailyFreezeNoVideo => '暂时没有可播放的视频。';

  @override
  String get dailyFreezeError => '出了点问题，请稍后再试。';

  @override
  String get dailyFreezeAdded => '已添加冻结，可保护一天缺勤。';

  @override
  String get dailyFreezeNoRoom => '今天无法再添加冻结了。';

  @override
  String get dailyFreezeLoadingVideo => '正在加载视频…';

  @override
  String get dailyFreezeWatch => '看视频获得冻结';

  @override
  String get dailyFreezesFull => '冻结已满。每个可保护你错过的一天。';

  @override
  String get dailyFreezeTomorrow => '每天可通过视频获得一个冻结。明天再来吧。';

  @override
  String get dailyStreakTitle => '你的连续天数';

  @override
  String get dailyStreakNone => '还没有连续记录';

  @override
  String get dailyStreakStart => '玩一次今天的“每日一题”就能开始。';

  @override
  String dailyStreakBest(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '最长：$count 天',
    );
    return '$_temp0';
  }

  @override
  String dailyFreezesSemantic(int count, int max) {
    return '连续冻结 $count/$max';
  }

  @override
  String get dailyFreezesTitle => '连续冻结';

  @override
  String get dailyFreezesEach => '每个可保护错过的一天。';

  @override
  String dailyFreezeWeekly(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '每周一免费送一个，还有 $days 天。',
      one: '每周一免费送一个，就在明天。',
    );
    return '$_temp0';
  }

  @override
  String get dailyCalendarPrevious => '上个月';

  @override
  String get dailyCalendarNext => '下个月';

  @override
  String dailyCalendarCellSemantic(String date, String state) {
    return '$date，$state';
  }

  @override
  String get dailyCalendarPlayed => '已玩';

  @override
  String get dailyCalendarFrozen => '已冻结';

  @override
  String get dailyCalendarFuture => '未到';

  @override
  String get dailyLegendPlayed => '已玩';

  @override
  String get dailyLegendFrozen => '冻结';

  @override
  String get dailyLegendToday => '今天';

  @override
  String get eventTitle => '每周活动';

  @override
  String get eventUnreachable => '暂时无法获取本周活动。';

  @override
  String get eventEnded => '已结束';

  @override
  String eventEndsIn(String timeLeft) {
    return '$timeLeft 后结束';
  }

  @override
  String eventTimeLeftDaysHours(int days, int hours) {
    return '$days天$hours小时';
  }

  @override
  String eventTimeLeftHours(int hours) {
    return '$hours小时';
  }

  @override
  String eventTimeLeftMinutes(int minutes) {
    return '$minutes分钟';
  }

  @override
  String eventSummary(int cleared, int total, String endsIn) {
    return '$cleared/$total 关 · $endsIn';
  }

  @override
  String get eventFigurePoints => '积分';

  @override
  String eventRankOf(int count) {
    return '共 $count 人';
  }

  @override
  String get eventRankPlay => '玩一关即可上榜';

  @override
  String get eventRankSetName => '设置名字即可上榜';

  @override
  String eventTileSemanticDone(int slot, int stars, int points) {
    String _temp0 = intl.Intl.pluralLogic(
      stars,
      locale: localeName,
      other: '$stars 颗星',
    );
    return '第 $slot 关，$_temp0，$points 积分';
  }

  @override
  String eventTileSemanticNew(int slot) {
    return '第 $slot 关，未玩';
  }

  @override
  String eventTilePoints(int points) {
    return '$points分';
  }

  @override
  String get eventStandingsTitle => '本周排行';

  @override
  String get eventStandingsEmpty => '榜上还没有人，来做第一个吧。';

  @override
  String eventStandingsCleared(int cleared) {
    return ' · $cleared/7';
  }

  @override
  String get eventSubmitRefused => '服务器未接受这个成绩——活动可能已经结束。';

  @override
  String get eventSubmitFailed => '已完成——但成绩没能发送，请重试。';

  @override
  String eventDeadEndUndo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '从这里无法完成了。撤销 $count 步。',
    );
    return '$_temp0';
  }

  @override
  String get eventNoHint => '当前局面暂时没有提示。';

  @override
  String get eventHudLabel => '关卡';

  @override
  String eventHudBand(String event, String endsIn) {
    return '$event · $endsIn';
  }

  @override
  String get eventSending => '发送中…';

  @override
  String eventResult(int points, int total) {
    return '$points 积分 · 本周 $total';
  }

  @override
  String eventResultRanked(int points, int total, int rank) {
    return '$points 积分 · 本周 $total · #$rank';
  }

  @override
  String get journeyTitle => '旅程';

  @override
  String journeyStarsSemantic(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 颗星',
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
    return '世界 $world/$worlds，$name，已通关 $solved/$total';
  }

  @override
  String journeyWorldOf(int world, int worlds) {
    return '世界 $world/$worlds';
  }

  @override
  String journeyRibbonSemantic(int world, String name, int solved, int total) {
    return '世界 $world，$name，已通关 $solved/$total。滚动到这里';
  }

  @override
  String journeyRibbonLabel(int world, String name) {
    return '世界 $world · $name';
  }

  @override
  String get journeyYouPin => '你';

  @override
  String journeyBandCaps(int world, int count) {
    return '世界 $world · $count';
  }

  @override
  String get journeyBandFirstPours => '初试身手';

  @override
  String get journeyBandFindingRhythm => '渐入佳境';

  @override
  String get journeyBandDeepWater => '深水区';

  @override
  String get journeyBandMastery => '大师之境';

  @override
  String get notifSoftAskTitle => '需要提醒吗？';

  @override
  String get notifSoftAskBody =>
      '今天的“每日一题”上线或下一关在等你时，给你提个醒。每天最多两条，随时可以在“设置”中关闭。';

  @override
  String get notifSoftAskBodyDenied =>
      'Pourfect 的通知已关闭。在手机设置中开启后，“每日一题”上线或新世界到来时会提醒你。每天最多两条。';

  @override
  String get notifSoftAskOpenSettings => '打开设置';

  @override
  String get notifSoftAskYes => '好的';

  @override
  String get notifChannelName => '提醒';

  @override
  String get notifChannelDescription => '“每日一题”、你的下一关和新世界。每天最多两条。';

  @override
  String get playHudLevel => '关卡';

  @override
  String playHudTitle(String label, String value) {
    return '$label $value';
  }

  @override
  String get playHudHard => '困难 ×1.5';

  @override
  String get playHudHardLabel => '困难关卡，积分为 1.5 倍';

  @override
  String get playHudMoves => '步数';

  @override
  String playHudMovesLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 步',
    );
    return '$_temp0';
  }

  @override
  String playParLeftFor3Stars(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '还剩 $count 步可得 3 星',
    );
    return '$_temp0';
  }

  @override
  String get playParSpent => '标准步数已用完 · 最多 2 星';

  @override
  String playParLeftFor2Stars(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '还剩 $count 步可得 2 星',
    );
    return '$_temp0';
  }

  @override
  String get playParOneStarFromHere => '现在起 1 星 · 完成即可';

  @override
  String get playParAnyFinish => '完成即得 1 星';

  @override
  String playParMeterLabel(int stars, int used, int par, String words) {
    return '$stars 星节奏，已用 $used 步，标准 $par 步。$words';
  }

  @override
  String playHudBusyLabel(String label) {
    return '$label，处理中。点按取消';
  }

  @override
  String get playHudUndo => '撤销';

  @override
  String get playHudHint => '提示';

  @override
  String get playHudRestart => '重来';

  @override
  String get playExtraTubeLabel => '看视频获得一根额外的管子';

  @override
  String get playExtraTubeChip => '+ 管子';

  @override
  String playStarsOfTotal(int earned, int total) {
    return '$earned/$total 颗星';
  }

  @override
  String get playDismiss => '关闭';

  @override
  String get playLeaveTitleSoSoon => '这就走啦？';

  @override
  String get playLeaveTitleMissYou => '小球们会想你的';

  @override
  String get playLeaveTitleAbandon => '不倒了吗？';

  @override
  String get playLeaveTitleMidPour => '倒到一半就走？';

  @override
  String get playLeaveBody => '这一关的步数和用时不会保存。';

  @override
  String get playLeaveKeepPouring => '继续倒';

  @override
  String get playLeaveConfirm => '离开';

  @override
  String get playTutorialSkipLabel => '跳过教程';

  @override
  String get playTutorialSkip => '跳过';

  @override
  String playTipBubbleLabel(String text) {
    return '$text。关闭';
  }

  @override
  String get playTipPar => '在标准步数内完成可得三星。进度条显示你已用了多少。';

  @override
  String get playTipTallTubes => '管子变高了！现在每根能装五个球。';

  @override
  String get playTipHint => '卡住了？“提示”会告诉你一步好棋。';

  @override
  String get playTipUndo => '超过标准步数了？撤销是免费的——想退多少步都行。';

  @override
  String get playGuideSorted => '排好了！现在让每根管子都只有一种颜色。';

  @override
  String get playGuideDrop => '现在点要倒入的地方：同色的球上，或空管子。';

  @override
  String get playGuideWrongTube => '点小手指着的管子，改为拿起那里的球。';

  @override
  String get playGuideFirstTap => '点一根管子，拿起最上面的球。';

  @override
  String get playGuideFirstPour => '倒好了！继续吧。';

  @override
  String get playGuideKeepGoing => '继续：每根管子一种颜色。';

  @override
  String playCoachHolding(int count) {
    return '拿着 $count 个 · 倒进跳动的管子';
  }

  @override
  String get playExtraTubeAdTitle => '看视频获得一根额外的管子？';

  @override
  String get playExtraTubeAdBody => '本关多一根空管子。使用额外管子通关最多可得两星。';

  @override
  String get playExtraTubeNotFinished => '视频没看完，未获得管子。';

  @override
  String get playExtraTubeSaved => '已保存——下一根管子免费。';

  @override
  String get playNoVideo => '暂时没有可播放的视频。';

  @override
  String get playRewardFailed => '出了点问题，没有消耗任何东西。';

  @override
  String get playHintShowing => '提示已显示：倒进发光的管子。';

  @override
  String get playHintNoneNothingUsed => '当前局面没有提示，没有消耗任何东西。';

  @override
  String get playHintNotFinished => '视频没看完，未获得提示。';

  @override
  String get playHintVideoSaved => '你的视频已保留，可用于下一次提示。';

  @override
  String get playHintNoneVideoSaved => '当前局面没有提示——你的视频已保留，可用于下一次。';

  @override
  String get playHintNone => '当前局面没有可用的提示。';

  @override
  String get playHintHere => '这是你的提示——倒进发光的管子。';

  @override
  String get playDeadEndRestart => '从这里无法完成了。重来一次，换个思路试试。';

  @override
  String get playDeadEndRestartTube => '从这里无法完成了。重来一次，换个思路试试。或点“+ 管子”获得一根备用管子。';

  @override
  String playDeadEndUndo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '从这里无法完成了。撤销 $count 步即可回到正轨。',
    );
    return '$_temp0';
  }

  @override
  String playDeadEndUndoTube(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '从这里无法完成了。撤销 $count 步即可回到正轨。或点“+ 管子”获得一根备用管子。',
    );
    return '$_temp0';
  }

  @override
  String playDeadEndUndoAction(int count) {
    return '撤销 $count 步';
  }

  @override
  String get playHintAdTitle => '看视频获得提示？';

  @override
  String playHintAdFreeLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '你还有 $count 次免费提示。',
    );
    return '$_temp0';
  }

  @override
  String get playHintAdNoneLeft => '免费提示已用完。看个短视频再得一次。';

  @override
  String get playWatch => '观看';

  @override
  String get playLoadFailed => '无法加载关卡';

  @override
  String get playTubeSorted => '排好了！';

  @override
  String get playWinTitlePerfect => '完美\n倾倒！';

  @override
  String get playWinTitleNice => '漂亮\n倾倒！';

  @override
  String get playWinTitlePoured => '倒完啦！';

  @override
  String get playWinLastPour => '最后一倒…';

  @override
  String playWinMovesPar(int count, int par) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 步 · 标准 $par',
    );
    return '$_temp0';
  }

  @override
  String playWinLevelBand(int level, String band) {
    return '第 $level 关 · $band';
  }

  @override
  String get playWinNewBest => '新纪录！';

  @override
  String playWinMovesChip(int par) {
    return '步数 · 标准 $par';
  }

  @override
  String get playWinUntimed => '未计时';

  @override
  String get playWinFastest => '最快纪录！';

  @override
  String get playWinTime => '用时';

  @override
  String get playWinUnderPar => '快于标准！';

  @override
  String get playWinPoints => '积分';

  @override
  String playWinWorldBand(int world, String band) {
    return '世界 $world · $band';
  }

  @override
  String get playWinTryAssisted => '不用额外管子通关才能拿三星。';

  @override
  String playWinTryShort(int par, int took, int short) {
    String _temp0 = intl.Intl.pluralLogic(
      short,
      locale: localeName,
      other: '标准 $par 步，你用了 $took 步。差 $short 步拿 3★。',
      one: '标准 $par 步，你用了 $took 步。差 1 步拿 3★。',
    );
    return '$_temp0';
  }

  @override
  String playWinTryInReach(int par) {
    return '标准 $par 步。三星触手可及。';
  }

  @override
  String get playWinTryButton => '挑战 3★';

  @override
  String get playWinTryButtonLabel => '重玩本关，挑战三星';

  @override
  String get playWinReplayLabel => '重玩本关';

  @override
  String get playWinHomeLabel => '返回主界面';

  @override
  String get playWinNextLevel => '下一关';

  @override
  String get playWinBackToLevels => '返回关卡';

  @override
  String playChestNextAtLabel(int stars) {
    return '$stars 颗星时开启下一个星星宝箱';
  }

  @override
  String get playChestOpenLabel => '打开星星宝箱';

  @override
  String get playChestReady => '星星宝箱可以打开了！';

  @override
  String playChestNextAt(int stars) {
    return '下个宝箱：$stars ★';
  }

  @override
  String get playChestOpen => '打开';

  @override
  String get playChestDoubleFailed => '这次没能翻倍。';

  @override
  String get playChestDoubleNotFinished => '视频没看完，未翻倍。';

  @override
  String get playChestOpening => '正在打开…';

  @override
  String playChestTitle(int index) {
    return '星星宝箱 $index';
  }

  @override
  String get playChestNotYetTitle => '就差一点';

  @override
  String get playChestAlreadyOpenTitle => '已打开';

  @override
  String get playChestFailedTitle => '没能打开';

  @override
  String get playChestNotYetNote => '你最新的星星还在传往服务器的路上，请稍后再试。';

  @override
  String get playChestAlreadyOpenNote => '这个宝箱已在另一台设备上打开。';

  @override
  String get playChestFailedNote => '请检查网络连接后重试。';

  @override
  String playChestRewardCount(int count) {
    return '+$count';
  }

  @override
  String playChestHintsCaption(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '提示',
    );
    return '$_temp0';
  }

  @override
  String playChestTubesCaption(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '额外管子',
    );
    return '$_temp0';
  }

  @override
  String playChestUnlocked(String name) {
    return '已解锁：$name';
  }

  @override
  String playChestBallSkinName(String skin) {
    return '$skin小球皮肤';
  }

  @override
  String playChestTubeThemeName(String theme) {
    return '$theme管子';
  }

  @override
  String get playChestNewLook => '新外观';

  @override
  String get playChestSavedNote => '已存好备用。“提示”和“+ 管子”会优先使用它们。';

  @override
  String get playChestLoadingVideo => '正在加载视频…';

  @override
  String get playChestDouble => '看视频翻倍';

  @override
  String get playChestCollect => '收下';

  @override
  String playClockLabel(String time) {
    return '用时 $time';
  }

  @override
  String playClockDetailLabel(
    String time,
    String par,
    String sign,
    int percent,
  ) {
    String _temp0 = intl.Intl.selectLogic(sign, {'plus': '加', 'other': '减'});
    return '用时 $time，标准 $par，积分$_temp0 $percent%';
  }

  @override
  String playClockBonusChip(String sign, int percent) {
    return '积分 $sign$percent%';
  }

  @override
  String get playLoading => '加载中';

  @override
  String get playWorking => '处理中';

  @override
  String get playZenTitle => 'Zen';

  @override
  String get playZenIntro => '无尽关卡。不计时，没有星星，没有排行榜——尽情倒吧。';

  @override
  String get playZenPaceCalm => '悠闲';

  @override
  String get playZenPaceSteady => '沉稳';

  @override
  String get playZenPaceDeep => '深邃';

  @override
  String playZenPaceColors(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 种颜色',
    );
    return '$_temp0';
  }

  @override
  String playZenPaceLabel(String pace, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$pace，$count 种颜色',
    );
    return '$_temp0';
  }

  @override
  String playZenBandPoured(String pace, int count) {
    return '$pace · 已倒完 $count 局';
  }

  @override
  String playZenPoured(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '倒完啦！已完成 $count 局。',
      one: '倒完啦！',
    );
    return '$_temp0';
  }

  @override
  String get playZenNext => '下一局';

  @override
  String get playZenLeaveBody => '这一局的步数不会保存，已完成的局数会保留。';

  @override
  String get playZenDeadEnd => '从这里无法完成了。撤销或重来吧。';

  @override
  String get playZenNoHint => '当前局面暂时没有提示。';

  @override
  String get settingsTitle => '设置';

  @override
  String get settingsSectionFeel => '手感';

  @override
  String get settingsSectionVisibility => '辨识度';

  @override
  String get settingsSectionLeaderboard => '排行榜';

  @override
  String get settingsSectionNotifications => '通知';

  @override
  String get settingsSectionSupport => '支持';

  @override
  String get settingsSectionAccount => '账号与关于';

  @override
  String get settingsSectionDanger => '危险区域';

  @override
  String get settingsSoundTitle => '音效';

  @override
  String get settingsSoundDetail => '倾倒、按钮和奖励';

  @override
  String get settingsSoundVolume => '音效音量';

  @override
  String get settingsMusicTitle => '音乐';

  @override
  String get settingsMusicDetail => '绝不打断你自己的音乐';

  @override
  String get settingsMusicVolume => '音乐音量';

  @override
  String get settingsHapticsTitle => '振动反馈';

  @override
  String get settingsHapticsDetail => '每个球落下时轻轻一震';

  @override
  String get settingsSmoothMotionTitle => '流畅动画';

  @override
  String get settingsSmoothMotionAuto => '自动';

  @override
  String get settingsSmoothMotion60 => '60 Hz';

  @override
  String get settingsSmoothMotionMax => '最高';

  @override
  String get settingsMotionUnknown => '若手机跟得上，“自动”会使用屏幕的最高刷新率';

  @override
  String settingsMotionFixed(String max) {
    return '此屏幕只支持 $max Hz';
  }

  @override
  String settingsMotionBatterySaver(String current) {
    return '省电模式将其限制在 $current Hz';
  }

  @override
  String settingsMotionAutoStuttered(String current, String max) {
    return '当前 $current Hz · 此手机在 $max Hz 时卡顿';
  }

  @override
  String settingsMotionAuto(String current) {
    return '当前 $current Hz · 卡顿时降至 60 Hz';
  }

  @override
  String settingsMotionPinnedByPhone(String current) {
    return '手机的显示设置将其固定在 $current Hz';
  }

  @override
  String settingsMotionStandard(String current, String max) {
    return '当前 $current Hz · 此屏幕最高支持 $max Hz';
  }

  @override
  String settingsMotionMax(String current) {
    return '当前 $current Hz，已是此屏幕的最高刷新率';
  }

  @override
  String get settingsBoldSymbolsTitle => '加粗符号';

  @override
  String get settingsBoldSymbolsDetail => '更醒目的图形，适合色盲和色弱玩家';

  @override
  String get settingsRenameTitle => '修改名字';

  @override
  String get settingsRenameDetail => '你在排行榜上的显示名';

  @override
  String get settingsShowOnBoardsTitle => '在排行榜上显示我';

  @override
  String get settingsShowOnBoardsDetail => '关闭后隐藏名字和排名，星星照常计算。';

  @override
  String get settingsHowToPlayTitle => '玩法说明';

  @override
  String get settingsHowToPlayDetail => '重玩带引导的第一关';

  @override
  String get settingsQuestionsTitle => '常见问题';

  @override
  String get settingsQuestionsDetail => '星星、提示、计时等';

  @override
  String get settingsRateTitle => '给 Pourfect 评分';

  @override
  String get settingsRateDetail => '告诉其他玩家你的想法';

  @override
  String get settingsCollectionTitle => '收藏馆';

  @override
  String get settingsCollectionDetail => '小球皮肤和管子主题';

  @override
  String get settingsRestoreTitle => '恢复购买';

  @override
  String get settingsRestoreDetail => '去除广告或皮肤礼包';

  @override
  String get settingsRestoreDone => '已恢复购买（如有）。';

  @override
  String get settingsRemoveAdsTitle => '去除广告';

  @override
  String get settingsRemoveAdsDetail => '关卡之间不再有广告，提示视频保留。';

  @override
  String get settingsAdsRemoved => '广告已去除——谢谢你';

  @override
  String get settingsPurchaseThanks => '谢谢！关卡之间的广告已关闭。';

  @override
  String get settingsPurchaseAlreadyOwned => '已购买——广告已关闭。';

  @override
  String get settingsPurchasePending => '付款处理中，完成后广告即会关闭。';

  @override
  String get settingsStoreUnavailable => '此设备暂时无法使用应用商店。';

  @override
  String get settingsPurchaseFailed => '购买未成功，你没有被扣款。';

  @override
  String get settingsStoreOpenFailed => '无法打开应用商店。';

  @override
  String get settingsBrowserOpenFailed => '无法打开浏览器。';

  @override
  String get settingsSignedIn => '已登录';

  @override
  String get settingsSignedInDetail => '你的进度随你而行';

  @override
  String get settingsSaveProgressTitle => '保存你的进度';

  @override
  String get settingsSaveProgressDetail => '换手机也能保留星星';

  @override
  String get settingsPrivacyPolicy => '隐私政策';

  @override
  String get settingsTermsAndLicenses => '条款与许可';

  @override
  String get settingsTermsOfUse => '使用条款';

  @override
  String get settingsRefundPolicy => '退款政策';

  @override
  String get settingsOpenSourceLicenses => '开源许可';

  @override
  String get settingsAdPrivacyTitle => '广告隐私选项';

  @override
  String get settingsAdPrivacyDetail => '更改你对广告的授权';

  @override
  String get settingsResetRowTitle => '重置进度';

  @override
  String get settingsResetRowDetail => '清除所有星星，从第 1 关重新开始';

  @override
  String get settingsResetTitle => '要重置进度吗？';

  @override
  String get settingsResetNothing => '目前还没有可重置的内容。';

  @override
  String settingsResetBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '这将清除 $count 个已通关关卡的所有星星和最佳成绩，并重新锁定第 1 关之后的所有关卡。此操作无法撤销。',
    );
    return '$_temp0';
  }

  @override
  String get settingsKeepIt => '保留';

  @override
  String get settingsResetConfirm => '全部清除';

  @override
  String get settingsResetDone => '进度已重置。';

  @override
  String get settingsSignOutTitle => '要退出登录吗？';

  @override
  String get settingsSignOutBody => '你的进度会保留在这台手机上。随时可以重新登录，在别的设备上继续。';

  @override
  String get settingsSignOutStay => '保持登录';

  @override
  String get settingsSignOutConfirm => '退出登录';

  @override
  String get settingsServerUnreachable => '无法连接服务器，设置未更改。';

  @override
  String get settingsDeleteRowTitle => '删除账号';

  @override
  String get settingsDeleteRowDetail => '删除你的账号及所有相关数据';

  @override
  String get settingsDeleteTitle => '要删除你的账号吗？';

  @override
  String get settingsDeleteBody =>
      '这将删除你的账号、星星、连续天数和排行榜记录，包括这台手机上和我们服务器上的数据。此操作无法撤销。\n\n“去除广告”不受影响——它属于你购买时使用的商店账号，再次游玩时会自动恢复。';

  @override
  String get settingsDeleteConfirm => '全部删除';

  @override
  String get settingsDeleteServerRefused => '无法连接服务器，没有删除任何内容——请在联网后重试。';

  @override
  String get settingsDeleteNotAuthenticated =>
      '无法确认是你本人。请重新登录后再删除账号——目前还没有删除任何内容。';

  @override
  String settingsFooterVersion(String version) {
    return 'Pourfect $version';
  }

  @override
  String settingsFooterVersionBoards(int count, String version) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Pourfect $version · 内含 $count 个已验证可解的关卡',
    );
    return '$_temp0';
  }

  @override
  String get settingsNamingYou => '正在起名…';

  @override
  String get settingsYourName => '你的名字';

  @override
  String get settingsGuest => '以游客身份游玩';

  @override
  String get settingsStatSolved => '通关';

  @override
  String get settingsStatStars => '星星';

  @override
  String get settingsNotifyTurnOnTitle => '开启通知';

  @override
  String get settingsNotifyDeniedDetail => '已在手机设置中关闭，点按前往开启。';

  @override
  String get settingsNotifyNotYetDetail => 'Pourfect 还不能给你发通知';

  @override
  String get settingsRemindersTitle => '“每日一题”提醒';

  @override
  String get settingsRemindersDetail => '早晚各一次，每天最多两条';

  @override
  String get settingsNewsTitle => '游戏动态';

  @override
  String get settingsNewsDetail => '新世界和公告';

  @override
  String settingsToggleOn(String title) {
    return '$title，已开启';
  }

  @override
  String settingsToggleOff(String title) {
    return '$title，已关闭';
  }

  @override
  String get settingsFaqSectionPlaying => '游戏玩法';

  @override
  String get settingsFaqSectionStuck => '卡住了？';

  @override
  String get settingsFaqSectionProgress => '你的进度';

  @override
  String get settingsFaqSectionAds => '广告与声音';

  @override
  String get settingsFaqHowToPlayQ => '怎么玩？';

  @override
  String get settingsFaqHowToPlayA =>
      '点一根管子拿起最上面的球，再点另一根管子把球倒进去。球只能落在同色的球上或空管子里。让每根管子都只有一种颜色，就过关了。“设置”→“玩法说明”可以重玩带引导的第一关。';

  @override
  String get settingsFaqStarsQ => '星星代表什么？';

  @override
  String get settingsFaqStarsA =>
      '星星只看步数。在标准步数内完成得三星，在标准步数的 1.5 倍以内完成得两星，只要完成就得一星。标准步数是这一关最少的通关步数。';

  @override
  String get settingsFaqClockQ => '计时会让我丢星吗？';

  @override
  String get settingsFaqClockA => '绝不会。时间只影响积分。快于标准用时可获得额外积分；慢慢来也没关系，星星一颗不少。';

  @override
  String get settingsFaqSolvableQ => '每一关都有解吗？';

  @override
  String get settingsFaqSolvableA => '是的。每一关在上线前都已被解出，标准步数正是来自那个解法，所以一定能达到。';

  @override
  String get settingsFaqDailyQ => '什么是“每日一题”？';

  @override
  String get settingsFaqDailyA => '每天一道新题，有专属排行榜。需要联网，闯关关卡则不需要。';

  @override
  String get settingsFaqUndoQ => '撤销有次数限制吗？';

  @override
  String get settingsFaqUndoA => '没有。每一关的撤销都免费且不限次数。';

  @override
  String get settingsFaqHintsQ => '提示怎么用？';

  @override
  String settingsFaqHintsA(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '前 $count 次提示免费。之后看一个短视频可获得一次。如果找不到提示，这个视频仍会留给下一次。',
    );
    return '$_temp0';
  }

  @override
  String get settingsFaqTubeQ => '“+ 管子”按钮是什么？';

  @override
  String get settingsFaqTubeA =>
      '当你的步数达到标准，或提示显示已无法完成时，可以看视频获得一根额外的空管子，每次挑战最多两根。撤销不会把它收走。使用额外管子通关最多可得两星。';

  @override
  String get settingsFaqHardQ => '什么是“困难”关卡？';

  @override
  String get settingsFaqHardA => '每十关中最难的一关会带有红色的“困难”标记。它和其他关卡玩法一样，但积分为 1.5 倍。';

  @override
  String get settingsFaqChestsQ => '什么是星星宝箱？';

  @override
  String get settingsFaqChestsA =>
      '在“旅程”中每攒够 30 颗星就能打开一个宝箱：两次提示和一根额外管子，存起来备用。每第三个宝箱还会解锁一款小球皮肤。';

  @override
  String get settingsFaqFreezeQ => '什么是连续冻结？';

  @override
  String get settingsFaqFreezeA =>
      '错过一天“每日一题”时，冻结会帮你补上，连续天数不会中断。每周一免费送一个，每天还可以通过视频获得一个，最多持有两个。';

  @override
  String get settingsFaqAccountQ => '需要注册账号吗？';

  @override
  String get settingsFaqAccountA => '不需要。你可以以游客身份游玩，进度保存在这台手机上。登录后，换新手机也能保留星星。';

  @override
  String get settingsFaqOfflineQ => '可以离线玩吗？';

  @override
  String get settingsFaqOfflineA => '可以，整个闯关模式都行。“每日一题”和排行榜需要联网，你的进度会在重新联网后同步。';

  @override
  String get settingsFaqNameQ => '怎么修改排行榜上的名字？';

  @override
  String get settingsFaqNameA => '“设置”→“修改名字”。你也可以在那里把自己从排行榜上隐藏，星星照常计算。';

  @override
  String get settingsFaqRemoveAdsQ => '“去除广告”有什么用？';

  @override
  String get settingsFaqRemoveAdsA => '它会关闭关卡之间的广告。提示和管子的视频会保留，因为只有你主动要求时才会看到。';

  @override
  String get settingsFaqReinstallQ => '我重装了游戏，“去除广告”去哪了？';

  @override
  String get settingsFaqReinstallA =>
      '它属于你购买时使用的商店账号，通常会自动恢复。如果没有，请点“设置”→“恢复购买”。';

  @override
  String get settingsFaqMusicQ => '游戏会打断我的音乐吗？';

  @override
  String get settingsFaqMusicA =>
      '不会。Pourfect 的声音会和你的音乐或播客同时播放。音效和振动反馈可以在“设置”中关闭。';

  @override
  String get settingsLegalTitle => '开始之前';

  @override
  String get settingsLegalIntro => 'Pourfect 免费、可离线游玩，也不需要账号。请先阅读并接受以下内容。';

  @override
  String settingsLegalAcceptTerms(String document) {
    return '我接受$document';
  }

  @override
  String settingsLegalReadPrivacy(String document) {
    return '我已阅读$document';
  }

  @override
  String settingsLegalAlsoCovers(String document, String version) {
    return '接受即表示同时同意我们的$document（版本 $version）。';
  }

  @override
  String get settingsLegalPrivacyPolicy => '隐私政策';

  @override
  String get settingsLegalTermsOfService => '服务条款';

  @override
  String get settingsLegalRefundPolicy => '退款政策';

  @override
  String settingsLegalReadDocument(String document) {
    return '阅读$document';
  }

  @override
  String get settingsLegalAccept => '开始倒吧！';

  @override
  String get settingsLegalReadAgain => '你随时可以在“设置”中再次阅读。';

  @override
  String get settingsLegalLoadFailed =>
      '此设备无法加载该文件。\n\n接受前，你可以在 legal.pranta.dev 阅读。';

  @override
  String get settingsUpdateTitle => '新版 Pourfect 已就绪';

  @override
  String get settingsUpdateBody => 'Google Play 会下载更新，完成后重新打开游戏。你的星星是安全的。';

  @override
  String get settingsUpdateMandatoryTitle => '该更新了';

  @override
  String get settingsUpdateMandatoryBody =>
      '此版本的 Pourfect 已不再受支持。Google Play 会下载更新并重新打开游戏。你的星星是安全的。';

  @override
  String get settingsUpdateNow => '立即更新';

  @override
  String get settingsRenameHello => '你好';

  @override
  String get settingsRenameMyNameIs => '我的名字是';

  @override
  String get settingsRenameHint => '其他玩家会在排行榜上看到这个名字';

  @override
  String get settingsRenameSave => '保存';

  @override
  String settingsCollectionUnlockWith(String how) {
    return '解锁方式：$how。';
  }

  @override
  String get settingsCollectionChangeFailed => '暂时无法更换，请稍后再试。';

  @override
  String get settingsPackThanks => '谢谢！礼包马上就会解锁。';

  @override
  String get settingsPackAlreadyOwned => '你已拥有，正在恢复。';

  @override
  String get settingsPackPending => '付款处理中，完成后礼包即会解锁。';

  @override
  String get settingsCollectionOffline => '连接网络后即可查看你的收藏。';

  @override
  String get settingsCollectionBallSkins => '小球皮肤';

  @override
  String get settingsCollectionTubeThemes => '管子主题';

  @override
  String settingsCollectionPreview(String skin, String theme) {
    return '$skin小球 · $theme管子';
  }

  @override
  String settingsCollectionItemWorn(String name) {
    return '$name，使用中';
  }

  @override
  String settingsCollectionItemTapToWear(String name) {
    return '$name，点按使用';
  }

  @override
  String settingsCollectionItemLocked(String name, String how) {
    return '$name，未解锁：$how';
  }

  @override
  String get settingsCollectionWearing => '使用中';

  @override
  String get settingsCollectionTapToWear => '点按使用';

  @override
  String settingsUnlockChest(int number) {
    return '星星宝箱 $number';
  }

  @override
  String settingsUnlockStreak(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '连续 $days 天',
    );
    return '$_temp0';
  }

  @override
  String get settingsUnlockFree => '免费';

  @override
  String get settingsSkinPack => '皮肤礼包';

  @override
  String get settingsSkinPackDetail => '大理石、珍珠、棋盘格小球，木纹、丁香紫管子。';

  @override
  String get settingsOwned => '已拥有';

  @override
  String get settingsSoon => '即将推出';

  @override
  String get settingsSkinClassic => '经典';

  @override
  String get settingsSkinGlossy => '亮光';

  @override
  String get settingsSkinStriped => '糖果条纹';

  @override
  String get settingsSkinGlow => '荧光';

  @override
  String get settingsSkinSpeckled => '彩糖';

  @override
  String get settingsSkinMarble => '大理石';

  @override
  String get settingsSkinPearl => '珍珠';

  @override
  String get settingsSkinChecker => '棋盘格';

  @override
  String get settingsTubeToy => '玩具';

  @override
  String get settingsTubeFrost => '磨砂';

  @override
  String get settingsTubeWood => '木纹';

  @override
  String get settingsTubeLilac => '丁香紫';
}

/// The translations for Chinese, using the Han script (`zh_Hant`).
class AppLocalizationsZhHant extends AppLocalizationsZh {
  AppLocalizationsZhHant() : super('zh_Hant');

  @override
  String get accountGoogleFailed => '這支手機無法使用 Google 登入。請再試一次，或改用下方的電子郵件。';

  @override
  String get accountAppleFailed =>
      '這支手機無法使用 Apple 登入。請確認已在「設定」中登入 Apple 帳號，或改用下方的電子郵件。';

  @override
  String get accountExistsNoLocal => '這個電子郵件已經有帳號了。登入後，這支手機會載入該帳號儲存的星星。';

  @override
  String accountExistsWithLocal(int solved) {
    String _temp0 = intl.Intl.pluralLogic(
      solved,
      locale: localeName,
      other: '這個電子郵件已經有帳號了。這支手機有 $solved 個已過關的關卡不在該帳號中，兩者無法合併——登入後會改為該帳號的內容。',
    );
    return '$_temp0';
  }

  @override
  String get accountEmailInUse => '這個電子郵件已經有帳號了，請改為登入。';

  @override
  String get accountEmailMalformed => '這看起來不像電子郵件地址。';

  @override
  String get accountPasswordWeak => '這個密碼太容易被猜到了，換個長一點的吧。';

  @override
  String get accountWrongPassword => '電子郵件和密碼不相符。';

  @override
  String get accountTooManyAttempts => '嘗試次數太多了。請等幾分鐘再試。';

  @override
  String get accountNeedsRecentLogin => '請先重新登入。';

  @override
  String get accountMethodNotEnabled => '目前無法使用電子郵件登入。請試試「使用 Google 帳戶繼續」。';

  @override
  String get accountSessionUnavailable => '已登入，但進度還沒儲存到伺服器。連線恢復後就會同步。';

  @override
  String get accountUnavailable => '無法連上伺服器。你的進度仍安全地保存在這台裝置上。';

  @override
  String get accountUseThatAccount => '使用該帳號';

  @override
  String get accountExistingTitle => '你已經有帳號了';

  @override
  String get accountExistingBodyEmpty => '這支手機會載入該帳號已儲存的星星。';

  @override
  String accountExistingBodyLocal(int cleared) {
    String _temp0 = intl.Intl.pluralLogic(
      cleared,
      locale: localeName,
      other: '這支手機有 $cleared 個已過關的關卡不在該帳號中。兩者無法合併，因此會改為該帳號現有的內容。',
    );
    return '$_temp0';
  }

  @override
  String get accountSignIn => '登入';

  @override
  String get accountSignInCancelled => '已取消登入，沒有任何變更。';

  @override
  String get accountSignedInToast => '已登入。換新手機時，星星也會跟著你。';

  @override
  String get accountResetNeedsEmail => '請先輸入電子郵件，再點「忘記密碼？」。';

  @override
  String get accountResetSent => '如果這個電子郵件有帳號，重設連結已寄出。';

  @override
  String get accountYourAccount => '你的帳號';

  @override
  String accountRankValue(int rank) {
    return '#$rank';
  }

  @override
  String accountStreakValue(int days) {
    return '$days天';
  }

  @override
  String get accountCardTravels => '這張卡片跟著你的帳號走，換了新手機也能從上次的進度繼續。';

  @override
  String get accountYourNameHeader => '你的名字';

  @override
  String get accountChangeName => '更改名字';

  @override
  String get accountChangeNameDetail => '你在排行榜上的名字';

  @override
  String get accountShowOnBoards => '在排行榜上顯示我';

  @override
  String get accountShowOnBoardsDetail => '關閉會隱藏名字和排名，星星照樣計算。';

  @override
  String get accountYourPlayHeader => '你的遊戲';

  @override
  String get accountStatistics => '統計';

  @override
  String get accountStatisticsDetail => '你的時間、活動和每個關卡';

  @override
  String get accountSessionHeader => '登入狀態';

  @override
  String get accountDeleteHint => '若要刪除帳號，請前往「設定 → 危險區域」。';

  @override
  String get accountVisibilityFailed => '無法連上伺服器，所以沒有任何變更。';

  @override
  String get accountSignOutTitle => '要登出嗎？';

  @override
  String get accountSignOutBody => '你的進度會留在這支手機上。隨時可以重新登入，在其他地方繼續。';

  @override
  String get accountStaySignedIn => '保持登入';

  @override
  String get accountSignOut => '登出';

  @override
  String get accountSignOutDetail => '你的進度會留在這支手機上';

  @override
  String get accountSaveTitle => '儲存你的進度';

  @override
  String get accountSaveIntro => '你的星星、連續天數和排行榜名字都會跟著帳號走，換了新手機也能從上次的進度繼續。';

  @override
  String get accountContinueApple => '透過 Apple 繼續';

  @override
  String get accountContinueGoogle => '使用 Google 帳戶繼續';

  @override
  String get accountOr => '或';

  @override
  String get accountEmailLabel => '電子郵件';

  @override
  String get accountEmailEmpty => '請輸入電子郵件。';

  @override
  String get accountPasswordLabel => '密碼';

  @override
  String get accountPasswordHelper => '至少 8 個字元';

  @override
  String get accountPasswordEmpty => '請輸入密碼。';

  @override
  String get accountPasswordShort => '至少需要 8 個字元。';

  @override
  String get accountShowPassword => '顯示密碼';

  @override
  String get accountHidePassword => '隱藏密碼';

  @override
  String get accountCreate => '建立帳號';

  @override
  String get accountSwitchToSignIn => '已經有帳號了？登入';

  @override
  String get accountSwitchToSignInSemantic => '改為登入';

  @override
  String get accountSwitchToCreate => '還沒有帳號？建立一個';

  @override
  String get accountSwitchToCreateSemantic => '改為建立帳號';

  @override
  String get accountForgotPassword => '忘記密碼？';

  @override
  String get accountForgotPasswordSemantic => '重設密碼';

  @override
  String get accountNaming => '正在取名…';

  @override
  String get accountSignedInLabel => '已登入';

  @override
  String accountPouringSince(String month, int year) {
    return '$year 年 $month起開始倒球';
  }

  @override
  String get accountPlayerCardTag => '玩家卡';

  @override
  String get accountStatSolved => '已過關';

  @override
  String get accountStatStars => '星星';

  @override
  String get accountStatStreak => '連續';

  @override
  String get accountStatRank => '排名';

  @override
  String accountStarsValue(int stars) {
    return '$stars★';
  }

  @override
  String get accountSyncing => '同步中…';

  @override
  String get accountSyncingDetail => '正在將進度存到你的帳號';

  @override
  String get accountWaitingToSync => '等待同步';

  @override
  String get accountWaitingOffline => '恢復連線後就會儲存';

  @override
  String get accountWaitingPending => '最新的關卡即將上傳';

  @override
  String get accountSyncedDetail => '進度已存到你的帳號';

  @override
  String get accountSynced => '已同步';

  @override
  String get accountSyncedJustNow => '剛剛已同步';

  @override
  String accountSyncedMinutesAgo(int minutes) {
    return '$minutes 分鐘前已同步';
  }

  @override
  String accountSyncedHoursAgo(int hours) {
    return '$hours 小時前已同步';
  }

  @override
  String accountSyncedDaysAgo(int days) {
    return '$days 天前已同步';
  }

  @override
  String get accountCrestSignedIn => '你的帳號';

  @override
  String get accountCrestGuest => '以訪客身分遊玩';

  @override
  String get accountRenameRefused => '這個名字未被接受。';

  @override
  String get accountRenameOffline => '無法連上伺服器，請稍後再試。';

  @override
  String get ranksTitle => '排行榜';

  @override
  String get ranksTabToday => '今日';

  @override
  String get ranksTabCampaign => '主線';

  @override
  String get ranksLoading => '正在讀取排行榜…';

  @override
  String get ranksEmptyDailyTitle => '今天還沒有人完成題目';

  @override
  String get ranksEmptyDailyDetail => '搶當第一名吧。';

  @override
  String get ranksEmptyCampaignTitle => '還沒有上榜的玩家';

  @override
  String get ranksEmptyCampaignDetail => '這裡以星星數決勝負。';

  @override
  String get ranksYourSpot => '你的名次';

  @override
  String ranksPlayerCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '共 $countString 位玩家上榜',
    );
    return '$_temp0';
  }

  @override
  String ranksMoves(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 步',
    );
    return '$_temp0';
  }

  @override
  String ranksStars(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 顆星',
    );
    return '$_temp0';
  }

  @override
  String ranksLevels(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 關',
    );
    return '$_temp0';
  }

  @override
  String ranksInTime(String time) {
    return '用時 $time';
  }

  @override
  String get ranksOpenSpot => '虛位以待';

  @override
  String ranksNameYou(String name) {
    return '$name（你）';
  }

  @override
  String ranksPlaceOpen(int place) {
    return '第 $place 名，虛位以待';
  }

  @override
  String ranksPlaceSemantic(int rank, String name, String score) {
    return '第 $rank 名，$name，$score';
  }

  @override
  String ranksScoreWithTieBreak(String score, String tieBreak) {
    return '$score，$tieBreak';
  }

  @override
  String get ranksOffTitle => '這個版本未開放排行榜';

  @override
  String get ranksOffDetail => '主線關卡不受影響。';

  @override
  String get ranksLoadFailed => '無法載入排行榜';

  @override
  String get ranksOffline => '你好像離線了。所有關卡不需連線也能玩。';

  @override
  String get ranksTimeout => '伺服器回應太久了。';

  @override
  String get ranksServerError => '我們這邊出了點問題。你的進度很安全。';

  @override
  String get ranksHiddenTitle => '你已隱藏';

  @override
  String get ranksHiddenDetail => '你的星星和連續天數照樣計算——只是不會出現在這裡。開關在「設定」中。';

  @override
  String get statsTitle => '你的統計';

  @override
  String get statsTabOverview => '總覽';

  @override
  String get statsTabLevels => '關卡';

  @override
  String get statsTabBadges => '徽章';

  @override
  String get statsPaceOnPar => '持平';

  @override
  String statsPaceUnder(int percent) {
    return '快 $percent%';
  }

  @override
  String statsPaceOver(int percent) {
    return '慢 $percent%';
  }

  @override
  String get statsEmptyTitle => '還沒有資料';

  @override
  String get statsEmptyBody => '過一關後這裡就會出現：你與標準時間的比較、最佳成績，以及你遊玩的日子。';

  @override
  String get statsBackToLevels => '返回關卡';

  @override
  String get statsLevelsSolved => '已過關卡';

  @override
  String get statsStars => '星星';

  @override
  String get statsPoints => '分數';

  @override
  String get statsPlayed => '遊玩時間';

  @override
  String get statsNowOn => '目前進度';

  @override
  String get statsBestSolveMoves => '最佳成績總步數';

  @override
  String get statsAgainstClock => '挑戰時間';

  @override
  String get statsNoTimes => '還沒有時間紀錄。計時功能推出前過關的關卡沒有時間——重玩一次就會開始計時。';

  @override
  String get statsFastest => '最快';

  @override
  String get statsLongest => '最久';

  @override
  String get statsAvgPace => '平均節奏';

  @override
  String statsClockValue(String time, int level) {
    return '$time · 第$level關';
  }

  @override
  String statsUntimed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '你有 $count 個已過關卡是在計時功能推出前完成的，沒有時間紀錄。',
    );
    return '$_temp0';
  }

  @override
  String statsUnderParSemantic(int under, int total) {
    return '$total 個計時關卡中有 $under 個低於標準時間';
  }

  @override
  String get statsUnderParTag => '低於標準';

  @override
  String get statsLast30Days => '最近 30 天';

  @override
  String statsStreakChip(int count) {
    return '連續 $count 天';
  }

  @override
  String get statsNoStreak => '沒有連續紀錄';

  @override
  String statsDaysPlayed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '玩了 $count 天',
    );
    return '$_temp0';
  }

  @override
  String statsLevelsFinished(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '完成 $count 關',
    );
    return '$_temp0';
  }

  @override
  String statsBestStreak(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '最長 $count 天',
    );
    return '$_temp0';
  }

  @override
  String get statsToday => '今天';

  @override
  String statsMonthShort(String month) {
    String _temp0 = intl.Intl.selectLogic(month, {
      'jan': '1月',
      'feb': '2月',
      'mar': '3月',
      'apr': '4月',
      'may': '5月',
      'jun': '6月',
      'jul': '7月',
      'aug': '8月',
      'sep': '9月',
      'oct': '10月',
      'nov': '11月',
      'dec': '12月',
      'other': '$month',
    });
    return '$_temp0';
  }

  @override
  String statsMonthDay(String month, int day) {
    return '$month$day日';
  }

  @override
  String statsBarLevels(String day, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$day · $count 關',
    );
    return '$_temp0';
  }

  @override
  String statsBarNoPlay(String day) {
    return '$day · 沒有遊玩';
  }

  @override
  String get statsWorldAhead => '未開始';

  @override
  String get statsWorldNoTimes => '無時間';

  @override
  String statsWorldPoints(int points) {
    final intl.NumberFormat pointsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String pointsString = pointsNumberFormat.format(points);

    return '$pointsString 分';
  }

  @override
  String statsWorldSolvedSemantic(String name, int cleared, int total) {
    return '$name：$total 關中已過 $cleared 關';
  }

  @override
  String statsWorldPaceSemantic(String pace) {
    return '節奏 $pace';
  }

  @override
  String statsWorldPointsSemantic(int points) {
    final intl.NumberFormat pointsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String pointsString = pointsNumberFormat.format(points);

    return '$pointsString 分';
  }

  @override
  String get statsColLevel => '關卡';

  @override
  String get statsColStars => '星星';

  @override
  String get statsColMoves => '步數';

  @override
  String get statsColTime => '時間';

  @override
  String get statsColPoints => '分數';

  @override
  String statsMovesBestPossible(int moves, int best) {
    return '$moves 步，最佳可能 $best 步';
  }

  @override
  String statsMoves(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 步',
    );
    return '$_temp0';
  }

  @override
  String badgeUnlockedCount(int earned, int total) {
    return '已解鎖 $earned/$total';
  }

  @override
  String get badgeUnlocked => '已解鎖';

  @override
  String get badgeNotYet => '尚未達成';

  @override
  String badgeProgress(int shown, int target) {
    return '$shown/$target';
  }

  @override
  String badgeSemantic(String title, String description, String status) {
    return '$title：$description $status';
  }

  @override
  String get badgeFirstPourTitle => '初次倒球';

  @override
  String get badgeFirstPourDesc => '完成你的第一關。';

  @override
  String get badgePar10Title => '剛好標準';

  @override
  String get badgePar10Desc => '以剛好標準步數完成 10 關。';

  @override
  String get badgePar50Title => '標準大師';

  @override
  String get badgePar50Desc => '以剛好標準步數完成 50 關。';

  @override
  String get badgeCleanClearTitle => '落子無悔';

  @override
  String get badgeCleanClearDesc => '不使用復原完成一關。';

  @override
  String get badgeSpeedyTitle => '快手倒球';

  @override
  String get badgeSpeedyDesc => '在 30 秒內完成一關。';

  @override
  String get badgeLevels100Title => '百關達人';

  @override
  String get badgeLevels100Desc => '完成 100 關。';

  @override
  String get badgeStars300Title => '星星收藏家';

  @override
  String get badgeStars300Desc => '收集 300 顆星星。';

  @override
  String get badgeWorldPerfectTitle => '完美世界';

  @override
  String get badgeWorldPerfectDesc => '在一個世界的每一關都拿到三星。';

  @override
  String get badgeStreak7Title => '一週不間斷';

  @override
  String get badgeStreak7Desc => '每日一題連續 7 天。';

  @override
  String get badgeStreak30Title => '一月不間斷';

  @override
  String get badgeStreak30Desc => '每日一題連續 30 天。';

  @override
  String get badgeChests5Title => '尋寶獵人';

  @override
  String get badgeChests5Desc => '打開 5 個星星寶箱。';

  @override
  String get badgeHard5Title => '硬骨頭';

  @override
  String get badgeHard5Desc => '完成 5 個「困難」關卡。';

  @override
  String get badgeEventFullTitle => '全勤一週';

  @override
  String get badgeEventFullDesc => '完成每週活動的全部七個題目。';

  @override
  String get badgeZen25Title => 'Zen 庭園';

  @override
  String get badgeZen25Desc => '在 Zen 模式中完成 25 個題目。';

  @override
  String get commonCancel => '取消';

  @override
  String get commonClose => '關閉';

  @override
  String get commonBack => '返回';

  @override
  String get commonOk => '好';

  @override
  String get commonSave => '儲存';

  @override
  String get commonRetry => '再試一次';

  @override
  String get commonNotNow => '以後再說';

  @override
  String commonLevelN(int level) {
    return '第 $level 關';
  }

  @override
  String get hubAccountYours => '你的帳號';

  @override
  String get hubAccountSave => '儲存你的進度';

  @override
  String get hubPlayerFallback => '玩家';

  @override
  String get hubSettings => '設定';

  @override
  String get hubTagline => '倒球 · 分類 · 放鬆';

  @override
  String hubStatChipSemantic(String value, String label) {
    return '$value $label。統計';
  }

  @override
  String get hubStatSolved => '已過關';

  @override
  String get hubStatStars => '星星';

  @override
  String get hubStatStreak => '連續';

  @override
  String hubStreakDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 天',
    );
    return '$_temp0';
  }

  @override
  String hubRankNumber(int rank) {
    return '#$rank';
  }

  @override
  String hubEventSemantic(int cleared, int total) {
    return '每週活動，已完成 $cleared/$total 題';
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
  String get hubZenSemantic => 'Zen 模式';

  @override
  String hubZenLockedSemantic(int level) {
    return 'Zen 模式在第 $level 關解鎖';
  }

  @override
  String get hubZenOpen => '無限暢玩，不計時';

  @override
  String hubZenLocked(int level, int remaining) {
    return '第 $level 關 · 還差 $remaining 關';
  }

  @override
  String get hubDockJourney => '旅程';

  @override
  String get hubDockRankings => '排行榜';

  @override
  String get hubDockStats => '統計';

  @override
  String get hubTip => '太棒了！「旅程」裡有每一關的地圖，每天還有新的每日一題可以玩。';

  @override
  String hubHeroWorld(int world) {
    return '世界 $world';
  }

  @override
  String hubHeroWorldBand(int world, String band) {
    return '世界 $world · $band';
  }

  @override
  String hubHeroPar(int par) {
    return '標準 $par';
  }

  @override
  String get hubPlay => '開始';

  @override
  String hubPlaySemantic(int level) {
    return '開始第 $level 關';
  }

  @override
  String get hubMoreUpdateTitle => '更新以解鎖更多關卡';

  @override
  String get hubMoreUpdateBody => '新世界上線了，需要最新版的 Pourfect。更新遊戲，繼續倒球吧。';

  @override
  String get hubMoreDownloadingTitle => '新關卡即將到來';

  @override
  String get hubMoreDownloadingBody => '下一個世界正在下載，馬上就好。';

  @override
  String get hubMoreAllDoneTitle => '全部倒完了！';

  @override
  String get hubMoreOfflineBody => '連上網路後，更多關卡會在背景下載。在那之前，今天的每日一題正等著你。';

  @override
  String get hubMoreOnlineBody => '只要連上網路，更多關卡就會在背景下載。在那之前，今天的每日一題正等著你。';

  @override
  String get hubMoreCheckAgain => '再檢查一次';

  @override
  String hubAchievementOne(String title) {
    return '成就解鎖：$title';
  }

  @override
  String hubAchievementMany(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '解鎖了 $count 個成就！',
    );
    return '$_temp0';
  }

  @override
  String get hubUpdateReady => '有更新可以安裝了。';

  @override
  String get hubUpdateRestart => '重新啟動';

  @override
  String hubSpanSeconds(int seconds) {
    return '$seconds秒';
  }

  @override
  String hubSpanMinutes(int minutes) {
    return '$minutes分';
  }

  @override
  String hubSpanMinutesSeconds(int minutes, int seconds) {
    return '$minutes分$seconds秒';
  }

  @override
  String hubSpanHours(int hours) {
    return '$hours小時';
  }

  @override
  String hubSpanHoursMinutes(int hours, int minutes) {
    return '$hours小時$minutes分';
  }

  @override
  String get hubParOn => '剛好標準時間';

  @override
  String hubParUnder(int percent) {
    return '比標準快 $percent%';
  }

  @override
  String hubParOver(int percent) {
    return '比標準慢 $percent%';
  }

  @override
  String get dailyTitle => '每日一題';

  @override
  String get dailyCardSemantic => '今日挑戰';

  @override
  String get dailyCardUnavailable => '無法取得今日題目';

  @override
  String get dailyCardSolved => '已完成';

  @override
  String dailyCardNextIn(String time) {
    return '$time 後更新';
  }

  @override
  String dailyCardEndsIn(String time) {
    return '$time 後結束';
  }

  @override
  String dailyStreakDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '連續 $count 天',
    );
    return '$_temp0';
  }

  @override
  String dailyStreakMilestone(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '連續 $count 天！',
    );
    return '$_temp0';
  }

  @override
  String get dailyRankSemantic => '排行榜';

  @override
  String dailyRankSemanticRanked(int rank) {
    return '排行榜，第 $rank 名';
  }

  @override
  String get dailyRankSticker => '排名';

  @override
  String get dailyLeaveLost => '今天每日一題的步數不會儲存。今天隨時可以重新開始。';

  @override
  String get dailySubmitRefused => '伺服器不接受這個成績。';

  @override
  String get dailySubmitFailed => '已完成——但成績無法送出。請稍後再試。';

  @override
  String get dailyHudLabel => '每日';

  @override
  String get dailyHudValue => '一題';

  @override
  String get dailyDeadEndRestart => '從這裡無法完成了。重新開始，換個走法試試。';

  @override
  String dailyDeadEndUndo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '從這裡無法完成了。復原 $count 步就能回到正軌。',
    );
    return '$_temp0';
  }

  @override
  String get dailyActionRestart => '重新開始';

  @override
  String dailyActionUndo(int count) {
    return '復原 $count 步';
  }

  @override
  String get dailyNoHint => '這個局面沒有提示。';

  @override
  String get dailyLoadingTitle => '正在載入今日題目';

  @override
  String get dailyOffTitle => '這個版本未開放每日挑戰';

  @override
  String get dailyOffDetail => '主線關卡不受影響——所有關卡都在這台裝置上。';

  @override
  String get dailyNoBoardTitle => '今天沒有題目';

  @override
  String get dailyNoBoardDetail => '今日挑戰來自伺服器，但目前無法連線。主線關卡不需要連線。';

  @override
  String get dailyLoaderCaption => '正在倒出今日題目…';

  @override
  String get dailyBackToLevels => '返回關卡';

  @override
  String dailyWeekSemantic(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 天',
    );
    return '你的連續紀錄：$_temp0。開啟';
  }

  @override
  String dailyDaySemantic(String weekday, String state) {
    return '$weekday，$state';
  }

  @override
  String get dailyDayFrozen => '錯過，已用保護卡';

  @override
  String get dailyDayPlayedToday => '今天已玩';

  @override
  String get dailyDayPlayed => '已玩';

  @override
  String get dailyDayToday => '今天，還沒玩';

  @override
  String get dailyDayMissed => '沒玩';

  @override
  String get dailyDayFuture => '尚未到來';

  @override
  String get dailyOutcomeBest => '新紀錄';

  @override
  String get dailyOutcomeSolved => '完成';

  @override
  String get dailyFigureMoves => '步數';

  @override
  String get dailyFigureStreak => '連續';

  @override
  String get dailyUnranked => '未排名';

  @override
  String dailyOfPlayers(int count) {
    return '共 $count 人';
  }

  @override
  String get dailyReminderOn => '明天傍晚會提醒你一次。';

  @override
  String get dailyRemindMe => '明天提醒我';

  @override
  String get dailyDone => '完成';

  @override
  String get dailyFreezeVideoUnfinished => '沒拿到保護卡——影片沒有看完。';

  @override
  String get dailyFreezeNoVideo => '目前沒有可播放的影片。';

  @override
  String get dailyFreezeError => '出了點問題，請稍後再試。';

  @override
  String get dailyFreezeAdded => '已獲得保護卡，可抵銷一天沒玩。';

  @override
  String get dailyFreezeNoRoom => '今天無法再增加保護卡了。';

  @override
  String get dailyFreezeLoadingVideo => '影片載入中…';

  @override
  String get dailyFreezeWatch => '看影片獲得保護卡';

  @override
  String get dailyFreezesFull => '保護卡已滿。每張可抵銷一天沒玩。';

  @override
  String get dailyFreezeTomorrow => '每天可看一次影片換保護卡，明天再來。';

  @override
  String get dailyStreakTitle => '你的連續紀錄';

  @override
  String get dailyStreakNone => '還沒有連續紀錄';

  @override
  String get dailyStreakStart => '玩今天的每日一題來開始吧。';

  @override
  String dailyStreakBest(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '最長：$count 天',
    );
    return '$_temp0';
  }

  @override
  String dailyFreezesSemantic(int count, int max) {
    return '連續保護卡 $count/$max 張';
  }

  @override
  String get dailyFreezesTitle => '連續保護卡';

  @override
  String get dailyFreezesEach => '每張可抵銷一天沒玩。';

  @override
  String dailyFreezeWeekly(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '每週一免費送一張，$days 天後送達。',
      one: '每週一免費送一張，就在明天。',
    );
    return '$_temp0';
  }

  @override
  String get dailyCalendarPrevious => '上個月';

  @override
  String get dailyCalendarNext => '下個月';

  @override
  String dailyCalendarCellSemantic(String date, String state) {
    return '$date，$state';
  }

  @override
  String get dailyCalendarPlayed => '已玩';

  @override
  String get dailyCalendarFrozen => '已保護';

  @override
  String get dailyCalendarFuture => '尚未到來';

  @override
  String get dailyLegendPlayed => '已玩';

  @override
  String get dailyLegendFrozen => '已保護';

  @override
  String get dailyLegendToday => '今天';

  @override
  String get eventTitle => '每週活動';

  @override
  String get eventUnreachable => '目前無法取得本週活動。';

  @override
  String get eventEnded => '已結束';

  @override
  String eventEndsIn(String timeLeft) {
    return '$timeLeft 後結束';
  }

  @override
  String eventTimeLeftDaysHours(int days, int hours) {
    return '$days天$hours小時';
  }

  @override
  String eventTimeLeftHours(int hours) {
    return '$hours小時';
  }

  @override
  String eventTimeLeftMinutes(int minutes) {
    return '$minutes分';
  }

  @override
  String eventSummary(int cleared, int total, String endsIn) {
    return '已完成 $cleared/$total 題 · $endsIn';
  }

  @override
  String get eventFigurePoints => '分數';

  @override
  String eventRankOf(int count) {
    return '共 $count 人';
  }

  @override
  String get eventRankPlay => '玩一題即可排名';

  @override
  String get eventRankSetName => '設定名字即可排名';

  @override
  String eventTileSemanticDone(int slot, int stars, int points) {
    String _temp0 = intl.Intl.pluralLogic(
      stars,
      locale: localeName,
      other: '$stars 顆星',
    );
    return '第 $slot 題，$_temp0，$points 分';
  }

  @override
  String eventTileSemanticNew(int slot) {
    return '第 $slot 題，未玩';
  }

  @override
  String eventTilePoints(int points) {
    return '$points分';
  }

  @override
  String get eventStandingsTitle => '本週排行榜';

  @override
  String get eventStandingsEmpty => '還沒有人上榜，搶當第一名吧。';

  @override
  String eventStandingsCleared(int cleared) {
    return ' · $cleared/7';
  }

  @override
  String get eventSubmitRefused => '伺服器不接受這個成績——活動可能已經結束了。';

  @override
  String get eventSubmitFailed => '已完成——但成績無法送出。請再試一次。';

  @override
  String eventDeadEndUndo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '從這裡無法完成了。復原 $count 步吧。',
    );
    return '$_temp0';
  }

  @override
  String get eventNoHint => '目前這個局面沒有提示。';

  @override
  String get eventHudLabel => '題目';

  @override
  String eventHudBand(String event, String endsIn) {
    return '$event · $endsIn';
  }

  @override
  String get eventSending => '傳送中…';

  @override
  String eventResult(int points, int total) {
    return '$points 分 · 本週 $total 分';
  }

  @override
  String eventResultRanked(int points, int total, int rank) {
    return '$points 分 · 本週 $total 分 · #$rank';
  }

  @override
  String get journeyTitle => '旅程';

  @override
  String journeyStarsSemantic(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 顆星',
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
    return '第 $world 個世界，共 $worlds 個，$name，$total 關中已過 $solved 關';
  }

  @override
  String journeyWorldOf(int world, int worlds) {
    return '世界 $world/$worlds';
  }

  @override
  String journeyRibbonSemantic(int world, String name, int solved, int total) {
    return '世界 $world，$name，$total 關中已過 $solved 關。捲動到這裡';
  }

  @override
  String journeyRibbonLabel(int world, String name) {
    return '世界 $world · $name';
  }

  @override
  String get journeyYouPin => '你';

  @override
  String journeyBandCaps(int world, int count) {
    return '世界 $world · $count';
  }

  @override
  String get journeyBandFirstPours => '初試身手';

  @override
  String get journeyBandFindingRhythm => '漸入佳境';

  @override
  String get journeyBandDeepWater => '深水區';

  @override
  String get journeyBandMastery => '大師之境';

  @override
  String get notifSoftAskTitle => '需要提醒嗎？';

  @override
  String get notifSoftAskBody =>
      '今天的每日一題上線、或下一關在等你時，我們會通知你。每天最多兩則，隨時可以在「設定」中關閉。';

  @override
  String get notifSoftAskBodyDenied =>
      'Pourfect 的通知已關閉。到手機的設定中開啟，就能在每日一題上線或新世界推出時收到通知。每天最多兩則。';

  @override
  String get notifSoftAskOpenSettings => '開啟設定';

  @override
  String get notifSoftAskYes => '好啊';

  @override
  String get notifChannelName => '提醒';

  @override
  String get notifChannelDescription => '每日一題、下一關和新世界。每天最多兩則。';

  @override
  String get playHudLevel => '關卡';

  @override
  String playHudTitle(String label, String value) {
    return '$label $value';
  }

  @override
  String get playHudHard => '困難 ×1.5';

  @override
  String get playHudHardLabel => '困難關卡，分數 1.5 倍';

  @override
  String get playHudMoves => '步數';

  @override
  String playHudMovesLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 步',
    );
    return '$_temp0';
  }

  @override
  String playParLeftFor3Stars(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '再 $count 步內可拿 3 星',
    );
    return '$_temp0';
  }

  @override
  String get playParSpent => '標準步數已用完 · 最多 2 星';

  @override
  String playParLeftFor2Stars(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '再 $count 步內可拿 2 星',
    );
    return '$_temp0';
  }

  @override
  String get playParOneStarFromHere => '最多 1 星 · 完成即可';

  @override
  String get playParAnyFinish => '完成就能拿 1 星';

  @override
  String playParMeterLabel(int stars, int used, int par, String words) {
    return '$stars 星節奏，已用 $used 步，標準 $par 步。$words';
  }

  @override
  String playHudBusyLabel(String label) {
    return '$label，處理中。點一下取消';
  }

  @override
  String get playHudUndo => '復原';

  @override
  String get playHudHint => '提示';

  @override
  String get playHudRestart => '重來';

  @override
  String get playExtraTubeLabel => '看影片獲得一支額外試管';

  @override
  String get playExtraTubeChip => '+ 試管';

  @override
  String playStarsOfTotal(int earned, int total) {
    return '$earned/$total 顆星';
  }

  @override
  String get playDismiss => '關閉';

  @override
  String get playLeaveTitleSoSoon => '這麼快就要走了？';

  @override
  String get playLeaveTitleMissYou => '球球會想你的';

  @override
  String get playLeaveTitleAbandon => '不倒了嗎？';

  @override
  String get playLeaveTitleMidPour => '倒到一半就走？';

  @override
  String get playLeaveBody => '這一題的步數和時間不會儲存。';

  @override
  String get playLeaveKeepPouring => '繼續倒';

  @override
  String get playLeaveConfirm => '離開';

  @override
  String get playTutorialSkipLabel => '略過教學';

  @override
  String get playTutorialSkip => '略過';

  @override
  String playTipBubbleLabel(String text) {
    return '$text。關閉';
  }

  @override
  String get playTipPar => '在標準步數內完成可拿三星。進度條會顯示你用了多少。';

  @override
  String get playTipTallTubes => '更高的試管！現在每支可以裝五顆球。';

  @override
  String get playTipHint => '卡住了？「提示」會告訴你一步好棋。';

  @override
  String get playTipUndo => '超過標準步數了？復原是免費的——想退幾步都行。';

  @override
  String get playGuideSorted => '分好了！讓每支試管都只剩一種顏色。';

  @override
  String get playGuideDrop => '現在點要倒的地方：同色的球上，或空試管。';

  @override
  String get playGuideWrongTube => '點手指指著的試管，改拿那些球。';

  @override
  String get playGuideFirstTap => '點一支試管，拿起最上面的球。';

  @override
  String get playGuideFirstPour => '倒好了！繼續加油。';

  @override
  String get playGuideKeepGoing => '繼續：每支試管一種顏色。';

  @override
  String playCoachHolding(int count) {
    return '拿著 $count 顆 · 倒進跳動的試管';
  }

  @override
  String get playExtraTubeAdTitle => '看影片獲得一支額外試管？';

  @override
  String get playExtraTubeAdBody => '本關多一支空試管。使用額外試管完成的關卡最多可得兩星。';

  @override
  String get playExtraTubeNotFinished => '沒拿到試管——影片沒有看完。';

  @override
  String get playExtraTubeSaved => '已保留——下一支試管免費。';

  @override
  String get playNoVideo => '目前沒有可播放的影片。';

  @override
  String get playRewardFailed => '出了點問題，沒有扣除任何東西。';

  @override
  String get playHintShowing => '提示已顯示：倒進發光的試管。';

  @override
  String get playHintNoneNothingUsed => '這個局面沒有提示，沒有扣除任何東西。';

  @override
  String get playHintNotFinished => '沒拿到提示——影片沒有看完。';

  @override
  String get playHintVideoSaved => '你的影片已保留給下一次提示。';

  @override
  String get playHintNoneVideoSaved => '這個局面沒有提示——你的影片已保留給下一次。';

  @override
  String get playHintNone => '這個局面沒有可用的提示。';

  @override
  String get playHintHere => '提示來了——倒進發光的試管。';

  @override
  String get playDeadEndRestart => '從這裡無法完成了。重新開始，換個走法試試。';

  @override
  String get playDeadEndRestartTube => '從這裡無法完成了。重新開始，換個走法試試。或點「+ 試管」多拿一支空試管。';

  @override
  String playDeadEndUndo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '從這裡無法完成了。復原 $count 步就能回到正軌。',
    );
    return '$_temp0';
  }

  @override
  String playDeadEndUndoTube(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '從這裡無法完成了。復原 $count 步就能回到正軌。或點「+ 試管」多拿一支空試管。',
    );
    return '$_temp0';
  }

  @override
  String playDeadEndUndoAction(int count) {
    return '復原 $count 步';
  }

  @override
  String get playHintAdTitle => '看影片獲得提示？';

  @override
  String playHintAdFreeLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '你還有 $count 次免費提示。',
    );
    return '$_temp0';
  }

  @override
  String get playHintAdNoneLeft => '免費提示用完了。看一段短片就能再拿一次。';

  @override
  String get playWatch => '觀看';

  @override
  String get playLoadFailed => '無法載入關卡';

  @override
  String get playTubeSorted => '完成！';

  @override
  String get playWinTitlePerfect => '倒得\n完美！';

  @override
  String get playWinTitleNice => '倒得\n漂亮！';

  @override
  String get playWinTitlePoured => '倒完了！';

  @override
  String get playWinLastPour => '最後一倒…';

  @override
  String playWinMovesPar(int count, int par) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 步 · 標準 $par',
    );
    return '$_temp0';
  }

  @override
  String playWinLevelBand(int level, String band) {
    return '第 $level 關 · $band';
  }

  @override
  String get playWinNewBest => '新紀錄！';

  @override
  String playWinMovesChip(int par) {
    return '步 · 標準 $par';
  }

  @override
  String get playWinUntimed => '未計時';

  @override
  String get playWinFastest => '最快紀錄！';

  @override
  String get playWinTime => '時間';

  @override
  String get playWinUnderPar => '超越標準！';

  @override
  String get playWinPoints => '分數';

  @override
  String playWinWorldBand(int world, String band) {
    return '世界 $world · $band';
  }

  @override
  String get playWinTryAssisted => '不用額外試管完成才能拿三星。';

  @override
  String playWinTryShort(int par, int took, int short) {
    String _temp0 = intl.Intl.pluralLogic(
      short,
      locale: localeName,
      other: '標準 $par 步，你用了 $took 步。差 $short 步就能拿 3★。',
    );
    return '$_temp0';
  }

  @override
  String playWinTryInReach(int par) {
    return '標準 $par 步。三星就在眼前。';
  }

  @override
  String get playWinTryButton => '挑戰 3★';

  @override
  String get playWinTryButtonLabel => '重玩本關挑戰三星';

  @override
  String get playWinReplayLabel => '重玩本關';

  @override
  String get playWinHomeLabel => '回到主畫面';

  @override
  String get playWinNextLevel => '下一關';

  @override
  String get playWinBackToLevels => '返回關卡';

  @override
  String playChestNextAtLabel(int stars) {
    return '累積 $stars 顆星可開下一個星星寶箱';
  }

  @override
  String get playChestOpenLabel => '打開星星寶箱';

  @override
  String get playChestReady => '星星寶箱可以打開了！';

  @override
  String playChestNextAt(int stars) {
    return '下一個寶箱：$stars ★';
  }

  @override
  String get playChestOpen => '打開';

  @override
  String get playChestDoubleFailed => '這次無法加倍。';

  @override
  String get playChestDoubleNotFinished => '沒有加倍——影片沒有看完。';

  @override
  String get playChestOpening => '打開中…';

  @override
  String playChestTitle(int index) {
    return '第 $index 個星星寶箱';
  }

  @override
  String get playChestNotYetTitle => '就快好了';

  @override
  String get playChestAlreadyOpenTitle => '已經打開了';

  @override
  String get playChestFailedTitle => '無法打開';

  @override
  String get playChestNotYetNote => '你最新的星星還在傳到伺服器的路上，請稍後再試。';

  @override
  String get playChestAlreadyOpenNote => '這個寶箱已在其他裝置上打開了。';

  @override
  String get playChestFailedNote => '請檢查網路連線後再試一次。';

  @override
  String playChestRewardCount(int count) {
    return '+$count';
  }

  @override
  String playChestHintsCaption(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '提示',
    );
    return '$_temp0';
  }

  @override
  String playChestTubesCaption(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '額外試管',
    );
    return '$_temp0';
  }

  @override
  String playChestUnlocked(String name) {
    return '已解鎖：$name';
  }

  @override
  String playChestBallSkinName(String skin) {
    return '$skin球造型';
  }

  @override
  String playChestTubeThemeName(String theme) {
    return '$theme試管';
  }

  @override
  String get playChestNewLook => '新造型';

  @override
  String get playChestSavedNote => '已存起來，需要時再用。「提示」和「+ 試管」會優先使用這些。';

  @override
  String get playChestLoadingVideo => '影片載入中…';

  @override
  String get playChestDouble => '看影片加倍';

  @override
  String get playChestCollect => '領取';

  @override
  String playClockLabel(String time) {
    return '時間 $time';
  }

  @override
  String playClockDetailLabel(
    String time,
    String par,
    String sign,
    int percent,
  ) {
    String _temp0 = intl.Intl.selectLogic(sign, {'plus': '加', 'other': '減'});
    return '時間 $time，標準時間 $par，分數$_temp0百分之 $percent';
  }

  @override
  String playClockBonusChip(String sign, int percent) {
    return '$sign$percent% 分';
  }

  @override
  String get playLoading => '載入中';

  @override
  String get playWorking => '處理中';

  @override
  String get playZenTitle => 'Zen';

  @override
  String get playZenIntro => '無限題目。不計時、不計星、沒有排行榜——盡情倒就好。';

  @override
  String get playZenPaceCalm => '悠閒';

  @override
  String get playZenPaceSteady => '沉穩';

  @override
  String get playZenPaceDeep => '深邃';

  @override
  String playZenPaceColors(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 種顏色',
    );
    return '$_temp0';
  }

  @override
  String playZenPaceLabel(String pace, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$pace，$count 種顏色',
    );
    return '$_temp0';
  }

  @override
  String playZenBandPoured(String pace, int count) {
    return '$pace · 已完成 $count 題';
  }

  @override
  String playZenPoured(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '倒完了！已完成 $count 題。',
      one: '倒完了！',
    );
    return '$_temp0';
  }

  @override
  String get playZenNext => '下一題';

  @override
  String get playZenLeaveBody => '這一題的步數不會儲存，已完成的題數會保留。';

  @override
  String get playZenDeadEnd => '從這裡無法完成了。復原或重新開始吧。';

  @override
  String get playZenNoHint => '目前這個局面沒有提示。';

  @override
  String get settingsTitle => '設定';

  @override
  String get settingsSectionFeel => '手感';

  @override
  String get settingsSectionVisibility => '辨識度';

  @override
  String get settingsSectionLeaderboard => '排行榜';

  @override
  String get settingsSectionNotifications => '通知';

  @override
  String get settingsSectionSupport => '支援';

  @override
  String get settingsSectionAccount => '帳號與關於';

  @override
  String get settingsSectionDanger => '危險區域';

  @override
  String get settingsSoundTitle => '音效';

  @override
  String get settingsSoundDetail => '倒球、按鈕和獎勵';

  @override
  String get settingsSoundVolume => '音效音量';

  @override
  String get settingsMusicTitle => '音樂';

  @override
  String get settingsMusicDetail => '絕不蓋過你自己的音樂';

  @override
  String get settingsMusicVolume => '音樂音量';

  @override
  String get settingsHapticsTitle => '震動回饋';

  @override
  String get settingsHapticsDetail => '每顆球落下時輕輕一震';

  @override
  String get settingsSmoothMotionTitle => '流暢動態';

  @override
  String get settingsSmoothMotionAuto => '自動';

  @override
  String get settingsSmoothMotion60 => '60 Hz';

  @override
  String get settingsSmoothMotionMax => '最高';

  @override
  String get settingsMotionUnknown => '若手機跟得上，「自動」會使用螢幕的最高更新率';

  @override
  String settingsMotionFixed(String max) {
    return '這個螢幕只支援 $max Hz';
  }

  @override
  String settingsMotionBatterySaver(String current) {
    return '省電模式將它限制在 $current Hz';
  }

  @override
  String settingsMotionAutoStuttered(String current, String max) {
    return '目前 $current Hz · 這支手機在 $max Hz 時會卡頓';
  }

  @override
  String settingsMotionAuto(String current) {
    return '目前 $current Hz · 卡頓時會降到 60 Hz';
  }

  @override
  String settingsMotionPinnedByPhone(String current) {
    return '手機的螢幕設定將它固定在 $current Hz';
  }

  @override
  String settingsMotionStandard(String current, String max) {
    return '目前 $current Hz · 這個螢幕最高可達 $max Hz';
  }

  @override
  String settingsMotionMax(String current) {
    return '目前 $current Hz，這個螢幕的最高速度';
  }

  @override
  String get settingsBoldSymbolsTitle => '粗體符號';

  @override
  String get settingsBoldSymbolsDetail => '加粗圖形，方便色盲或色弱玩家辨識';

  @override
  String get settingsRenameTitle => '更改名字';

  @override
  String get settingsRenameDetail => '你在排行榜上的名字';

  @override
  String get settingsShowOnBoardsTitle => '在排行榜上顯示我';

  @override
  String get settingsShowOnBoardsDetail => '關閉會隱藏名字和排名，星星照樣計算。';

  @override
  String get settingsHowToPlayTitle => '玩法說明';

  @override
  String get settingsHowToPlayDetail => '重玩第一關的引導教學';

  @override
  String get settingsQuestionsTitle => '常見問題';

  @override
  String get settingsQuestionsDetail => '星星、提示、計時等';

  @override
  String get settingsRateTitle => '為 Pourfect 評分';

  @override
  String get settingsRateDetail => '告訴其他玩家你的想法';

  @override
  String get settingsCollectionTitle => '收藏館';

  @override
  String get settingsCollectionDetail => '球造型和試管主題';

  @override
  String get settingsRestoreTitle => '恢復購買';

  @override
  String get settingsRestoreDetail => '移除廣告或造型包';

  @override
  String get settingsRestoreDone => '已恢復購買項目（如果有的話）。';

  @override
  String get settingsRemoveAdsTitle => '移除廣告';

  @override
  String get settingsRemoveAdsDetail => '關卡之間不再有廣告，提示影片保留。';

  @override
  String get settingsAdsRemoved => '廣告已移除——謝謝你';

  @override
  String get settingsPurchaseThanks => '謝謝你！關卡之間的廣告已關閉。';

  @override
  String get settingsPurchaseAlreadyOwned => '已經購買過了——廣告已關閉。';

  @override
  String get settingsPurchasePending => '付款處理中。完成後廣告就會關閉。';

  @override
  String get settingsStoreUnavailable => '這台裝置目前無法使用商店。';

  @override
  String get settingsPurchaseFailed => '購買沒有完成，你沒有被扣款。';

  @override
  String get settingsStoreOpenFailed => '無法開啟商店。';

  @override
  String get settingsBrowserOpenFailed => '無法開啟瀏覽器。';

  @override
  String get settingsSignedIn => '已登入';

  @override
  String get settingsSignedInDetail => '你的進度會跟著你';

  @override
  String get settingsSaveProgressTitle => '儲存你的進度';

  @override
  String get settingsSaveProgressDetail => '換手機時保留你的星星';

  @override
  String get settingsPrivacyPolicy => '隱私權政策';

  @override
  String get settingsTermsAndLicenses => '條款與授權';

  @override
  String get settingsTermsOfUse => '使用條款';

  @override
  String get settingsRefundPolicy => '退款政策';

  @override
  String get settingsOpenSourceLicenses => '開放原始碼授權';

  @override
  String get settingsAdPrivacyTitle => '廣告隱私權選項';

  @override
  String get settingsAdPrivacyDetail => '更改你對廣告的同意設定';

  @override
  String get settingsResetRowTitle => '重設進度';

  @override
  String get settingsResetRowDetail => '清除所有星星，從第 1 關重新開始';

  @override
  String get settingsResetTitle => '要重設進度嗎？';

  @override
  String get settingsResetNothing => '目前還沒有可以重設的進度。';

  @override
  String settingsResetBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '這會清除 $count 個已過關卡的所有星星和最佳成績，並重新鎖住第 1 關之後的所有關卡。此操作無法復原。',
    );
    return '$_temp0';
  }

  @override
  String get settingsKeepIt => '保留';

  @override
  String get settingsResetConfirm => '全部清除';

  @override
  String get settingsResetDone => '進度已重設。';

  @override
  String get settingsSignOutTitle => '要登出嗎？';

  @override
  String get settingsSignOutBody => '你的進度會留在這支手機上。隨時可以重新登入，在其他地方繼續。';

  @override
  String get settingsSignOutStay => '保持登入';

  @override
  String get settingsSignOutConfirm => '登出';

  @override
  String get settingsServerUnreachable => '無法連上伺服器，所以沒有任何變更。';

  @override
  String get settingsDeleteRowTitle => '刪除帳號';

  @override
  String get settingsDeleteRowDetail => '移除你的帳號及所有相關資料';

  @override
  String get settingsDeleteTitle => '要刪除你的帳號嗎？';

  @override
  String get settingsDeleteBody =>
      '這會移除你的帳號、星星、連續紀錄和排行榜資料，包括這支手機和我們伺服器上的。此操作無法復原。\n\n「移除廣告」不受影響——它屬於你購買時使用的商店帳號，再次遊玩時會自動恢復。';

  @override
  String get settingsDeleteConfirm => '全部刪除';

  @override
  String get settingsDeleteServerRefused => '無法連上伺服器，沒有刪除任何資料——恢復連線後再試一次。';

  @override
  String get settingsDeleteNotAuthenticated =>
      '無法確認是你本人。請重新登入後再刪除帳號——目前還沒有刪除任何資料。';

  @override
  String settingsFooterVersion(String version) {
    return 'Pourfect $version';
  }

  @override
  String settingsFooterVersionBoards(int count, String version) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Pourfect $version · 收錄 $count 個經驗證可解的題目',
    );
    return '$_temp0';
  }

  @override
  String get settingsNamingYou => '正在取名…';

  @override
  String get settingsYourName => '你的名字';

  @override
  String get settingsGuest => '以訪客身分遊玩';

  @override
  String get settingsStatSolved => '已過關';

  @override
  String get settingsStatStars => '星星';

  @override
  String get settingsNotifyTurnOnTitle => '開啟通知';

  @override
  String get settingsNotifyDeniedDetail => '手機設定中已關閉，點一下前往開啟。';

  @override
  String get settingsNotifyNotYetDetail => 'Pourfect 還無法通知你';

  @override
  String get settingsRemindersTitle => '每日一題提醒';

  @override
  String get settingsRemindersDetail => '早晚各一次，每天最多兩則';

  @override
  String get settingsNewsTitle => '遊戲消息';

  @override
  String get settingsNewsDetail => '新世界與公告';

  @override
  String settingsToggleOn(String title) {
    return '$title，開啟';
  }

  @override
  String settingsToggleOff(String title) {
    return '$title，關閉';
  }

  @override
  String get settingsFaqSectionPlaying => '遊戲玩法';

  @override
  String get settingsFaqSectionStuck => '卡關了？';

  @override
  String get settingsFaqSectionProgress => '你的進度';

  @override
  String get settingsFaqSectionAds => '廣告與聲音';

  @override
  String get settingsFaqHowToPlayQ => '怎麼玩？';

  @override
  String get settingsFaqHowToPlayA =>
      '點一支試管拿起最上面的球，再點另一支試管倒進去。球只能倒在同色的球上或空試管裡。讓每支試管都只有一種顏色，就過關了。「設定 → 玩法說明」可以重玩第一關的引導教學。';

  @override
  String get settingsFaqStarsQ => '星星代表什麼？';

  @override
  String get settingsFaqStarsA =>
      '星星只看步數。在標準步數以內完成可得三星，在標準步數的 1.5 倍以內可得兩星，只要完成就有一星。標準步數是該關卡可解的最少步數。';

  @override
  String get settingsFaqClockQ => '計時會讓我少拿星星嗎？';

  @override
  String get settingsFaqClockA => '絕對不會。時間只影響分數。打敗標準時間可拿額外分數，慢慢玩也能保住每一顆星。';

  @override
  String get settingsFaqSolvableQ => '每一關都有解嗎？';

  @override
  String get settingsFaqSolvableA => '是的。每個題目上線前都已經解開過，標準步數就是從那個解法來的，所以一定做得到。';

  @override
  String get settingsFaqDailyQ => '什麼是每日一題？';

  @override
  String get settingsFaqDailyA => '每天一個新題目，有自己的排行榜。需要網路連線，主線關卡則不需要。';

  @override
  String get settingsFaqUndoQ => '復原有次數限制嗎？';

  @override
  String get settingsFaqUndoA => '沒有。每一關的復原都免費且無限次。';

  @override
  String get settingsFaqHintsQ => '提示怎麼用？';

  @override
  String settingsFaqHintsA(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '前 $count 次提示免費。之後看一段短片就能拿一次。如果找不到提示，影片仍會算在下一次提示上。',
    );
    return '$_temp0';
  }

  @override
  String get settingsFaqTubeQ => '「+ 試管」按鈕是什麼？';

  @override
  String get settingsFaqTubeA =>
      '當步數達到標準步數，或提示顯示已無法完成時，你可以看影片獲得一支額外的空試管，每次挑戰最多兩支。復原不會把它收回。使用額外試管完成的關卡最多可得兩星。';

  @override
  String get settingsFaqHardQ => '什麼是「困難」關卡？';

  @override
  String get settingsFaqHardA => '每十關中最難的一關會掛上紅色的「困難」標章。玩法和其他關卡一樣，但分數是 1.5 倍。';

  @override
  String get settingsFaqChestsQ => '什麼是星星寶箱？';

  @override
  String get settingsFaqChestsA =>
      '每累積 30 顆星，就能在「旅程」中打開一個寶箱：兩次提示和一支額外試管，存起來需要時再用。每第三個寶箱還會解鎖一款球造型。';

  @override
  String get settingsFaqFreezeQ => '什麼是連續保護卡？';

  @override
  String get settingsFaqFreezeA =>
      '錯過一天的每日一題時，保護卡會幫你抵銷，連續紀錄就不會中斷。每週一免費送一張，每天可看影片換一張，最多持有兩張。';

  @override
  String get settingsFaqAccountQ => '需要帳號嗎？';

  @override
  String get settingsFaqAccountA =>
      '不需要。你可以用訪客身分遊玩，進度會存在這支手機上。登入後，換新手機也能保留你的星星。';

  @override
  String get settingsFaqOfflineQ => '可以離線玩嗎？';

  @override
  String get settingsFaqOfflineA => '可以，整個主線都能離線玩。每日一題和排行榜需要連線，恢復連線後進度會自動同步。';

  @override
  String get settingsFaqNameQ => '怎麼更改排行榜名字？';

  @override
  String get settingsFaqNameA => '「設定 → 更改名字」。你也可以在那裡把自己從排行榜上隱藏，星星照樣計算。';

  @override
  String get settingsFaqRemoveAdsQ => '「移除廣告」有什麼作用？';

  @override
  String get settingsFaqRemoveAdsA => '它會關閉關卡之間的廣告。提示和試管的影片會保留，因為只有你主動要求時才會看到。';

  @override
  String get settingsFaqReinstallQ => '我重新安裝了，「移除廣告」怎麼不見了？';

  @override
  String get settingsFaqReinstallA =>
      '它屬於你購買時使用的商店帳號，通常會自動恢復。如果沒有，請點「設定 → 恢復購買」。';

  @override
  String get settingsFaqMusicQ => '遊戲會中斷我的音樂嗎？';

  @override
  String get settingsFaqMusicA =>
      '不會。Pourfect 的音效會和你的音樂或 Podcast 一起播放。音效和震動回饋可以在「設定」中關閉。';

  @override
  String get settingsLegalTitle => '開倒之前';

  @override
  String get settingsLegalIntro => 'Pourfect 完全免費、可離線遊玩，也不需要帳號。請先閱讀並同意以下內容。';

  @override
  String settingsLegalAcceptTerms(String document) {
    return '我同意$document';
  }

  @override
  String settingsLegalReadPrivacy(String document) {
    return '我已閱讀$document';
  }

  @override
  String settingsLegalAlsoCovers(String document, String version) {
    return '同意即表示也接受我們的$document（版本 $version）。';
  }

  @override
  String get settingsLegalPrivacyPolicy => '隱私權政策';

  @override
  String get settingsLegalTermsOfService => '服務條款';

  @override
  String get settingsLegalRefundPolicy => '退款政策';

  @override
  String settingsLegalReadDocument(String document) {
    return '閱讀$document';
  }

  @override
  String get settingsLegalAccept => '開始倒吧！';

  @override
  String get settingsLegalReadAgain => '隨時可以在「設定」中再次閱讀。';

  @override
  String get settingsLegalLoadFailed =>
      '這台裝置無法載入這份文件。\n\n同意前，你可以前往 legal.pranta.dev 閱讀。';

  @override
  String get settingsUpdateTitle => '新版 Pourfect 來了';

  @override
  String get settingsUpdateBody => 'Google Play 會下載更新，完成後自動重新開啟遊戲。你的星星很安全。';

  @override
  String get settingsUpdateMandatoryTitle => '該更新了';

  @override
  String get settingsUpdateMandatoryBody =>
      '這個版本的 Pourfect 已不再支援。Google Play 會下載更新並重新開啟遊戲。你的星星很安全。';

  @override
  String get settingsUpdateNow => '立即更新';

  @override
  String get settingsRenameHello => '你好';

  @override
  String get settingsRenameMyNameIs => '我的名字是';

  @override
  String get settingsRenameHint => '其他玩家會在排行榜上看到這個名字';

  @override
  String get settingsRenameSave => '儲存';

  @override
  String settingsCollectionUnlockWith(String how) {
    return '解鎖方式：$how。';
  }

  @override
  String get settingsCollectionChangeFailed => '目前無法更換，請稍後再試。';

  @override
  String get settingsPackThanks => '謝謝你！造型包馬上就會解鎖。';

  @override
  String get settingsPackAlreadyOwned => '你已經擁有了，正在恢復。';

  @override
  String get settingsPackPending => '付款處理中。完成後造型包就會解鎖。';

  @override
  String get settingsCollectionOffline => '連上網路即可查看你的收藏。';

  @override
  String get settingsCollectionBallSkins => '球造型';

  @override
  String get settingsCollectionTubeThemes => '試管主題';

  @override
  String settingsCollectionPreview(String skin, String theme) {
    return '$skin球 · $theme試管';
  }

  @override
  String settingsCollectionItemWorn(String name) {
    return '$name，使用中';
  }

  @override
  String settingsCollectionItemTapToWear(String name) {
    return '$name，點一下使用';
  }

  @override
  String settingsCollectionItemLocked(String name, String how) {
    return '$name，未解鎖：$how';
  }

  @override
  String get settingsCollectionWearing => '使用中';

  @override
  String get settingsCollectionTapToWear => '點一下使用';

  @override
  String settingsUnlockChest(int number) {
    return '星星寶箱 $number';
  }

  @override
  String settingsUnlockStreak(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '連續 $days 天',
    );
    return '$_temp0';
  }

  @override
  String get settingsUnlockFree => '免費';

  @override
  String get settingsSkinPack => '造型包';

  @override
  String get settingsSkinPackDetail => '大理石、珍珠和棋盤格球，以及木紋和紫丁香試管。';

  @override
  String get settingsOwned => '已擁有';

  @override
  String get settingsSoon => '即將推出';

  @override
  String get settingsSkinClassic => '經典';

  @override
  String get settingsSkinGlossy => '亮面';

  @override
  String get settingsSkinStriped => '糖果條紋';

  @override
  String get settingsSkinGlow => '螢光';

  @override
  String get settingsSkinSpeckled => '彩色糖粒';

  @override
  String get settingsSkinMarble => '大理石';

  @override
  String get settingsSkinPearl => '珍珠';

  @override
  String get settingsSkinChecker => '棋盤格';

  @override
  String get settingsTubeToy => '玩具';

  @override
  String get settingsTubeFrost => '霜凍';

  @override
  String get settingsTubeWood => '木紋';

  @override
  String get settingsTubeLilac => '紫丁香';
}

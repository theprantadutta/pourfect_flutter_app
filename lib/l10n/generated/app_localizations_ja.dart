// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get accountGoogleFailed =>
      'このスマホではGoogleでのサインインができませんでした。もう一度試すか、下のメールアドレスをお使いください。';

  @override
  String get accountAppleFailed =>
      'このスマホではAppleでのサインインができませんでした。「設定」でAppleアカウントにサインインしているか確認するか、下のメールアドレスをお使いください。';

  @override
  String get accountExistsNoLocal =>
      'このメールアドレスのアカウントはすでにあります。サインインすると、そのアカウントに保存された星がこのスマホに読み込まれます。';

  @override
  String accountExistsWithLocal(int solved) {
    String _temp0 = intl.Intl.pluralLogic(
      solved,
      locale: localeName,
      other:
          'このメールアドレスのアカウントはすでにあります。このスマホにはそのアカウントにないクリア済みレベルが$solved個あり、両方を統合することはできません。サインインすると、そのアカウントの内容に置き換わります。',
    );
    return '$_temp0';
  }

  @override
  String get accountEmailInUse => 'このメールアドレスのアカウントはすでにあります。サインインをお試しください。';

  @override
  String get accountEmailMalformed => 'メールアドレスの形式が正しくないようです。';

  @override
  String get accountPasswordWeak => 'このパスワードは推測されやすすぎます。もっと長いものをお試しください。';

  @override
  String get accountWrongPassword => 'メールアドレスとパスワードが一致しません。';

  @override
  String get accountTooManyAttempts => '試行回数が多すぎます。数分待ってからもう一度お試しください。';

  @override
  String get accountNeedsRecentLogin => '先にもう一度サインインしてください。';

  @override
  String get accountMethodNotEnabled =>
      '現在、メールでのサインインは利用できません。「Google で続行」をお試しください。';

  @override
  String get accountSessionUnavailable =>
      'サインインしましたが、進行状況はまだサーバーに保存されていません。接続が戻ると同期されます。';

  @override
  String get accountUnavailable => 'サーバーに接続できませんでした。進行状況はこの端末に安全に残っています。';

  @override
  String get accountUseThatAccount => 'そのアカウントを使う';

  @override
  String get accountExistingTitle => 'アカウントはすでにあります';

  @override
  String get accountExistingBodyEmpty => 'そのアカウントに保存された星がこのスマホに読み込まれます。';

  @override
  String accountExistingBodyLocal(int cleared) {
    String _temp0 = intl.Intl.pluralLogic(
      cleared,
      locale: localeName,
      other:
          'このスマホには、そのアカウントにないクリア済みレベルが$cleared個あります。統合はできないため、そのアカウントの内容に置き換わります。',
    );
    return '$_temp0';
  }

  @override
  String get accountSignIn => 'サインイン';

  @override
  String get accountSignInCancelled => 'サインインをキャンセルしました。変更はありません。';

  @override
  String get accountSignedInToast => 'サインインしました。新しいスマホでも星を引き継げます。';

  @override
  String get accountResetNeedsEmail =>
      '先にメールアドレスを入力してから、「パスワードをお忘れですか？」をタップしてください。';

  @override
  String get accountResetSent => 'このメールアドレスのアカウントがあれば、再設定用のリンクをお送りします。';

  @override
  String get accountYourAccount => 'あなたのアカウント';

  @override
  String accountRankValue(int rank) {
    return '$rank位';
  }

  @override
  String accountStreakValue(int days) {
    return '$days日';
  }

  @override
  String get accountCardTravels => 'このカードはアカウントと一緒に移るので、新しいスマホでも続きから遊べます。';

  @override
  String get accountYourNameHeader => '名前';

  @override
  String get accountChangeName => '名前を変更';

  @override
  String get accountChangeNameDetail => 'ランキングでの表示名';

  @override
  String get accountShowOnBoards => 'ランキングに表示する';

  @override
  String get accountShowOnBoardsDetail => 'オフで名前と順位を非表示。星は加算されます。';

  @override
  String get accountYourPlayHeader => 'プレイ';

  @override
  String get accountStatistics => '統計';

  @override
  String get accountStatisticsDetail => 'タイム、プレイ履歴、全レベルの記録';

  @override
  String get accountSessionHeader => 'セッション';

  @override
  String get accountDeleteHint => 'アカウントを削除するには、設定 → 危険な操作 へ。';

  @override
  String get accountVisibilityFailed => 'サーバーに接続できなかったため、変更されませんでした。';

  @override
  String get accountSignOutTitle => 'サインアウトしますか？';

  @override
  String get accountSignOutBody =>
      '進行状況はこのスマホに残ります。いつでもサインインし直して、別の端末で続きを遊べます。';

  @override
  String get accountStaySignedIn => 'サインインしたままにする';

  @override
  String get accountSignOut => 'サインアウト';

  @override
  String get accountSignOutDetail => '進行状況はこのスマホに残ります';

  @override
  String get accountSaveTitle => '進行状況を保存';

  @override
  String get accountSaveIntro =>
      '星、連続記録、ランキング名はアカウントと一緒に移るので、新しいスマホでも続きから遊べます。';

  @override
  String get accountContinueApple => 'Appleで続ける';

  @override
  String get accountContinueGoogle => 'Google で続行';

  @override
  String get accountOr => 'または';

  @override
  String get accountEmailLabel => 'メールアドレス';

  @override
  String get accountEmailEmpty => 'メールアドレスを入力してください。';

  @override
  String get accountPasswordLabel => 'パスワード';

  @override
  String get accountPasswordHelper => '8文字以上';

  @override
  String get accountPasswordEmpty => 'パスワードを入力してください。';

  @override
  String get accountPasswordShort => '8文字以上にしてください。';

  @override
  String get accountShowPassword => 'パスワードを表示';

  @override
  String get accountHidePassword => 'パスワードを隠す';

  @override
  String get accountCreate => 'アカウント作成';

  @override
  String get accountSwitchToSignIn => 'アカウントをお持ちですか？サインイン';

  @override
  String get accountSwitchToSignInSemantic => 'サインインに切り替える';

  @override
  String get accountSwitchToCreate => 'アカウントがない場合は作成';

  @override
  String get accountSwitchToCreateSemantic => 'アカウント作成に切り替える';

  @override
  String get accountForgotPassword => 'パスワードをお忘れですか？';

  @override
  String get accountForgotPasswordSemantic => 'パスワードを再設定';

  @override
  String get accountNaming => '名前を準備中…';

  @override
  String get accountSignedInLabel => 'サインイン済み';

  @override
  String accountPouringSince(String month, int year) {
    return '$year年$monthからプレイ';
  }

  @override
  String get accountPlayerCardTag => 'プレイヤーカード';

  @override
  String get accountStatSolved => 'クリア';

  @override
  String get accountStatStars => '星';

  @override
  String get accountStatStreak => '連続';

  @override
  String get accountStatRank => '順位';

  @override
  String accountStarsValue(int stars) {
    return '$stars★';
  }

  @override
  String get accountSyncing => '同期中…';

  @override
  String get accountSyncingDetail => '進行状況をアカウントに保存しています';

  @override
  String get accountWaitingToSync => '同期待ち';

  @override
  String get accountWaitingOffline => 'オンラインに戻ると保存されます';

  @override
  String get accountWaitingPending => '最新のレベルを次に送信します';

  @override
  String get accountSyncedDetail => '進行状況はアカウントに保存済みです';

  @override
  String get accountSynced => '同期済み';

  @override
  String get accountSyncedJustNow => 'たった今同期';

  @override
  String accountSyncedMinutesAgo(int minutes) {
    return '$minutes分前に同期';
  }

  @override
  String accountSyncedHoursAgo(int hours) {
    return '$hours時間前に同期';
  }

  @override
  String accountSyncedDaysAgo(int days) {
    return '$days日前に同期';
  }

  @override
  String get accountCrestSignedIn => 'あなたのアカウント';

  @override
  String get accountCrestGuest => 'ゲストでプレイ中';

  @override
  String get accountRenameRefused => 'その名前は使えませんでした。';

  @override
  String get accountRenameOffline => 'サーバーに接続できませんでした。少ししてからもう一度お試しください。';

  @override
  String get ranksTitle => 'ランキング';

  @override
  String get ranksTabToday => '今日';

  @override
  String get ranksTabCampaign => 'キャンペーン';

  @override
  String get ranksLoading => 'ランキングを取得中…';

  @override
  String get ranksEmptyDailyTitle => '今日の盤面をクリアした人はまだいません';

  @override
  String get ranksEmptyDailyDetail => '一番乗りしましょう。';

  @override
  String get ranksEmptyCampaignTitle => 'ランキング入りしたプレイヤーはまだいません';

  @override
  String get ranksEmptyCampaignDetail => '順位は星の数で決まります。';

  @override
  String get ranksYourSpot => 'あなたの順位';

  @override
  String ranksPlayerCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'このランキングには$countString人',
    );
    return '$_temp0';
  }

  @override
  String ranksMoves(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count手',
    );
    return '$_temp0';
  }

  @override
  String ranksStars(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '星$count個',
    );
    return '$_temp0';
  }

  @override
  String ranksLevels(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countレベル',
    );
    return '$_temp0';
  }

  @override
  String ranksInTime(String time) {
    return 'タイム $time';
  }

  @override
  String get ranksOpenSpot => '空き';

  @override
  String ranksNameYou(String name) {
    return '$name（あなた）';
  }

  @override
  String ranksPlaceOpen(int place) {
    return '$place位、空き';
  }

  @override
  String ranksPlaceSemantic(int rank, String name, String score) {
    return '$rank位、$name、$score';
  }

  @override
  String ranksScoreWithTieBreak(String score, String tieBreak) {
    return '$score、$tieBreak';
  }

  @override
  String get ranksOffTitle => 'このビルドではランキングは利用できません';

  @override
  String get ranksOffDetail => 'キャンペーンには影響ありません。';

  @override
  String get ranksLoadFailed => 'ランキングを読み込めませんでした';

  @override
  String get ranksOffline => 'オフラインのようです。すべてのレベルは接続なしでも遊べます。';

  @override
  String get ranksTimeout => 'サーバーの応答に時間がかかりすぎました。';

  @override
  String get ranksServerError => 'こちら側で問題が発生しました。進行状況は無事です。';

  @override
  String get ranksHiddenTitle => '非表示になっています';

  @override
  String get ranksHiddenDetail =>
      '星と連続記録はそのまま加算されます。ここに表示されないだけです。切り替えは設定からできます。';

  @override
  String get statsTitle => '統計';

  @override
  String get statsTabOverview => '概要';

  @override
  String get statsTabLevels => 'レベル';

  @override
  String get statsTabBadges => 'バッジ';

  @override
  String get statsPaceOnPar => 'パーちょうど';

  @override
  String statsPaceUnder(int percent) {
    return '$percent%速い';
  }

  @override
  String statsPaceOver(int percent) {
    return '$percent%遅い';
  }

  @override
  String get statsEmptyTitle => 'まだ記録がありません';

  @override
  String get statsEmptyBody => 'レベルをクリアすると、パーと比べたタイム、ベスト記録、プレイした日がここに表示されます。';

  @override
  String get statsBackToLevels => 'レベル一覧へ';

  @override
  String get statsLevelsSolved => 'クリアしたレベル';

  @override
  String get statsStars => '星';

  @override
  String get statsPoints => 'ポイント';

  @override
  String get statsPlayed => 'プレイ時間';

  @override
  String get statsNowOn => '現在地';

  @override
  String get statsBestSolveMoves => 'ベスト記録の合計手数';

  @override
  String get statsAgainstClock => 'タイム記録';

  @override
  String get statsNoTimes =>
      'まだタイムの記録がありません。時計の導入前にクリアしたレベルにはタイムがありません。もう一度プレイすると計測が始まります。';

  @override
  String get statsFastest => '最速';

  @override
  String get statsLongest => '最長';

  @override
  String get statsAvgPace => '平均ペース';

  @override
  String statsClockValue(String time, int level) {
    return '$time · Lv$level';
  }

  @override
  String statsUntimed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'クリア済みのうち$countレベルは時計の導入前にクリアしたため、タイムの記録がありません。',
    );
    return '$_temp0';
  }

  @override
  String statsUnderParSemantic(int under, int total) {
    return 'タイム記録のある$totalレベル中$underレベルがパー以内';
  }

  @override
  String get statsUnderParTag => 'パー以内';

  @override
  String get statsLast30Days => '過去30日';

  @override
  String statsStreakChip(int count) {
    return '$count日連続';
  }

  @override
  String get statsNoStreak => '連続なし';

  @override
  String statsDaysPlayed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count日プレイ',
    );
    return '$_temp0';
  }

  @override
  String statsLevelsFinished(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countレベルクリア',
    );
    return '$_temp0';
  }

  @override
  String statsBestStreak(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '最高$count日',
    );
    return '$_temp0';
  }

  @override
  String get statsToday => '今日';

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
      other: '$day · $countレベル',
    );
    return '$_temp0';
  }

  @override
  String statsBarNoPlay(String day) {
    return '$day · プレイなし';
  }

  @override
  String get statsWorldAhead => '未挑戦';

  @override
  String get statsWorldNoTimes => '記録なし';

  @override
  String statsWorldPoints(int points) {
    final intl.NumberFormat pointsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String pointsString = pointsNumberFormat.format(points);

    return '${pointsString}pt';
  }

  @override
  String statsWorldSolvedSemantic(String name, int cleared, int total) {
    return '$name：$total中$clearedクリア';
  }

  @override
  String statsWorldPaceSemantic(String pace) {
    return 'ペース $pace';
  }

  @override
  String statsWorldPointsSemantic(int points) {
    final intl.NumberFormat pointsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String pointsString = pointsNumberFormat.format(points);

    return '$pointsStringポイント';
  }

  @override
  String get statsColLevel => 'Lv';

  @override
  String get statsColStars => '星';

  @override
  String get statsColMoves => '手数';

  @override
  String get statsColTime => 'タイム';

  @override
  String get statsColPoints => 'pt';

  @override
  String statsMovesBestPossible(int moves, int best) {
    return '$moves手、最少$best手';
  }

  @override
  String statsMoves(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count手',
    );
    return '$_temp0';
  }

  @override
  String badgeUnlockedCount(int earned, int total) {
    return '$total個中$earned個を解除';
  }

  @override
  String get badgeUnlocked => '解除済み';

  @override
  String get badgeNotYet => '未解除';

  @override
  String badgeProgress(int shown, int target) {
    return '$target中$shown';
  }

  @override
  String badgeSemantic(String title, String description, String status) {
    return '$title：$description $status';
  }

  @override
  String get badgeFirstPourTitle => 'はじめの一杯';

  @override
  String get badgeFirstPourDesc => '最初のレベルをクリアする。';

  @override
  String get badgePar10Title => 'パーぴったり';

  @override
  String get badgePar10Desc => '10レベルをちょうどパーでクリアする。';

  @override
  String get badgePar50Title => 'パーの達人';

  @override
  String get badgePar50Desc => '50レベルをちょうどパーでクリアする。';

  @override
  String get badgeCleanClearTitle => 'やり直しなし';

  @override
  String get badgeCleanClearDesc => '「戻す」を使わずにレベルをクリアする。';

  @override
  String get badgeSpeedyTitle => 'スピード注ぎ';

  @override
  String get badgeSpeedyDesc => '30秒以内にレベルをクリアする。';

  @override
  String get badgeLevels100Title => '百戦錬磨';

  @override
  String get badgeLevels100Desc => '100レベルをクリアする。';

  @override
  String get badgeStars300Title => '星コレクター';

  @override
  String get badgeStars300Desc => '星を300個集める。';

  @override
  String get badgeWorldPerfectTitle => '完璧なワールド';

  @override
  String get badgeWorldPerfectDesc => '1つのワールドの全レベルで星3つを獲得する。';

  @override
  String get badgeStreak7Title => '1週間の注ぎ手';

  @override
  String get badgeStreak7Desc => '今日のパズルで7日連続を達成する。';

  @override
  String get badgeStreak30Title => '1か月の注ぎ手';

  @override
  String get badgeStreak30Desc => '今日のパズルで30日連続を達成する。';

  @override
  String get badgeChests5Title => '宝探し';

  @override
  String get badgeChests5Desc => 'スターチェストを5個開ける。';

  @override
  String get badgeHard5Title => '手ごわい相手';

  @override
  String get badgeHard5Desc => 'ハードレベルを5つクリアする。';

  @override
  String get badgeEventFullTitle => '1週間制覇';

  @override
  String get badgeEventFullDesc => 'ウィークリーイベントの7面すべてをクリアする。';

  @override
  String get badgeZen25Title => 'Zenの庭';

  @override
  String get badgeZen25Desc => 'Zenモードで25面クリアする。';

  @override
  String get commonCancel => 'キャンセル';

  @override
  String get commonClose => '閉じる';

  @override
  String get commonBack => '戻る';

  @override
  String get commonOk => 'OK';

  @override
  String get commonSave => '保存';

  @override
  String get commonRetry => '再試行';

  @override
  String get commonNotNow => '今はしない';

  @override
  String commonLevelN(int level) {
    return 'レベル$level';
  }

  @override
  String get hubAccountYours => 'あなたのアカウント';

  @override
  String get hubAccountSave => '進行状況を保存';

  @override
  String get hubPlayerFallback => 'プレイヤー';

  @override
  String get hubSettings => '設定';

  @override
  String get hubTagline => '注ぐ · 分ける · くつろぐ';

  @override
  String hubStatChipSemantic(String value, String label) {
    return '$label $value。統計';
  }

  @override
  String get hubStatSolved => 'クリア';

  @override
  String get hubStatStars => '星';

  @override
  String get hubStatStreak => '連続';

  @override
  String hubStreakDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count日',
    );
    return '$_temp0';
  }

  @override
  String hubRankNumber(int rank) {
    return '$rank位';
  }

  @override
  String hubEventSemantic(int cleared, int total) {
    return 'ウィークリーイベント、$total面中$cleared面';
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
    return '$cleared/$total · $rank位 · $timeLeft';
  }

  @override
  String get hubZen => 'Zen';

  @override
  String get hubZenSemantic => 'Zenモード';

  @override
  String hubZenLockedSemantic(int level) {
    return 'Zenモードはレベル$levelで解放';
  }

  @override
  String get hubZenOpen => 'エンドレス、時間制限なし';

  @override
  String hubZenLocked(int level, int remaining) {
    return 'レベル$level · あと$remaining';
  }

  @override
  String get hubDockJourney => '旅路';

  @override
  String get hubDockRankings => 'ランキング';

  @override
  String get hubDockStats => '統計';

  @override
  String get hubTip => 'いいですね！「旅路」ですべてのレベルを見られます。「今日のパズル」も毎日新しく登場します。';

  @override
  String hubHeroWorld(int world) {
    return 'ワールド$world';
  }

  @override
  String hubHeroWorldBand(int world, String band) {
    return 'ワールド$world · $band';
  }

  @override
  String hubHeroPar(int par) {
    return 'パー$par';
  }

  @override
  String get hubPlay => 'プレイ';

  @override
  String hubPlaySemantic(int level) {
    return 'レベル$levelをプレイ';
  }

  @override
  String get hubMoreUpdateTitle => 'アップデートで新レベル';

  @override
  String get hubMoreUpdateBody =>
      '新しいワールドが登場しました。最新のPourfectが必要です。アップデートして続きを楽しみましょう。';

  @override
  String get hubMoreDownloadingTitle => '新しいレベルを準備中';

  @override
  String get hubMoreDownloadingBody => '次のワールドをダウンロードしています。すぐに終わります。';

  @override
  String get hubMoreAllDoneTitle => '全レベルクリア！';

  @override
  String get hubMoreOfflineBody =>
      'インターネットに接続すると、新しいレベルがバックグラウンドでダウンロードされます。それまでは今日のパズルをどうぞ。';

  @override
  String get hubMoreOnlineBody =>
      'オンラインのときに、新しいレベルがバックグラウンドでダウンロードされます。それまでは今日のパズルをどうぞ。';

  @override
  String get hubMoreCheckAgain => 'もう一度確認';

  @override
  String hubAchievementOne(String title) {
    return '実績解除：$title';
  }

  @override
  String hubAchievementMany(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count個の実績を解除しました！',
    );
    return '$_temp0';
  }

  @override
  String get hubUpdateReady => 'アップデートをインストールできます。';

  @override
  String get hubUpdateRestart => '再起動';

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
    return '$hours時間';
  }

  @override
  String hubSpanHoursMinutes(int hours, int minutes) {
    return '$hours時間$minutes分';
  }

  @override
  String get hubParOn => 'パーちょうど';

  @override
  String hubParUnder(int percent) {
    return 'パーより$percent%速い';
  }

  @override
  String hubParOver(int percent) {
    return 'パーより$percent%遅い';
  }

  @override
  String get dailyTitle => '今日のパズル';

  @override
  String get dailyCardSemantic => '今日のチャレンジ';

  @override
  String get dailyCardUnavailable => '今日の盤面を取得できません';

  @override
  String get dailyCardSolved => 'クリア';

  @override
  String dailyCardNextIn(String time) {
    return '次まで $time';
  }

  @override
  String dailyCardEndsIn(String time) {
    return '残り $time';
  }

  @override
  String dailyStreakDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count日連続',
    );
    return '$_temp0';
  }

  @override
  String dailyStreakMilestone(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count日連続！',
    );
    return '$_temp0';
  }

  @override
  String get dailyRankSemantic => 'ランキング';

  @override
  String dailyRankSemanticRanked(int rank) {
    return 'ランキング、$rank位';
  }

  @override
  String get dailyRankSticker => '順位';

  @override
  String get dailyLeaveLost => '今日のパズルの手数は保存されません。今日中ならいつでも最初からプレイできます。';

  @override
  String get dailySubmitRefused => 'サーバーがこの結果を受け付けませんでした。';

  @override
  String get dailySubmitFailed => 'クリアしましたが、結果を送信できませんでした。あとでもう一度お試しください。';

  @override
  String get dailyHudLabel => '今日の';

  @override
  String get dailyHudValue => 'パズル';

  @override
  String get dailyDeadEndRestart => 'ここからはクリアできません。やり直して別の手を試しましょう。';

  @override
  String dailyDeadEndUndo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ここからはクリアできません。$count手戻せば立て直せます。',
    );
    return '$_temp0';
  }

  @override
  String get dailyActionRestart => 'やり直し';

  @override
  String dailyActionUndo(int count) {
    return '$count手戻す';
  }

  @override
  String get dailyNoHint => 'この局面ではヒントがありません。';

  @override
  String get dailyLoadingTitle => '今日の盤面を読み込み中';

  @override
  String get dailyOffTitle => 'このビルドでは今日のパズルを利用できません';

  @override
  String get dailyOffDetail => 'キャンペーンには影響ありません。すべてのレベルはこの端末に入っています。';

  @override
  String get dailyNoBoardTitle => '今日の盤面はありません';

  @override
  String get dailyNoBoardDetail =>
      '今日のチャレンジはサーバーから届きますが、接続できませんでした。キャンペーンはサーバーなしで遊べます。';

  @override
  String get dailyLoaderCaption => '今日の盤面を注いでいます…';

  @override
  String get dailyBackToLevels => 'レベル一覧へ';

  @override
  String dailyWeekSemantic(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count日',
    );
    return '連続記録：$_temp0。開く';
  }

  @override
  String dailyDaySemantic(String weekday, String state) {
    return '$weekday、$state';
  }

  @override
  String get dailyDayFrozen => '未プレイ、フリーズで保護';

  @override
  String get dailyDayPlayedToday => '今日プレイ済み';

  @override
  String get dailyDayPlayed => 'プレイ済み';

  @override
  String get dailyDayToday => '今日、まだ未プレイ';

  @override
  String get dailyDayMissed => '未プレイ';

  @override
  String get dailyDayFuture => 'これから';

  @override
  String get dailyOutcomeBest => '自己ベスト更新';

  @override
  String get dailyOutcomeSolved => 'クリア';

  @override
  String get dailyFigureMoves => '手数';

  @override
  String get dailyFigureStreak => '連続';

  @override
  String get dailyUnranked => '圏外';

  @override
  String dailyOfPlayers(int count) {
    return '/ $count人';
  }

  @override
  String get dailyReminderOn => '明日の夜に1回お知らせします。';

  @override
  String get dailyRemindMe => '明日お知らせ';

  @override
  String get dailyDone => '完了';

  @override
  String get dailyFreezeVideoUnfinished => '動画が最後まで再生されなかったため、フリーズは追加されません。';

  @override
  String get dailyFreezeNoVideo => '現在、再生できる動画がありません。';

  @override
  String get dailyFreezeError => '問題が発生しました。あとでもう一度お試しください。';

  @override
  String get dailyFreezeAdded => 'フリーズを追加しました。1日休んでも大丈夫です。';

  @override
  String get dailyFreezeNoRoom => '今日はこれ以上フリーズを追加できません。';

  @override
  String get dailyFreezeLoadingVideo => '動画を読み込み中…';

  @override
  String get dailyFreezeWatch => '動画を見てフリーズをもらう';

  @override
  String get dailyFreezesFull => 'フリーズは上限です。1つで1日分の休みを守ります。';

  @override
  String get dailyFreezeTomorrow => '動画でもらえるフリーズは1日1つ。また明日どうぞ。';

  @override
  String get dailyStreakTitle => '連続記録';

  @override
  String get dailyStreakNone => '連続記録はまだありません';

  @override
  String get dailyStreakStart => '今日のパズルをプレイして始めましょう。';

  @override
  String dailyStreakBest(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '最高：$count日',
    );
    return '$_temp0';
  }

  @override
  String dailyFreezesSemantic(int count, int max) {
    return '連続記録フリーズ $max個中$count個';
  }

  @override
  String get dailyFreezesTitle => '連続記録フリーズ';

  @override
  String get dailyFreezesEach => '1つで1日分の休みを守ります。';

  @override
  String dailyFreezeWeekly(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '毎週月曜に1つ無料。次は$days日後です。',
      one: '毎週月曜に1つ無料。次は明日です。',
    );
    return '$_temp0';
  }

  @override
  String get dailyCalendarPrevious => '前の月';

  @override
  String get dailyCalendarNext => '次の月';

  @override
  String dailyCalendarCellSemantic(String date, String state) {
    return '$date、$state';
  }

  @override
  String get dailyCalendarPlayed => 'プレイ済み';

  @override
  String get dailyCalendarFrozen => 'フリーズ';

  @override
  String get dailyCalendarFuture => 'これから';

  @override
  String get dailyLegendPlayed => 'プレイ';

  @override
  String get dailyLegendFrozen => 'フリーズ';

  @override
  String get dailyLegendToday => '今日';

  @override
  String get eventTitle => 'ウィークリーイベント';

  @override
  String get eventUnreachable => '今週のイベントに接続できません。';

  @override
  String get eventEnded => '終了';

  @override
  String eventEndsIn(String timeLeft) {
    return '残り $timeLeft';
  }

  @override
  String eventTimeLeftDaysHours(int days, int hours) {
    return '$days日$hours時間';
  }

  @override
  String eventTimeLeftHours(int hours) {
    return '$hours時間';
  }

  @override
  String eventTimeLeftMinutes(int minutes) {
    return '$minutes分';
  }

  @override
  String eventSummary(int cleared, int total, String endsIn) {
    return '$total面中$cleared面 · $endsIn';
  }

  @override
  String get eventFigurePoints => 'ポイント';

  @override
  String eventRankOf(int count) {
    return '/ $count人';
  }

  @override
  String get eventRankPlay => 'プレイして順位に参加';

  @override
  String get eventRankSetName => '名前を設定して参加';

  @override
  String eventTileSemanticDone(int slot, int stars, int points) {
    String _temp0 = intl.Intl.pluralLogic(
      stars,
      locale: localeName,
      other: '星$starsつ',
    );
    return 'ボード$slot、$_temp0、$pointsポイント';
  }

  @override
  String eventTileSemanticNew(int slot) {
    return 'ボード$slot、未プレイ';
  }

  @override
  String eventTilePoints(int points) {
    return '${points}pt';
  }

  @override
  String get eventStandingsTitle => '今週のランキング';

  @override
  String get eventStandingsEmpty => 'まだ誰もいません。一番乗りしましょう。';

  @override
  String eventStandingsCleared(int cleared) {
    return ' · $cleared/7';
  }

  @override
  String get eventSubmitRefused => 'サーバーがこの結果を受け付けませんでした。イベントが終了した可能性があります。';

  @override
  String get eventSubmitFailed => 'クリアしましたが、結果を送信できませんでした。もう一度お試しください。';

  @override
  String eventDeadEndUndo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ここからはクリアできません。$count手戻しましょう。',
    );
    return '$_temp0';
  }

  @override
  String get eventNoHint => '今はこの局面のヒントがありません。';

  @override
  String get eventHudLabel => 'ボード';

  @override
  String eventHudBand(String event, String endsIn) {
    return '$event · $endsIn';
  }

  @override
  String get eventSending => '送信中…';

  @override
  String eventResult(int points, int total) {
    return '$pointsポイント · 今週$total';
  }

  @override
  String eventResultRanked(int points, int total, int rank) {
    return '$pointsポイント · 今週$total · $rank位';
  }

  @override
  String get journeyTitle => '旅路';

  @override
  String journeyStarsSemantic(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '星$count個',
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
    return 'ワールド$world/$worlds、$name、$totalレベル中$solvedクリア';
  }

  @override
  String journeyWorldOf(int world, int worlds) {
    return 'ワールド $world/$worlds';
  }

  @override
  String journeyRibbonSemantic(int world, String name, int solved, int total) {
    return 'ワールド$world、$name、$totalレベル中$solvedクリア。そこへスクロール';
  }

  @override
  String journeyRibbonLabel(int world, String name) {
    return 'ワールド$world · $name';
  }

  @override
  String get journeyYouPin => 'いま';

  @override
  String journeyBandCaps(int world, int count) {
    return 'ワールド$world · $count';
  }

  @override
  String get journeyBandFirstPours => 'はじめの一歩';

  @override
  String get journeyBandFindingRhythm => 'リズムをつかむ';

  @override
  String get journeyBandDeepWater => '深みへ';

  @override
  String get journeyBandMastery => 'マスター';

  @override
  String get notifSoftAskTitle => 'お知らせを受け取りますか？';

  @override
  String get notifSoftAskBody =>
      '今日のパズルが届いたときや、次のレベルが待っているときにお知らせします。1日2回まで。設定からいつでもオフにできます。';

  @override
  String get notifSoftAskBodyDenied =>
      'Pourfectの通知がオフになっています。端末の設定でオンにすると、今日のパズルや新しいワールドが届いたときにお知らせします。1日2回までです。';

  @override
  String get notifSoftAskOpenSettings => '設定を開く';

  @override
  String get notifSoftAskYes => '受け取る';

  @override
  String get notifChannelName => 'リマインダー';

  @override
  String get notifChannelDescription => '今日のパズル、次のレベル、新しいワールドのお知らせ。1日2回まで。';

  @override
  String get playHudLevel => 'レベル';

  @override
  String playHudTitle(String label, String value) {
    return '$label $value';
  }

  @override
  String get playHudHard => 'ハード ×1.5';

  @override
  String get playHudHardLabel => 'ハードレベル、ポイント1.5倍';

  @override
  String get playHudMoves => '手数';

  @override
  String playHudMovesLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count手',
    );
    return '$_temp0';
  }

  @override
  String playParLeftFor3Stars(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '星3つまであと$count手',
    );
    return '$_temp0';
  }

  @override
  String get playParSpent => 'パー到達 · ここからは星2つ';

  @override
  String playParLeftFor2Stars(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '星2つまであと$count手',
    );
    return '$_temp0';
  }

  @override
  String get playParOneStarFromHere => 'ここからは星1つ · クリアで獲得';

  @override
  String get playParAnyFinish => 'クリアすれば星1つ獲得';

  @override
  String playParMeterLabel(int stars, int used, int par, String words) {
    return '星$starsつペース、パー$par手中$used手。$words';
  }

  @override
  String playHudBusyLabel(String label) {
    return '$label、処理中。タップでキャンセル';
  }

  @override
  String get playHudUndo => '戻す';

  @override
  String get playHudHint => 'ヒント';

  @override
  String get playHudRestart => 'やり直し';

  @override
  String get playExtraTubeLabel => '動画を見てチューブを1本追加';

  @override
  String get playExtraTubeChip => '+ チューブ';

  @override
  String playStarsOfTotal(int earned, int total) {
    return '星$totalつ中$earnedつ';
  }

  @override
  String get playDismiss => '閉じる';

  @override
  String get playLeaveTitleSoSoon => 'もう行っちゃいますか？';

  @override
  String get playLeaveTitleMissYou => 'ボールたちが寂しがります';

  @override
  String get playLeaveTitleAbandon => '注ぐのをやめますか？';

  @override
  String get playLeaveTitleMidPour => '途中でやめちゃいますか？';

  @override
  String get playLeaveBody => 'この盤面の手数と時間は保存されません。';

  @override
  String get playLeaveKeepPouring => '続ける';

  @override
  String get playLeaveConfirm => 'やめる';

  @override
  String get playTutorialSkipLabel => 'チュートリアルをスキップ';

  @override
  String get playTutorialSkip => 'スキップ';

  @override
  String playTipBubbleLabel(String text) {
    return '$text。閉じる';
  }

  @override
  String get playTipPar => 'パー以内でクリアすると星3つ。バーで使った手数がわかります。';

  @override
  String get playTipTallTubes => '背の高いチューブ！1本にボールが5個入ります。';

  @override
  String get playTipHint => '行き詰まりましたか？ヒントで良い次の一手がわかります。';

  @override
  String get playTipUndo => 'パーを超えましたか？「戻す」は無料です。好きなだけ戻れます。';

  @override
  String get playGuideSorted => 'そろいました！すべてのチューブを1色にしましょう。';

  @override
  String get playGuideDrop => '次は注ぐ先をタップ。同じ色の上か、空のチューブへ。';

  @override
  String get playGuideWrongTube => '手が指しているチューブをタップして、そちらを持ち上げましょう。';

  @override
  String get playGuideFirstTap => 'チューブをタップして、いちばん上のボールを持ち上げましょう。';

  @override
  String get playGuideFirstPour => '注げました！その調子です。';

  @override
  String get playGuideKeepGoing => 'その調子。1本に1色です。';

  @override
  String playCoachHolding(int count) {
    return '$count個持っています · はねているチューブへ';
  }

  @override
  String get playExtraTubeAdTitle => '動画を見てチューブを追加しますか？';

  @override
  String get playExtraTubeAdBody =>
      'このレベルで空のチューブが1本増えます。追加チューブを使ってクリアした場合、星は最大2つです。';

  @override
  String get playExtraTubeNotFinished => '動画が最後まで再生されなかったため、チューブは追加されません。';

  @override
  String get playExtraTubeSaved => '保存しました。次のチューブは無料です。';

  @override
  String get playNoVideo => '現在、再生できる動画がありません。';

  @override
  String get playRewardFailed => '問題が発生しました。何も消費されていません。';

  @override
  String get playHintShowing => 'ヒントを表示中です。光っているチューブに注ぎましょう。';

  @override
  String get playHintNoneNothingUsed => 'この局面ではヒントがありません。何も消費されていません。';

  @override
  String get playHintNotFinished => '動画が最後まで再生されなかったため、ヒントはありません。';

  @override
  String get playHintVideoSaved => '視聴した動画は次のヒント用に保存されました。';

  @override
  String get playHintNoneVideoSaved => 'この局面ではヒントがありません。視聴した動画は次回用に保存されました。';

  @override
  String get playHintNone => 'この局面で使えるヒントはありません。';

  @override
  String get playHintHere => 'ヒントです。光っているチューブに注ぎましょう。';

  @override
  String get playDeadEndRestart => 'ここからはクリアできません。やり直して別の手を試しましょう。';

  @override
  String get playDeadEndRestartTube =>
      'ここからはクリアできません。やり直して別の手を試しましょう。または「+ チューブ」で予備のチューブを使えます。';

  @override
  String playDeadEndUndo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ここからはクリアできません。$count手戻せば立て直せます。',
    );
    return '$_temp0';
  }

  @override
  String playDeadEndUndoTube(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ここからはクリアできません。$count手戻せば立て直せます。または「+ チューブ」で予備のチューブを使えます。',
    );
    return '$_temp0';
  }

  @override
  String playDeadEndUndoAction(int count) {
    return '$count手戻す';
  }

  @override
  String get playHintAdTitle => '動画を見てヒントをもらいますか？';

  @override
  String playHintAdFreeLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '無料ヒントは残り$count回です。',
    );
    return '$_temp0';
  }

  @override
  String get playHintAdNoneLeft => '無料ヒントを使い切りました。短い動画を見るともう1回もらえます。';

  @override
  String get playWatch => '見る';

  @override
  String get playLoadFailed => 'レベルを読み込めませんでした';

  @override
  String get playTubeSorted => '完成！';

  @override
  String get playWinTitlePerfect => 'パーフェクト\nクリア！';

  @override
  String get playWinTitleNice => 'ナイス\nクリア！';

  @override
  String get playWinTitlePoured => 'クリア！';

  @override
  String get playWinLastPour => '最後のひと注ぎ…';

  @override
  String playWinMovesPar(int count, int par) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count手 · パー$par',
    );
    return '$_temp0';
  }

  @override
  String playWinLevelBand(int level, String band) {
    return 'レベル$level · $band';
  }

  @override
  String get playWinNewBest => '自己ベスト！';

  @override
  String playWinMovesChip(int par) {
    return '手数 · パー$par';
  }

  @override
  String get playWinUntimed => '計測なし';

  @override
  String get playWinFastest => '最速記録！';

  @override
  String get playWinTime => 'タイム';

  @override
  String get playWinUnderPar => 'パー以内！';

  @override
  String get playWinPoints => 'ポイント';

  @override
  String playWinWorldBand(int world, String band) {
    return 'ワールド$world · $band';
  }

  @override
  String get playWinTryAssisted => '星3つには、追加チューブなしでのクリアが必要です。';

  @override
  String playWinTryShort(int par, int took, int short) {
    String _temp0 = intl.Intl.pluralLogic(
      short,
      locale: localeName,
      other: 'パー$par、$took手でクリア。3★まであと$short手です。',
    );
    return '$_temp0';
  }

  @override
  String playWinTryInReach(int par) {
    return 'パー$par。星3つはもうすぐです。';
  }

  @override
  String get playWinTryButton => '3★をめざす';

  @override
  String get playWinTryButtonLabel => '星3つをめざしてこのレベルをもう一度プレイ';

  @override
  String get playWinReplayLabel => 'このレベルをもう一度プレイ';

  @override
  String get playWinHomeLabel => 'ホーム画面に戻る';

  @override
  String get playWinNextLevel => '次のレベル';

  @override
  String get playWinBackToLevels => 'レベル一覧へ';

  @override
  String playChestNextAtLabel(int stars) {
    return '次のスターチェストは星$stars個で獲得';
  }

  @override
  String get playChestOpenLabel => 'スターチェストを開ける';

  @override
  String get playChestReady => 'スターチェストを開けられます！';

  @override
  String playChestNextAt(int stars) {
    return '次のチェスト：$stars ★';
  }

  @override
  String get playChestOpen => '開ける';

  @override
  String get playChestDoubleFailed => '今回は2倍にできませんでした。';

  @override
  String get playChestDoubleNotFinished => '動画が最後まで再生されなかったため、2倍になりませんでした。';

  @override
  String get playChestOpening => '開けています…';

  @override
  String playChestTitle(int index) {
    return 'スターチェスト $index';
  }

  @override
  String get playChestNotYetTitle => 'もう少しです';

  @override
  String get playChestAlreadyOpenTitle => '開封済み';

  @override
  String get playChestFailedTitle => '開けられませんでした';

  @override
  String get playChestNotYetNote => '最新の星をサーバーに送信中です。少ししてからもう一度お試しください。';

  @override
  String get playChestAlreadyOpenNote => 'このチェストは別の端末で開けられました。';

  @override
  String get playChestFailedNote => '接続を確認して、もう一度お試しください。';

  @override
  String playChestRewardCount(int count) {
    return '+$count';
  }

  @override
  String playChestHintsCaption(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ヒント',
    );
    return '$_temp0';
  }

  @override
  String playChestTubesCaption(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '追加チューブ',
    );
    return '$_temp0';
  }

  @override
  String playChestUnlocked(String name) {
    return '解放：$name';
  }

  @override
  String playChestBallSkinName(String skin) {
    return 'ボールスキン「$skin」';
  }

  @override
  String playChestTubeThemeName(String theme) {
    return 'チューブ「$theme」';
  }

  @override
  String get playChestNewLook => '新しい見た目';

  @override
  String get playChestSavedNote =>
      '必要なときのために取っておかれます。「ヒント」と「+ チューブ」ではこちらが先に使われます。';

  @override
  String get playChestLoadingVideo => '動画を読み込み中…';

  @override
  String get playChestDouble => '動画を見て2倍にする';

  @override
  String get playChestCollect => '受け取る';

  @override
  String playClockLabel(String time) {
    return 'タイム $time';
  }

  @override
  String playClockDetailLabel(
    String time,
    String par,
    String sign,
    int percent,
  ) {
    String _temp0 = intl.Intl.selectLogic(sign, {
      'plus': 'プラス',
      'other': 'マイナス',
    });
    return 'タイム $time、パー $par、ポイント$_temp0$percentパーセント';
  }

  @override
  String playClockBonusChip(String sign, int percent) {
    return '$sign$percent% pt';
  }

  @override
  String get playLoading => '読み込み中';

  @override
  String get playWorking => '処理中';

  @override
  String get playZenTitle => 'Zen';

  @override
  String get playZenIntro => '終わりのない盤面。時計も星もランキングもなし。ただ注ぐだけ。';

  @override
  String get playZenPaceCalm => 'おだやか';

  @override
  String get playZenPaceSteady => 'じっくり';

  @override
  String get playZenPaceDeep => 'どっぷり';

  @override
  String playZenPaceColors(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count色',
    );
    return '$_temp0';
  }

  @override
  String playZenPaceLabel(String pace, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$pace、$count色',
    );
    return '$_temp0';
  }

  @override
  String playZenBandPoured(String pace, int count) {
    return '$pace · $count面クリア';
  }

  @override
  String playZenPoured(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'クリア！これまでに$count面です。',
      one: 'クリア！',
    );
    return '$_temp0';
  }

  @override
  String get playZenNext => '次へ';

  @override
  String get playZenLeaveBody => 'この盤面の手数は保存されません。クリア数はそのまま残ります。';

  @override
  String get playZenDeadEnd => 'ここからはクリアできません。戻すか、やり直しましょう。';

  @override
  String get playZenNoHint => '今はこの局面のヒントがありません。';

  @override
  String get settingsTitle => '設定';

  @override
  String get settingsSectionFeel => '操作感';

  @override
  String get settingsSectionVisibility => '見やすさ';

  @override
  String get settingsSectionLeaderboard => 'ランキング';

  @override
  String get settingsSectionNotifications => '通知';

  @override
  String get settingsSectionSupport => 'サポート';

  @override
  String get settingsSectionAccount => 'アカウントと情報';

  @override
  String get settingsSectionDanger => '危険な操作';

  @override
  String get settingsSoundTitle => '効果音';

  @override
  String get settingsSoundDetail => '注ぐ音、ボタン、ごほうび';

  @override
  String get settingsSoundVolume => '効果音の音量';

  @override
  String get settingsMusicTitle => '音楽';

  @override
  String get settingsMusicDetail => 'あなたの音楽を止めることはありません';

  @override
  String get settingsMusicVolume => '音楽の音量';

  @override
  String get settingsHapticsTitle => '振動';

  @override
  String get settingsHapticsDetail => 'ボールが着地するたびに軽く振動';

  @override
  String get settingsSmoothMotionTitle => 'なめらかな動き';

  @override
  String get settingsSmoothMotionAuto => '自動';

  @override
  String get settingsSmoothMotion60 => '60 Hz';

  @override
  String get settingsSmoothMotionMax => '最大';

  @override
  String get settingsMotionUnknown => '自動では、スマホが対応できれば画面の最高レートを使います';

  @override
  String settingsMotionFixed(String max) {
    return 'この画面は$max Hzのみで動作します';
  }

  @override
  String settingsMotionBatterySaver(String current) {
    return '省電力モードにより$current Hzに制限されています';
  }

  @override
  String settingsMotionAutoStuttered(String current, String max) {
    return '$current Hzで動作中 · $max Hzではカクつきました';
  }

  @override
  String settingsMotionAuto(String current) {
    return '$current Hzで動作中 · カクつくと60 Hzに下げます';
  }

  @override
  String settingsMotionPinnedByPhone(String current) {
    return 'スマホの画面設定により$current Hzに固定されています';
  }

  @override
  String settingsMotionStandard(String current, String max) {
    return '$current Hzで動作中 · この画面は$max Hzまで対応';
  }

  @override
  String settingsMotionMax(String current) {
    return '$current Hzで動作中、この画面の最高レートです';
  }

  @override
  String get settingsBoldSymbolsTitle => '太い記号';

  @override
  String get settingsBoldSymbolsDetail => '色覚多様性（色弱）向けに形をくっきり表示';

  @override
  String get settingsRenameTitle => '名前を変更';

  @override
  String get settingsRenameDetail => 'ランキングでの表示名';

  @override
  String get settingsShowOnBoardsTitle => 'ランキングに表示する';

  @override
  String get settingsShowOnBoardsDetail => 'オフで名前と順位を非表示。星は加算されます。';

  @override
  String get settingsHowToPlayTitle => '遊び方';

  @override
  String get settingsHowToPlayDetail => 'ガイド付きの最初のレベルをもう一度';

  @override
  String get settingsQuestionsTitle => 'よくある質問';

  @override
  String get settingsQuestionsDetail => '星、ヒント、時計など';

  @override
  String get settingsRateTitle => 'Pourfectを評価';

  @override
  String get settingsRateDetail => '感想をほかのプレイヤーに伝えましょう';

  @override
  String get settingsCollectionTitle => 'コレクション';

  @override
  String get settingsCollectionDetail => 'ボールスキンとチューブテーマ';

  @override
  String get settingsRestoreTitle => '購入を復元';

  @override
  String get settingsRestoreDetail => '広告削除またはスキンパック';

  @override
  String get settingsRestoreDone => '購入履歴があれば復元しました。';

  @override
  String get settingsRemoveAdsTitle => '広告を削除';

  @override
  String get settingsRemoveAdsDetail => 'レベル間の広告なし。ヒント動画は残ります。';

  @override
  String get settingsAdsRemoved => '広告削除済み、ありがとうございます';

  @override
  String get settingsPurchaseThanks => 'ありがとうございます。レベル間の広告はオフになりました。';

  @override
  String get settingsPurchaseAlreadyOwned => '購入済みです。広告はオフです。';

  @override
  String get settingsPurchasePending => '支払い処理中です。完了すると広告がオフになります。';

  @override
  String get settingsStoreUnavailable => '現在、この端末ではストアを利用できません。';

  @override
  String get settingsPurchaseFailed => '購入が完了しませんでした。料金は請求されていません。';

  @override
  String get settingsStoreOpenFailed => 'ストアを開けませんでした。';

  @override
  String get settingsBrowserOpenFailed => 'ブラウザを開けませんでした。';

  @override
  String get settingsSignedIn => 'サインイン済み';

  @override
  String get settingsSignedInDetail => '進行状況を引き継げます';

  @override
  String get settingsSaveProgressTitle => '進行状況を保存';

  @override
  String get settingsSaveProgressDetail => 'スマホを替えても星を引き継げます';

  @override
  String get settingsPrivacyPolicy => 'プライバシーポリシー';

  @override
  String get settingsTermsAndLicenses => '規約とライセンス';

  @override
  String get settingsTermsOfUse => '利用規約';

  @override
  String get settingsRefundPolicy => '返金ポリシー';

  @override
  String get settingsOpenSourceLicenses => 'オープンソースライセンス';

  @override
  String get settingsAdPrivacyTitle => '広告のプライバシー設定';

  @override
  String get settingsAdPrivacyDetail => '広告に関する同意内容を変更';

  @override
  String get settingsResetRowTitle => '進行状況をリセット';

  @override
  String get settingsResetRowDetail => 'すべての星を消してレベル1から始める';

  @override
  String get settingsResetTitle => '進行状況をリセットしますか？';

  @override
  String get settingsResetNothing => 'リセットするものはまだありません。';

  @override
  String settingsResetBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'クリア済みの$countレベルの星とベスト記録がすべて消え、レベル1以降が再びロックされます。元に戻すことはできません。',
    );
    return '$_temp0';
  }

  @override
  String get settingsKeepIt => 'やめておく';

  @override
  String get settingsResetConfirm => 'すべて消去';

  @override
  String get settingsResetDone => '進行状況をリセットしました。';

  @override
  String get settingsSignOutTitle => 'サインアウトしますか？';

  @override
  String get settingsSignOutBody =>
      '進行状況はこのスマホに残ります。いつでもサインインし直して、別の端末で続きを遊べます。';

  @override
  String get settingsSignOutStay => 'サインインしたままにする';

  @override
  String get settingsSignOutConfirm => 'サインアウト';

  @override
  String get settingsServerUnreachable => 'サーバーに接続できなかったため、変更されませんでした。';

  @override
  String get settingsDeleteRowTitle => 'アカウントを削除';

  @override
  String get settingsDeleteRowDetail => 'アカウントと関連データをすべて削除';

  @override
  String get settingsDeleteTitle => 'アカウントを削除しますか？';

  @override
  String get settingsDeleteBody =>
      'アカウント、星、連続記録、ランキングの記録が、このスマホとサーバーの両方から削除されます。元に戻すことはできません。\n\n「広告を削除」には影響しません。購入したストアのアカウントに紐づいているため、再びプレイすると復元されます。';

  @override
  String get settingsDeleteConfirm => 'すべて削除';

  @override
  String get settingsDeleteServerRefused =>
      'サーバーに接続できませんでした。何も削除されていません。オンラインに戻ってからもう一度お試しください。';

  @override
  String get settingsDeleteNotAuthenticated =>
      'ご本人確認ができませんでした。もう一度サインインしてからアカウントを削除してください。まだ何も削除されていません。';

  @override
  String settingsFooterVersion(String version) {
    return 'Pourfect $version';
  }

  @override
  String settingsFooterVersionBoards(int count, String version) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Pourfect $version · クリア可能と証明済みの$count面を収録',
    );
    return '$_temp0';
  }

  @override
  String get settingsNamingYou => '名前を準備中…';

  @override
  String get settingsYourName => '名前';

  @override
  String get settingsGuest => 'ゲストでプレイ中';

  @override
  String get settingsStatSolved => 'クリア';

  @override
  String get settingsStatStars => '星';

  @override
  String get settingsNotifyTurnOnTitle => '通知をオンにする';

  @override
  String get settingsNotifyDeniedDetail => 'スマホの設定でオフです。タップで開きます。';

  @override
  String get settingsNotifyNotYetDetail => 'Pourfectはまだ通知できません';

  @override
  String get settingsRemindersTitle => '今日のパズルのリマインダー';

  @override
  String get settingsRemindersDetail => '朝と夜に、1日2回まで';

  @override
  String get settingsNewsTitle => 'ゲームのお知らせ';

  @override
  String get settingsNewsDetail => '新しいワールドとお知らせ';

  @override
  String settingsToggleOn(String title) {
    return '$title、オン';
  }

  @override
  String settingsToggleOff(String title) {
    return '$title、オフ';
  }

  @override
  String get settingsFaqSectionPlaying => 'プレイ';

  @override
  String get settingsFaqSectionStuck => '行き詰まったら';

  @override
  String get settingsFaqSectionProgress => '進行状況';

  @override
  String get settingsFaqSectionAds => '広告とサウンド';

  @override
  String get settingsFaqHowToPlayQ => '遊び方は？';

  @override
  String get settingsFaqHowToPlayA =>
      'チューブをタップして上のボールを持ち上げ、別のチューブをタップして注ぎます。ボールは同じ色の上か、空のチューブにしか入りません。すべてのチューブを1色にそろえればクリアです。設定 → 遊び方 で、ガイド付きの最初のレベルをもう一度遊べます。';

  @override
  String get settingsFaqStarsQ => '星の意味は？';

  @override
  String get settingsFaqStarsA =>
      '星は手数だけで決まります。パー以内なら星3つ、パーの1.5倍以内なら星2つ、クリアすれば星1つです。パーとは、そのレベルをクリアできる最少の手数です。';

  @override
  String get settingsFaqClockQ => '時間がかかると星が減りますか？';

  @override
  String get settingsFaqClockA =>
      '減りません。時間で変わるのはポイントだけです。タイムのパーより早ければボーナスポイント。ゆっくり遊んでも星はそのままです。';

  @override
  String get settingsFaqSolvableQ => 'すべてのレベルはクリアできますか？';

  @override
  String get settingsFaqSolvableA =>
      'はい。すべての盤面は配信前に解かれていて、パーはその解き方から決まっているので、必ず達成できます。';

  @override
  String get settingsFaqDailyQ => '今日のパズルとは？';

  @override
  String get settingsFaqDailyA =>
      '毎日新しい盤面が登場し、専用のランキングがあります。インターネット接続が必要です。キャンペーンのレベルは接続なしで遊べます。';

  @override
  String get settingsFaqUndoQ => '「戻す」に回数制限はありますか？';

  @override
  String get settingsFaqUndoA => 'ありません。「戻す」はどのレベルでも無料で無制限です。';

  @override
  String get settingsFaqHintsQ => 'ヒントの仕組みは？';

  @override
  String settingsFaqHintsA(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '最初の$count回のヒントは無料です。その後は短い動画を見るともらえます。ヒントが見つからなかった場合でも、視聴した動画は次のヒントに使えます。',
    );
    return '$_temp0';
  }

  @override
  String get settingsFaqTubeQ => '「+ チューブ」ボタンとは？';

  @override
  String get settingsFaqTubeA =>
      '手数がパーに達したときや、ヒントでクリアできないとわかったときに、動画を見て空のチューブを追加できます（1回の挑戦で2本まで）。「戻す」を使っても消えません。追加チューブを使ってクリアした場合、星は最大2つです。';

  @override
  String get settingsFaqHardQ => 'ハードレベルとは？';

  @override
  String get settingsFaqHardA =>
      '10レベルごとに最も難しいレベルには、赤い「ハード」バッジが付きます。遊び方はほかのレベルと同じで、ポイントは1.5倍です。';

  @override
  String get settingsFaqChestsQ => 'スターチェストとは？';

  @override
  String get settingsFaqChestsA =>
      '星30個ごとに、旅路でチェストが1つ開きます。中身はヒント2回と追加チューブ1本で、必要なときまで取っておけます。3つ目ごとのチェストではボールスキンも解放されます。';

  @override
  String get settingsFaqFreezeQ => '連続記録フリーズとは？';

  @override
  String get settingsFaqFreezeA =>
      '今日のパズルを1日休んでも、フリーズがその日を守って連続記録が続きます。毎週月曜に1つ無料でもらえ、動画で1日1つ獲得でき、最大2つまで持てます。';

  @override
  String get settingsFaqAccountQ => 'アカウントは必要ですか？';

  @override
  String get settingsFaqAccountA =>
      'いいえ。ゲストとして遊べて、進行状況はこのスマホに保存されます。サインインすると、新しいスマホに替えても星を引き継げます。';

  @override
  String get settingsFaqOfflineQ => 'オフラインで遊べますか？';

  @override
  String get settingsFaqOfflineA =>
      'はい、キャンペーンはすべて遊べます。今日のパズルとランキングには接続が必要で、進行状況はオンラインに戻ると同期されます。';

  @override
  String get settingsFaqNameQ => 'ランキングの名前を変えるには？';

  @override
  String get settingsFaqNameA =>
      '設定 → 名前を変更 から変えられます。そこでランキングから自分を非表示にすることもできます。星はそのまま加算されます。';

  @override
  String get settingsFaqRemoveAdsQ => '「広告を削除」で何が変わりますか？';

  @override
  String get settingsFaqRemoveAdsA =>
      'レベル間の広告がオフになります。ヒントとチューブの動画は残ります。これらは自分で選んだときにだけ表示されるからです。';

  @override
  String get settingsFaqReinstallQ => '再インストールしたら「広告を削除」が消えました';

  @override
  String get settingsFaqReinstallA =>
      '購入したストアのアカウントに紐づいているので、通常は自動で戻ります。戻らない場合は、設定 → 購入を復元 をタップしてください。';

  @override
  String get settingsFaqMusicQ => 'ゲームで音楽が止まりますか？';

  @override
  String get settingsFaqMusicA =>
      '止まりません。Pourfectのサウンドは、音楽やポッドキャストと一緒に流れます。効果音と振動は設定でオフにできます。';

  @override
  String get settingsLegalTitle => '注ぐ前に';

  @override
  String get settingsLegalIntro =>
      'Pourfectは無料で、オフラインでも遊べて、アカウントも不要です。まずは以下をお読みのうえ、同意してください。';

  @override
  String settingsLegalAcceptTerms(String document) {
    return '$documentに同意します';
  }

  @override
  String settingsLegalReadPrivacy(String document) {
    return '$documentを読みました';
  }

  @override
  String settingsLegalAlsoCovers(String document, String version) {
    return '同意すると、$document（バージョン$version）にも同意したことになります。';
  }

  @override
  String get settingsLegalPrivacyPolicy => 'プライバシーポリシー';

  @override
  String get settingsLegalTermsOfService => '利用規約';

  @override
  String get settingsLegalRefundPolicy => '返金ポリシー';

  @override
  String settingsLegalReadDocument(String document) {
    return '$documentを読む';
  }

  @override
  String get settingsLegalAccept => 'さあ、注ごう！';

  @override
  String get settingsLegalReadAgain => 'これらは設定からいつでも読み返せます。';

  @override
  String get settingsLegalLoadFailed =>
      'この端末ではこの文書を読み込めませんでした。\n\n同意する前に legal.pranta.dev でお読みいただけます。';

  @override
  String get settingsUpdateTitle => '新しいPourfectの準備ができました';

  @override
  String get settingsUpdateBody =>
      'Google Playがダウンロードし、完了するとゲームを再び開きます。星は無事です。';

  @override
  String get settingsUpdateMandatoryTitle => 'アップデートが必要です';

  @override
  String get settingsUpdateMandatoryBody =>
      'このバージョンのPourfectはサポートが終了しました。Google Playがアップデートをダウンロードし、ゲームを再び開きます。星は無事です。';

  @override
  String get settingsUpdateNow => '今すぐ更新';

  @override
  String get settingsRenameHello => 'こんにちは';

  @override
  String get settingsRenameMyNameIs => 'わたしの名前は';

  @override
  String get settingsRenameHint => 'ランキングでほかのプレイヤーに表示されます';

  @override
  String get settingsRenameSave => '保存';

  @override
  String settingsCollectionUnlockWith(String how) {
    return '解放条件：$how';
  }

  @override
  String get settingsCollectionChangeFailed => '今は変更できませんでした。あとでもう一度お試しください。';

  @override
  String get settingsPackThanks => 'ありがとうございます！パックはまもなく解放されます。';

  @override
  String get settingsPackAlreadyOwned => '購入済みです。今すぐ復元します。';

  @override
  String get settingsPackPending => '支払い処理中です。完了するとパックが解放されます。';

  @override
  String get settingsCollectionOffline => 'コレクションを見るにはインターネットに接続してください。';

  @override
  String get settingsCollectionBallSkins => 'ボールスキン';

  @override
  String get settingsCollectionTubeThemes => 'チューブテーマ';

  @override
  String settingsCollectionPreview(String skin, String theme) {
    return '$skinのボール · $themeのチューブ';
  }

  @override
  String settingsCollectionItemWorn(String name) {
    return '$name、使用中';
  }

  @override
  String settingsCollectionItemTapToWear(String name) {
    return '$name、タップで使用';
  }

  @override
  String settingsCollectionItemLocked(String name, String how) {
    return '$name、ロック中：$how';
  }

  @override
  String get settingsCollectionWearing => '使用中';

  @override
  String get settingsCollectionTapToWear => 'タップで使用';

  @override
  String settingsUnlockChest(int number) {
    return 'スターチェスト$number';
  }

  @override
  String settingsUnlockStreak(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days日連続',
    );
    return '$_temp0';
  }

  @override
  String get settingsUnlockFree => '無料';

  @override
  String get settingsSkinPack => 'スキンパック';

  @override
  String get settingsSkinPackDetail => 'マーブル、パール、チェッカーのボールと、ウッド、ライラックのチューブ。';

  @override
  String get settingsOwned => '購入済み';

  @override
  String get settingsSoon => '近日';

  @override
  String get settingsSkinClassic => 'クラシック';

  @override
  String get settingsSkinGlossy => 'ツヤツヤ';

  @override
  String get settingsSkinStriped => 'キャンディ';

  @override
  String get settingsSkinGlow => 'グロー';

  @override
  String get settingsSkinSpeckled => 'スプリンクル';

  @override
  String get settingsSkinMarble => 'マーブル';

  @override
  String get settingsSkinPearl => 'パール';

  @override
  String get settingsSkinChecker => 'チェッカー';

  @override
  String get settingsTubeToy => 'トイ';

  @override
  String get settingsTubeFrost => 'フロスト';

  @override
  String get settingsTubeWood => 'ウッド';

  @override
  String get settingsTubeLilac => 'ライラック';
}

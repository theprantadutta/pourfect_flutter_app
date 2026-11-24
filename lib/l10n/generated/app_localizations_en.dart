// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get accountGoogleFailed =>
      'Google sign-in did not work on this phone. Try again, or use email below.';

  @override
  String get accountAppleFailed =>
      'Apple sign-in did not work on this phone. Check you are signed in to your Apple Account in Settings, or use email below.';

  @override
  String get accountExistsNoLocal =>
      'You already have an account with that email. Sign in to it and this phone will load the stars saved to it.';

  @override
  String accountExistsWithLocal(int solved) {
    String _temp0 = intl.Intl.pluralLogic(
      solved,
      locale: localeName,
      other:
          'You already have an account with that email. This phone has $solved solved levels that are not on it, and the two cannot be merged — signing in replaces them with whatever that account holds.',
      one:
          'You already have an account with that email. This phone has $solved solved level that are not on it, and the two cannot be merged — signing in replaces them with whatever that account holds.',
    );
    return '$_temp0';
  }

  @override
  String get accountEmailInUse =>
      'There is already an account with that email. Try signing in instead.';

  @override
  String get accountEmailMalformed =>
      'That does not look like an email address.';

  @override
  String get accountPasswordWeak =>
      'That password is too easy to guess. Try a longer one.';

  @override
  String get accountWrongPassword => 'That email and password do not match.';

  @override
  String get accountTooManyAttempts =>
      'Too many tries. Wait a few minutes and try again.';

  @override
  String get accountNeedsRecentLogin => 'Please sign in again first.';

  @override
  String get accountMethodNotEnabled =>
      'Email sign-in is not available right now. Try Continue with Google.';

  @override
  String get accountSessionUnavailable =>
      'Signed in, but your progress has not been saved to the server yet. It will sync when the connection is back.';

  @override
  String get accountUnavailable =>
      'Could not reach the server. Your progress is still safe on this device.';

  @override
  String get accountUseThatAccount => 'Use that account';

  @override
  String get accountExistingTitle => 'You already have an account';

  @override
  String get accountExistingBodyEmpty =>
      'This phone will load the stars already saved to it.';

  @override
  String accountExistingBodyLocal(int cleared) {
    String _temp0 = intl.Intl.pluralLogic(
      cleared,
      locale: localeName,
      other:
          'This phone has $cleared solved levels that are not on that account. They cannot be combined, so they will be replaced by whatever the account already holds.',
      one:
          'This phone has $cleared solved level that are not on that account. They cannot be combined, so they will be replaced by whatever the account already holds.',
    );
    return '$_temp0';
  }

  @override
  String get accountSignIn => 'Sign in';

  @override
  String get accountSignInCancelled => 'Sign-in cancelled. Nothing changed.';

  @override
  String get accountSignedInToast =>
      'Signed in. Your stars now follow you to a new phone.';

  @override
  String get accountResetNeedsEmail =>
      'Enter your email first, then tap Forgot your password.';

  @override
  String get accountResetSent =>
      'If that email has an account, a reset link is on its way.';

  @override
  String get accountYourAccount => 'Your account';

  @override
  String accountRankValue(int rank) {
    return '#$rank';
  }

  @override
  String accountStreakValue(int days) {
    return '${days}d';
  }

  @override
  String get accountCardTravels =>
      'This card goes with your account, so a new phone starts right where you left off.';

  @override
  String get accountYourNameHeader => 'Your name';

  @override
  String get accountChangeName => 'Change your name';

  @override
  String get accountChangeNameDetail => 'How you appear on the boards';

  @override
  String get accountShowOnBoards => 'Show me on leaderboards';

  @override
  String get accountShowOnBoardsDetail =>
      'Off hides your name and rank. Stars still count.';

  @override
  String get accountYourPlayHeader => 'Your play';

  @override
  String get accountStatistics => 'Statistics';

  @override
  String get accountStatisticsDetail => 'Your times, activity and every level';

  @override
  String get accountSessionHeader => 'Session';

  @override
  String get accountDeleteHint =>
      'To delete your account, go to Settings → Danger zone.';

  @override
  String get accountVisibilityFailed =>
      'Could not reach the server, so nothing changed.';

  @override
  String get accountSignOutTitle => 'Sign out?';

  @override
  String get accountSignOutBody =>
      'Your progress stays on this phone. You can sign back in any time to pick it up somewhere else.';

  @override
  String get accountStaySignedIn => 'Stay signed in';

  @override
  String get accountSignOut => 'Sign out';

  @override
  String get accountSignOutDetail => 'Your progress stays on this phone';

  @override
  String get accountSaveTitle => 'Save your progress';

  @override
  String get accountSaveIntro =>
      'Your stars, streak and leaderboard name move with your account, so a new phone starts where you left off.';

  @override
  String get accountContinueApple => 'Continue with Apple';

  @override
  String get accountContinueGoogle => 'Continue with Google';

  @override
  String get accountOr => 'OR';

  @override
  String get accountEmailLabel => 'Email';

  @override
  String get accountEmailEmpty => 'Enter your email.';

  @override
  String get accountPasswordLabel => 'Password';

  @override
  String get accountPasswordHelper => 'At least 8 characters';

  @override
  String get accountPasswordEmpty => 'Enter a password.';

  @override
  String get accountPasswordShort => 'At least 8 characters.';

  @override
  String get accountShowPassword => 'Show password';

  @override
  String get accountHidePassword => 'Hide password';

  @override
  String get accountCreate => 'Create account';

  @override
  String get accountSwitchToSignIn => 'Already have an account? Sign in';

  @override
  String get accountSwitchToSignInSemantic => 'Sign in instead';

  @override
  String get accountSwitchToCreate => 'Need an account? Create one';

  @override
  String get accountSwitchToCreateSemantic => 'Create an account instead';

  @override
  String get accountForgotPassword => 'Forgot your password?';

  @override
  String get accountForgotPasswordSemantic => 'Reset your password';

  @override
  String get accountNaming => 'Naming you…';

  @override
  String get accountSignedInLabel => 'Signed in';

  @override
  String accountPouringSince(String month, int year) {
    return 'POURING SINCE $month $year';
  }

  @override
  String get accountPlayerCardTag => 'PLAYER CARD';

  @override
  String get accountStatSolved => 'SOLVED';

  @override
  String get accountStatStars => 'STARS';

  @override
  String get accountStatStreak => 'STREAK';

  @override
  String get accountStatRank => 'RANK';

  @override
  String accountStarsValue(int stars) {
    return '$stars★';
  }

  @override
  String get accountSyncing => 'Syncing…';

  @override
  String get accountSyncingDetail => 'Saving progress to your account';

  @override
  String get accountWaitingToSync => 'Waiting to sync';

  @override
  String get accountWaitingOffline => 'Saves when you are back online';

  @override
  String get accountWaitingPending => 'Your latest levels go up next';

  @override
  String get accountSyncedDetail => 'Progress saved to your account';

  @override
  String get accountSynced => 'Synced';

  @override
  String get accountSyncedJustNow => 'Synced just now';

  @override
  String accountSyncedMinutesAgo(int minutes) {
    return 'Synced ${minutes}m ago';
  }

  @override
  String accountSyncedHoursAgo(int hours) {
    return 'Synced ${hours}h ago';
  }

  @override
  String accountSyncedDaysAgo(int days) {
    return 'Synced ${days}d ago';
  }

  @override
  String get accountCrestSignedIn => 'Your account';

  @override
  String get accountCrestGuest => 'Playing as a guest';

  @override
  String get accountRenameRefused => 'That name was not accepted.';

  @override
  String get accountRenameOffline =>
      'Could not reach the server. Try again in a moment.';

  @override
  String get ranksTitle => 'Rankings';

  @override
  String get ranksTabToday => 'Today';

  @override
  String get ranksTabCampaign => 'Campaign';

  @override
  String get ranksLoading => 'Fetching the leaderboard…';

  @override
  String get ranksEmptyDailyTitle => 'Nobody has finished today’s board yet';

  @override
  String get ranksEmptyDailyDetail => 'Be the first.';

  @override
  String get ranksEmptyCampaignTitle => 'No ranked players yet';

  @override
  String get ranksEmptyCampaignDetail => 'Stars decide this one.';

  @override
  String get ranksYourSpot => 'Your spot';

  @override
  String ranksPlayerCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString players on this board',
      one: '1 player on this board',
    );
    return '$_temp0';
  }

  @override
  String ranksMoves(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count moves',
      one: '$count move',
    );
    return '$_temp0';
  }

  @override
  String ranksStars(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count stars',
      one: '$count star',
    );
    return '$_temp0';
  }

  @override
  String ranksLevels(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count levels',
      one: '$count level',
    );
    return '$_temp0';
  }

  @override
  String ranksInTime(String time) {
    return 'in $time';
  }

  @override
  String get ranksOpenSpot => 'Open spot';

  @override
  String ranksNameYou(String name) {
    return '$name (you)';
  }

  @override
  String ranksPlaceOpen(int place) {
    return 'Place $place, open';
  }

  @override
  String ranksPlaceSemantic(int rank, String name, String score) {
    return 'Place $rank, $name, $score';
  }

  @override
  String ranksScoreWithTieBreak(String score, String tieBreak) {
    return '$score, $tieBreak';
  }

  @override
  String get ranksOffTitle => 'Leaderboards are off in this build';

  @override
  String get ranksOffDetail => 'The campaign is unaffected.';

  @override
  String get ranksLoadFailed => 'Could not load the board';

  @override
  String get ranksOffline =>
      'You look offline. Every level still plays without a connection.';

  @override
  String get ranksTimeout => 'The server took too long to answer.';

  @override
  String get ranksServerError =>
      'Something went wrong on our side. Your progress is safe.';

  @override
  String get ranksHiddenTitle => 'You are hidden';

  @override
  String get ranksHiddenDetail =>
      'Your stars and streak still count — you just do not appear here. Settings has the switch.';

  @override
  String get statsTitle => 'Your Stats';

  @override
  String get statsTabOverview => 'Overview';

  @override
  String get statsTabLevels => 'Levels';

  @override
  String get statsTabBadges => 'Badges';

  @override
  String get statsPaceOnPar => 'on par';

  @override
  String statsPaceUnder(int percent) {
    return '$percent% under';
  }

  @override
  String statsPaceOver(int percent) {
    return '$percent% over';
  }

  @override
  String get statsEmptyTitle => 'Nothing to show yet';

  @override
  String get statsEmptyBody =>
      'Solve a level and this fills up: your times against par, your best solves, and the days you played.';

  @override
  String get statsBackToLevels => 'Back to levels';

  @override
  String get statsLevelsSolved => 'levels solved';

  @override
  String get statsStars => 'stars';

  @override
  String get statsPoints => 'points';

  @override
  String get statsPlayed => 'played';

  @override
  String get statsNowOn => 'now on';

  @override
  String get statsBestSolveMoves => 'moves in best solves';

  @override
  String get statsAgainstClock => 'AGAINST THE CLOCK';

  @override
  String get statsNoTimes =>
      'No times on record yet. Levels you cleared before the clock arrived have no time — replay one and it starts counting.';

  @override
  String get statsFastest => 'Fastest';

  @override
  String get statsLongest => 'Longest';

  @override
  String get statsAvgPace => 'Avg pace';

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
          '$count of your solved levels were cleared before the clock and have no time recorded.',
    );
    return '$_temp0';
  }

  @override
  String statsUnderParSemantic(int under, int total) {
    return '$under of $total timed levels under par';
  }

  @override
  String get statsUnderParTag => 'UNDER PAR';

  @override
  String get statsLast30Days => 'LAST 30 DAYS';

  @override
  String statsStreakChip(int count) {
    return '$count day streak';
  }

  @override
  String get statsNoStreak => 'no streak';

  @override
  String statsDaysPlayed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days played',
      one: '$count day played',
    );
    return '$_temp0';
  }

  @override
  String statsLevelsFinished(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count levels finished',
      one: '$count level finished',
    );
    return '$_temp0';
  }

  @override
  String statsBestStreak(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'best $count days',
      one: 'best $count day',
    );
    return '$_temp0';
  }

  @override
  String get statsToday => 'Today';

  @override
  String statsMonthShort(String month) {
    String _temp0 = intl.Intl.selectLogic(month, {
      'jan': 'Jan',
      'feb': 'Feb',
      'mar': 'Mar',
      'apr': 'Apr',
      'may': 'May',
      'jun': 'Jun',
      'jul': 'Jul',
      'aug': 'Aug',
      'sep': 'Sep',
      'oct': 'Oct',
      'nov': 'Nov',
      'dec': 'Dec',
      'other': '$month',
    });
    return '$_temp0';
  }

  @override
  String statsMonthDay(String month, int day) {
    return '$month $day';
  }

  @override
  String statsBarLevels(String day, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$day · $count levels',
      one: '$day · $count level',
    );
    return '$_temp0';
  }

  @override
  String statsBarNoPlay(String day) {
    return '$day · no play';
  }

  @override
  String get statsWorldAhead => 'ahead';

  @override
  String get statsWorldNoTimes => 'no times';

  @override
  String statsWorldPoints(int points) {
    final intl.NumberFormat pointsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String pointsString = pointsNumberFormat.format(points);

    return '$pointsString pts';
  }

  @override
  String statsWorldSolvedSemantic(String name, int cleared, int total) {
    return '$name: $cleared of $total solved';
  }

  @override
  String statsWorldPaceSemantic(String pace) {
    return 'pace $pace';
  }

  @override
  String statsWorldPointsSemantic(int points) {
    final intl.NumberFormat pointsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String pointsString = pointsNumberFormat.format(points);

    return '$pointsString points';
  }

  @override
  String get statsColLevel => 'LVL';

  @override
  String get statsColStars => 'STARS';

  @override
  String get statsColMoves => 'MOVES';

  @override
  String get statsColTime => 'TIME';

  @override
  String get statsColPoints => 'PTS';

  @override
  String statsMovesBestPossible(int moves, int best) {
    return '$moves moves, best possible $best';
  }

  @override
  String statsMoves(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count moves',
      one: '$count move',
    );
    return '$_temp0';
  }

  @override
  String badgeUnlockedCount(int earned, int total) {
    return '$earned of $total unlocked';
  }

  @override
  String get badgeUnlocked => 'Unlocked';

  @override
  String get badgeNotYet => 'Not yet';

  @override
  String badgeProgress(int shown, int target) {
    return '$shown of $target';
  }

  @override
  String badgeSemantic(String title, String description, String status) {
    return '$title: $description $status';
  }

  @override
  String get badgeFirstPourTitle => 'First pour';

  @override
  String get badgeFirstPourDesc => 'Clear your first level.';

  @override
  String get badgePar10Title => 'On par';

  @override
  String get badgePar10Desc => 'Clear 10 levels in exactly par.';

  @override
  String get badgePar50Title => 'Par master';

  @override
  String get badgePar50Desc => 'Clear 50 levels in exactly par.';

  @override
  String get badgeCleanClearTitle => 'No take-backs';

  @override
  String get badgeCleanClearDesc => 'Clear a level without using undo.';

  @override
  String get badgeSpeedyTitle => 'Quick pour';

  @override
  String get badgeSpeedyDesc => 'Clear a level in under 30 seconds.';

  @override
  String get badgeLevels100Title => 'Centurion';

  @override
  String get badgeLevels100Desc => 'Clear 100 levels.';

  @override
  String get badgeStars300Title => 'Star hoarder';

  @override
  String get badgeStars300Desc => 'Collect 300 stars.';

  @override
  String get badgeWorldPerfectTitle => 'Flawless world';

  @override
  String get badgeWorldPerfectDesc => 'Three-star every level in a world.';

  @override
  String get badgeStreak7Title => 'Week of pours';

  @override
  String get badgeStreak7Desc => 'Reach a 7-day Daily Pour streak.';

  @override
  String get badgeStreak30Title => 'Month of pours';

  @override
  String get badgeStreak30Desc => 'Reach a 30-day Daily Pour streak.';

  @override
  String get badgeChests5Title => 'Treasure hunter';

  @override
  String get badgeChests5Desc => 'Open 5 star chests.';

  @override
  String get badgeHard5Title => 'Tough nut';

  @override
  String get badgeHard5Desc => 'Clear 5 HARD levels.';

  @override
  String get badgeEventFullTitle => 'Full week';

  @override
  String get badgeEventFullDesc => 'Clear all seven boards of a weekly event.';

  @override
  String get badgeZen25Title => 'Zen garden';

  @override
  String get badgeZen25Desc => 'Pour 25 boards in Zen mode.';

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

  @override
  String get playHudLevel => 'Level';

  @override
  String playHudTitle(String label, String value) {
    return '$label $value';
  }

  @override
  String get playHudHard => 'HARD ×1.5';

  @override
  String get playHudHardLabel => 'Hard level, one and a half times the points';

  @override
  String get playHudMoves => 'MOVES';

  @override
  String playHudMovesLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count moves',
      one: '1 move',
    );
    return '$_temp0';
  }

  @override
  String playParLeftFor3Stars(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count moves left for 3 stars',
      one: '1 move left for 3 stars',
    );
    return '$_temp0';
  }

  @override
  String get playParSpent => 'Par spent · 2 stars from here';

  @override
  String playParLeftFor2Stars(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count moves left for 2 stars',
      one: '1 move left for 2 stars',
    );
    return '$_temp0';
  }

  @override
  String get playParOneStarFromHere => '1 star from here · any finish';

  @override
  String get playParAnyFinish => 'Any finish earns 1 star';

  @override
  String playParMeterLabel(int stars, int used, int par, String words) {
    return '$stars star pace, $used of par $par moves. $words';
  }

  @override
  String playHudBusyLabel(String label) {
    return '$label, working. Tap to cancel';
  }

  @override
  String get playHudUndo => 'Undo';

  @override
  String get playHudHint => 'Hint';

  @override
  String get playHudRestart => 'Restart';

  @override
  String get playExtraTubeLabel => 'Watch a video for an extra tube';

  @override
  String get playExtraTubeChip => '+ Tube';

  @override
  String playStarsOfTotal(int earned, int total) {
    return '$earned of $total stars';
  }

  @override
  String get playDismiss => 'Dismiss';

  @override
  String get playLeaveTitleSoSoon => 'Leaving so soon?';

  @override
  String get playLeaveTitleMissYou => 'The balls will miss you';

  @override
  String get playLeaveTitleAbandon => 'Abandon the pour?';

  @override
  String get playLeaveTitleMidPour => 'Walking out mid-pour?';

  @override
  String get playLeaveBody =>
      'Your moves and time on this board won\'t be saved.';

  @override
  String get playLeaveKeepPouring => 'Keep pouring';

  @override
  String get playLeaveConfirm => 'Leave';

  @override
  String get playTutorialSkipLabel => 'Skip the tutorial';

  @override
  String get playTutorialSkip => 'Skip';

  @override
  String playTipBubbleLabel(String text) {
    return '$text. Dismiss';
  }

  @override
  String get playTipPar =>
      'Finish within par for three stars. The bar shows how much you\'ve used.';

  @override
  String get playTipTallTubes => 'Taller tubes! Each one holds five balls now.';

  @override
  String get playTipHint => 'Stuck? Hint shows you a good next move.';

  @override
  String get playTipUndo =>
      'Past par? Undo is free — step back as far as you like.';

  @override
  String get playGuideSorted => 'Sorted! Now make every tube a single color.';

  @override
  String get playGuideDrop =>
      'Now tap where they go: onto the same color, or an empty tube.';

  @override
  String get playGuideWrongTube =>
      'Tap the tube the hand points at to pick those up instead.';

  @override
  String get playGuideFirstTap => 'Tap a tube to pick up the balls on top.';

  @override
  String get playGuideFirstPour => 'That\'s a pour! Keep going.';

  @override
  String get playGuideKeepGoing => 'Keep going: one color per tube.';

  @override
  String playCoachHolding(int count) {
    return 'Holding $count · drop into a bouncing tube';
  }

  @override
  String get playExtraTubeAdTitle => 'Watch a video for an extra tube?';

  @override
  String get playExtraTubeAdBody =>
      'One more empty tube for this level. A level finished with an extra tube earns up to two stars.';

  @override
  String get playExtraTubeNotFinished =>
      'No tube — the video was not finished.';

  @override
  String get playExtraTubeSaved => 'Saved — your next tube is free.';

  @override
  String get playNoVideo => 'No video available right now.';

  @override
  String get playRewardFailed => 'Something went wrong. Nothing was used.';

  @override
  String get playHintShowing =>
      'Your hint is showing: pour into the glowing tube.';

  @override
  String get playHintNoneNothingUsed =>
      'No hint for this position. Nothing was used.';

  @override
  String get playHintNotFinished => 'No hint — the video was not finished.';

  @override
  String get playHintVideoSaved => 'Your video is saved for the next hint.';

  @override
  String get playHintNoneVideoSaved =>
      'No hint for this position — your video is saved for the next one.';

  @override
  String get playHintNone => 'No hint available for this position.';

  @override
  String get playHintHere => 'Here is your hint — pour into the glowing tube.';

  @override
  String get playDeadEndRestart =>
      'No way to finish from here. Restart to try another line.';

  @override
  String get playDeadEndRestartTube =>
      'No way to finish from here. Restart to try another line. Or tap + Tube for a spare tube.';

  @override
  String playDeadEndUndo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'No way to finish from here. Undo $count moves to get back on track.',
      one: 'No way to finish from here. Undo 1 move to get back on track.',
    );
    return '$_temp0';
  }

  @override
  String playDeadEndUndoTube(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'No way to finish from here. Undo $count moves to get back on track. Or tap + Tube for a spare tube.',
      one: 'No way to finish from here. Undo 1 move to get back on track. Or tap + Tube for a spare tube.',
    );
    return '$_temp0';
  }

  @override
  String playDeadEndUndoAction(int count) {
    return 'Undo $count';
  }

  @override
  String get playHintAdTitle => 'Watch a video for a hint?';

  @override
  String playHintAdFreeLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'You have $count free hints left.',
      one: 'You have 1 free hint left.',
    );
    return '$_temp0';
  }

  @override
  String get playHintAdNoneLeft =>
      'Your free hints are used up. A short video earns one more.';

  @override
  String get playWatch => 'Watch';

  @override
  String get playLoadFailed => 'Could not load levels';

  @override
  String get playTubeSorted => 'SORTED!';

  @override
  String get playWinTitlePerfect => 'Perfect\nPour!';

  @override
  String get playWinTitleNice => 'Nice\nPour!';

  @override
  String get playWinTitlePoured => 'Poured!';

  @override
  String get playWinLastPour => 'Last pour…';

  @override
  String playWinMovesPar(int count, int par) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count MOVES · PAR $par',
      one: '1 MOVE · PAR $par',
    );
    return '$_temp0';
  }

  @override
  String playWinLevelBand(int level, String band) {
    return 'Level $level · $band';
  }

  @override
  String get playWinNewBest => 'NEW BEST!';

  @override
  String playWinMovesChip(int par) {
    return 'moves · par $par';
  }

  @override
  String get playWinUntimed => 'untimed';

  @override
  String get playWinFastest => 'fastest yet!';

  @override
  String get playWinTime => 'time';

  @override
  String get playWinUnderPar => 'UNDER PAR!';

  @override
  String get playWinPoints => 'points';

  @override
  String playWinWorldBand(int world, String band) {
    return 'WORLD $world · $band';
  }

  @override
  String get playWinTryAssisted =>
      'Three stars need a clear without the extra tube.';

  @override
  String playWinTryShort(int par, int took, int short) {
    String _temp0 = intl.Intl.pluralLogic(
      short,
      locale: localeName,
      other: 'Par $par, you took $took. $short moves from 3★.',
      one: 'Par $par, you took $took. One move from 3★.',
    );
    return '$_temp0';
  }

  @override
  String playWinTryInReach(int par) {
    return 'Par $par. Three stars are in reach.';
  }

  @override
  String get playWinTryButton => 'TRY FOR 3★';

  @override
  String get playWinTryButtonLabel => 'Replay this level for three stars';

  @override
  String get playWinReplayLabel => 'Replay this level';

  @override
  String get playWinHomeLabel => 'Back to the home screen';

  @override
  String get playWinNextLevel => 'NEXT LEVEL';

  @override
  String get playWinBackToLevels => 'BACK TO LEVELS';

  @override
  String playChestNextAtLabel(int stars) {
    return 'Next star chest at $stars stars';
  }

  @override
  String get playChestOpenLabel => 'Open star chest';

  @override
  String get playChestReady => 'A star chest is ready!';

  @override
  String playChestNextAt(int stars) {
    return 'Next chest at $stars ★';
  }

  @override
  String get playChestOpen => 'OPEN';

  @override
  String get playChestDoubleFailed => 'Could not double it this time.';

  @override
  String get playChestDoubleNotFinished =>
      'Not doubled — the video was not finished.';

  @override
  String get playChestOpening => 'Opening…';

  @override
  String playChestTitle(int index) {
    return 'Star chest $index';
  }

  @override
  String get playChestNotYetTitle => 'Almost there';

  @override
  String get playChestAlreadyOpenTitle => 'Already open';

  @override
  String get playChestFailedTitle => 'Could not open it';

  @override
  String get playChestNotYetNote =>
      'Your newest stars are still on their way to the server. Try again in a moment.';

  @override
  String get playChestAlreadyOpenNote =>
      'This chest was opened on another device.';

  @override
  String get playChestFailedNote => 'Check your connection and try again.';

  @override
  String playChestRewardCount(int count) {
    return '+$count';
  }

  @override
  String playChestHintsCaption(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'hints',
    );
    return '$_temp0';
  }

  @override
  String playChestTubesCaption(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'extra tubes',
      one: 'extra tube',
    );
    return '$_temp0';
  }

  @override
  String playChestUnlocked(String name) {
    return 'Unlocked: $name';
  }

  @override
  String playChestBallSkinName(String skin) {
    return '$skin ball skin';
  }

  @override
  String playChestTubeThemeName(String theme) {
    return '$theme tubes';
  }

  @override
  String get playChestNewLook => 'a new look';

  @override
  String get playChestSavedNote =>
      'Saved for when you need them. Hint and + Tube use these first.';

  @override
  String get playChestLoadingVideo => 'Loading video…';

  @override
  String get playChestDouble => 'Double it with a video';

  @override
  String get playChestCollect => 'Collect';

  @override
  String playClockLabel(String time) {
    return 'Time $time';
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
    return 'Time $time of par $par, $_temp0 $percent percent points';
  }

  @override
  String playClockBonusChip(String sign, int percent) {
    return '$sign$percent% pts';
  }

  @override
  String get playLoading => 'Loading';

  @override
  String get playWorking => 'Working';

  @override
  String get playZenTitle => 'Zen';

  @override
  String get playZenIntro =>
      'Endless boards. No clock, no stars, no leaderboard — just pour.';

  @override
  String get playZenPaceCalm => 'Calm';

  @override
  String get playZenPaceSteady => 'Steady';

  @override
  String get playZenPaceDeep => 'Deep';

  @override
  String playZenPaceColors(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count colors',
      one: '1 color',
    );
    return '$_temp0';
  }

  @override
  String playZenPaceLabel(String pace, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$pace, $count colors',
      one: '$pace, 1 color',
    );
    return '$_temp0';
  }

  @override
  String playZenBandPoured(String pace, int count) {
    return '$pace · $count poured';
  }

  @override
  String playZenPoured(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Poured! $count so far.',
      one: 'Poured!',
    );
    return '$_temp0';
  }

  @override
  String get playZenNext => 'NEXT';

  @override
  String get playZenLeaveBody =>
      'This board\'s moves won\'t be saved. Your poured count stays.';

  @override
  String get playZenDeadEnd => 'No way to finish from here. Undo or restart.';

  @override
  String get playZenNoHint => 'No hint for this position right now.';
}

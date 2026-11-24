import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('en')];

  /// Account screen: Google refused the sign-in (shown under the form and as a toast). 'Google' is a brand name.
  ///
  /// In en, this message translates to:
  /// **'Google sign-in did not work on this phone. Try again, or use email below.'**
  String get accountGoogleFailed;

  /// Account screen: Apple refused the sign-in. 'Apple Account' and 'Settings' name the iOS system app and account; use Apple's own translation.
  ///
  /// In en, this message translates to:
  /// **'Apple sign-in did not work on this phone. Check you are signed in to your Apple Account in Settings, or use email below.'**
  String get accountAppleFailed;

  /// Account screen: the credential belongs to another account and this phone has no solved levels, so nothing is lost by switching. Must reassure, not warn.
  ///
  /// In en, this message translates to:
  /// **'You already have an account with that email. Sign in to it and this phone will load the stars saved to it.'**
  String get accountExistsNoLocal;

  /// Account screen: the credential belongs to another account and this phone has solved levels that would be replaced by switching.
  ///
  /// In en, this message translates to:
  /// **'{solved, plural, =1{You already have an account with that email. This phone has {solved} solved level that are not on it, and the two cannot be merged — signing in replaces them with whatever that account holds.} other{You already have an account with that email. This phone has {solved} solved levels that are not on it, and the two cannot be merged — signing in replaces them with whatever that account holds.}}'**
  String accountExistsWithLocal(int solved);

  /// Account screen: creating an account with an email that is taken.
  ///
  /// In en, this message translates to:
  /// **'There is already an account with that email. Try signing in instead.'**
  String get accountEmailInUse;

  /// Account screen: the email field's text is not an email address (form validation and server answer).
  ///
  /// In en, this message translates to:
  /// **'That does not look like an email address.'**
  String get accountEmailMalformed;

  /// Account screen: the password was rejected as weak.
  ///
  /// In en, this message translates to:
  /// **'That password is too easy to guess. Try a longer one.'**
  String get accountPasswordWeak;

  /// Account screen: wrong password OR no such account. Deliberately does not say which, so nobody can probe for registered emails.
  ///
  /// In en, this message translates to:
  /// **'That email and password do not match.'**
  String get accountWrongPassword;

  /// Account screen: sign-in was rate limited.
  ///
  /// In en, this message translates to:
  /// **'Too many tries. Wait a few minutes and try again.'**
  String get accountTooManyAttempts;

  /// Account screen: the action needs a fresh sign-in.
  ///
  /// In en, this message translates to:
  /// **'Please sign in again first.'**
  String get accountNeedsRecentLogin;

  /// Account screen: email sign-in is switched off. 'Continue with Google' is the button label (accountContinueGoogle); keep it matching.
  ///
  /// In en, this message translates to:
  /// **'Email sign-in is not available right now. Try Continue with Google.'**
  String get accountMethodNotEnabled;

  /// Account screen: signed in, but the game's server did not answer yet.
  ///
  /// In en, this message translates to:
  /// **'Signed in, but your progress has not been saved to the server yet. It will sync when the connection is back.'**
  String get accountSessionUnavailable;

  /// Account screen: network failure during sign-in.
  ///
  /// In en, this message translates to:
  /// **'Could not reach the server. Your progress is still safe on this device.'**
  String get accountUnavailable;

  /// Confirm button in the 'You already have an account' dialog. Short.
  ///
  /// In en, this message translates to:
  /// **'Use that account'**
  String get accountUseThatAccount;

  /// Dialog title when the sign-in belongs to an existing account.
  ///
  /// In en, this message translates to:
  /// **'You already have an account'**
  String get accountExistingTitle;

  /// Dialog body when this phone has no progress to lose by switching to the existing account.
  ///
  /// In en, this message translates to:
  /// **'This phone will load the stars already saved to it.'**
  String get accountExistingBodyEmpty;

  /// Dialog body when switching to the existing account would replace this phone's solved levels.
  ///
  /// In en, this message translates to:
  /// **'{cleared, plural, =1{This phone has {cleared} solved level that are not on that account. They cannot be combined, so they will be replaced by whatever the account already holds.} other{This phone has {cleared} solved levels that are not on that account. They cannot be combined, so they will be replaced by whatever the account already holds.}}'**
  String accountExistingBodyLocal(int cleared);

  /// Button: sign in with email and password (form button and dialog confirm). Short.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get accountSignIn;

  /// Toast after the player backed out of the Google/Apple sheet.
  ///
  /// In en, this message translates to:
  /// **'Sign-in cancelled. Nothing changed.'**
  String get accountSignInCancelled;

  /// Toast after a successful sign-in.
  ///
  /// In en, this message translates to:
  /// **'Signed in. Your stars now follow you to a new phone.'**
  String get accountSignedInToast;

  /// Account screen: tapped the password-reset link with an empty email field. 'Forgot your password' must match accountForgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter your email first, then tap Forgot your password.'**
  String get accountResetNeedsEmail;

  /// Account screen: after asking for a password reset. Must not reveal whether the email is registered.
  ///
  /// In en, this message translates to:
  /// **'If that email has an account, a reset link is on its way.'**
  String get accountResetSent;

  /// Header title of the account screen for a signed-in player.
  ///
  /// In en, this message translates to:
  /// **'Your account'**
  String get accountYourAccount;

  /// The player's leaderboard rank on the Player Card, e.g. '#12'. Very short.
  ///
  /// In en, this message translates to:
  /// **'#{rank}'**
  String accountRankValue(int rank);

  /// Current daily streak in days on the Player Card, e.g. '5d'. Very short (a tiny stat cell).
  ///
  /// In en, this message translates to:
  /// **'{days}d'**
  String accountStreakValue(int days);

  /// Line under the Player Card. Claims only that the account moves to a new phone; never say 'safe' or 'backed up'.
  ///
  /// In en, this message translates to:
  /// **'This card goes with your account, so a new phone starts right where you left off.'**
  String get accountCardTravels;

  /// Section header above the rename and leaderboard-visibility rows.
  ///
  /// In en, this message translates to:
  /// **'Your name'**
  String get accountYourNameHeader;

  /// Row title: opens the rename box for the leaderboard name.
  ///
  /// In en, this message translates to:
  /// **'Change your name'**
  String get accountChangeName;

  /// One-line detail under 'Change your name'. Ellipsized, keep it short.
  ///
  /// In en, this message translates to:
  /// **'How you appear on the boards'**
  String get accountChangeNameDetail;

  /// Toggle row title: whether the player is listed on public leaderboards.
  ///
  /// In en, this message translates to:
  /// **'Show me on leaderboards'**
  String get accountShowOnBoards;

  /// One-line detail under the leaderboard toggle. Ellipsized, keep it short.
  ///
  /// In en, this message translates to:
  /// **'Off hides your name and rank. Stars still count.'**
  String get accountShowOnBoardsDetail;

  /// Section header above the Statistics and sync rows.
  ///
  /// In en, this message translates to:
  /// **'Your play'**
  String get accountYourPlayHeader;

  /// Row title that opens the statistics screen.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get accountStatistics;

  /// One-line detail under 'Statistics'. Ellipsized, keep it short.
  ///
  /// In en, this message translates to:
  /// **'Your times, activity and every level'**
  String get accountStatisticsDetail;

  /// Section header above the sign-out card.
  ///
  /// In en, this message translates to:
  /// **'Session'**
  String get accountSessionHeader;

  /// Footnote at the bottom of the account screen. 'Settings' and 'Danger zone' name the in-app Settings screen and its section; match their translations.
  ///
  /// In en, this message translates to:
  /// **'To delete your account, go to Settings → Danger zone.'**
  String get accountDeleteHint;

  /// Message when the leaderboard visibility switch could not be saved.
  ///
  /// In en, this message translates to:
  /// **'Could not reach the server, so nothing changed.'**
  String get accountVisibilityFailed;

  /// Title of the sign-out confirmation dialog.
  ///
  /// In en, this message translates to:
  /// **'Sign out?'**
  String get accountSignOutTitle;

  /// Body of the sign-out confirmation dialog.
  ///
  /// In en, this message translates to:
  /// **'Your progress stays on this phone. You can sign back in any time to pick it up somewhere else.'**
  String get accountSignOutBody;

  /// Cancel button of the sign-out dialog.
  ///
  /// In en, this message translates to:
  /// **'Stay signed in'**
  String get accountStaySignedIn;

  /// Sign-out button, dialog confirm and the sign-out card's title and accessibility label.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get accountSignOut;

  /// One-line detail on the sign-out card. Ellipsized, keep it short.
  ///
  /// In en, this message translates to:
  /// **'Your progress stays on this phone'**
  String get accountSignOutDetail;

  /// Header title of the account screen for a player who is not signed in.
  ///
  /// In en, this message translates to:
  /// **'Save your progress'**
  String get accountSaveTitle;

  /// Intro at the top of the sign-in form. Claims only that progress moves to a new phone; never say 'safe' or 'backed up'.
  ///
  /// In en, this message translates to:
  /// **'Your stars, streak and leaderboard name move with your account, so a new phone starts where you left off.'**
  String get accountSaveIntro;

  /// Sign in with Apple button (iOS). Use Apple's official translation of this label.
  ///
  /// In en, this message translates to:
  /// **'Continue with Apple'**
  String get accountContinueApple;

  /// Sign in with Google button. Use Google's official translation of this label.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get accountContinueGoogle;

  /// Divider between the social sign-in buttons and the email form. Capitals.
  ///
  /// In en, this message translates to:
  /// **'OR'**
  String get accountOr;

  /// Email field label.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get accountEmailLabel;

  /// Validation: the email field is empty.
  ///
  /// In en, this message translates to:
  /// **'Enter your email.'**
  String get accountEmailEmpty;

  /// Password field label.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get accountPasswordLabel;

  /// Helper text under the password field when creating an account, shown before typing.
  ///
  /// In en, this message translates to:
  /// **'At least 8 characters'**
  String get accountPasswordHelper;

  /// Validation: the password field is empty.
  ///
  /// In en, this message translates to:
  /// **'Enter a password.'**
  String get accountPasswordEmpty;

  /// Validation: the new password is shorter than 8 characters.
  ///
  /// In en, this message translates to:
  /// **'At least 8 characters.'**
  String get accountPasswordShort;

  /// Accessibility label of the eye button that reveals the password.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get accountShowPassword;

  /// Accessibility label of the eye button that hides the password again.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get accountHidePassword;

  /// Main button of the form when creating a new account. Short.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get accountCreate;

  /// Text link under the form that switches it from 'create account' to 'sign in'.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Sign in'**
  String get accountSwitchToSignIn;

  /// Accessibility label of the 'Already have an account? Sign in' link.
  ///
  /// In en, this message translates to:
  /// **'Sign in instead'**
  String get accountSwitchToSignInSemantic;

  /// Text link under the form that switches it from 'sign in' to 'create account'.
  ///
  /// In en, this message translates to:
  /// **'Need an account? Create one'**
  String get accountSwitchToCreate;

  /// Accessibility label of the 'Need an account? Create one' link.
  ///
  /// In en, this message translates to:
  /// **'Create an account instead'**
  String get accountSwitchToCreateSemantic;

  /// Text link that sends a password-reset email.
  ///
  /// In en, this message translates to:
  /// **'Forgot your password?'**
  String get accountForgotPassword;

  /// Accessibility label of the 'Forgot your password?' link.
  ///
  /// In en, this message translates to:
  /// **'Reset your password'**
  String get accountForgotPasswordSemantic;

  /// Shown on the Player Card in place of the leaderboard name while the server has not assigned one yet.
  ///
  /// In en, this message translates to:
  /// **'Naming you…'**
  String get accountNaming;

  /// Player Card line where the email goes, for an account with no email (Google/Apple without one).
  ///
  /// In en, this message translates to:
  /// **'Signed in'**
  String get accountSignedInLabel;

  /// Player Card: the month the player's history starts, in capitals, e.g. 'POURING SINCE JAN 2026'. month is statsMonthShort upper-cased.
  ///
  /// In en, this message translates to:
  /// **'POURING SINCE {month} {year}'**
  String accountPouringSince(String month, int year);

  /// Small tilted tag on the corner of the Player Card. Capitals, very short.
  ///
  /// In en, this message translates to:
  /// **'PLAYER CARD'**
  String get accountPlayerCardTag;

  /// Player Card stat label under the number of levels solved. Capitals, about 8 characters max.
  ///
  /// In en, this message translates to:
  /// **'SOLVED'**
  String get accountStatSolved;

  /// Player Card stat label under the star total. Capitals, about 8 characters max.
  ///
  /// In en, this message translates to:
  /// **'STARS'**
  String get accountStatStars;

  /// Player Card stat label under the daily streak. Capitals, about 8 characters max.
  ///
  /// In en, this message translates to:
  /// **'STREAK'**
  String get accountStatStreak;

  /// Player Card stat label under the leaderboard rank. Capitals, about 8 characters max.
  ///
  /// In en, this message translates to:
  /// **'RANK'**
  String get accountStatRank;

  /// Player Card star total with a star symbol, e.g. '38★'. Keep the symbol.
  ///
  /// In en, this message translates to:
  /// **'{stars}★'**
  String accountStarsValue(int stars);

  /// Sync row title while progress is uploading.
  ///
  /// In en, this message translates to:
  /// **'Syncing…'**
  String get accountSyncing;

  /// Sync row detail while uploading. One line.
  ///
  /// In en, this message translates to:
  /// **'Saving progress to your account'**
  String get accountSyncingDetail;

  /// Sync row title when progress is not uploaded yet.
  ///
  /// In en, this message translates to:
  /// **'Waiting to sync'**
  String get accountWaitingToSync;

  /// Sync row detail when the server is unreachable. One line.
  ///
  /// In en, this message translates to:
  /// **'Saves when you are back online'**
  String get accountWaitingOffline;

  /// Sync row detail when some levels are queued for upload. One line.
  ///
  /// In en, this message translates to:
  /// **'Your latest levels go up next'**
  String get accountWaitingPending;

  /// Sync row detail once everything is uploaded. One line.
  ///
  /// In en, this message translates to:
  /// **'Progress saved to your account'**
  String get accountSyncedDetail;

  /// Sync row title once uploaded, when the time is unknown.
  ///
  /// In en, this message translates to:
  /// **'Synced'**
  String get accountSynced;

  /// Sync row title, uploaded less than a minute ago.
  ///
  /// In en, this message translates to:
  /// **'Synced just now'**
  String get accountSyncedJustNow;

  /// Sync row title, uploaded some minutes ago. Abbreviated unit, short.
  ///
  /// In en, this message translates to:
  /// **'Synced {minutes}m ago'**
  String accountSyncedMinutesAgo(int minutes);

  /// Sync row title, uploaded some hours ago. Abbreviated unit, short.
  ///
  /// In en, this message translates to:
  /// **'Synced {hours}h ago'**
  String accountSyncedHoursAgo(int hours);

  /// Sync row title, uploaded some days ago. Abbreviated unit, short.
  ///
  /// In en, this message translates to:
  /// **'Synced {days}d ago'**
  String accountSyncedDaysAgo(int days);

  /// Accessibility label of the player's crest button (home screen) when signed in.
  ///
  /// In en, this message translates to:
  /// **'Your account'**
  String get accountCrestSignedIn;

  /// Accessibility label of the player's crest button (home screen) when not signed in.
  ///
  /// In en, this message translates to:
  /// **'Playing as a guest'**
  String get accountCrestGuest;

  /// Message when the server refused a new leaderboard name without giving its own reason.
  ///
  /// In en, this message translates to:
  /// **'That name was not accepted.'**
  String get accountRenameRefused;

  /// Message when renaming failed because the server could not be reached.
  ///
  /// In en, this message translates to:
  /// **'Could not reach the server. Try again in a moment.'**
  String get accountRenameOffline;

  /// Header title of the leaderboard screen.
  ///
  /// In en, this message translates to:
  /// **'Rankings'**
  String get ranksTitle;

  /// Leaderboard tab: today's daily challenge board. Short tab label.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get ranksTabToday;

  /// Leaderboard tab: the campaign star board. Short tab label.
  ///
  /// In en, this message translates to:
  /// **'Campaign'**
  String get ranksTabCampaign;

  /// Caption under the loading animation on the leaderboard screen.
  ///
  /// In en, this message translates to:
  /// **'Fetching the leaderboard…'**
  String get ranksLoading;

  /// Leaderboard, Today tab, nobody on it yet.
  ///
  /// In en, this message translates to:
  /// **'Nobody has finished today’s board yet'**
  String get ranksEmptyDailyTitle;

  /// Line under the empty Today board.
  ///
  /// In en, this message translates to:
  /// **'Be the first.'**
  String get ranksEmptyDailyDetail;

  /// Leaderboard, Campaign tab, nobody on it yet.
  ///
  /// In en, this message translates to:
  /// **'No ranked players yet'**
  String get ranksEmptyCampaignTitle;

  /// Line under the empty Campaign board: the campaign board is ranked by stars.
  ///
  /// In en, this message translates to:
  /// **'Stars decide this one.'**
  String get ranksEmptyCampaignDetail;

  /// Section label above the player's own row when they are outside the visible top list.
  ///
  /// In en, this message translates to:
  /// **'Your spot'**
  String get ranksYourSpot;

  /// Footer under the leaderboard: how many players are ranked.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 player on this board} other{{count} players on this board}}'**
  String ranksPlayerCount(int count);

  /// A daily-board score: how many moves the solve took.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{{count} move} other{{count} moves}}'**
  String ranksMoves(int count);

  /// A campaign-board score, spoken by screen readers: the player's star total.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{{count} star} other{{count} stars}}'**
  String ranksStars(int count);

  /// Under a campaign-board name: how many levels the player has cleared.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{{count} level} other{{count} levels}}'**
  String ranksLevels(int count);

  /// Under a daily-board name: the time the solve took, e.g. 'in 1:07'.
  ///
  /// In en, this message translates to:
  /// **'in {time}'**
  String ranksInTime(String time);

  /// Name shown on an empty podium step (nobody holds this place yet).
  ///
  /// In en, this message translates to:
  /// **'Open spot'**
  String get ranksOpenSpot;

  /// A leaderboard name marked as the player's own row. name is the player's leaderboard name.
  ///
  /// In en, this message translates to:
  /// **'{name} (you)'**
  String ranksNameYou(String name);

  /// Screen reader label of an empty podium step.
  ///
  /// In en, this message translates to:
  /// **'Place {place}, open'**
  String ranksPlaceOpen(int place);

  /// Screen reader label of a podium step: rank, player name, score (e.g. '14 moves, in 1:07').
  ///
  /// In en, this message translates to:
  /// **'Place {rank}, {name}, {score}'**
  String ranksPlaceSemantic(int rank, String name, String score);

  /// Screen reader: a score followed by its tie-breaker, e.g. '14 moves, in 1:07' or '38 stars, 12 levels'.
  ///
  /// In en, this message translates to:
  /// **'{score}, {tieBreak}'**
  String ranksScoreWithTieBreak(String score, String tieBreak);

  /// Leaderboard screen in a build with no server configured.
  ///
  /// In en, this message translates to:
  /// **'Leaderboards are off in this build'**
  String get ranksOffTitle;

  /// Line under 'Leaderboards are off in this build'.
  ///
  /// In en, this message translates to:
  /// **'The campaign is unaffected.'**
  String get ranksOffDetail;

  /// Title when the leaderboard failed to load.
  ///
  /// In en, this message translates to:
  /// **'Could not load the board'**
  String get ranksLoadFailed;

  /// Leaderboard failed to load: no connection.
  ///
  /// In en, this message translates to:
  /// **'You look offline. Every level still plays without a connection.'**
  String get ranksOffline;

  /// Leaderboard failed to load: timeout.
  ///
  /// In en, this message translates to:
  /// **'The server took too long to answer.'**
  String get ranksTimeout;

  /// Leaderboard failed to load: server error.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong on our side. Your progress is safe.'**
  String get ranksServerError;

  /// Notice above the leaderboard for a player who turned off 'Show me on leaderboards'.
  ///
  /// In en, this message translates to:
  /// **'You are hidden'**
  String get ranksHiddenTitle;

  /// Body of the 'You are hidden' notice. 'Settings' is the in-app Settings screen.
  ///
  /// In en, this message translates to:
  /// **'Your stars and streak still count — you just do not appear here. Settings has the switch.'**
  String get ranksHiddenDetail;

  /// Header title of the statistics screen.
  ///
  /// In en, this message translates to:
  /// **'Your Stats'**
  String get statsTitle;

  /// Statistics tab: headline figures. Short tab label (three tabs share a phone width).
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get statsTabOverview;

  /// Statistics tab: per-world and per-level results. Short tab label.
  ///
  /// In en, this message translates to:
  /// **'Levels'**
  String get statsTabLevels;

  /// Statistics tab: achievements. Short tab label.
  ///
  /// In en, this message translates to:
  /// **'Badges'**
  String get statsTabBadges;

  /// Average time against the par time: exactly on par. Lowercase, short (chip).
  ///
  /// In en, this message translates to:
  /// **'on par'**
  String get statsPaceOnPar;

  /// Average time against par: faster than par by a percentage, e.g. '18% under'. Short (chip).
  ///
  /// In en, this message translates to:
  /// **'{percent}% under'**
  String statsPaceUnder(int percent);

  /// Average time against par: slower than par by a percentage, e.g. '40% over'. Neutral, never scolding. Short (chip).
  ///
  /// In en, this message translates to:
  /// **'{percent}% over'**
  String statsPaceOver(int percent);

  /// Statistics screen before any level is solved.
  ///
  /// In en, this message translates to:
  /// **'Nothing to show yet'**
  String get statsEmptyTitle;

  /// Body under 'Nothing to show yet'.
  ///
  /// In en, this message translates to:
  /// **'Solve a level and this fills up: your times against par, your best solves, and the days you played.'**
  String get statsEmptyBody;

  /// Button on the empty statistics screen that goes back.
  ///
  /// In en, this message translates to:
  /// **'Back to levels'**
  String get statsBackToLevels;

  /// Label under the big number of levels solved. Lowercase, short.
  ///
  /// In en, this message translates to:
  /// **'levels solved'**
  String get statsLevelsSolved;

  /// Label under the big star total. Lowercase, short.
  ///
  /// In en, this message translates to:
  /// **'stars'**
  String get statsStars;

  /// Label under the big points total. Lowercase, short.
  ///
  /// In en, this message translates to:
  /// **'points'**
  String get statsPoints;

  /// Label under the total time played (e.g. '4h 12m'). Lowercase, short.
  ///
  /// In en, this message translates to:
  /// **'played'**
  String get statsPlayed;

  /// Label under 'Level 42': the furthest level unlocked. Lowercase, short.
  ///
  /// In en, this message translates to:
  /// **'now on'**
  String get statsNowOn;

  /// Label under the sum of moves across every level's best solve.
  ///
  /// In en, this message translates to:
  /// **'moves in best solves'**
  String get statsBestSolveMoves;

  /// Card label for the time-against-par figures. Capitals.
  ///
  /// In en, this message translates to:
  /// **'AGAINST THE CLOCK'**
  String get statsAgainstClock;

  /// Shown in the AGAINST THE CLOCK card when no level has a recorded time.
  ///
  /// In en, this message translates to:
  /// **'No times on record yet. Levels you cleared before the clock arrived have no time — replay one and it starts counting.'**
  String get statsNoTimes;

  /// Row label: the fastest clear. Short.
  ///
  /// In en, this message translates to:
  /// **'Fastest'**
  String get statsFastest;

  /// Row label: the slowest clear. Short.
  ///
  /// In en, this message translates to:
  /// **'Longest'**
  String get statsLongest;

  /// Row label: average time against par. Short, abbreviated.
  ///
  /// In en, this message translates to:
  /// **'Avg pace'**
  String get statsAvgPace;

  /// A time and the level it was set on, e.g. '0:42 · L12'. L is short for Level. Very short.
  ///
  /// In en, this message translates to:
  /// **'{time} · L{level}'**
  String statsClockValue(String time, int level);

  /// Footnote: how many solved levels have no recorded time.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, other{{count} of your solved levels were cleared before the clock and have no time recorded.}}'**
  String statsUntimed(int count);

  /// Screen reader label of the under-par ring.
  ///
  /// In en, this message translates to:
  /// **'{under} of {total} timed levels under par'**
  String statsUnderParSemantic(int under, int total);

  /// Tiny caption inside the ring, under '5/9'. Capitals, about 10 characters max.
  ///
  /// In en, this message translates to:
  /// **'UNDER PAR'**
  String get statsUnderParTag;

  /// Activity chart label. Capitals.
  ///
  /// In en, this message translates to:
  /// **'LAST 30 DAYS'**
  String get statsLast30Days;

  /// Chip: the current daily play streak, e.g. '5 day streak'. Short.
  ///
  /// In en, this message translates to:
  /// **'{count} day streak'**
  String statsStreakChip(int count);

  /// Chip when there is no current streak. Lowercase, short.
  ///
  /// In en, this message translates to:
  /// **'no streak'**
  String get statsNoStreak;

  /// Footer under the activity chart. Short (shares a row with two others).
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{{count} day played} other{{count} days played}}'**
  String statsDaysPlayed(int count);

  /// Footer under the activity chart. Short (shares a row with two others).
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{{count} level finished} other{{count} levels finished}}'**
  String statsLevelsFinished(int count);

  /// Footer under the activity chart: the longest streak. Short (shares a row with two others).
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{best {count} day} other{best {count} days}}'**
  String statsBestStreak(int count);

  /// Tooltip of today's bar in the activity chart.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get statsToday;

  /// A short month name (3 letters in English). Used in the activity chart tooltip ('Jan 5') and, upper-cased, on the Player Card ('POURING SINCE JAN 2026'). Translate each branch value only, not the jan/feb keys.
  ///
  /// In en, this message translates to:
  /// **'{month, select, jan{Jan} feb{Feb} mar{Mar} apr{Apr} may{May} jun{Jun} jul{Jul} aug{Aug} sep{Sep} oct{Oct} nov{Nov} dec{Dec} other{{month}}}'**
  String statsMonthShort(String month);

  /// A day in the activity chart tooltip, e.g. 'Jan 5'. month is statsMonthShort.
  ///
  /// In en, this message translates to:
  /// **'{month} {day}'**
  String statsMonthDay(String month, int day);

  /// Tooltip of a played day in the activity chart, e.g. 'Jan 5 · 3 levels'.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{{day} · {count} level} other{{day} · {count} levels}}'**
  String statsBarLevels(String day, int count);

  /// Tooltip of a day with no play in the activity chart, e.g. 'Jan 5 · no play'.
  ///
  /// In en, this message translates to:
  /// **'{day} · no play'**
  String statsBarNoPlay(String day);

  /// Chip on a world the player has not started. Lowercase, very short.
  ///
  /// In en, this message translates to:
  /// **'ahead'**
  String get statsWorldAhead;

  /// Chip on a world with no recorded times. Lowercase, very short.
  ///
  /// In en, this message translates to:
  /// **'no times'**
  String get statsWorldNoTimes;

  /// Points earned in a world, abbreviated, e.g. '1,240 pts'. Very short.
  ///
  /// In en, this message translates to:
  /// **'{points} pts'**
  String statsWorldPoints(int points);

  /// Screen reader label of a world row. name is the world's name. Followed, comma-separated, by statsWorldPaceSemantic and statsWorldPointsSemantic when known.
  ///
  /// In en, this message translates to:
  /// **'{name}: {cleared} of {total} solved'**
  String statsWorldSolvedSemantic(String name, int cleared, int total);

  /// Screen reader: a world's average pace against par. pace is statsPaceOnPar/Under/Over.
  ///
  /// In en, this message translates to:
  /// **'pace {pace}'**
  String statsWorldPaceSemantic(String pace);

  /// Screen reader: points earned in a world.
  ///
  /// In en, this message translates to:
  /// **'{points} points'**
  String statsWorldPointsSemantic(int points);

  /// Per-level table column header: level number. Capitals, 3-4 characters (narrow column).
  ///
  /// In en, this message translates to:
  /// **'LVL'**
  String get statsColLevel;

  /// Per-level table column header. Capitals, about 6 characters (narrow column).
  ///
  /// In en, this message translates to:
  /// **'STARS'**
  String get statsColStars;

  /// Per-level table column header: your best moves / the minimum. Capitals.
  ///
  /// In en, this message translates to:
  /// **'MOVES'**
  String get statsColMoves;

  /// Per-level table column header. Capitals, about 5 characters (narrow column).
  ///
  /// In en, this message translates to:
  /// **'TIME'**
  String get statsColTime;

  /// Per-level table column header: points, abbreviated. Capitals, 3-4 characters (narrow column).
  ///
  /// In en, this message translates to:
  /// **'PTS'**
  String get statsColPoints;

  /// Screen reader label of a per-level row's moves cell.
  ///
  /// In en, this message translates to:
  /// **'{moves} moves, best possible {best}'**
  String statsMovesBestPossible(int moves, int best);

  /// Screen reader label of a per-level row's moves cell when the minimum is unknown.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{{count} move} other{{count} moves}}'**
  String statsMoves(int count);

  /// Badges tab heading: achievements unlocked so far.
  ///
  /// In en, this message translates to:
  /// **'{earned} of {total} unlocked'**
  String badgeUnlockedCount(int earned, int total);

  /// Status on an earned achievement card. Short.
  ///
  /// In en, this message translates to:
  /// **'Unlocked'**
  String get badgeUnlocked;

  /// Status on a one-off achievement not earned yet. Short.
  ///
  /// In en, this message translates to:
  /// **'Not yet'**
  String get badgeNotYet;

  /// Screen reader: progress toward an achievement, e.g. '4 of 10'.
  ///
  /// In en, this message translates to:
  /// **'{shown} of {target}'**
  String badgeProgress(int shown, int target);

  /// Screen reader label of an achievement card: its title, description, then 'Unlocked' or progress like '4 of 10'.
  ///
  /// In en, this message translates to:
  /// **'{title}: {description} {status}'**
  String badgeSemantic(String title, String description, String status);

  /// Achievement title (card heading, one line, ellipsized; keep it short).
  ///
  /// In en, this message translates to:
  /// **'First pour'**
  String get badgeFirstPourTitle;

  /// Achievement description (two lines max on a small card).
  ///
  /// In en, this message translates to:
  /// **'Clear your first level.'**
  String get badgeFirstPourDesc;

  /// Achievement title (one line, short). 'Par' is the minimum number of moves.
  ///
  /// In en, this message translates to:
  /// **'On par'**
  String get badgePar10Title;

  /// Achievement description (two lines max). Par = the proven minimum number of moves.
  ///
  /// In en, this message translates to:
  /// **'Clear 10 levels in exactly par.'**
  String get badgePar10Desc;

  /// Achievement title (one line, short).
  ///
  /// In en, this message translates to:
  /// **'Par master'**
  String get badgePar50Title;

  /// Achievement description (two lines max).
  ///
  /// In en, this message translates to:
  /// **'Clear 50 levels in exactly par.'**
  String get badgePar50Desc;

  /// Achievement title (one line, short): finishing a level without undo.
  ///
  /// In en, this message translates to:
  /// **'No take-backs'**
  String get badgeCleanClearTitle;

  /// Achievement description (two lines max).
  ///
  /// In en, this message translates to:
  /// **'Clear a level without using undo.'**
  String get badgeCleanClearDesc;

  /// Achievement title (one line, short).
  ///
  /// In en, this message translates to:
  /// **'Quick pour'**
  String get badgeSpeedyTitle;

  /// Achievement description (two lines max).
  ///
  /// In en, this message translates to:
  /// **'Clear a level in under 30 seconds.'**
  String get badgeSpeedyDesc;

  /// Achievement title (one line, short) for clearing 100 levels.
  ///
  /// In en, this message translates to:
  /// **'Centurion'**
  String get badgeLevels100Title;

  /// Achievement description (two lines max).
  ///
  /// In en, this message translates to:
  /// **'Clear 100 levels.'**
  String get badgeLevels100Desc;

  /// Achievement title (one line, short).
  ///
  /// In en, this message translates to:
  /// **'Star hoarder'**
  String get badgeStars300Title;

  /// Achievement description (two lines max).
  ///
  /// In en, this message translates to:
  /// **'Collect 300 stars.'**
  String get badgeStars300Desc;

  /// Achievement title (one line, short).
  ///
  /// In en, this message translates to:
  /// **'Flawless world'**
  String get badgeWorldPerfectTitle;

  /// Achievement description (two lines max): earn three stars on every level of one world.
  ///
  /// In en, this message translates to:
  /// **'Three-star every level in a world.'**
  String get badgeWorldPerfectDesc;

  /// Achievement title (one line, short).
  ///
  /// In en, this message translates to:
  /// **'Week of pours'**
  String get badgeStreak7Title;

  /// Achievement description (two lines max). 'Daily Pour' is the name of the daily challenge; keep it as the game names it.
  ///
  /// In en, this message translates to:
  /// **'Reach a 7-day Daily Pour streak.'**
  String get badgeStreak7Desc;

  /// Achievement title (one line, short).
  ///
  /// In en, this message translates to:
  /// **'Month of pours'**
  String get badgeStreak30Title;

  /// Achievement description (two lines max). 'Daily Pour' is the name of the daily challenge.
  ///
  /// In en, this message translates to:
  /// **'Reach a 30-day Daily Pour streak.'**
  String get badgeStreak30Desc;

  /// Achievement title (one line, short).
  ///
  /// In en, this message translates to:
  /// **'Treasure hunter'**
  String get badgeChests5Title;

  /// Achievement description (two lines max). Star chests are rewards opened with stars.
  ///
  /// In en, this message translates to:
  /// **'Open 5 star chests.'**
  String get badgeChests5Desc;

  /// Achievement title (one line, short).
  ///
  /// In en, this message translates to:
  /// **'Tough nut'**
  String get badgeHard5Title;

  /// Achievement description (two lines max). HARD is the in-game label on hard levels, in capitals.
  ///
  /// In en, this message translates to:
  /// **'Clear 5 HARD levels.'**
  String get badgeHard5Desc;

  /// Achievement title (one line, short).
  ///
  /// In en, this message translates to:
  /// **'Full week'**
  String get badgeEventFullTitle;

  /// Achievement description (two lines max).
  ///
  /// In en, this message translates to:
  /// **'Clear all seven boards of a weekly event.'**
  String get badgeEventFullDesc;

  /// Achievement title (one line, short).
  ///
  /// In en, this message translates to:
  /// **'Zen garden'**
  String get badgeZen25Title;

  /// Achievement description (two lines max). 'Zen mode' is the untimed relax mode.
  ///
  /// In en, this message translates to:
  /// **'Pour 25 boards in Zen mode.'**
  String get badgeZen25Desc;

  /// Generic cancel button.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// Generic close button.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get commonClose;

  /// Generic back button, also its accessibility label.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get commonBack;

  /// Generic acknowledge button.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get commonOk;

  /// Generic save button.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get commonSave;

  /// Button to retry something that failed.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get commonRetry;

  /// Dismisses an offer without accepting it.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get commonNotNow;

  /// A campaign level's name, e.g. 'Level 25'.
  ///
  /// In en, this message translates to:
  /// **'Level {level}'**
  String commonLevelN(int level);

  /// Game screen header title word when no level number follows. Short: it sits in the HUD.
  ///
  /// In en, this message translates to:
  /// **'Level'**
  String get playHudLevel;

  /// Game screen header title: a mode word followed by its number, e.g. 'Level 12' or 'Daily 5'. Short.
  ///
  /// In en, this message translates to:
  /// **'{label} {value}'**
  String playHudTitle(String label, String value);

  /// Small sticker next to the level title on a hard level (worth 1.5 times the points). Very short, uppercase.
  ///
  /// In en, this message translates to:
  /// **'HARD ×1.5'**
  String get playHudHard;

  /// Screen-reader label for the HARD ×1.5 sticker.
  ///
  /// In en, this message translates to:
  /// **'Hard level, one and a half times the points'**
  String get playHudHardLabel;

  /// Tiny caption under the move count in a 44px square. Must stay very short (about 6 characters).
  ///
  /// In en, this message translates to:
  /// **'MOVES'**
  String get playHudMoves;

  /// Screen-reader label for the move counter.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 move} other{{count} moves}}'**
  String playHudMovesLabel(int count);

  /// Par meter line under the progress bar: moves left before the run drops to 2 stars. One short line.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 move left for 3 stars} other{{count} moves left for 3 stars}}'**
  String playParLeftFor3Stars(int count);

  /// Par meter line once the player has used exactly par moves. One short line.
  ///
  /// In en, this message translates to:
  /// **'Par spent · 2 stars from here'**
  String get playParSpent;

  /// Par meter line: moves left before the run drops to 1 star. One short line.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 move left for 2 stars} other{{count} moves left for 2 stars}}'**
  String playParLeftFor2Stars(int count);

  /// Par meter line once only 1 star is still possible. One short line.
  ///
  /// In en, this message translates to:
  /// **'1 star from here · any finish'**
  String get playParOneStarFromHere;

  /// Par meter line far past par: finishing at all earns 1 star. One short line.
  ///
  /// In en, this message translates to:
  /// **'Any finish earns 1 star'**
  String get playParAnyFinish;

  /// Screen-reader label for the par meter. {words} is one of the par meter lines (e.g. '2 moves left for 3 stars').
  ///
  /// In en, this message translates to:
  /// **'{stars} star pace, {used} of par {par} moves. {words}'**
  String playParMeterLabel(int stars, int used, int par, String words);

  /// Screen-reader label for a board button (e.g. Hint) while it is working; tapping again cancels.
  ///
  /// In en, this message translates to:
  /// **'{label}, working. Tap to cancel'**
  String playHudBusyLabel(String label);

  /// Board action button: take back the last pour. Short (button under an icon).
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get playHudUndo;

  /// Board action button: show a good next move. Short (button under an icon).
  ///
  /// In en, this message translates to:
  /// **'Hint'**
  String get playHudHint;

  /// Board action button: start the level over. Also the action on the 'no way to finish' message. Short.
  ///
  /// In en, this message translates to:
  /// **'Restart'**
  String get playHudRestart;

  /// Screen-reader label for the '+ Tube' chip, which plays a rewarded video for one extra empty tube.
  ///
  /// In en, this message translates to:
  /// **'Watch a video for an extra tube'**
  String get playExtraTubeLabel;

  /// Small pill button offering one extra empty tube (for a video). Very short.
  ///
  /// In en, this message translates to:
  /// **'+ Tube'**
  String get playExtraTubeChip;

  /// Screen-reader label for a row of stars, e.g. '2 of 3 stars'.
  ///
  /// In en, this message translates to:
  /// **'{earned} of {total} stars'**
  String playStarsOfTotal(int earned, int total);

  /// Screen-reader label for the dimmed area behind a dialog; tapping it closes the dialog.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get playDismiss;

  /// Playful title of the dialog asked before leaving a half-played board (one of four picked at random).
  ///
  /// In en, this message translates to:
  /// **'Leaving so soon?'**
  String get playLeaveTitleSoSoon;

  /// Playful title of the dialog asked before leaving a half-played board (one of four picked at random).
  ///
  /// In en, this message translates to:
  /// **'The balls will miss you'**
  String get playLeaveTitleMissYou;

  /// Playful title of the dialog asked before leaving a half-played board (one of four picked at random).
  ///
  /// In en, this message translates to:
  /// **'Abandon the pour?'**
  String get playLeaveTitleAbandon;

  /// Playful title of the dialog asked before leaving a half-played board (one of four picked at random).
  ///
  /// In en, this message translates to:
  /// **'Walking out mid-pour?'**
  String get playLeaveTitleMidPour;

  /// Body of the leave-the-board dialog: says plainly what is lost.
  ///
  /// In en, this message translates to:
  /// **'Your moves and time on this board won\'t be saved.'**
  String get playLeaveBody;

  /// Leave-the-board dialog: button to stay on the board. Short (half-width button).
  ///
  /// In en, this message translates to:
  /// **'Keep pouring'**
  String get playLeaveKeepPouring;

  /// Leave-the-board dialog: button to leave. Short (half-width button).
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get playLeaveConfirm;

  /// Screen-reader label for the Skip link on the first-level tutorial caption.
  ///
  /// In en, this message translates to:
  /// **'Skip the tutorial'**
  String get playTutorialSkipLabel;

  /// Small link on the tutorial caption that ends the tutorial. Very short.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get playTutorialSkip;

  /// Screen-reader label for a one-time tip bubble; {text} is the tip, tapping dismisses it.
  ///
  /// In en, this message translates to:
  /// **'{text}. Dismiss'**
  String playTipBubbleLabel(String text);

  /// One-time tip on level 2 about par and the par meter bar. Shown in a toast; keep to two lines.
  ///
  /// In en, this message translates to:
  /// **'Finish within par for three stars. The bar shows how much you\'ve used.'**
  String get playTipPar;

  /// One-time tip on the first board whose tubes hold five balls instead of four.
  ///
  /// In en, this message translates to:
  /// **'Taller tubes! Each one holds five balls now.'**
  String get playTipTallTubes;

  /// One-time tip after 40 seconds stuck, pointing at the Hint button.
  ///
  /// In en, this message translates to:
  /// **'Stuck? Hint shows you a good next move.'**
  String get playTipHint;

  /// One-time tip the first time a run goes past par: undo costs nothing.
  ///
  /// In en, this message translates to:
  /// **'Past par? Undo is free — step back as far as you like.'**
  String get playTipUndo;

  /// Tutorial caption after the player completes their first tube. Max two lines.
  ///
  /// In en, this message translates to:
  /// **'Sorted! Now make every tube a single color.'**
  String get playGuideSorted;

  /// Tutorial caption while holding balls: tap a tube to pour into. Max two lines.
  ///
  /// In en, this message translates to:
  /// **'Now tap where they go: onto the same color, or an empty tube.'**
  String get playGuideDrop;

  /// Tutorial caption when the player picked up a different tube than the one the hand points at. Max two lines.
  ///
  /// In en, this message translates to:
  /// **'Tap the tube the hand points at to pick those up instead.'**
  String get playGuideWrongTube;

  /// First tutorial caption on level 1. Max two lines.
  ///
  /// In en, this message translates to:
  /// **'Tap a tube to pick up the balls on top.'**
  String get playGuideFirstTap;

  /// Tutorial caption after the first pour. Max two lines.
  ///
  /// In en, this message translates to:
  /// **'That\'s a pour! Keep going.'**
  String get playGuideFirstPour;

  /// Tutorial caption after the second pour onward. Max two lines.
  ///
  /// In en, this message translates to:
  /// **'Keep going: one color per tube.'**
  String get playGuideKeepGoing;

  /// Toast above the board while balls are picked up: how many are held and where they can go (tubes that accept them bounce).
  ///
  /// In en, this message translates to:
  /// **'Holding {count} · drop into a bouncing tube'**
  String playCoachHolding(int count);

  /// Title of the dialog asking before a rewarded video for an extra tube.
  ///
  /// In en, this message translates to:
  /// **'Watch a video for an extra tube?'**
  String get playExtraTubeAdTitle;

  /// Body of the extra-tube video dialog.
  ///
  /// In en, this message translates to:
  /// **'One more empty tube for this level. A level finished with an extra tube earns up to two stars.'**
  String get playExtraTubeAdBody;

  /// Toast when the player closed the extra-tube video early.
  ///
  /// In en, this message translates to:
  /// **'No tube — the video was not finished.'**
  String get playExtraTubeNotFinished;

  /// Toast when a watched video's extra tube could not be given now and is kept for next time.
  ///
  /// In en, this message translates to:
  /// **'Saved — your next tube is free.'**
  String get playExtraTubeSaved;

  /// Toast when no rewarded video can be shown.
  ///
  /// In en, this message translates to:
  /// **'No video available right now.'**
  String get playNoVideo;

  /// Toast when a rewarded video failed for another reason; nothing was charged.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Nothing was used.'**
  String get playRewardFailed;

  /// Toast when the player taps Hint while a hint is already on the board.
  ///
  /// In en, this message translates to:
  /// **'Your hint is showing: pour into the glowing tube.'**
  String get playHintShowing;

  /// Toast when no hint can be found; no hint or video was spent.
  ///
  /// In en, this message translates to:
  /// **'No hint for this position. Nothing was used.'**
  String get playHintNoneNothingUsed;

  /// Toast when the player closed the hint video early.
  ///
  /// In en, this message translates to:
  /// **'No hint — the video was not finished.'**
  String get playHintNotFinished;

  /// Toast when the board changed while the hint video played; the reward is kept for the next hint.
  ///
  /// In en, this message translates to:
  /// **'Your video is saved for the next hint.'**
  String get playHintVideoSaved;

  /// Toast after a hint video when no hint exists for the position; the reward is kept.
  ///
  /// In en, this message translates to:
  /// **'No hint for this position — your video is saved for the next one.'**
  String get playHintNoneVideoSaved;

  /// Toast when a free hint found nothing for the position (the hint was given back).
  ///
  /// In en, this message translates to:
  /// **'No hint available for this position.'**
  String get playHintNone;

  /// Toast after a rewarded hint video, pointing at the glowing destination tube.
  ///
  /// In en, this message translates to:
  /// **'Here is your hint — pour into the glowing tube.'**
  String get playHintHere;

  /// Dead-end hint toast when undoing cannot help; has a Restart action.
  ///
  /// In en, this message translates to:
  /// **'No way to finish from here. Restart to try another line.'**
  String get playDeadEndRestart;

  /// Dead-end hint toast, variant when the '+ Tube' button (an extra empty tube) is also offered.
  ///
  /// In en, this message translates to:
  /// **'No way to finish from here. Restart to try another line. Or tap + Tube for a spare tube.'**
  String get playDeadEndRestartTube;

  /// Dead-end hint toast: how many moves to undo to reach a solvable position. Has an 'Undo N' action.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{No way to finish from here. Undo 1 move to get back on track.} other{No way to finish from here. Undo {count} moves to get back on track.}}'**
  String playDeadEndUndo(int count);

  /// Dead-end hint toast, variant when the '+ Tube' button (an extra empty tube) is also offered.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{No way to finish from here. Undo 1 move to get back on track. Or tap + Tube for a spare tube.} other{No way to finish from here. Undo {count} moves to get back on track. Or tap + Tube for a spare tube.}}'**
  String playDeadEndUndoTube(int count);

  /// Action button on the dead-end toast: undo that many moves. Very short.
  ///
  /// In en, this message translates to:
  /// **'Undo {count}'**
  String playDeadEndUndoAction(int count);

  /// Title of the dialog asking before a rewarded video for a hint.
  ///
  /// In en, this message translates to:
  /// **'Watch a video for a hint?'**
  String get playHintAdTitle;

  /// Body of the hint video dialog while free hints remain.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{You have 1 free hint left.} other{You have {count} free hints left.}}'**
  String playHintAdFreeLeft(int count);

  /// Body of the hint video dialog once the free hints are gone.
  ///
  /// In en, this message translates to:
  /// **'Your free hints are used up. A short video earns one more.'**
  String get playHintAdNoneLeft;

  /// Confirm button on a rewarded-video dialog. Short (half-width button).
  ///
  /// In en, this message translates to:
  /// **'Watch'**
  String get playWatch;

  /// Title on the game screen when the level data failed to load.
  ///
  /// In en, this message translates to:
  /// **'Could not load levels'**
  String get playLoadFailed;

  /// Tiny badge on a tube that is finished (one color, full). Very short, uppercase.
  ///
  /// In en, this message translates to:
  /// **'SORTED!'**
  String get playTubeSorted;

  /// Big result title for a 3-star clear, over two lines (keep the line break). Very short words.
  ///
  /// In en, this message translates to:
  /// **'Perfect\nPour!'**
  String get playWinTitlePerfect;

  /// Big result title for a 2-star clear, over two lines (keep the line break). Very short words.
  ///
  /// In en, this message translates to:
  /// **'Nice\nPour!'**
  String get playWinTitleNice;

  /// Big result title for a 1-star clear. Very short.
  ///
  /// In en, this message translates to:
  /// **'Poured!'**
  String get playWinTitlePoured;

  /// Big caption where the board buttons were, during the final pour celebration. Short.
  ///
  /// In en, this message translates to:
  /// **'Last pour…'**
  String get playWinLastPour;

  /// Pill under 'Last pour…': moves used and par. Uppercase, short.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 MOVE · PAR {par}} other{{count} MOVES · PAR {par}}}'**
  String playWinMovesPar(int count, int par);

  /// Chip at the top of the result screen: level number and its band (world) name.
  ///
  /// In en, this message translates to:
  /// **'Level {level} · {band}'**
  String playWinLevelBand(int level, String band);

  /// Sticker on the result screen for a personal best. Very short, uppercase.
  ///
  /// In en, this message translates to:
  /// **'NEW BEST!'**
  String get playWinNewBest;

  /// Caption under the move count chip on the result screen. Short (a third of the screen width).
  ///
  /// In en, this message translates to:
  /// **'moves · par {par}'**
  String playWinMovesChip(int par);

  /// Caption under the time chip when the run had no clock (the tutorial). Short, lowercase.
  ///
  /// In en, this message translates to:
  /// **'untimed'**
  String get playWinUntimed;

  /// Caption under the time chip for the player's fastest clear of the level. Short, lowercase.
  ///
  /// In en, this message translates to:
  /// **'fastest yet!'**
  String get playWinFastest;

  /// Caption under the time chip on the result screen. Short, lowercase.
  ///
  /// In en, this message translates to:
  /// **'time'**
  String get playWinTime;

  /// Small sticker on the time chip when the clear beat the time par. Very short, uppercase.
  ///
  /// In en, this message translates to:
  /// **'UNDER PAR!'**
  String get playWinUnderPar;

  /// Caption under the points chip on the result screen. Short, lowercase.
  ///
  /// In en, this message translates to:
  /// **'points'**
  String get playWinPoints;

  /// Label over the world progress bar on the result screen. {band} is already uppercase. Uppercase, one line.
  ///
  /// In en, this message translates to:
  /// **'WORLD {world} · {band}'**
  String playWinWorldBand(int world, String band);

  /// Result screen nudge to replay, when the clear used the extra tube (capped at 2 stars). Two lines max.
  ///
  /// In en, this message translates to:
  /// **'Three stars need a clear without the extra tube.'**
  String get playWinTryAssisted;

  /// Result screen nudge to replay: par, moves taken, and how many moves short of 3 stars. Two lines max.
  ///
  /// In en, this message translates to:
  /// **'{short, plural, =1{Par {par}, you took {took}. One move from 3★.} other{Par {par}, you took {took}. {short} moves from 3★.}}'**
  String playWinTryShort(int par, int took, int short);

  /// Result screen nudge to replay for 3 stars. Two lines max.
  ///
  /// In en, this message translates to:
  /// **'Par {par}. Three stars are in reach.'**
  String playWinTryInReach(int par);

  /// Compact button on the result screen to replay for three stars. Very short, uppercase.
  ///
  /// In en, this message translates to:
  /// **'TRY FOR 3★'**
  String get playWinTryButton;

  /// Screen-reader label for the TRY FOR 3★ button.
  ///
  /// In en, this message translates to:
  /// **'Replay this level for three stars'**
  String get playWinTryButtonLabel;

  /// Screen-reader label for the replay icon button on the result screen.
  ///
  /// In en, this message translates to:
  /// **'Replay this level'**
  String get playWinReplayLabel;

  /// Screen-reader label for the home icon button on the result screen.
  ///
  /// In en, this message translates to:
  /// **'Back to the home screen'**
  String get playWinHomeLabel;

  /// Main button on the result screen. Uppercase, short (large font).
  ///
  /// In en, this message translates to:
  /// **'NEXT LEVEL'**
  String get playWinNextLevel;

  /// Main result-screen button when there is no next level. Uppercase, short (large font).
  ///
  /// In en, this message translates to:
  /// **'BACK TO LEVELS'**
  String get playWinBackToLevels;

  /// Screen-reader label for the star chest card before the next chest is earned.
  ///
  /// In en, this message translates to:
  /// **'Next star chest at {stars} stars'**
  String playChestNextAtLabel(int stars);

  /// Screen-reader label for the star chest card when a chest is ready.
  ///
  /// In en, this message translates to:
  /// **'Open star chest'**
  String get playChestOpenLabel;

  /// Star chest card text when a chest can be opened. One line.
  ///
  /// In en, this message translates to:
  /// **'A star chest is ready!'**
  String get playChestReady;

  /// Star chest card text above its progress bar: the star total that earns the next chest. One short line.
  ///
  /// In en, this message translates to:
  /// **'Next chest at {stars} ★'**
  String playChestNextAt(int stars);

  /// Small button on the star chest card. Very short, uppercase.
  ///
  /// In en, this message translates to:
  /// **'OPEN'**
  String get playChestOpen;

  /// Toast when doubling a chest's reward after the video failed.
  ///
  /// In en, this message translates to:
  /// **'Could not double it this time.'**
  String get playChestDoubleFailed;

  /// Toast when the player closed the chest-doubling video early.
  ///
  /// In en, this message translates to:
  /// **'Not doubled — the video was not finished.'**
  String get playChestDoubleNotFinished;

  /// Star chest dialog title while it is being opened. Short.
  ///
  /// In en, this message translates to:
  /// **'Opening…'**
  String get playChestOpening;

  /// Star chest dialog title once opened: which chest this is (1st, 2nd, ...). Short.
  ///
  /// In en, this message translates to:
  /// **'Star chest {index}'**
  String playChestTitle(int index);

  /// Star chest dialog title when the server has not counted the stars yet. Short.
  ///
  /// In en, this message translates to:
  /// **'Almost there'**
  String get playChestNotYetTitle;

  /// Star chest dialog title when the chest was already opened. Short.
  ///
  /// In en, this message translates to:
  /// **'Already open'**
  String get playChestAlreadyOpenTitle;

  /// Star chest dialog title when opening failed. Short.
  ///
  /// In en, this message translates to:
  /// **'Could not open it'**
  String get playChestFailedTitle;

  /// Star chest dialog body when the server has not counted the newest stars yet.
  ///
  /// In en, this message translates to:
  /// **'Your newest stars are still on their way to the server. Try again in a moment.'**
  String get playChestNotYetNote;

  /// Star chest dialog body when the chest was opened elsewhere.
  ///
  /// In en, this message translates to:
  /// **'This chest was opened on another device.'**
  String get playChestAlreadyOpenNote;

  /// Star chest dialog body when opening failed (network).
  ///
  /// In en, this message translates to:
  /// **'Check your connection and try again.'**
  String get playChestFailedNote;

  /// Big number on a chest reward chip, e.g. '+2'.
  ///
  /// In en, this message translates to:
  /// **'+{count}'**
  String playChestRewardCount(int count);

  /// Caption under the '+N' hints reward chip in the star chest. One short word.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, other{hints}}'**
  String playChestHintsCaption(int count);

  /// Caption under the '+N' extra tubes reward chip in the star chest. Short.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{extra tube} other{extra tubes}}'**
  String playChestTubesCaption(int count);

  /// Star chest reward pill for a new cosmetic. {name} is e.g. 'Glossy ball skin' or 'a new look'.
  ///
  /// In en, this message translates to:
  /// **'Unlocked: {name}'**
  String playChestUnlocked(String name);

  /// A cosmetic's name in the star chest: a ball skin. {skin} is the skin's name.
  ///
  /// In en, this message translates to:
  /// **'{skin} ball skin'**
  String playChestBallSkinName(String skin);

  /// A cosmetic's name in the star chest: a tube theme. {theme} is the theme's name.
  ///
  /// In en, this message translates to:
  /// **'{theme} tubes'**
  String playChestTubeThemeName(String theme);

  /// Fallback cosmetic name in 'Unlocked: a new look' when the app does not know the item.
  ///
  /// In en, this message translates to:
  /// **'a new look'**
  String get playChestNewLook;

  /// Small note under the chest rewards: hints and extra tubes are banked; Hint and + Tube are button names.
  ///
  /// In en, this message translates to:
  /// **'Saved for when you need them. Hint and + Tube use these first.'**
  String get playChestSavedNote;

  /// Chest dialog button while the doubling video loads. Fits one button line.
  ///
  /// In en, this message translates to:
  /// **'Loading video…'**
  String get playChestLoadingVideo;

  /// Chest dialog button: watch a video to double the reward. Fits one button line.
  ///
  /// In en, this message translates to:
  /// **'Double it with a video'**
  String get playChestDouble;

  /// Chest dialog button that closes it after a reward. Short.
  ///
  /// In en, this message translates to:
  /// **'Collect'**
  String get playChestCollect;

  /// Screen-reader label for the level clock. {time} is a spoken duration.
  ///
  /// In en, this message translates to:
  /// **'Time {time}'**
  String playClockLabel(String time);

  /// Screen-reader label for the level clock with its time par and the score bonus (plus) or penalty (minus) in percent. {sign} is 'plus' or 'minus'.
  ///
  /// In en, this message translates to:
  /// **'Time {time} of par {par}, {sign, select, plus{plus} other{minus}} {percent} percent points'**
  String playClockDetailLabel(
    String time,
    String par,
    String sign,
    int percent,
  );

  /// Tiny chip next to the clock: how the time changes the points, e.g. '+25% pts'. {sign} is +, − or ±. Very short.
  ///
  /// In en, this message translates to:
  /// **'{sign}{percent}% pts'**
  String playClockBonusChip(String sign, int percent);

  /// Screen-reader label for the pouring-balls loading animation.
  ///
  /// In en, this message translates to:
  /// **'Loading'**
  String get playLoading;

  /// Screen-reader label for the small busy indicator.
  ///
  /// In en, this message translates to:
  /// **'Working'**
  String get playWorking;

  /// Name of the endless relaxed mode, as the screen title and board header. Short.
  ///
  /// In en, this message translates to:
  /// **'Zen'**
  String get playZenTitle;

  /// Intro line on the Zen mode picker.
  ///
  /// In en, this message translates to:
  /// **'Endless boards. No clock, no stars, no leaderboard — just pour.'**
  String get playZenIntro;

  /// Zen mode pace option with the fewest colors. One short word (large font).
  ///
  /// In en, this message translates to:
  /// **'Calm'**
  String get playZenPaceCalm;

  /// Zen mode pace option with a medium number of colors. One short word (large font).
  ///
  /// In en, this message translates to:
  /// **'Steady'**
  String get playZenPaceSteady;

  /// Zen mode pace option with the most colors. One short word (large font).
  ///
  /// In en, this message translates to:
  /// **'Deep'**
  String get playZenPaceDeep;

  /// Under a Zen pace option: how many ball colors its boards use (always 4 or more).
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 color} other{{count} colors}}'**
  String playZenPaceColors(int count);

  /// Screen-reader label for a Zen pace option: its name and how many colors (always 4 or more).
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{{pace}, 1 color} other{{pace}, {count} colors}}'**
  String playZenPaceLabel(String pace, int count);

  /// Zen board header subtitle: the pace name and how many boards were finished this session. Short.
  ///
  /// In en, this message translates to:
  /// **'{pace} · {count} poured'**
  String playZenBandPoured(String pace, int count);

  /// Shown when a Zen board is finished, with the session's running count of boards (1 or more).
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Poured!} other{Poured! {count} so far.}}'**
  String playZenPoured(int count);

  /// Button for the next Zen board. Uppercase, very short.
  ///
  /// In en, this message translates to:
  /// **'NEXT'**
  String get playZenNext;

  /// Body of the leave dialog on a Zen board: what is and is not lost.
  ///
  /// In en, this message translates to:
  /// **'This board\'s moves won\'t be saved. Your poured count stays.'**
  String get playZenLeaveBody;

  /// Toast when Hint finds no way to finish the Zen board.
  ///
  /// In en, this message translates to:
  /// **'No way to finish from here. Undo or restart.'**
  String get playZenDeadEnd;

  /// Toast when no Zen hint is available.
  ///
  /// In en, this message translates to:
  /// **'No hint for this position right now.'**
  String get playZenNoHint;

  /// Settings screen header title; keep short.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// Settings section label over sound, music, haptics and motion; shown in capitals; one short word.
  ///
  /// In en, this message translates to:
  /// **'Feel'**
  String get settingsSectionFeel;

  /// Settings section label over the accessibility (bold symbols) toggle; shown in capitals; keep short.
  ///
  /// In en, this message translates to:
  /// **'Visibility'**
  String get settingsSectionVisibility;

  /// Settings section label over the name and leaderboard-visibility rows; shown in capitals; keep short.
  ///
  /// In en, this message translates to:
  /// **'Leaderboard'**
  String get settingsSectionLeaderboard;

  /// Settings section label over the notification switches; shown in capitals; keep short.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get settingsSectionNotifications;

  /// Settings section label over help, rating, collection and purchase rows; shown in capitals; keep short.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get settingsSectionSupport;

  /// Settings section label over sign-in and legal rows; shown in capitals; keep short.
  ///
  /// In en, this message translates to:
  /// **'Account & about'**
  String get settingsSectionAccount;

  /// Settings section label over reset progress and delete account; shown in capitals in red; keep short.
  ///
  /// In en, this message translates to:
  /// **'Danger zone'**
  String get settingsSectionDanger;

  /// Settings toggle row title for sound effects; one line, keep short.
  ///
  /// In en, this message translates to:
  /// **'Sound effects'**
  String get settingsSoundTitle;

  /// Explanation under the Sound effects toggle; may wrap but keep brief.
  ///
  /// In en, this message translates to:
  /// **'Pours, buttons and rewards'**
  String get settingsSoundDetail;

  /// Accessibility label of the sound effects volume slider.
  ///
  /// In en, this message translates to:
  /// **'Effects volume'**
  String get settingsSoundVolume;

  /// Settings toggle row title for background music; keep short.
  ///
  /// In en, this message translates to:
  /// **'Music'**
  String get settingsMusicTitle;

  /// Explanation under the Music toggle: the game never interrupts the player's own music app.
  ///
  /// In en, this message translates to:
  /// **'Never plays over your own music'**
  String get settingsMusicDetail;

  /// Accessibility label of the music volume slider.
  ///
  /// In en, this message translates to:
  /// **'Music volume'**
  String get settingsMusicVolume;

  /// Settings toggle row title for vibration feedback; keep short.
  ///
  /// In en, this message translates to:
  /// **'Haptics'**
  String get settingsHapticsTitle;

  /// Explanation under the Haptics toggle.
  ///
  /// In en, this message translates to:
  /// **'A tick as each ball lands'**
  String get settingsHapticsDetail;

  /// Settings row title for the screen refresh-rate choice; keep short.
  ///
  /// In en, this message translates to:
  /// **'Smooth motion'**
  String get settingsSmoothMotionTitle;

  /// Segmented option: pick the refresh rate automatically. Very short (one of three tabs).
  ///
  /// In en, this message translates to:
  /// **'Auto'**
  String get settingsSmoothMotionAuto;

  /// Segmented option: always run at 60 Hz. Very short (one of three tabs).
  ///
  /// In en, this message translates to:
  /// **'60 Hz'**
  String get settingsSmoothMotion60;

  /// Segmented option: always the screen's fastest refresh rate. Very short (one of three tabs).
  ///
  /// In en, this message translates to:
  /// **'Max'**
  String get settingsSmoothMotionMax;

  /// Smooth motion detail line when the screen's refresh rate is not known yet.
  ///
  /// In en, this message translates to:
  /// **'Auto uses your screen\'s fastest rate if this phone keeps up'**
  String get settingsMotionUnknown;

  /// Smooth motion detail line when the screen has a single refresh rate. {max} is a number like 60 or 59.9.
  ///
  /// In en, this message translates to:
  /// **'This screen only runs at {max} Hz'**
  String settingsMotionFixed(String max);

  /// Smooth motion detail line when the phone's power saving mode limits the refresh rate. {current} is a number like 60.
  ///
  /// In en, this message translates to:
  /// **'Battery Saver is holding it at {current} Hz'**
  String settingsMotionBatterySaver(String current);

  /// Smooth motion detail line in Auto after the game stepped down because frames were dropped. Both are numbers like 60 and 120.
  ///
  /// In en, this message translates to:
  /// **'Running at {current} Hz · this phone stuttered at {max} Hz'**
  String settingsMotionAutoStuttered(String current, String max);

  /// Smooth motion detail line in Auto. {current} is a number like 120.
  ///
  /// In en, this message translates to:
  /// **'Running at {current} Hz · drops to 60 Hz if it stutters'**
  String settingsMotionAuto(String current);

  /// Smooth motion detail line when 60 Hz was chosen but the phone's own setting forces a higher rate. {current} is a number like 90.
  ///
  /// In en, this message translates to:
  /// **'Your phone\'s display setting keeps it at {current} Hz'**
  String settingsMotionPinnedByPhone(String current);

  /// Smooth motion detail line when 60 Hz is chosen. Both are numbers like 60 and 120.
  ///
  /// In en, this message translates to:
  /// **'Running at {current} Hz · this screen can do {max} Hz'**
  String settingsMotionStandard(String current, String max);

  /// Smooth motion detail line when Max is chosen. {current} is a number like 120.
  ///
  /// In en, this message translates to:
  /// **'Running at {current} Hz, the fastest this screen goes'**
  String settingsMotionMax(String current);

  /// Settings toggle title: draws the shapes on the balls with heavier strokes; keep short.
  ///
  /// In en, this message translates to:
  /// **'Bold symbols'**
  String get settingsBoldSymbolsTitle;

  /// Explanation under Bold symbols. Name the condition (color blindness) in the words players search for.
  ///
  /// In en, this message translates to:
  /// **'Stronger shapes for color vision deficiency'**
  String get settingsBoldSymbolsDetail;

  /// Settings row title that opens the leaderboard name editor; one line.
  ///
  /// In en, this message translates to:
  /// **'Change your name'**
  String get settingsRenameTitle;

  /// Detail under Change your name; one line, ellipsized if long.
  ///
  /// In en, this message translates to:
  /// **'How you appear on the boards'**
  String get settingsRenameDetail;

  /// Settings toggle title: list the player on public leaderboards; one line.
  ///
  /// In en, this message translates to:
  /// **'Show me on leaderboards'**
  String get settingsShowOnBoardsTitle;

  /// Explanation under Show me on leaderboards.
  ///
  /// In en, this message translates to:
  /// **'Off hides your name and rank. Stars still count.'**
  String get settingsShowOnBoardsDetail;

  /// Settings row title that replays the tutorial level; one line.
  ///
  /// In en, this message translates to:
  /// **'How to play'**
  String get settingsHowToPlayTitle;

  /// Detail under How to play; one line, ellipsized if long.
  ///
  /// In en, this message translates to:
  /// **'Replay the guided first level'**
  String get settingsHowToPlayDetail;

  /// Settings row title and header of the FAQ screen; keep short.
  ///
  /// In en, this message translates to:
  /// **'Questions'**
  String get settingsQuestionsTitle;

  /// Detail under Questions (the FAQ); one line, ellipsized if long.
  ///
  /// In en, this message translates to:
  /// **'Stars, hints, the clock and more'**
  String get settingsQuestionsDetail;

  /// Settings row title that opens the store listing to leave a rating; one line. 'Pourfect' is the game's name.
  ///
  /// In en, this message translates to:
  /// **'Rate Pourfect'**
  String get settingsRateTitle;

  /// Detail under Rate Pourfect; one line, ellipsized if long.
  ///
  /// In en, this message translates to:
  /// **'Tell other players what you think'**
  String get settingsRateDetail;

  /// Settings row title and header of the Collection screen (ball skins and tube themes); keep short.
  ///
  /// In en, this message translates to:
  /// **'Collection'**
  String get settingsCollectionTitle;

  /// Detail under Collection; one line, ellipsized if long.
  ///
  /// In en, this message translates to:
  /// **'Ball skins and tube themes'**
  String get settingsCollectionDetail;

  /// Settings row title that restores in-app purchases; one line.
  ///
  /// In en, this message translates to:
  /// **'Restore purchases'**
  String get settingsRestoreTitle;

  /// Detail under Restore purchases, naming the two products; one line.
  ///
  /// In en, this message translates to:
  /// **'Remove Ads or the Skin pack'**
  String get settingsRestoreDetail;

  /// Toast after Restore purchases finishes.
  ///
  /// In en, this message translates to:
  /// **'Purchases restored, if there were any.'**
  String get settingsRestoreDone;

  /// Settings row title for the Remove Ads purchase, also its accessibility label; one line.
  ///
  /// In en, this message translates to:
  /// **'Remove ads'**
  String get settingsRemoveAdsTitle;

  /// Detail under Remove ads: what it does and does not remove. Keep both halves.
  ///
  /// In en, this message translates to:
  /// **'No ads between levels. Hint videos stay.'**
  String get settingsRemoveAdsDetail;

  /// Settings row shown instead of the purchase once ads are removed; one line.
  ///
  /// In en, this message translates to:
  /// **'Ads removed — thank you'**
  String get settingsAdsRemoved;

  /// Toast after buying Remove Ads.
  ///
  /// In en, this message translates to:
  /// **'Thank you. Ads between levels are off.'**
  String get settingsPurchaseThanks;

  /// Toast when Remove Ads was already bought.
  ///
  /// In en, this message translates to:
  /// **'Already purchased — ads are off.'**
  String get settingsPurchaseAlreadyOwned;

  /// Toast when the Remove Ads payment is still pending.
  ///
  /// In en, this message translates to:
  /// **'Payment pending. Ads will switch off once it clears.'**
  String get settingsPurchasePending;

  /// Toast when the app store cannot be reached for a purchase (Settings and Collection).
  ///
  /// In en, this message translates to:
  /// **'The store is not available on this device right now.'**
  String get settingsStoreUnavailable;

  /// Toast when a purchase failed (Settings and Collection).
  ///
  /// In en, this message translates to:
  /// **'The purchase did not go through. You have not been charged.'**
  String get settingsPurchaseFailed;

  /// Toast when the store listing could not be opened from Rate Pourfect.
  ///
  /// In en, this message translates to:
  /// **'Could not open the store.'**
  String get settingsStoreOpenFailed;

  /// Toast when a legal document link could not open the web browser.
  ///
  /// In en, this message translates to:
  /// **'Could not open the browser.'**
  String get settingsBrowserOpenFailed;

  /// Settings row title (and player card line) for a signed-in player; keep short.
  ///
  /// In en, this message translates to:
  /// **'Signed in'**
  String get settingsSignedIn;

  /// Detail under Signed in when there is no email to show; one line.
  ///
  /// In en, this message translates to:
  /// **'Your progress moves with you'**
  String get settingsSignedInDetail;

  /// Settings row title that opens sign-in for a guest player; one line.
  ///
  /// In en, this message translates to:
  /// **'Save your progress'**
  String get settingsSaveProgressTitle;

  /// Detail under Save your progress; one line, ellipsized if long.
  ///
  /// In en, this message translates to:
  /// **'Keep your stars if you change phones'**
  String get settingsSaveProgressDetail;

  /// Settings row title that opens the privacy policy web page; one line.
  ///
  /// In en, this message translates to:
  /// **'Privacy policy'**
  String get settingsPrivacyPolicy;

  /// Settings row title and dialog title for terms of use, refund policy and open-source licenses; keep short.
  ///
  /// In en, this message translates to:
  /// **'Terms & licenses'**
  String get settingsTermsAndLicenses;

  /// Button in the Terms & licenses dialog.
  ///
  /// In en, this message translates to:
  /// **'Terms of use'**
  String get settingsTermsOfUse;

  /// Button in the Terms & licenses dialog.
  ///
  /// In en, this message translates to:
  /// **'Refund policy'**
  String get settingsRefundPolicy;

  /// Button in the Terms & licenses dialog that opens the license page.
  ///
  /// In en, this message translates to:
  /// **'Open-source licenses'**
  String get settingsOpenSourceLicenses;

  /// Settings row title that reopens the advertising consent form; one line.
  ///
  /// In en, this message translates to:
  /// **'Ad privacy options'**
  String get settingsAdPrivacyTitle;

  /// Detail under Ad privacy options; one line, ellipsized if long.
  ///
  /// In en, this message translates to:
  /// **'Change what you agreed to for advertising'**
  String get settingsAdPrivacyDetail;

  /// Danger zone row title; one line.
  ///
  /// In en, this message translates to:
  /// **'Reset progress'**
  String get settingsResetRowTitle;

  /// Detail under Reset progress; one line, ellipsized if long.
  ///
  /// In en, this message translates to:
  /// **'Erase every star and start from level 1'**
  String get settingsResetRowDetail;

  /// Confirmation dialog title for resetting progress.
  ///
  /// In en, this message translates to:
  /// **'Reset progress?'**
  String get settingsResetTitle;

  /// Reset confirmation body when no level has been solved.
  ///
  /// In en, this message translates to:
  /// **'There is nothing to reset yet.'**
  String get settingsResetNothing;

  /// Reset confirmation body. {count} is how many levels the player has solved.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{This erases every star and best score across 1 solved level, and locks everything after level 1 again. It cannot be undone.} other{This erases every star and best score across {count} solved levels, and locks everything after level 1 again. It cannot be undone.}}'**
  String settingsResetBody(int count);

  /// Cancel button on the reset-progress and delete-account confirmations; short.
  ///
  /// In en, this message translates to:
  /// **'Keep it'**
  String get settingsKeepIt;

  /// Destructive confirm button on the reset-progress dialog; short.
  ///
  /// In en, this message translates to:
  /// **'Erase everything'**
  String get settingsResetConfirm;

  /// Toast after progress was reset.
  ///
  /// In en, this message translates to:
  /// **'Progress reset.'**
  String get settingsResetDone;

  /// Sign-out confirmation dialog title.
  ///
  /// In en, this message translates to:
  /// **'Sign out?'**
  String get settingsSignOutTitle;

  /// Sign-out confirmation body.
  ///
  /// In en, this message translates to:
  /// **'Your progress stays on this phone. You can sign back in any time to pick it up somewhere else.'**
  String get settingsSignOutBody;

  /// Cancel button on the sign-out confirmation; short.
  ///
  /// In en, this message translates to:
  /// **'Stay signed in'**
  String get settingsSignOutStay;

  /// Confirm button on the sign-out confirmation; short.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get settingsSignOutConfirm;

  /// Toast when a leaderboard or notification setting could not be saved.
  ///
  /// In en, this message translates to:
  /// **'Could not reach the server, so nothing changed.'**
  String get settingsServerUnreachable;

  /// Danger zone row title; one line.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get settingsDeleteRowTitle;

  /// Detail under Delete account; one line, ellipsized if long.
  ///
  /// In en, this message translates to:
  /// **'Remove your account and everything with it'**
  String get settingsDeleteRowDetail;

  /// Delete-account confirmation dialog title.
  ///
  /// In en, this message translates to:
  /// **'Delete your account?'**
  String get settingsDeleteTitle;

  /// Delete-account confirmation body; two paragraphs. 'Remove Ads' is the purchase's name.
  ///
  /// In en, this message translates to:
  /// **'This removes your account, your stars, your streak and your leaderboard entry, on this phone and on our server. It cannot be undone.\n\nRemove Ads is not affected — it belongs to the store account you bought it with, and restores if you play again.'**
  String get settingsDeleteBody;

  /// Destructive confirm button on the delete-account dialog; short.
  ///
  /// In en, this message translates to:
  /// **'Delete everything'**
  String get settingsDeleteConfirm;

  /// Toast when account deletion failed because the server was unreachable.
  ///
  /// In en, this message translates to:
  /// **'Could not reach the server. Nothing was deleted — try again when you are back online.'**
  String get settingsDeleteServerRefused;

  /// Toast when account deletion failed because the login could not be verified.
  ///
  /// In en, this message translates to:
  /// **'Could not confirm it is you. Sign in again, then delete your account — nothing has been deleted yet.'**
  String get settingsDeleteNotAuthenticated;

  /// Small footer at the bottom of Settings: the game's name and version, e.g. 'Pourfect 2.8.0 (20)'.
  ///
  /// In en, this message translates to:
  /// **'Pourfect {version}'**
  String settingsFooterVersion(String version);

  /// Small footer at the bottom of Settings: game name, version, and how many levels the game has (each proven solvable).
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Pourfect {version} · made with 1 proven-solvable board} other{Pourfect {version} · made with {count} proven-solvable boards}}'**
  String settingsFooterVersionBoards(int count, String version);

  /// Shown on the player card while the server has not yet assigned a leaderboard name.
  ///
  /// In en, this message translates to:
  /// **'Naming you…'**
  String get settingsNamingYou;

  /// Accessibility label of the player card, which opens the name editor.
  ///
  /// In en, this message translates to:
  /// **'Your name'**
  String get settingsYourName;

  /// Player card line for a player who has not signed in; one line.
  ///
  /// In en, this message translates to:
  /// **'Playing as a guest'**
  String get settingsGuest;

  /// Tiny caps label under the solved-levels count on the player card; very short.
  ///
  /// In en, this message translates to:
  /// **'SOLVED'**
  String get settingsStatSolved;

  /// Tiny caps label under the stars count on the player card; very short.
  ///
  /// In en, this message translates to:
  /// **'STARS'**
  String get settingsStatStars;

  /// Settings row title shown while the phone blocks notifications; one line.
  ///
  /// In en, this message translates to:
  /// **'Turn on notifications'**
  String get settingsNotifyTurnOnTitle;

  /// Detail under Turn on notifications when the system setting is off; one line.
  ///
  /// In en, this message translates to:
  /// **'Off in your phone\'s settings. Tap to open them.'**
  String get settingsNotifyDeniedDetail;

  /// Detail under Turn on notifications before permission was asked; one line.
  ///
  /// In en, this message translates to:
  /// **'Pourfect can\'t notify you yet'**
  String get settingsNotifyNotYetDetail;

  /// Notification toggle title. 'Daily Pour' is the daily challenge's name; keep short.
  ///
  /// In en, this message translates to:
  /// **'Daily Pour reminders'**
  String get settingsRemindersTitle;

  /// Explanation under Daily Pour reminders.
  ///
  /// In en, this message translates to:
  /// **'Morning and evening, never more than two a day'**
  String get settingsRemindersDetail;

  /// Notification toggle title for announcements; keep short.
  ///
  /// In en, this message translates to:
  /// **'Game news'**
  String get settingsNewsTitle;

  /// Explanation under Game news.
  ///
  /// In en, this message translates to:
  /// **'New worlds and announcements'**
  String get settingsNewsDetail;

  /// Accessibility label of a settings switch that is on. {title} is the row title.
  ///
  /// In en, this message translates to:
  /// **'{title}, on'**
  String settingsToggleOn(String title);

  /// Accessibility label of a settings switch that is off. {title} is the row title.
  ///
  /// In en, this message translates to:
  /// **'{title}, off'**
  String settingsToggleOff(String title);

  /// FAQ section label; shown in capitals; keep short.
  ///
  /// In en, this message translates to:
  /// **'Playing'**
  String get settingsFaqSectionPlaying;

  /// FAQ section label over undo, hints and power-up questions; shown in capitals; keep short.
  ///
  /// In en, this message translates to:
  /// **'Stuck?'**
  String get settingsFaqSectionStuck;

  /// FAQ section label; shown in capitals; keep short.
  ///
  /// In en, this message translates to:
  /// **'Your progress'**
  String get settingsFaqSectionProgress;

  /// FAQ section label; shown in capitals; keep short.
  ///
  /// In en, this message translates to:
  /// **'Ads & sound'**
  String get settingsFaqSectionAds;

  /// FAQ question.
  ///
  /// In en, this message translates to:
  /// **'How do I play?'**
  String get settingsFaqHowToPlayQ;

  /// FAQ answer. 'Settings → How to play' must match the Settings screen and the How to play row titles.
  ///
  /// In en, this message translates to:
  /// **'Tap a tube to pick up its top balls, then tap another tube to pour them in. Balls only land on the same color or in an empty tube. Sort every tube to one color and the level is done. Settings → How to play replays the guided first level.'**
  String get settingsFaqHowToPlayA;

  /// FAQ question.
  ///
  /// In en, this message translates to:
  /// **'What do the stars mean?'**
  String get settingsFaqStarsQ;

  /// FAQ answer. The thresholds (par, 1.5x par) are game rules; keep them exact.
  ///
  /// In en, this message translates to:
  /// **'Stars count moves, nothing else. Finish in par or fewer for three stars, within one and a half times par for two, and any finish earns one. Par is the fewest moves the level can be solved in.'**
  String get settingsFaqStarsA;

  /// FAQ question.
  ///
  /// In en, this message translates to:
  /// **'Does the clock cost me stars?'**
  String get settingsFaqClockQ;

  /// FAQ answer.
  ///
  /// In en, this message translates to:
  /// **'Never. Time only changes your points. Beat the time par for bonus points, or take as long as you like and keep every star.'**
  String get settingsFaqClockA;

  /// FAQ question.
  ///
  /// In en, this message translates to:
  /// **'Is every level solvable?'**
  String get settingsFaqSolvableQ;

  /// FAQ answer.
  ///
  /// In en, this message translates to:
  /// **'Yes. Every board was solved before it shipped, and par comes from that solution, so it is always reachable.'**
  String get settingsFaqSolvableA;

  /// FAQ question. 'Daily Pour' is the daily challenge's name.
  ///
  /// In en, this message translates to:
  /// **'What is the Daily Pour?'**
  String get settingsFaqDailyQ;

  /// FAQ answer.
  ///
  /// In en, this message translates to:
  /// **'A new board every day, with its own leaderboard. It needs an internet connection. The campaign levels do not.'**
  String get settingsFaqDailyA;

  /// FAQ question.
  ///
  /// In en, this message translates to:
  /// **'Is undo limited?'**
  String get settingsFaqUndoQ;

  /// FAQ answer.
  ///
  /// In en, this message translates to:
  /// **'No. Undo is free and unlimited, on every level.'**
  String get settingsFaqUndoA;

  /// FAQ question.
  ///
  /// In en, this message translates to:
  /// **'How do hints work?'**
  String get settingsFaqHintsQ;

  /// FAQ answer. {count} is the number of free hints the game gives.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Your first hint is free. After that, a short video earns one. If a hint cannot be found, the video still counts toward your next one.} other{Your first {count} hints are free. After that, a short video earns one. If a hint cannot be found, the video still counts toward your next one.}}'**
  String settingsFaqHintsA(int count);

  /// FAQ question. '+ Tube' is the in-game button's label.
  ///
  /// In en, this message translates to:
  /// **'What is the + Tube button?'**
  String get settingsFaqTubeQ;

  /// FAQ answer.
  ///
  /// In en, this message translates to:
  /// **'When your moves reach par, or a hint shows there is no way to finish, you can watch a video for an extra empty tube, up to two per attempt. Undo will not take it away. A level finished with an extra tube earns up to two stars.'**
  String get settingsFaqTubeA;

  /// FAQ question. 'HARD' is the badge's text on the level.
  ///
  /// In en, this message translates to:
  /// **'What are HARD levels?'**
  String get settingsFaqHardQ;

  /// FAQ answer. 'HARD' must match the badge's text.
  ///
  /// In en, this message translates to:
  /// **'The toughest level in every ten wears a red HARD badge. It plays like any other level, and it is worth one and a half times the points.'**
  String get settingsFaqHardA;

  /// FAQ question.
  ///
  /// In en, this message translates to:
  /// **'What are star chests?'**
  String get settingsFaqChestsQ;

  /// FAQ answer. 'Journey' is the level map screen's name.
  ///
  /// In en, this message translates to:
  /// **'Every 30 stars opens a chest on your Journey: two hints and an extra tube, saved for when you need them. Every third chest also unlocks a ball skin.'**
  String get settingsFaqChestsA;

  /// FAQ question.
  ///
  /// In en, this message translates to:
  /// **'What is a streak freeze?'**
  String get settingsFaqFreezeQ;

  /// FAQ answer.
  ///
  /// In en, this message translates to:
  /// **'Miss a day of the Daily Pour and a freeze covers it, so your streak carries on. You get one free every Monday, can earn one a day with a video, and can hold two.'**
  String get settingsFaqFreezeA;

  /// FAQ question.
  ///
  /// In en, this message translates to:
  /// **'Do I need an account?'**
  String get settingsFaqAccountQ;

  /// FAQ answer.
  ///
  /// In en, this message translates to:
  /// **'No. You play as a guest and your progress is saved on this phone. Signing in keeps your stars when you move to a new phone.'**
  String get settingsFaqAccountA;

  /// FAQ question.
  ///
  /// In en, this message translates to:
  /// **'Can I play offline?'**
  String get settingsFaqOfflineQ;

  /// FAQ answer.
  ///
  /// In en, this message translates to:
  /// **'Yes, the whole campaign. The Daily Pour and leaderboards need a connection, and your progress syncs when you are back online.'**
  String get settingsFaqOfflineA;

  /// FAQ question.
  ///
  /// In en, this message translates to:
  /// **'How do I change my leaderboard name?'**
  String get settingsFaqNameQ;

  /// FAQ answer. 'Settings → Change your name' must match the screen and row titles.
  ///
  /// In en, this message translates to:
  /// **'Settings → Change your name. You can also hide yourself from the boards there; your stars still count.'**
  String get settingsFaqNameA;

  /// FAQ question. 'Remove ads' is the purchase's name.
  ///
  /// In en, this message translates to:
  /// **'What does Remove ads do?'**
  String get settingsFaqRemoveAdsQ;

  /// FAQ answer.
  ///
  /// In en, this message translates to:
  /// **'It turns off the ads between levels. Hint and tube videos stay, because you only ever see one when you ask for it.'**
  String get settingsFaqRemoveAdsA;

  /// FAQ question.
  ///
  /// In en, this message translates to:
  /// **'I reinstalled. Where did Remove ads go?'**
  String get settingsFaqReinstallQ;

  /// FAQ answer. 'Settings → Restore purchases' must match the screen and row titles.
  ///
  /// In en, this message translates to:
  /// **'It belongs to the store account you bought it with and usually comes back on its own. If not, tap Settings → Restore purchases.'**
  String get settingsFaqReinstallA;

  /// FAQ question.
  ///
  /// In en, this message translates to:
  /// **'Will the game stop my music?'**
  String get settingsFaqMusicQ;

  /// FAQ answer.
  ///
  /// In en, this message translates to:
  /// **'No. Pourfect plays its sounds alongside your music or podcast. Sound and haptics can be turned off in Settings.'**
  String get settingsFaqMusicA;

  /// Title of the legal acceptance card shown before play; large display type, keep short.
  ///
  /// In en, this message translates to:
  /// **'Before we pour'**
  String get settingsLegalTitle;

  /// Intro text on the legal acceptance card.
  ///
  /// In en, this message translates to:
  /// **'Pourfect is free, works offline and doesn\'t need an account. Please read and accept these first.'**
  String get settingsLegalIntro;

  /// Checkbox text on the legal card. {document} is the Terms of Service name, shown as a tappable link.
  ///
  /// In en, this message translates to:
  /// **'I accept the {document}'**
  String settingsLegalAcceptTerms(String document);

  /// Checkbox text on the legal card. {document} is the Privacy Policy name, shown as a tappable link.
  ///
  /// In en, this message translates to:
  /// **'I\'ve read the {document}'**
  String settingsLegalReadPrivacy(String document);

  /// Small print under the checkboxes. {document} is the Refund Policy name, shown as a tappable link; {version} is the legal documents' version.
  ///
  /// In en, this message translates to:
  /// **'Accepting also covers our {document} (version {version}).'**
  String settingsLegalAlsoCovers(String document, String version);

  /// The privacy policy document's name: a link on the legal card and the reader dialog's title.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get settingsLegalPrivacyPolicy;

  /// The terms document's name: a link on the legal card and the reader dialog's title.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get settingsLegalTermsOfService;

  /// The refund policy document's name: a link on the legal card and the reader dialog's title.
  ///
  /// In en, this message translates to:
  /// **'Refund Policy'**
  String get settingsLegalRefundPolicy;

  /// Accessibility label of a document link on the legal card.
  ///
  /// In en, this message translates to:
  /// **'Read the {document}'**
  String settingsLegalReadDocument(String document);

  /// Big button that accepts the legal documents and starts the game; all caps, short.
  ///
  /// In en, this message translates to:
  /// **'LET\'S POUR!'**
  String get settingsLegalAccept;

  /// Small note under the accept button.
  ///
  /// In en, this message translates to:
  /// **'You can read these again any time in Settings.'**
  String get settingsLegalReadAgain;

  /// Shown in the document reader when a bundled legal document is missing. Keep the address legal.pranta.dev unchanged.
  ///
  /// In en, this message translates to:
  /// **'This document could not be loaded on this device.\n\nYou can read it at legal.pranta.dev before accepting.'**
  String get settingsLegalLoadFailed;

  /// Title of the in-app update prompt; display type, keep short.
  ///
  /// In en, this message translates to:
  /// **'A new Pourfect is ready'**
  String get settingsUpdateTitle;

  /// Body of the in-app update prompt.
  ///
  /// In en, this message translates to:
  /// **'Google Play will download it and open the game again when it is done. Your stars are safe.'**
  String get settingsUpdateBody;

  /// Title of the update prompt when this version is no longer supported; keep short.
  ///
  /// In en, this message translates to:
  /// **'Time to update'**
  String get settingsUpdateMandatoryTitle;

  /// Body of the mandatory update prompt.
  ///
  /// In en, this message translates to:
  /// **'This version of Pourfect is no longer supported. Google Play will download the update and open the game again. Your stars are safe.'**
  String get settingsUpdateMandatoryBody;

  /// Primary button on the update prompt; short.
  ///
  /// In en, this message translates to:
  /// **'Update now'**
  String get settingsUpdateNow;

  /// Big header of the name editor, styled as a 'HELLO my name is' sticker; one short word, caps.
  ///
  /// In en, this message translates to:
  /// **'HELLO'**
  String get settingsRenameHello;

  /// Small line under HELLO on the name sticker; caps, short.
  ///
  /// In en, this message translates to:
  /// **'MY NAME IS'**
  String get settingsRenameMyNameIs;

  /// Helper text under the name field in the name editor.
  ///
  /// In en, this message translates to:
  /// **'Other players see this on the boards'**
  String get settingsRenameHint;

  /// Save button of the name editor; caps, short.
  ///
  /// In en, this message translates to:
  /// **'SAVE'**
  String get settingsRenameSave;

  /// Toast when tapping a locked skin. {how} is a short unlock condition like 'Star chest 3' or '7-day streak'.
  ///
  /// In en, this message translates to:
  /// **'Unlock it with: {how}.'**
  String settingsCollectionUnlockWith(String how);

  /// Toast when wearing a skin failed.
  ///
  /// In en, this message translates to:
  /// **'Could not change it right now. Try again later.'**
  String get settingsCollectionChangeFailed;

  /// Toast after buying the Skin pack.
  ///
  /// In en, this message translates to:
  /// **'Thank you! The pack unlocks in a moment.'**
  String get settingsPackThanks;

  /// Toast when the Skin pack was already bought.
  ///
  /// In en, this message translates to:
  /// **'Already yours. Restoring it now.'**
  String get settingsPackAlreadyOwned;

  /// Toast when the Skin pack payment is still pending.
  ///
  /// In en, this message translates to:
  /// **'Payment pending. The pack unlocks once it clears.'**
  String get settingsPackPending;

  /// Shown on the Collection screen when the catalogue could not be loaded.
  ///
  /// In en, this message translates to:
  /// **'Connect to the internet to see your collection.'**
  String get settingsCollectionOffline;

  /// Collection section label; shown in capitals; keep short.
  ///
  /// In en, this message translates to:
  /// **'Ball skins'**
  String get settingsCollectionBallSkins;

  /// Collection section label; shown in capitals; keep short.
  ///
  /// In en, this message translates to:
  /// **'Tube themes'**
  String get settingsCollectionTubeThemes;

  /// Caption under the preview of what is worn. {skin} is a ball skin name, {theme} a tube theme name.
  ///
  /// In en, this message translates to:
  /// **'{skin} balls · {theme} tubes'**
  String settingsCollectionPreview(String skin, String theme);

  /// Accessibility label of a skin card that is being worn.
  ///
  /// In en, this message translates to:
  /// **'{name}, worn'**
  String settingsCollectionItemWorn(String name);

  /// Accessibility label of an owned skin card.
  ///
  /// In en, this message translates to:
  /// **'{name}, tap to wear'**
  String settingsCollectionItemTapToWear(String name);

  /// Accessibility label of a locked skin card. {how} is a short unlock condition.
  ///
  /// In en, this message translates to:
  /// **'{name}, locked: {how}'**
  String settingsCollectionItemLocked(String name, String how);

  /// Status under a skin card that is being worn; one line, very short.
  ///
  /// In en, this message translates to:
  /// **'Wearing'**
  String get settingsCollectionWearing;

  /// Status under an owned skin card; one line, very short.
  ///
  /// In en, this message translates to:
  /// **'Tap to wear'**
  String get settingsCollectionTapToWear;

  /// Unlock condition on a locked skin card: the numbered star chest that gives it. One line, very short.
  ///
  /// In en, this message translates to:
  /// **'Star chest {number}'**
  String settingsUnlockChest(int number);

  /// Unlock condition on a locked skin card: a Daily Pour streak of this many days. One line, very short.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, other{{days}-day streak}}'**
  String settingsUnlockStreak(int days);

  /// Unlock condition on a skin card that is free; very short.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get settingsUnlockFree;

  /// Name of the paid cosmetics pack: title of its card, and the unlock condition on skins it contains. Short.
  ///
  /// In en, this message translates to:
  /// **'Skin pack'**
  String get settingsSkinPack;

  /// What the Skin pack contains. Use the same skin and theme names as elsewhere.
  ///
  /// In en, this message translates to:
  /// **'Marble, Pearl and Checker balls, Wood and Lilac tubes.'**
  String get settingsSkinPackDetail;

  /// Chip on the Skin pack card once bought; caps, very short.
  ///
  /// In en, this message translates to:
  /// **'OWNED'**
  String get settingsOwned;

  /// Shown on the Skin pack buy button when no price is available yet; very short.
  ///
  /// In en, this message translates to:
  /// **'Soon'**
  String get settingsSoon;

  /// Ball skin name: the plain default look. Very short.
  ///
  /// In en, this message translates to:
  /// **'Classic'**
  String get settingsSkinClassic;

  /// Ball skin name: shiny highlight. Very short.
  ///
  /// In en, this message translates to:
  /// **'Glossy'**
  String get settingsSkinGlossy;

  /// Ball skin name: candy-like stripes. Very short.
  ///
  /// In en, this message translates to:
  /// **'Candy stripe'**
  String get settingsSkinStriped;

  /// Ball skin name: glowing. Very short.
  ///
  /// In en, this message translates to:
  /// **'Glow'**
  String get settingsSkinGlow;

  /// Ball skin name: candy sprinkles. Very short.
  ///
  /// In en, this message translates to:
  /// **'Sprinkles'**
  String get settingsSkinSpeckled;

  /// Ball skin name: marbled stone. Very short.
  ///
  /// In en, this message translates to:
  /// **'Marble'**
  String get settingsSkinMarble;

  /// Ball skin name: pearly sheen. Very short.
  ///
  /// In en, this message translates to:
  /// **'Pearl'**
  String get settingsSkinPearl;

  /// Ball skin name: checkerboard pattern. Very short.
  ///
  /// In en, this message translates to:
  /// **'Checker'**
  String get settingsSkinChecker;

  /// Tube theme name: the plain default white tubes. Very short.
  ///
  /// In en, this message translates to:
  /// **'Toy'**
  String get settingsTubeToy;

  /// Tube theme name: frosted icy glass. Very short.
  ///
  /// In en, this message translates to:
  /// **'Frost'**
  String get settingsTubeFrost;

  /// Tube theme name: wooden. Very short.
  ///
  /// In en, this message translates to:
  /// **'Wood'**
  String get settingsTubeWood;

  /// Tube theme name: pale purple (lilac) tubes. Very short.
  ///
  /// In en, this message translates to:
  /// **'Lilac'**
  String get settingsTubeLilac;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}

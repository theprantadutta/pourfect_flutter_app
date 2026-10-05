/// App root: theme wiring and navigation.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'state/campaign_worlds.dart';
import 'state/legal_acceptance.dart';
import 'state/monetization_controller.dart';
import 'services/notifications/notification_service.dart';
import 'services/updates/app_updater.dart';
import 'services/updates/release_policy.dart';
import 'state/review_prompter.dart';
import 'state/providers.dart';
import 'state/daily_controller.dart';
import 'state/sync_controller.dart';
import 'ui/screens/daily_challenge_screen.dart';
import 'ui/screens/game_screen.dart';
import 'ui/screens/legal_consent_screen.dart';
import 'ui/screens/leaderboard_screen.dart';
import 'ui/screens/account_screen.dart';
import 'ui/screens/home_screen.dart';
import 'ui/screens/journey_screen.dart';
import 'ui/screens/settings_screen.dart';
import 'ui/screens/statistics_screen.dart';
import 'ui/theme/tokens.dart';
import 'ui/theme/toy.dart';
import 'ui/theme/typography.dart';
import 'ui/transitions.dart';
import 'ui/widgets/splash_handoff.dart';
import 'ui/widgets/toy_kit.dart';
import 'ui/widgets/update_prompt.dart';

class PourfectApp extends StatelessWidget {
  const PourfectApp({super.key});

  @override
  Widget build(BuildContext context) {
    const tokens = PourfectTokens.toybox;

    return MaterialApp(
      title: 'Pourfect',
      debugShowCheckedModeBanner: false,
      // One theme. Toybox replaced the original dark direction outright; there
      // is no dark variant to fall back to or keep in sync.
      theme: _buildTheme(tokens),
      home: const _Shell(),
    );
  }

  ThemeData _buildTheme(PourfectTokens tokens) {
    final base = ThemeData.light(useMaterial3: true);

    return base.copyWith(
      scaffoldBackgroundColor: tokens.surface,
      canvasColor: tokens.surface,
      extensions: [tokens],
      colorScheme: base.colorScheme.copyWith(
        brightness: Brightness.light,
        surface: tokens.surface,
        onSurface: Toy.ink,
        primary: Toy.tomato,
        onPrimary: Colors.white,
        secondary: Toy.yellow,
        onSecondary: Toy.ink,
        error: Toy.tomatoDark,
      ),
      textTheme: base.textTheme.apply(
        bodyColor: tokens.textPrimary,
        displayColor: tokens.textPrimary,
        fontFamily: kUiFontFamily,
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: Toy.tomato,
        selectionColor: Color(0x73A78BFA),
        selectionHandleColor: Toy.tomato,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: Toy.ink,
        behavior: SnackBarBehavior.floating,
        contentTextStyle: Toy.ui(
          14,
          weight: FontWeight.w700,
          color: Colors.white,
        ),
        actionTextColor: Toy.yellow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Toy.rButton),
        ),
      ),
      // Material's ink ripple belongs to a different design language. Every
      // control here responds through Pressable, which sinks instead.
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: _NoDefaultTransition(),
          TargetPlatform.iOS: _NoDefaultTransition(),
        },
      ),
    );
  }
}

/// Guards against a stock slide sneaking in through any route we did not build
/// ourselves.
class _NoDefaultTransition extends PageTransitionsBuilder {
  const _NoDefaultTransition();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => FadeTransition(opacity: animation, child: child);
}

/// Holds the level map and pushes the board on top of it.
class _Shell extends ConsumerStatefulWidget {
  const _Shell();

  @override
  ConsumerState<_Shell> createState() => _ShellState();
}

class _ShellState extends ConsumerState<_Shell> with WidgetsBindingObserver {
  /// Notification taps, cancelled with the shell.
  StreamSubscription<PourfectNotification>? _taps;

  /// Null until the launch count and stored acceptance have been read.
  bool? _showLegalGate;

  final _updater = AppUpdater();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _resolveLegalGate();
    // Building the controller is what asks the display for its fast mode.
    ref.read(displayRateProvider);
    // Generating the sound bank takes a few milliseconds and opening the mixer
    // can take longer, so it happens off the first frame. A device with no
    // usable audio still reaches the level map.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(audioServiceProvider).init();
      // Ads and billing initialise off the first frame too. Neither may block
      // startup: a device with no Play Services still has to reach level 1.
      ref.read(adServiceProvider).init();

      // BUILT BEFORE BILLING STARTS. Monetization is a lazy provider and it is
      // what verifies purchase receipts; billing replays every owned purchase
      // the moment it initialises. In the other order the replay is announced
      // to a broadcast stream with no subscriber and is simply dropped — which
      // was the only retry a purchase whose first verification failed had.
      // The receipt queue is persisted as a second line of defence, but the
      // order is the fix.
      ref.read(monetizationProvider);
      ref.read(billingServiceProvider).init();

      // And the first sync. Off the first frame like everything else here,
      // because the level map must be on screen before any of this runs — a
      // player on a train opens the game and plays; they do not wait for a
      // handshake with a server they do not know exists.
      ref.read(syncControllerProvider.notifier).syncNow();

      // More levels, if the player is within a world of the end of what this
      // phone holds. Returns at once for everybody else.
      ref.read(campaignWorldsProvider.notifier).maybeFetch();

      // And Play's update check, last and least urgent of the lot. Flexible by
      // default, so the download happens while the player plays.
      //
      // THE LISTENER IS THE HALF THAT WAS MISSING. A flexible update does not
      // install itself, so downloading one and never offering the restart left
      // the update sitting on the device for ever while the app behaved as if
      // nothing had happened. Registered before the check, because the check
      // can raise it immediately when an earlier run already downloaded one.
      _updater.readyToInstall.addListener(_offerRestart);
      _updater.updateAvailable.addListener(_offerUpdate);
      unawaited(_checkForUpdate());

      // And today's board, so the home card knows whether it has been played
      // before the player looks at it. Off the first frame like everything
      // else: the level map does not wait on it.
      ref.read(dailyProvider.notifier).ensureLoaded();

      // Re-registers an ALREADY granted push token. Never asks: a prompt on
      // launch is a measurable D1 killer, and the ask belongs at the one
      // moment it means something — just after a daily is finished.
      //
      // Re-registering every session is what keeps the stored row pointing at
      // a device that still exists; tokens rotate on reinstall, on restore,
      // and whenever the OS decides.
      ref.read(pushServiceProvider).registerIfPermitted();
    });

    // WHERE A TAP GOES. A reminder about today's challenge that opens the hub
    // has spent the one interruption the player agreed to and delivered them
    // somewhere they could already get to.
    //
    // Subscribed here rather than in the service, because the service has no
    // business knowing what a route is — it reports which notification was
    // opened and this decides where that lands.
    _taps = NotificationService.shared.taps.listen((notification) {
      if (!mounted) return;
      switch (notification) {
        case PourfectNotification.dailyChallenge:
          _openDaily();
        case PourfectNotification.unknown:
          // Deliberately nothing. They are already on the hub, which is the
          // honest destination for a message this build does not recognise.
          break;
      }
    });
  }

  /// Syncs again when the app comes back.
  ///
  /// The cheapest moment to reconcile: somebody who played on another device
  /// while this one was in their pocket sees it here, and anything that failed
  /// to push earlier gets another go without a retry timer to tune.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(syncControllerProvider.notifier).syncNow();
      // Midnight UTC may have passed while the app was in a pocket, in which
      // case yesterday's board is the wrong one to be offering.
      ref.read(dailyProvider.notifier).refresh();
      // Some Android builds drop a window's preferred display mode while it
      // is in the background, which would quietly leave us at 60 Hz.
      ref.read(displayRateProvider.notifier).reapply();
      // The network may have come back while the app was away, so the quiet
      // period after a failed download is skipped.
      ref.read(campaignWorldsProvider.notifier).maybeFetch(force: true);
      // An update interrupted by leaving the app is resumed here, and a
      // player who was away for a day may have a newer build waiting.
      unawaited(_checkForUpdate());
    }
  }

  bool _updatePromptOpen = false;

  /// Reads the supported-minimum policy, then asks Play.
  ///
  /// The policy (App Releases in the admin dashboard) only decides whether
  /// the prompt may offer Not now; Play still decides whether there is
  /// anything to update to. No policy, an unreadable one, or no network all
  /// mean an ordinary, dismissible prompt: nobody is locked out by a request
  /// that failed.
  Future<void> _checkForUpdate() async {
    final policy = await fetchReleasePolicy(
      ref.read(apiClientProvider),
      defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android',
    );
    if (!mounted) return;
    _updater.mandatory =
        policy?.requiresUpdate(ref.read(appVersionProvider)) ?? false;
    await _updater.check();
  }

  /// Asks about an available update, but only on the hub.
  ///
  /// Never over a level (the prompt waits for the level route to pop, see
  /// [_openLevel]), never over the legal gate, and never twice at once.
  Future<void> _offerUpdate() async {
    if (!mounted || !_updater.updateAvailable.value || _updatePromptOpen) {
      return;
    }
    if (_showLegalGate == true) return;
    if (!(ModalRoute.of(context)?.isCurrent ?? true)) return;

    _updatePromptOpen = true;
    try {
      final now = await showUpdatePrompt(
        context,
        mandatory: _updater.mandatory,
      );
      if (!mounted) return;
      if (!now) {
        await _updater.later();
        return;
      }
      final outcome = await _updater.updateNow();
      // Backing out of Play's own screen is the same answer as Not now,
      // unless this build is no longer supported, in which case the next
      // check asks again.
      if (outcome == UpdateNowOutcome.declined && !_updater.mandatory) {
        await _updater.later();
      }
    } finally {
      _updatePromptOpen = false;
    }
  }

  /// Offers the restart that installs a downloaded update.
  ///
  /// A bar rather than a dialog, and never automatic. `completeFlexibleUpdate`
  /// restarts the process; doing that unasked would close the game on somebody
  /// halfway through a board, which is a worse bug than being a version behind.
  /// It waits to be taken up, and says nothing if it is not.
  void _offerRestart() {
    if (!mounted || !_updater.readyToInstall.value) return;

    // A toy toast, not a SnackBar: the hub stands on a ToyScaffold, which is
    // not a Scaffold, so a SnackBar here would never have appeared.
    showToyToast(
      context,
      'An update is ready to install.',
      actionLabel: 'Restart',
      onAction: _updater.install,
      duration: const Duration(seconds: 10),
    );
  }

  @override
  void dispose() {
    _taps?.cancel();
    _updater.readyToInstall.removeListener(_offerRestart);
    _updater.updateAvailable.removeListener(_offerUpdate);
    _updater.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Decides whether the acceptance gate stands in front of the level map.
  ///
  /// Deliberately does NOT block the first frame — the level map renders while
  /// this resolves, so a prefs read cannot delay startup. The gate replaces
  /// the map a moment later if it is needed, and a brand-new player never
  /// sees it at all on their first launch.
  Future<void> _resolveLegalGate() async {
    final launchCount = await LegalAcceptance.recordLaunch();
    final accepted = await LegalAcceptance.isCurrentVersionAccepted();
    if (!mounted) return;
    setState(() {
      _showLegalGate = LegalAcceptance.shouldShowGate(
        launchCount: launchCount,
        accepted: accepted,
      );
    });
  }

  void _openLevel(int levelId, Rect? origin) {
    Navigator.of(context)
        .push(
          PourfectPageRoute<void>(
            origin: origin,
            settings: RouteSettings(name: '/level/$levelId'),
            builder: (context) => GameScreen(
              levelId: levelId,
              onExit: () => Navigator.of(context).maybePop(),
            ),
          ),
        )
        // Completes when the level route has POPPED, so the hub is back and
        // the player is between things. That is the only moment in this app
        // worth asking for a rating in — everywhere else they are mid-puzzle,
        // mid-animation, or mid-decision.
        .then((_) {
          if (!mounted) return;
          // A waiting update takes this moment instead of the rating ask: one
          // dialog per return to the hub, and the update is the one that
          // changes what they play next.
          if (_updater.updateAvailable.value) {
            _offerUpdate();
            return;
          }
          ref.read(reviewPrompterProvider.notifier).maybeAsk();
        });
  }

  void _openDaily() {
    Navigator.of(context).push(
      PourfectPageRoute<void>(
        settings: const RouteSettings(name: '/daily'),
        builder: (context) => DailyChallengeScreen(
          onExit: () => Navigator.of(context).maybePop(),
        ),
      ),
    );
  }

  void _openLeaderboard() {
    Navigator.of(context).push(
      PourfectPageRoute<void>(
        settings: const RouteSettings(name: '/leaderboard'),
        builder: (context) =>
            LeaderboardScreen(onBack: () => Navigator.of(context).maybePop()),
      ),
    );
  }

  void _openStatistics() {
    Navigator.of(context).push(
      PourfectPageRoute<void>(
        settings: const RouteSettings(name: '/statistics'),
        builder: (context) =>
            StatisticsScreen(onBack: () => Navigator.of(context).maybePop()),
      ),
    );
  }

  void _openSettings() {
    Navigator.of(context).push(
      PourfectPageRoute<void>(
        settings: const RouteSettings(name: '/settings'),
        builder: (context) =>
            SettingsScreen(onClose: () => Navigator.of(context).maybePop()),
      ),
    );
  }

  /// The campaign path, full screen. The hub shows a slice of the same thing.
  void _openJourney() {
    Navigator.of(context).push(
      PourfectPageRoute<void>(
        settings: const RouteSettings(name: '/journey'),
        builder: (context) => JourneyScreen(
          onOpenLevel: _openLevel,
          onOpenSettings: _openSettings,
          onOpenStatistics: _openStatistics,
          onOpenDaily: _openDaily,
          onOpenLeaderboard: _openLeaderboard,
          onOpenAccount: _openAccount,
        ),
      ),
    );
  }

  void _openAccount() {
    Navigator.of(context).push(
      PourfectPageRoute<void>(
        settings: const RouteSettings(name: '/account'),
        builder: (context) => AccountScreen(onOpenStatistics: _openStatistics),
      ),
    );
  }

  /// True until the splash handoff has played out, once per cold start.
  bool _splashing = true;

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      if (_showLegalGate == true)
        LegalConsentScreen(
          onAccepted: () {
            setState(() => _showLegalGate = false);
            _offerUpdate();
          },
        )
      else
        HomeScreen(
          onOpenLevel: _openLevel,
          onOpenSettings: _openSettings,
          onOpenStatistics: _openStatistics,
          onOpenDaily: _openDaily,
          onOpenLeaderboard: _openLeaderboard,
          onOpenAccount: _openAccount,
          onOpenJourney: _openJourney,
        ),
      if (_splashing)
        SplashHandoff(onDone: () => setState(() => _splashing = false)),
    ],
  );
}

/// System chrome for a full-bleed board.
///
/// Edge-to-edge with transparent bars: the board should meet the screen edges,
/// and a grey status-bar strip above the dotted ground is the sort of detail
/// that makes an app feel unfinished. Each screen's `ToyScaffold` sets the
/// icon brightness for its own ground when the bars are swiped back in.
void configureSystemChrome() {
  // FULL SCREEN. No status bar, no navigation bar.
  //
  // A game does not need the clock and the battery on top of its board, and
  // the strip they sit in is the most reliable way to make a full-bleed
  // screen look like a web page. `immersiveSticky` rather than `immersive`:
  // the bars come back on a swipe from the edge and then hide themselves
  // again, so nothing is unreachable and nothing stays.
  //
  // iOS hides its status bar from Info.plist rather than from here —
  // UIStatusBarHidden, with UIViewControllerBasedStatusBarAppearance false so
  // the plist is what decides.
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  SystemChrome.setPreferredOrientations([
    // Portrait only. The board is a vertical arrangement of vertical vessels;
    // landscape would either shrink the balls or waste most of the screen.
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
}

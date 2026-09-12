/// App root: theme wiring and navigation.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'state/legal_acceptance.dart';
import 'state/monetization_controller.dart';
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
import 'ui/theme/typography.dart';
import 'ui/transitions.dart';

class PourfectApp extends StatelessWidget {
  const PourfectApp({super.key});

  @override
  Widget build(BuildContext context) {
    const tokens = PourfectTokens.dark;

    return MaterialApp(
      title: 'Pourfect',
      debugShowCheckedModeBanner: false,
      // The light theme is deliberately absent rather than stubbed. Every value
      // the UI uses comes from PourfectTokens, so adding warm-paper later is a
      // second constant plus a themeMode, not a rewrite.
      theme: _buildTheme(tokens),
      home: const _Shell(),
    );
  }

  ThemeData _buildTheme(PourfectTokens tokens) {
    final base = ThemeData.dark(useMaterial3: true);

    return base.copyWith(
      scaffoldBackgroundColor: tokens.surface,
      canvasColor: tokens.surface,
      extensions: [tokens],
      colorScheme: base.colorScheme.copyWith(
        surface: tokens.surface,
        primary: tokens.accent,
      ),
      textTheme: base.textTheme.apply(
        bodyColor: tokens.textPrimary,
        displayColor: tokens.textPrimary,
        fontFamily: kUiFontFamily,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: tokens.surfaceRaised,
        contentTextStyle: bodyStyle(tokens)
            .copyWith(color: tokens.textPrimary, fontSize: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: tokens.hairline),
        ),
      ),
      // Material's ink ripple belongs to a different design language. Every
      // control here responds through Pressable instead.
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
  /// Null until the launch count and stored acceptance have been read.
  bool? _showLegalGate;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _resolveLegalGate();
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
    }
  }

  @override
  void dispose() {
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
    Navigator.of(context).push(
      PourfectPageRoute<void>(
        origin: origin,
        settings: RouteSettings(name: '/level/$levelId'),
        builder: (context) => GameScreen(
          levelId: levelId,
          onExit: () => Navigator.of(context).maybePop(),
        ),
      ),
    );
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
        builder: (context) => const AccountScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => _showLegalGate == true
      ? LegalConsentScreen(
          onAccepted: () => setState(() => _showLegalGate = false),
        )
      : HomeScreen(
          onOpenLevel: _openLevel,
          onOpenSettings: _openSettings,
          onOpenStatistics: _openStatistics,
          onOpenDaily: _openDaily,
          onOpenLeaderboard: _openLeaderboard,
          onOpenAccount: _openAccount,
          onOpenJourney: _openJourney,
        );
}

/// System chrome for a full-bleed dark board.
///
/// Edge-to-edge with transparent bars: the board should meet the screen edges,
/// and a grey status-bar strip above a near-black game is the sort of detail
/// that makes an app feel unfinished.
void configureSystemChrome() {
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  SystemChrome.setPreferredOrientations([
    // Portrait only. The board is a vertical arrangement of vertical vessels;
    // landscape would either shrink the balls or waste most of the screen.
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
}

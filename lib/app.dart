/// App root: theme wiring and navigation.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'state/legal_acceptance.dart';
import 'state/providers.dart';
import 'ui/screens/game_screen.dart';
import 'ui/screens/legal_consent_screen.dart';
import 'ui/screens/level_select_screen.dart';
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

class _ShellState extends ConsumerState<_Shell> {
  /// Null until the launch count and stored acceptance have been read.
  bool? _showLegalGate;

  @override
  void initState() {
    super.initState();
    _resolveLegalGate();
    // Generating the sound bank takes a few milliseconds and opening the mixer
    // can take longer, so it happens off the first frame. A device with no
    // usable audio still reaches the level map.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(audioServiceProvider).init();
      // Ads and billing initialise off the first frame too. Neither may block
      // startup: a device with no Play Services still has to reach level 1.
      ref.read(adServiceProvider).init();
      ref.read(billingServiceProvider).init();
    });
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

  @override
  Widget build(BuildContext context) => _showLegalGate == true
      ? LegalConsentScreen(
          onAccepted: () => setState(() => _showLegalGate = false),
        )
      : LevelSelectScreen(
          onOpenLevel: _openLevel,
          onOpenSettings: _openSettings,
          onOpenStatistics: _openStatistics,
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

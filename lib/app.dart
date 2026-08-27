/// App root: theme wiring and the single screen.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'ui/screens/game_screen.dart';
import 'ui/theme/tokens.dart';
import 'ui/theme/typography.dart';

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
      // second `PourfectTokens` constant plus a themeMode — not a rewrite.
      theme: _buildTheme(tokens),
      home: const GameScreen(),
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
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
    );
  }
}

/// System chrome for a full-bleed dark board.
///
/// Edge-to-edge with transparent bars: the board should meet the screen edges,
/// and a grey status bar strip above a near-black game is the sort of detail
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

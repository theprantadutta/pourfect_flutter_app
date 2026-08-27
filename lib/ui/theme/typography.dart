/// Type ramp.
///
/// Two families, used for different jobs. The UI face is the platform sans;
/// every NUMBER — move counts, level numbers, timers, leaderboard figures — is
/// monospace with tabular figures, so a counter ticking from 9 to 10 does not
/// shift the layout around it. That jitter is small and constant and it is
/// exactly the kind of thing that makes an app feel cheap.
///
/// FONTS ARE NOT YET BUNDLED. These resolve to the platform faces (Roboto and
/// Roboto Mono on Android), which look good and cost zero bytes. Bundling a
/// chosen pair is a licence decision, not a technical one — see CLAUDE.md.
/// Everything downstream reads these constants, so swapping in a TTF later is
/// a two-line change here plus a pubspec entry.
library;

import 'package:flutter/material.dart';

import 'tokens.dart';

/// Display face. Null means "platform default", which is the right answer until
/// a licensed face is chosen.
const String? kUiFontFamily = null;

/// Monospace face for numerals.
const String kMonoFontFamily = 'monospace';

/// Small uppercase label: section headers, HUD captions.
///
/// Wide tracking and a muted colour on purpose — these should sit behind the
/// board, not compete with it.
TextStyle labelStyle(PourfectTokens tokens) => TextStyle(
  fontFamily: kUiFontFamily,
  fontSize: 11,
  fontWeight: FontWeight.w600,
  letterSpacing: 1.4,
  height: 1.2,
  color: tokens.textMuted,
);

/// Any number the player reads.
TextStyle numericStyle(
  PourfectTokens tokens, {
  double size = 20,
  FontWeight weight = FontWeight.w600,
  Color? color,
}) => TextStyle(
  fontFamily: kMonoFontFamily,
  fontSize: size,
  fontWeight: weight,
  height: 1.1,
  letterSpacing: 0.5,
  color: color ?? tokens.textNumeric,
  fontFeatures: const [FontFeature.tabularFigures()],
);

/// Card and dialogue titles.
TextStyle titleStyle(PourfectTokens tokens) => TextStyle(
  fontFamily: kUiFontFamily,
  fontSize: 22,
  fontWeight: FontWeight.w600,
  height: 1.25,
  letterSpacing: -0.2,
  color: tokens.textPrimary,
);

/// Body copy. Generous line height — this is a calm game.
TextStyle bodyStyle(PourfectTokens tokens) => TextStyle(
  fontFamily: kUiFontFamily,
  fontSize: 15,
  fontWeight: FontWeight.w400,
  height: 1.55,
  color: tokens.textMuted,
);

/// Button and action labels.
TextStyle actionStyle(PourfectTokens tokens, {Color? color}) => TextStyle(
  fontFamily: kUiFontFamily,
  fontSize: 14,
  fontWeight: FontWeight.w600,
  letterSpacing: 0.2,
  color: color ?? tokens.textPrimary,
);

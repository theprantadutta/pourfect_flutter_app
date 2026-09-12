/// Type ramp.
///
/// Two families, used for different jobs. The UI face is the platform sans;
/// every NUMBER — move counts, level numbers, timers, leaderboard figures — is
/// monospace with tabular figures, so a counter ticking from 9 to 10 does not
/// shift the layout around it. That jitter is small and constant and it is
/// exactly the kind of thing that makes an app feel cheap.
///
/// JetBrains Mono is BUNDLED (OFL-1.1, see assets/fonts/ATTRIBUTION.md) rather
/// than fetched: the game must be fully playable offline, and a face that pops
/// in on first launch looks broken. It carries every numeral in the game.
///
/// The UI face is still the platform default. Manrope is the chosen pairing but
/// was not available on the build machine; adding it is a one-line change here
/// plus a pubspec entry, and everything downstream reads these constants.
library;

import 'package:flutter/material.dart';

import 'tokens.dart';

/// Display face.
///
/// Bundled rather than fetched, so it renders identically on every device and
/// cannot pop in on first launch. This was null for a long time, which meant
/// every screen fell back to whatever the OEM ships — and the difference
/// between a Samsung and a Pixel was the difference between two products.
const String kUiFontFamily = 'Manrope';

/// Monospace face for numerals. Bundled, so it renders identically on every
/// device rather than inheriting whatever the OEM ships.
const String kMonoFontFamily = 'JetBrainsMono';

/// Small uppercase label: section headers, HUD captions.
///
/// Wide tracking and a muted color on purpose — these should sit behind the
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

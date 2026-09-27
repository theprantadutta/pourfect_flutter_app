/// Type ramp.
///
/// Two families, bundled (OFL-1.1, see assets/fonts/ATTRIBUTION.md) rather than
/// fetched — the game must be fully playable offline, and a face that pops in
/// on first launch looks broken:
///
///  * **Bagel Fat One** for display: the logo, screen titles, big numbers and
///    CTA labels. See `Toy.display`.
///  * **Outfit** 500–800 for everything else. Every NUMBER a player reads —
///    move counts, timers, leaderboard figures — uses tabular figures, so a
///    counter ticking from 9 to 10 does not shift the layout around it.
///
/// These helpers keep their original names so the screens read the same API;
/// the Toybox-specific ramp lives on [Toy].
library;

import 'package:flutter/material.dart';

import 'tokens.dart';
import 'toy.dart';

/// UI face.
const String kUiFontFamily = Toy.uiFamily;

/// Display face.
const String kDisplayFontFamily = Toy.displayFamily;

/// Small caps label: section headers, HUD captions. 11/800/+2.
TextStyle labelStyle(PourfectTokens tokens) =>
    Toy.caps(color: tokens.textMuted);

/// Any number the player reads. Tabular Outfit, heavy by default.
TextStyle numericStyle(
  PourfectTokens tokens, {
  double size = 20,
  FontWeight weight = FontWeight.w800,
  Color? color,
}) => Toy.numbers(size, color: color ?? tokens.textNumeric, weight: weight);

/// Card and dialog titles: the display face, flat ink.
TextStyle titleStyle(PourfectTokens tokens) =>
    Toy.display(24, color: tokens.textPrimary, height: 1.1);

/// Body copy.
TextStyle bodyStyle(PourfectTokens tokens) => TextStyle(
  fontFamily: kUiFontFamily,
  fontSize: 15,
  fontWeight: FontWeight.w500,
  height: 1.45,
  color: tokens.textMuted,
);

/// Button and action labels.
TextStyle actionStyle(PourfectTokens tokens, {Color? color}) => TextStyle(
  fontFamily: kUiFontFamily,
  fontSize: 14,
  fontWeight: FontWeight.w800,
  letterSpacing: 0.2,
  color: color ?? tokens.textPrimary,
);

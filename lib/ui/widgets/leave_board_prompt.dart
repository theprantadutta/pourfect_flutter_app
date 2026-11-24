/// "Leaving so soon?" — asked before walking out of a board that has moves on
/// it, by the back button and the system back gesture alike.
///
/// Owner's ask (2026-10-10): a board half-poured was being lost to one stray
/// tap. The copy is playful on purpose, but the body always says plainly what
/// is lost.
library;

import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../l10n/l10n.dart';
import '../theme/toy.dart';
import 'toy_kit.dart';

List<String> _titles(AppLocalizations l10n) => [
  l10n.playLeaveTitleSoSoon,
  l10n.playLeaveTitleMissYou,
  l10n.playLeaveTitleAbandon,
  l10n.playLeaveTitleMidPour,
];

/// True when the player chose to leave. [lost] defaults to the campaign
/// board's copy.
Future<bool> confirmLeaveBoard(BuildContext context, {String? lost}) {
  final l10n = context.l10n;
  final titles = _titles(l10n);
  return showToyConfirm(
    context: context,
    title: titles[math.Random().nextInt(titles.length)],
    body: lost ?? l10n.playLeaveBody,
    cancelLabel: l10n.playLeaveKeepPouring,
    confirmLabel: l10n.playLeaveConfirm,
    confirmColor: Toy.tomato,
    confirmTextColor: Colors.white,
  );
}

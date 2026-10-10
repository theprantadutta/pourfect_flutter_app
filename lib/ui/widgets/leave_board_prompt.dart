/// "Leaving so soon?" — asked before walking out of a board that has moves on
/// it, by the back button and the system back gesture alike.
///
/// Owner's ask (2026-10-10): a board half-poured was being lost to one stray
/// tap. The copy is playful on purpose, but the body always says plainly what
/// is lost.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/toy.dart';
import 'toy_kit.dart';

const _titles = [
  'Leaving so soon?',
  'The balls will miss you',
  'Abandon the pour?',
  'Walking out mid-pour?',
];

/// True when the player chose to leave.
Future<bool> confirmLeaveBoard(
  BuildContext context, {
  String lost = "Your moves and time on this board won't be saved.",
}) => showToyConfirm(
  context: context,
  title: _titles[math.Random().nextInt(_titles.length)],
  body: lost,
  cancelLabel: 'Keep pouring',
  confirmLabel: 'Leave',
  confirmColor: Toy.tomato,
  confirmTextColor: Colors.white,
);

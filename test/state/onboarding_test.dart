// First-run teaching: the flags behind it, and the guidance the first level
// follows.

import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pourfect_flutter_app/engine/board.dart';
import 'package:pourfect_flutter_app/engine/level_set.dart';
import 'package:pourfect_flutter_app/engine/rules.dart';
import 'package:pourfect_flutter_app/state/onboarding.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  ProviderContainer make() {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    return c;
  }

  group('flags', () {
    test('a fresh install has everything still to learn', () async {
      SharedPreferences.setMockInitialValues({});
      final c = make();
      c.read(onboardingProvider);
      await c.read(onboardingProvider.notifier).ready;

      final s = c.read(onboardingProvider);
      expect(s.loaded, isTrue);
      expect(s.tutorialDone, isFalse);
      expect(s.seen, isEmpty);
    });

    test('a tip is claimed exactly once', () async {
      SharedPreferences.setMockInitialValues({});
      final c = make();
      final ob = c.read(onboardingProvider.notifier);

      expect(await ob.claim(Tip.undo), isTrue);
      expect(await ob.claim(Tip.undo), isFalse);
      expect(await ob.claim(Tip.hint), isTrue);
    });

    test('flags survive a relaunch', () async {
      SharedPreferences.setMockInitialValues({});
      final first = make();
      final ob = first.read(onboardingProvider.notifier);
      await ob.finishTutorial();
      await ob.claim(Tip.par);

      final second = make();
      second.read(onboardingProvider);
      await second.read(onboardingProvider.notifier).ready;
      final s = second.read(onboardingProvider);
      expect(s.tutorialDone, isTrue);
      expect(s.hasSeen(Tip.par), isTrue);
      expect(s.hasSeen(Tip.undo), isFalse);
    });

    test('a claim waits for the stored flags, so nothing shows twice', () async {
      // The lazy-provider trap: build() and the first question arrive in the
      // same breath. Judged against defaults, a seen tip would show again.
      SharedPreferences.setMockInitialValues({
        'pourfect.onboarding.tips_seen.v1': ['undo'],
      });
      final c = make();
      expect(await c.read(onboardingProvider.notifier).claim(Tip.undo), isFalse);
    });

    test('How to play resets the level and every tip', () async {
      SharedPreferences.setMockInitialValues({
        'pourfect.onboarding.tutorial_done.v1': true,
        'pourfect.onboarding.tips_seen.v1': ['par', 'undo', 'hint', 'hub'],
      });
      final c = make();
      final ob = c.read(onboardingProvider.notifier);
      await ob.reset();

      final s = c.read(onboardingProvider);
      expect(s.tutorialDone, isFalse);
      expect(s.seen, isEmpty);
      expect(await ob.claim(Tip.hub), isTrue);
    });

    test('an unknown stored tip name is ignored, not fatal', () async {
      SharedPreferences.setMockInitialValues({
        'pourfect.onboarding.tips_seen.v1': ['par', 'retired_tip'],
      });
      final c = make();
      c.read(onboardingProvider);
      await c.read(onboardingProvider.notifier).ready;
      expect(c.read(onboardingProvider).seen, {Tip.par});
    });
  });

  group('guidance', () {
    late Board level1;
    late int par;

    setUpAll(() {
      final set = LevelSetCodec.decode(
        File('assets/levels/levels.bin').readAsBytesSync(),
      );
      final l = set.levels.firstWhere((l) => l.id == 1).level;
      level1 = l.board;
      par = l.minMoves;
    });

    test('following the hand solves level 1 in exactly par', () {
      var board = level1;
      var moves = 0;
      while (!board.isWon) {
        final move = guidedMove(board);
        expect(move, isNotNull);
        board = applyMove(board, move!).board;
        moves++;
        expect(moves, lessThanOrEqualTo(par));
      }
      expect(moves, par);
    });

    test('a player who wanders off is guided from where they are', () {
      // Take some other legal move first, then follow the hand.
      var board = level1;
      final detour = legalMoves(board).firstWhere(
        (m) => m != guidedMove(level1),
      );
      board = applyMove(board, detour).board;

      var steps = 0;
      while (!board.isWon && steps < 40) {
        board = applyMove(board, guidedMove(board)!).board;
        steps++;
      }
      expect(board.isWon, isTrue);
    });

    test('nothing to point at on a finished board', () {
      var board = level1;
      while (!board.isWon) {
        board = applyMove(board, guidedMove(board)!).board;
      }
      expect(guidedMove(board), isNull);
    });
  });
}

/// Questions players actually have, answered from how the game really works.
///
/// Asked for by the 1.0.0 testers. Every answer here is a rule the code
/// enforces, so each one names what it rests on — change the rule and the
/// sentence becomes a lie on a screen people trust:
///
/// - stars: `starsFor` (3 at par, 2 within 1.5x, 1 for any finish)
/// - the clock: `parSecondsFor`, and it moves points only, never stars
/// - hints: `kFreeHints`, and the credit kept when a hint cannot resolve
/// - the extra tube: `GameState.canOfferExtraTube`, stuck or past par, two at most
/// - music: no audio focus is ever requested (verified on Android)
///
/// No contact address. There is none confirmed, and an invented one on a help
/// page is worse than none.
library;

import 'package:flutter/material.dart';

import '../../state/monetization_controller.dart' show kFreeHints;
import '../theme/toy.dart';
import '../widgets/settings_rows.dart';
import '../widgets/toy_kit.dart';

/// One question and its answer.
typedef Faq = ({String question, String answer});

/// The questions, by section. Public so a test can hold the copy to the rules.
const List<(String, List<Faq>)> kFaqSections = [
  (
    'Playing',
    [
      (
        question: 'How do I play?',
        answer:
            'Tap a tube to pick up its top balls, then tap another tube to '
            'pour them in. Balls only land on the same color or in an empty '
            'tube. Sort every tube to one color and the level is done. '
            'Settings → How to play replays the guided first level.',
      ),
      (
        question: 'What do the stars mean?',
        answer:
            'Stars count moves, nothing else. Finish in par or fewer for '
            'three stars, within one and a half times par for two, and any '
            'finish earns one. Par is the fewest moves the level can be '
            'solved in.',
      ),
      (
        question: 'Does the clock cost me stars?',
        answer:
            'Never. Time only changes your points. Beat the time par for '
            'bonus points, or take as long as you like and keep every star.',
      ),
      (
        question: 'Is every level solvable?',
        answer:
            'Yes. Every board was solved before it shipped, and par comes '
            'from that solution, so it is always reachable.',
      ),
      (
        question: 'What is the Daily Pour?',
        answer:
            'A new board every day, with its own leaderboard. It needs an '
            'internet connection. The campaign levels do not.',
      ),
    ],
  ),
  (
    'Stuck?',
    [
      (
        question: 'Is undo limited?',
        answer: 'No. Undo is free and unlimited, on every level.',
      ),
      (
        question: 'How do hints work?',
        answer:
            'Your first $kFreeHints hints are free. After that, a short '
            'video earns one. If a hint cannot be found, the video still '
            'counts toward your next one.',
      ),
      (
        question: 'What is the + Tube button?',
        answer:
            'When you are stuck, or your moves reach par, you can watch a '
            'video for an extra empty tube, up to two per attempt. Undo will '
            'not take it away. A level finished with an extra tube earns up '
            'to two stars.',
      ),
    ],
  ),
  (
    'Your progress',
    [
      (
        question: 'Do I need an account?',
        answer:
            'No. You play as a guest and your progress is saved on this '
            'phone. Signing in keeps your stars when you move to a new phone.',
      ),
      (
        question: 'Can I play offline?',
        answer:
            'Yes, the whole campaign. The Daily Pour and leaderboards need a '
            'connection, and your progress syncs when you are back online.',
      ),
      (
        question: 'How do I change my leaderboard name?',
        answer:
            'Settings → Change your name. You can also hide yourself from '
            'the boards there; your stars still count.',
      ),
    ],
  ),
  (
    'Ads & sound',
    [
      (
        question: 'What does Remove ads do?',
        answer:
            'It turns off the ads between levels. Hint and tube videos stay, '
            'because you only ever see one when you ask for it.',
      ),
      (
        question: 'I reinstalled. Where did Remove ads go?',
        answer:
            'It belongs to your Google Play account and usually comes back '
            'on its own. If not, tap Settings → Restore purchases.',
      ),
      (
        question: 'Will the game stop my music?',
        answer:
            'No. Pourfect plays its sounds alongside your music or podcast. '
            'Sound and haptics can be turned off in Settings.',
      ),
    ],
  ),
];

class FaqScreen extends StatelessWidget {
  final VoidCallback onClose;

  const FaqScreen({super.key, required this.onClose});

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Toy.cream,
    body: ToyScaffold(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      safeBottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ToyHeader(title: 'Questions', onBack: onClose),
          const SizedBox(height: 12),
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                0,
                2,
                0,
                24 + MediaQuery.paddingOf(context).bottom,
              ),
              children: [
                for (final (section, faqs) in kFaqSections) ...[
                  SectionHeader(label: section),
                  Group(children: [for (final faq in faqs) _FaqRow(faq: faq)]),
                ],
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

/// A question that opens to its answer.
///
/// Closed by default: sixteen answers open at once is a wall of text, and the
/// question list is how somebody finds theirs.
class _FaqRow extends StatefulWidget {
  final Faq faq;

  const _FaqRow({required this.faq});

  @override
  State<_FaqRow> createState() => _FaqRowState();
}

class _FaqRowState extends State<_FaqRow> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final calm = Toy.calm(context);
    final motion = calm ? Duration.zero : const Duration(milliseconds: 180);

    return Pressable(
      onPressed: () => setState(() => _open = !_open),
      depth: 1.5,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.faq.question,
                    style: Toy.ui(15, weight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 8),
                AnimatedRotation(
                  turns: _open ? 0.5 : 0,
                  duration: motion,
                  child: const Icon(Icons.expand_more_rounded, color: Toy.ink),
                ),
              ],
            ),
            AnimatedSize(
              duration: motion,
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: !_open
                  ? const SizedBox(width: double.infinity)
                  : Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        widget.faq.answer,
                        style: Toy.ui(
                          14,
                          weight: FontWeight.w500,
                          color: Toy.inkMuted,
                          height: 1.4,
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

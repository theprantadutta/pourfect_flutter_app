/// Questions players actually have, answered from how the game really works.
///
/// Asked for by the 1.0.0 testers. Every answer here is a rule the code
/// enforces, so each one names what it rests on — change the rule and the
/// sentence becomes a lie on a screen people trust:
///
/// - stars: `starsFor` (3 at par, 2 within 1.5x, 1 for any finish)
/// - the clock: `parSecondsFor`, and it moves points only, never stars
/// - hints: `kFreeHints`, and the credit kept when a hint cannot resolve
/// - the extra tube: `GameState.canOfferExtraTube`, past par or after a dead-end hint, two at most
/// - music: no audio focus is ever requested (verified on Android)
///
/// No contact address. There is none confirmed, and an invented one on a help
/// page is worse than none.
library;

import 'package:material_ui/material_ui.dart';

import '../../l10n/l10n.dart';
import '../../state/monetization_controller.dart' show kFreeHints;
import '../theme/toy.dart';
import '../widgets/settings_rows.dart';
import '../widgets/toy_kit.dart';

/// One question and its answer.
typedef Faq = ({String question, String answer});

/// The questions, by section, in [l]'s language. Public so a test can hold
/// the copy to the rules.
List<(String, List<Faq>)> faqSections(AppLocalizations l) => [
  (
    l.settingsFaqSectionPlaying,
    [
      (question: l.settingsFaqHowToPlayQ, answer: l.settingsFaqHowToPlayA),
      (question: l.settingsFaqStarsQ, answer: l.settingsFaqStarsA),
      (question: l.settingsFaqClockQ, answer: l.settingsFaqClockA),
      (question: l.settingsFaqSolvableQ, answer: l.settingsFaqSolvableA),
      (question: l.settingsFaqDailyQ, answer: l.settingsFaqDailyA),
    ],
  ),
  (
    l.settingsFaqSectionStuck,
    [
      (question: l.settingsFaqUndoQ, answer: l.settingsFaqUndoA),
      (question: l.settingsFaqHintsQ, answer: l.settingsFaqHintsA(kFreeHints)),
      (question: l.settingsFaqTubeQ, answer: l.settingsFaqTubeA),
      (question: l.settingsFaqHardQ, answer: l.settingsFaqHardA),
      (question: l.settingsFaqChestsQ, answer: l.settingsFaqChestsA),
      (question: l.settingsFaqFreezeQ, answer: l.settingsFaqFreezeA),
    ],
  ),
  (
    l.settingsFaqSectionProgress,
    [
      (question: l.settingsFaqAccountQ, answer: l.settingsFaqAccountA),
      (question: l.settingsFaqOfflineQ, answer: l.settingsFaqOfflineA),
      (question: l.settingsFaqNameQ, answer: l.settingsFaqNameA),
    ],
  ),
  (
    l.settingsFaqSectionAds,
    [
      (question: l.settingsFaqRemoveAdsQ, answer: l.settingsFaqRemoveAdsA),
      (question: l.settingsFaqReinstallQ, answer: l.settingsFaqReinstallA),
      (question: l.settingsFaqMusicQ, answer: l.settingsFaqMusicA),
    ],
  ),
];

/// [faqSections] in the device's language, for code with no BuildContext
/// (the tests that pin the copy to the game's constants).
List<(String, List<Faq>)> get kFaqSections => faqSections(appL10n());

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
          ToyHeader(
            title: context.l10n.settingsQuestionsTitle,
            onBack: onClose,
          ),
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
                for (final (section, faqs) in faqSections(context.l10n)) ...[
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

/// The acceptance gate for the Privacy Policy, Terms of Use and Refund Policy.
///
/// **Never shown on a first launch.** A brand-new player goes straight to a
/// puzzle; this appears on their SECOND launch, and thereafter whenever the
/// shared legal version is bumped. See `LegalAcceptance.shouldShowGate` for
/// why — first-launch friction is a measurable D1 killer and organic ranking
/// is the whole acquisition strategy.
///
/// Back navigation is blocked, so once it is shown it cannot be skipped. The
/// documents are read from the bundle rather than fetched, so this works with
/// no network — which matters for a game that is otherwise fully playable
/// offline.
///
/// Toybox: a "Before we pour" card with a chunky checkbox for the Terms and
/// one for the Privacy Policy, each naming its document as a link that opens
/// the bundled copy. LET'S POUR! is live once both are ticked.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../state/legal_acceptance.dart';
import '../theme/toy.dart';
import '../widgets/toy_kit.dart';
import '../widgets/pour_loader.dart';

class LegalConsentScreen extends StatefulWidget {
  /// Called once the player has accepted.
  final VoidCallback onAccepted;

  const LegalConsentScreen({super.key, required this.onAccepted});

  @override
  State<LegalConsentScreen> createState() => _LegalConsentScreenState();
}

class _LegalConsentScreenState extends State<LegalConsentScreen> {
  static const _privacy = _Document(
    'Privacy Policy',
    'assets/legal/privacy.md',
  );
  static const _terms = _Document('Terms of Service', 'assets/legal/terms.md');
  static const _refund = _Document('Refund Policy', 'assets/legal/refund.md');
  static const _documents = <_Document>[_privacy, _terms, _refund];

  final Map<String, String> _contents = {};
  bool _loaded = false;
  bool _acceptedTerms = false;
  bool _readPrivacy = false;
  bool _accepting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    for (final doc in _documents) {
      try {
        _contents[doc.asset] = await rootBundle.loadString(doc.asset);
      } catch (_) {
        // A missing asset must not leave a blank document behind a link —
        // say what happened and point at the hosted copy.
        _contents[doc.asset] =
            'This document could not be loaded on this device.\n\n'
            'You can read it at legal.pranta.dev before accepting.';
      }
    }
    if (mounted) setState(() => _loaded = true);
  }

  Future<void> _accept() async {
    setState(() => _accepting = true);
    await LegalAcceptance.recordAccepted();
    if (mounted) widget.onAccepted();
  }

  bool get _ready => _loaded && _acceptedTerms && _readPrivacy && !_accepting;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Cannot be dismissed. An acceptance gate with a back button is not a
      // gate, and the record of consent would be meaningless.
      canPop: false,
      child: ToyScaffold(
        padding: const EdgeInsets.fromLTRB(22, 0, 22, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Centred in the room above the button rather than pinned to the
            // top: on a tall phone the top-aligned card left a third of the
            // screen empty between it and LET'S POUR!. Still scrolls when the
            // text is large or the phone is short.
            Expanded(
              child: LayoutBuilder(
                builder: (context, box) => SingleChildScrollView(
                  padding: const EdgeInsets.only(top: 30, bottom: 12),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: (box.maxHeight - 42).clamp(0, double.infinity),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const _Wordmark(),
                        const SizedBox(height: 28),
                        _card(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            ToyButton(
              label: "LET'S POUR!",
              height: 62,
              onPressed: _ready ? _accept : null,
            ),
            const SizedBox(height: 12),
            Text(
              'You can read these again any time in Settings.',
              textAlign: TextAlign.center,
              style: Toy.ui(12, color: Toy.inkMuted),
            ),
          ],
        ),
      ),
    );
  }

  Widget _card() => Container(
    padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
    decoration: Toy.box(radius: Toy.rHero, shadow: 6, strokeWidth: 3),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Before we pour', style: Toy.display(32)),
        const SizedBox(height: 14),
        Text(
          "Pourfect is free, works offline and doesn't need an account. "
          'Please read and accept these first.',
          style: Toy.ui(
            14,
            weight: FontWeight.w500,
            color: const Color(0xFF4A4460),
            height: 1.5,
          ),
        ),
        const SizedBox(height: 14),
        _CheckRow(
          checked: _acceptedTerms,
          lead: 'I accept the ',
          link: _terms.label,
          onToggle: () => setState(() => _acceptedTerms = !_acceptedTerms),
          onOpen: () => _open(_terms),
        ),
        const SizedBox(height: 12),
        _CheckRow(
          checked: _readPrivacy,
          lead: "I've read the ",
          link: _privacy.label,
          onToggle: () => setState(() => _readPrivacy = !_readPrivacy),
          onOpen: () => _open(_privacy),
        ),
        const SizedBox(height: 14),
        // The third document is accepted too, and says so, with its own link.
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              'Accepting also covers our ',
              style: Toy.ui(12, weight: FontWeight.w500, color: Toy.inkMuted),
            ),
            _Link(
              label: _refund.label,
              size: 12,
              color: Toy.inkMuted,
              onPressed: () => _open(_refund),
            ),
            Text(
              ' (version ${LegalAcceptance.currentLegalVersion}).',
              style: Toy.ui(12, weight: FontWeight.w500, color: Toy.inkMuted),
            ),
          ],
        ),
      ],
    ),
  );

  /// Opens a bundled document to read in place.
  Future<void> _open(_Document doc) async {
    final body = _contents[doc.asset];
    await showToyDialog<void>(
      context: context,
      builder: (context) {
        final height = math.min(
          MediaQuery.sizeOf(context).height * 0.55,
          480.0,
        );
        return ToyDialogCard(
          headerColor: Toy.blue,
          header: Text(
            doc.label,
            style: Toy.display(22, color: Colors.white, shadow: 2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: height,
                child: body == null
                    ? const Center(child: PourLoader(ballSize: 18))
                    : Scrollbar(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.only(right: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: _render(body),
                          ),
                        ),
                      ),
              ),
              const SizedBox(height: 16),
              ToyButton(
                label: 'Close',
                color: Toy.mint,
                textColor: Toy.ink,
                height: 52,
                radius: 16,
                shadow: 4,
                fontSize: 20,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Renders the markdown legally enough to read, without a dependency.
  ///
  /// Showing the raw source leaks `#`, `**` and table pipes onto a screen the
  /// player is being asked to READ AND ACCEPT — which reads as unfinished on a
  /// game whose whole positioning is that it is not. A markdown package would
  /// cost APK budget for three static documents, so this handles the small
  /// subset they actually use: headings, bullets, bold, rules and tables.
  static List<Widget> _render(String source) {
    final base = Toy.ui(13, weight: FontWeight.w500, height: 1.5);
    final widgets = <Widget>[];

    for (final raw in source.split('\n')) {
      final line = raw.trimRight();

      if (line.trim().isEmpty) {
        widgets.add(const SizedBox(height: 10));
        continue;
      }

      // Horizontal rule.
      if (line.trim() == '---') {
        widgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Container(height: 1.5, color: Toy.divider),
          ),
        );
        continue;
      }

      // Table rows read acceptably as plain rows once the pipes are gone; the
      // separator row is pure syntax and is dropped.
      if (line.trimLeft().startsWith('|')) {
        final cells = line
            .trim()
            .split('|')
            .map((c) => c.trim())
            .where((c) => c.isNotEmpty);
        if (cells.every((c) => RegExp(r'^:?-{2,}:?$').hasMatch(c))) continue;
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Text(_inline(cells.join('  ·  ')), style: base),
          ),
        );
        continue;
      }

      final heading = RegExp(r'^(#{1,6})\s+(.*)$').firstMatch(line);
      if (heading != null) {
        final level = heading.group(1)!.length;
        widgets
          ..add(SizedBox(height: level <= 2 ? 16 : 12))
          ..add(
            Text(
              _inline(heading.group(2)!),
              style: Toy.ui(
                level == 1 ? 18 : (level == 2 ? 16 : 14),
                weight: FontWeight.w800,
                height: 1.3,
              ),
            ),
          )
          ..add(const SizedBox(height: 6));
        continue;
      }

      final bullet = RegExp(r'^(\s*)[-*]\s+(.*)$').firstMatch(line);
      if (bullet != null) {
        final indent = bullet.group(1)!.length;
        widgets.add(
          Padding(
            padding: EdgeInsets.only(left: 8.0 + indent * 4, bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '•  ',
                  style: base.copyWith(
                    color: Toy.tomato,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Expanded(child: Text(_inline(bullet.group(2)!), style: base)),
              ],
            ),
          ),
        );
        continue;
      }

      widgets.add(Text(_inline(line), style: base));
    }

    return widgets;
  }

  /// Strips inline markers. Bold is dropped rather than styled — mixing spans
  /// per line buys very little on a document nobody reads twice.
  static String _inline(String text) => text
      .replaceAll('**', '')
      .replaceAll('`', '')
      .replaceAllMapped(
        RegExp(r'\[([^\]]+)\]\(([^)]+)\)'),
        (m) => '${m.group(1)} (${m.group(2)})',
      );
}

/// "Pourfect" with the Ball-O: the o is an amber dot ball.
class _Wordmark extends StatelessWidget {
  const _Wordmark();

  @override
  Widget build(BuildContext context) {
    final style = Toy.display(50, color: Toy.tomato, shadow: 3);
    return Semantics(
      label: 'Pourfect',
      excludeSemantics: true,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('P', style: style),
            Padding(
              padding: const EdgeInsets.fromLTRB(2, 0, 2, 4),
              child: ToyBall.id(0, size: 37),
            ),
            Text('urfect', style: style),
          ],
        ),
      ),
    );
  }
}

/// One chunky checkbox row. The whole row ticks; the document name opens it.
class _CheckRow extends StatelessWidget {
  const _CheckRow({
    required this.checked,
    required this.lead,
    required this.link,
    required this.onToggle,
    required this.onOpen,
  });

  final bool checked;
  final String lead;
  final String link;
  final VoidCallback onToggle;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final calm = Toy.calm(context);
    return Semantics(
      checked: checked,
      child: Pressable(
        onPressed: onToggle,
        semanticLabel: '$lead$link',
        depth: 1.5,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Toy.cream,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Toy.ink, width: Toy.stroke),
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: calm
                    ? Duration.zero
                    : const Duration(milliseconds: 140),
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: checked ? Toy.mint : Toy.card,
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(color: Toy.ink, width: Toy.stroke),
                ),
                child: checked ? const ToyIcon(ToyGlyph.check, size: 18) : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(lead, style: Toy.ui(14)),
                    _Link(label: link, onPressed: onOpen),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// An underlined document name that opens the document.
class _Link extends StatelessWidget {
  const _Link({
    required this.label,
    required this.onPressed,
    this.size = 14,
    this.color = Toy.ink,
  });

  final String label;
  final VoidCallback onPressed;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => Pressable(
    onPressed: onPressed,
    semanticLabel: 'Read the $label',
    depth: 1,
    child: Text(
      label,
      style: Toy.ui(size, weight: FontWeight.w800, color: color).copyWith(
        decoration: TextDecoration.underline,
        decorationColor: color,
        decorationThickness: 2,
      ),
    ),
  );
}

class _Document {
  final String label;
  final String asset;

  const _Document(this.label, this.asset);
}

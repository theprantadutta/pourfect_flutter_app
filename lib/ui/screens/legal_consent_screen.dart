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
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../state/legal_acceptance.dart';
import '../theme/tokens.dart';
import '../theme/typography.dart';
import '../widgets/pressable.dart';

class LegalConsentScreen extends StatefulWidget {
  /// Called once the player has accepted.
  final VoidCallback onAccepted;

  const LegalConsentScreen({super.key, required this.onAccepted});

  @override
  State<LegalConsentScreen> createState() => _LegalConsentScreenState();
}

class _LegalConsentScreenState extends State<LegalConsentScreen> {
  static const _documents = <_Document>[
    _Document('Privacy', 'assets/legal/privacy.md'),
    _Document('Terms', 'assets/legal/terms.md'),
    _Document('Refunds', 'assets/legal/refund.md'),
  ];

  final Map<String, String> _contents = {};
  int _selected = 0;
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
        // A missing asset must not leave a blank screen with an Accept button
        // under it — say what happened and point at the hosted copy.
        _contents[doc.asset] =
            'This document could not be loaded on this device.\n\n'
            'You can read it at legal.pranta.dev before accepting.';
      }
    }
    if (mounted) setState(() {});
  }

  Future<void> _accept() async {
    setState(() => _accepting = true);
    await LegalAcceptance.recordAccepted();
    if (mounted) widget.onAccepted();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = PourfectTokens.of(context);
    final asset = _documents[_selected].asset;
    final body = _contents[asset];

    return PopScope(
      // Cannot be dismissed. An acceptance gate with a back button is not a
      // gate, and the record of consent would be meaningless.
      canPop: false,
      child: Scaffold(
        backgroundColor: tokens.surface,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'POURFECT',
                  style: actionStyle(tokens, color: tokens.dimText)
                      .copyWith(fontSize: 12, letterSpacing: 1.6),
                ),
                const SizedBox(height: 6),
                Text('Before you continue', style: titleStyle(tokens)),
                const SizedBox(height: 10),
                Text(
                  'A quick read, once. Nothing here is a surprise — the game '
                  'works offline, an account is optional, and you are never '
                  'on a leaderboard unless you pick a name.',
                  style: bodyStyle(tokens).copyWith(fontSize: 14),
                ),
                const SizedBox(height: 18),
                _tabs(tokens),
                const SizedBox(height: 12),
                Expanded(child: _document(tokens, body)),
                const SizedBox(height: 16),
                _acceptButton(tokens, ready: body != null),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _tabs(PourfectTokens tokens) => Row(
    children: [
      for (var i = 0; i < _documents.length; i++) ...[
        if (i > 0) const SizedBox(width: 8),
        Expanded(
          child: Pressable(
            onPressed: () => setState(() => _selected = i),
            child: AnimatedContainer(
              duration: tokens.selectDuration,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: i == _selected ? tokens.surfaceRaised : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: i == _selected ? tokens.accent.withValues(alpha: 0.55)
                      : tokens.hairline,
                ),
              ),
              child: Center(
                child: Text(
                  _documents[i].label,
                  style: actionStyle(
                    tokens,
                    color: i == _selected ? tokens.textPrimary : tokens.textMuted,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    ],
  );

  Widget _document(PourfectTokens tokens, String? body) {
    if (body == null) {
      return Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: tokens.accent.withValues(alpha: 0.6),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: tokens.surfaceRaised,
        borderRadius: BorderRadius.circular(tokens.panelRadius),
        border: Border.all(color: tokens.hairline),
      ),
      child: Scrollbar(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: _render(tokens, body),
          ),
        ),
      ),
    );
  }

  /// Renders the markdown legally enough to read, without a dependency.
  ///
  /// Showing the raw source leaks `#`, `**` and table pipes onto a screen the
  /// player is being asked to READ AND ACCEPT — which reads as unfinished on a
  /// game whose whole positioning is that it is not. A markdown package would
  /// cost APK budget for three static documents, so this handles the small
  /// subset they actually use: headings, bullets, bold, rules and tables.
  List<Widget> _render(PourfectTokens tokens, String source) {
    final base = bodyStyle(tokens).copyWith(fontSize: 12.5, height: 1.5);
    final widgets = <Widget>[];

    for (final raw in source.split('\n')) {
      final line = raw.trimRight();

      if (line.trim().isEmpty) {
        widgets.add(const SizedBox(height: 10));
        continue;
      }

      // Horizontal rule.
      if (line.trim() == '---') {
        widgets.add(Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Divider(color: tokens.hairline, height: 1),
        ));
        continue;
      }

      // Table rows read acceptably as plain rows once the pipes are gone; the
      // separator row is pure syntax and is dropped.
      if (line.trimLeft().startsWith('|')) {
        final cells = line.trim().split('|').map((c) => c.trim()).where((c) => c.isNotEmpty);
        if (cells.every((c) => RegExp(r'^:?-{2,}:?$').hasMatch(c))) continue;
        widgets.add(Padding(
          padding: const EdgeInsets.only(bottom: 2),
          child: Text(_inline(cells.join('  ·  ')), style: base),
        ));
        continue;
      }

      final heading = RegExp(r'^(#{1,6})\s+(.*)$').firstMatch(line);
      if (heading != null) {
        final level = heading.group(1)!.length;
        widgets
          ..add(SizedBox(height: level <= 2 ? 16 : 12))
          ..add(Text(
            _inline(heading.group(2)!),
            style: base.copyWith(
              fontSize: level == 1 ? 17 : (level == 2 ? 15 : 13.5),
              fontWeight: FontWeight.w600,
              color: tokens.textPrimary,
              height: 1.3,
            ),
          ))
          ..add(const SizedBox(height: 6));
        continue;
      }

      final bullet = RegExp(r'^(\s*)[-*]\s+(.*)$').firstMatch(line);
      if (bullet != null) {
        final indent = bullet.group(1)!.length;
        widgets.add(Padding(
          padding: EdgeInsets.only(left: 8.0 + indent * 4, bottom: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('·  ', style: base.copyWith(color: tokens.accent)),
              Expanded(child: Text(_inline(bullet.group(2)!), style: base)),
            ],
          ),
        ));
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

  Widget _acceptButton(PourfectTokens tokens, {required bool ready}) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        'By continuing you accept all three documents '
        '(version ${LegalAcceptance.currentLegalVersion}).',
        textAlign: TextAlign.center,
        style: bodyStyle(tokens).copyWith(fontSize: 12, color: tokens.dimText),
      ),
      const SizedBox(height: 12),
      Pressable(
        onPressed: ready && !_accepting ? _accept : null,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: tokens.accent.withValues(alpha: ready ? 0.14 : 0.05),
            borderRadius: BorderRadius.circular(tokens.panelRadius),
            border: Border.all(
              color: tokens.accent.withValues(alpha: ready ? 0.5 : 0.15),
            ),
          ),
          child: Center(
            child: Text(
              'Accept and play',
              style: actionStyle(
                tokens,
                color: ready ? tokens.accent : tokens.dimText,
              ).copyWith(fontSize: 16),
            ),
          ),
        ),
      ),
    ],
  );
}

class _Document {
  final String label;
  final String asset;

  const _Document(this.label, this.asset);
}

/// Settings.
///
/// Small screen, but its absence is the first thing a tester notices: sound and
/// haptics that cannot be turned off read as a bug rather than a missing
/// feature. Everything here takes effect on the very next tap.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../state/progress_repository.dart';
import '../../state/providers.dart';
import '../theme/ball_palette.dart';
import '../theme/tokens.dart';
import '../theme/typography.dart';
import '../widgets/ball.dart';
import '../widgets/pressable.dart';

/// Where the store listing's privacy policy points. Play requires this to be
/// reachable from inside the app as well as from the listing.
const kPrivacyPolicyUrl = 'https://pourfect.pranta.dev/privacy';

class SettingsScreen extends ConsumerStatefulWidget {
  final VoidCallback onClose;

  const SettingsScreen({super.key, required this.onClose});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  String _version = '';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() => _version = '${info.version} (${info.buildNumber})');
      }
    } catch (_) {
      // A missing version string is not worth an error state.
    }
  }

  Future<void> _confirmReset() async {
    final tokens = PourfectTokens.of(context);
    final cleared = ref.read(progressProvider).length;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: tokens.surfaceRaised,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(tokens.panelRadius),
          side: BorderSide(color: tokens.hairline),
        ),
        title: Text('Reset progress?', style: titleStyle(tokens)),
        content: Text(
          cleared == 0
              ? 'There is nothing to reset yet.'
              : 'This erases every star and best score across '
                    '$cleared solved ${cleared == 1 ? "level" : "levels"}, '
                    'and locks everything after level 1 again. It cannot be '
                    'undone.',
          style: bodyStyle(tokens),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Keep it',
              style: actionStyle(tokens, color: tokens.textMuted),
            ),
          ),
          TextButton(
            onPressed: cleared == 0
                ? null
                : () => Navigator.of(context).pop(true),
            child: Text(
              'Erase everything',
              // The destructive action reads as destructive. Rose is the
              // palette's own warm red, so this stays inside the game's
              // language rather than importing a system alert colour.
              style: actionStyle(tokens, color: const Color(0xFFC85F72)),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await ref.read(progressProvider.notifier).resetAll();
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          const SnackBar(
            content: Text('Progress reset.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
    }
  }

  Future<void> _openPrivacy() async {
    final uri = Uri.parse(kPrivacyPolicyUrl);
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          const SnackBar(
            content: Text('Could not open the browser.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = PourfectTokens.of(context);
    final settings = ref.watch(settingsProvider);
    final controller = ref.read(settingsProvider.notifier);

    return Scaffold(
      backgroundColor: tokens.surface,
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            tokens.space4,
            tokens.space3,
            tokens.space4,
            tokens.space5,
          ),
          children: [
            Row(
              children: [
                Pressable(
                  onPressed: widget.onClose,
                  semanticLabel: 'Back',
                  child: Padding(
                    padding: EdgeInsets.only(right: tokens.space3),
                    child: Icon(
                      Icons.chevron_left_rounded,
                      size: 26,
                      color: tokens.textMuted,
                    ),
                  ),
                ),
                Text(
                  'Settings',
                  style: titleStyle(tokens).copyWith(fontSize: 26),
                ),
              ],
            ),
            SizedBox(height: tokens.space5),

            _SectionLabel('Feel'),
            _ToggleRow(
              title: 'Sound',
              detail:
                  'Pours, chimes and taps. Mixes with your music — it will '
                  'never pause what you are listening to.',
              value: settings.soundEnabled,
              onChanged: controller.setSound,
            ),
            _ToggleRow(
              title: 'Haptics',
              detail: 'A tick as each ball lands, stronger when a tube fills.',
              value: settings.hapticsEnabled,
              onChanged: controller.setHaptics,
            ),

            SizedBox(height: tokens.space5),
            _SectionLabel('Visibility'),
            _ToggleRow(
              title: 'Bold symbols',
              detail:
                  'Every ball always carries a shape as well as a colour. '
                  'This makes those shapes larger and higher contrast.',
              value: settings.boldSymbols,
              onChanged: controller.setBoldSymbols,
            ),
            SizedBox(height: tokens.space3),
            _SymbolPreview(bold: settings.boldSymbols),

            SizedBox(height: tokens.space5),
            _SectionLabel('Progress'),
            _ActionRow(
              title: 'Reset progress',
              detail: 'Erase every star and start from level 1.',
              onTap: _confirmReset,
              destructive: true,
            ),

            SizedBox(height: tokens.space5),
            _SectionLabel('About'),
            _ActionRow(
              title: 'Privacy policy',
              detail: kPrivacyPolicyUrl.replaceFirst('https://', ''),
              onTap: _openPrivacy,
            ),
            Padding(
              padding: EdgeInsets.symmetric(vertical: tokens.space3),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Version',
                    style: bodyStyle(tokens).copyWith(fontSize: 14),
                  ),
                  Text(
                    _version.isEmpty ? '—' : _version,
                    style: numericStyle(
                      tokens,
                      size: 13,
                      weight: FontWeight.w500,
                      color: tokens.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    final tokens = PourfectTokens.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: tokens.space2),
      child: Text(text.toUpperCase(), style: labelStyle(tokens)),
    );
  }
}

/// A row with no box around it — a hairline underneath is enough separation,
/// and boxing every setting is what makes a settings screen look like a form.
class _ToggleRow extends StatelessWidget {
  final String title;
  final String detail;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleRow({
    required this.title,
    required this.detail,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = PourfectTokens.of(context);

    return Pressable(
      onPressed: () => onChanged(!value),
      semanticLabel: '$title, ${value ? "on" : "off"}',
      scale: 0.99,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: tokens.space3),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: tokens.hairline)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: actionStyle(tokens).copyWith(fontSize: 15),
                  ),
                  SizedBox(height: tokens.space1),
                  Text(
                    detail,
                    style: bodyStyle(tokens)
                        .copyWith(fontSize: 13, height: 1.45),
                  ),
                ],
              ),
            ),
            SizedBox(width: tokens.space3),
            _Switch(value: value),
          ],
        ),
      ),
    );
  }
}

/// A hairline switch, not Material's. The stock one arrives with its own
/// colour language and ripple; this one is made of the same tokens as
/// everything else on screen.
class _Switch extends StatelessWidget {
  final bool value;

  const _Switch({required this.value});

  @override
  Widget build(BuildContext context) {
    final tokens = PourfectTokens.of(context);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      width: 46,
      height: 27,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: value
            ? tokens.accent.withValues(alpha: 0.20)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: value
              ? tokens.accent.withValues(alpha: 0.55)
              : tokens.hairlineStrong,
        ),
      ),
      child: AnimatedAlign(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        alignment: value ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          width: 19,
          height: 19,
          decoration: BoxDecoration(
            color: value ? tokens.accent : tokens.textMuted,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  final String title;
  final String detail;
  final VoidCallback onTap;
  final bool destructive;

  const _ActionRow({
    required this.title,
    required this.detail,
    required this.onTap,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = PourfectTokens.of(context);

    return Pressable(
      onPressed: onTap,
      semanticLabel: title,
      scale: 0.99,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: tokens.space3),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: tokens.hairline)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: actionStyle(
                      tokens,
                      color: destructive
                          ? const Color(0xFFC85F72)
                          : tokens.textPrimary,
                    ).copyWith(fontSize: 15),
                  ),
                  SizedBox(height: tokens.space1),
                  Text(detail, style: bodyStyle(tokens).copyWith(fontSize: 13)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, size: 20, color: tokens.dimText),
          ],
        ),
      ),
    );
  }
}

/// Shows the first few balls at board size so the symbols toggle can be judged
/// against the thing it changes, rather than by reading a sentence about it.
class _SymbolPreview extends StatelessWidget {
  final bool bold;

  const _SymbolPreview({required this.bold});

  @override
  Widget build(BuildContext context) {
    final tokens = PourfectTokens.of(context);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: tokens.space3,
        vertical: tokens.space3,
      ),
      decoration: BoxDecoration(
        color: tokens.surfaceRaised,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: tokens.hairline),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          for (var i = 0; i < 6 && i < kBallPalette.length; i++)
            Ball(colorId: i, size: 34, boldGlyph: bold),
        ],
      ),
    );
  }
}

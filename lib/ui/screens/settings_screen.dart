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

import '../../services/analytics/analytics_service.dart';
import '../../services/iap/billing_service.dart';
import '../../state/monetization_controller.dart';
import '../../state/play_history.dart';
import '../../state/progress_repository.dart';
import '../../state/sync_controller.dart';
import '../../state/account_controller.dart';
import '../../state/providers.dart';
import '../theme/ball_palette.dart';
import '../transitions.dart';
import 'account_screen.dart';
import '../theme/tokens.dart';
import '../theme/typography.dart';
import '../widgets/ball.dart';
import '../widgets/pressable.dart';

/// The hosted legal documents. Confirmed live, and the same host Snake
/// Classic uses.
///
/// Play requires a reachable privacy policy URL on the listing AND from inside
/// the app. The in-app acceptance screen reads the BUNDLED copies in
/// `assets/legal/`, so these links are for the listing and for anybody who
/// wants to read the current version outside the installed build.
const kPrivacyPolicyUrl =
    'https://legal.pranta.dev/privacy?projectName=pourfect';
const kTermsUrl = 'https://legal.pranta.dev/terms?projectName=pourfect';
const kRefundPolicyUrl = 'https://legal.pranta.dev/refund?projectName=pourfect';

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
    // The offer being SEEN is the denominator of the purchase funnel. Without
    // it, a low conversion rate is indistinguishable from nobody finding it.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!ref.read(monetizationProvider).adsRemoved) {
        ref
            .read(analyticsServiceProvider)
            .log(
              const IapViewed(productId: 'remove_ads', placement: 'settings'),
            );
      }
    });
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
              // language rather than importing a system alert color.
              style: actionStyle(tokens, color: const Color(0xFFC85F72)),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await ref.read(progressProvider.notifier).resetAll();
      // The play history goes with it. Leaving a two-year streak standing
      // behind a wiped campaign would be a statistics screen reporting a
      // player who no longer exists.
      await ref.read(playHistoryProvider.notifier).resetAll();
      // ...and on the server, which is the half that used to be missing: the
      // next sync merged every star straight back, so this confirmation
      // promised something the app undid on the next app resume. A reset that
      // cannot be delivered right now is remembered and blocks merging until
      // it lands, so an offline reset is still a reset.
      await ref.read(syncControllerProvider.notifier).reset();
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

  Future<void> _buyRemoveAds() async {
    final outcome = await ref
        .read(monetizationProvider.notifier)
        .buyRemoveAds(placement: 'settings');
    if (!mounted) return;

    final message = switch (outcome) {
      PurchaseOutcome.purchased => 'Thank you. Ads between levels are off.',
      PurchaseOutcome.alreadyOwned => 'Already purchased — ads are off.',
      // Backing out is a normal choice, not a failure, and must never be
      // reported as an error.
      PurchaseOutcome.cancelled => null,
      PurchaseOutcome.unavailable =>
        'The store is not available on this device right now.',
      PurchaseOutcome.failed =>
        'The purchase did not go through. You have '
            'not been charged.',
    };
    if (message == null) return;

    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }

  Future<void> _restore() async {
    await ref.read(billingServiceProvider).restorePurchases();
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        const SnackBar(
          content: Text('Purchases restored, if there were any.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  /// Re-opens the advertising consent form.
  ///
  /// The row only exists where the SDK says a privacy-options entry point is
  /// REQUIRED, which is the same regions where the consent form itself is.
  /// Showing it everywhere would put a dead control in front of most players;
  /// showing it nowhere - which is what shipped - means somebody who consented
  /// in the EEA had no way to change their mind, and the form the app already
  /// knew how to open was unreachable from any screen.
  Future<void> _openAdPrivacyOptions() async {
    // The service applies whatever the player chooses: withdrawing consent
    // discards inventory requested under the old answer, granting it starts
    // filling again. This screen only has to reflect the result.
    await ref.read(adServiceProvider).showPrivacyOptions();
    if (mounted) setState(() {});
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

  Future<void> _openAccount() async {
    await Navigator.of(context).push(
      PourfectPageRoute<void>(builder: (_) => const AccountScreen()),
    );
  }

  Future<void> _confirmSignOut() async {
    final tokens = PourfectTokens.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: tokens.surfaceRaised,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(tokens.panelRadius),
          side: BorderSide(color: tokens.hairline),
        ),
        title: Text('Sign out?', style: titleStyle(tokens)),
        content: Text(
          // True, and worth saying: the campaign is on the device and stays
          // there. Signing out changes which account it syncs into next, and
          // the merge is monotonic, so nothing can be taken away by it.
          'Your progress stays on this phone. You can sign back in any time '
          'to pick it up somewhere else.',
          style: bodyStyle(tokens),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Stay signed in',
              style: actionStyle(tokens, color: tokens.textMuted),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Sign out', style: actionStyle(tokens)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await ref.read(accountProvider.notifier).signOut();
    }
  }

  Future<void> _confirmDeleteAccount() async {
    final tokens = PourfectTokens.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: tokens.surfaceRaised,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(tokens.panelRadius),
          side: BorderSide(color: tokens.hairline),
        ),
        title: Text('Delete your account?', style: titleStyle(tokens)),
        content: Text(
          'This removes your account, your stars, your streak and your '
          'leaderboard entry, on this phone and on our server. It cannot be '
          'undone.\n\nRemove Ads is not affected — it belongs to your Google '
          'Play account, and restores if you play again.',
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
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              'Delete everything',
              style: actionStyle(tokens, color: const Color(0xFFC85F72)),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final outcome = await ref.read(accountProvider.notifier).deleteAccount();
    if (!mounted) return;

    // A refusal has to be VISIBLE. Silently failing here leaves somebody
    // believing their data is gone when it is not, which is worse than the
    // deletion never having been offered.
    final problem = switch (outcome) {
      AccountDeletion.serverRefused =>
        'Could not reach the server. Nothing was deleted — try again when '
            'you are back online.',
      // Distinct from the above, because the fix is different. Reporting
      // success here is what the audit caught: no request was ever sent, the
      // account was untouched, and the credentials needed to retry had been
      // thrown away.
      AccountDeletion.notAuthenticated =>
        'Could not confirm it is you. Sign in again, then delete your '
            'account — nothing has been deleted yet.',
      AccountDeletion.busy || AccountDeletion.deleted => null,
    };

    if (problem != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: tokens.surfaceRaised,
          content: Text(problem, style: bodyStyle(tokens)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = PourfectTokens.of(context);
    final settings = ref.watch(settingsProvider);
    final controller = ref.read(settingsProvider.notifier);
    final money = ref.watch(monetizationProvider);

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
              // Names the condition explicitly. "Bold symbols" is the honest
              // label — the shapes are always there and this only changes
              // emphasis — but somebody who needs it will scan a settings list
              // for the words they already know, not for our framing.
              detail:
                  'Larger, higher-contrast shapes on each ball. Helpful for '
                  'color vision deficiency. Every ball always carries a shape '
                  'as well as a color, so this only changes how strongly it '
                  'is drawn.',
              value: settings.boldSymbols,
              onChanged: controller.setBoldSymbols,
            ),
            SizedBox(height: tokens.space3),
            _SymbolPreview(bold: settings.boldSymbols),

            SizedBox(height: tokens.space5),
            _SectionLabel('Support'),
            _RemoveAdsRow(
              adsRemoved: money.adsRemoved,
              price: ref.watch(billingServiceProvider).removeAdsProduct?.price,
              onBuy: _buyRemoveAds,
            ),
            // Play requires a user-visible way to restore a purchase, and a
            // player who reinstalls needs it to be findable.
            _ActionRow(
              title: 'Restore purchases',
              detail: 'If you bought Remove Ads on this account before.',
              onTap: _restore,
            ),

            SizedBox(height: tokens.space5),
            _SectionLabel('Progress'),
            // Hidden entirely in a build with no Firebase, rather than shown
            // as a control that cannot work.
            if (ref.watch(accountProvider).available) ...[
              if (ref.watch(accountProvider).signedIn)
                _ActionRow(
                  title: 'Signed in',
                  detail:
                      ref.watch(accountProvider).email ??
                      'Your progress moves with your account.',
                  onTap: _confirmSignOut,
                )
              else
                _ActionRow(
                  title: 'Save your progress',
                  // The honest claim, and the whole of it. Not "your progress
                  // is safe" — an anonymous account already survives a crash;
                  // what it does NOT survive is a new phone.
                  detail: 'Keep your stars if you change phones.',
                  onTap: _openAccount,
                ),
            ],
            _ActionRow(
              title: 'Reset progress',
              detail: 'Erase every star and start from level 1.',
              onTap: _confirmReset,
              destructive: true,
            ),
            // Required by Play for any app that lets people create accounts,
            // and it must be reachable IN the app rather than only on the web.
            if (ref.watch(accountProvider).available)
              _ActionRow(
                title: 'Delete account',
                detail: 'Remove your account and everything stored with it.',
                onTap: _confirmDeleteAccount,
                destructive: true,
              ),

            SizedBox(height: tokens.space5),
            _SectionLabel('About'),
            _ActionRow(
              title: 'Privacy policy',
              detail: kPrivacyPolicyUrl.replaceFirst('https://', ''),
              onTap: _openPrivacy,
            ),
            if (ref.watch(adServiceProvider).privacyOptionsRequired)
              _ActionRow(
                title: 'Ad privacy options',
                detail: 'Change what you agreed to for advertising.',
                onTap: _openAdPrivacyOptions,
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

/// The single purchase. States plainly what it does AND what it does not, so
/// nobody buys it expecting hints to become free.
class _RemoveAdsRow extends StatelessWidget {
  final bool adsRemoved;
  final String? price;
  final VoidCallback onBuy;

  const _RemoveAdsRow({
    required this.adsRemoved,
    required this.price,
    required this.onBuy,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = PourfectTokens.of(context);

    if (adsRemoved) {
      return Container(
        padding: EdgeInsets.symmetric(vertical: tokens.space3),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: tokens.hairline)),
        ),
        child: Row(
          children: [
            Icon(Icons.check_rounded, size: 18, color: tokens.accentWarm),
            SizedBox(width: tokens.space2),
            Expanded(
              child: Text(
                'Ads removed — thank you',
                style: actionStyle(
                  tokens,
                  color: tokens.accentWarm,
                ).copyWith(fontSize: 15),
              ),
            ),
          ],
        ),
      );
    }

    return Pressable(
      onPressed: onBuy,
      semanticLabel: 'Remove ads',
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
                    'Remove ads',
                    style: actionStyle(tokens).copyWith(fontSize: 15),
                  ),
                  SizedBox(height: tokens.space1),
                  Text(
                    'Stops the ads between levels, for good. Hint videos stay '
                    'available if you ever want one.',
                    style: bodyStyle(tokens)
                        .copyWith(fontSize: 13, height: 1.45),
                  ),
                ],
              ),
            ),
            SizedBox(width: tokens.space3),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: tokens.accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: tokens.accent.withValues(alpha: 0.4)),
              ),
              child: Text(
                // Falls back to a dash rather than a hard-coded price: the
                // store is the authority on what this costs in each region,
                // and a wrong price shown next to a real charge is a refund.
                price ?? '—',
                style: numericStyle(tokens, size: 14, color: tokens.accent),
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
/// color language and ripple; this one is made of the same tokens as
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

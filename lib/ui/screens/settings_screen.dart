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
import '../widgets/player_crest.dart';
import '../widgets/rename_dialog.dart';
import '../widgets/settings_rows.dart';
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

  /// Renames the leaderboard handle.
  Future<void> _renameHandle() async {
    final tokens = PourfectTokens.of(context);

    // The DIALOG owns its controller, and that is the whole fix.
    //
    // Building it here and disposing it after `showDialog` returns looks
    // correct and is not: the future completes when Navigator.pop is called,
    // while the dialog and its TextField are still in the tree playing the
    // exit animation. Disposing at that moment left the field rebuilding
    // against a dead controller — "A TextEditingController was used after
    // being disposed", thrown on cancel, every time.
    final chosen = await showRenameDialog(
      context,
      ref.read(accountProvider).handle ?? '',
    );

    if (chosen == null || !mounted) return;

    final problem = await ref.read(accountProvider.notifier).renameHandle(chosen);
    if (!mounted) return;

    if (problem != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(problem, style: bodyStyle(tokens)),
          backgroundColor: tokens.surfaceRaised,
        ),
      );
    }
  }

  /// Puts the player on the boards, or takes them off.
  Future<void> _setLeaderboardVisibility(bool visible) async {
    final tokens = PourfectTokens.of(context);
    final ok = await ref.read(accountProvider.notifier)
        .setLeaderboardVisibility(visible);

    if (ok || !mounted) return;

    // The switch has NOT moved, because the server never agreed. Saying so is
    // the whole point: a control that looks like it worked, on a request that
    // did not, tells somebody they are hidden while they are still listed.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Could not reach the server, so nothing changed.',
          style: bodyStyle(tokens),
        ),
        backgroundColor: tokens.surfaceRaised,
      ),
    );
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
    final account = ref.watch(accountProvider);
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
            SizedBox(height: tokens.space4),

            // WHOSE settings these are, before what they contain.
            //
            // The screen used to open on "Sound". Snake Classic's equivalent
            // opens on the player, and that is the difference between a
            // preferences list and somewhere you recognise — it also puts the
            // handle in front of somebody who has never seen it.
            _PlayerHeader(
              account: account,
              solved: ref.watch(progressProvider).length,
              stars: ref.read(progressProvider.notifier).totalStars,
              onRename: _renameHandle,
            ),

            SizedBox(height: tokens.space5),
            SectionHeader(icon: Icons.graphic_eq_rounded, label: 'Feel'),
            Group(children: [
              ToggleRow(
                icon: Icons.volume_up_rounded,
                title: 'Sound',
                detail: 'Never pauses your music.',
                value: settings.soundEnabled,
                onChanged: controller.setSound,
              ),
              ToggleRow(
                icon: Icons.vibration_rounded,
                title: 'Haptics',
                detail: 'A tick as each ball lands.',
                value: settings.hapticsEnabled,
                onChanged: controller.setHaptics,
                last: true,
              ),
            ]),

            SizedBox(height: tokens.space5),
            SectionHeader(
              icon: Icons.visibility_rounded,
              label: 'Visibility',
            ),
            Group(children: [
              ToggleRow(
                icon: Icons.category_rounded,
                title: 'Bold symbols',
                // Names the condition explicitly. "Bold symbols" is the honest
                // label — the shapes are always there and this only changes
                // emphasis — but somebody who needs it will scan a settings
                // list for the words they already know, not for our framing.
                detail: 'Stronger shapes on each ball. For color vision '
                    'deficiency.',
                value: settings.boldSymbols,
                onChanged: controller.setBoldSymbols,
              ),
              // INSIDE the group, directly under the switch that changes it.
              // A preview separated from its control is a picture; touching
              // the two makes it a demonstration.
              GroupInset(child: _SymbolPreview(bold: settings.boldSymbols)),
            ]),

            SizedBox(height: tokens.space5),
            SectionHeader(
              icon: Icons.leaderboard_rounded,
              label: 'Leaderboard',
            ),
            Group(children: [
              // The name comes FIRST, because it is the thing a player came
              // looking for. The switch under it is the thing they did not
              // know they had.
              // Says what tapping DOES. The handle itself is already the
              // largest thing on the screen, at the top, so repeating it here
              // was the same value printed twice and neither one reading as a
              // control.
              ActionRow(
                icon: Icons.badge_rounded,
                title: 'Change your name',
                detail: 'How you appear on the boards.',
                onTap: _renameHandle,
              ),
              ToggleRow(
                icon: Icons.public_rounded,
                title: 'Show me on leaderboards',
                detail: 'Off hides your name and rank. Stars still count.',
                value: account.showOnLeaderboards,
                onChanged: _setLeaderboardVisibility,
                last: true,
              ),
            ]),

            SizedBox(height: tokens.space5),
            SectionHeader(
              icon: Icons.favorite_rounded,
              label: 'Support',
            ),
            Group(children: [
              _RemoveAdsRow(
                adsRemoved: money.adsRemoved,
                price: ref.watch(billingServiceProvider).removeAdsProduct?.price,
                onBuy: _buyRemoveAds,
              ),
              // Play requires a user-visible way to restore a purchase, and a
              // player who reinstalls needs it to be findable.
              ActionRow(
                icon: Icons.restore_rounded,
                title: 'Restore purchases',
                detail: 'If you bought Remove Ads before.',
                onTap: _restore,
                last: true,
              ),
            ]),

            SizedBox(height: tokens.space5),
            SectionHeader(
              icon: Icons.cloud_done_rounded,
              label: 'Account',
            ),
            Group(children: [
              // Hidden entirely in a build with no Firebase, rather than shown
              // as a control that cannot work.
              if (account.available)
                if (account.signedIn)
                  ActionRow(
                    icon: Icons.check_circle_rounded,
                    title: 'Signed in',
                    detail: account.email ?? 'Your progress moves with you.',
                    onTap: _confirmSignOut,
                    last: true,
                  )
                else
                  ActionRow(
                    icon: Icons.cloud_upload_rounded,
                    title: 'Save your progress',
                    // The honest claim, and the whole of it. Not "your
                    // progress is safe" — an anonymous account already
                    // survives a crash; what it does NOT survive is a new
                    // phone.
                    detail: 'Keep your stars if you change phones.',
                    onTap: _openAccount,
                    last: true,
                  ),
            ]),

            SizedBox(height: tokens.space5),
            SectionHeader(
              icon: Icons.info_outline_rounded,
              label: 'About',
            ),
            Group(children: [
              ActionRow(
                icon: Icons.shield_rounded,
                title: 'Privacy policy',
                detail: kPrivacyPolicyUrl.replaceFirst('https://', ''),
                onTap: _openPrivacy,
                last: !ref.watch(adServiceProvider).privacyOptionsRequired,
              ),
              if (ref.watch(adServiceProvider).privacyOptionsRequired)
                ActionRow(
                  icon: Icons.campaign_rounded,
                  title: 'Ad privacy options',
                  detail: 'Change what you agreed to for advertising.',
                  onTap: _openAdPrivacyOptions,
                  last: true,
                ),
            ]),

            // LAST, and in its own frame.
            //
            // These two used to sit in the middle of the list at the same
            // weight as Haptics, separated only by being red. Putting them at
            // the bottom behind their own border is the difference between a
            // control you can reach and one you have to decide to reach.
            SizedBox(height: tokens.space5),
            SectionHeader(
              icon: Icons.warning_rounded,
              label: 'Danger zone',
              danger: true,
            ),
            Group(
              danger: true,
              children: [
                ActionRow(
                  icon: Icons.restart_alt_rounded,
                  title: 'Reset progress',
                  detail: 'Erase every star and start from level 1.',
                  onTap: _confirmReset,
                  destructive: true,
                  last: !account.available,
                ),
                // Required by Play for any app that lets people create
                // accounts, and it must be reachable IN the app rather than
                // only on the web.
                if (account.available)
                  ActionRow(
                    icon: Icons.person_remove_rounded,
                    title: 'Delete account',
                    detail: 'Remove your account and everything with it.',
                    onTap: _confirmDeleteAccount,
                    destructive: true,
                    last: true,
                  ),
              ],
            ),

            SizedBox(height: tokens.space4),
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
        padding: EdgeInsets.symmetric(
          horizontal: tokens.space3,
          vertical: tokens.space3,
        ),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: tokens.hairline)),
        ),
        child: Row(
          children: [
            RowIcon(icon: Icons.check_circle_rounded, active: true),
            SizedBox(width: tokens.space3),
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
        padding: EdgeInsets.symmetric(
          horizontal: tokens.space3,
          vertical: tokens.space3,
        ),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: tokens.hairline)),
        ),
        child: Row(
          children: [
            RowIcon(icon: Icons.block_rounded),
            SizedBox(width: tokens.space3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Remove ads',
                    style: actionStyle(tokens).copyWith(fontSize: 15),
                  ),
                  SizedBox(height: 2),
                  Text(
                    // Says what it does NOT do as well, so nobody buys it
                    // expecting hints to become free.
                    'No ads between levels. Hint videos stay.',
                    style: bodyStyle(tokens)
                        .copyWith(fontSize: 12, height: 1.4),
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

/// A section's name, with a glyph and a rule out to the edge.
///
/// **This screen is app furniture, and may look like it.** The no-cards rule
/// in CLAUDE.md is about the HOME screen, where every bordered box reads as a
/// piece of an app rather than a game. Settings IS an app surface — the
/// reference this was rebuilt against groups every setting into a framed panel
/// and is better for it. What does carry over is the palette: quiet glyphs and
/// hairlines, never the reference's neon.
class _PlayerHeader extends StatelessWidget {
  final AccountState account;
  final int solved;
  final int stars;
  final VoidCallback onRename;

  const _PlayerHeader({
    required this.account,
    required this.solved,
    required this.stars,
    required this.onRename,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = PourfectTokens.of(context);

    return Pressable(
      onPressed: onRename,
      semanticLabel: 'Your name',
      scale: 0.99,
      child: Container(
        padding: EdgeInsets.all(tokens.space4),
        decoration: BoxDecoration(
          color: tokens.surfaceRaised,
          borderRadius: BorderRadius.circular(tokens.panelRadius),
          border: Border.all(color: tokens.hairline),
        ),
        child: Row(
          children: [
            PlayerCrest(
              seed: account.userId,
              photoUrl: account.photoUrl,
              signedIn: account.signedIn,
              size: 46,
            ),
            SizedBox(width: tokens.space3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // SHRINKS rather than crops. A handle is the one string on
                  // this screen that is a name, and half a name with an
                  // ellipsis on it is worse than a small whole one — the
                  // longest the server can issue is 24 characters, which fits
                  // once it is allowed to scale.
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      account.handle ?? 'Naming you…',
                      style: titleStyle(tokens).copyWith(fontSize: 18),
                      maxLines: 1,
                    ),
                  ),
                  SizedBox(height: tokens.space1),
                  Text(
                    // States what the account actually buys, and nothing
                    // more. An anonymous account survives a crash; what it
                    // does not survive is a new phone.
                    account.signedIn
                        ? (account.email ?? 'Signed in')
                        : 'Playing as a guest',
                    style: bodyStyle(tokens).copyWith(fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            SizedBox(width: tokens.space3),
            _HeaderStat(value: solved, label: 'SOLVED'),
            SizedBox(width: tokens.space3),
            _HeaderStat(
              value: stars,
              label: 'STARS',
              color: tokens.accentWarm,
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderStat extends StatelessWidget {
  final int value;
  final String label;
  final Color? color;

  const _HeaderStat({required this.value, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    final tokens = PourfectTokens.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          value.toString().padLeft(2, '0'),
          style: numericStyle(tokens, size: 16).copyWith(
            color: color ?? tokens.textPrimary,
          ),
        ),
        Text(label, style: labelStyle(tokens).copyWith(fontSize: 9)),
      ],
    );
  }
}

/// A row with no box around it — a hairline underneath is enough separation,
/// and boxing every setting is what makes a settings screen look like a form.
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
      // No border of its own. It sits INSIDE the group now, and a bordered
      // box within a bordered box is two frames arguing about which one is
      // the container. The ground tint alone separates it.
      decoration: BoxDecoration(
        color: tokens.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
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

/// The rename box.
///
/// Validates as you type rather than on submit, so the rule is visible while
/// somebody is still deciding rather than after they have committed to a name
/// and been bounced. `displayNameProblem` is the SAME function the server's
/// validator mirrors, so a name accepted here is not refused there.

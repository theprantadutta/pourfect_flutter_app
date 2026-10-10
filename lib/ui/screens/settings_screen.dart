/// Settings.
///
/// Small screen, but its absence is the first thing a tester notices: sound and
/// haptics that cannot be turned off read as a bug rather than a missing
/// feature. Everything here takes effect on the very next tap.
///
/// **This screen is app furniture, and may look like it.** The no-cards rule
/// in CLAUDE.md is about the HOME screen, where every bordered box reads as a
/// piece of an app rather than a game. Settings IS an app surface: in Toybox
/// every section is a chunky white card, every row leads with a colored tile,
/// and the danger zone is its own tomato-tinted card at the bottom.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/analytics/analytics_service.dart';
import '../../services/iap/billing_service.dart';
import '../../state/account_controller.dart';
import '../../services/api/push_service.dart';
import '../../state/monetization_controller.dart';
import '../../state/notification_prefs.dart';
import '../../state/onboarding.dart';
import '../../state/play_history.dart';
import '../../state/progress_repository.dart';
import '../../state/providers.dart';
import '../../state/sync_controller.dart';
import '../theme/ball_palette.dart';
import '../theme/toy.dart';
import '../transitions.dart';
import '../widgets/ball.dart';
import '../widgets/rename_dialog.dart';
import '../widgets/settings_rows.dart';
import '../widgets/toy_kit.dart';
import 'account_screen.dart';
import 'faq_screen.dart';
import 'game_screen.dart';

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
    // The permission may have changed in the system settings, and the
    // switches on another device, since this screen was last open.
    Future.microtask(
      () => ref.read(notificationPrefsProvider.notifier).refresh(),
    );
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
    final cleared = ref.read(progressProvider).length;

    final confirmed = await showRowConfirm(
      context: context,
      title: 'Reset progress?',
      body: cleared == 0
          ? 'There is nothing to reset yet.'
          : 'This erases every star and best score across '
                '$cleared solved ${cleared == 1 ? "level" : "levels"}, '
                'and locks everything after level 1 again. It cannot be '
                'undone.',
      cancelLabel: 'Keep it',
      confirmLabel: 'Erase everything',
      destructive: true,
      confirmEnabled: cleared != 0,
    );

    if (confirmed && mounted) {
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
      showRowMessage(context, 'Progress reset.');
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
      PurchaseOutcome.pending =>
        'Payment pending. Ads will switch off once it clears.',
      PurchaseOutcome.unavailable =>
        'The store is not available on this device right now.',
      PurchaseOutcome.failed =>
        'The purchase did not go through. You have '
            'not been charged.',
    };
    if (message == null) return;
    showRowMessage(context, message);
  }

  /// Replays the guided level, with every one-time tip reset to show again.
  Future<void> _howToPlay() async {
    await ref.read(onboardingProvider.notifier).reset();
    if (!mounted) return;
    Navigator.of(context).push(
      PourfectPageRoute<void>(
        builder: (route) => GameScreen(
          levelId: 1,
          tutorial: true,
          onExit: () => Navigator.of(route).pop(),
        ),
      ),
    );
  }

  void _openQuestions() {
    Navigator.of(context).push(
      PourfectPageRoute<void>(
        builder: (route) => FaqScreen(onClose: () => Navigator.of(route).pop()),
      ),
    );
  }

  /// The store listing, for somebody who came looking for a way to rate.
  ///
  /// The listing rather than the in-app card: Play may silently refuse the
  /// card on quota, and a row that sometimes does nothing reads as broken.
  /// The card stays where `ReviewPrompter` puts it — after a good win.
  Future<void> _rate() async {
    final opened = await ref.read(reviewServiceProvider).openStoreListing();
    if (!opened && mounted) {
      showRowMessage(context, 'Could not open the store.');
    }
  }

  Future<void> _restore() async {
    await ref.read(billingServiceProvider).restorePurchases();
    if (!mounted) return;
    showRowMessage(context, 'Purchases restored, if there were any.');
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

  Future<void> _openUrl(String url) async {
    final ok = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );
    if (!ok && mounted) showRowMessage(context, 'Could not open the browser.');
  }

  Future<void> _openPrivacy() => _openUrl(kPrivacyPolicyUrl);

  /// Terms, refunds and the open-source licenses, behind one row.
  ///
  /// The font licenses are REQUIRED to travel with the app (SIL OFL), and
  /// `registerFontLicenses` puts them on Flutter's license page — which is
  /// only compliance if somebody can actually reach that page.
  Future<void> _openTermsAndLicenses() async {
    final choice = await showToyDialog<String>(
      context: context,
      builder: (context) => ToyDialogCard(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Terms & licenses', style: Toy.display(24, height: 1.1)),
            const SizedBox(height: 16),
            for (final (key, label) in const [
              ('terms', 'Terms of use'),
              ('refund', 'Refund policy'),
              ('licenses', 'Open-source licenses'),
            ]) ...[
              ToyButton.secondary(
                label: label,
                onPressed: () => Navigator.of(context).pop(key),
              ),
              const SizedBox(height: 10),
            ],
            const SizedBox(height: 4),
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
      ),
    );
    if (!mounted) return;
    switch (choice) {
      case 'terms':
        await _openUrl(kTermsUrl);
      case 'refund':
        await _openUrl(kRefundPolicyUrl);
      case 'licenses':
        showLicensePage(
          context: context,
          applicationName: 'Pourfect',
          applicationVersion: _version.isEmpty ? null : _version,
        );
    }
  }

  Future<void> _openAccount() async {
    await Navigator.of(context)
        .push(PourfectPageRoute<void>(builder: (_) => const AccountScreen()));
  }

  Future<void> _confirmSignOut() async {
    final confirmed = await showRowConfirm(
      context: context,
      title: 'Sign out?',
      // True, and worth saying: the campaign is on the device and stays
      // there. Signing out changes which account it syncs into next, and
      // the merge is monotonic, so nothing can be taken away by it.
      body:
          'Your progress stays on this phone. You can sign back in any time '
          'to pick it up somewhere else.',
      cancelLabel: 'Stay signed in',
      confirmLabel: 'Sign out',
    );

    if (confirmed && mounted) {
      await ref.read(accountProvider.notifier).signOut();
    }
  }

  /// Renames the leaderboard handle.
  Future<void> _renameHandle() async {
    // The DIALOG owns its controller, and that is the whole fix.
    //
    // Building it here and disposing it after the dialog returns looks
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

    final problem = await ref
        .read(accountProvider.notifier)
        .renameHandle(chosen);
    if (!mounted) return;

    if (problem != null) showRowMessage(context, problem);
  }

  /// Puts the player on the boards, or takes them off.
  Future<void> _setLeaderboardVisibility(bool visible) async {
    final ok = await ref
        .read(accountProvider.notifier)
        .setLeaderboardVisibility(visible);

    if (ok || !mounted) return;

    // The switch has NOT moved, because the server never agreed. Saying so is
    // the whole point: a control that looks like it worked, on a request that
    // did not, tells somebody they are hidden while they are still listed.
    showRowMessage(context, 'Could not reach the server, so nothing changed.');
  }

  Future<void> _confirmDeleteAccount() async {
    final confirmed = await showRowConfirm(
      context: context,
      title: 'Delete your account?',
      body:
          'This removes your account, your stars, your streak and your '
          'leaderboard entry, on this phone and on our server. It cannot be '
          'undone.\n\nRemove Ads is not affected — it belongs to your Google '
          'Play account, and restores if you play again.',
      cancelLabel: 'Keep it',
      confirmLabel: 'Delete everything',
      destructive: true,
    );

    if (!confirmed || !mounted) return;

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

    if (problem != null) showRowMessage(context, problem);
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final account = ref.watch(accountProvider);
    final controller = ref.read(settingsProvider.notifier);
    final money = ref.watch(monetizationProvider);
    final adPrivacy = ref.watch(adServiceProvider).privacyOptionsRequired;
    final boards = ref.watch(campaignProvider).value?.levels.length;

    return Scaffold(
      backgroundColor: Toy.cream,
      body: ToyScaffold(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
        safeBottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ToyHeader(title: 'Settings', onBack: widget.onClose),
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
                  // WHOSE settings these are, before what they contain.
                  //
                  // The screen used to open on "Sound". Snake Classic's
                  // equivalent opens on the player, and that is the difference
                  // between a preferences list and somewhere you recognise —
                  // it also puts the handle in front of somebody who has never
                  // seen it.
                  _PlayerCard(
                    account: account,
                    solved: ref.watch(progressProvider).length,
                    stars: ref.read(progressProvider.notifier).totalStars,
                    onRename: _renameHandle,
                  ),

                  const SectionHeader(label: 'Feel'),
                  Group(
                    children: [
                      ToggleRow(
                        icon: const Icon(Icons.music_note_rounded),
                        iconColor: Toy.yellow,
                        title: 'Sound',
                        detail: 'Never pauses your music',
                        value: settings.soundEnabled,
                        onChanged: controller.setSound,
                      ),
                      ToggleRow(
                        icon: const Icon(Icons.vibration_rounded),
                        iconColor: Toy.pink,
                        title: 'Haptics',
                        detail: 'A tick as each ball lands',
                        value: settings.hapticsEnabled,
                        onChanged: controller.setHaptics,
                      ),
                      ChoiceRow<SmoothMotion>(
                        icon: const Icon(Icons.speed_rounded),
                        iconColor: Toy.mint,
                        title: 'Smooth motion',
                        detail: _smoothMotionDetail(
                          ref.watch(displayRateProvider),
                          settings.smoothMotion,
                        ),
                        options: const [
                          (SmoothMotion.auto, 'Auto'),
                          (SmoothMotion.standard, '60 Hz'),
                          (SmoothMotion.max, 'Max'),
                        ],
                        value: settings.smoothMotion,
                        onChanged: (mode) {
                          controller.setSmoothMotion(mode);
                          // Picking Auto again is asking for another try at
                          // the fast rate, so an old step-down is forgotten.
                          if (mode == SmoothMotion.auto) {
                            ref.read(displayRateProvider.notifier).retryAuto();
                          }
                        },
                      ),
                    ],
                  ),

                  const SectionHeader(label: 'Visibility'),
                  Group(
                    children: [
                      ToggleRow(
                        icon: Text(
                          'Aa',
                          style: Toy.ui(15, weight: FontWeight.w800),
                        ),
                        iconColor: Toy.blue,
                        iconInk: Colors.white,
                        title: 'Bold symbols',
                        // Names the condition explicitly. "Bold symbols" is the
                        // honest label — the shapes are always there and this
                        // only changes emphasis — but somebody who needs it
                        // will scan a settings list for the words they already
                        // know, not for our framing.
                        detail: 'Stronger shapes for color vision deficiency',
                        value: settings.boldSymbols,
                        onChanged: controller.setBoldSymbols,
                      ),
                      // INSIDE the group, directly under the switch that
                      // changes it. A preview separated from its control is a
                      // picture; touching the two makes it a demonstration.
                      GroupInset(
                        child: _SymbolPreview(bold: settings.boldSymbols),
                      ),
                    ],
                  ),

                  const SectionHeader(label: 'Leaderboard'),
                  Group(
                    children: [
                      // The name comes FIRST, because it is the thing a player
                      // came looking for. Says what tapping DOES: the handle is
                      // already the largest thing on the screen, at the top.
                      ActionRow(
                        icon: const Icon(Icons.edit_rounded),
                        iconColor: Toy.mint,
                        title: 'Change your name',
                        detail: 'How you appear on the boards',
                        onTap: _renameHandle,
                      ),
                      ToggleRow(
                        icon: const Icon(Icons.contrast_rounded),
                        iconColor: kRowMoss,
                        title: 'Show me on leaderboards',
                        detail:
                            'Off hides your name and rank. Stars still '
                            'count.',
                        value: account.showOnLeaderboards,
                        onChanged: _setLeaderboardVisibility,
                      ),
                    ],
                  ),

                  const SectionHeader(label: 'Notifications'),
                  _NotificationsGroup(
                    onProblem: (message) => showRowMessage(context, message),
                  ),

                  const SectionHeader(label: 'Support'),
                  Group(
                    children: [
                      ActionRow(
                        icon: const Icon(Icons.school_rounded),
                        iconColor: Toy.yellow,
                        title: 'How to play',
                        detail: 'Replay the guided first level',
                        onTap: _howToPlay,
                      ),
                      ActionRow(
                        icon: const Icon(Icons.help_rounded),
                        iconColor: Toy.lilac,
                        iconInk: Colors.white,
                        title: 'Questions',
                        detail: 'Stars, hints, the clock and more',
                        onTap: _openQuestions,
                      ),
                      ActionRow(
                        icon: const Icon(Icons.star_rounded),
                        iconColor: Toy.pink,
                        title: 'Rate Pourfect',
                        detail: 'Tell other players what you think',
                        onTap: _rate,
                      ),
                      _RemoveAdsRow(
                        adsRemoved: money.adsRemoved,
                        price: ref
                            .watch(billingServiceProvider)
                            .removeAdsProduct
                            ?.price,
                        onBuy: _buyRemoveAds,
                      ),
                      // Play requires a user-visible way to restore a
                      // purchase, and a player who reinstalls needs it to be
                      // findable.
                      ActionRow(
                        icon: const Icon(Icons.replay_rounded),
                        title: 'Restore purchases',
                        detail: 'If you bought Remove Ads before',
                        onTap: _restore,
                      ),
                    ],
                  ),

                  const SectionHeader(label: 'Account & about'),
                  Group(
                    children: [
                      // Hidden entirely in a build with no Firebase, rather
                      // than shown as a control that cannot work.
                      if (account.available)
                        if (account.signedIn)
                          ActionRow(
                            icon: const Icon(Icons.check_rounded),
                            iconColor: Toy.lilac,
                            iconInk: Colors.white,
                            title: 'Signed in',
                            detail: account.email == null
                                ? 'Your progress moves with you'
                                : maskEmail(account.email!),
                            onTap: _confirmSignOut,
                          )
                        else
                          ActionRow(
                            icon: const Icon(Icons.cloud_upload_rounded),
                            iconColor: Toy.blue,
                            iconInk: Colors.white,
                            title: 'Save your progress',
                            // The honest claim, and the whole of it. Not "your
                            // progress is safe" — an anonymous account already
                            // survives a crash; what it does NOT survive is a
                            // new phone.
                            detail: 'Keep your stars if you change phones',
                            onTap: _openAccount,
                          ),
                      ActionRow(
                        icon: Text(
                          '§',
                          style: Toy.ui(16, weight: FontWeight.w800),
                        ),
                        title: 'Privacy policy',
                        onTap: _openPrivacy,
                      ),
                      ActionRow(
                        icon: Text(
                          '¶',
                          style: Toy.ui(16, weight: FontWeight.w800),
                        ),
                        title: 'Terms & licenses',
                        onTap: _openTermsAndLicenses,
                      ),
                      if (adPrivacy)
                        ActionRow(
                          icon: const Icon(Icons.campaign_rounded),
                          title: 'Ad privacy options',
                          detail: 'Change what you agreed to for advertising',
                          onTap: _openAdPrivacyOptions,
                        ),
                    ],
                  ),

                  // LAST, and in its own card.
                  //
                  // These two used to sit in the middle of the list at the same
                  // weight as Haptics, separated only by being red. Putting them
                  // at the bottom behind their own tint is the difference
                  // between a control you can reach and one you have to decide
                  // to reach.
                  const SectionHeader(label: 'Danger zone', danger: true),
                  Group(
                    danger: true,
                    children: [
                      ActionRow(
                        title: 'Reset progress',
                        detail: 'Erase every star and start from level 1',
                        onTap: _confirmReset,
                      ),
                      // Required by Play for any app that lets people create
                      // accounts, and it must be reachable IN the app rather
                      // than only on the web.
                      if (account.available)
                        ActionRow(
                          title: 'Delete account',
                          detail: 'Remove your account and everything with it',
                          onTap: _confirmDeleteAccount,
                          destructive: true,
                        ),
                    ],
                  ),

                  const SizedBox(height: 28),
                  Text(
                    [
                      'Pourfect ${_version.isEmpty ? '—' : _version}',
                      if (boards != null)
                        'made with $boards proven-solvable '
                            'boards',
                    ].join(' · '),
                    textAlign: TextAlign.center,
                    style: Toy.ui(12, color: Toy.inkMuted),
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
    if (adsRemoved) {
      return const ActionRow(
        icon: Icon(Icons.check_rounded),
        iconColor: Toy.mint,
        title: 'Ads removed — thank you',
        onTap: null,
      );
    }

    return Pressable(
      onPressed: onBuy,
      semanticLabel: 'Remove ads',
      depth: 1.5,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        child: Row(
          children: [
            const RowIcon(icon: Icon(Icons.close_rounded), color: Toy.yellow),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Remove ads',
                    style: Toy.ui(15, weight: FontWeight.w700),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    // Says what it does NOT do as well, so nobody buys it
                    // expecting hints to become free.
                    'No ads between levels. Hint videos stay.',
                    style: Toy.ui(
                      12,
                      weight: FontWeight.w500,
                      color: Toy.inkMuted,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            ToyBox(
              color: Toy.tomato,
              radius: Toy.rChip,
              strokeWidth: Toy.strokeThin,
              shadow: 2,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              child: Text(
                // Falls back to a dash rather than a hard-coded price: the
                // store is the authority on what this costs in each region,
                // and a wrong price shown next to a real charge is a refund.
                price ?? '—',
                style: Toy.numbers(13, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The player, at the top of their own settings: a lilac card.
///
/// Their photo appears here, inside the toy frame, when the provider supplied
/// one; otherwise the colored initial. This is the player's own screen, so the
/// picture is a courtesy rather than a disclosure — see CLAUDE.md on why it is
/// never on anything public.
class _PlayerCard extends StatelessWidget {
  final AccountState account;
  final int solved;
  final int stars;
  final VoidCallback onRename;

  const _PlayerCard({
    required this.account,
    required this.solved,
    required this.stars,
    required this.onRename,
  });

  @override
  Widget build(BuildContext context) {
    final name = account.handle ?? 'Naming you…';

    return Pressable(
      onPressed: onRename,
      semanticLabel: 'Your name',
      child: ToyBox(
        color: Toy.lilac,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            ToyAvatar(
              name: account.handle ?? '',
              photoUrl: account.photoUrl,
              size: 48,
              color: Toy.card,
              letterColor: Toy.lilac,
            ),
            const SizedBox(width: 12),
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
                      name,
                      style: Toy.display(20, height: 1.1),
                      maxLines: 1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    // States what the account actually buys, and nothing
                    // more. An anonymous account survives a crash; what it
                    // does not survive is a new phone.
                    account.signedIn
                        ? (account.email == null
                              ? 'Signed in'
                              : maskEmail(account.email!))
                        : 'Playing as a guest',
                    style: Toy.ui(12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _MiniStat(value: solved, label: 'SOLVED', color: Toy.card),
            const SizedBox(width: 6),
            _MiniStat(value: stars, label: 'STARS', color: Toy.yellow),
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final int value;
  final String label;
  final Color color;

  const _MiniStat({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => ToyBox(
    color: color,
    radius: Toy.rChip,
    strokeWidth: Toy.strokeThin,
    shadow: 0,
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('$value', style: Toy.numbers(14)),
        Text(label, style: Toy.ui(9, weight: FontWeight.w800, height: 1.1)),
      ],
    ),
  );
}

/// Every ball at board size, so the symbols toggle can be judged against the
/// thing it changes rather than by reading a sentence about it.
class _SymbolPreview extends StatelessWidget {
  final bool bold;

  const _SymbolPreview({required this.bold});

  @override
  Widget build(BuildContext context) {
    const perRow = 5;
    final count = kBallPalette.length;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Toy.cream,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Toy.ink, width: Toy.strokeThin),
      ),
      child: Column(
        children: [
          for (var start = 0; start < count; start += perRow) ...[
            if (start > 0) const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                for (var i = start; i < start + perRow; i++)
                  i < count
                      ? Ball(colorId: i, size: 34, boldGlyph: bold)
                      : const SizedBox(width: 34),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// The Smooth motion row's detail: what the screen is actually doing, so a
/// choice that cannot change anything on this phone says why instead of
/// looking broken.
String _smoothMotionDetail(DisplayRateState display, SmoothMotion mode) {
  final rate = display.rate;
  String hz(double v) =>
      v % 1 == 0 ? '${v.toInt()} Hz' : '${v.toStringAsFixed(1)} Hz';
  if (!rate.isKnown) {
    return 'Auto uses your screen\'s fastest rate if this phone keeps up';
  }
  if (!rate.canGoHigh) return 'This screen only runs at ${hz(rate.max)}';
  if (mode != SmoothMotion.standard && rate.lowPower) {
    return 'Battery Saver is holding it at ${hz(rate.current)}';
  }
  return switch (mode) {
    SmoothMotion.auto when display.autoStepdown =>
      'Running at ${hz(rate.current)} · this phone stuttered at '
          '${hz(rate.max)}',
    SmoothMotion.auto =>
      'Running at ${hz(rate.current)} · drops to 60 Hz if it stutters',
    // Some phones (Samsung's "High" motion smoothness) hold the panel at its
    // top rate whatever an app asks. Say so, rather than claim 60.
    SmoothMotion.standard when rate.current > 61 =>
      "Your phone's display setting keeps it at ${hz(rate.current)}",
    SmoothMotion.standard =>
      'Running at ${hz(rate.current)} · this screen can do ${hz(rate.max)}',
    SmoothMotion.max =>
      'Running at ${hz(rate.current)}, the fastest this screen goes',
  };
}

/// Whether the phone may notify at all, and the player's two switches.
///
/// The switches are the SERVER's (it decides what to send), so each one moves
/// only once the server has agreed. The permission row appears only while
/// the phone cannot show anything: it is the one fix the player has to make.
class _NotificationsGroup extends ConsumerWidget {
  final ValueChanged<String> onProblem;

  const _NotificationsGroup({required this.onProblem});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notificationPrefsProvider);
    final controller = ref.read(notificationPrefsProvider.notifier);
    final allowed = state.permission == PushPermission.granted;

    Future<void> save(Future<bool> Function() change) async {
      if (!await change()) {
        onProblem('Could not reach the server, so nothing changed.');
      }
    }

    return Group(
      children: [
        if (state.loaded && !allowed)
          ActionRow(
            icon: const Icon(Icons.notifications_off_rounded),
            iconColor: Toy.tomato,
            iconInk: Colors.white,
            title: 'Turn on notifications',
            detail: state.permission == PushPermission.denied
                ? "Off in your phone's settings. Tap to open them."
                : "Pourfect can't notify you yet",
            onTap: () async {
              final granted = await controller.turnOn();
              ref
                  .read(analyticsServiceProvider)
                  .log(
                    NotificationPermissionAnswered(
                      placement: 'settings',
                      granted: granted,
                    ),
                  );
            },
          ),
        ToggleRow(
          icon: const Icon(Icons.wb_twilight_rounded),
          iconColor: Toy.blue,
          iconInk: Colors.white,
          title: 'Daily Pour reminders',
          detail: 'Morning and evening, never more than two a day',
          value: state.prefs.reminders,
          onChanged: (on) => save(() => controller.setReminders(on)),
        ),
        ToggleRow(
          icon: const Icon(Icons.auto_awesome_rounded),
          iconColor: Toy.lilac,
          title: 'Game news',
          detail: 'New worlds and announcements',
          value: state.prefs.news,
          onChanged: (on) => save(() => controller.setNews(on)),
        ),
      ],
    );
  }
}

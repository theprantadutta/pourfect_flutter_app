/// Saving your progress to an account.
///
/// Reached from Settings and from nowhere else, deliberately. There is no
/// sign-in wall and there must never be one: first-launch friction is a
/// measurable D1 killer, and a ball-sort puzzle needs no identity to be
/// played. This screen exists for the player who has something worth keeping
/// and goes looking for a way to keep it.
///
/// **The copy is bounded by what is actually true.** Signing in makes progress
/// survive a new phone, because the uid is preserved by linking and the server
/// row travels with it. It does not make progress indestructible, and nothing
/// here says "safe" or "backed up forever".
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/api/identity.dart';
import '../../state/account_controller.dart';
import '../../state/play_history.dart';
import '../../state/progress_repository.dart';
import '../../state/providers.dart';
import '../../state/sync_controller.dart';
import '../theme/toy.dart';
import '../widgets/rename_dialog.dart';
import '../widgets/settings_rows.dart';
import '../widgets/toy_kit.dart';
import '../widgets/pour_loader.dart';

class AccountScreen extends ConsumerStatefulWidget {
  const AccountScreen({super.key, this.onOpenStatistics});

  /// Where the Statistics row goes. Null in the signed-out case and in tests,
  /// where the row is not drawn at all.
  final VoidCallback? onOpenStatistics;

  @override
  ConsumerState<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends ConsumerState<AccountScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  /// Register or sign in. One form, because they differ by one button and a
  /// validation rule, and two screens would double the copy for no gain.
  bool _registering = true;

  String? _problem;

  /// Shown once Google reports the credential already belongs to an account.
  ///
  /// Without it the ordinary returning player on a new phone reached a dead
  /// end: an explanation, and a Google button that could only retry the same
  /// link and fail the same way.

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  /// What a player is told, per outcome.
  ///
  /// Deliberately not Firebase's own message. Those are written for
  /// developers, occasionally name internal endpoints, and change between SDK
  /// versions — none of which belongs in front of somebody trying to save
  /// their puzzle progress.
  /// [solved] is how many levels this device has, because the honest wording
  /// of one of these outcomes depends entirely on it.
  static String? _explain(
    IdentityOutcome outcome,
    int solved,
  ) => switch (outcome) {
    IdentityOutcome.ok => null,
    // Backing out of the Google sheet is a decision, not a failure.
    IdentityOutcome.cancelled => null,

    // THE REINSTALL CASE IS THE COMMON ONE AND USED TO READ AS A THREAT.
    //
    // This said "signing into it will leave the progress on this device
    // behind" unconditionally. Somebody who has just reinstalled has NO
    // progress on this device — that is the whole reason they are here — so
    // the warning described a loss that could not happen and talked them out
    // of the one action that restores their account. Cloud progress you are
    // discouraged from claiming is not cloud progress.
    //
    // The confirmation dialog has always branched on this. The inline message
    // now agrees with it rather than contradicting it a step earlier.
    IdentityOutcome.credentialBelongsToAnotherAccount =>
      solved == 0
          ? 'You already have an account with that email. Sign in to it and '
                'this phone will load the stars saved to it.'
          : 'You already have an account with that email. This phone has '
                '$solved solved ${solved == 1 ? "level" : "levels"} that are '
                'not on it, and the two cannot be merged — signing in replaces '
                'them with whatever that account holds.',
    IdentityOutcome.emailAlreadyInUse =>
      'There is already an account with that email. Try signing in instead.',
    IdentityOutcome.emailMalformed =>
      'That does not look like an email address.',
    IdentityOutcome.passwordTooWeak =>
      'That password is too easy to guess. Try a longer one.',
    IdentityOutcome.wrongPassword => 'That email and password do not match.',
    IdentityOutcome.noSuchAccount => 'That email and password do not match.',
    IdentityOutcome.tooManyAttempts =>
      'Too many tries. Wait a few minutes and try again.',
    IdentityOutcome.needsRecentLogin => 'Please sign in again first.',
    // Points at the way in that IS switched on rather than at a retry, which
    // cannot work. A player never sees this in a correctly configured build.
    IdentityOutcome.methodNotEnabled =>
      'Email sign-in is not available right now. Try Continue with Google.',
    // Firebase took the sign-in; our own server did not answer. The account
    // is real and the next sync will pick it up, so this is not a failure to
    // undo — just one worth being honest about.
    IdentityOutcome.sessionUnavailable =>
      'Signed in, but your progress has not been saved to the server yet. '
          'It will sync when the connection is back.',
    IdentityOutcome.unavailable =>
      'Could not reach the server. Your progress is still safe on this device.',
  };

  Future<void> _google() async {
    setState(() => _problem = null);
    final result = await ref
        .read(accountProvider.notifier)
        .continueWithGoogle();

    if (result.outcome == IdentityOutcome.credentialBelongsToAnotherAccount) {
      // ASKED RIGHT HERE, because it is what almost everybody wants.
      //
      // This used to raise a button further down the screen and wait to be
      // found -- and on a phone, with the error text added, that button was
      // below the fold. So the common case, somebody reclaiming their own
      // account, was the one that required scrolling to discover.
      await _offerExistingAccount(
        confirmLabel: 'Use that account',
        onConfirmed: () =>
            ref.read(accountProvider.notifier).useExistingGoogleAccount(),
      );
      return;
    }
    _settle(result);
  }

  /// Offers the account the credential already belongs to, and joins it.
  ///
  /// One dialog for both ways in, because the QUESTION is the same -- you
  /// already have an account, do you want it -- even though the answer runs
  /// different code for Google and for email.
  ///
  /// It is a dialog rather than a button for a reason that only appeared on a
  /// real phone: with the explanation on screen, the button fell below the
  /// fold. The action almost every player wants was the one they had to go
  /// looking for. Asking outright costs one tap and hides nothing.
  ///
  /// Declining leaves the explanation on screen, so saying no does not leave
  /// somebody staring at a form that refused them without saying why.
  Future<void> _offerExistingAccount({
    required String confirmLabel,
    required Future<IdentityResult> Function() onConfirmed,
  }) async {
    final cleared = ref.read(progressProvider).length;

    final confirmed = await showRowConfirm(
      context: context,
      title: 'You already have an account',
      // THE REINSTALL CASE IS THE FIRST BRANCH ON PURPOSE. An empty device
      // has nothing to lose and everything to gain, and telling somebody
      // otherwise is how cloud progress goes unclaimed.
      body: cleared == 0
          ? 'This phone will load the stars already saved to it.'
          : 'This phone has $cleared solved '
                '${cleared == 1 ? "level" : "levels"} that are not on that '
                'account. They cannot be combined, so they will be '
                'replaced by whatever the account already holds.',
      cancelLabel: 'Not now',
      confirmLabel: confirmLabel,
    );

    if (!mounted) return;

    if (!confirmed) {
      setState(
        () => _problem = _explain(
          IdentityOutcome.credentialBelongsToAnotherAccount,
          ref.read(progressProvider).length,
        ),
      );
      return;
    }

    setState(() => _problem = null);
    _settle(await onConfirmed());
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _problem = null;
      // CLEARED HERE TOO, AND ITS ABSENCE IS WHAT PRODUCED THE CONFUSING
      // SCREEN.
      //
      // `_offerExistingAccount` is raised by the GOOGLE path and was only ever
      // lowered by the Google path. So a failed Google attempt left "Sign in
      // to that account" on screen, and it survived straight through an email
      // attempt underneath it — a button wired to `useExistingGoogleAccount`,
      // sitting under an email form, which would have re-opened the Google
    });

    final account = ref.read(accountProvider.notifier);
    final registering = _registering;
    final result = registering
        ? await account.createAccount(_email.text, _password.text)
        : await account.signIn(_email.text, _password.text);

    // THE REINSTALL PATH, MADE ONE TAP INSTEAD OF A PUZZLE.
    //
    // Somebody reinstalling types their email, presses Create account, and is
    // told the account already exists. That is the right answer to the wrong
    // question: they do not want a new account, they want the one they have.
    // Flipping the form to sign-in keeps their email in place, so the only
    // thing left to do is the password — rather than hunting for the "Already
    // have an account?" link while a red sentence implies they are about to
    // lose something.
    if (registering &&
        result.outcome == IdentityOutcome.credentialBelongsToAnotherAccount &&
        mounted) {
      // They have already typed the password for the account they want, so
      // offer exactly that and reuse it, rather than flipping the form and
      // making them enter it a second time.
      setState(() => _registering = false);
      await _offerExistingAccount(
        confirmLabel: 'Sign in',
        onConfirmed: () => account.signIn(_email.text, _password.text),
      );
      return;
    }

    _settle(result);
  }

  void _settle(IdentityResult result) {
    if (!mounted) return;

    if (result.isOk) {
      // SAID OUT LOUD. The screen used to close without a word, and testers
      // could not tell a sign-in that worked from one that had quietly given
      // up. Taken before the pop, while this context still has an ancestor.
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).maybePop();
      messenger
        ..clearSnackBars()
        ..showSnackBar(
          rowMessageBar('Signed in. Your stars now follow you to a new phone.'),
        );
      return;
    }
    setState(
      () => _problem = _explain(
        result.outcome,
        ref.read(progressProvider).length,
      ),
    );
  }

  Future<void> _resetPassword() async {
    final email = _email.text.trim();
    if (email.isEmpty) {
      setState(() => _problem = 'Enter your email first.');
      return;
    }

    await ref.read(accountProvider.notifier).sendPasswordReset(email);
    if (!mounted) return;

    // The same message whether or not that address has an account. Saying
    // otherwise would let a stranger test which emails are registered.
    setState(
      () => _problem =
          'If that email has an account, a reset link is on its way.',
    );
  }

  /// What the crest opens once there is an account behind it.
  ///
  /// **The first version of this was three sentences and nothing else**, and
  /// the honest verdict on it was "what even is this". It was built to avoid
  /// duplicating Settings and ended up avoiding content instead — a profile
  /// screen that told you nothing about yourself.
  ///
  /// The thing a player actually wants here is the answer to "what is attached
  /// to this account", so that is what it leads with: the Player Card, whose
  /// four figures say what would travel to a new phone. The controls under it
  /// are the identity ones only; the deep numbers live in Statistics and the
  /// settings live in Settings, and this links to both rather than reprinting
  /// them.
  Widget _signedIn(BuildContext context, AccountState account) {
    final progress = ref.watch(progressProvider);
    final history = ref.watch(playHistoryProvider);
    final stars = ref.read(progressProvider.notifier).totalStars;
    final streak = ref.read(playHistoryProvider.notifier).currentStreak();
    final rank = switch (ref.watch(campaignRankProvider)) {
      AsyncData(:final value?) => '#$value',
      _ => '—',
    };
    final sync = ref.watch(syncControllerProvider);

    return _Screen(
      title: 'Your account',
      children: [
        _PlayerCard(
          account: account,
          since: _pouringSince(progress, history),
          solved: progress.length,
          stars: stars,
          streak: streak > 0 ? '${streak}d' : '—',
          rank: rank,
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            // The honest claim and the whole of it — an account moves this
            // to a new phone, and that is all it promises.
            'This card goes with your account, so a new phone starts right '
            'where you left off.',
            style: Toy.ui(13, weight: FontWeight.w500, color: Toy.inkMuted),
          ),
        ),

        const SectionHeader(label: 'Your name'),
        Group(
          children: [
            // Says what tapping DOES, not the handle again — that is already
            // the largest thing on the screen. Same reasoning as the Settings
            // row, and the same words.
            ActionRow(
              icon: const Icon(Icons.edit_rounded),
              iconColor: Toy.mint,
              title: 'Change your name',
              detail: 'How you appear on the boards',
              onTap: _rename,
            ),
            ToggleRow(
              icon: const Icon(Icons.contrast_rounded),
              iconColor: kRowMoss,
              title: 'Show me on leaderboards',
              detail: 'Off hides your name and rank. Stars still count.',
              value: account.showOnLeaderboards,
              onChanged: _setVisibility,
            ),
          ],
        ),

        if (widget.onOpenStatistics != null ||
            sync.status != SyncStatus.off) ...[
          const SectionHeader(label: 'Your play'),
          Group(
            children: [
              // WHERE THE STATISTICS SCREEN IS REACHED FROM.
              //
              // It was only ever reachable by tapping the stat row on the home
              // screen, which is drawn as plain text and reads as a caption
              // rather than a control — so a whole screen of content went
              // unfound. A profile is where somebody looks for their numbers.
              if (widget.onOpenStatistics != null)
                ActionRow(
                  icon: const BarsGlyph(),
                  iconColor: Toy.pink,
                  title: 'Statistics',
                  // ActionRow gives a detail ONE line and ellipsises the rest
                  // — that is the Settings rule, so the copy fits the row
                  // rather than the row growing for it.
                  detail: 'Your times, activity and every level',
                  onTap: widget.onOpenStatistics!,
                ),
              if (sync.status != SyncStatus.off) _SyncRow(sync: sync),
            ],
          ),
        ],

        const SectionHeader(label: 'Session', danger: true),
        _SignOutCard(onPressed: _confirmSignOut),
        const SizedBox(height: 24),
        Text(
          'To delete your account, go to Settings → Danger zone.',
          textAlign: TextAlign.center,
          style: Toy.ui(12, weight: FontWeight.w500, color: Toy.inkMuted),
        ),
      ],
    );
  }

  /// The month this player's history starts, from what this device knows.
  ///
  /// The earlier of the first day played and the first level cleared. Null
  /// when neither is known, and the card then simply leaves the line out —
  /// there is no account-creation date on the session to fall back to.
  static DateTime? _pouringSince(
    Map<int, LevelProgress> progress,
    Map<String, DayRecord> history,
  ) {
    DateTime? earliest;
    void consider(DateTime? d) {
      if (d != null && (earliest == null || d.isBefore(earliest!))) {
        earliest = d;
      }
    }

    for (final key in history.keys) {
      consider(parseDayKey(key));
    }
    for (final p in progress.values) {
      if (p.firstClearedAtMillis > 0) {
        consider(
          DateTime.fromMillisecondsSinceEpoch(p.firstClearedAtMillis).toLocal(),
        );
      }
    }
    return earliest;
  }

  /// Renames through the SAME dialog Settings uses.
  Future<void> _rename() async {
    final chosen = await showRenameDialog(
      context,
      ref.read(accountProvider).handle ?? '',
    );
    if (chosen == null || !mounted) return;

    final problem = await ref
        .read(accountProvider.notifier)
        .renameHandle(chosen);
    if (problem != null && mounted) showRowMessage(context, problem);
  }

  Future<void> _setVisibility(bool visible) async {
    final ok = await ref
        .read(accountProvider.notifier)
        .setLeaderboardVisibility(visible);
    // The switch has NOT moved, because the server never agreed. Saying so is
    // the point: a control that looks like it worked on a request that did not
    // tells somebody they are hidden while they are still listed.
    if (!ok && mounted) {
      showRowMessage(
        context,
        'Could not reach the server, so nothing changed.',
      );
    }
  }

  Future<void> _confirmSignOut() async {
    final confirmed = await showRowConfirm(
      context: context,
      title: 'Sign out?',
      body:
          'Your progress stays on this phone. You can sign back in any time '
          'to pick it up somewhere else.',
      cancelLabel: 'Stay signed in',
      confirmLabel: 'Sign out',
    );

    if (!confirmed || !mounted) return;
    await ref.read(accountProvider.notifier).signOut();
  }

  @override
  Widget build(BuildContext context) {
    final account = ref.watch(accountProvider);

    // ALREADY SIGNED IN IS A STATE THIS SCREEN HAS TO HAVE.
    //
    // It did not, and the crest on the home screen opens this screen
    // unconditionally — so a signed-in player tapped their own avatar and was
    // asked to sign in again, while Settings two taps away correctly showed
    // their email. Settings only ever got it right because ITS entry point is
    // conditional: the "Save your progress" row is hidden once you are signed
    // in. The crest had no such guard, so the bug was in the routing as much
    // as in this file.
    if (account.signedIn) return _signedIn(context, account);

    return _Screen(
      title: 'Save your progress',
      children: [
        ToyBox(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
          radius: Toy.rHero,
          shadow: 5,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                // Precisely what it does. Not "your progress is safe" — an
                // account moves it to a new phone, and that is the whole claim.
                'Your stars, streak and leaderboard name move with your '
                'account, so a new phone starts where you left off.',
                style: Toy.ui(
                  14,
                  weight: FontWeight.w500,
                  color: Toy.inkMuted,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 16),

              ToyButton.secondary(
                label: 'Continue with Google',
                icon: const _GoogleMark(),
                onPressed: account.busy ? null : _google,
              ),

              const SizedBox(height: 16),
              Row(
                children: [
                  const Expanded(child: _Rule()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text('OR', style: Toy.caps()),
                  ),
                  const Expanded(child: _Rule()),
                ],
              ),
              const SizedBox(height: 16),

              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _Field(
                      controller: _email,
                      label: 'Email',
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      validator: (value) {
                        final text = (value ?? '').trim();
                        if (text.isEmpty) return 'Enter your email.';
                        // Deliberately loose. Firebase is the real arbiter, and
                        // a strict pattern here rejects valid addresses.
                        if (!text.contains('@') || !text.contains('.')) {
                          return 'That does not look like an email address.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    _Field(
                      controller: _password,
                      label: 'Password',
                      obscure: true,
                      helper: _registering ? 'At least 8 characters' : null,
                      autofillHints: [
                        _registering
                            ? AutofillHints.newPassword
                            : AutofillHints.password,
                      ],
                      validator: (value) {
                        final text = value ?? '';
                        if (text.isEmpty) return 'Enter a password.';
                        // Only enforced when CREATING one. Applying it at
                        // sign-in would lock out anybody whose existing
                        // password is shorter than a rule invented later.
                        if (_registering && text.length < 8) {
                          return 'At least 8 characters.';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),

              // ORDER MATTERS, AND IT WAS BACKWARDS.
              //
              // The explanation comes first and the action that answers it
              // comes directly underneath, so the two read as one thing.
              if (_problem != null) ...[
                const SizedBox(height: 12),
                Text(
                  _problem!,
                  style: Toy.ui(
                    13,
                    weight: FontWeight.w600,
                    color: kDestructive,
                    height: 1.4,
                  ),
                ),
              ],

              const SizedBox(height: 16),
              ToyButton(
                label: _registering ? 'Create account' : 'Sign in',
                height: 56,
                fontSize: 22,
                icon: account.busy ? const BounceDots() : null,
                onPressed: account.busy ? null : _submit,
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),
        _TextLink(
          label: _registering
              ? 'Already have an account? Sign in'
              : 'Need an account? Create one',
          semanticLabel: _registering
              ? 'Sign in instead'
              : 'Create an account instead',
          color: Toy.tomatoDark,
          onPressed: () => setState(() {
            _registering = !_registering;
            _problem = null;
          }),
        ),
        if (!_registering)
          _TextLink(
            label: 'Forgot your password?',
            semanticLabel: 'Reset your password',
            color: Toy.inkMuted,
            onPressed: _resetPassword,
          ),
      ],
    );
  }
}

/// The ground both states of this screen stand on: header, then a scrolling
/// column with room under it for the last card's hard shadow.
class _Screen extends StatelessWidget {
  const _Screen({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    // A Scaffold underneath the toy ground: it pads for the keyboard under the
    // sign-in form, and it is what the row messages are shown on.
    return Scaffold(
      backgroundColor: Toy.cream,
      body: ToyScaffold(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
        safeBottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ToyHeader(title: title),
            const SizedBox(height: 12),
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  0,
                  2,
                  0,
                  24 + MediaQuery.paddingOf(context).bottom,
                ),
                children: children,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The yellow Player Card: who you are and what travels with the account.
///
/// Tilted, and carries the PLAYER CARD tag — the two tilted elements this
/// screen is allowed. The photo appears here, inside the toy frame, when the
/// provider supplied one: this is the player's own card, never a public one.
class _PlayerCard extends StatelessWidget {
  const _PlayerCard({
    required this.account,
    required this.since,
    required this.solved,
    required this.stars,
    required this.streak,
    required this.rank,
  });

  final AccountState account;
  final DateTime? since;
  final int solved;
  final int stars;
  final String streak;
  final String rank;

  static const _months = [
    'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', //
    'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC',
  ];

  @override
  Widget build(BuildContext context) {
    final handle = account.handle;
    final since = this.since;

    final card = Container(
      padding: const EdgeInsets.all(18),
      decoration: Toy.box(
        fill: Toy.yellow,
        radius: Toy.rHero,
        shadow: 6,
        strokeWidth: 3,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: Toy.hard(4),
                ),
                child: ToyAvatar(
                  name: handle ?? '',
                  photoUrl: account.photoUrl,
                  size: 72,
                  color: Toy.lilac,
                  strokeWidth: 3,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Shrinks rather than crops, like the Settings card: half
                    // a name with an ellipsis on it is worse than a small
                    // whole one.
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        handle ?? 'Naming you…',
                        style: Toy.display(30),
                        maxLines: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      account.email == null
                          ? 'Signed in'
                          : maskEmail(account.email!),
                      style: Toy.ui(13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (since != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'POURING SINCE ${_months[since.month - 1]} '
                        '${since.year}',
                        style: Toy.ui(
                          11,
                          weight: FontWeight.w800,
                          letterSpacing: 1,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _StatStrip(solved: solved, stars: stars, streak: streak, rank: rank),
        ],
      ),
    );

    return Padding(
      // Room for the tag above and the tilt at the corners.
      padding: const EdgeInsets.fromLTRB(4, 14, 4, 6),
      child: Transform.rotate(
        angle: -1.5 * math.pi / 180,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            card,
            Positioned(
              top: -13,
              right: 18,
              child: Transform.rotate(
                angle: 3 * math.pi / 180,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Toy.ink,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'PLAYER CARD',
                    style: Toy.ui(
                      10,
                      weight: FontWeight.w800,
                      color: Toy.yellow,
                      letterSpacing: 1.5,
                    ),
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

/// Solved, stars, streak, rank — four cells, rank in tomato.
class _StatStrip extends StatelessWidget {
  const _StatStrip({
    required this.solved,
    required this.stars,
    required this.streak,
    required this.rank,
  });

  final int solved;
  final int stars;
  final String streak;
  final String rank;

  @override
  Widget build(BuildContext context) {
    Widget cell(String value, String label, {bool hot = false}) => Expanded(
      child: Container(
        color: hot ? Toy.tomato : null,
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: Toy.numbers(19, color: hot ? Colors.white : Toy.ink),
                maxLines: 1,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              label,
              style: Toy.ui(
                10,
                weight: FontWeight.w800,
                color: hot ? Colors.white : Toy.inkMuted,
              ),
            ),
          ],
        ),
      ),
    );
    const rule = SizedBox(width: 2, child: ColoredBox(color: Toy.ink));

    return Container(
      decoration: BoxDecoration(
        color: Toy.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Toy.ink, width: Toy.stroke),
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            cell('$solved', 'SOLVED'),
            rule,
            cell('$stars★', 'STARS'),
            rule,
            cell(streak, 'STREAK'),
            rule,
            cell(rank, 'RANK', hot: true),
          ],
        ),
      ),
    );
  }
}

/// Where this account's progress stands with the server. Read-only.
class _SyncRow extends StatelessWidget {
  const _SyncRow({required this.sync});

  final SyncState sync;

  @override
  Widget build(BuildContext context) {
    final (title, detail) = switch (sync.status) {
      SyncStatus.syncing => ('Syncing…', 'Saving progress to your account'),
      SyncStatus.unreachable => (
        'Waiting to sync',
        'Saves when you are back online',
      ),
      _ when sync.pending > 0 => (
        'Waiting to sync',
        'Your latest levels go up next',
      ),
      _ => (_synced(sync.lastSucceededAt), 'Progress saved to your account'),
    };
    return ActionRow(
      icon: const Icon(Icons.swap_vert_rounded),
      iconColor: Toy.blue,
      iconInk: Colors.white,
      title: title,
      detail: detail,
      onTap: null,
    );
  }

  static String _synced(DateTime? at) {
    if (at == null) return 'Synced';
    final ago = DateTime.now().difference(at);
    if (ago.inMinutes < 1) return 'Synced just now';
    if (ago.inHours < 1) return 'Synced ${ago.inMinutes}m ago';
    if (ago.inDays < 1) return 'Synced ${ago.inHours}h ago';
    return 'Synced ${ago.inDays}d ago';
  }
}

/// Sign out: a card of its own, on a tomato shadow.
class _SignOutCard extends StatelessWidget {
  const _SignOutCard({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Pressable(
      onPressed: onPressed,
      semanticLabel: 'Sign out',
      child: ToyBox(
        radius: Toy.rControl,
        shadowColor: Toy.tomato,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        child: Row(
          children: [
            const RowIcon(
              icon: Icon(Icons.power_settings_new_rounded),
              color: Toy.tomato,
              ink: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sign out',
                    style: Toy.ui(
                      15,
                      weight: FontWeight.w800,
                      color: kDestructive,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    // States what it does NOT do, because that is the fear.
                    'Your progress stays on this phone',
                    style: Toy.ui(
                      12,
                      weight: FontWeight.w500,
                      color: Toy.inkMuted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _Field extends StatefulWidget {
  const _Field({
    required this.controller,
    required this.label,
    required this.validator,
    this.obscure = false,
    this.helper,
    this.keyboardType,
    this.autofillHints,
  });

  final TextEditingController controller;
  final String label;
  final String? Function(String?) validator;

  /// A secret field: hidden by default, with an eye to show it.
  final bool obscure;

  /// The rule the field will be held to, shown BEFORE it is broken.
  final String? helper;
  final TextInputType? keyboardType;
  final List<String>? autofillHints;

  @override
  State<_Field> createState() => _FieldState();
}

class _FieldState extends State<_Field> {
  /// Whether a secret field is currently hidden.
  ///
  /// Testers reported typing a password blind with no way to check it — on a
  /// phone keyboard, a typo is the usual reason a sign-in fails.
  late bool _hidden = widget.obscure;

  @override
  Widget build(BuildContext context) {
    OutlineInputBorder border(Color color) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: color, width: Toy.stroke),
    );

    return TextFormField(
      controller: widget.controller,
      obscureText: _hidden,
      keyboardType: widget.keyboardType,
      autofillHints: widget.autofillHints,
      autocorrect: false,
      // Keyed on the FIELD, not on whether it is hidden right now: showing a
      // password must not start feeding it to the keyboard's suggestions.
      enableSuggestions: !widget.obscure,
      style: Toy.ui(16),
      cursorColor: Toy.tomato,
      validator: widget.validator,
      decoration: InputDecoration(
        labelText: widget.label,
        labelStyle: Toy.ui(14, weight: FontWeight.w600, color: Toy.inkMuted),
        floatingLabelStyle: Toy.ui(14, weight: FontWeight.w700),
        helperText: widget.helper,
        helperStyle: Toy.ui(12, color: Toy.inkMuted),
        suffixIcon: !widget.obscure
            ? null
            : Pressable(
                onPressed: () => setState(() => _hidden = !_hidden),
                semanticLabel: _hidden ? 'Show password' : 'Hide password',
                child: Icon(
                  _hidden
                      ? Icons.visibility_rounded
                      : Icons.visibility_off_rounded,
                  color: Toy.ink,
                ),
              ),
        errorStyle: Toy.ui(12, color: kDestructive),
        filled: true,
        fillColor: Toy.cream,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        enabledBorder: border(Toy.ink),
        focusedBorder: border(Toy.tomato),
        errorBorder: border(kDestructive),
        focusedErrorBorder: border(kDestructive),
      ),
    );
  }
}

/// A line of text that is a control: the register / sign-in switch.
class _TextLink extends StatelessWidget {
  const _TextLink({
    required this.label,
    required this.semanticLabel,
    required this.color,
    required this.onPressed,
  });

  final String label;
  final String semanticLabel;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Pressable(
    onPressed: onPressed,
    semanticLabel: semanticLabel,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: Toy.ui(14, weight: FontWeight.w700, color: color),
      ),
    ),
  );
}

class _Rule extends StatelessWidget {
  const _Rule();

  @override
  Widget build(BuildContext context) =>
      Container(height: 1.5, color: Toy.divider);
}

/// A plain "G" in a small ink ring. Not Google's logo — the brand mark has
/// usage rules and does not belong drawn by hand in a toy stroke.
class _GoogleMark extends StatelessWidget {
  const _GoogleMark();

  @override
  Widget build(BuildContext context) => Container(
    width: 24,
    height: 24,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: Toy.cream,
      shape: BoxShape.circle,
      border: Border.all(color: Toy.ink, width: Toy.strokeThin),
    ),
    child: Text('G', style: Toy.ui(13, weight: FontWeight.w800, height: 1)),
  );
}

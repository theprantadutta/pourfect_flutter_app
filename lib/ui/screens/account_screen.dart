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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/api/identity.dart';
import '../../state/account_controller.dart';
import '../../state/progress_repository.dart';
import '../../state/providers.dart';
import '../theme/tokens.dart';
import '../theme/typography.dart';
import '../../state/play_history.dart';
import '../widgets/rename_dialog.dart';
import '../widgets/settings_rows.dart';
import '../widgets/player_crest.dart';
import '../widgets/pressable.dart';

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
  static String? _explain(IdentityOutcome outcome, int solved) => switch (outcome) {
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
    IdentityOutcome.credentialBelongsToAnotherAccount => solved == 0
        ? 'You already have an account with that email. Sign in to it and '
              'this phone will load the stars saved to it.'
        : 'You already have an account with that email. This phone has '
              '$solved solved ${solved == 1 ? "level" : "levels"} that are '
              'not on it, and the two cannot be merged — signing in replaces '
              'them with whatever that account holds.',
    IdentityOutcome.emailAlreadyInUse =>
      'There is already an account with that email. Try signing in instead.',
    IdentityOutcome.emailMalformed => 'That does not look like an email address.',
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
    final result = await ref.read(accountProvider.notifier).continueWithGoogle();

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
        title: Text('You already have an account', style: titleStyle(tokens)),
        content: Text(
          // THE REINSTALL CASE IS THE FIRST BRANCH ON PURPOSE. An empty device
          // has nothing to lose and everything to gain, and telling somebody
          // otherwise is how cloud progress goes unclaimed.
          cleared == 0
              ? 'This phone will load the stars already saved to it.'
              : 'This phone has $cleared solved '
                    '${cleared == 1 ? "level" : "levels"} that are not on that '
                    'account. They cannot be combined, so they will be '
                    'replaced by whatever the account already holds.',
          style: bodyStyle(tokens),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Not now',
              style: actionStyle(tokens, color: tokens.textMuted),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(confirmLabel, style: actionStyle(tokens)),
          ),
        ],
      ),
    );

    if (!mounted) return;

    if (confirmed != true) {
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
      Navigator.of(context).maybePop();
      return;
    }
    setState(
      () => _problem = _explain(result.outcome, ref.read(progressProvider).length),
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
      () => _problem = 'If that email has an account, a reset link is on its way.',
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
  /// to this account", so that is what it leads with: the four figures that
  /// say what would travel to a new phone. The controls under them are the
  /// identity ones only; the deep numbers live in Statistics and the settings
  /// live in Settings, and this links to both rather than reprinting them.
  Widget _signedIn(
    BuildContext context,
    PourfectTokens tokens,
    AccountState account,
  ) {
    final progress = ref.watch(progressProvider);
    final stars = ref.read(progressProvider.notifier).totalStars;
    final streak = ref.read(playHistoryProvider.notifier).currentStreak();
    final rank = switch (ref.watch(campaignRankProvider)) {
      AsyncData(:final value?) => '#$value',
      _ => '—',
    };

    return Scaffold(
      backgroundColor: tokens.surface,
      appBar: AppBar(
        backgroundColor: tokens.surface,
        elevation: 0,
        title: Text('Your account', style: titleStyle(tokens)),
        iconTheme: IconThemeData(color: tokens.textPrimary),
      ),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.all(tokens.space4),
          children: [
            Row(
              children: [
                PlayerCrest(
                  seed: account.userId,
                  signedIn: true,
                  size: 56,
                  photoUrl: account.photoUrl,
                ),
                SizedBox(width: tokens.space3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Shrinks rather than crops, like the Settings header:
                      // half a name with an ellipsis on it is worse than a
                      // small whole one.
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          account.handle ?? 'Naming you…',
                          style: titleStyle(tokens).copyWith(fontSize: 22),
                          maxLines: 1,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        account.email ?? 'Signed in',
                        style: bodyStyle(tokens).copyWith(fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            SizedBox(height: tokens.space5),
            SectionHeader(
              icon: Icons.inventory_2_rounded,
              label: 'What travels with you',
            ),
            Group(children: [
              GroupInset(
                child: Padding(
                  padding: EdgeInsets.only(top: tokens.space3),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _Stat(value: '${progress.length}', label: 'SOLVED'),
                      _Stat(
                        value: '$stars',
                        label: 'STARS',
                        color: tokens.accentWarm,
                      ),
                      _Stat(
                        value: streak > 0 ? '${streak}d' : '—',
                        label: 'STREAK',
                        color: tokens.accent,
                      ),
                      _Stat(value: rank, label: 'RANK', color: tokens.accent),
                    ],
                  ),
                ),
              ),
            ]),
            SizedBox(height: tokens.space2),
            Text(
              // The honest claim and the whole of it — an account moves this
              // to a new phone, and that is all it promises.
              'These move with your account, so a new phone starts where you '
              'left off.',
              style: bodyStyle(tokens).copyWith(fontSize: 12),
            ),

            SizedBox(height: tokens.space5),
            SectionHeader(
              icon: Icons.badge_rounded,
              label: 'Your name',
            ),
            Group(children: [
              // Says what tapping DOES, not the handle again — that is
              // already the largest thing on the screen, six rows up. Same
              // reasoning as the Settings row, and the same words.
              ActionRow(
                icon: Icons.edit_rounded,
                title: 'Change your name',
                detail: 'How you appear on the boards.',
                onTap: _rename,
              ),
              ToggleRow(
                icon: Icons.public_rounded,
                title: 'Show me on leaderboards',
                detail: 'Off hides your name and rank. Stars still count.',
                value: account.showOnLeaderboards,
                onChanged: _setVisibility,
                last: true,
              ),
            ]),

            if (widget.onOpenStatistics != null) ...[
            SizedBox(height: tokens.space5),
            SectionHeader(
              icon: Icons.insights_rounded,
              label: 'Your play',
            ),
            Group(children: [
              // WHERE THE STATISTICS SCREEN IS REACHED FROM.
              //
              // It was only ever reachable by tapping the stat row on the home
              // screen, which is drawn as plain text and reads as a caption
              // rather than a control — so a whole screen of content went
              // unfound. A profile is where somebody looks for their numbers.
              ActionRow(
                icon: Icons.bar_chart_rounded,
                title: 'Statistics',
                // ActionRow gives a detail ONE line and ellipsises the rest —
                // that is the Settings rule, so the copy fits the row rather
                // than the row growing for it. The first draft ran to 47
                // characters and clipped at "and your a…", which reads as a
                // bug rather than as restraint.
                detail: 'Your times, activity and every level.',
                onTap: widget.onOpenStatistics!,
                last: true,
              ),
            ]),
            ],

            SizedBox(height: tokens.space5),
            SectionHeader(
              icon: Icons.logout_rounded,
              label: 'Session',
              danger: true,
            ),
            Group(
              danger: true,
              children: [
                ActionRow(
                  icon: Icons.logout_rounded,
                  title: 'Sign out',
                  // States what it does NOT do, because that is the fear.
                  detail: 'Your progress stays on this phone.',
                  onTap: _confirmSignOut,
                  destructive: true,
                  last: true,
                ),
              ],
            ),
            SizedBox(height: tokens.space3),
            Text(
              'Deleting your account is in Settings, with the other '
              'irreversible things.',
              style: bodyStyle(tokens).copyWith(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  /// Renames through the SAME dialog Settings uses.
  Future<void> _rename() async {
    final chosen = await showRenameDialog(
      context,
      ref.read(accountProvider).handle ?? '',
    );
    if (chosen == null || !mounted) return;

    final problem = await ref.read(accountProvider.notifier).renameHandle(chosen);
    if (problem != null && mounted) _toast(problem);
  }

  Future<void> _setVisibility(bool visible) async {
    final ok = await ref
        .read(accountProvider.notifier)
        .setLeaderboardVisibility(visible);
    // The switch has NOT moved, because the server never agreed. Saying so is
    // the point: a control that looks like it worked on a request that did not
    // tells somebody they are hidden while they are still listed.
    if (!ok && mounted) _toast('Could not reach the server, so nothing changed.');
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

    if (confirmed != true || !mounted) return;
    await ref.read(accountProvider.notifier).signOut();
  }

  void _toast(String message) {
    final tokens = PourfectTokens.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: bodyStyle(tokens)),
        backgroundColor: tokens.surfaceRaised,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = PourfectTokens.of(context);
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
    if (account.signedIn) return _signedIn(context, tokens, account);

    return Scaffold(
      backgroundColor: tokens.surface,
      appBar: AppBar(
        backgroundColor: tokens.surface,
        elevation: 0,
        title: Text('Save your progress', style: titleStyle(tokens)),
        iconTheme: IconThemeData(color: tokens.textPrimary),
      ),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.all(tokens.space4),
          children: [
            Text(
              // Precisely what it does. Not "your progress is safe" — an
              // account moves it to a new phone, and that is the whole claim.
              'Your stars, streak and leaderboard name move with your account, '
              'so a new phone starts where you left off.',
              style: bodyStyle(tokens),
            ),
            SizedBox(height: tokens.space5),

            _GoogleButton(onPressed: account.busy ? null : _google),

            SizedBox(height: tokens.space4),
            Row(
              children: [
                Expanded(child: Divider(color: tokens.hairline)),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: tokens.space3),
                  child: Text('or', style: labelStyle(tokens)),
                ),
                Expanded(child: Divider(color: tokens.hairline)),
              ],
            ),
            SizedBox(height: tokens.space4),

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
                  SizedBox(height: tokens.space3),
                  _Field(
                    controller: _password,
                    label: 'Password',
                    obscure: true,
                    autofillHints: [
                      _registering
                          ? AutofillHints.newPassword
                          : AutofillHints.password,
                    ],
                    validator: (value) {
                      final text = value ?? '';
                      if (text.isEmpty) return 'Enter a password.';
                      // Only enforced when CREATING one. Applying it at
                      // sign-in would lock out anybody whose existing password
                      // is shorter than a rule invented later.
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
            // The explanation comes first and the action that answers it comes
            // directly underneath, so the two read as one thing. Previously the
            // button sat ABOVE the sentence explaining what it would cost —
            // which is the opposite of what `_google` documents, and left two
            // primary buttons stacked with the reasoning stranded between them.
            if (_problem != null) ...[
              SizedBox(height: tokens.space3),
              Text(
                _problem!,
                style: bodyStyle(tokens).copyWith(
                  color: const Color(0xFFC85F72),
                ),
              ),
            ],


            SizedBox(height: tokens.space4),
            _PrimaryButton(
              label: _registering ? 'Create account' : 'Sign in',
              busy: account.busy,
              onPressed: account.busy ? null : _submit,
            ),

            SizedBox(height: tokens.space3),
            Pressable(
              onPressed: () => setState(() {
                _registering = !_registering;
                _problem = null;
              }),
              semanticLabel: _registering
                  ? 'Sign in instead'
                  : 'Create an account instead',
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: tokens.space2),
                child: Text(
                  _registering
                      ? 'Already have an account? Sign in'
                      : 'Need an account? Create one',
                  textAlign: TextAlign.center,
                  style: actionStyle(tokens, color: tokens.accent),
                ),
              ),
            ),

            if (!_registering)
              Pressable(
                onPressed: _resetPassword,
                semanticLabel: 'Reset your password',
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: tokens.space2),
                  child: Text(
                    'Forgot your password?',
                    textAlign: TextAlign.center,
                    style: actionStyle(tokens, color: tokens.textMuted),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.label,
    required this.validator,
    this.obscure = false,
    this.keyboardType,
    this.autofillHints,
  });

  final TextEditingController controller;
  final String label;
  final String? Function(String?) validator;
  final bool obscure;
  final TextInputType? keyboardType;
  final List<String>? autofillHints;

  @override
  Widget build(BuildContext context) {
    final tokens = PourfectTokens.of(context);

    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      autofillHints: autofillHints,
      autocorrect: false,
      enableSuggestions: !obscure,
      style: bodyStyle(tokens).copyWith(color: tokens.textPrimary),
      cursorColor: tokens.accent,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: labelStyle(tokens),
        filled: true,
        fillColor: tokens.surfaceRaised,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(tokens.panelRadius),
          borderSide: BorderSide(color: tokens.hairline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(tokens.panelRadius),
          borderSide: BorderSide(color: tokens.accent),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(tokens.panelRadius),
          borderSide: const BorderSide(color: Color(0xFFC85F72)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(tokens.panelRadius),
          borderSide: const BorderSide(color: Color(0xFFC85F72)),
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    required this.busy,
    required this.onPressed,
  });

  final String label;
  final bool busy;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final tokens = PourfectTokens.of(context);

    return Pressable(
      onPressed: onPressed,
      semanticLabel: label,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: tokens.space3),
        decoration: BoxDecoration(
          color: onPressed == null ? tokens.surfaceRaised : tokens.accent,
          borderRadius: BorderRadius.circular(tokens.panelRadius),
        ),
        alignment: Alignment.center,
        child: busy
            ? SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: tokens.textPrimary,
                ),
              )
            : Text(
                label,
                style: actionStyle(tokens, color: tokens.surface),
              ),
      ),
    );
  }
}

class _GoogleButton extends StatelessWidget {
  const _GoogleButton({required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final tokens = PourfectTokens.of(context);

    return Pressable(
      onPressed: onPressed,
      semanticLabel: 'Continue with Google',
      child: Container(
        padding: EdgeInsets.symmetric(vertical: tokens.space3),
        decoration: BoxDecoration(
          color: tokens.surfaceRaised,
          borderRadius: BorderRadius.circular(tokens.panelRadius),
          border: Border.all(color: tokens.hairlineStrong),
        ),
        alignment: Alignment.center,
        child: Text(
          'Continue with Google',
          style: actionStyle(tokens, color: tokens.textPrimary),
        ),
      ),
    );
  }
}

/// One number and its unit, for the row at the top of the account screen.
class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label, this.color});

  final String value;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final tokens = PourfectTokens.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: numericStyle(tokens, size: 20).copyWith(
            color: color ?? tokens.textPrimary,
          ),
        ),
        SizedBox(height: 2),
        Text(label, style: labelStyle(tokens).copyWith(fontSize: 9)),
      ],
    );
  }
}

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
import '../theme/tokens.dart';
import '../theme/typography.dart';
import '../widgets/pressable.dart';

class AccountScreen extends ConsumerStatefulWidget {
  const AccountScreen({super.key});

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
  static String? _explain(IdentityOutcome outcome) => switch (outcome) {
    IdentityOutcome.ok => null,
    // Backing out of the Google sheet is a decision, not a failure.
    IdentityOutcome.cancelled => null,
    IdentityOutcome.credentialBelongsToAnotherAccount =>
      'That account already exists. Signing into it will leave the progress '
          'on this device behind — it cannot be merged.',
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
    IdentityOutcome.unavailable =>
      'Could not reach the server. Your progress is still safe on this device.',
  };

  Future<void> _google() async {
    setState(() => _problem = null);
    final result = await ref.read(accountProvider.notifier).continueWithGoogle();
    _settle(result);
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _problem = null);

    final account = ref.read(accountProvider.notifier);
    final result = _registering
        ? await account.createAccount(_email.text, _password.text)
        : await account.signIn(_email.text, _password.text);

    _settle(result);
  }

  void _settle(IdentityResult result) {
    if (!mounted) return;

    if (result.isOk) {
      Navigator.of(context).maybePop();
      return;
    }
    setState(() => _problem = _explain(result.outcome));
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

  @override
  Widget build(BuildContext context) {
    final tokens = PourfectTokens.of(context);
    final account = ref.watch(accountProvider);

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

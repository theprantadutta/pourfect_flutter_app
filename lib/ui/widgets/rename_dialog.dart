/// The box for changing your leaderboard name.
///
/// Shared by Settings and the account screen the crest opens. Both surfaces
/// legitimately offer a rename, and one dialog is the difference between them
/// agreeing by construction and agreeing because somebody remembered to edit
/// two files.
library;

import 'package:flutter/material.dart';

import '../../services/api/leaderboard_api.dart';
import '../theme/tokens.dart';
import '../theme/typography.dart';

/// Opens the rename box and returns the chosen name, or null if cancelled.
Future<String?> showRenameDialog(BuildContext context, String initial) =>
    showDialog<String>(
      context: context,
      builder: (context) => RenameDialog(initial: initial),
    );

class RenameDialog extends StatefulWidget {
  const RenameDialog({super.key, required this.initial});

  /// The name already in use, which the field opens holding.
  final String initial;

  @override
  State<RenameDialog> createState() => RenameDialogState();
}

class RenameDialogState extends State<RenameDialog> {
  late final TextEditingController _controller;
  String? _problem;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initial);

    // Pre-selected, because the field arrives holding a name they already have
    // and the thing they came to do is replace it. Making somebody clear it by
    // hand first is a small rudeness repeated every time.
    _controller.selection = TextSelection(
      baseOffset: 0,
      extentOffset: widget.initial.length,
    );
  }

  @override
  void dispose() {
    // Runs when the ROUTE is gone, not when the future completed — which is
    // the difference between this and disposing at the call site.
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = PourfectTokens.of(context);

    return AlertDialog(
      backgroundColor: tokens.surfaceRaised,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(tokens.panelRadius),
        side: BorderSide(color: tokens.hairline),
      ),
      title: Text('Your name', style: titleStyle(tokens)),
      // Scrollable, because an AlertDialog gives its content the height left
      // over after the keyboard takes its share, and on a short screen that
      // can be less than the content needs. The overflow that reported
      // alongside the disposed-controller crash was this.
      content: SingleChildScrollView(
        child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'This is what other players see on the leaderboards.',
            style: bodyStyle(tokens),
          ),
          SizedBox(height: tokens.space3),
          TextField(
            controller: _controller,
            autofocus: true,
            maxLength: kMaxDisplayName,
            style: bodyStyle(tokens).copyWith(color: tokens.textPrimary),
            decoration: InputDecoration(
              errorText: _problem,
              counterStyle: labelStyle(tokens),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: tokens.hairline),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: tokens.accent),
              ),
            ),
            onChanged: (value) =>
                setState(() => _problem = displayNameProblem(value)),
            onSubmitted: (_) => _submit(),
          ),
        ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Cancel',
            style: actionStyle(tokens, color: tokens.textMuted),
          ),
        ),
        TextButton(
          onPressed: _problem == null ? _submit : null,
          // The color is set explicitly, which overrides the disabled tint
          // Flutter would otherwise apply — so a Save that cannot be pressed
          // looked exactly like one that could. Seen on device.
          child: Text(
            'Save',
            style: actionStyle(
              tokens,
              color: _problem == null ? null : tokens.dimText,
            ),
          ),
        ),
      ],
    );
  }

  void _submit() {
    final name = _controller.text.trim();
    final problem = displayNameProblem(name);
    if (problem != null) {
      setState(() => _problem = problem);
      return;
    }
    Navigator.of(context).pop(name);
  }
}

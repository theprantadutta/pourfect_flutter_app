/// The box for changing your leaderboard name: a "HELLO my name is" tag.
///
/// Shared by Settings and the account screen the crest opens. Both surfaces
/// legitimately offer a rename, and one dialog is the difference between them
/// agreeing by construction and agreeing because somebody remembered to edit
/// two files.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../services/api/leaderboard_api.dart';
import '../theme/toy.dart';
import 'toy_kit.dart';

/// Opens the rename box and returns the chosen name, or null if cancelled.
Future<String?> showRenameDialog(BuildContext context, String initial) =>
    showToyDialog<String>(
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
    final calm = Toy.calm(context);

    final card = ToyDialogCard(
      headerColor: Toy.tomato,
      header: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'HELLO',
            style: Toy.display(46, color: Colors.white, shadow: 2),
          ),
          const SizedBox(height: 2),
          Text(
            'MY NAME IS',
            style: Toy.caps(size: 15, color: Colors.white),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _NameField(
            controller: _controller,
            onChanged: (value) =>
                setState(() => _problem = displayNameProblem(value)),
            onSubmitted: _submit,
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  _problem ?? 'Other players see this on the boards',
                  style: Toy.ui(
                    12,
                    weight: _problem == null ? FontWeight.w600 : FontWeight.w700,
                    color: _problem == null ? Toy.inkMuted : Toy.tomatoDark,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: _controller,
                builder: (context, value, _) => Text(
                  '${value.text.characters.length}/$kMaxDisplayName',
                  style: Toy.numbers(12, color: Toy.inkMuted),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ToyButton.secondary(
                  label: 'Cancel',
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ToyButton(
                  label: 'SAVE',
                  color: Toy.mint,
                  textColor: Toy.ink,
                  height: 52,
                  radius: 16,
                  shadow: 4,
                  fontSize: 20,
                  // Disabled while the name is refused, and it LOOKS disabled:
                  // a Save that cannot be pressed looking exactly like one that
                  // can was seen on device.
                  onPressed: _problem == null ? _submit : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );

    // The tag wobbles as it lands: -3° settling to -1° on a spring. Calm keeps
    // the resting tilt and drops the motion.
    final tilted = calm
        ? Transform.rotate(angle: _rad(-1), child: card)
        : TweenAnimationBuilder<double>(
            tween: Tween(begin: -3, end: -1),
            duration: const Duration(milliseconds: 700),
            curve: Curves.elasticOut,
            builder: (context, deg, child) =>
                Transform.rotate(angle: _rad(deg), child: child),
            child: card,
          );

    // Scrollable and lifted over the keyboard: a dialog route does not pad
    // for the inset, and on a short screen the field would sit under it.
    return AnimatedPadding(
      duration: const Duration(milliseconds: 120),
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 8),
        child: tilted,
      ),
    );
  }

  static double _rad(double deg) => deg * math.pi / 180;

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

/// The cream name field, written in the display face.
class _NameField extends StatelessWidget {
  const _NameField({
    required this.controller,
    required this.onChanged,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onSubmitted;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 62,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        color: Toy.cream,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Toy.ink, width: Toy.stroke),
      ),
      child: TextSelectionTheme(
        data: TextSelectionThemeData(
          cursorColor: Toy.tomato,
          selectionColor: Toy.lilac.withValues(alpha: 0.45),
          selectionHandleColor: Toy.tomato,
        ),
        child: TextField(
          controller: controller,
          autofocus: true,
          maxLength: kMaxDisplayName,
          // The counter is drawn under the box, as part of the tag.
          buildCounter:
              (_, {required currentLength, required isFocused, maxLength}) =>
                  null,
          cursorColor: Toy.tomato,
          cursorWidth: 3,
          cursorRadius: const Radius.circular(2),
          style: Toy.display(28, height: 1.2),
          decoration: const InputDecoration.collapsed(hintText: null),
          onChanged: onChanged,
          onSubmitted: (_) => onSubmitted(),
        ),
      ),
    );
  }
}

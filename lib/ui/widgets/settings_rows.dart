/// The row vocabulary Settings is built from, shared with the account screen.
///
/// Extracted when the account screen the crest opens needed the same language.
/// Rebuilding a second set of rows there would have given the app two
/// settings-shaped surfaces that drift apart on the first change to either —
/// and the first version of that screen, built without these, is exactly what
/// "what even is this, why does it look like that" was about.
///
/// These are app furniture and may look like it. See the settings section of
/// CLAUDE.md for why that is the opposite of the home screen's rule.
library;

import 'package:flutter/material.dart';

import '../theme/tokens.dart';
import '../theme/typography.dart';
import 'pressable.dart';

class SectionHeader extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool danger;

  const SectionHeader({
    super.key,
    required this.icon,
    required this.label,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = PourfectTokens.of(context);
    final color = danger ? kDestructive : tokens.textMuted;

    return Padding(
      padding: EdgeInsets.only(bottom: tokens.space3),
      child: Row(
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 15, color: color),
          ),
          SizedBox(width: tokens.space2),
          Text(
            label.toUpperCase(),
            style: labelStyle(tokens).copyWith(
              color: color,
              letterSpacing: 1.8,
            ),
          ),
          SizedBox(width: tokens.space3),
          // Carries the eye along the row and gives the label somewhere to
          // end. One hairline; the reference draws four corner brackets, which
          // is its language rather than ours.
          Expanded(
            child: Container(height: 1, color: tokens.hairline),
          ),
        ],
      ),
    );
  }
}

/// The destructive red, in one place.
const Color kDestructive = Color(0xFFC85F72);

/// The panel a section's rows sit in.
///
/// Rows used to be loose on the ground with a hairline under each, so six
/// sections and thirteen rows read as one undifferentiated column and the only
/// thing separating "Haptics" from "Delete account" was the color of the text.
class Group extends StatelessWidget {
  final List<Widget> children;
  final bool danger;

  const Group({super.key, required this.children, this.danger = false});

  @override
  Widget build(BuildContext context) {
    final tokens = PourfectTokens.of(context);

    return Container(
      decoration: BoxDecoration(
        color: tokens.surfaceRaised,
        borderRadius: BorderRadius.circular(tokens.panelRadius),
        border: Border.all(
          color: danger
              ? kDestructive.withValues(alpha: 0.35)
              : tokens.hairline,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }
}

/// Something that is not a row, sitting inside a group.
class GroupInset extends StatelessWidget {
  final Widget child;

  const GroupInset({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final tokens = PourfectTokens.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        tokens.space3,
        0,
        tokens.space3,
        tokens.space3,
      ),
      child: child,
    );
  }
}

/// The player, at the top of their own settings.

class ToggleRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String detail;
  final bool value;
  final ValueChanged<bool> onChanged;

  /// Drops the divider, so the last row does not draw a line onto the panel's
  /// own bottom edge.
  final bool last;

  const ToggleRow({
    super.key,
    required this.icon,
    required this.title,
    required this.detail,
    required this.value,
    required this.onChanged,
    this.last = false,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = PourfectTokens.of(context);

    return Pressable(
      onPressed: () => onChanged(!value),
      semanticLabel: '$title, ${value ? "on" : "off"}',
      scale: 0.99,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: tokens.space3,
          vertical: tokens.space3,
        ),
        decoration: BoxDecoration(
          border: last
              ? null
              : Border(bottom: BorderSide(color: tokens.hairline)),
        ),
        child: Row(
          children: [
            // The glyph is what makes a list of thirteen rows scannable.
            // Muted, and it brightens with the switch — so the state is
            // legible from the left edge as well as the right.
            RowIcon(icon: icon, active: value),
            SizedBox(width: tokens.space3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: actionStyle(tokens).copyWith(fontSize: 15),
                  ),
                  SizedBox(height: 2),
                  Text(
                    detail,
                    style: bodyStyle(tokens)
                        .copyWith(fontSize: 12, height: 1.4),
                  ),
                ],
              ),
            ),
            SizedBox(width: tokens.space3),
            SettingsSwitch(value: value),
          ],
        ),
      ),
    );
  }
}

/// A settings row's glyph, in its own tile.
class RowIcon extends StatelessWidget {
  final IconData icon;
  final bool active;
  final bool destructive;

  const RowIcon({
    super.key,
    required this.icon,
    this.active = false,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = PourfectTokens.of(context);
    final color = destructive
        ? kDestructive
        : active
            ? tokens.accent
            : tokens.textMuted;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: color.withValues(alpha: active || destructive ? 0.14 : 0.07),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, size: 18, color: color),
    );
  }
}

/// A hairline switch, not Material's. The stock one arrives with its own
/// color language and ripple; this one is made of the same tokens as
/// everything else on screen.
class SettingsSwitch extends StatelessWidget {
  final bool value;

  const SettingsSwitch({super.key, required this.value});

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

class ActionRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String detail;
  final VoidCallback onTap;
  final bool destructive;
  final bool last;

  const ActionRow({
    super.key,
    required this.icon,
    required this.title,
    required this.detail,
    required this.onTap,
    this.destructive = false,
    this.last = false,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = PourfectTokens.of(context);

    return Pressable(
      onPressed: onTap,
      semanticLabel: title,
      scale: 0.99,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: tokens.space3,
          vertical: tokens.space3,
        ),
        decoration: BoxDecoration(
          border: last
              ? null
              : Border(bottom: BorderSide(color: tokens.hairline)),
        ),
        child: Row(
          children: [
            RowIcon(icon: icon, destructive: destructive),
            SizedBox(width: tokens.space3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: actionStyle(
                      tokens,
                      color: destructive ? kDestructive : tokens.textPrimary,
                    ).copyWith(fontSize: 15),
                  ),
                  SizedBox(height: 2),
                  Text(
                    detail,
                    style: bodyStyle(tokens).copyWith(fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
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

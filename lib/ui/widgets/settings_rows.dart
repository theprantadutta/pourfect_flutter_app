/// The row vocabulary Settings is built from, shared with the account screen.
///
/// Extracted when the account screen the crest opens needed the same language.
/// Rebuilding a second set of rows there would have given the app two
/// settings-shaped surfaces that drift apart on the first change to either —
/// and the first version of that screen, built without these, is exactly what
/// "what even is this, why does it look like that" was about.
///
/// These are app furniture and may look like it. See the settings section of
/// CLAUDE.md for why that is the opposite of the home screen's rule. In the
/// Toybox direction a section is a white card with an ink stroke and a hard
/// shadow; every row leads with a colored icon tile, so a list of thirteen
/// rows can be scanned by color from the left edge.
library;

import 'package:flutter/material.dart';

import '../theme/toy.dart';
import 'toy_kit.dart';

/// The destructive color, in one place.
const Color kDestructive = Toy.tomatoDark;

/// The moss ball's green: the "show me" tile. Not one of the brand accents,
/// so it lives here rather than in [Toy].
const Color kRowMoss = Color(0xFF9BE15D);

/// The hairline between rows inside a danger card: tomato-tint's own darker
/// step, so the rule does not read as a cream seam on pink.
const Color _dangerDivider = Color(0xFFF6C9BB);

/// Section label above a card: FEEL, VISIBILITY, DANGER ZONE.
class SectionHeader extends StatelessWidget {
  final String label;
  final bool danger;

  const SectionHeader({super.key, required this.label, this.danger = false});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 18, bottom: 2),
    child: ToySectionLabel(
      label,
      color: danger ? Toy.tomato : Toy.inkMuted,
    ),
  );
}

/// The card a section's rows sit in.
///
/// Rows used to be loose on the ground with a hairline under each, so six
/// sections and thirteen rows read as one undifferentiated column and the only
/// thing separating "Haptics" from "Delete account" was the color of the text.
///
/// Draws the hairline BETWEEN its children itself, so no row has to know
/// whether it is last.
class Group extends StatelessWidget {
  final List<Widget> children;
  final bool danger;

  const Group({super.key, required this.children, this.danger = false});

  @override
  Widget build(BuildContext context) {
    final divider = Container(
      height: 1.5,
      color: danger ? _dangerDivider : Toy.divider,
    );
    // The hard shadow paints outside the layout box; the bottom margin keeps a
    // scroll view's clip from shaving it.
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Container(
        decoration: Toy.box(
          fill: danger ? Toy.tomatoTint : Toy.card,
          shadowColor: danger ? Toy.tomato : Toy.ink,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0 && children[i] is! GroupInset) divider,
              children[i],
            ],
          ],
        ),
      ),
    );
  }
}

/// Something that is not a row, sitting inside a group.
class GroupInset extends StatelessWidget {
  final Widget child;

  const GroupInset({super.key, required this.child});

  @override
  Widget build(BuildContext context) =>
      Padding(padding: const EdgeInsets.fromLTRB(12, 0, 12, 12), child: child);
}

/// A settings row's glyph, in its colored tile.
///
/// [icon] is a Material icon or any widget; it is drawn in [ink] at the
/// tile's icon size.
class RowIcon extends StatelessWidget {
  final Widget icon;
  final Color color;
  final Color ink;

  const RowIcon({
    super.key,
    required this.icon,
    required this.color,
    this.ink = Toy.ink,
  });

  @override
  Widget build(BuildContext context) => ToyIconTile(
    color: color,
    child: IconTheme.merge(
      data: IconThemeData(color: ink, size: 20),
      child: DefaultTextStyle.merge(
        style: TextStyle(color: ink),
        child: icon,
      ),
    ),
  );
}

/// The row body both kinds share: tile, title, detail, trailing.
class _RowBody extends StatelessWidget {
  final Widget? icon;
  final String title;
  final String? detail;
  final Widget? trailing;
  final Color titleColor;
  final FontWeight titleWeight;

  /// Detail lines: 1 for an action (the Settings rule — the copy is written to
  /// fit the row), unbounded where the sentence is the explanation.
  final int? detailLines;

  const _RowBody({
    required this.icon,
    required this.title,
    required this.detail,
    required this.trailing,
    this.titleColor = Toy.ink,
    this.titleWeight = FontWeight.w700,
    this.detailLines = 1,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
    child: Row(
      children: [
        if (icon != null) ...[icon!, const SizedBox(width: 12)],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: Toy.ui(15, weight: titleWeight, color: titleColor),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (detail != null && detail!.isNotEmpty) ...[
                const SizedBox(height: 1),
                Text(
                  detail!,
                  style: Toy.ui(
                    12,
                    weight: FontWeight.w500,
                    color: Toy.inkMuted,
                    height: 1.3,
                  ),
                  maxLines: detailLines,
                  overflow: detailLines == null ? null : TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
        if (trailing != null) ...[const SizedBox(width: 12), trailing!],
      ],
    ),
  );
}

/// The ink chevron at the end of a row that goes somewhere.
class RowChevron extends StatelessWidget {
  final Color color;

  const RowChevron({super.key, this.color = Toy.ink});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(right: 2),
    child: Transform.flip(
      flipX: true,
      child: ToyIcon(ToyGlyph.back, size: 16, color: color),
    ),
  );
}

class ToggleRow extends StatelessWidget {
  final Widget icon;
  final Color iconColor;
  final Color iconInk;
  final String title;
  final String detail;
  final bool value;
  final ValueChanged<bool> onChanged;

  const ToggleRow({
    super.key,
    required this.icon,
    required this.iconColor,
    this.iconInk = Toy.ink,
    required this.title,
    required this.detail,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => Pressable(
    onPressed: () => onChanged(!value),
    semanticLabel: '$title, ${value ? "on" : "off"}',
    depth: 1.5,
    child: _RowBody(
      icon: RowIcon(icon: icon, color: iconColor, ink: iconInk),
      title: title,
      detail: detail,
      // A switch's detail is the explanation of what it does, and may wrap;
      // the one-line rule is for rows that navigate.
      detailLines: null,
      // The whole row is the control. The toggle is its picture, so it takes
      // no taps of its own and cannot fire twice.
      trailing: ExcludeSemantics(
        child: ToyToggle(value: value, onChanged: null),
      ),
    ),
  );
}

class ActionRow extends StatelessWidget {
  final Widget? icon;
  final Color iconColor;
  final Color iconInk;
  final String title;
  final String? detail;
  final VoidCallback? onTap;
  final bool destructive;

  /// Replaces the chevron: a price button, say. Null keeps the chevron; pass
  /// [SizedBox.shrink] for a row with nothing on the right.
  final Widget? trailing;

  const ActionRow({
    super.key,
    this.icon,
    this.iconColor = Toy.cream,
    this.iconInk = Toy.ink,
    required this.title,
    this.detail,
    required this.onTap,
    this.destructive = false,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final body = _RowBody(
      icon: icon == null
          ? null
          : RowIcon(icon: icon!, color: iconColor, ink: iconInk),
      title: title,
      detail: detail,
      titleColor: destructive ? kDestructive : Toy.ink,
      titleWeight: destructive ? FontWeight.w800 : FontWeight.w700,
      trailing:
          trailing ??
          (onTap == null
              ? null
              : RowChevron(color: destructive ? kDestructive : Toy.ink)),
    );
    if (onTap == null) return Semantics(label: title, child: body);
    return Pressable(
      onPressed: onTap,
      semanticLabel: title,
      depth: 1.5,
      child: body,
    );
  }
}

/// Three ink bars: the Statistics tile.
class BarsGlyph extends StatelessWidget {
  const BarsGlyph({super.key});

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 18,
    height: 16,
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (final h in const [8.0, 14.0, 11.0])
          Container(
            width: 4,
            height: h,
            decoration: BoxDecoration(
              color: Toy.ink,
              borderRadius: BorderRadius.circular(1),
            ),
          ),
      ],
    ),
  );
}

/// A short message in the Toybox voice: an ink pill, white Outfit.
///
/// Uses the nearest [ScaffoldMessenger], so the screen must sit in a
/// [Scaffold] for it to appear.
void showRowMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..clearSnackBars()
    ..showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Toy.ink,
        elevation: 0,
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Toy.rControl),
        ),
        content: Text(
          message,
          style: Toy.ui(14, weight: FontWeight.w700, color: Colors.white),
        ),
      ),
    );
}

/// Masks the local part of an email for display: `pranta•••@gmail.com`.
///
/// Settings and the player card are screens people screenshot and share. The
/// address stays recognizable to its owner without being readable by anyone
/// the screenshot reaches.
String maskEmail(String email) {
  final at = email.indexOf('@');
  if (at <= 0) return email;
  final local = email.substring(0, at);
  final keep = (local.length / 2).ceil().clamp(1, 6);
  if (keep >= local.length) return email;
  return '${local.substring(0, keep)}•••${email.substring(at)}';
}

/// A two-button question in the Toybox style, for the settings-shaped screens.
///
/// Differs from `showToyConfirm` in the two ways these screens need: the
/// confirm can be DISABLED (a reset with nothing to reset still explains
/// itself rather than silently not opening), and a destructive confirm is
/// tomato with white text. Resolves true only for the confirm button.
Future<bool> showRowConfirm({
  required BuildContext context,
  required String title,
  required String body,
  required String confirmLabel,
  String cancelLabel = 'Cancel',
  bool destructive = false,
  bool confirmEnabled = true,
}) async {
  final result = await showToyDialog<bool>(
    context: context,
    builder: (context) => ToyDialogCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: Toy.display(24, height: 1.1)),
          const SizedBox(height: 10),
          Flexible(
            child: SingleChildScrollView(
              child: Text(
                body,
                style: Toy.ui(
                  15,
                  weight: FontWeight.w500,
                  color: Toy.inkMuted,
                  height: 1.4,
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: ToyButton.secondary(
                  label: cancelLabel,
                  onPressed: () => Navigator.of(context).pop(false),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ToyButton(
                  label: confirmLabel,
                  color: destructive ? Toy.tomato : Toy.mint,
                  textColor: destructive ? Colors.white : Toy.ink,
                  height: 52,
                  radius: 16,
                  shadow: 4,
                  fontSize: 18,
                  onPressed: confirmEnabled
                      ? () => Navigator.of(context).pop(true)
                      : null,
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
  return result ?? false;
}

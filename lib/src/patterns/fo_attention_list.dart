import 'package:flutter/material.dart';

import '../primitives/fo_button.dart';
import '../primitives/fo_focus_ring.dart';
import '../primitives/fo_status_chip.dart';
import '../theme/fo_context.dart';
import '../tokens/fo_layout.dart';
import '../tokens/fo_tokens.dart';

/// One thing that needs somebody: "Slim Chino is due in 7 days", "3 change
/// requests are waiting for you".
///
/// A toned mark (what kind of thing), a title that says the fact in a
/// sentence, a subtitle with the evidence, and **one way to act on it** —
/// either an [actionLabel] button ("Open order", "Review") on a wide window,
/// or the whole row as a link with a chevron ([onTap]) on a phone. An
/// attention item with nothing to do is a notification, and belongs
/// somewhere else.
///
/// The tone is the item's urgency, not decoration: [FoStatusTone.danger] for
/// a deadline that is close, warning for a pile-up, info for something
/// waiting on someone else.
class FoAttentionItem extends StatelessWidget {
  /// Creates an attention item.
  const FoAttentionItem({
    required this.icon,
    required this.title,
    this.subtitle,
    this.tone = FoStatusTone.warning,
    this.actionLabel,
    this.onAction,
    this.onTap,
    this.trailing,
    this.unseen = false,
    this.unseenLabel,
    super.key,
  })  : assert(
          !unseen || unseenLabel != null,
          'unseenLabel is required when unseen is set — a dot nobody can '
          'read aloud is colour alone.',
        ),
        assert(
          onAction == null || actionLabel != null,
          'actionLabel is required when onAction is set.',
        ),
        assert(
          onAction == null || onTap == null,
          'Pass onAction (a button) or onTap (the whole row), not both — two '
          'targets for one thing is one too many.',
        );

  /// The mark — what kind of thing this is.
  final IconData icon;

  /// The fact, as a sentence. Caller-supplied.
  final String title;

  /// The evidence — codes, counts, dates.
  final String? subtitle;

  /// How urgent it is.
  final FoStatusTone tone;

  /// The button's label — "Open order".
  final String? actionLabel;

  /// The button's action.
  final VoidCallback? onAction;

  /// Makes the whole row the target, with a chevron — the phone form.
  final VoidCallback? onTap;

  /// A verdict at the end of the row — a `FoStatusChip` "Done" or "Not yet"
  /// in a readiness checklist, where the row is a check rather than a task.
  final Widget? trailing;

  /// Marks an alert nobody has opened yet, with a primary dot.
  final bool unseen;

  /// What the dot means, read aloud — "New".
  final String? unseenLabel;

  /// The mark's disc.
  static const double _markSize = 36;

  @override
  Widget build(BuildContext context) {
    final (Color ink, Color ground) = switch (tone) {
      FoStatusTone.neutral => (
          context.foColors.fgMuted,
          context.foColors.surfaceSunken,
        ),
      FoStatusTone.primary => (
          context.foColors.primary,
          context.foColors.primarySoft,
        ),
      FoStatusTone.success => (
          context.foColors.success,
          context.foColors.successSoft,
        ),
      FoStatusTone.warning => (
          context.foColors.warning,
          context.foColors.warningSoft,
        ),
      FoStatusTone.danger => (
          context.foColors.danger,
          context.foColors.dangerSoft,
        ),
      FoStatusTone.info => (context.foColors.info, context.foColors.infoSoft),
    };

    final Widget text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(title, style: context.foText.label),
        if (subtitle != null) ...<Widget>[
          SizedBox(height: context.foSpacing.xs),
          Text(
            subtitle!,
            style: context.foText.body.copyWith(
              fontSize: FoTokens.fontLabel,
              color: context.foColors.fgMuted,
            ),
          ),
        ],
      ],
    );

    final Widget mark = Center(
// A circle stays a circle under any constraints (see FoDisc).
      widthFactor: 1,
      heightFactor: 1,
      child: Container(
        width: _markSize,
        height: _markSize,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: ground, shape: BoxShape.circle),
        child: Icon(icon, size: FoTokens.iconSmall, color: ink),
      ),
    );

    final Widget row = Padding(
      padding: EdgeInsets.symmetric(vertical: context.foSpacing.md),
      child: Row(
        children: <Widget>[
          mark,
          SizedBox(width: context.foSpacing.md),
          Expanded(
            child: onAction == null
                ? text
                // The text and the button wrap, so at 200% text the button
                // drops under the sentence instead of off the right.
                : Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: context.foSpacing.md,
                    runSpacing: context.foSpacing.sm,
                    children: <Widget>[
                      text,
                      FoButton(
                        label: actionLabel!,
                        variant: FoButtonVariant.secondary,
                        onPressed: onAction,
                      ),
                    ],
                  ),
          ),
          if (trailing != null) ...<Widget>[
            SizedBox(width: context.foSpacing.sm),
            trailing!,
          ],
          if (unseen) ...<Widget>[
            SizedBox(width: context.foSpacing.sm),
            Semantics(
              label: unseenLabel,
              child: Center(
// A circle stays a circle under any constraints (see FoDisc).
                widthFactor: 1,
                heightFactor: 1,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: context.foColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ],
          if (onTap != null) ...<Widget>[
            SizedBox(width: context.foSpacing.sm),
            Icon(
              Icons.chevron_right,
              size: FoTokens.iconMedium,
              color: context.foColors.fgSubtle,
            ),
          ],
        ],
      ),
    );

    // A container, not a merge: merging would fold the button into the
    // sentence, and a screen reader would hear one node with two jobs.
    if (onTap == null) return Semantics(container: true, child: row);

    final BorderRadius radius = BorderRadius.circular(context.foRadii.md);
    return Semantics(
      button: true,
      child: FoFocusRing(
        borderRadius: radius,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onTap,
            borderRadius: radius,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: FoLayout.minTouchTarget,
              ),
              child: row,
            ),
          ),
        ),
      ),
    );
  }
}

/// A list of [FoAttentionItem]s with a hairline between each — "Needs your
/// attention" on a dashboard or a home screen.
///
/// The heading and the count beside it are the caller's (a
/// `FoSectionSurface`, say); this is only the rows. An empty list renders
/// nothing: "nothing needs you" is the caller's sentence to write, and it
/// must never be what a *failed* load shows.
class FoAttentionList extends StatelessWidget {
  /// Creates an attention list.
  const FoAttentionList({required this.items, super.key});

  /// The rows, most urgent first.
  final List<FoAttentionItem> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (int i = 0; i < items.length; i++) ...<Widget>[
          if (i > 0)
            Divider(
              height: FoLayout.hairlineWidth,
              thickness: FoLayout.hairlineWidth,
              color: context.foColors.edge,
            ),
          items[i],
        ],
      ],
    );
  }
}

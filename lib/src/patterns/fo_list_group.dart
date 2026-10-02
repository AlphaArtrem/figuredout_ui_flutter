import 'package:flutter/material.dart';

import '../primitives/fo_focus_ring.dart';
import '../theme/fo_context.dart';
import '../tokens/fo_layout.dart';
import '../tokens/fo_tokens.dart';

/// How a [FoListRow]'s leading mark is drawn.
enum FoListRowLeading {
  /// A bare glyph in `fgMuted` — a settings menu.
  icon,

  /// A glyph on a primary-wash tile — a guide, a report, a topic.
  tile,
}

/// One row in a [FoListGroup]: a destination, a setting, a person, a guide.
///
/// A leading mark, a title, an optional subtitle, something on the right — a
/// figure, a chip, a word — and a chevron when the row goes somewhere. The
/// whole row is the target, at least 56 points tall. [child] puts a control
/// under the row that belongs to it (the Appearance switch in a settings
/// list) rather than beside it.
///
/// Pass [leadingWidget] for anything [icon] cannot be — a `FoAvatar`, a
/// numbered disc, a colour swatch.
class FoListRow extends StatelessWidget {
  /// Creates a list row.
  const FoListRow({
    required this.title,
    this.subtitle,
    this.icon,
    this.leadingStyle = FoListRowLeading.icon,
    this.leadingWidget,
    this.trailing,
    this.onTap,
    this.semanticLabel,
    this.showChevron,
    this.selected = false,
    this.child,
    super.key,
  });

  /// What the row is. Caller-supplied.
  final String title;

  /// A line of detail under it.
  final String? subtitle;

  /// The leading glyph.
  final IconData? icon;

  /// How [icon] is drawn.
  final FoListRowLeading leadingStyle;

  /// A leading widget instead of [icon].
  final Widget? leadingWidget;

  /// A figure, a chip or a word at the end of the row.
  final Widget? trailing;

  /// Makes the row a target.
  final VoidCallback? onTap;

  /// What the row says to a screen reader, when the visible text does not
  /// say it whole — "Pressing, 616 waiting".
  final String? semanticLabel;

  /// Draws the chevron. Defaults to on when the row has [onTap].
  final bool? showChevron;

  /// Marks the row as the current one — on the primary wash.
  final bool selected;

  /// A control that belongs to this row, under it.
  final Widget? child;

  /// The leading tile's size.
  static const double _tileSize = 36;

  @override
  Widget build(BuildContext context) {
    final Widget? leading = leadingWidget ??
        (icon == null
            ? null
            : leadingStyle == FoListRowLeading.tile
                ? Container(
                    width: _tileSize,
                    height: _tileSize,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: context.foColors.primarySoft,
                      borderRadius: BorderRadius.circular(context.foRadii.md),
                    ),
                    child: Icon(
                      icon,
                      size: FoTokens.iconSmall,
                      color: context.foColors.primary,
                    ),
                  )
                : Icon(
                    icon,
                    size: FoTokens.iconMedium - 2,
                    color: context.foColors.fgMuted,
                  ));

    final bool chevron = showChevron ?? onTap != null;

    final Widget row = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: FoLayout.minTouchTarget + 8),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: context.foSpacing.md,
          vertical: context.foSpacing.sm,
        ),
        child: Row(
          children: <Widget>[
            if (leading != null) ...<Widget>[
              leading,
              SizedBox(width: context.foSpacing.md),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    title,
                    style: context.foText.subtitle.copyWith(
                      color: selected ? context.foColors.primary : null,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: context.foText.body.copyWith(
                        fontSize: FoTokens.fontLabel,
                        color: context.foColors.fgSubtle,
                      ),
                    ),
                ],
              ),
            ),
            if (trailing != null) ...<Widget>[
              SizedBox(width: context.foSpacing.md),
              Flexible(child: trailing!),
            ],
            if (chevron) ...<Widget>[
              SizedBox(width: context.foSpacing.xs),
              Icon(
                Icons.chevron_right,
                size: FoTokens.iconSmall + 2,
                color: context.foColors.fgSubtle,
              ),
            ],
          ],
        ),
      ),
    );

    final Widget body = child == null
        ? row
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              row,
              Padding(
                padding: EdgeInsets.fromLTRB(
                  context.foSpacing.md,
                  0,
                  context.foSpacing.md,
                  context.foSpacing.md,
                ),
                child: child,
              ),
            ],
          );

    final Color fill =
        selected ? context.foColors.primarySoft : Colors.transparent;

    if (onTap == null) {
      return Semantics(
        container: true,
        selected: selected,
        label: semanticLabel,
        child: ColoredBox(color: fill, child: body),
      );
    }

    final BorderRadius radius = BorderRadius.circular(context.foRadii.md);
    return Semantics(
      button: true,
      selected: selected,
      label: semanticLabel,
      excludeSemantics: semanticLabel != null && child == null,
      child: FoFocusRing(
        borderRadius: radius,
        child: Material(
          color: fill,
          child: InkWell(onTap: onTap, child: body),
        ),
      ),
    );
  }
}

/// A titled group of [FoListRow]s on one card, a hairline between each —
/// More, Settings, Help topics, "Did you mean one of these?".
///
/// The heading is a mono caption, with an optional note at its far end ("in
/// production order", "Pressing supervisor").
class FoListGroup extends StatelessWidget {
  /// Creates a list group.
  const FoListGroup({
    required this.rows,
    this.heading,
    this.headingTrailing,
    super.key,
  });

  /// The rows, in order.
  final List<Widget> rows;

  /// The caption over the card.
  final String? heading;

  /// A short note at the end of the heading line.
  final String? headingTrailing;

  @override
  Widget build(BuildContext context) {
    final BorderRadius radius = BorderRadius.circular(context.foRadii.card);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (heading != null) ...<Widget>[
          Padding(
            padding: EdgeInsets.symmetric(horizontal: context.foSpacing.xs),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              spacing: context.foSpacing.md,
              children: <Widget>[
                Semantics(
                  header: true,
                  child: Text(
                    heading!.toUpperCase(),
                    style: context.foText.caption,
                  ),
                ),
                if (headingTrailing != null)
                  Text(
                    headingTrailing!,
                    style: context.foText.body.copyWith(
                      fontSize: FoTokens.fontCaption,
                      color: context.foColors.fgSubtle,
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(height: context.foSpacing.sm),
        ],
        DecoratedBox(
          decoration: BoxDecoration(
            color: context.foColors.surfaceRaised,
            borderRadius: radius,
          ),
          child: DecoratedBox(
            position: DecorationPosition.foreground,
            decoration: BoxDecoration(
              borderRadius: radius,
              border: Border.all(color: context.foColors.edge),
            ),
            child: ClipRRect(
              borderRadius: radius,
              child: Material(
                type: MaterialType.transparency,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    for (int i = 0; i < rows.length; i++) ...<Widget>[
                      if (i > 0)
                        Divider(
                          height: FoLayout.hairlineWidth,
                          thickness: FoLayout.hairlineWidth,
                          color: context.foColors.edge,
                        ),
                      rows[i],
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

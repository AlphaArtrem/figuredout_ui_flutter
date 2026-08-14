import 'package:flutter/material.dart';

import '../theme/fo_context.dart';
import '../tokens/fo_layout.dart';
import 'fo_card.dart';
import 'fo_section_header.dart';

/// A framed section: a titled card whose content runs edge to edge.
///
/// This is the shape rule §3.1 exists for. The header sits above a full-width
/// divider, and the content below it is often a table that paints its own
/// header row to the card's edges. Drawn with `decoration.border`, the card's
/// hairline would disappear behind that row along the top edge. `FoCard` puts
/// it in `foregroundDecoration`, so it survives — see `FoCard`'s doc for why
/// the symptom never looks like the cause.
class FoSectionSurface extends StatelessWidget {
  /// Creates a framed section.
  const FoSectionSurface({
    required this.child,
    this.title,
    this.subtitle,
    this.trailing,
    this.headerPadding,
    this.contentPadding,
    this.showDivider = true,
    super.key,
  });

  /// The section's content.
  final Widget child;

  /// The section's name. Caller-supplied, so it can be localized.
  final String? title;

  /// A line under the title, for context the title cannot carry.
  final String? subtitle;

  /// An action in the header.
  final Widget? trailing;

  /// Padding around the header. Defaults to `foSpacing.lg`.
  final EdgeInsetsGeometry? headerPadding;

  /// Padding around the content. Defaults to none, because the content of a
  /// framed section is usually meant to reach the edges.
  final EdgeInsetsGeometry? contentPadding;

  /// The rule between header and content. Turn it off when the content
  /// already begins with one of its own.
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final bool hasTitle = title?.trim().isNotEmpty ?? false;
    final bool hasSubtitle = subtitle?.trim().isNotEmpty ?? false;
    final bool hasHeader = hasTitle || hasSubtitle || trailing != null;

    return FoCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (hasHeader) ...<Widget>[
            Padding(
              padding: headerPadding ?? EdgeInsets.all(context.foSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  if (hasTitle || trailing != null)
                    FoSectionHeader(
                      title: hasTitle ? title!.trim() : '',
                      trailing: trailing,
                    ),
                  if (hasSubtitle) ...<Widget>[
                    if (hasTitle || trailing != null)
                      SizedBox(height: context.foSpacing.xs),
                    Text(
                      subtitle!,
                      style: context.foText.body.copyWith(
                        color: context.foColors.fgMuted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (showDivider)
              Divider(
                height: FoLayout.hairlineWidth,
                thickness: FoLayout.hairlineWidth,
                color: context.foColors.edge,
              ),
          ],
          Padding(
            padding: contentPadding ?? EdgeInsets.zero,
            child: child,
          ),
        ],
      ),
    );
  }
}

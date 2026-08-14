import 'package:flutter/material.dart';

import '../theme/fo_context.dart';
import '../tokens/fo_layout.dart';

/// The thing a page is named by: an eyebrow, a title, a lede and its actions.
///
/// Distinct from `FoSectionHeader`, which names a region *inside* a page. A
/// page has exactly one of these, and it is the only place that gets the
/// display scale — reserve it, or the scale stops meaning "this is the page".
class FoPageHeader extends StatelessWidget {
  /// Creates a page header.
  const FoPageHeader({
    required this.title,
    this.eyebrow,
    this.lede,
    this.actions,
    this.showRule = true,
    super.key,
  });

  /// The page's name. Caller-supplied, so it can be localized.
  final String title;

  /// A mono uppercase line above the title — a section, a breadcrumb, a state.
  /// It *names* what follows, which is what mono uppercase is for (§3.3).
  final String? eyebrow;

  /// One or two sentences under the title.
  final String? lede;

  /// The page's actions.
  final List<Widget>? actions;

  /// The rule under the header, separating it from the page's content.
  final bool showRule;

  @override
  Widget build(BuildContext context) {
    final bool wide = context.foWindowClass.isAtLeastMedium;
    final bool hasActions = actions?.isNotEmpty ?? false;

    final Widget text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (eyebrow != null) ...<Widget>[
          Text(eyebrow!.toUpperCase(), style: context.foText.caption),
          SizedBox(height: context.foSpacing.xs),
        ],
        Semantics(
          header: true,
          child: Text(title, style: context.foText.display),
        ),
        if (lede != null) ...<Widget>[
          SizedBox(height: context.foSpacing.sm),
          ConstrainedBox(
            // A lede that runs the full width of a desktop window is a line
            // the eye loses its place in on the way back.
            constraints: const BoxConstraints(maxWidth: 640),
            child: Text(
              lede!,
              style: context.foText.body.copyWith(
                color: context.foColors.fgMuted,
              ),
            ),
          ),
        ],
      ],
    );

    final Widget actionRow = Wrap(
      spacing: context.foSpacing.sm,
      runSpacing: context.foSpacing.sm,
      children: actions ?? const <Widget>[],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (!hasActions)
          text
        else if (wide)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(child: text),
              SizedBox(width: context.foSpacing.lg),
              actionRow,
            ],
          )
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              text,
              SizedBox(height: context.foSpacing.lg),
              actionRow,
            ],
          ),
        if (showRule) ...<Widget>[
          SizedBox(height: context.foSpacing.lg),
          Divider(
            height: FoLayout.hairlineWidth,
            thickness: FoLayout.hairlineWidth,
            color: context.foColors.edge,
          ),
        ],
      ],
    );
  }
}

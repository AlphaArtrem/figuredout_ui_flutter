import 'package:flutter/material.dart';

import '../theme/fo_context.dart';

/// A section's title, with an optional hint dot and an optional trailing
/// action.
///
/// The title is marked `header: true`, which is what lets a screen-reader user
/// jump between sections instead of reading every card top to bottom.
///
/// The trailing action stacks below the title when the header is narrower than
/// [stackBelow]. That threshold is the *header's own* width, measured with a
/// `LayoutBuilder`, not the window's: a header inside a half-width panel on a
/// desktop needs to stack for the same reason a phone does, and the window
/// class cannot see that.
class FoSectionHeader extends StatelessWidget {
  /// Creates a section header.
  const FoSectionHeader({
    required this.title,
    this.hint,
    this.trailing,
    this.stackBelow = 520,
    super.key,
  });

  /// The section's name. Caller-supplied, so it can be localized.
  final String title;

  /// An optional `FoHint`, sitting immediately after the title.
  final Widget? hint;

  /// An optional action — a button, a filter, a count.
  final Widget? trailing;

  /// The header width below which [trailing] stacks under the title.
  final double stackBelow;

  @override
  Widget build(BuildContext context) {
    final Widget titleRow = Row(
      children: <Widget>[
        Expanded(
          child: Semantics(
            header: true,
            child: Text(title, style: context.foText.title),
          ),
        ),
        if (hint != null) hint!,
      ],
    );

    if (trailing == null) return titleRow;

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        if (constraints.maxWidth < stackBelow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              titleRow,
              SizedBox(height: context.foSpacing.sm),
              trailing!,
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(child: titleRow),
            SizedBox(width: context.foSpacing.sm),
            Flexible(child: trailing!),
          ],
        );
      },
    );
  }
}

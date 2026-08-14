import 'package:flutter/material.dart';

import '../primitives/fo_section_header.dart';
import '../theme/fo_context.dart';

/// A titled group of fields inside a form.
///
/// The gap between fields is `foSpacing.lg`, stated once here rather than at
/// every call site, because a form where two sections space their fields
/// differently reads as two forms.
class FoFormSection extends StatelessWidget {
  /// Creates a form section.
  const FoFormSection({
    required this.title,
    required this.children,
    this.helper,
    this.hint,
    super.key,
  });

  /// The group's name. Caller-supplied, so it can be localized.
  final String title;

  /// A line under the title, for a rule the fields cannot state themselves.
  final String? helper;

  /// An optional `FoHint` beside the title.
  final Widget? hint;

  /// The fields.
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final bool hasHelper = helper?.trim().isNotEmpty ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        FoSectionHeader(title: title, hint: hint),
        if (hasHelper) ...<Widget>[
          SizedBox(height: context.foSpacing.xs),
          Text(
            helper!,
            style: context.foText.body.copyWith(
              color: context.foColors.fgMuted,
            ),
          ),
        ],
        SizedBox(height: context.foSpacing.lg),
        for (int i = 0; i < children.length; i++) ...<Widget>[
          children[i],
          if (i < children.length - 1) SizedBox(height: context.foSpacing.lg),
        ],
      ],
    );
  }
}

/// One cell in a [FoFormInlineRow].
@immutable
class FoFormInlineItem {
  /// Creates an inline item.
  const FoFormInlineItem({required this.child, this.flex = 1});

  /// The field.
  final Widget child;

  /// Its share of the row. Two fields at flex 2 and 1 split two-thirds/one.
  final int flex;
}

/// Two or three fields on one line — a quantity beside its unit, a date beside
/// a shift.
///
/// [stackOnCompact] is opt-in rather than automatic: some pairs genuinely must
/// stay side by side to be read as one value, and forcing every row to stack
/// on a phone would break those. Pass it wherever the fields are merely
/// adjacent rather than paired.
class FoFormInlineRow extends StatelessWidget {
  /// Creates an inline row.
  const FoFormInlineRow({
    required this.items,
    this.stackOnCompact = false,
    super.key,
  });

  /// The cells.
  final List<FoFormInlineItem> items;

  /// Stacks the cells full-width on a compact window.
  final bool stackOnCompact;

  @override
  Widget build(BuildContext context) {
    final bool stack = stackOnCompact && !context.foWindowClass.isAtLeastMedium;

    if (stack) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          for (int i = 0; i < items.length; i++) ...<Widget>[
            SizedBox(width: double.infinity, child: items[i].child),
            if (i < items.length - 1) SizedBox(height: context.foSpacing.sm),
          ],
        ],
      );
    }

    return Row(
      children: <Widget>[
        for (int i = 0; i < items.length; i++) ...<Widget>[
          Expanded(flex: items[i].flex, child: items[i].child),
          if (i < items.length - 1) SizedBox(width: context.foSpacing.md),
        ],
      ],
    );
  }
}

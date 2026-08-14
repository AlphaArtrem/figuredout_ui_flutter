import 'package:flutter/material.dart';

import '../theme/fo_context.dart';

/// One term and its value.
@immutable
class FoDescriptionItem {
  /// Creates an item.
  const FoDescriptionItem({required this.label, required this.value});

  /// What the value is. Caller-supplied, so it can be localized.
  final String label;

  /// The value. A widget rather than a string, so a status chip, a boolean
  /// cell or a link can sit here without a second component.
  final Widget value;
}

/// A list of term/value pairs — the detail view of one record.
///
/// Two columns on a wide window, stacked on a narrow one. The stacking is not
/// cosmetic: at a phone's width a two-column layout gives the value about
/// forty per cent of the line, so anything longer than a date wraps to three
/// lines beside a one-line label, and the pairing stops being visible.
///
/// Each pair is one announcement, so a screen reader reads "Line: A" rather
/// than "Line" and "A" as two unrelated fragments several beats apart.
class FoDescriptionList extends StatelessWidget {
  /// Creates a description list.
  const FoDescriptionList(
      {required this.items, this.labelWidth = 180, super.key});

  /// The pairs, in reading order.
  final List<FoDescriptionItem> items;

  /// The label column's width on a wide window.
  final double labelWidth;

  @override
  Widget build(BuildContext context) {
    final bool wide = context.foWindowClass.isAtLeastMedium;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (int i = 0; i < items.length; i++) ...<Widget>[
          MergeSemantics(
            child: wide
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      SizedBox(
                        width: labelWidth,
                        child: Text(
                          items[i].label,
                          style: context.foText.label.copyWith(
                            color: context.foColors.fgMuted,
                          ),
                        ),
                      ),
                      SizedBox(width: context.foSpacing.md),
                      Expanded(child: items[i].value),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        items[i].label,
                        style: context.foText.label.copyWith(
                          color: context.foColors.fgMuted,
                        ),
                      ),
                      SizedBox(height: context.foSpacing.xs),
                      items[i].value,
                    ],
                  ),
          ),
          if (i < items.length - 1) SizedBox(height: context.foSpacing.lg),
        ],
      ],
    );
  }
}

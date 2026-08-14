import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/fo_context.dart';

/// The footer of a paged list or table.
///
/// The counts are formatted by the caller rather than here: "1–20 of 340" is a
/// sentence, and building it from parts inside a design system produces the
/// kind of string that cannot be translated into a language that orders it
/// differently.
class FoPaginationBar extends StatelessWidget {
  /// Creates a pagination bar.
  const FoPaginationBar({
    required this.page,
    required this.totalPages,
    required this.totalLabel,
    required this.pageLabel,
    required this.previousTooltip,
    required this.nextTooltip,
    required this.onPageChanged,
    super.key,
  });

  /// The current page, 1-based.
  final int page;

  /// How many pages there are. Clamped to at least one, so an empty result
  /// reads "page 1 of 1" rather than "1 of 0".
  final int totalPages;

  /// The total, already worded — "340 entries".
  final String totalLabel;

  /// The position, already worded — "Page 2 of 17".
  final String pageLabel;

  /// The back button's tooltip.
  final String previousTooltip;

  /// The forward button's tooltip.
  final String nextTooltip;

  /// Called with the new page number.
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    final int pages = math.max(1, totalPages);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.foSpacing.lg,
        vertical: context.foSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: context.foColors.surface,
        border: Border(top: BorderSide(color: context.foColors.edge)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          // Flexible + ellipsis: on a narrow phone the total, the page counter
          // and two 48dp touch targets do not fit side by side, and a fixed
          // Text overflows the row rather than shortening.
          Flexible(
            child: Text(
              totalLabel,
              style: context.foText.label,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(width: context.foSpacing.lg),
          IconButton(
            icon: const Icon(Icons.chevron_left),
            tooltip: previousTooltip,
            onPressed: page > 1 ? () => onPageChanged(page - 1) : null,
          ),
          Flexible(
            child: Text(
              pageLabel,
              style: context.foText.numeric,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            tooltip: nextTooltip,
            onPressed: page < pages ? () => onPageChanged(page + 1) : null,
          ),
        ],
      ),
    );
  }
}

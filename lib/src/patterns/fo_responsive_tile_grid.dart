import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/fo_context.dart';
import '../tokens/fo_layout.dart';

/// A grid of tiles that keeps every row evenly distributed — **including the
/// last partial one**.
///
/// That is the whole reason it is not a `GridView`. A `GridView` gives the
/// final row's two tiles the same width as a full row's four, leaving them
/// stranded at the left with a gap beside them that reads as missing content.
/// This lays out row by row, so three tiles in a four-column grid split the
/// full width between them.
///
/// The columns are chosen from the grid's **own** width via a `LayoutBuilder`,
/// not from the window class: a grid inside a half-width panel has to reflow
/// for the same reason a phone does, and the window cannot see that.
class FoResponsiveTileGrid<T> extends StatelessWidget {
  /// Creates a tile grid.
  const FoResponsiveTileGrid({
    required this.items,
    required this.itemBuilder,
    this.columnsBuilder,
    super.key,
  });

  /// What to lay out.
  final List<T> items;

  /// Builds one tile.
  final Widget Function(BuildContext context, T item) itemBuilder;

  /// Chooses the column count for a given width. Defaults to 4 / 3 / 2 across
  /// the expanded, medium and compact bands.
  final int Function(double maxWidth)? columnsBuilder;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double gap = context.foSpacing.md;
        final int columns = math.max(
          1,
          (columnsBuilder ?? _defaultColumns)(constraints.maxWidth),
        );

        final List<List<T>> rows = <List<T>>[];
        for (int i = 0; i < items.length; i += columns) {
          rows.add(items.sublist(i, math.min(i + columns, items.length)));
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            for (int r = 0; r < rows.length; r++) ...<Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  for (int c = 0; c < rows[r].length; c++) ...<Widget>[
                    Expanded(child: itemBuilder(context, rows[r][c])),
                    if (c < rows[r].length - 1) SizedBox(width: gap),
                  ],
                ],
              ),
              if (r < rows.length - 1) SizedBox(height: gap),
            ],
          ],
        );
      },
    );
  }

  static int _defaultColumns(double maxWidth) {
    if (maxWidth >= FoLayout.expandedBreakpoint) return 4;
    if (maxWidth >= FoLayout.compactBreakpoint) return 3;
    return 2;
  }
}

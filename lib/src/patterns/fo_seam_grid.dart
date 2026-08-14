import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../primitives/fo_card.dart';
import '../theme/fo_context.dart';
import '../tokens/fo_layout.dart';

/// A grid of cells that reads as **one object** rather than a row of separate
/// cards.
///
/// The difference matters: four stat cards with four shadows are four things
/// the eye has to relate to each other; one seamed block with hairlines
/// between its cells is a single figure with four parts. Reach for this
/// whenever the numbers belong to the same subject.
///
/// **Pass a child count that divides evenly by every step it will reflow
/// through** (4 → 2 → 1). A hole in a grid of hairlines does not read as
/// deliberate whitespace — it reads as a figure that failed to load.
class FoSeamGrid extends StatelessWidget {
  /// Creates a seam grid.
  const FoSeamGrid({
    required this.children,
    this.columnsBuilder,
    super.key,
  });

  /// The cells. Usually `FoSeamCell`s.
  final List<Widget> children;

  /// Chooses the column count for a given width. Defaults to 4 / 2 / 1 across
  /// the expanded, medium and compact bands — each step a clean divisor of the
  /// one above, so a four-cell grid never leaves a hole.
  final int Function(double maxWidth)? columnsBuilder;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();

    return FoCard(
      padding: EdgeInsets.zero,
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final int columns = math.max(
            1,
            math.min(
              children.length,
              (columnsBuilder ?? _defaultColumns)(constraints.maxWidth),
            ),
          );
          final int rowCount = (children.length / columns).ceil();
          final Color seam = context.foColors.edge;

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              for (int r = 0; r < rowCount; r++)
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      for (int c = 0; c < columns; c++)
                        Expanded(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              border: Border(
                                // Seams only between cells — an outer edge
                                // here would double up with the card's own
                                // hairline and read as a heavier line.
                                left: c == 0
                                    ? BorderSide.none
                                    : BorderSide(color: seam),
                                top: r == 0
                                    ? BorderSide.none
                                    : BorderSide(color: seam),
                              ),
                            ),
                            child: r * columns + c < children.length
                                ? children[r * columns + c]
                                : const SizedBox.shrink(),
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  static int _defaultColumns(double maxWidth) {
    if (maxWidth >= FoLayout.expandedBreakpoint) return 4;
    if (maxWidth >= FoLayout.compactBreakpoint) return 2;
    return 1;
  }
}

/// One cell of a [FoSeamGrid] — the padding, so a cell never has to restate
/// it and two cells cannot disagree.
class FoSeamCell extends StatelessWidget {
  /// Creates a cell.
  const FoSeamCell({required this.child, this.padding, super.key});

  /// The cell's content, usually a `FoStatCardContent`.
  final Widget child;

  /// Overrides the default `foSpacing.lg` padding.
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) => Padding(
        padding: padding ?? EdgeInsets.all(context.foSpacing.lg),
        child: child,
      );
}

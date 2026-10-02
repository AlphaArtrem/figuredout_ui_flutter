import 'package:flutter/material.dart';

import '../theme/fo_context.dart';
import '../tokens/fo_layout.dart';
import '../tokens/fo_tokens.dart';
import 'fo_status_chip.dart';

/// One part of a [FoProportionBar] — passed, sent to alter, rejected.
@immutable
class FoProportionPart {
  /// Creates a part.
  const FoProportionPart({
    required this.label,
    required this.value,
    this.tone = FoStatusTone.neutral,
  });

  /// What the part is — "Passed". Caller-supplied.
  final String label;

  /// How many are in it.
  final int value;

  /// Its colour. A status, because these parts are outcomes.
  final FoStatusTone tone;
}

/// One whole split into its outcomes, as a single bar: of 38 checked, 32
/// passed, 5 sent to alter, 1 rejected.
///
/// Segments are in proportion, two points apart, and a part with nothing in
/// it takes no room. [remaining] is the unfilled rest of a known total — what
/// is still to check — drawn as track rather than as a part.
///
/// The bar itself is hidden from a screen reader and [semanticLabel] says the
/// split in words, because a bar is never the only way to read its own
/// numbers. [showLegend] prints the parts under it with their figures.
class FoProportionBar extends StatelessWidget {
  /// Creates a proportion bar.
  const FoProportionBar({
    required this.parts,
    required this.semanticLabel,
    this.remaining = 0,
    this.showLegend = false,
    this.thickness = 8,
    super.key,
  });

  /// The parts, in the order they are drawn.
  final List<FoProportionPart> parts;

  /// The split in words — "32 passed, 5 to alter, 1 rejected, 2 still to
  /// check". Caller-supplied.
  final String semanticLabel;

  /// The unfilled rest of the whole.
  final int remaining;

  /// Prints each part's swatch, label and figure under the bar.
  final bool showLegend;

  /// The bar's height: 8 in a row, 12 as a summary.
  final double thickness;

  static Color _ink(BuildContext context, FoStatusTone tone) => switch (tone) {
        FoStatusTone.neutral => context.foColors.fgSubtle,
        FoStatusTone.primary => context.foColors.primary,
        FoStatusTone.success => context.foColors.success,
        FoStatusTone.warning => context.foColors.warning,
        FoStatusTone.danger => context.foColors.danger,
        FoStatusTone.info => context.foColors.info,
      };

  @override
  Widget build(BuildContext context) {
    final List<FoProportionPart> shown =
        parts.where((FoProportionPart p) => p.value > 0).toList();
    final BorderRadius radius = BorderRadius.circular(thickness / 2);

    final Widget bar = SizedBox(
      height: thickness,
      child: Row(
        children: <Widget>[
          for (int i = 0; i < shown.length; i++) ...<Widget>[
            if (i > 0) const SizedBox(width: 2),
            Expanded(
              flex: shown[i].value,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: _ink(context, shown[i].tone),
                  borderRadius: radius,
                ),
              ),
            ),
          ],
          if (remaining > 0) ...<Widget>[
            if (shown.isNotEmpty) const SizedBox(width: 2),
            Expanded(
              flex: remaining,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: context.foCharts.track,
                  borderRadius: radius,
                ),
              ),
            ),
          ],
          if (shown.isEmpty && remaining <= 0)
            Expanded(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: context.foCharts.track,
                  borderRadius: radius,
                ),
              ),
            ),
        ],
      ),
    );

    return Semantics(
      container: true,
      label: semanticLabel,
      child: ExcludeSemantics(
        child: !showLegend
            ? bar
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  bar,
                  SizedBox(height: context.foSpacing.md),
                  for (final FoProportionPart part in parts)
                    Padding(
                      padding: EdgeInsets.only(bottom: context.foSpacing.xs),
                      child: Row(
                        children: <Widget>[
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: _ink(context, part.tone),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          SizedBox(width: context.foSpacing.sm),
                          Expanded(
                            child: Text(part.label, style: context.foText.body),
                          ),
                          Text(
                            '${part.value}',
                            style: context.foText.numeric.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}

/// One cell of a [FoSizeValueStrip].
@immutable
class FoSizeValue {
  /// Creates a cell.
  const FoSizeValue({
    required this.size,
    required this.value,
    this.caption,
    this.state = FoSizeValueState.plain,
  });

  /// The size — "M". Caller-supplied.
  final String size;

  /// The figure, already formatted.
  final String value;

  /// A line under it — "of 40", "12 ready".
  final String? caption;

  /// How the cell is marked.
  final FoSizeValueState state;
}

/// How a [FoSizeValue] cell is marked.
enum FoSizeValueState {
  /// Nothing to say.
  plain,

  /// The one being worked on — a primary ring.
  current,

  /// Done — loaded all that was ready. Success wash.
  complete,

  /// Needs attention — over, or in conflict. Warning wash and ring.
  flagged,

  /// Nothing here — a zero, quietened.
  empty,
}

/// A row of per-size figures, read-only: loaded of ready, what is inside a
/// carton, what an entry holds.
///
/// The display twin of `FoSizeCountGrid`, which is the input. Equal cells,
/// size as a caption over a mono figure, with an optional [total] cell at the
/// end. More sizes than fit at [minCellWidth] wrap onto a second row rather
/// than shrinking a figure past legibility.
class FoSizeValueStrip extends StatelessWidget {
  /// Creates a strip.
  const FoSizeValueStrip({
    required this.values,
    this.total,
    this.semanticLabel,
    this.minCellWidth = 56,
    super.key,
  });

  /// One cell per size.
  final List<FoSizeValue> values;

  /// A trailing total cell, on the primary wash.
  final FoSizeValue? total;

  /// What the strip shows — "Loaded so far, by size". Read before the cells.
  final String? semanticLabel;

  /// The narrowest a cell may be before the strip wraps.
  final double minCellWidth;

  @override
  Widget build(BuildContext context) {
    final List<FoSizeValue> cells = <FoSizeValue>[
      ...values,
      if (total != null) total!,
    ];
    final double gap = context.foSpacing.xs + 2;

    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: semanticLabel,
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final int perRow =
              ((constraints.maxWidth + gap) / (minCellWidth + gap))
                  .floor()
                  .clamp(1, cells.length);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              for (int start = 0;
                  start < cells.length;
                  start += perRow) ...<Widget>[
                if (start > 0) SizedBox(height: gap),
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      for (int i = start; i < start + perRow; i++) ...<Widget>[
                        if (i > start) SizedBox(width: gap),
                        Expanded(
                          child: i < cells.length
                              ? _Cell(
                                  cell: cells[i],
                                  isTotal:
                                      total != null && i == cells.length - 1,
                                )
                              : const SizedBox.shrink(),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({required this.cell, required this.isTotal});

  final FoSizeValue cell;
  final bool isTotal;

  @override
  Widget build(BuildContext context) {
    final BorderRadius radius = BorderRadius.circular(context.foRadii.md);
    final (Color fill, Color? edge, double width) = switch (cell.state) {
      _ when isTotal => (context.foColors.primarySoft, null, 0.0),
      FoSizeValueState.plain => (
          context.foColors.surfaceRaised,
          context.foColors.edge,
          FoLayout.hairlineWidth
        ),
      FoSizeValueState.current => (
          context.foColors.surfaceRaised,
          context.foColors.primary,
          2.0
        ),
      FoSizeValueState.complete => (
          context.foColors.successSoft,
          context.foColors.success,
          FoLayout.hairlineWidth
        ),
      FoSizeValueState.flagged => (
          context.foColors.warningSoft,
          context.foColors.warning,
          2.0
        ),
      FoSizeValueState.empty => (
          context.foColors.surface,
          context.foColors.edge,
          FoLayout.hairlineWidth
        ),
    };
    final bool quiet = cell.state == FoSizeValueState.empty;

    return MergeSemantics(
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: context.foSpacing.xs,
          vertical: context.foSpacing.sm,
        ),
        decoration: BoxDecoration(color: fill, borderRadius: radius),
        foregroundDecoration: edge == null
            ? null
            : BoxDecoration(
                borderRadius: radius,
                border: Border.all(color: edge, width: width),
              ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(cell.size.toUpperCase(), style: context.foText.caption),
            SizedBox(height: context.foSpacing.xs),
            Text(
              cell.value,
              textAlign: TextAlign.center,
              style: context.foText.numeric.copyWith(
                fontSize: FoTokens.fontTitle,
                fontWeight: FontWeight.w600,
                color: quiet
                    ? context.foColors.fgSubtle
                    : isTotal
                        ? context.foColors.primary
                        : null,
              ),
            ),
            if (cell.caption != null)
              Text(
                cell.caption!,
                textAlign: TextAlign.center,
                style: context.foText.body.copyWith(
                  fontSize: FoTokens.fontCaption,
                  color: context.foColors.fgSubtle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

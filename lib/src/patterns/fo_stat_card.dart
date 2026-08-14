import 'package:flutter/material.dart';

import '../primitives/fo_card.dart';
import '../theme/fo_context.dart';
import '../tokens/fo_tokens.dart';

/// One figure, with its name above and an optional note below.
///
/// The layout is deliberate: the **caption names the value and the value is
/// the value**, which is rule §3.3 made concrete. The name is mono uppercase
/// so it recedes; the figure is mono tabular so a column of them aligns and
/// so a changing number does not shift the ones beside it.
///
/// Use this inside a `FoSeamCell` when the figure belongs to a set, and inside
/// a [FoStatCard] when it stands alone.
class FoStatCardContent extends StatelessWidget {
  /// Creates a stat's content.
  const FoStatCardContent({
    required this.label,
    required this.value,
    this.note,
    this.trend,
    this.chart,
    super.key,
  });

  /// What the figure is. Uppercased here, so the caller passes normal case.
  final String label;

  /// The figure, already formatted. Formatting is the app's — the grouping
  /// separator and the decimal mark are locale decisions this package cannot
  /// make on its behalf.
  final String value;

  /// A line under the figure: a comparison, a period, a caveat.
  final String? note;

  /// Which way the figure has moved, if that is meaningful.
  final FoTrend? trend;

  /// A sparkline or similar, under the note.
  final Widget? chart;

  /// The figure's size. Larger than `display`, because on a stat card the
  /// number is the content rather than a heading over it.
  static const double _valueSize = 30;

  @override
  Widget build(BuildContext context) {
    final (Color? ink, IconData? mark) = switch (trend) {
      FoTrend.up => (context.foColors.success, Icons.arrow_upward),
      FoTrend.down => (context.foColors.danger, Icons.arrow_downward),
      FoTrend.flat => (context.foColors.fgMuted, Icons.remove),
      null => (null, null),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(label.toUpperCase(), style: context.foText.caption),
        SizedBox(height: context.foSpacing.xs),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: <Widget>[
            Flexible(
              child: Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.foText.numeric.copyWith(
                  fontSize: _valueSize,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (mark != null) ...<Widget>[
              SizedBox(width: context.foSpacing.xs),
              Icon(mark, size: FoTokens.iconSmall, color: ink),
            ],
          ],
        ),
        if (note != null) ...<Widget>[
          SizedBox(height: context.foSpacing.xs),
          Text(
            note!,
            style: context.foText.body.copyWith(
              // The note takes the trend's ink when there is one, so the
              // direction is legible without relying on the arrow alone.
              color: ink ?? context.foColors.fgMuted,
            ),
          ),
        ],
        if (chart != null) ...<Widget>[
          SizedBox(height: context.foSpacing.md),
          chart!,
        ],
      ],
    );
  }
}

/// Which way a figure has moved.
///
/// Up is not automatically good — a rise in rejections is not a success — so
/// the caller decides which direction to report, and the colour follows the
/// direction rather than any judgement about it.
enum FoTrend {
  /// Higher than the comparison.
  up,

  /// Lower.
  down,

  /// Unchanged.
  flat,
}

/// A single figure on its own card.
///
/// For a *set* of related figures, reach for a `FoSeamGrid` of
/// [FoStatCardContent]s instead: four separate cards are four things the eye
/// has to relate, where one seamed block is one figure with four parts.
class FoStatCard extends StatelessWidget {
  /// Creates a stat card.
  const FoStatCard({
    required this.label,
    required this.value,
    this.note,
    this.trend,
    this.chart,
    this.onTap,
    super.key,
  });

  /// What the figure is.
  final String label;

  /// The figure, already formatted.
  final String value;

  /// A line under the figure.
  final String? note;

  /// Which way it has moved.
  final FoTrend? trend;

  /// A sparkline or similar.
  final Widget? chart;

  /// Drills into the figure.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => FoCard(
        onTap: onTap,
        semanticLabel: onTap == null ? null : '$label: $value',
        child: FoStatCardContent(
          label: label,
          value: value,
          note: note,
          trend: trend,
          chart: chart,
        ),
      );
}

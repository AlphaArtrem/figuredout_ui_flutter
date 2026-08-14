import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../theme/fo_context.dart';
import '../tokens/fo_layout.dart';

/// The shared `fl_chart` building blocks, so every chart reads the tokens the
/// same way: a recessive grid, axis labels in *text* tokens rather than series
/// colours, tabular figures on every number, and tooltips on the raised
/// surface.
///
/// Axis labels are the rule worth stating: a label drawn in a series colour
/// looks like part of the data. It is chrome, so it takes chrome's ink.
abstract final class FoChartTheme {
  /// The height a chart gets when nobody says otherwise.
  static const double defaultHeight = 220;

  /// **G6.** `fl_chart` animates its entry by default, and that animation
  /// ignores reduced-motion, leaves a line invisible in a background tab and
  /// in print, and makes screenshot tooling race it. Every chart in this
  /// package passes this.
  ///
  /// The web package disables Recharts' entry animation on all four of its
  /// wrappers for exactly the same reasons.
  static const Duration animation = Duration.zero;

  /// `1.2K`, for an axis that has no room for `1,240`.
  static final NumberFormat compactNumber = NumberFormat.compact();

  /// `1,240`, for a tooltip and for the view-as-table fallback, where the
  /// exact figure is the point.
  static final NumberFormat exactNumber = NumberFormat.decimalPattern();

  /// A positive ceiling for a dataset that may be empty or all zero.
  ///
  /// Returns 1.0 rather than 0, because an axis whose max is its min makes
  /// `fl_chart` divide by zero — which on the web target is a silent NaN and a
  /// blank plot rather than a crash.
  static double positiveMax(Iterable<num> values) {
    double max = 0;
    for (final num value in values) {
      final double d = value.toDouble();
      if (d > max) max = d;
    }
    return max > 0 ? max : 1.0;
  }

  /// The style for an axis tick. Chrome's ink, never a series colour.
  static TextStyle axisLabel(BuildContext context) =>
      context.foText.caption.copyWith(
        color: context.foCharts.axisLabel,
        fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
      );

  /// The grid. Recessive by design — it is a ruler, not content.
  static FlGridData grid(BuildContext context, {bool vertical = false}) =>
      FlGridData(
        drawVerticalLine: vertical,
        getDrawingHorizontalLine: (_) => FlLine(
          color: context.foCharts.grid,
          strokeWidth: FoLayout.hairlineWidth,
        ),
        getDrawingVerticalLine: (_) => FlLine(
          color: context.foCharts.grid,
          strokeWidth: FoLayout.hairlineWidth,
        ),
      );

  /// The baseline only. A full box around a plot adds three lines that carry
  /// no information.
  static FlBorderData border(BuildContext context) => FlBorderData(
        border: Border(bottom: BorderSide(color: context.foCharts.grid)),
      );

  /// The left axis, in compact numbers.
  static AxisTitles leftAxis(BuildContext context) => AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 44,
          getTitlesWidget: (double value, TitleMeta meta) {
            // The extremes sit on the plot's own edges and collide with the
            // border and the neighbouring axis.
            if (value == meta.max || value == meta.min) {
              return const SizedBox.shrink();
            }
            return Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Text(
                compactNumber.format(value),
                style: axisLabel(context),
                textAlign: TextAlign.right,
              ),
            );
          },
        ),
      );

  /// No axis at all.
  static const AxisTitles noAxis = AxisTitles();

  /// A bottom axis of `d MMM` labels from ISO `YYYY-MM-DD` keys, thinned so
  /// they never collide.
  static AxisTitles dateAxis(BuildContext context, List<String> dates) {
    final int step = (dates.length / 5).ceil().clamp(1, 31);
    return AxisTitles(
      sideTitles: SideTitles(
        showTitles: true,
        reservedSize: 26,
        interval: 1,
        getTitlesWidget: (double value, TitleMeta meta) {
          final int i = value.round();
          if (i < 0 || i >= dates.length || i % step != 0) {
            return const SizedBox.shrink();
          }
          return Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(formatDayLabel(dates[i]), style: axisLabel(context)),
          );
        },
      ),
    );
  }

  /// A bottom axis of category labels.
  static AxisTitles categoryAxis(BuildContext context, List<String> labels) =>
      AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 26,
          getTitlesWidget: (double value, TitleMeta meta) {
            final int i = value.round();
            if (i < 0 || i >= labels.length) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(labels[i], style: axisLabel(context)),
            );
          },
        ),
      );

  /// `2026-07-16` → `16 Jul`. Falls back to the raw key if it will not parse,
  /// so a malformed date shows as itself rather than as nothing.
  static String formatDayLabel(String isoDate) {
    final DateTime? parsed = DateTime.tryParse(isoDate);
    if (parsed == null) return isoDate;
    return DateFormat('d MMM').format(parsed);
  }

  /// Tooltips for a line chart, on the raised surface.
  static LineTouchData lineTouch(
    BuildContext context, {
    required String Function(int seriesIndex, int spotIndex, double y) label,
  }) =>
      LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (_) => context.foColors.surfaceRaised,
          tooltipBorder: BorderSide(color: context.foColors.edge),
          getTooltipItems: (List<LineBarSpot> spots) => spots
              .map(
                (LineBarSpot s) => LineTooltipItem(
                  label(s.barIndex, s.spotIndex, s.y),
                  _tooltipStyle(context),
                ),
              )
              .toList(),
        ),
      );

  /// Tooltips for a bar chart, on the raised surface.
  static BarTouchData barTouch(
    BuildContext context, {
    required String Function(int groupIndex, int rodIndex, double y) label,
  }) =>
      BarTouchData(
        touchTooltipData: BarTouchTooltipData(
          getTooltipColor: (_) => context.foColors.surfaceRaised,
          tooltipBorder: BorderSide(color: context.foColors.edge),
          getTooltipItem: (
            BarChartGroupData group,
            int groupIndex,
            BarChartRodData rod,
            int rodIndex,
          ) =>
              BarTooltipItem(
            label(groupIndex, rodIndex, rod.toY),
            _tooltipStyle(context),
          ),
        ),
      );

  static TextStyle _tooltipStyle(BuildContext context) =>
      context.foText.numeric.copyWith(color: context.foColors.fg);
}

/// A legend: one dot plus one name per series, wrapping on a narrow window.
///
/// The dot carries the identity and the text stays in text tokens, so a
/// series name never has to be legible in its own series colour — which for
/// a pale categorical hue on a light surface it would not be.
class FoChartLegend extends StatelessWidget {
  /// Creates a legend.
  const FoChartLegend({required this.entries, super.key});

  /// One entry per series.
  final List<({String label, Color color})> entries;

  /// The dot's diameter.
  static const double _dotSize = 10;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: context.foSpacing.lg,
      runSpacing: context.foSpacing.xs,
      children: <Widget>[
        for (final ({String label, Color color}) e in entries)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: _dotSize,
                height: _dotSize,
                decoration: BoxDecoration(
                  color: e.color,
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: context.foSpacing.xs),
              Text(
                e.label,
                style: context.foText.caption,
              ),
            ],
          ),
      ],
    );
  }
}

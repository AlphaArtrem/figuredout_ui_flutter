import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../theme/fo_context.dart';
import 'fo_chart_theme.dart';

/// One named series on a [FoTrendChart]: parallel to the chart's shared date
/// axis, one value per date.
@immutable
class FoTrendSeries {
  /// Creates a series.
  const FoTrendSeries({required this.label, required this.values});

  /// The series' name, for the legend and the tooltip.
  final String label;

  /// One value per date, in the same order.
  final List<num> values;
}

/// A multi-series line chart over a shared list of ISO dates.
///
/// Series colours come from the categorical palette **in fixed order**, so the
/// same series keeps the same colour between renders and between screens — a
/// series that changes colour when another one is filtered out is worse than
/// no colour at all.
///
/// Wrap it in a `FoChartShell`, which owns the empty state and the
/// view-as-table fallback.
class FoTrendChart extends StatelessWidget {
  /// Creates a trend chart.
  const FoTrendChart({
    required this.dates,
    required this.series,
    super.key,
  });

  /// ISO `YYYY-MM-DD` keys shared by every series.
  final List<String> dates;

  /// The series.
  final List<FoTrendSeries> series;

  @override
  Widget build(BuildContext context) {
    return Padding(
      // The final point and its date label otherwise sit on the plot border
      // and get clipped by the card's edge.
      padding: EdgeInsets.only(right: context.foSpacing.md),
      child: LineChart(
        duration: FoChartTheme.animation,
        LineChartData(
          gridData: FoChartTheme.grid(context),
          borderData: FoChartTheme.border(context),
          titlesData: FlTitlesData(
            leftTitles: FoChartTheme.leftAxis(context),
            bottomTitles: FoChartTheme.dateAxis(context, dates),
            topTitles: FoChartTheme.noAxis,
            rightTitles: FoChartTheme.noAxis,
          ),
          lineTouchData: FoChartTheme.lineTouch(
            context,
            label: (int seriesIndex, int spotIndex, double y) {
              final String date = spotIndex < dates.length
                  ? FoChartTheme.formatDayLabel(dates[spotIndex])
                  : '';
              return '${series[seriesIndex].label}\n'
                  '$date · ${FoChartTheme.exactNumber.format(y)}';
            },
          ),
          minY: 0,
          minX: 0,
          maxX: dates.isEmpty ? 0 : (dates.length - 1) + 0.25,
          lineBarsData: <LineChartBarData>[
            for (int i = 0; i < series.length; i++)
              LineChartBarData(
                spots: <FlSpot>[
                  for (int d = 0;
                      d < series[i].values.length && d < dates.length;
                      d++)
                    FlSpot(d.toDouble(), series[i].values[d].toDouble()),
                ],
                color: context.foCharts.series(i),
                dotData: const FlDotData(show: false),
              ),
          ],
        ),
      ),
    );
  }
}

/// One category on a [FoBarChart] — a line, a shift, a machine — with one
/// value per series.
@immutable
class FoBarGroup {
  /// Creates a group.
  const FoBarGroup({required this.label, required this.values});

  /// The category's name.
  final String label;

  /// One value per series, aligned to the chart's `seriesLabels`.
  final List<num> values;
}

/// A grouped bar chart, with an optional dashed target rule.
class FoBarChart extends StatelessWidget {
  /// Creates a bar chart.
  const FoBarChart({
    required this.groups,
    required this.seriesLabels,
    this.targetValue,
    this.targetLabel,
    super.key,
  });

  /// The categories.
  final List<FoBarGroup> groups;

  /// One label per series.
  final List<String> seriesLabels;

  /// A horizontal rule — today's input as the target for today's output.
  final double? targetValue;

  /// The rule's label.
  final String? targetLabel;

  /// The bar's width. Thin, so a group of three still reads as one category.
  static const double _barWidth = 14;

  /// The gap inside a group — enough to separate, not enough to split it.
  static const double _barsSpace = 2;

  @override
  Widget build(BuildContext context) {
    return BarChart(
      duration: FoChartTheme.animation,
      BarChartData(
        gridData: FoChartTheme.grid(context),
        borderData: FoChartTheme.border(context),
        titlesData: FlTitlesData(
          leftTitles: FoChartTheme.leftAxis(context),
          bottomTitles: FoChartTheme.categoryAxis(
            context,
            groups.map((FoBarGroup g) => g.label).toList(),
          ),
          topTitles: FoChartTheme.noAxis,
          rightTitles: FoChartTheme.noAxis,
        ),
        barTouchData: FoChartTheme.barTouch(
          context,
          label: (int groupIndex, int rodIndex, double y) {
            final String group = groups[groupIndex].label;
            final String name =
                rodIndex < seriesLabels.length ? seriesLabels[rodIndex] : '';
            return '$group · $name\n${FoChartTheme.exactNumber.format(y)}';
          },
        ),
        extraLinesData: targetValue == null
            ? null
            : ExtraLinesData(
                horizontalLines: <HorizontalLine>[
                  HorizontalLine(
                    y: targetValue!,
                    color: context.foCharts.targetLine,
                    strokeWidth: 1.5,
                    dashArray: const <int>[6, 4],
                    label: targetLabel == null
                        ? null
                        : HorizontalLineLabel(
                            show: true,
                            alignment: Alignment.topRight,
                            style: FoChartTheme.axisLabel(context),
                            labelResolver: (_) => targetLabel!,
                          ),
                  ),
                ],
              ),
        barGroups: <BarChartGroupData>[
          for (int g = 0; g < groups.length; g++)
            BarChartGroupData(
              x: g,
              barsSpace: _barsSpace,
              barRods: <BarChartRodData>[
                for (int s = 0; s < groups[g].values.length; s++)
                  BarChartRodData(
                    toY: groups[g].values[s].toDouble(),
                    width: _barWidth,
                    color: context.foCharts.series(s),
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(context.foRadii.sm),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

/// A tiny axis-less trend line for a KPI tile.
///
/// Non-interactive by design: the tile it sits on carries the tap, and a
/// sparkline with its own tooltip competes with it for the same gesture.
class FoSparkline extends StatelessWidget {
  /// Creates a sparkline.
  const FoSparkline({
    required this.values,
    this.height = 32,
    this.color,
    super.key,
  });

  /// The points.
  final List<num> values;

  /// How tall.
  final double height;

  /// Defaults to the first categorical hue.
  final Color? color;

  /// The wash under the line — a hint of volume, not a filled area chart.
  static const double _fillAlpha = 0.08;

  @override
  Widget build(BuildContext context) {
    // One point is not a trend, and fl_chart cannot draw a line through it.
    if (values.length < 2) return SizedBox(height: height);
    final Color line = color ?? context.foCharts.series(0);

    return SizedBox(
      height: height,
      child: LineChart(
        duration: FoChartTheme.animation,
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineTouchData: const LineTouchData(enabled: false),
          minY: 0,
          lineBarsData: <LineChartBarData>[
            LineChartBarData(
              spots: <FlSpot>[
                for (int i = 0; i < values.length; i++)
                  FlSpot(i.toDouble(), values[i].toDouble()),
              ],
              color: line,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: line.withValues(alpha: _fillAlpha),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One category on a [FoParetoChart].
@immutable
class FoParetoItem {
  /// Creates an item.
  const FoParetoItem({
    required this.label,
    required this.qty,
    required this.cumulativePct,
  });

  /// The category's name.
  final String label;

  /// How many.
  final int qty;

  /// The running share of the total, 0–100.
  final double cumulativePct;
}

/// A pareto chart: quantity bars, biggest first, with a cumulative-percentage
/// line over them.
///
/// The line is normalised onto the bars' scale so there is **one** y axis.
/// Dual axes let the author choose where the line crosses the bars, which
/// means the reader cannot trust the crossing — and the crossing is the whole
/// point of a pareto. The exact percentage is in the tooltip and in the
/// shell's view-as-table.
class FoParetoChart extends StatelessWidget {
  /// Creates a pareto chart.
  const FoParetoChart({
    required this.items,
    required this.qtyLabel,
    required this.cumulativeLabel,
    super.key,
  });

  /// The categories, already sorted biggest first.
  final List<FoParetoItem> items;

  /// The bars' name, for the legend.
  final String qtyLabel;

  /// The line's name, for the legend.
  final String cumulativeLabel;

  /// The line's hue index. Not 1 — the bars are 0, and 2 is far enough away
  /// in the categorical order to read as a different kind of thing.
  static const int _lineSeriesIndex = 2;

  /// The bar's width.
  static const double _barWidth = 18;

  @override
  Widget build(BuildContext context) {
    final double maxQty = FoChartTheme.positiveMax(
      items.map((FoParetoItem i) => i.qty),
    );

    return Stack(
      children: <Widget>[
        BarChart(
          duration: FoChartTheme.animation,
          BarChartData(
            maxY: maxQty,
            gridData: FoChartTheme.grid(context),
            borderData: FoChartTheme.border(context),
            titlesData: FlTitlesData(
              leftTitles: FoChartTheme.leftAxis(context),
              bottomTitles: FoChartTheme.categoryAxis(
                context,
                items.map((FoParetoItem i) => i.label).toList(),
              ),
              topTitles: FoChartTheme.noAxis,
              rightTitles: FoChartTheme.noAxis,
            ),
            barTouchData: FoChartTheme.barTouch(
              context,
              label: (int groupIndex, int rodIndex, double y) {
                final FoParetoItem item = items[groupIndex];
                return '${item.label}\n'
                    '${FoChartTheme.exactNumber.format(item.qty)} · '
                    '${item.cumulativePct.toStringAsFixed(0)}%';
              },
            ),
            barGroups: <BarChartGroupData>[
              for (int i = 0; i < items.length; i++)
                BarChartGroupData(
                  x: i,
                  barRods: <BarChartRodData>[
                    BarChartRodData(
                      toY: items[i].qty.toDouble(),
                      width: _barWidth,
                      color: context.foCharts.series(0),
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(context.foRadii.sm),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
        // The line rides on the bars' own scale, drawn over them with no axes
        // and no touch of its own so the bars keep the gesture.
        IgnorePointer(
          child: LineChart(
            duration: FoChartTheme.animation,
            LineChartData(
              minY: 0,
              maxY: maxQty,
              minX: 0,
              maxX: (items.length - 1).toDouble().clamp(0, double.infinity),
              gridData: const FlGridData(show: false),
              titlesData: const FlTitlesData(show: false),
              borderData: FlBorderData(show: false),
              lineTouchData: const LineTouchData(enabled: false),
              lineBarsData: <LineChartBarData>[
                LineChartBarData(
                  spots: <FlSpot>[
                    for (int i = 0; i < items.length; i++)
                      FlSpot(
                        i.toDouble(),
                        items[i].cumulativePct / 100 * maxQty,
                      ),
                  ],
                  color: context.foCharts.series(_lineSeriesIndex),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// One stage of a [FoStageFunnel].
@immutable
class FoFunnelStage {
  /// Creates a stage.
  const FoFunnelStage({required this.label, required this.qty});

  /// The stage's name.
  final String label;

  /// How many reached it.
  final int qty;
}

/// A horizontal stage funnel: one bar per stage, width proportional to
/// quantity, on a single hue.
///
/// Hand-built because `fl_chart` has no funnel — and because the useful part
/// is not the bars but the plain-language gap spelled out between them. "2,400
/// waiting after Cutting" is the sentence a shop-floor supervisor acts on; the
/// shape alone tells them there is a bottleneck but not how big.
///
/// One hue, not six: the stages are one pipeline, and colouring them
/// categorically would suggest they are unrelated things.
class FoStageFunnel extends StatelessWidget {
  /// Creates a stage funnel.
  const FoStageFunnel({required this.stages, this.gapLabel, super.key});

  /// The stages, in pipeline order.
  final List<FoFunnelStage> stages;

  /// Builds the between-stages caption, e.g.
  /// `(gap, previous) => '2,400 waiting after Cutting'`. Caller-supplied, so
  /// it can be localized. Without it the gaps are not shown at all.
  final String Function(int gap, String previousLabel)? gapLabel;

  static const double _labelWidth = 110;
  static const double _barHeight = 18;

  /// Below this the label moves above its bar rather than beside it.
  static const double _stackLabelBelow = 280;

  @override
  Widget build(BuildContext context) {
    final double maxQty = FoChartTheme.positiveMax(
      stages.map((FoFunnelStage s) => s.qty),
    );

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool stacked = constraints.maxWidth < _stackLabelBelow;

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            for (int i = 0; i < stages.length; i++) ...<Widget>[
              if (i > 0 &&
                  gapLabel != null &&
                  stages[i - 1].qty - stages[i].qty > 0)
                Padding(
                  padding: EdgeInsets.only(
                    left: context.foSpacing.sm,
                    bottom: context.foSpacing.xs,
                  ),
                  child: Text(
                    gapLabel!(
                      stages[i - 1].qty - stages[i].qty,
                      stages[i - 1].label,
                    ),
                    style: context.foText.caption,
                  ),
                ),
              // One announcement per stage: the bar carries no text, so name
              // and quantity would otherwise be read as unrelated fragments.
              Semantics(
                container: true,
                label: '${stages[i].label}: '
                    '${FoChartTheme.exactNumber.format(stages[i].qty)}',
                excludeSemantics: true,
                child: _Stage(
                  stage: stages[i],
                  fraction: stages[i].qty / maxQty,
                  stacked: stacked,
                ),
              ),
              if (i < stages.length - 1) SizedBox(height: context.foSpacing.md),
            ],
          ],
        );
      },
    );
  }
}

class _Stage extends StatelessWidget {
  const _Stage({
    required this.stage,
    required this.fraction,
    required this.stacked,
  });

  final FoFunnelStage stage;
  final double fraction;
  final bool stacked;

  @override
  Widget build(BuildContext context) {
    final Widget label = Text(stage.label, style: context.foText.label);
    final Widget value = Text(
      FoChartTheme.exactNumber.format(stage.qty),
      style: context.foText.numeric,
    );

    final Widget bar = Row(
      children: <Widget>[
        Expanded(
          child: Container(
            height: FoStageFunnel._barHeight,
            decoration: BoxDecoration(
              color: context.foColors.surfaceSunken,
              borderRadius: BorderRadius.circular(context.foRadii.sm),
            ),
            child: FractionallySizedBox(
              alignment: AlignmentDirectional.centerStart,
              widthFactor: fraction.clamp(0.0, 1.0),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: context.foCharts.sequential,
                  borderRadius: BorderRadius.circular(context.foRadii.sm),
                ),
              ),
            ),
          ),
        ),
        SizedBox(width: context.foSpacing.sm),
        value,
      ],
    );

    if (stacked) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          label,
          SizedBox(height: context.foSpacing.xs),
          bar,
        ],
      );
    }

    return Row(
      children: <Widget>[
        SizedBox(width: FoStageFunnel._labelWidth, child: label),
        SizedBox(width: context.foSpacing.sm),
        Expanded(child: bar),
      ],
    );
  }
}

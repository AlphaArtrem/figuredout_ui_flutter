import 'package:figuredout_ui/figuredout_ui.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

import '../../support/doc_page.dart';

const List<String> _dates = <String>[
  '2026-08-08',
  '2026-08-09',
  '2026-08-10',
  '2026-08-11',
  '2026-08-12',
  '2026-08-13',
  '2026-08-14',
];

const List<num> _cut = <num>[1240, 1180, 1310, 980, 1420, 1360, 1290];
const List<num> _stitched = <num>[1100, 1040, 1180, 900, 1260, 1210, 1150];

const FoChartShellCopy _copy = FoChartShellCopy(
  emptyTitle: 'Nothing recorded for this period yet.',
  showTable: 'View as table',
  showChart: 'View as chart',
  errorTitle: 'Could not load this chart',
  retryLabel: 'Retry',
);

/// Every chart, each inside the shell that owns its empty state and its
/// view-as-table fallback.
class Charts extends StatelessWidget {
  /// Creates the charts page.
  const Charts({super.key});

  @override
  Widget build(BuildContext context) {
    final FoChartColors palette = context.foCharts;

    return DocPage(
      title: 'Charts',
      lede: 'Every chart goes through FoChartShell. Press "View as table" on '
          'any of them: without that fallback a chart is the only way to read '
          'its own numbers, and it cannot be read by a screen reader, at 1.6x '
          'text scale, or by anyone who needs the exact figure.',
      children: <Widget>[
        DocSection(
          title: 'Trend',
          child: FoChartShell(
            copy: _copy,
            columnLabels: const <String>['Cut', 'Stitched'],
            legend: FoChartLegend(
              entries: <({String label, Color color})>[
                (label: 'Cut', color: palette.series(0)),
                (label: 'Stitched', color: palette.series(1)),
              ],
            ),
            tableRows: <FoChartTableRow>[
              for (int i = 0; i < _dates.length; i++)
                FoChartTableRow(
                  label: FoChartTheme.formatDayLabel(_dates[i]),
                  values: <String>[
                    FoChartTheme.exactNumber.format(_cut[i]),
                    FoChartTheme.exactNumber.format(_stitched[i]),
                  ],
                ),
            ],
            chart: const FoTrendChart(
              dates: _dates,
              series: <FoTrendSeries>[
                FoTrendSeries(label: 'Cut', values: _cut),
                FoTrendSeries(label: 'Stitched', values: _stitched),
              ],
            ),
          ),
        ),
        DocSection(
          title: 'Bars, with a target rule',
          child: FoChartShell(
            copy: _copy,
            columnLabels: const <String>['In', 'Out'],
            legend: FoChartLegend(
              entries: <({String label, Color color})>[
                (label: 'In', color: palette.series(0)),
                (label: 'Out', color: palette.series(1)),
              ],
            ),
            tableRows: const <FoChartTableRow>[
              FoChartTableRow(
                label: 'Line A',
                values: <String>['1,240', '1,100'],
              ),
              FoChartTableRow(label: 'Line B', values: <String>['980', '910']),
              FoChartTableRow(
                label: 'Line C',
                values: <String>['1,420', '1,180'],
              ),
            ],
            chart: const FoBarChart(
              groups: <FoBarGroup>[
                FoBarGroup(label: 'Line A', values: <num>[1240, 1100]),
                FoBarGroup(label: 'Line B', values: <num>[980, 910]),
                FoBarGroup(label: 'Line C', values: <num>[1420, 1180]),
              ],
              seriesLabels: <String>['In', 'Out'],
              targetValue: 1200,
              targetLabel: 'Target',
            ),
          ),
        ),
        const DocSection(
          title: 'Pareto — one y axis, never two',
          child: FoChartShell(
            copy: _copy,
            columnLabels: <String>['Pieces', 'Running %'],
            tableRows: <FoChartTableRow>[
              FoChartTableRow(label: 'Fraying', values: <String>['142', '38%']),
              FoChartTableRow(
                label: 'Skipped stitch',
                values: <String>['96', '64%'],
              ),
              FoChartTableRow(
                label: 'Mis-cut',
                values: <String>['74', '84%'],
              ),
              FoChartTableRow(label: 'Stain', values: <String>['58', '100%']),
            ],
            chart: FoParetoChart(
              items: <FoParetoItem>[
                FoParetoItem(label: 'Fraying', qty: 142, cumulativePct: 38),
                FoParetoItem(label: 'Skipped', qty: 96, cumulativePct: 64),
                FoParetoItem(label: 'Mis-cut', qty: 74, cumulativePct: 84),
                FoParetoItem(label: 'Stain', qty: 58, cumulativePct: 100),
              ],
              qtyLabel: 'Pieces',
              cumulativeLabel: 'Running total',
            ),
          ),
        ),
        DocSection(
          title: 'Stage funnel — the gaps are the point',
          child: FoChartShell(
            copy: _copy,
            height: 300,
            columnLabels: const <String>['Pieces'],
            tableRows: const <FoChartTableRow>[
              FoChartTableRow(label: 'Cutting', values: <String>['4,000']),
              FoChartTableRow(label: 'Stitching', values: <String>['3,100']),
              FoChartTableRow(label: 'Finishing', values: <String>['2,450']),
              FoChartTableRow(label: 'Packing', values: <String>['2,300']),
            ],
            chart: FoStageFunnel(
              stages: const <FoFunnelStage>[
                FoFunnelStage(label: 'Cutting', qty: 4000),
                FoFunnelStage(label: 'Stitching', qty: 3100),
                FoFunnelStage(label: 'Finishing', qty: 2450),
                FoFunnelStage(label: 'Packing', qty: 2300),
              ],
              gapLabel: (int gap, String previous) =>
                  '${FoChartTheme.exactNumber.format(gap)} waiting after '
                  '$previous',
            ),
          ),
        ),
        DocSection(
          title: 'Sparkline — no shell, it lives on a tile',
          child: FoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('CUT TODAY', style: context.foText.caption),
                SizedBox(height: context.foSpacing.xs),
                Text(
                  '1,290',
                  style: context.foText.numeric.copyWith(
                    fontSize: FoTokens.fontDisplay,
                  ),
                ),
                SizedBox(height: context.foSpacing.sm),
                const FoSparkline(values: _cut),
              ],
            ),
          ),
        ),
        DocSection(
          title: 'The shell without data',
          child: Column(
            children: <Widget>[
              const FoChartShell(
                copy: _copy,
                height: 140,
                columnLabels: <String>['Cut'],
                tableRows: <FoChartTableRow>[],
                chart: SizedBox.shrink(),
              ),
              SizedBox(height: context.foSpacing.lg),
              FoChartShell(
                copy: _copy,
                height: 160,
                columnLabels: const <String>['Cut'],
                tableRows: const <FoChartTableRow>[],
                error: 'Connection refused',
                onRetry: () {},
                chart: const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Every chart, each in its shell. Press "View as table".
@widgetbook.UseCase(name: 'Chart shell', type: FoChartShell, path: '04 Charts')
Widget buildChartShell(BuildContext context) => const Charts();

/// A multi-series line over a shared date axis.
@widgetbook.UseCase(name: 'Trend', type: FoTrendChart, path: '04 Charts')
Widget buildTrendChart(BuildContext context) => const Charts();

/// Grouped bars with a dashed target rule.
@widgetbook.UseCase(name: 'Bars', type: FoBarChart, path: '04 Charts')
Widget buildBarChart(BuildContext context) => const Charts();

/// Quantity bars with a cumulative line on the same axis.
@widgetbook.UseCase(name: 'Pareto', type: FoParetoChart, path: '04 Charts')
Widget buildParetoChart(BuildContext context) => const Charts();

/// The pipeline, with the waiting spelled out between stages.
@widgetbook.UseCase(name: 'Funnel', type: FoStageFunnel, path: '04 Charts')
Widget buildStageFunnel(BuildContext context) => const Charts();

/// An axis-less line for a KPI tile.
@widgetbook.UseCase(name: 'Sparkline', type: FoSparkline, path: '04 Charts')
Widget buildSparkline(BuildContext context) => const Charts();

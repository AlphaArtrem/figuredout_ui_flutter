import 'package:figuredout_ui/figuredout_ui.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/pump.dart';

const FoChartShellCopy _copy = FoChartShellCopy(
  emptyTitle: 'Nothing to plot yet.',
  showTable: 'View as table',
  showChart: 'View as chart',
  errorTitle: 'Could not load',
  retryLabel: 'Retry',
);

const List<FoChartTableRow> _rows = <FoChartTableRow>[
  FoChartTableRow(label: '16 Jul', values: <String>['1,240']),
  FoChartTableRow(label: '17 Jul', values: <String>['880']),
];

void main() {
  group('FoChartShell', () {
    /// The highest-value thing borrowed from the web package: without the
    /// fallback, a chart is the only way to read its own numbers — and it
    /// cannot be read by a screen reader, at 1.6x text scale, or by anyone
    /// who needs the exact figure rather than the shape.
    testWidgets('view-as-table renders the same numbers as text', (
      WidgetTester tester,
    ) async {
      await pumpFo(
        tester,
        surfaceSize: const Size(900, 800),
        child: const FoChartShell(
          copy: _copy,
          columnLabels: <String>['Cut'],
          tableRows: _rows,
          chart: Text('the plot'),
        ),
      );

      expect(find.text('the plot'), findsOneWidget);
      expect(find.text('1,240'), findsNothing);

      await tester.tap(find.text('View as table'));
      await tester.pumpAndSettle();

      expect(find.text('the plot'), findsNothing);
      expect(find.text('1,240'), findsOneWidget);
      expect(find.text('880'), findsOneWidget);
    });

    testWidgets('no rows means the shell shows the empty state, not the chart',
        (
      WidgetTester tester,
    ) async {
      await pumpFo(
        tester,
        surfaceSize: const Size(900, 800),
        child: const FoChartShell(
          copy: _copy,
          columnLabels: <String>['Cut'],
          tableRows: <FoChartTableRow>[],
          chart: Text('the plot'),
        ),
      );

      // So no chart has to decide for itself what "nothing to plot" looks
      // like, which is how five charts grow five different empty states.
      expect(find.text('Nothing to plot yet.'), findsOneWidget);
      expect(find.text('the plot'), findsNothing);
    });

    testWidgets('an error carries its retry', (WidgetTester tester) async {
      int retries = 0;
      await pumpFo(
        tester,
        surfaceSize: const Size(900, 800),
        child: FoChartShell(
          copy: _copy,
          columnLabels: const <String>['Cut'],
          tableRows: _rows,
          error: 'Connection refused',
          onRetry: () => retries++,
          chart: const Text('the plot'),
        ),
      );

      expect(find.text('Could not load'), findsOneWidget);
      expect(find.text('Connection refused'), findsOneWidget);
      await tester.tap(find.text('Retry'));
      expect(retries, 1);
    });

    testWidgets('loading shows a skeleton, not a spinner', (
      WidgetTester tester,
    ) async {
      await pumpFo(
        tester,
        surfaceSize: const Size(900, 800),
        child: const FoChartShell(
          copy: _copy,
          columnLabels: <String>['Cut'],
          tableRows: _rows,
          loading: true,
          chart: Text('the plot'),
        ),
      );
      await tester.pump();
      expect(find.byType(FoSkeleton), findsOneWidget);
    });
  });

  group('FoChartTheme', () {
    /// G6. `fl_chart` animates its entry by default, and that animation
    /// ignores reduced-motion, leaves a line invisible in a background tab and
    /// in print, and makes screenshot tooling race it.
    test('the entry animation is off', () {
      expect(FoChartTheme.animation, Duration.zero);
    });

    test('positiveMax never returns zero', () {
      // An axis whose max equals its min makes fl_chart divide by zero, which
      // on web is a silent NaN and a blank plot rather than a crash.
      expect(FoChartTheme.positiveMax(const <num>[]), 1.0);
      expect(FoChartTheme.positiveMax(const <num>[0, 0]), 1.0);
      expect(FoChartTheme.positiveMax(const <num>[3, 9, 4]), 9.0);
    });

    test('a malformed date shows as itself rather than as nothing', () {
      expect(FoChartTheme.formatDayLabel('not-a-date'), 'not-a-date');
      expect(FoChartTheme.formatDayLabel('2026-07-16'), '16 Jul');
    });

    testWidgets('an axis label takes chrome ink, never a series colour', (
      WidgetTester tester,
    ) async {
      late TextStyle style;
      await pumpFo(
        tester,
        child: Builder(
          builder: (BuildContext context) {
            style = FoChartTheme.axisLabel(context);
            return const SizedBox.shrink();
          },
        ),
      );

      expect(style.color, FoChartColors.light.axisLabel);
      for (final Color series in FoChartColors.light.categorical) {
        expect(style.color, isNot(series));
      }
    });
  });

  group('charts render', () {
    testWidgets('every chart draws without exploding', (
      WidgetTester tester,
    ) async {
      final Map<String, Widget> charts = <String, Widget>{
        'trend': const FoTrendChart(
          dates: <String>['2026-07-16', '2026-07-17'],
          series: <FoTrendSeries>[
            FoTrendSeries(label: 'Cut', values: <num>[1240, 880]),
          ],
        ),
        'bar': const FoBarChart(
          groups: <FoBarGroup>[
            FoBarGroup(label: 'Line A', values: <num>[1240, 900]),
          ],
          seriesLabels: <String>['In', 'Out'],
        ),
        'sparkline': const FoSparkline(values: <num>[1, 4, 2, 8]),
        'pareto': const FoParetoChart(
          items: <FoParetoItem>[
            FoParetoItem(label: 'Fray', qty: 40, cumulativePct: 50),
            FoParetoItem(label: 'Skip', qty: 40, cumulativePct: 100),
          ],
          qtyLabel: 'Pieces',
          cumulativeLabel: 'Running total',
        ),
        'funnel': const FoStageFunnel(
          stages: <FoFunnelStage>[
            FoFunnelStage(label: 'Cutting', qty: 4000),
            FoFunnelStage(label: 'Stitching', qty: 1600),
          ],
        ),
      };

      for (final MapEntry<String, Widget> entry in charts.entries) {
        await pumpFo(
          tester,
          surfaceSize: const Size(900, 800),
          child: SizedBox(height: 240, child: entry.value),
        );
        await tester.pump();
        expect(tester.takeException(), isNull, reason: entry.key);
      }
    });

    testWidgets('an all-zero dataset does not blank the plot', (
      WidgetTester tester,
    ) async {
      await pumpFo(
        tester,
        surfaceSize: const Size(900, 800),
        child: const SizedBox(
          height: 240,
          child: FoParetoChart(
            items: <FoParetoItem>[
              FoParetoItem(label: 'None', qty: 0, cumulativePct: 0),
            ],
            qtyLabel: 'Pieces',
            cumulativeLabel: 'Running total',
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('a one-point sparkline draws nothing rather than a dot', (
      WidgetTester tester,
    ) async {
      await pumpFo(tester, child: const FoSparkline(values: <num>[5]));
      // One point is not a trend, and fl_chart cannot draw a line through it.
      expect(find.byType(LineChart), findsNothing);
    });

    testWidgets('the funnel announces each stage as one thing', (
      WidgetTester tester,
    ) async {
      await pumpFo(
        tester,
        surfaceSize: const Size(900, 800),
        child: const FoStageFunnel(
          stages: <FoFunnelStage>[FoFunnelStage(label: 'Cutting', qty: 4000)],
        ),
      );

      // The bar carries no text of its own, so name and quantity would
      // otherwise be read as unrelated fragments.
      expect(find.bySemanticsLabel('Cutting: 4,000'), findsOneWidget);
    });
  });
}

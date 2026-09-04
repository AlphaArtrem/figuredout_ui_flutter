import 'package:flutter/material.dart';

import '../primitives/fo_button.dart';
import '../primitives/fo_skeleton.dart';
import '../theme/fo_context.dart';
import 'fo_chart_theme.dart';

/// The copy a [FoChartShell] needs.
///
/// Required rather than defaulted, because the package holds no user-facing
/// strings.
@immutable
class FoChartShellCopy {
  /// Creates the shell's copy.
  const FoChartShellCopy({
    required this.emptyTitle,
    required this.showTable,
    required this.showChart,
    this.errorTitle,
    this.retryLabel,
  });

  /// What to say when there is nothing to plot.
  final String emptyTitle;

  /// The toggle's label while the chart is showing.
  final String showTable;

  /// The toggle's label while the table is showing.
  final String showChart;

  /// The heading for a failed load.
  final String? errorTitle;

  /// The retry button's label.
  final String? retryLabel;
}

/// One row of the view-as-table fallback.
@immutable
class FoChartTableRow {
  /// Creates a table row.
  const FoChartTableRow({required this.label, required this.values});

  /// What the row is — a date, a category, a stage.
  final String label;

  /// Its values, in the same order as the shell's column headings.
  final List<String> values;
}

/// The frame every chart goes through.
///
/// This is the highest-value thing the Flutter package borrows from the web
/// one. Left to themselves, five charts grow five different empty states and
/// five different loading treatments — and, more importantly, **each becomes
/// the only way to read its own numbers.** A chart cannot be read by a screen
/// reader, cannot be read at 1.6× text scale, and cannot be read at all by
/// someone who needs the exact figure rather than the shape.
///
/// So the shell owns three things: loading, empty, and a view-as-table toggle
/// that renders the same data as text. Every `FoChart*` is designed to sit
/// inside one.
class FoChartShell extends StatefulWidget {
  /// Creates a chart shell.
  const FoChartShell({
    required this.chart,
    required this.copy,
    required this.columnLabels,
    required this.tableRows,
    this.loading = false,
    this.error,
    this.onRetry,
    this.height = FoChartTheme.defaultHeight,
    this.legend,
    super.key,
  });

  /// The chart itself.
  final Widget chart;

  /// The shell's strings.
  final FoChartShellCopy copy;

  /// The table's column headings, excluding the leading label column.
  final List<String> columnLabels;

  /// The same numbers the chart is drawing, as text.
  ///
  /// Empty means there is nothing to plot, and the shell shows its empty
  /// state — so a chart never has to decide that for itself.
  final List<FoChartTableRow> tableRows;

  /// Shows skeletons in the chart's shape.
  final bool loading;

  /// A failed load.
  final String? error;

  /// Reloads.
  final VoidCallback? onRetry;

  /// The plot's height.
  final double height;

  /// An optional legend, shown above the chart and hidden with it.
  final Widget? legend;

  @override
  State<FoChartShell> createState() => _FoChartShellState();
}

class _FoChartShellState extends State<FoChartShell> {
  bool _asTable = false;

  @override
  Widget build(BuildContext context) {
    if (widget.loading) {
      return SizedBox(
        height: widget.height,
        child: FoSkeleton.box(height: widget.height),
      );
    }

    final String? failure = widget.error;
    if (failure != null && failure.isNotEmpty) {
      return _Message(
        height: widget.height,
        title: widget.copy.errorTitle ?? failure,
        detail: widget.copy.errorTitle == null ? null : failure,
        actionLabel: widget.onRetry == null ? null : widget.copy.retryLabel,
        onAction: widget.onRetry,
      );
    }

    if (widget.tableRows.isEmpty) {
      return _Message(height: widget.height, title: widget.copy.emptyTitle);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: FoButton(
            label: _asTable ? widget.copy.showChart : widget.copy.showTable,
            variant: FoButtonVariant.clear,
            icon: _asTable ? Icons.show_chart : Icons.table_rows_outlined,
            onPressed: () => setState(() => _asTable = !_asTable),
          ),
        ),
        SizedBox(height: context.foSpacing.sm),
        if (_asTable)
          _ValueTable(
            columnLabels: widget.columnLabels,
            rows: widget.tableRows,
          )
        else ...<Widget>[
          if (widget.legend != null) ...<Widget>[
            widget.legend!,
            SizedBox(height: context.foSpacing.md),
          ],
          SizedBox(height: widget.height, child: widget.chart),
        ],
      ],
    );
  }
}

/// The chart's numbers as text. Deliberately a plain table rather than a
/// `FoDataTable`: it has no paging, no sorting and no card layout, and it must
/// stay legible at 1.6× text scale, which a fixed-height row cannot.
class _ValueTable extends StatelessWidget {
  const _ValueTable({required this.columnLabels, required this.rows});

  final List<String> columnLabels;
  final List<FoChartTableRow> rows;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(context.foRadii.md),
        border: Border.all(color: context.foColors.edge),
      ),
      child: Column(
        children: <Widget>[
          _row(
            context,
            label: '',
            values: columnLabels,
            style: context.foText.caption,
            ground: context.foColors.surfaceSunken,
            uppercase: true,
          ),
          for (int i = 0; i < rows.length; i++)
            _row(
              context,
              label: rows[i].label,
              values: rows[i].values,
              style: context.foText.numeric,
              divided: i > 0,
            ),
        ],
      ),
    );
  }

  Widget _row(
    BuildContext context, {
    required String label,
    required List<String> values,
    required TextStyle style,
    Color? ground,
    bool uppercase = false,
    bool divided = false,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.foSpacing.md,
        vertical: context.foSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: ground,
        border: divided
            ? Border(
                top: BorderSide(color: context.foColors.edge),
              )
            : null,
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            flex: 2,
            child: Text(
              uppercase ? label.toUpperCase() : label,
              style: uppercase ? style : context.foText.label,
            ),
          ),
          for (final String value in values)
            Expanded(
              child: Text(
                uppercase ? value.toUpperCase() : value,
                textAlign: TextAlign.end,
                style: style,
              ),
            ),
        ],
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({
    required this.height,
    required this.title,
    this.detail,
    this.actionLabel,
    this.onAction,
  });

  final double height;
  final String title;
  final String? detail;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    // **A floor, not a fixed height.** This is the slot a chart would have
    // occupied, and holding it keeps a loading, empty or failed chart from
    // making the page jump — but the thing in it here is a sentence, and a
    // sentence at twice the system text size is taller than a plot's height.
    // A `SizedBox` clipped it and painted the rest past the bottom.
    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: height),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              title,
              textAlign: TextAlign.center,
              style: context.foText.body.copyWith(
                color: context.foColors.fgMuted,
              ),
            ),
            if (detail != null) ...<Widget>[
              SizedBox(height: context.foSpacing.xs),
              Text(
                detail!,
                textAlign: TextAlign.center,
                style: context.foText.caption,
              ),
            ],
            if (actionLabel != null && onAction != null) ...<Widget>[
              SizedBox(height: context.foSpacing.md),
              FoButton(
                label: actionLabel!,
                variant: FoButtonVariant.secondary,
                icon: Icons.refresh,
                onPressed: onAction,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

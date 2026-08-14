import 'dart:math' as math;

import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';

import '../primitives/fo_card.dart';
import '../primitives/fo_skeleton.dart';
import '../theme/fo_context.dart';
import '../theme/fo_window_class.dart';
import '../tokens/fo_layout.dart';
import 'fo_empty_state.dart';

/// How much room a column gets relative to its neighbours.
enum FoColumnSize {
  /// A short value: a status, a count, a date.
  s,

  /// The default.
  m,

  /// A name, a description — the column the row is identified by.
  l,
}

/// One column of a [FoDataTable].
@immutable
class FoTableColumn<T> {
  /// Creates a column.
  const FoTableColumn({
    required this.label,
    required this.cellBuilder,
    this.size = FoColumnSize.m,
    this.numeric = false,
    this.sortable = false,
    this.cardValueBuilder,
  });

  /// The heading. A `Text` unless the column needs a mark.
  final Widget label;

  /// Renders one cell.
  final Widget Function(BuildContext context, T row) cellBuilder;

  /// Its share of the width.
  final FoColumnSize size;

  /// Right-aligns the column. Figures belong in `context.foText.numeric`, so
  /// they align on the decimal as well as on the edge.
  final bool numeric;

  /// Whether tapping the heading sorts by it.
  final bool sortable;

  /// The cell's value as plain text, for the compact card layout.
  ///
  /// A column without one is dropped from the card — which is the intended
  /// escape hatch for a column that only makes sense in a wide table, such as
  /// a row of icon actions.
  final String? Function(T row)? cardValueBuilder;
}

/// A table on a wide window, a list of cards on a narrow one.
///
/// Not two components, because they are one table: the same columns feed both,
/// and a screen that had to build them separately would let them drift.
///
/// It owns its own loading, error and empty states. That is deliberate — a
/// screen that early-returns an error above the table destroys the search box
/// and the filters along with it, so the user cannot even change what they
/// were asking for. Pass [error] and [onRetry] and let the table render them
/// in the rows' place.
class FoDataTable<T> extends StatelessWidget {
  /// Creates a data table.
  const FoDataTable({
    required this.columns,
    required this.rows,
    required this.loading,
    required this.errorTitle,
    required this.retryLabel,
    this.error,
    this.onRetry,
    this.emptyState,
    this.onRowTap,
    this.cardBuilder,
    this.sortColumnIndex,
    this.ascending = true,
    this.onSort,
    this.minWidth,
    this.compactPadding,
    super.key,
  });

  /// The columns.
  final List<FoTableColumn<T>> columns;

  /// The rows.
  final List<T> rows;

  /// Shows skeletons in the shape of the table while true and empty.
  final bool loading;

  /// The heading for a failed load — "Could not load entries". Caller-supplied,
  /// so it can be localized.
  final String errorTitle;

  /// The retry button's label.
  final String retryLabel;

  /// The failure, shown as the error state's detail. Null or empty means none.
  final String? error;

  /// Reloads. Without it the error state has no way out.
  final VoidCallback? onRetry;

  /// What to show when the load succeeded and returned nothing.
  final Widget? emptyState;

  /// Opens a row.
  final void Function(T row)? onRowTap;

  /// Builds a compact card, overriding the one assembled from the columns.
  final Widget Function(BuildContext context, T row)? cardBuilder;

  /// Which column is sorted.
  final int? sortColumnIndex;

  /// Sort direction.
  final bool ascending;

  /// Called when a sortable heading is tapped.
  final void Function(int columnIndex, bool ascending)? onSort;

  /// The width below which the table scrolls sideways rather than compressing.
  final double? minWidth;

  /// Padding around the compact card list.
  final EdgeInsetsGeometry? compactPadding;

  /// The width a wide table gets on a medium window when the caller has not
  /// set its own [minWidth]: enough that columns keep their content, with the
  /// overflow reachable by scrolling sideways rather than crushed to fit.
  static const double mediumMinWidth = 900;

  @override
  Widget build(BuildContext context) {
    final bool wide = context.foWindowClass.isAtLeastMedium;

    if (loading && rows.isEmpty) {
      return wide
          ? _WideTableSkeleton(columnCount: columns.length)
          : Padding(
              padding: EdgeInsets.all(context.foSpacing.lg),
              child: const FoSkeletonList(),
            );
    }

    final String? failure = error;
    if (failure != null && failure.isNotEmpty && rows.isEmpty) {
      // A friendly title with the raw server message as the detail: a bare
      // message with no mark and no retry reads as a dead end.
      return FoEmptyState.error(
        title: errorTitle,
        hint: failure,
        actionLabel: onRetry != null ? retryLabel : null,
        onAction: onRetry,
      );
    }

    if (rows.isEmpty) return emptyState ?? const SizedBox.shrink();

    return wide
        ? _WideTable<T>(
            columns: columns,
            rows: rows,
            onRowTap: onRowTap,
            sortColumnIndex: sortColumnIndex,
            ascending: ascending,
            onSort: onSort,
            minWidth: minWidth ??
                (context.foWindowClass == FoWindowClass.medium
                    ? mediumMinWidth
                    : null),
          )
        : _CompactTable<T>(
            columns: columns,
            rows: rows,
            onRowTap: onRowTap,
            cardBuilder: cardBuilder,
            padding: compactPadding,
          );
  }
}

class _WideTable<T> extends StatelessWidget {
  const _WideTable({
    required this.columns,
    required this.rows,
    required this.onRowTap,
    required this.sortColumnIndex,
    required this.ascending,
    required this.onSort,
    required this.minWidth,
  });

  final List<FoTableColumn<T>> columns;
  final List<T> rows;
  final void Function(T row)? onRowTap;
  final int? sortColumnIndex;
  final bool ascending;
  final void Function(int columnIndex, bool ascending)? onSort;
  final double? minWidth;

  @override
  Widget build(BuildContext context) {
    final Widget table = DataTable2(
      sortColumnIndex: sortColumnIndex,
      sortAscending: ascending,
      columnSpacing: context.foSpacing.md,
      horizontalMargin: context.foSpacing.lg,
      // The header is a well the column names sit in — the sunken step. It is
      // also a full-bleed band, which is why the frame's hairline below has to
      // be a foreground decoration (rule §3.1).
      headingRowColor: WidgetStatePropertyAll<Color>(
        context.foColors.surfaceSunken,
      ),
      headingTextStyle: context.foText.label,
      dataTextStyle: context.foText.body,
      dividerThickness: FoLayout.hairlineWidth,
      columns: List<DataColumn2>.generate(columns.length, (int index) {
        final FoTableColumn<T> column = columns[index];
        return DataColumn2(
          label: column.label,
          size: _toColumnSize(column.size),
          numeric: column.numeric,
          onSort: column.sortable && onSort != null
              ? (int columnIndex, bool isAscending) =>
                  onSort!.call(columnIndex, isAscending)
              : null,
        );
      }),
      rows: rows
          .map(
            (T row) => DataRow2(
              onTap: onRowTap == null ? null : () => onRowTap!(row),
              cells: <DataCell>[
                for (final FoTableColumn<T> column in columns)
                  DataCell(column.cellBuilder(context, row)),
              ],
            ),
          )
          .toList(),
    );

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double width = math.max(minWidth ?? 0, constraints.maxWidth);
        final BorderRadius radius = BorderRadius.circular(
          context.foRadii.card,
        );

        final Widget framed = DecoratedBox(
          decoration: BoxDecoration(
            color: context.foColors.surface,
            borderRadius: radius,
          ),
          // G3, and the reason this is not `Border.all` in the decoration
          // above: the heading row paints its own background to the frame's
          // edges inside the clip, so a border underneath it loses its top
          // edge. The symptom is a table missing one line along the top.
          child: DecoratedBox(
            position: DecorationPosition.foreground,
            decoration: BoxDecoration(
              borderRadius: radius,
              border: Border.all(color: context.foColors.edge),
            ),
            child: ClipRRect(
              borderRadius: radius,
              child: SizedBox(width: width, child: table),
            ),
          ),
        );

        if (minWidth == null) return framed;
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: framed,
        );
      },
    );
  }

  ColumnSize _toColumnSize(FoColumnSize size) => switch (size) {
        FoColumnSize.s => ColumnSize.S,
        FoColumnSize.m => ColumnSize.M,
        FoColumnSize.l => ColumnSize.L,
      };
}

class _CompactTable<T> extends StatelessWidget {
  const _CompactTable({
    required this.columns,
    required this.rows,
    required this.onRowTap,
    required this.cardBuilder,
    required this.padding,
  });

  final List<FoTableColumn<T>> columns;
  final List<T> rows;
  final void Function(T row)? onRowTap;
  final Widget Function(BuildContext context, T row)? cardBuilder;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: padding ?? EdgeInsets.all(context.foSpacing.lg),
      itemCount: rows.length,
      separatorBuilder: (BuildContext context, int index) =>
          SizedBox(height: context.foSpacing.sm),
      itemBuilder: (BuildContext context, int index) {
        final T row = rows[index];
        // One card is one row of the table, so it is one announcement —
        // otherwise a screen reader reads a loose run of label/value fragments
        // with nothing tying them to a record.
        return MergeSemantics(
          child: cardBuilder?.call(context, row) ??
              _AutoCard<T>(
                row: row,
                columns: columns,
                onTap: onRowTap == null ? null : () => onRowTap!(row),
              ),
        );
      },
    );
  }
}

/// A row rendered as a card: the first column's value is the title, the rest
/// become label/value pairs.
class _AutoCard<T> extends StatelessWidget {
  const _AutoCard({required this.row, required this.columns, this.onTap});

  final T row;
  final List<FoTableColumn<T>> columns;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final String? title =
        columns.isEmpty ? null : columns.first.cardValueBuilder?.call(row);
    final List<({String? label, String? value})> fields =
        <({String? label, String? value})>[
      for (final FoTableColumn<T> column in columns.skip(1))
        (
          label: _columnLabel(column.label),
          value: column.cardValueBuilder?.call(row),
        ),
    ].where((({String? label, String? value}) f) {
      return f.label != null && f.value != null;
    }).toList();

    return FoCard(
      onTap: onTap,
      semanticLabel: title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (title != null && title.isNotEmpty)
            Text(title, style: context.foText.subtitle),
          if (title != null && title.isNotEmpty && fields.isNotEmpty)
            SizedBox(height: context.foSpacing.md),
          for (int i = 0; i < fields.length; i++) ...<Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: Text(
                    fields[i].label!,
                    style: context.foText.label.copyWith(
                      color: context.foColors.fgMuted,
                    ),
                  ),
                ),
                SizedBox(width: context.foSpacing.md),
                Flexible(
                  child: Text(
                    fields[i].value!,
                    textAlign: TextAlign.end,
                    style: context.foText.label,
                  ),
                ),
              ],
            ),
            if (i < fields.length - 1) SizedBox(height: context.foSpacing.sm),
          ],
        ],
      ),
    );
  }

  /// The plain text of a heading, for the card's label column. Null for a
  /// heading that is not text — an icon-only actions column, say — which drops
  /// the field from the card, as intended.
  String? _columnLabel(Widget widget) {
    if (widget case Text(:final String? data, :final TextSpan? textSpan)) {
      return data ?? textSpan?.toPlainText();
    }
    return null;
  }
}

/// Skeletons in the shape of the table, rather than a spinner over it: the
/// layout does not jump when the rows land.
class _WideTableSkeleton extends StatelessWidget {
  const _WideTableSkeleton({required this.columnCount});

  final int columnCount;

  static const int _rowCount = 4;

  @override
  Widget build(BuildContext context) {
    final BorderRadius radius = BorderRadius.circular(context.foRadii.card);

    Widget row({required double height}) => Row(
          children: <Widget>[
            for (int i = 0; i < columnCount; i++) ...<Widget>[
              Expanded(child: FoSkeleton.line(height: height)),
              if (i < columnCount - 1) SizedBox(width: context.foSpacing.md),
            ],
          ],
        );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.foColors.surface,
        borderRadius: radius,
      ),
      child: DecoratedBox(
        position: DecorationPosition.foreground,
        decoration: BoxDecoration(
          borderRadius: radius,
          border: Border.all(color: context.foColors.edge),
        ),
        child: ListView(
          padding: EdgeInsets.all(context.foSpacing.lg),
          children: <Widget>[
            row(height: 16),
            SizedBox(height: context.foSpacing.lg),
            for (int r = 0; r < _rowCount; r++) ...<Widget>[
              row(height: 14),
              if (r < _rowCount - 1) SizedBox(height: context.foSpacing.lg),
            ],
          ],
        ),
      ),
    );
  }
}

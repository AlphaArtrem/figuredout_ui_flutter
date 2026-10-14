import 'dart:math' as math;

import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';

import '../primitives/fo_card.dart';
import '../primitives/fo_focus_ring.dart';
import '../primitives/fo_skeleton.dart';
import '../theme/fo_context.dart';
import '../theme/fo_window_class.dart';
import '../tokens/fo_layout.dart';
import '../tokens/fo_tokens.dart';
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

/// How a [FoDataTable] is sized.
enum FoTableSizing {
  /// The table fills the box it is given and its rows scroll inside it, under
  /// a fixed heading row (`DataTable2`). Needs a bounded height. The default,
  /// and what the table has always been.
  fill,

  /// The table is as tall as its rows. Nothing in it scrolls vertically, so a
  /// page that scrolls (a `FoListCard` in its unbounded mode, in a page scroll
  /// view) is the one place the records scroll. Wider than the box and the
  /// table scrolls sideways instead.
  content,
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
    this.width,
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

  /// A fixed width in logical pixels, for a column whose content is the same
  /// size in every row — a status chip, a quantity, a date. Null shares the
  /// remaining width by [size].
  final double? width;
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
///
/// **Two sizes.** [sizing] `fill` (the default) is a table in a box: the box
/// must be bounded and the rows scroll inside it. `content` is a table that
/// grows with its rows and never scrolls vertically — the body of a
/// `FoListCard` on a page that scrolls. Use [framed] `false` there, because
/// the card is the frame.
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
    this.sizing = FoTableSizing.fill,
    this.framed = true,
    this.isSelected,
    this.rowKey,
    this.sectionOf,
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

  /// [FoTableSizing.fill] (the default) or [FoTableSizing.content], a table
  /// that is as tall as its rows. See the class doc.
  final FoTableSizing sizing;

  /// Draws the table's own surface, hairline and rounded corners. Turn it off
  /// inside a card that is already the frame (`FoListCard`), or the table
  /// is framed twice. Compact cards are their own frames and ignore it.
  final bool framed;

  /// Whether a row is the open one: a `content` row is drawn on `primarySoft`
  /// and announced as selected. Ignored by `fill`.
  final bool Function(T row)? isSelected;

  /// A key for a row, so state (a hover, a focus) follows the record when the
  /// list is re-sorted or paged. Used by `content`.
  final Key Function(T row)? rowKey;

  /// A heading to group rows under — History's day. A full-width section row
  /// is drawn whenever the value changes from the previous row (and before the
  /// first row if it is not null). A row whose value is null draws no heading
  /// and stays in the group above it. Used by `content`.
  final String? Function(T row)? sectionOf;

  /// The width a wide table gets on a medium window when the caller has not
  /// set its own [minWidth]: enough that columns keep their content, with the
  /// overflow reachable by scrolling sideways rather than crushed to fit.
  static const double mediumMinWidth = 900;

  @override
  Widget build(BuildContext context) {
    final bool wide = context.foWindowClass.isAtLeastMedium;
    final bool content = sizing == FoTableSizing.content;

    if (loading && rows.isEmpty) {
      return wide
          ? _WideTableSkeleton(
              columnCount: columns.length,
              framed: framed,
              content: content,
            )
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

    final double? wideMinWidth = minWidth ??
        (context.foWindowClass == FoWindowClass.medium ? mediumMinWidth : null);

    if (content) {
      return wide
          ? _ContentTable<T>(
              columns: columns,
              rows: rows,
              onRowTap: onRowTap,
              sortColumnIndex: sortColumnIndex,
              ascending: ascending,
              onSort: onSort,
              minWidth: wideMinWidth,
              framed: framed,
              isSelected: isSelected,
              rowKey: rowKey,
              sectionOf: sectionOf,
            )
          : _CompactTable<T>(
              columns: columns,
              rows: rows,
              onRowTap: onRowTap,
              cardBuilder: cardBuilder,
              padding: compactPadding,
              content: true,
              isSelected: isSelected,
              rowKey: rowKey,
              sectionOf: sectionOf,
            );
    }

    return wide
        ? _WideTable<T>(
            columns: columns,
            rows: rows,
            onRowTap: onRowTap,
            sortColumnIndex: sortColumnIndex,
            ascending: ascending,
            onSort: onSort,
            minWidth: wideMinWidth,
            framed: framed,
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
    required this.framed,
  });

  final List<FoTableColumn<T>> columns;
  final List<T> rows;
  final void Function(T row)? onRowTap;
  final int? sortColumnIndex;
  final bool ascending;
  final void Function(int columnIndex, bool ascending)? onSort;
  final double? minWidth;
  final bool framed;

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
          fixedWidth: column.width,
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

        final Widget sized = SizedBox(width: width, child: table);
        final Widget framedTable = !framed
            ? sized
            : DecoratedBox(
                decoration: BoxDecoration(
                  color: context.foColors.surface,
                  borderRadius: radius,
                ),
                // G3, and the reason this is not `Border.all` in the
                // decoration above: the heading row paints its own background
                // to the frame's edges inside the clip, so a border underneath
                // it loses its top edge. The symptom is a table missing one
                // line along the top.
                child: DecoratedBox(
                  position: DecorationPosition.foreground,
                  decoration: BoxDecoration(
                    borderRadius: radius,
                    border: Border.all(color: context.foColors.edge),
                  ),
                  child: ClipRRect(
                    borderRadius: radius,
                    child: sized,
                  ),
                ),
              );

        if (minWidth == null) return framedTable;
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: framedTable,
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

/// The `content` layout of a wide table: a heading band and one line per
/// record, as tall as its rows and never scrolling vertically.
///
/// Not `DataTable2`, whose body is a vertical scroll view and so needs a
/// bounded height. Every part is a plain box: a heading band on the sunken
/// step, rows with a hairline above them (a foreground decoration, rule §3.1),
/// the whole row the target, the open row on `primarySoft`.
class _ContentTable<T> extends StatelessWidget {
  const _ContentTable({
    required this.columns,
    required this.rows,
    required this.onRowTap,
    required this.sortColumnIndex,
    required this.ascending,
    required this.onSort,
    required this.minWidth,
    required this.framed,
    required this.isSelected,
    required this.rowKey,
    required this.sectionOf,
  });

  final List<FoTableColumn<T>> columns;
  final List<T> rows;
  final void Function(T row)? onRowTap;
  final int? sortColumnIndex;
  final bool ascending;
  final void Function(int columnIndex, bool ascending)? onSort;
  final double? minWidth;
  final bool framed;
  final bool Function(T row)? isSelected;
  final Key Function(T row)? rowKey;
  final String? Function(T row)? sectionOf;

  /// The heading band's least height: a caption line with air.
  static const double headingHeight = 36;

  /// A row's least height: the touch floor.
  static const double rowHeight = FoLayout.minTouchTarget;

  static int _flex(FoColumnSize size) => switch (size) {
        FoColumnSize.s => 2,
        FoColumnSize.m => 3,
        FoColumnSize.l => 4,
      };

  /// Lays [cells] out on the columns' widths: fixed where a column has one,
  /// otherwise sharing the rest by size, with a gap between.
  Widget _line(BuildContext context, List<Widget> cells) {
    final double gap = context.foSpacing.md;
    return Row(
      children: <Widget>[
        for (int i = 0; i < columns.length; i++) ...<Widget>[
          if (i > 0) SizedBox(width: gap),
          if (columns[i].width != null)
            SizedBox(width: columns[i].width, child: cells[i])
          else
            Expanded(flex: _flex(columns[i].size), child: cells[i]),
        ],
      ],
    );
  }

  Widget _headingCell(BuildContext context, int index) {
    final FoTableColumn<T> column = columns[index];
    final TextStyle style = context.foText.caption;
    final Widget label = switch (column.label) {
      Text(:final String? data, :final TextAlign? textAlign)
          when data != null =>
        // Mono captions are uppercase (rule §3.3) and a heading may take two
        // lines before it is cut, so a long word wraps instead of vanishing.
        Text(
          data.toUpperCase(),
          style: style,
          textAlign: textAlign ?? (column.numeric ? TextAlign.end : null),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      final Widget other => DefaultTextStyle.merge(style: style, child: other),
    };

    final bool sorted = sortColumnIndex == index;
    final bool sortable = column.sortable && onSort != null;
    final Widget content = Row(
      mainAxisAlignment:
          column.numeric ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: <Widget>[
        Flexible(child: label),
        if (sorted) ...<Widget>[
          SizedBox(width: context.foSpacing.xs),
          Icon(
            ascending ? Icons.arrow_upward : Icons.arrow_downward,
            size: FoTokens.iconSmall - 4,
            color: context.foColors.fgMuted,
          ),
        ],
      ],
    );
    if (!sortable) return content;
    return Semantics(
      button: true,
      child: InkWell(
        onTap: () => onSort!(index, sorted ? !ascending : true),
        child: content,
      ),
    );
  }

  Widget _heading(BuildContext context) {
    return ColoredBox(
      color: context.foColors.surfaceSunken,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: headingHeight),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: context.foSpacing.lg,
            vertical: context.foSpacing.xs,
          ),
          child: _line(context, <Widget>[
            for (int i = 0; i < columns.length; i++) _headingCell(context, i),
          ]),
        ),
      ),
    );
  }

  Widget _row(BuildContext context, T row) {
    final bool selected = isSelected?.call(row) ?? false;
    final Widget line = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: rowHeight),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: context.foSpacing.lg,
          vertical: context.foSpacing.sm,
        ),
        child: _line(context, <Widget>[
          for (final FoTableColumn<T> column in columns)
            Align(
              alignment: column.numeric
                  ? AlignmentDirectional.centerEnd
                  : AlignmentDirectional.centerStart,
              child: column.cellBuilder(context, row),
            ),
        ]),
      ),
    );

    final VoidCallback? onTap = onRowTap == null ? null : () => onRowTap!(row);
    final Widget target = Material(
      color: selected ? context.foColors.primarySoft : Colors.transparent,
      child: FoFocusRing(
        borderRadius: BorderRadius.zero,
        child: InkWell(
          onTap: onTap,
          hoverColor: context.foColors.surfaceRaised,
          child: line,
        ),
      ),
    );

    final Widget hairlined = DecoratedBox(
      position: DecorationPosition.foreground,
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: context.foColors.edge,
          ),
        ),
      ),
      child: target,
    );

    final Widget announced = Semantics(
      container: true,
      selected: isSelected == null ? null : selected,
      child: hairlined,
    );
    final Key? key = rowKey?.call(row);
    return key == null ? announced : KeyedSubtree(key: key, child: announced);
  }

  Widget _section(BuildContext context, String heading) {
    return Semantics(
      header: true,
      child: DecoratedBox(
        position: DecorationPosition.foreground,
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: context.foColors.edge,
            ),
          ),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: context.foSpacing.lg,
            vertical: context.foSpacing.sm,
          ),
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              heading,
              style: context.foText.caption,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double width = constraints.hasBoundedWidth
            ? math.max(minWidth ?? 0, constraints.maxWidth)
            : (minWidth ?? FoDataTable.mediumMinWidth);

        String? section;
        final List<Widget> children = <Widget>[_heading(context)];
        for (final T row in rows) {
          final String? heading = sectionOf?.call(row);
          if (heading != null && heading != section) {
            children.add(_section(context, heading));
          }
          section = heading ?? section;
          children.add(_row(context, row));
        }

        final Widget table = SizedBox(
          width: width,
          child: DefaultTextStyle(
            style: context.foText.body,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
            ),
          ),
        );

        final BorderRadius radius = BorderRadius.circular(
          context.foRadii.card,
        );
        final Widget shown = !framed
            ? table
            : DecoratedBox(
                decoration: BoxDecoration(
                  color: context.foColors.surface,
                  borderRadius: radius,
                ),
                // Rule §3.1: the heading band paints to the frame's edges
                // inside the clip, so the hairline is a foreground decoration.
                child: DecoratedBox(
                  position: DecorationPosition.foreground,
                  decoration: BoxDecoration(
                    borderRadius: radius,
                    border: Border.all(color: context.foColors.edge),
                  ),
                  child: ClipRRect(borderRadius: radius, child: table),
                ),
              );

        if (minWidth == null) return shown;
        // Sideways only: a table taller than the page is the page's to scroll.
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          primary: false,
          child: shown,
        );
      },
    );
  }
}

class _CompactTable<T> extends StatelessWidget {
  const _CompactTable({
    required this.columns,
    required this.rows,
    required this.onRowTap,
    required this.cardBuilder,
    required this.padding,
    this.content = false,
    this.isSelected,
    this.rowKey,
    this.sectionOf,
  });

  final List<FoTableColumn<T>> columns;
  final List<T> rows;
  final void Function(T row)? onRowTap;
  final Widget Function(BuildContext context, T row)? cardBuilder;
  final EdgeInsetsGeometry? padding;

  /// Sized to its cards (a `Column`) instead of scrolling them (a `ListView`).
  final bool content;
  final bool Function(T row)? isSelected;
  final Key Function(T row)? rowKey;
  final String? Function(T row)? sectionOf;

  Widget _card(BuildContext context, T row) {
    // One card is one row of the table, so it is one announcement —
    // otherwise a screen reader reads a loose run of label/value fragments
    // with nothing tying them to a record.
    final Widget card = MergeSemantics(
      child: cardBuilder?.call(context, row) ??
          _AutoCard<T>(
            row: row,
            columns: columns,
            onTap: onRowTap == null ? null : () => onRowTap!(row),
          ),
    );
    final Widget marked = isSelected == null
        ? card
        : Semantics(selected: isSelected!(row), child: card);
    final Key? key = rowKey?.call(row);
    return key == null ? marked : KeyedSubtree(key: key, child: marked);
  }

  @override
  Widget build(BuildContext context) {
    if (content) {
      final EdgeInsetsGeometry inset =
          padding ?? EdgeInsets.all(context.foSpacing.lg);
      String? section;
      final List<Widget> children = <Widget>[];
      for (int i = 0; i < rows.length; i++) {
        final T row = rows[i];
        final String? heading = sectionOf?.call(row);
        if (heading != null && heading != section) {
          if (children.isNotEmpty) {
            children.add(SizedBox(height: context.foSpacing.md));
          }
          children.add(
            Semantics(
              header: true,
              child: Text(heading, style: context.foText.caption),
            ),
          );
          children.add(SizedBox(height: context.foSpacing.sm));
        } else if (children.isNotEmpty) {
          children.add(SizedBox(height: context.foSpacing.sm));
        }
        section = heading ?? section;
        children.add(_card(context, row));
      }
      return Padding(
        padding: inset,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        ),
      );
    }

    return ListView.separated(
      padding: padding ?? EdgeInsets.all(context.foSpacing.lg),
      itemCount: rows.length,
      separatorBuilder: (BuildContext context, int index) =>
          SizedBox(height: context.foSpacing.sm),
      itemBuilder: (BuildContext context, int index) =>
          _card(context, rows[index]),
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
///
/// A `ListView` in `fill`, which has a bounded box to scroll in; a `Column` in
/// `content`, which has none.
class _WideTableSkeleton extends StatelessWidget {
  const _WideTableSkeleton({
    required this.columnCount,
    required this.framed,
    required this.content,
  });

  final int columnCount;
  final bool framed;
  final bool content;

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

    final List<Widget> lines = <Widget>[
      row(height: 16),
      SizedBox(height: context.foSpacing.lg),
      for (int r = 0; r < _rowCount; r++) ...<Widget>[
        row(height: 14),
        if (r < _rowCount - 1) SizedBox(height: context.foSpacing.lg),
      ],
    ];
    final EdgeInsets padding = EdgeInsets.all(context.foSpacing.lg);
    final Widget body = content
        ? Padding(
            padding: padding,
            child: Column(mainAxisSize: MainAxisSize.min, children: lines),
          )
        : ListView(padding: padding, children: lines);

    if (!framed) return body;
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
        child: body,
      ),
    );
  }
}

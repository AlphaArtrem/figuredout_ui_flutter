import 'package:flutter/material.dart';

import '../theme/fo_context.dart';

/// One value column of a [FoMatrixTable].
///
/// Fixed-width on purpose: a matrix is read down its columns as much as across
/// its rows, and a column that resizes to its widest cell stops the eye being
/// able to compare two rows at a glance.
@immutable
class FoMatrixColumn {
  /// Creates a column.
  const FoMatrixColumn({
    required this.label,
    this.width = defaultWidth,
    this.alignment = Alignment.center,
    this.padding,
  });

  /// The heading. A widget rather than a string so a column can carry a unit,
  /// a hint or a two-line name.
  final Widget label;

  /// The column's width in logical pixels.
  final double width;

  /// How a cell's content sits in its box.
  final AlignmentGeometry alignment;

  /// Overrides the cell padding — for an editable cell, which needs less.
  final EdgeInsetsGeometry? padding;

  /// Wide enough for a size label and a three-figure quantity.
  static const double defaultWidth = 108;
}

/// One data row of a [FoMatrixTable].
@immutable
class FoMatrixRow {
  /// Creates a row.
  const FoMatrixRow({
    required this.leading,
    required this.cells,
    this.backgroundColor,
    this.leadingAlignment = Alignment.centerLeft,
    this.emphasized = false,
  });

  /// The row's label, in the leading column.
  final Widget leading;

  /// One widget per [FoMatrixTable.columns], in order.
  final List<Widget> cells;

  /// Tints the whole row — a total, an invalid row. Reach for
  /// `context.foColors.dangerSoft` and friends rather than a raw colour.
  final Color? backgroundColor;

  /// How [leading] sits in its box.
  final AlignmentGeometry leadingAlignment;

  /// Draws the row's label in bold label type rather than body type.
  final bool emphasized;
}

/// A group of rows under an optional label.
@immutable
class FoMatrixSection {
  /// Creates a section.
  const FoMatrixSection({required this.rows, this.label});

  /// The group's name, spanning the full width. Caller-supplied, so it can be
  /// localized. Not rendered when [FoMatrixTable.pinLeadingColumn] is set.
  final String? label;

  /// The section's rows.
  final List<FoMatrixRow> rows;
}

/// The pinned bottom row of a [FoMatrixTable] — column totals.
@immutable
class FoMatrixSummaryRow {
  /// Creates a summary row.
  const FoMatrixSummaryRow({required this.leading, required this.cells});

  /// The row's label, in the leading column.
  final Widget leading;

  /// One widget per [FoMatrixTable.columns], in order.
  final List<Widget> cells;
}

/// A fixed-width grid: rows down the leading column, values across.
///
/// The shape a size breakdown takes — sizes across the top, a stage or a
/// colour down the side — for read-only grids and editable ones alike. Not a
/// `FoDataTable`: that one is a list of records that happens to be tabular and
/// reflows to cards on a phone. This is a *matrix*, where the position of a
/// cell in two dimensions is its meaning, so it keeps its shape at every width
/// and scrolls sideways instead.
///
/// Set [pinLeadingColumn] once the columns outrun the window.
class FoMatrixTable extends StatelessWidget {
  /// Creates a matrix table.
  const FoMatrixTable({
    required this.columns,
    required this.sections,
    this.leadingHeader,
    this.leadingColumnWidth = defaultLeadingColumnWidth,
    this.columnGroupLabel,
    this.summaryRow,
    this.rowMinHeight = defaultRowMinHeight,
    this.pinLeadingColumn = false,
    super.key,
  });

  /// The value columns.
  final List<FoMatrixColumn> columns;

  /// The rows, in groups. Pass a single unlabelled section for a flat grid.
  final List<FoMatrixSection> sections;

  /// The heading above the leading column.
  final Widget? leadingHeader;

  /// The leading column's width.
  final double leadingColumnWidth;

  /// A band above the column headings naming what the columns are — "Sizes".
  /// Caller-supplied, so it can be localized.
  final String? columnGroupLabel;

  /// A totals row pinned below the sections.
  final FoMatrixSummaryRow? summaryRow;

  /// The height a row is laid out at — a floor normally, and an exact height
  /// under [pinLeadingColumn].
  final double rowMinHeight;

  /// Keeps the row-label column fixed while the value columns scroll sideways.
  ///
  /// Without it, scrolling right takes the labels with it and the user ends up
  /// typing into unlabelled rows. Rows are laid out at exactly [rowMinHeight]
  /// in this mode so the two columns stay aligned, so use it only where the
  /// leading cell is a single line. [FoMatrixSection.label] is not rendered
  /// here — a full-width band cannot span a split that scrolls.
  final bool pinLeadingColumn;

  /// Room for a stage name or a colour, which is what the leading column
  /// almost always carries.
  static const double defaultLeadingColumnWidth = 220;

  /// One touch target tall, so an editable cell is reachable with a glove on.
  static const double defaultRowMinHeight = 48;

  @override
  Widget build(BuildContext context) {
    assert(
      sections.every(
        (FoMatrixSection section) => section.rows.every(
          (FoMatrixRow row) => row.cells.length == columns.length,
        ),
      ),
      'Every matrix row must have the same number of cells as matrix columns.',
    );
    assert(
      summaryRow == null || summaryRow!.cells.length == columns.length,
      'Summary row must have the same number of cells as matrix columns.',
    );

    final double matrixWidth = columns.fold<double>(
      0,
      (double sum, FoMatrixColumn column) => sum + column.width,
    );

    if (pinLeadingColumn) {
      return _PinnedLeadingMatrix(
        columns: columns,
        sections: sections,
        leadingHeader: leadingHeader,
        leadingColumnWidth: leadingColumnWidth,
        matrixWidth: matrixWidth,
        summaryRow: summaryRow,
        rowHeight: rowMinHeight,
      );
    }

    return Scrollbar(
      // Visible thumb: the grid overflows silently otherwise, and the columns
      // past the edge are simply never found.
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: _MatrixFrame(
          child: SizedBox(
            width: leadingColumnWidth + matrixWidth,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                if (columnGroupLabel?.trim().isNotEmpty ?? false)
                  _MatrixGroupRow(
                    leadingWidth: leadingColumnWidth,
                    matrixWidth: matrixWidth,
                    label: columnGroupLabel!,
                    isLast: false,
                  ),
                _MatrixHeaderRow(
                  leadingHeader: leadingHeader,
                  leadingWidth: leadingColumnWidth,
                  columns: columns,
                  rowMinHeight: rowMinHeight,
                  isLast: sections.isEmpty && summaryRow == null,
                ),
                for (int sectionIndex = 0;
                    sectionIndex < sections.length;
                    sectionIndex++) ...<Widget>[
                  if (sections[sectionIndex].label?.trim().isNotEmpty ?? false)
                    _MatrixSectionLabelRow(
                      label: sections[sectionIndex].label!,
                      totalWidth: leadingColumnWidth + matrixWidth,
                      isLast: sections[sectionIndex].rows.isEmpty &&
                          summaryRow == null &&
                          sectionIndex == sections.length - 1,
                    ),
                  for (int rowIndex = 0;
                      rowIndex < sections[sectionIndex].rows.length;
                      rowIndex++)
                    _MatrixDataRow(
                      row: sections[sectionIndex].rows[rowIndex],
                      columns: columns,
                      leadingWidth: leadingColumnWidth,
                      rowMinHeight: rowMinHeight,
                      isLast: sectionIndex == sections.length - 1 &&
                          rowIndex == sections[sectionIndex].rows.length - 1 &&
                          summaryRow == null,
                    ),
                ],
                if (summaryRow != null)
                  _MatrixSummaryDataRow(
                    row: summaryRow!,
                    columns: columns,
                    leadingWidth: leadingColumnWidth,
                    rowMinHeight: rowMinHeight,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Matrix whose leading (row-label) column stays put while the value columns
/// scroll sideways. Both columns lay their rows out at the same fixed height,
/// which is what keeps the labels lined up with the values they name.
class _PinnedLeadingMatrix extends StatelessWidget {
  const _PinnedLeadingMatrix({
    required this.columns,
    required this.sections,
    required this.leadingHeader,
    required this.leadingColumnWidth,
    required this.matrixWidth,
    required this.summaryRow,
    required this.rowHeight,
  });

  final List<FoMatrixColumn> columns;
  final List<FoMatrixSection> sections;
  final Widget? leadingHeader;
  final double leadingColumnWidth;
  final double matrixWidth;
  final FoMatrixSummaryRow? summaryRow;
  final double rowHeight;

  @override
  Widget build(BuildContext context) {
    final List<FoMatrixRow> dataRows = <FoMatrixRow>[
      for (final FoMatrixSection section in sections) ...section.rows,
    ];
    final int lastIndex = dataRows.length - 1;

    Widget sized(Widget child) => SizedBox(height: rowHeight, child: child);

    final List<Widget> leadingCells = <Widget>[
      sized(
        _MatrixFrameCell(
          width: leadingColumnWidth,
          alignment: Alignment.centerLeft,
          isHeader: true,
          isLast: dataRows.isEmpty && summaryRow == null,
          child: leadingHeader ?? const SizedBox.shrink(),
        ),
      ),
      for (int i = 0; i < dataRows.length; i++)
        sized(
          _MatrixFrameCell(
            width: leadingColumnWidth,
            alignment: dataRows[i].leadingAlignment,
            backgroundColor: dataRows[i].backgroundColor,
            isLast: i == lastIndex && summaryRow == null,
            child: DefaultTextStyle(
              style: dataRows[i].emphasized
                  ? context.foText.label.copyWith(fontWeight: FontWeight.w700)
                  : context.foText.body,
              child: dataRows[i].leading,
            ),
          ),
        ),
      if (summaryRow != null)
        sized(
          _MatrixFrameCell(
            width: leadingColumnWidth,
            alignment: Alignment.centerLeft,
            backgroundColor: context.foColors.surfaceSunken,
            isLast: true,
            child: DefaultTextStyle(
              style: context.foText.label.copyWith(fontWeight: FontWeight.w700),
              child: summaryRow!.leading,
            ),
          ),
        ),
    ];

    Widget valueRow({
      required List<Widget> cells,
      required bool isHeader,
      required bool isLast,
      Color? backgroundColor,
    }) =>
        sized(
          Row(
            children: <Widget>[
              for (int index = 0; index < columns.length; index++)
                _MatrixFrameCell(
                  width: columns[index].width,
                  alignment: columns[index].alignment,
                  padding: columns[index].padding,
                  backgroundColor: backgroundColor,
                  isHeader: isHeader,
                  isTrailingEdge: index == columns.length - 1,
                  isLast: isLast,
                  child: DefaultTextStyle(
                    style:
                        isHeader ? context.foText.label : context.foText.body,
                    child: cells[index],
                  ),
                ),
            ],
          ),
        );

    final List<Widget> valueRows = <Widget>[
      valueRow(
        cells: <Widget>[
          for (final FoMatrixColumn column in columns) column.label,
        ],
        isHeader: true,
        isLast: dataRows.isEmpty && summaryRow == null,
      ),
      for (int i = 0; i < dataRows.length; i++)
        valueRow(
          cells: dataRows[i].cells,
          isHeader: false,
          isLast: i == lastIndex && summaryRow == null,
          backgroundColor: dataRows[i].backgroundColor,
        ),
      if (summaryRow != null)
        valueRow(
          cells: summaryRow!.cells,
          isHeader: false,
          isLast: true,
          backgroundColor: context.foColors.surfaceSunken,
        ),
    ];

    return _MatrixFrame(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: leadingColumnWidth,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: leadingCells,
            ),
          ),
          Expanded(
            child: Scrollbar(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: matrixWidth,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: valueRows,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The rounded, hairlined surface the grid sits in.
///
/// G3, and rule §3.1: the header row and the summary row paint their own
/// background to the frame's edges inside the clip, so a border in the same
/// decoration as the fill loses its top and bottom edges. The symptom is a
/// grid missing one line along the top — which is exactly how the pinned
/// leading column shipped in Luxe. The same fix `FoDataTable` carries.
class _MatrixFrame extends StatelessWidget {
  const _MatrixFrame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final BorderRadius radius = BorderRadius.circular(context.foRadii.md);

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
        child: ClipRRect(borderRadius: radius, child: child),
      ),
    );
  }
}

class _MatrixGroupRow extends StatelessWidget {
  const _MatrixGroupRow({
    required this.leadingWidth,
    required this.matrixWidth,
    required this.label,
    required this.isLast,
  });

  final double leadingWidth;
  final double matrixWidth;
  final String label;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        _MatrixFrameCell(
          width: leadingWidth,
          alignment: Alignment.centerLeft,
          isHeader: true,
          child: const SizedBox.shrink(),
        ),
        Container(
          width: matrixWidth,
          padding: EdgeInsets.symmetric(
            horizontal: context.foSpacing.md,
            vertical: context.foSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: context.foColors.surfaceSunken,
            border: Border(
              bottom: BorderSide(
                color: isLast ? Colors.transparent : context.foColors.edge,
              ),
            ),
          ),
          // The caption style names the columns rather than stating a value,
          // which is what this band is for — rule §3.3.
          child: Text(label, style: context.foText.caption),
        ),
      ],
    );
  }
}

class _MatrixHeaderRow extends StatelessWidget {
  const _MatrixHeaderRow({
    required this.leadingHeader,
    required this.leadingWidth,
    required this.columns,
    required this.rowMinHeight,
    required this.isLast,
  });

  final Widget? leadingHeader;
  final double leadingWidth;
  final List<FoMatrixColumn> columns;
  final double rowMinHeight;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        _MatrixFrameCell(
          width: leadingWidth,
          alignment: Alignment.centerLeft,
          minHeight: rowMinHeight,
          isHeader: true,
          isLast: isLast,
          child: leadingHeader ?? const SizedBox.shrink(),
        ),
        for (int index = 0; index < columns.length; index++)
          _MatrixFrameCell(
            width: columns[index].width,
            alignment: columns[index].alignment,
            padding: columns[index].padding,
            minHeight: rowMinHeight,
            isHeader: true,
            isTrailingEdge: index == columns.length - 1,
            isLast: isLast,
            child: DefaultTextStyle(
              style: context.foText.label,
              child: columns[index].label,
            ),
          ),
      ],
    );
  }
}

class _MatrixSectionLabelRow extends StatelessWidget {
  const _MatrixSectionLabelRow({
    required this.label,
    required this.totalWidth,
    required this.isLast,
  });

  final String label;
  final double totalWidth;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: totalWidth,
      padding: EdgeInsets.symmetric(
        horizontal: context.foSpacing.md,
        vertical: context.foSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: context.foColors.surfaceSunken,
        border: Border(
          bottom: BorderSide(
            color: isLast ? Colors.transparent : context.foColors.edge,
          ),
        ),
      ),
      child: Text(
        label,
        style: context.foText.label.copyWith(
          color: context.foColors.fgMuted,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _MatrixDataRow extends StatelessWidget {
  const _MatrixDataRow({
    required this.row,
    required this.columns,
    required this.leadingWidth,
    required this.rowMinHeight,
    required this.isLast,
  });

  final FoMatrixRow row;
  final List<FoMatrixColumn> columns;
  final double leadingWidth;
  final double rowMinHeight;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        _MatrixFrameCell(
          width: leadingWidth,
          alignment: row.leadingAlignment,
          minHeight: rowMinHeight,
          backgroundColor: row.backgroundColor,
          isLast: isLast,
          child: DefaultTextStyle(
            style: row.emphasized
                ? context.foText.label.copyWith(fontWeight: FontWeight.w700)
                : context.foText.body,
            child: row.leading,
          ),
        ),
        for (int index = 0; index < columns.length; index++)
          _MatrixFrameCell(
            width: columns[index].width,
            alignment: columns[index].alignment,
            padding: columns[index].padding,
            minHeight: rowMinHeight,
            backgroundColor: row.backgroundColor,
            isTrailingEdge: index == columns.length - 1,
            isLast: isLast,
            // Value cells need the same explicit style as the leading cell.
            // Without it they fell back to the ambient Material default, which
            // is dimmer than `foText.body` in dark mode — so this table read
            // grey next to an identical table rendering near-white.
            child: DefaultTextStyle(
              style: context.foText.body,
              child: row.cells[index],
            ),
          ),
      ],
    );
  }
}

class _MatrixSummaryDataRow extends StatelessWidget {
  const _MatrixSummaryDataRow({
    required this.row,
    required this.columns,
    required this.leadingWidth,
    required this.rowMinHeight,
  });

  final FoMatrixSummaryRow row;
  final List<FoMatrixColumn> columns;
  final double leadingWidth;
  final double rowMinHeight;

  @override
  Widget build(BuildContext context) {
    final TextStyle style = context.foText.label.copyWith(
      fontWeight: FontWeight.w700,
    );

    return Row(
      children: <Widget>[
        _MatrixFrameCell(
          width: leadingWidth,
          alignment: Alignment.centerLeft,
          minHeight: rowMinHeight,
          backgroundColor: context.foColors.surfaceSunken,
          isLast: true,
          child: DefaultTextStyle(style: style, child: row.leading),
        ),
        for (int index = 0; index < columns.length; index++)
          _MatrixFrameCell(
            width: columns[index].width,
            alignment: columns[index].alignment,
            padding: columns[index].padding,
            minHeight: rowMinHeight,
            backgroundColor: context.foColors.surfaceSunken,
            isTrailingEdge: index == columns.length - 1,
            isLast: true,
            child: DefaultTextStyle(style: style, child: row.cells[index]),
          ),
      ],
    );
  }
}

class _MatrixFrameCell extends StatelessWidget {
  const _MatrixFrameCell({
    required this.width,
    required this.alignment,
    required this.child,
    this.padding,
    this.minHeight,
    this.backgroundColor,
    this.isHeader = false,
    this.isTrailingEdge = false,
    this.isLast = false,
  });

  final double width;
  final AlignmentGeometry alignment;
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double? minHeight;
  final Color? backgroundColor;
  final bool isHeader;
  final bool isTrailingEdge;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final EdgeInsetsGeometry resolvedPadding = padding ??
        EdgeInsets.symmetric(
          horizontal: context.foSpacing.md,
          vertical: isHeader ? context.foSpacing.sm : context.foSpacing.xs,
        );

    return Container(
      width: width,
      constraints: BoxConstraints(minHeight: minHeight ?? 0),
      alignment: alignment,
      padding: resolvedPadding,
      decoration: BoxDecoration(
        // A heading is a well the column names sit in — the sunken step, the
        // same one `FoDataTable` gives its heading row.
        color: backgroundColor ??
            (isHeader
                ? context.foColors.surfaceSunken
                : context.foColors.surface),
        border: Border(
          right: BorderSide(
            color: isTrailingEdge ? Colors.transparent : context.foColors.edge,
          ),
          bottom: BorderSide(
            color: isLast ? Colors.transparent : context.foColors.edge,
          ),
        ),
      ),
      child: child,
    );
  }
}

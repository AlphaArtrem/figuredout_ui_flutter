import 'package:flutter/material.dart';

import '../primitives/fo_icon_button.dart';
import '../primitives/fo_number_field.dart';
import '../theme/fo_context.dart';
import '../tokens/fo_layout.dart';
import '../tokens/fo_tokens.dart';

/// One row of a [FoQuantityMatrix] — a colour of an order.
@immutable
class FoQuantityRow {
  /// Creates a row.
  const FoQuantityRow({
    required this.label,
    required this.values,
    this.leading,
    this.floors,
    this.originals,
  });

  /// The row's name — "Deep Navy". Caller-supplied.
  final String label;

  /// Something before the name — a `FoColourSwatch`.
  final Widget? leading;

  /// One value per column.
  final List<int> values;

  /// The least each cell may be — what is already cut, when editing an order
  /// that is running. Shown under the box ("cut 120"); a value below it is an
  /// error.
  final List<int>? floors;

  /// What each cell was before this edit, when editing. A cell that differs
  /// is marked and shows "was 160".
  final List<int>? originals;

  /// The row's total.
  int get total => values.fold<int>(0, (int a, int b) => a + b);
}

/// The words a [FoQuantityMatrix] needs.
@immutable
class FoQuantityMatrixCopy {
  /// Creates the copy.
  const FoQuantityMatrixCopy({
    required this.rowHeader,
    required this.totalLabel,
    required this.allRowsLabel,
    required this.cellLabel,
    required this.rowTotalLabel,
    this.ratioLabel,
    this.ratioCellLabel,
    this.copyLabel,
    this.removeLabel,
    this.floorCaption,
    this.wasCaption,
    this.belowFloorMessage,
  });

  /// "Colour".
  final String rowHeader;

  /// "Colour total".
  final String totalLabel;

  /// "All colours".
  final String allRowsLabel;

  /// "Deep Navy, size S".
  final String Function(String row, String column) cellLabel;

  /// "Deep Navy total. Typing a total splits it by the size ratio."
  final String Function(String row) rowTotalLabel;

  /// "Size ratio". Null hides the ratio row.
  final String? ratioLabel;

  /// "Ratio for size S".
  final String Function(String column)? ratioCellLabel;

  /// "Copy Deep Navy to Ecru" — given this row and the next.
  final String Function(String row, String next)? copyLabel;

  /// "Remove Deep Navy from this order".
  final String Function(String row)? removeLabel;

  /// "cut 120".
  final String Function(int floor)? floorCaption;

  /// "was 160".
  final String Function(int original)? wasCaption;

  /// "Deep Navy XXL can't go below 120: that many are already cut."
  final String Function(String row, String column, int floor)?
      belowFloorMessage;
}

/// The result of reading a block pasted from a spreadsheet.
@immutable
class FoQuantityPaste {
  /// Creates a paste result.
  const FoQuantityPaste({required this.rows, required this.unknown});

  /// Row index → values, for the rows the paste matched.
  final Map<int, List<int>> rows;

  /// Row names in the paste that match no row.
  final List<String> unknown;
}

/// Quantities by row and column — an order's colours by sizes — typed fast,
/// split by ratio, copied, pasted, and totalled as you type.
///
/// The row name stays put while the sizes scroll sideways, so nobody types
/// into an unlabelled row. A [ratio] row sits on top: typing a row's total
/// splits it across the columns by the ratio ([splitByRatio], largest
/// remainder, so the parts always add up to exactly the total). [onCopyToNext]
/// copies a row into the one below; [parsePaste] reads a block copied from a
/// spreadsheet. Column and grand totals update on every keystroke.
///
/// Editing a running order: [FoQuantityRow.floors] is what is already cut —
/// shown under each box, and a value below it is an error with a sentence
/// under the grid; [FoQuantityRow.originals] marks each changed cell with
/// what it was.
///
/// Rows are the caller's state; every change comes out through
/// [onRowChanged] with the whole row.
class FoQuantityMatrix extends StatelessWidget {
  /// Creates a quantity matrix.
  const FoQuantityMatrix({
    required this.columns,
    required this.rows,
    required this.onRowChanged,
    required this.copy,
    this.ratio,
    this.onRatioChanged,
    this.onCopyToNext,
    this.onRemove,
    this.rowErrors = const <int, String>{},
    this.numberFormatter,
    super.key,
  });

  /// The column names — "S", "M", "L". Caller-supplied.
  final List<String> columns;

  /// The rows.
  final List<FoQuantityRow> rows;

  /// Called with a row's index and its new values.
  final void Function(int row, List<int> values) onRowChanged;

  /// The words.
  final FoQuantityMatrixCopy copy;

  /// The split ratio, one per column. Null hides the ratio row and makes the
  /// row totals read-only.
  final List<int>? ratio;

  /// Called with a new ratio.
  final ValueChanged<List<int>>? onRatioChanged;

  /// Copies a row into the next one. Null hides the copy buttons.
  final ValueChanged<int>? onCopyToNext;

  /// Removes a row. Null hides the remove buttons.
  final ValueChanged<int>? onRemove;

  /// A sentence per row that cannot be saved — "Ecru has no quantities.
  /// Type its total, or remove the colour." Its row is tinted.
  final Map<int, String> rowErrors;

  /// Formats a total.
  final String Function(int value)? numberFormatter;

  /// Splits [total] across parts in proportion to [ratio], by largest
  /// remainder: each part gets its floor, and the pieces left over go to the
  /// largest fractions — ties to the larger ratio — so the parts always sum
  /// to exactly [total]. A zero ratio splits evenly.
  static List<int> splitByRatio(int total, List<int> ratio) {
    if (ratio.isEmpty) return <int>[];
    final List<int> r = ratio.every((int x) => x <= 0)
        ? List<int>.filled(ratio.length, 1)
        : ratio.map((int x) => x < 0 ? 0 : x).toList();
    final int sum = r.fold<int>(0, (int a, int b) => a + b);
    final List<int> parts = <int>[
      for (final int x in r) (total * x) ~/ sum,
    ];
    final List<double> fractions = <double>[
      for (final int x in r) total * x / sum - (total * x) ~/ sum,
    ];
    int left = total - parts.fold<int>(0, (int a, int b) => a + b);
    final List<int> order = List<int>.generate(r.length, (int i) => i)
      ..sort((int a, int b) {
        final int byFraction = fractions[b].compareTo(fractions[a]);
        return byFraction != 0 ? byFraction : r[b].compareTo(r[a]);
      });
    for (final int i in order) {
      if (left <= 0) break;
      parts[i]++;
      left--;
    }
    return parts;
  }

  /// Reads a block pasted from a spreadsheet against [rowLabels].
  ///
  /// One line per row. Cells are split on tabs — what a spreadsheet copies —
  /// and only when a line has no tab, on commas or runs of spaces; so
  /// "1,200" in a tab-separated paste stays twelve hundred. A first cell that
  /// is not a number is the row's name, matched without regard to case; a
  /// line that starts with a number maps by position. Missing cells are zero.
  static FoQuantityPaste parsePaste(
    String text, {
    required List<String> rowLabels,
    required int columnCount,
  }) {
    final Map<int, List<int>> rows = <int, List<int>>{};
    final List<String> unknown = <String>[];
    final List<String> lines = text
        .split(RegExp(r'\r?\n'))
        .where((String l) => l.trim().isNotEmpty)
        .toList();
    for (int n = 0; n < lines.length; n++) {
      final String line = lines[n];
      final List<String> cells = (line.contains('\t')
              ? line.split('\t')
              : line.split(RegExp(r',|\s{2,}')))
          .map((String c) => c.trim())
          .toList();
      if (cells.isEmpty) continue;
      int? row;
      List<String> numbers = cells;
      if (int.tryParse(cells.first.replaceAll(',', '')) == null) {
        final String name = cells.first.toLowerCase();
        final int match =
            rowLabels.indexWhere((String l) => l.toLowerCase() == name);
        if (match < 0) {
          unknown.add(cells.first);
          continue;
        }
        row = match;
        numbers = cells.sublist(1);
      } else if (n < rowLabels.length) {
        row = n;
      }
      if (row == null) continue;
      rows[row] = <int>[
        for (int i = 0; i < columnCount; i++)
          i < numbers.length
              ? int.tryParse(numbers[i].replaceAll(',', '')) ?? 0
              : 0,
      ];
    }
    return FoQuantityPaste(rows: rows, unknown: unknown);
  }

  static const double _rowHeaderWidth = 200;
  static const double _cellWidth = FoNumberField.defaultBoxWidth + 16;
  static const double _totalWidth = 120;

  String _fmt(int v) => (numberFormatter ?? (int n) => '$n')(v);

  @override
  Widget build(BuildContext context) {
    final bool hasRatio = ratio != null && copy.ratioLabel != null;
    final bool editing =
        rows.any((FoQuantityRow r) => r.floors != null || r.originals != null);
    // Rows share one height so the pinned names line up with the cells; the
    // caption line under an edited box grows with the reader's text size.
    final double rowHeight = FoNumberField.controlHeight +
        context.foSpacing.md +
        (editing
            ? MediaQuery.textScalerOf(context).scale(FoTokens.fontCaption) * 1.4
            : 0);
    const double headerHeight = FoLayout.minTouchTarget;
    final List<int> columnTotals = <int>[
      for (int c = 0; c < columns.length; c++)
        rows.fold<int>(0, (int s, FoQuantityRow r) => s + r.values[c]),
    ];
    final int grand = columnTotals.fold<int>(0, (int a, int b) => a + b);

    Color? tint(int r) =>
        rowErrors.containsKey(r) ? context.foColors.warningSoft : null;
    BoxDecoration line(Color? fill) => BoxDecoration(
          color: fill,
          border: Border(top: BorderSide(color: context.foColors.edge)),
        );

    // ─── The pinned column ─────────────────────────────────────────────────
    final Widget pinned = SizedBox(
      width: _rowHeaderWidth,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _HeaderCell(text: copy.rowHeader, height: headerHeight, start: true),
          if (hasRatio)
            Container(
              height: rowHeight,
              decoration: line(context.foColors.surface),
              padding: EdgeInsets.symmetric(horizontal: context.foSpacing.md),
              alignment: AlignmentDirectional.centerStart,
              child: Text(copy.ratioLabel!, style: context.foText.label),
            ),
          for (int r = 0; r < rows.length; r++)
            Container(
              height: rowHeight,
              decoration: line(tint(r)),
              padding: EdgeInsetsDirectional.only(start: context.foSpacing.md),
              child: Row(
                children: <Widget>[
                  if (rows[r].leading != null) ...<Widget>[
                    rows[r].leading!,
                    SizedBox(width: context.foSpacing.sm),
                  ],
                  Expanded(
                    child: Semantics(
                      header: true,
                      child: Text(
                        rows[r].label,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: context.foText.subtitle,
                      ),
                    ),
                  ),
                  if (onCopyToNext != null && copy.copyLabel != null)
                    FoIconButton(
                      icon: Icons.south,
                      iconSize: FoTokens.iconSmall,
                      tone: FoIconButtonTone.primary,
                      semanticLabel: r < rows.length - 1
                          ? copy.copyLabel!(rows[r].label, rows[r + 1].label)
                          : rows[r].label,
                      onPressed:
                          r < rows.length - 1 ? () => onCopyToNext!(r) : null,
                    ),
                  if (onRemove != null && copy.removeLabel != null)
                    FoIconButton(
                      icon: Icons.close,
                      iconSize: FoTokens.iconSmall,
                      semanticLabel: copy.removeLabel!(rows[r].label),
                      onPressed: () => onRemove!(r),
                    ),
                ],
              ),
            ),
          Container(
            height: headerHeight,
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: context.foColors.edgeStrong, width: 2),
              ),
            ),
            padding: EdgeInsets.symmetric(horizontal: context.foSpacing.md),
            alignment: AlignmentDirectional.centerStart,
            child: Text(copy.allRowsLabel, style: context.foText.label),
          ),
        ],
      ),
    );

    // ─── The scrolling columns ─────────────────────────────────────────────
    Widget cellFor(int r, int c) {
      final FoQuantityRow row = rows[r];
      final int value = row.values[c];
      final int? floor = row.floors?[c];
      final int? was = row.originals?[c];
      final bool below = floor != null && value < floor;
      final bool changed = was != null && was != value;
      final String caption = <String>[
        if (changed && copy.wasCaption != null) copy.wasCaption!(was),
        if (floor != null && copy.floorCaption != null)
          copy.floorCaption!(floor),
      ].join(' · ');
      return Container(
        width: _cellWidth,
        height: rowHeight,
        decoration: line(changed ? context.foColors.primarySoft : tint(r)),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            FoNumberField(
              value: value,
              showSteppers: false,
              error: below || rowErrors.containsKey(r),
              semanticLabel: copy.cellLabel(row.label, columns[c]),
              onChanged: (int v) => onRowChanged(
                r,
                List<int>.of(row.values)..[c] = v,
              ),
            ),
            if (caption.isNotEmpty)
              Text(
                caption,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.foText.numeric.copyWith(
                  fontSize: FoTokens.fontCaption - 1,
                  color: below
                      ? context.foColors.danger
                      : changed
                          ? context.foColors.primary
                          : context.foColors.fgSubtle,
                ),
              ),
          ],
        ),
      );
    }

    final Widget scrolling = SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              for (final String c in columns)
                _HeaderCell(text: c, height: headerHeight, width: _cellWidth),
              _HeaderCell(
                text: copy.totalLabel,
                height: headerHeight,
                width: _totalWidth,
              ),
            ],
          ),
          if (hasRatio)
            Row(
              children: <Widget>[
                for (int c = 0; c < columns.length; c++)
                  Container(
                    width: _cellWidth,
                    height: rowHeight,
                    decoration: line(context.foColors.surface),
                    alignment: Alignment.center,
                    child: FoNumberField(
                      value: ratio![c],
                      max: 99,
                      showSteppers: false,
                      boxWidth: 56,
                      enabled: onRatioChanged != null,
                      semanticLabel: copy.ratioCellLabel?.call(columns[c]) ??
                          '${copy.ratioLabel} ${columns[c]}',
                      onChanged: (int v) =>
                          onRatioChanged?.call(List<int>.of(ratio!)..[c] = v),
                    ),
                  ),
                Container(
                  width: _totalWidth,
                  height: rowHeight,
                  decoration: line(context.foColors.surface),
                ),
              ],
            ),
          for (int r = 0; r < rows.length; r++)
            Row(
              children: <Widget>[
                for (int c = 0; c < columns.length; c++) cellFor(r, c),
                Container(
                  width: _totalWidth,
                  height: rowHeight,
                  decoration: line(tint(r) ?? context.foColors.surface),
                  alignment: Alignment.center,
                  child: hasRatio
                      ? FoNumberField(
                          value: rows[r].total,
                          showSteppers: false,
                          boxWidth: 96,
                          semanticLabel: copy.rowTotalLabel(rows[r].label),
                          onChanged: (int total) => onRowChanged(
                            r,
                            splitByRatio(total, ratio!),
                          ),
                        )
                      : Text(
                          _fmt(rows[r].total),
                          style: context.foText.numeric.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ],
            ),
          Container(
            height: headerHeight,
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: context.foColors.edgeStrong, width: 2),
              ),
            ),
            child: Row(
              children: <Widget>[
                for (final int t in columnTotals)
                  SizedBox(
                    width: _cellWidth,
                    child: Text(
                      _fmt(t),
                      textAlign: TextAlign.center,
                      style: context.foText.numeric.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                Container(
                  width: _totalWidth,
                  height: headerHeight,
                  alignment: Alignment.center,
                  color: context.foColors.primarySoft,
                  child: Semantics(
                    liveRegion: true,
                    child: Text(
                      _fmt(grand),
                      style: context.foText.numeric.copyWith(
                        fontSize: FoTokens.fontTitle,
                        fontWeight: FontWeight.w700,
                        color: context.foColors.primary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    final BorderRadius radius = BorderRadius.circular(context.foRadii.md);
    final List<String> belowFloor = <String>[
      if (copy.belowFloorMessage != null)
        for (final FoQuantityRow row in rows)
          if (row.floors != null)
            for (int c = 0; c < columns.length; c++)
              if (row.values[c] < row.floors![c])
                copy.belowFloorMessage!(row.label, columns[c], row.floors![c]),
    ];
    final List<String> errors = <String>[...rowErrors.values, ...belowFloor];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        ClipRRect(
          borderRadius: radius,
          child: DecoratedBox(
            decoration: BoxDecoration(color: context.foColors.surfaceRaised),
            child: DecoratedBox(
              position: DecorationPosition.foreground,
              decoration: BoxDecoration(
                borderRadius: radius,
                border: Border.all(color: context.foColors.edge),
              ),
              child: Material(
                type: MaterialType.transparency,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    // The row names never scroll away: typing into an
                    // unlabelled row is how a size ends up on the wrong
                    // colour.
                    DecoratedBox(
                      decoration: BoxDecoration(
                        border: BorderDirectional(
                          end: BorderSide(color: context.foColors.edge),
                        ),
                      ),
                      child: pinned,
                    ),
                    Expanded(child: scrolling),
                  ],
                ),
              ),
            ),
          ),
        ),
        for (final String e in errors) ...<Widget>[
          SizedBox(height: context.foSpacing.sm),
          Semantics(
            liveRegion: true,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Icon(
                  Icons.error_outline,
                  size: FoTokens.iconSmall,
                  color: context.foColors.danger,
                ),
                SizedBox(width: context.foSpacing.xs),
                Expanded(
                  child: Text(
                    e,
                    style: context.foText.label.copyWith(
                      color: context.foColors.danger,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _HeaderCell extends StatelessWidget {
  const _HeaderCell({
    required this.text,
    required this.height,
    this.width,
    this.start = false,
  });

  final String text;
  final double height;
  final double? width;
  final bool start;

  @override
  Widget build(BuildContext context) => Container(
        width: width,
        height: height,
        color: context.foColors.surfaceSunken,
        padding: EdgeInsets.symmetric(horizontal: context.foSpacing.md),
        alignment: start ? AlignmentDirectional.centerStart : Alignment.center,
        child: Text(
          text.toUpperCase(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: context.foText.caption,
        ),
      );
}

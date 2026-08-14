import 'package:flutter/material.dart';

import '../primitives/fo_section_surface.dart';
import '../theme/fo_context.dart';

/// One label/value pair in a [FoDetailTableSection].
@immutable
class FoDetailTableItem {
  /// Creates an item.
  const FoDetailTableItem({required this.label, required this.value});

  /// What the value is. Caller-supplied, so it can be localized.
  final String label;

  /// The value. A widget, so a chip or a boolean cell can sit here.
  final Widget value;
}

/// One column of a [FoDetailTableSection.table].
@immutable
class FoDetailTableColumn {
  /// Creates a column.
  const FoDetailTableColumn({
    required this.label,
    this.numeric = false,
    this.alignment,
  });

  /// The heading.
  final String label;

  /// Right-aligns the column, unless [alignment] overrides it.
  final bool numeric;

  /// Overrides the alignment [numeric] would choose.
  final AlignmentGeometry? alignment;
}

/// One row of a [FoDetailTableSection.table].
@immutable
class FoDetailTableRow {
  /// Creates a row.
  const FoDetailTableRow({required this.cells});

  /// The cells, aligned to the section's columns.
  final List<Widget> cells;
}

/// One block of a [FoDetailTable] — either a grid of label/value pairs or a
/// small table.
@immutable
class FoDetailTableSection {
  /// A grid of label/value pairs.
  const FoDetailTableSection({
    required this.items,
    this.title,
    this.columns = 2,
  })  : tableColumns = const <FoDetailTableColumn>[],
        rows = const <FoDetailTableRow>[];

  /// A small table with its own headings.
  const FoDetailTableSection.table({
    required this.tableColumns,
    required this.rows,
    this.title,
  })  : items = const <FoDetailTableItem>[],
        columns = 1;

  /// The block's name.
  final String? title;

  /// The pairs, for the grid form.
  final List<FoDetailTableItem> items;

  /// How many columns the grid uses on a wide window. Always one on a
  /// compact one.
  final int columns;

  /// The columns, for the table form.
  final List<FoDetailTableColumn> tableColumns;

  /// The rows, for the table form.
  final List<FoDetailTableRow> rows;

  /// Whether this section is the table form.
  bool get isTable => tableColumns.isNotEmpty;
}

/// The summary block on a detail screen: several sections, each a grid of
/// label/value pairs or a small table.
///
/// Distinct from `FoDescriptionList`, which is a single flat list of pairs.
/// Reach for this when a record has *groups* of fields that need naming, and
/// for that one when it does not.
class FoDetailTable extends StatelessWidget {
  /// Creates a detail table.
  const FoDetailTable({
    required this.sections,
    this.embedInSurface = false,
    super.key,
  });

  /// The sections, in reading order.
  final List<FoDetailTableSection> sections;

  /// True when the caller has already framed this — inside a `FoCard` or a
  /// `FoFormSurface`. Each section then renders bare rather than growing its
  /// own frame, so the two do not nest and draw two hairlines.
  final bool embedInSurface;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (int i = 0; i < sections.length; i++) ...<Widget>[
          _Section(section: sections[i], embedInSurface: embedInSurface),
          if (i < sections.length - 1) SizedBox(height: context.foSpacing.lg),
        ],
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.section, required this.embedInSurface});

  final FoDetailTableSection section;
  final bool embedInSurface;

  @override
  Widget build(BuildContext context) {
    final Widget content = section.isTable
        ? _TableContent(section: section)
        : _GridContent(section: section);

    if (!embedInSurface) {
      return FoSectionSurface(
        title: section.title,
        contentPadding: EdgeInsets.all(context.foSpacing.lg),
        child: content,
      );
    }

    if (section.title == null) return content;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(section.title!, style: context.foText.subtitle),
        SizedBox(height: context.foSpacing.md),
        content,
      ],
    );
  }
}

class _GridContent extends StatelessWidget {
  const _GridContent({required this.section});

  final FoDetailTableSection section;

  @override
  Widget build(BuildContext context) {
    // One column on a phone regardless of what the section asked for: two
    // columns at that width give each value about a third of the line.
    final int columnCount =
        !context.foWindowClass.isAtLeastMedium || section.items.isEmpty
            ? 1
            : section.columns.clamp(1, section.items.length);

    final List<List<FoDetailTableItem>> rows = <List<FoDetailTableItem>>[];
    for (int i = 0; i < section.items.length; i += columnCount) {
      final int end = (i + columnCount) > section.items.length
          ? section.items.length
          : i + columnCount;
      rows.add(section.items.sublist(i, end));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (int r = 0; r < rows.length; r++) ...<Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              for (int c = 0; c < rows[r].length; c++)
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: c == rows[r].length - 1 ? 0 : context.foSpacing.lg,
                    ),
                    child: _ItemCell(item: rows[r][c]),
                  ),
                ),
              // Placeholders so a short final row's cells keep the same width
              // as every other row's, rather than stretching to fill.
              for (int s = rows[r].length; s < columnCount; s++)
                const Expanded(child: SizedBox.shrink()),
            ],
          ),
          if (r < rows.length - 1) SizedBox(height: context.foSpacing.lg),
        ],
      ],
    );
  }
}

class _TableContent extends StatelessWidget {
  const _TableContent({required this.section});

  final FoDetailTableSection section;

  @override
  Widget build(BuildContext context) {
    final BorderRadius radius = BorderRadius.circular(context.foRadii.md);

    AlignmentGeometry alignmentOf(int i) =>
        section.tableColumns[i].alignment ??
        (section.tableColumns[i].numeric
            ? Alignment.centerRight
            : Alignment.centerLeft);

    return DecoratedBox(
      decoration: BoxDecoration(borderRadius: radius),
      // Rule §3.1: the heading row paints its own ground to the frame's edges
      // inside the clip, so the frame's hairline goes on top of it.
      child: DecoratedBox(
        position: DecorationPosition.foreground,
        decoration: BoxDecoration(
          borderRadius: radius,
          border: Border.all(color: context.foColors.edge),
        ),
        child: ClipRRect(
          borderRadius: radius,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    for (int i = 0; i < section.tableColumns.length; i++)
                      Expanded(
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: context.foSpacing.md,
                            vertical: context.foSpacing.sm,
                          ),
                          alignment: alignmentOf(i),
                          decoration: BoxDecoration(
                            // The heading is a well the column names sit in.
                            color: context.foColors.surfaceSunken,
                            border: Border(
                              right: i == section.tableColumns.length - 1
                                  ? BorderSide.none
                                  : BorderSide(color: context.foColors.edge),
                              bottom: BorderSide(color: context.foColors.edge),
                            ),
                          ),
                          child: Text(
                            section.tableColumns[i].label,
                            style: context.foText.label,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              for (int r = 0; r < section.rows.length; r++)
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      for (int c = 0; c < section.rows[r].cells.length; c++)
                        Expanded(
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: context.foSpacing.md,
                              vertical: context.foSpacing.sm,
                            ),
                            alignment: alignmentOf(c),
                            decoration: BoxDecoration(
                              border: Border(
                                right: c == section.rows[r].cells.length - 1
                                    ? BorderSide.none
                                    : BorderSide(
                                        color: context.foColors.edge,
                                      ),
                                bottom: r == section.rows.length - 1
                                    ? BorderSide.none
                                    : BorderSide(
                                        color: context.foColors.edge,
                                      ),
                              ),
                            ),
                            child: DefaultTextStyle(
                              style: context.foText.body,
                              child: section.rows[r].cells[c],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ItemCell extends StatelessWidget {
  const _ItemCell({required this.item});

  final FoDetailTableItem item;

  @override
  Widget build(BuildContext context) {
    // One announcement per pair, so a screen reader reads "Line: A" rather
    // than two unrelated fragments.
    return MergeSemantics(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          // The label names the value, which is what mono uppercase is for.
          Text(item.label.toUpperCase(), style: context.foText.caption),
          SizedBox(height: context.foSpacing.xs),
          DefaultTextStyle(style: context.foText.body, child: item.value),
        ],
      ),
    );
  }
}

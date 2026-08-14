import 'package:figuredout_ui/figuredout_ui.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

import '../../support/doc_page.dart';

/// A row of the sample table.
class Entry {
  /// Creates a sample row.
  const Entry(this.part, this.line, this.quantity, this.submitted);

  /// What was cut.
  final String part;

  /// Where.
  final String line;

  /// How many.
  final int quantity;

  /// Whether it has been submitted.
  final bool submitted;
}

const List<Entry> _entries = <Entry>[
  Entry('Sleeve panel', 'Line A', 1240, true),
  Entry('Collar band', 'Line A', 880, true),
  Entry('Front placket', 'Line B', 412, false),
  Entry('Cuff', 'Line C', 96, false),
];

List<FoTableColumn<Entry>> _columns(BuildContext context) =>
    <FoTableColumn<Entry>>[
      FoTableColumn<Entry>(
        label: const Text('Part'),
        size: FoColumnSize.l,
        cellBuilder: (BuildContext c, Entry e) => Text(e.part),
        cardValueBuilder: (Entry e) => e.part,
      ),
      FoTableColumn<Entry>(
        label: const Text('Line'),
        size: FoColumnSize.s,
        cellBuilder: (BuildContext c, Entry e) => Text(e.line),
        cardValueBuilder: (Entry e) => e.line,
      ),
      FoTableColumn<Entry>(
        label: const Text('Quantity'),
        size: FoColumnSize.s,
        numeric: true,
        sortable: true,
        // Figures are mono and tabular, so a column of them aligns.
        cellBuilder: (BuildContext c, Entry e) =>
            Text('${e.quantity}', style: c.foText.numeric),
        cardValueBuilder: (Entry e) => '${e.quantity}',
      ),
      FoTableColumn<Entry>(
        label: const Text('Submitted'),
        size: FoColumnSize.s,
        cellBuilder: (BuildContext c, Entry e) => FoBooleanCell(
          value: e.submitted,
          yesLabel: 'Yes',
          noLabel: 'No',
          label: 'Submitted',
        ),
        cardValueBuilder: (Entry e) => e.submitted ? 'Yes' : 'No',
      ),
    ];

/// The table in each of its four states, and in both layouts.
class DataTables extends StatelessWidget {
  /// Creates the table page.
  const DataTables({super.key});

  @override
  Widget build(BuildContext context) {
    // Tall enough for four compact cards, which is the tallest of the four
    // states this page shows.
    Widget framed(Widget child, {double height = 480}) =>
        SizedBox(height: height, child: child);

    return DocPage(
      title: 'Data table',
      lede: 'A table on a wide window, a list of cards on a narrow one — one '
          'component, because they are one table and the same columns feed '
          'both. Switch the viewport addon to Compact 480 to see the cards.',
      children: <Widget>[
        DocSection(
          title: 'Rows',
          child: framed(
            FoDataTable<Entry>(
              columns: _columns(context),
              rows: _entries,
              loading: false,
              errorTitle: 'Could not load entries',
              retryLabel: 'Retry',
              onRowTap: (_) {},
            ),
          ),
        ),
        DocSection(
          title: 'Loading',
          child: framed(
            FoDataTable<Entry>(
              columns: _columns(context),
              rows: const <Entry>[],
              loading: true,
              errorTitle: 'Could not load entries',
              retryLabel: 'Retry',
            ),
          ),
        ),
        DocSection(
          title: 'Failed',
          child: framed(
            FoDataTable<Entry>(
              columns: _columns(context),
              rows: const <Entry>[],
              loading: false,
              error: 'Connection refused',
              errorTitle: 'Could not load entries',
              retryLabel: 'Retry',
              onRetry: () {},
            ),
          ),
        ),
        DocSection(
          title: 'Empty',
          child: framed(
            FoDataTable<Entry>(
              columns: _columns(context),
              rows: const <Entry>[],
              loading: false,
              errorTitle: 'Could not load entries',
              retryLabel: 'Retry',
              emptyState: const FoEmptyState(
                icon: Icons.inbox_outlined,
                title: 'No entries yet',
                hint: 'Entries logged against this plan will appear here.',
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// The pagination bar, the filter bar and the tile grid.
class ListChrome extends StatefulWidget {
  /// Creates the list-chrome page.
  const ListChrome({super.key});

  @override
  State<ListChrome> createState() => _ListChromeState();
}

class _ListChromeState extends State<ListChrome> {
  final TextEditingController _search = TextEditingController();
  int _page = 2;
  bool _filtered = true;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DocPage(
      title: 'List chrome',
      lede: 'The parts around a list: the filter bar above it, the pagination '
          'bar below it, and the tile grid for when the records are tiles '
          'rather than rows.',
      children: <Widget>[
        DocSection(
          title: 'Filter bar',
          child: Column(
            children: <Widget>[
              FoFilterBar(
                hasActiveFilters: _filtered,
                clearLabel: 'Clear filters',
                onClear: () => setState(() => _filtered = false),
                children: <Widget>[
                  FoListSearchField(
                    controller: _search,
                    hintText: 'Search entries',
                    onChanged: (_) {},
                  ),
                  SizedBox(
                    width: 200,
                    child: FoDropdownField<String>(
                      label: 'Line',
                      value: 'A',
                      items: const <DropdownMenuItem<String>>[
                        DropdownMenuItem<String>(
                          value: 'A',
                          child: Text('Line A'),
                        ),
                      ],
                      onChanged: (_) {},
                    ),
                  ),
                ],
              ),
              SizedBox(height: context.foSpacing.sm),
              Text(
                _filtered
                    ? 'Clear it — the action disappears, which is the signal '
                        'that the list is now the whole list.'
                    : 'No filters set, so there is nothing to clear.',
                style: context.foText.body.copyWith(
                  color: context.foColors.fgSubtle,
                ),
              ),
            ],
          ),
        ),
        DocSection(
          title: 'Pagination bar',
          child: FoPaginationBar(
            page: _page,
            totalPages: 17,
            totalLabel: '340 entries',
            pageLabel: 'Page $_page of 17',
            previousTooltip: 'Previous page',
            nextTooltip: 'Next page',
            onPageChanged: (int page) => setState(() => _page = page),
          ),
        ),
        DocSection(
          title: 'Tile grid — note the last row',
          child: FoResponsiveTileGrid<int>(
            items: const <int>[1, 2, 3, 4, 5, 6],
            itemBuilder: (BuildContext context, int i) => FoCard(
              child: Text('Tile $i', style: context.foText.subtitle),
            ),
          ),
        ),
      ],
    );
  }
}

/// The table in all four states. Switch to Compact 480 for the card layout.
@widgetbook.UseCase(name: 'Data table', type: FoDataTable, path: '03 Patterns')
Widget buildDataTables(BuildContext context) => const DataTables();

/// Filter bar, pagination bar and tile grid.
@widgetbook.UseCase(name: 'Filter bar', type: FoFilterBar, path: '03 Patterns')
Widget buildFilterBars(BuildContext context) => const ListChrome();

/// The paged footer.
@widgetbook.UseCase(
  name: 'Pagination bar',
  type: FoPaginationBar,
  path: '03 Patterns',
)
Widget buildPaginationBars(BuildContext context) => const ListChrome();

/// A grid whose last partial row fills the width.
@widgetbook.UseCase(
  name: 'Tile grid',
  type: FoResponsiveTileGrid,
  path: '03 Patterns',
)
Widget buildTileGrids(BuildContext context) => const ListChrome();

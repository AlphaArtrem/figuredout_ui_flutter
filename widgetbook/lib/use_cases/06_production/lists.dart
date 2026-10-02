import 'package:figuredout_ui/figuredout_ui.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

import '../../support/doc_page.dart';

/// A list page's chrome: status tabs, filters, the side panel and the bar.
class ListPatterns extends StatefulWidget {
  /// Creates the list-patterns page.
  const ListPatterns({super.key});

  @override
  State<ListPatterns> createState() => _ListPatternsState();
}

class _ListPatternsState extends State<ListPatterns> {
  int _tab = 0;
  bool _open = true;
  final TextEditingController _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  static const List<(String, String, FoEntryStatus, String)> _rows =
      <(String, String, FoEntryStatus, String)>[
    ('Draft', 'Pique Polo · Ecru', FoEntryStatus.draft, '64'),
    ('PRS-00416', 'Pique Polo · Deep Navy', FoEntryStatus.submitted, '210'),
    (
      'PRS-00415',
      'Heavyweight Crew Tee · Jet Black',
      FoEntryStatus.changeRequested,
      '96',
    ),
  ];

  static const List<String> _statusWords = <String>[
    'Draft',
    'Submitted',
    'Change requested',
    'Needs approval',
  ];

  Widget _list(BuildContext context) => Material(
        type: MaterialType.transparency,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            for (final (
                  String code,
                  String what,
                  FoEntryStatus status,
                  String n
                ) in _rows)
              Padding(
                padding: EdgeInsets.all(context.foSpacing.lg),
                child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: context.foSpacing.md,
                  runSpacing: context.foSpacing.sm,
                  children: <Widget>[
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(code, style: context.foText.subtitle),
                        Text(what, style: context.foText.body),
                      ],
                    ),
                    Text(n, style: context.foText.numeric),
                    FoStatusChip.entry(
                      status: status,
                      label: _statusWords[status.index],
                    ),
                  ],
                ),
              ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final Widget panel = FoSidePanel(
      eyebrow: 'Pressing entry',
      title: 'PRS-00416',
      titleIsCode: true,
      status: FoStatusChip.entry(
        status: FoEntryStatus.submitted,
        label: 'Submitted',
      ),
      onClose: () => setState(() => _open = false),
      closeSemanticLabel: 'Close the panel',
      footer: Wrap(
        spacing: context.foSpacing.sm,
        runSpacing: context.foSpacing.sm,
        children: <Widget>[
          FoButton(
            label: 'Open order',
            variant: FoButtonVariant.clear,
            trailingIcon: Icons.arrow_forward,
            onPressed: () {},
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          FoDescriptionList(
            labelWidth: 96,
            items: <FoDescriptionItem>[
              FoDescriptionItem(
                label: 'Order',
                value: Text('Pique Polo', style: context.foText.body),
              ),
              FoDescriptionItem(
                label: 'Entered by',
                value: Text(
                  'Imran Sheikh · 1 Oct, 17:50',
                  style: context.foText.body,
                ),
              ),
            ],
          ),
          SizedBox(height: context.foSpacing.lg),
          FoInfoBanner.locked(
            title: 'Locked after submitting',
            message: 'Submitted entries are locked so totals stay right. If '
                'something is wrong, ask an owner to change it.',
            requestChangeLabel: 'Request a change',
            onRequestChange: () {},
          ),
        ],
      ),
    );

    return DocPage(
      title: 'List patterns',
      lede: 'Status tabs with counts, filters that apply on change, the list, '
          'and the record beside it on a wide window — or as its own page on '
          'anything narrower. The main action sits in a bar below the '
          'content on a phone, never floating over it.',
      children: <Widget>[
        DocSection(
          title: 'Status tabs and filters',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              FoStatusTabs(
                semanticLabel: 'Status',
                selectedIndex: _tab,
                onSelected: (int i) => setState(() => _tab = i),
                countFormatter: (int n) =>
                    n >= 1000 ? '${n ~/ 1000},${n % 1000}' : '$n',
                tabs: const <FoStatusTab>[
                  FoStatusTab(label: 'All', count: 418),
                  FoStatusTab(label: 'Drafts', count: 3),
                  FoStatusTab(label: 'Change requested', count: 3),
                  FoStatusTab(label: 'Submitted', count: 412),
                ],
              ),
              SizedBox(height: context.foSpacing.md),
              Wrap(
                spacing: context.foSpacing.sm,
                runSpacing: context.foSpacing.sm,
                children: <Widget>[
                  FoFilterButton(
                      label: 'Order', value: 'All', onPressed: () {}),
                  FoFilterButton(
                    value: 'Last 7 days',
                    icon: Icons.calendar_today_outlined,
                    isActive: true,
                    onPressed: () {},
                  ),
                ],
              ),
            ],
          ),
        ),
        DocSection(
          title: 'List and side panel',
          child: SizedBox(
            height: 560,
            child: FoListDetailLayout(
              list: FoListCard(
                header: FoToolbar(
                  search: FoListSearchField(
                    controller: _search,
                    hintText: 'Search pressing entries',
                    onChanged: (_) {},
                  ),
                  filters: <Widget>[
                    FoFilterButton(
                      label: 'Order',
                      value: 'All',
                      onPressed: () {},
                    ),
                  ],
                ),
                body: SingleChildScrollView(child: _list(context)),
                footer: FoPaginationBar(
                  page: 1,
                  totalPages: 21,
                  totalLabel: 'Showing 1–20 of 418',
                  pageLabel: 'Page 1 of 21',
                  previousTooltip: 'Previous page',
                  nextTooltip: 'Next page',
                  pageSemanticLabel: (int p) => 'Page $p',
                  onPageChanged: (_) {},
                ),
              ),
              detail: _open ? panel : null,
            ),
          ),
        ),
        DocSection(
          title: 'Action bar',
          child: FoActionBar(
            actions: <Widget>[
              FoButton(
                label: 'Record pressing',
                variant: FoButtonVariant.primary,
                size: FoButtonSize.large,
                icon: Icons.add,
                onPressed: () {},
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Loading, nothing yet, no matches, couldn't load, and offline.
class PageStates extends StatelessWidget {
  /// Creates the page-states page.
  const PageStates({super.key});

  @override
  Widget build(BuildContext context) {
    Widget framed(Widget child) => FoCard(
          child: SizedBox(height: 320, child: child),
        );

    return DocPage(
      title: 'Page states',
      lede: 'Four situations, four screens, each with a next step. A failed '
          'load is never shown as empty — that tells somebody their work is '
          'gone. Offline is a banner, not a state: the page still works.',
      children: <Widget>[
        DocSection(
          title: 'Offline',
          child: FoInfoBanner.offline(
            title: "You're offline.",
            message: 'New entries are kept on this phone and sent when the '
                'connection is back.',
            pending: '2 waiting to send',
          ),
        ),
        DocSection(
          title: 'Loading',
          child: framed(const FoSkeletonList(itemCount: 3, itemHeight: 64)),
        ),
        DocSection(
          title: 'Nothing yet',
          child: framed(
            FoEmptyState(
              icon: Icons.assignment_outlined,
              title: 'No pressing entries yet',
              hint: 'Entries show here after someone records pressing.',
              actionLabel: 'Record pressing',
              onAction: () {},
            ),
          ),
        ),
        DocSection(
          title: 'No matches',
          child: framed(
            FoEmptyState.noResults(
              title: 'Nothing matches these filters',
              hint: 'Try a different search, or clear the filters to see '
                  'everything.',
              actionLabel: 'Clear filters',
              onAction: () {},
            ),
          ),
        ),
        DocSection(
          title: "Couldn't load",
          child: framed(
            FoEmptyState.error(
              title: "Couldn't load pressing entries",
              hint: 'Check the connection and try again. Nothing you entered '
                  'is lost.',
              actionLabel: 'Try again',
              onAction: () {},
            ),
          ),
        ),
        DocSection(
          title: 'Help next to the word',
          child: Row(
            children: <Widget>[
              Flexible(child: Text('Midline', style: context.foText.title)),
              const FoHint.guide(
                buttonLabel: 'What is Midline?',
                guideTitle: 'What is Midline?',
                guideBody: Text(
                  'A check part-way down the line. Count pieces whose parts '
                  "match, and those that don't match, are missing or need "
                  'altering.',
                ),
                closeLabel: 'Close the guide',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Status tabs, filter buttons, list and side panel, action bar.
@widgetbook.UseCase(
  name: 'List and side panel',
  type: FoListDetailLayout,
  path: '06 Production',
)
Widget buildListPatterns(BuildContext context) => const ListPatterns();

/// Loading, empty, no matches, couldn't load, offline, help.
@widgetbook.UseCase(
  name: 'Page states',
  type: FoEmptyState,
  path: '06 Production',
)
Widget buildPageStates(BuildContext context) => const PageStates();

import 'package:figuredout_ui/figuredout_ui.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

import '../../support/doc_page.dart';

const FoDiscardCopy _discardCopy = FoDiscardCopy(
  title: 'Discard changes?',
  message: 'Your edits will be lost.',
  confirmLabel: 'Discard',
  cancelLabel: 'Keep editing',
);

/// The detail table, in both of its forms.
class DetailTables extends StatelessWidget {
  /// Creates the detail-table page.
  const DetailTables({super.key});

  @override
  Widget build(BuildContext context) {
    return DocPage(
      title: 'Detail table',
      lede: 'The summary block on a detail screen. Distinct from '
          'FoDescriptionList, which is one flat list of pairs — reach for this '
          'when a record has groups of fields that need naming.',
      children: <Widget>[
        DocSection(
          title: 'Sections of pairs, and a small table',
          child: FoDetailTable(
            sections: <FoDetailTableSection>[
              FoDetailTableSection(
                title: 'Plan',
                items: <FoDetailTableItem>[
                  FoDetailTableItem(
                    label: 'Reference',
                    value: Text('CP-2026-0814', style: context.foText.numeric),
                  ),
                  const FoDetailTableItem(
                    label: 'Status',
                    value: FoStatusChip.tone(
                      label: 'Open',
                      tone: FoStatusTone.primary,
                      semanticPrefix: 'Status',
                    ),
                  ),
                  FoDetailTableItem(
                    label: 'Line',
                    value: Text('Line A', style: context.foText.body),
                  ),
                  FoDetailTableItem(
                    label: 'Opened',
                    value: Text('14 Aug 2026', style: context.foText.body),
                  ),
                ],
              ),
              FoDetailTableSection.table(
                title: 'By stage',
                tableColumns: const <FoDetailTableColumn>[
                  FoDetailTableColumn(label: 'Stage'),
                  FoDetailTableColumn(label: 'Planned', numeric: true),
                  FoDetailTableColumn(label: 'Actual', numeric: true),
                ],
                rows: <FoDetailTableRow>[
                  for (final (String, String, String) row
                      in const <(String, String, String)>[
                    ('Cutting', '4,000', '4,000'),
                    ('Stitching', '4,000', '3,100'),
                    ('Finishing', '3,100', '2,450'),
                  ])
                    FoDetailTableRow(
                      cells: <Widget>[
                        Text(row.$1, style: context.foText.body),
                        Text(row.$2, style: context.foText.numeric),
                        Text(row.$3, style: context.foText.numeric),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),
        DocSection(
          title: 'Embedded — the caller already framed it',
          child: FoCard(
            child: FoDetailTable(
              embedInSurface: true,
              sections: <FoDetailTableSection>[
                FoDetailTableSection(
                  title: 'Plan',
                  items: <FoDetailTableItem>[
                    FoDetailTableItem(
                      label: 'Reference',
                      value: Text(
                        'CP-2026-0814',
                        style: context.foText.numeric,
                      ),
                    ),
                    FoDetailTableItem(
                      label: 'Line',
                      value: Text('Line A', style: context.foText.body),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// The searchable picker and the one-field prompt.
class PickersAndPrompts extends StatefulWidget {
  /// Creates the picker page.
  const PickersAndPrompts({super.key});

  @override
  State<PickersAndPrompts> createState() => _PickersAndPromptsState();
}

class _PickersAndPromptsState extends State<PickersAndPrompts> {
  final TextEditingController _picked = TextEditingController();
  String? _pickedId;
  String? _promptResult;

  /// The order filter: null is "All", and the scope the picker was last on.
  FoEntityPickerOption? _order;
  int _orderScope = 0;

  // The PickerWeb and PickerPhone boards: running orders first, all on ask.
  static const List<(FoEntityPickerOption, bool)> _orders =
      <(FoEntityPickerOption, bool)>[
    (
      FoEntityPickerOption(
        id: '10024',
        label: 'Pique Polo',
        supportingText: 'JOB-2026-10024 · Hanworth & Vale',
        meta: '308 waiting to press',
      ),
      true,
    ),
    (
      FoEntityPickerOption(
        id: '10019',
        label: 'Slim Chino',
        supportingText: 'JOB-2026-10019 · Meridian Basics Co.',
        meta: '212 waiting to press',
      ),
      true,
    ),
    (
      FoEntityPickerOption(
        id: '10031',
        label: 'Heavyweight Crew Tee',
        supportingText: 'JOB-2026-10031 · Kestrel Outfitters',
        meta: '96 waiting to press',
      ),
      true,
    ),
    (
      FoEntityPickerOption(
        id: '10027',
        label: 'Oxford Button-Down',
        supportingText: 'JOB-2026-10027 · Nordstrom Apparel Group',
        meta: 'Due 21 Oct',
      ),
      true,
    ),
    (
      FoEntityPickerOption(
        id: '10029',
        label: 'Brushed Fleece Hoodie',
        supportingText: 'JOB-2026-10029 · Kestrel Outfitters',
        meta: 'Due 6 Nov',
      ),
      true,
    ),
    (
      FoEntityPickerOption(
        id: '10022',
        label: 'Canvas Work Jacket',
        supportingText: 'JOB-2026-10022 · Hanworth & Vale',
        meta: 'On hold',
      ),
      false,
    ),
    (
      FoEntityPickerOption(
        id: '10014',
        label: 'Jersey Henley',
        supportingText: 'JOB-2026-10014 · Nordstrom Apparel Group',
        meta: 'Sent 26 Sep',
      ),
      false,
    ),
  ];

  static const List<FoLookupScope> _orderScopes = <FoLookupScope>[
    FoLookupScope(label: 'Running', count: 22),
    FoLookupScope(label: 'All orders', count: 25),
  ];

  static const FoEntityPickerCopy _orderCopy = FoEntityPickerCopy(
    searchHint: 'Job number, article or buyer',
    emptyText: 'No orders match. Check the job number, or look in all '
        'orders, not just running ones.',
    errorText: "Couldn't load orders.",
    clearTooltip: 'Clear',
    requiredMessage: 'Choose an order.',
    closeLabel: 'Close without choosing',
    recentLabel: 'You used recently',
    likelyLabel: 'Pieces waiting at pressing',
    resultsLabel: 'All running orders, due soonest first',
    scanLabel: 'Scan job card',
    retryLabel: 'Try again',
    scopesLabel: 'Which orders',
    moveHint: 'move',
    chooseHint: 'choose',
    closeHint: 'close',
  );

  Future<List<FoEntityPickerOption>> _searchOrders(String query) async {
    final String q = query.toLowerCase();
    return <FoEntityPickerOption>[
      for (final (FoEntityPickerOption o, bool running) in _orders)
        if ((_orderScope == 1 || running) &&
            '${o.label} ${o.supportingText}'.toLowerCase().contains(q))
          o,
    ];
  }

  Future<void> _chooseOrder(BuildContext context) async {
    final FoEntityPickerOption? picked = await FoLookupPicker.show(
      context,
      title: 'Choose an order',
      subtitle: 'Filter pressing entries',
      copy: _orderCopy,
      search: _searchOrders,
      recent: <FoEntityPickerOption>[_orders[0].$1, _orders[1].$1],
      likely: <FoEntityPickerOption>[_orders[2].$1],
      scopes: _orderScopes,
      initialScope: _orderScope,
      onScopeChanged: (int i) => _orderScope = i,
      noneLabel: 'No filter: all orders',
      onScan: () async => _orders[2].$1,
      totalLabel: (int shown, int? total) => total == null || shown >= total
          ? null
          : 'Showing the first $shown of $total. Keep typing to narrow it '
              'down.',
    );
    if (picked == null || !mounted) return;
    setState(() => _order = picked.isNone ? null : picked);
  }

  static const List<FoEntityPickerOption> _options = <FoEntityPickerOption>[
    FoEntityPickerOption(
      id: '1',
      label: 'Sleeve panel',
      supportingText: 'SKU 4021 · Line A',
    ),
    FoEntityPickerOption(
      id: '2',
      label: 'Collar band',
      supportingText: 'SKU 4088 · Line A',
    ),
    FoEntityPickerOption(
      id: '3',
      label: 'Front placket',
      supportingText: 'SKU 4110 · Line B',
    ),
  ];

  static const FoEntityPickerCopy _copy = FoEntityPickerCopy(
    searchHint: 'Type to search parts',
    emptyText: 'No parts match that search.',
    errorText: 'Could not load parts.',
    clearTooltip: 'Clear',
    requiredMessage: 'Pick a part.',
    closeLabel: 'Close',
    recentLabel: 'Recent',
    resultsLabel: 'All parts',
    retryLabel: 'Try again',
  );

  @override
  void dispose() {
    _picked.dispose();
    super.dispose();
  }

  Future<List<FoEntityPickerOption>> _search(String query) async {
    if (query.isEmpty) return _options;
    final String q = query.toLowerCase();
    return _options
        .where((FoEntityPickerOption o) => o.label.toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return DocPage(
      title: 'Picker and prompt',
      lede: 'A dropdown stops working somewhere around thirty options; the '
          'picker is what replaces it. It is a dialog on a wide window and a '
          'full screen on a phone, searches as you type, and puts recent '
          'choices first. The text prompt goes through FoFormPresenter.',
      children: <Widget>[
        DocSection(
          title: 'Entity picker',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              SizedBox(
                width: 360,
                child: FoEntityPickerField(
                  controller: _picked,
                  label: 'Part',
                  selectedId: _pickedId,
                  isRequired: true,
                  copy: _copy,
                  search: _search,
                  recent: const <FoEntityPickerOption>[
                    FoEntityPickerOption(
                      id: '2',
                      label: 'Collar band',
                      supportingText: 'SKU 4088 · Line A',
                      meta: 'Picked yesterday',
                    ),
                  ],
                  onSelected: (FoEntityPickerOption? o) =>
                      setState(() => _pickedId = o?.id),
                ),
              ),
              SizedBox(height: context.foSpacing.sm),
              Text(
                _pickedId == null
                    ? 'Nothing picked yet.'
                    : 'Picked id: $_pickedId',
                style: context.foText.body.copyWith(
                  color: context.foColors.fgSubtle,
                ),
              ),
            ],
          ),
        ),
        DocSection(
          title: 'Lookup picker with scopes',
          child: Builder(
            builder: (BuildContext context) => Align(
              alignment: AlignmentDirectional.centerStart,
              child: FoFilterButton(
                label: 'Order',
                value: _order?.label ?? 'All',
                isActive: _order != null,
                onPressed: () => _chooseOrder(context),
              ),
            ),
          ),
        ),
        DocSection(
          title: 'Text prompt',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              FoButton(
                label: 'Ask for a reason',
                variant: FoButtonVariant.secondary,
                onPressed: () async {
                  final String? result = await showFoTextPrompt(
                    context,
                    title: 'Override reason',
                    subtitle: 'This is recorded against the entry.',
                    fieldLabel: 'Reason',
                    hintText: 'Why the planned quantity was exceeded',
                    confirmLabel: 'Save reason',
                    cancelLabel: 'Cancel',
                    maxLines: 3,
                    discardCopy: _discardCopy,
                  );
                  if (!context.mounted) return;
                  setState(() => _promptResult = result);
                },
              ),
              SizedBox(height: context.foSpacing.sm),
              Text(
                _promptResult == null
                    ? 'Nothing submitted yet. Note the confirm button stays '
                        'disabled until there is something to submit.'
                    : 'Submitted: $_promptResult',
                style: context.foText.body.copyWith(
                  color: context.foColors.fgSubtle,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Grouped fields and a small table, on a detail screen.
@widgetbook.UseCase(
  name: 'Detail table',
  type: FoDetailTable,
  path: '03 Patterns',
)
Widget buildDetailTables(BuildContext context) => const DetailTables();

/// Picking one record out of many, by searching.
@widgetbook.UseCase(
  name: 'Entity picker',
  type: FoEntityPickerField,
  path: '03 Patterns',
)
Widget buildEntityPickers(BuildContext context) => const PickersAndPrompts();

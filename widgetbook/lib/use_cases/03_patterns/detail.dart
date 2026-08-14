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
    discardCopy: _discardCopy,
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
          'picker is what replaces it. Both go through FoFormPresenter, so '
          'they honour the same dialog-versus-sheet breakpoint as every other '
          'modal instead of always being a sheet.',
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

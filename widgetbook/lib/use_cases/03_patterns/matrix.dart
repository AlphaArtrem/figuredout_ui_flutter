import 'package:figuredout_ui/figuredout_ui.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

import '../../support/doc_page.dart';

const List<String> _sizes = <String>['S', 'M', 'L', 'XL', '2XL', '3XL'];

const Map<String, List<int>> _cut = <String, List<int>>{
  'Navy': <int>[120, 340, 410, 260, 90, 0],
  'Ecru': <int>[80, 210, 260, 140, 40, 0],
};

const Map<String, List<int>> _pressed = <String, List<int>>{
  'Navy': <int>[120, 336, 402, 251, 88, 0],
  'Ecru': <int>[78, 205, 254, 139, 40, 0],
};

List<FoMatrixColumn> _columns() => <FoMatrixColumn>[
      for (final String size in _sizes)
        FoMatrixColumn(label: FoMatrixHeaderText(size), width: 84),
    ];

int _sumAt(int index, Iterable<List<int>> rows) =>
    rows.fold(0, (int sum, List<int> row) => sum + row[index]);

/// A grouped read-only grid: two stages, one summary row.
///
/// The shape a size breakdown takes everywhere — sizes across the top, a
/// colour or a stage down the side. Note that the grid keeps its shape at
/// every width rather than reflowing: the position of a cell in two dimensions
/// is what it means, so there is nothing to reflow it into.
class GroupedMatrix extends StatelessWidget {
  /// Creates the example.
  const GroupedMatrix({super.key});

  @override
  Widget build(BuildContext context) {
    return DocPage(
      title: 'Matrix table',
      lede: 'Sizes across, stages down. Fixed-width columns, because a matrix '
          'is read down its columns as much as across its rows.',
      children: <Widget>[
        DocSection(
          title: 'Grouped, with a summary row',
          child: FoMatrixTable(
            columnGroupLabel: 'Sizes',
            leadingHeader: const FoMatrixHeaderText(
              'Stage / colour',
              textAlign: TextAlign.left,
            ),
            columns: _columns(),
            sections: <FoMatrixSection>[
              FoMatrixSection(
                label: 'Cutting',
                rows: <FoMatrixRow>[
                  for (final MapEntry<String, List<int>> e in _cut.entries)
                    FoMatrixRow(
                      leading: Text(e.key),
                      cells: <Widget>[
                        for (final int q in e.value)
                          Text('$q', style: context.foText.numeric),
                      ],
                    ),
                ],
              ),
              FoMatrixSection(
                label: 'Pressing',
                rows: <FoMatrixRow>[
                  for (final MapEntry<String, List<int>> e in _pressed.entries)
                    FoMatrixRow(
                      leading: Text(e.key),
                      cells: <Widget>[
                        for (final int q in e.value)
                          Text('$q', style: context.foText.numeric),
                      ],
                    ),
                ],
              ),
            ],
            summaryRow: FoMatrixSummaryRow(
              leading: const Text('Total'),
              cells: <Widget>[
                for (int i = 0; i < _sizes.length; i++)
                  FoMatrixTotalText(
                    _sumAt(i, _cut.values) + _sumAt(i, _pressed.values),
                  ),
              ],
            ),
          ),
        ),
        const DocSection(
          title: 'Validation',
          child: FoMatrixValidationText(
            'Pressed quantity exceeds the quantity cut.',
          ),
        ),
      ],
    );
  }
}

/// An editable grid with the row labels pinned.
///
/// Narrow the viewport with the addon until the columns overflow: the labels
/// stay put while the values scroll. Without that, scrolling right takes the
/// labels with it and the user ends up typing into unlabelled rows.
class EditableMatrix extends StatefulWidget {
  /// Creates the example.
  const EditableMatrix({super.key});

  @override
  State<EditableMatrix> createState() => _EditableMatrixState();
}

class _EditableMatrixState extends State<EditableMatrix> {
  final Map<String, List<int>> _values = <String, List<int>>{
    for (final MapEntry<String, List<int>> e in _cut.entries)
      e.key: List<int>.of(e.value),
  };

  @override
  Widget build(BuildContext context) {
    return DocPage(
      title: 'Matrix table — editable',
      lede: 'The leading column is pinned, so the labels stay beside the '
          'values as the grid scrolls sideways.',
      children: <Widget>[
        DocSection(
          title: 'Pinned leading column',
          child: FoMatrixTable(
            pinLeadingColumn: true,
            leadingHeader: const FoMatrixHeaderText(
              'Colour',
              textAlign: TextAlign.left,
            ),
            columns: _columns(),
            sections: <FoMatrixSection>[
              FoMatrixSection(
                rows: <FoMatrixRow>[
                  for (final MapEntry<String, List<int>> e in _values.entries)
                    FoMatrixRow(
                      leading: Text(e.key),
                      cells: <Widget>[
                        for (int i = 0; i < _sizes.length; i++)
                          FoMatrixNumericCell(
                            value: e.value[i],
                            onChanged: (int q) => setState(() {
                              _values[e.key]![i] = q;
                            }),
                          ),
                      ],
                    ),
                ],
              ),
            ],
            summaryRow: FoMatrixSummaryRow(
              leading: const Text('Total'),
              cells: <Widget>[
                for (int i = 0; i < _sizes.length; i++)
                  FoMatrixTotalText(_sumAt(i, _values.values)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// The read-only grid, grouped, with totals.
@widgetbook.UseCase(
  name: 'Matrix table',
  type: FoMatrixTable,
  path: '03 Patterns',
)
Widget buildGroupedMatrix(BuildContext context) => const GroupedMatrix();

/// The editable grid with its leading column pinned.
@widgetbook.UseCase(
  name: 'Matrix table — editable',
  type: FoMatrixNumericCell,
  path: '03 Patterns',
)
Widget buildEditableMatrix(BuildContext context) => const EditableMatrix();

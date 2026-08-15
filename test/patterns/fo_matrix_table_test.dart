import 'package:figuredout_ui/figuredout_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/pump.dart';

List<FoMatrixColumn> _columns([int count = 3]) => <FoMatrixColumn>[
      for (int i = 0; i < count; i++)
        FoMatrixColumn(label: FoMatrixHeaderText('C$i')),
    ];

FoMatrixRow _row(String label, List<int> cells) => FoMatrixRow(
      leading: Text(label),
      cells: <Widget>[for (final int c in cells) Text('$c')],
    );

void main() {
  group('FoMatrixTable', () {
    testWidgets('renders headings, section labels, rows and totals', (
      WidgetTester tester,
    ) async {
      await pumpFo(
        tester,
        surfaceSize: const Size(1280, 900),
        child: FoMatrixTable(
          columnGroupLabel: 'Sizes',
          leadingHeader: const FoMatrixHeaderText('Colour'),
          columns: _columns(),
          sections: <FoMatrixSection>[
            FoMatrixSection(
              label: 'Cutting',
              rows: <FoMatrixRow>[
                _row('Navy', <int>[1, 2, 3])
              ],
            ),
          ],
          summaryRow: const FoMatrixSummaryRow(
            leading: Text('Total'),
            cells: <Widget>[
              FoMatrixTotalText(1),
              FoMatrixTotalText(2),
              FoMatrixTotalText(3),
            ],
          ),
        ),
      );

      expect(find.text('Sizes'), findsOneWidget);
      expect(find.text('Colour'), findsOneWidget);
      expect(find.text('Cutting'), findsOneWidget);
      expect(find.text('Navy'), findsOneWidget);
      expect(find.text('Total'), findsOneWidget);
      expect(find.text('C0'), findsOneWidget);
    });

    testWidgets('a row with the wrong cell count fails loudly', (
      WidgetTester tester,
    ) async {
      // The assertion is the whole safety net here: a short row would
      // otherwise render as a silently misaligned grid, which is worse than
      // a crash because the numbers still look like numbers.
      await pumpFo(
        tester,
        child: FoMatrixTable(
          columns: _columns(),
          sections: <FoMatrixSection>[
            FoMatrixSection(rows: <FoMatrixRow>[
              _row('Navy', <int>[1, 2])
            ]),
          ],
        ),
      );

      expect(tester.takeException(), isAssertionError);
    });

    testWidgets('the pinned leading column scrolls independently', (
      WidgetTester tester,
    ) async {
      await pumpFo(
        tester,
        // Narrow enough that eight 108pt columns cannot fit, which is the
        // only case the pin exists for.
        surfaceSize: const Size(500, 700),
        child: FoMatrixTable(
          pinLeadingColumn: true,
          leadingHeader: const FoMatrixHeaderText('Colour'),
          columns: _columns(8),
          sections: <FoMatrixSection>[
            FoMatrixSection(
              rows: <FoMatrixRow>[
                _row('Navy', const <int>[1, 2, 3, 4, 5, 6, 7, 8]),
              ],
            ),
          ],
        ),
      );

      final double labelBefore = tester.getTopLeft(find.text('Navy')).dx;
      final double valueBefore = tester.getTopLeft(find.text('C0')).dx;

      await tester.drag(find.byType(Scrollable).last, const Offset(-400, 0));
      await tester.pumpAndSettle();

      // The values move and the label does not — that is the whole point of
      // the mode. Without it the labels scroll away and the user ends up
      // typing into unlabelled rows.
      expect(tester.getTopLeft(find.text('C0')).dx, lessThan(valueBefore));
      expect(tester.getTopLeft(find.text('Navy')).dx, labelBefore);
    });

    testWidgets('an editable cell reports its parsed value', (
      WidgetTester tester,
    ) async {
      int? seen;
      await pumpFo(
        tester,
        surfaceSize: const Size(900, 700),
        child: FoMatrixTable(
          columns: _columns(1),
          sections: <FoMatrixSection>[
            FoMatrixSection(
              rows: <FoMatrixRow>[
                FoMatrixRow(
                  leading: const Text('Navy'),
                  cells: <Widget>[
                    FoMatrixNumericCell(
                      value: 0,
                      onChanged: (int q) => seen = q,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      );

      await tester.enterText(find.byType(TextFormField), '42');
      expect(seen, 42);

      // A half-typed cell is not an error; it is zero until it is a number.
      await tester.enterText(find.byType(TextFormField), '');
      expect(seen, 0);
    });

    testWidgets('an editable cell marks the enclosing form dirty', (
      WidgetTester tester,
    ) async {
      final FoFormController controller = FoFormController();

      await pumpFo(
        tester,
        surfaceSize: const Size(900, 700),
        child: FoFormScope(
          controller: controller,
          child: FoMatrixTable(
            columns: _columns(1),
            sections: <FoMatrixSection>[
              FoMatrixSection(
                rows: <FoMatrixRow>[
                  FoMatrixRow(
                    leading: const Text('Navy'),
                    cells: <Widget>[
                      FoMatrixNumericCell(value: 0, onChanged: (int _) {}),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      );

      expect(controller.dirty.value, isFalse);
      await tester.enterText(find.byType(TextFormField), '7');
      // Otherwise closing a size grid discards the edits without asking —
      // the guard `FoTextField` gets for free.
      expect(controller.dirty.value, isTrue);
    });
  });
}

import 'dart:async';

import 'package:figuredout_ui/figuredout_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/pump.dart';

const Size _phone = Size(400, 860);
const Size _desktop = Size(1280, 900);

Future<void> _app(
  WidgetTester tester, {
  required Widget child,
  Size size = _desktop,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pumpWidget(
    MaterialApp(
      theme: FoTheme.light(),
      home: Scaffold(body: SingleChildScrollView(child: child)),
    ),
  );
}

/// A host that opens something with a button, so overlays have a navigator.
Widget _opener(void Function(BuildContext) open) => Builder(
      builder: (BuildContext context) => TextButton(
        onPressed: () => open(context),
        child: const Text('Open'),
      ),
    );

void main() {
  group('FoChoiceGroup', () {
    testWidgets('single: reports a new pick, never the current one', (
      WidgetTester tester,
    ) async {
      final List<String> picked = <String>[];
      await pumpFo(
        tester,
        child: FoChoiceGroup<String>.single(
          semanticLabel: 'What was wrong, size M',
          value: 'stain',
          onChanged: picked.add,
          choices: const <FoChoice<String>>[
            FoChoice<String>(value: 'stain', label: 'Stain', count: 2),
            FoChoice<String>(value: 'hole', label: 'Hole'),
          ],
        ),
      );
      await tester.tap(find.text('Stain'));
      await tester.tap(find.text('Hole'));
      expect(picked, <String>['hole']);
      // The count is part of the name; selection is not colour alone.
      expect(find.bySemanticsLabel('Stain, 2'), findsOneWidget);
      expect(find.byIcon(Icons.check), findsOneWidget);
    });

    testWidgets('multiple: toggles in and out of the set', (
      WidgetTester tester,
    ) async {
      Set<int> values = <int>{1};
      await pumpFo(
        tester,
        child: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) =>
              FoChoiceGroup<int>.multiple(
            semanticLabel: 'Lines',
            layout: FoChoiceLayout.cards,
            values: values,
            onChanged: (Set<int> v) => setState(() => values = v),
            choices: const <FoChoice<int>>[
              FoChoice<int>(value: 1, label: 'Line 1', description: 'Priya'),
              FoChoice<int>(value: 4, label: 'Line 4'),
            ],
          ),
        ),
      );
      await tester.tap(find.text('Line 4'));
      await tester.pump();
      await tester.tap(find.text('Line 1'));
      await tester.pump();
      expect(values, <int>{4});
    });

    testWidgets('an error says what to do', (WidgetTester tester) async {
      await pumpFo(
        tester,
        child: FoChoiceGroup<int>.single(
          semanticLabel: 'Fault',
          value: null,
          onChanged: (_) {},
          errorText: 'Choose what was wrong to go on.',
          choices: const <FoChoice<int>>[FoChoice<int>(value: 1, label: 'A')],
        ),
      );
      expect(find.text('Choose what was wrong to go on.'), findsOneWidget);
      expect(
        tester.getSize(find.text('A')).height,
        lessThan(48),
        reason: 'the label is small; the target around it is not',
      );
    });
  });

  group('FoPinPad', () {
    testWidgets('completes on the last digit and restarts after a refusal', (
      WidgetTester tester,
    ) async {
      String pin = '';
      String? error;
      final List<String> completed = <String>[];
      await pumpFo(
        tester,
        surfaceSize: _phone,
        child: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) => SizedBox(
            width: 320,
            child: FoPinPad(
              value: pin,
              errorText: error,
              onChanged: (String v) => setState(() {
                pin = v;
                error = null;
              }),
              onCompleted: (String v) {
                completed.add(v);
                setState(() => error = 'That PIN is wrong.');
              },
              progressSemanticLabel: (int n, int of) => '$n of $of typed',
              deleteSemanticLabel: 'Delete last digit',
            ),
          ),
        ),
      );
      for (final String d in <String>['1', '2', '3', '4']) {
        await tester.tap(find.bySemanticsLabel(d));
        await tester.pump();
      }
      expect(completed, <String>['1234']);
      expect(find.text('That PIN is wrong.'), findsOneWidget);

      await tester.tap(find.bySemanticsLabel('5'));
      await tester.pump();
      expect(pin, '5', reason: 'a refused PIN is not appended to');
      expect(find.bySemanticsLabel('1 of 4 typed'), findsOneWidget);
    });
  });

  group('read-only figures', () {
    testWidgets('a proportion bar says the split in words', (
      WidgetTester tester,
    ) async {
      await pumpFo(
        tester,
        child: const SizedBox(
          width: 300,
          child: FoProportionBar(
            semanticLabel: '32 passed, 5 to alter, 1 rejected',
            showLegend: true,
            remaining: 2,
            parts: <FoProportionPart>[
              FoProportionPart(
                label: 'Passed',
                value: 32,
                tone: FoStatusTone.success,
              ),
              FoProportionPart(
                label: 'Alter',
                value: 5,
                tone: FoStatusTone.warning,
              ),
              FoProportionPart(
                label: 'Reject',
                value: 0,
                tone: FoStatusTone.danger,
              ),
            ],
          ),
        ),
      );
      expect(
        find.bySemanticsLabel('32 passed, 5 to alter, 1 rejected'),
        findsOneWidget,
      );
      expect(find.text('Reject'), findsOneWidget, reason: 'legend lists all');
    });

    testWidgets('a size strip wraps rather than shrinking past legibility', (
      WidgetTester tester,
    ) async {
      await pumpFo(
        tester,
        child: SizedBox(
          width: 200,
          child: FoSizeValueStrip(
            values: <FoSizeValue>[
              for (final String s in <String>['S', 'M', 'L', 'XL', 'XXL'])
                FoSizeValue(size: s, value: '20', caption: 'of 20'),
            ],
            total: const FoSizeValue(size: 'Total', value: '100'),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      final double s = tester.getTopLeft(find.text('S')).dy;
      final double total = tester.getTopLeft(find.text('TOTAL')).dy;
      expect(total, greaterThan(s));
    });

    testWidgets('a change diff marks only what moved, with a real minus', (
      WidgetTester tester,
    ) async {
      await pumpFo(
        tester,
        child: const FoChangeDiff(
          layout: FoChangeDiffLayout.list,
          copy: FoChangeDiffCopy(
            beforeLabel: 'Now',
            afterLabel: 'After',
            totalLabel: 'Total',
          ),
          changes: <FoChange>[
            FoChange(key: 'M', before: 30, after: 30),
            FoChange(key: 'L', before: 30, after: 18),
          ],
        ),
      );
      expect(find.text('M'), findsNothing);
      expect(find.text('30 → 18'), findsOneWidget);
      expect(find.text('−12'), findsNWidgets(2));
    });

    testWidgets('a timeline reads each event as one sentence', (
      WidgetTester tester,
    ) async {
      await pumpFo(
        tester,
        child: const SizedBox(
          width: 400,
          child: FoTimeline(
            heading: 'History',
            events: <FoTimelineEvent>[
              FoTimelineEvent(
                event: 'Submitted',
                actor: 'by Imran Sheikh',
                time: '1 Oct, 17:52',
                tone: FoStatusTone.success,
              ),
            ],
          ),
        ),
      );
      expect(find.text('HISTORY'), findsOneWidget);
      expect(
        find.textContaining('Submitted by Imran Sheikh · 1 Oct, 17:52',
            findRichText: true),
        findsOneWidget,
      );
    });
  });

  group('FoDisclosure and FoListRow', () {
    testWidgets('a disclosure opens and reports it', (
      WidgetTester tester,
    ) async {
      final List<bool> seen = <bool>[];
      await pumpFo(
        tester,
        child: SizedBox(
          width: 400,
          child: FoDisclosure(
            title: 'If something goes wrong',
            onExpandedChanged: seen.add,
            child: const Text('Ask an owner.'),
          ),
        ),
      );
      expect(find.text('Ask an owner.'), findsNothing);
      await tester.tap(find.text('If something goes wrong'));
      await tester.pumpAndSettle();
      expect(find.text('Ask an owner.'), findsOneWidget);
      expect(seen, <bool>[true]);
    });

    testWidgets('a list row is one target with a chevron', (
      WidgetTester tester,
    ) async {
      int taps = 0;
      await pumpFo(
        tester,
        child: SizedBox(
          width: 400,
          child: FoListGroup(
            heading: 'Stages',
            rows: <Widget>[
              FoListRow(
                title: 'Pressing',
                subtitle: '616 waiting',
                icon: Icons.iron_outlined,
                onTap: () => taps++,
              ),
            ],
          ),
        ),
      );
      await tester.tap(find.text('616 waiting'));
      expect(taps, 1);
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
      expect(
        tester.getSize(find.byType(FoListRow)).height,
        greaterThanOrEqualTo(56),
      );
    });
  });

  group('reasons', () {
    testWidgets('a quick reason fills the box and lets go when edited', (
      WidgetTester tester,
    ) async {
      final TextEditingController reason = TextEditingController();
      addTearDown(reason.dispose);
      await pumpFo(
        tester,
        child: SizedBox(
          width: 500,
          child: FoReasonField(
            controller: reason,
            label: 'Why are you declining?',
            quickReasons: const <FoQuickReason>[
              FoQuickReason(
                label: 'Counted wrong',
                text: 'The count does not match the floor.',
              ),
            ],
          ),
        ),
      );
      await tester.tap(find.text('Counted wrong'));
      await tester.pump();
      expect(reason.text, 'The count does not match the floor.');
      expect(find.byIcon(Icons.check), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'Something else');
      await tester.pump();
      expect(find.byIcon(Icons.check), findsNothing);
    });

    testWidgets('the dialog keeps its confirm off until there is a reason', (
      WidgetTester tester,
    ) async {
      String? result = 'unset';
      await _app(
        tester,
        child: _opener(
          (BuildContext context) async => result = await FoReasonDialog.show(
            context,
            copy: const FoReasonDialogCopy(
              title: 'Decline the change to PRS-00415?',
              reasonLabel: 'Why?',
              confirmLabel: 'Decline change',
              cancelLabel: 'Keep it waiting',
              requiredMessage: 'Say why, so Imran knows what to fix.',
            ),
            consequences: const <FoConsequence>[
              FoConsequence(text: 'Imran is told.'),
            ],
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      FoButton confirm() => tester.widget<FoButton>(
            find.widgetWithText(FoButton, 'Decline change'),
          );
      expect(confirm().onPressed, isNull);
      expect(find.text('Imran is told.'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'Wrong size.');
      await tester.pump();
      expect(confirm().onPressed, isNotNull);
      await tester.tap(find.text('Decline change'));
      await tester.pumpAndSettle();
      expect(result, 'Wrong size.');
    });
  });

  group('states and cards', () {
    testWidgets('done, page and outbox states carry their tone and actions', (
      WidgetTester tester,
    ) async {
      await _app(
        tester,
        size: _phone,
        child: Column(
          children: <Widget>[
            FoDoneState(
              title: 'Sent for approval',
              icon: Icons.schedule,
              tone: FoStatusTone.warning,
              actions: <Widget>[
                FoButton(
                  label: 'Record more',
                  variant: FoButtonVariant.primary,
                  onPressed: () {},
                ),
              ],
            ),
            const FoOutboxItem(
              state: FoOutboxState.needsYou,
              statusLabel: 'Needs you',
              title: 'Pique Polo',
              figure: '64',
            ),
          ],
        ),
      );
      expect(find.text('Sent for approval'), findsOneWidget);
      expect(find.text('Needs you'), findsOneWidget);
      final Container card = tester.widget<Container>(
        find
            .ancestor(
                of: find.text('Pique Polo'), matching: find.byType(Container))
            .last,
      );
      final Border edge =
          (card.foregroundDecoration! as BoxDecoration).border! as Border;
      expect(edge.top.color, FoColors.light.warning);
    });

    testWidgets('a page state keeps a way on', (WidgetTester tester) async {
      tester.view.physicalSize = _desktop;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          theme: FoTheme.light(),
          home: Scaffold(
            body: FoPageState(
              icon: Icons.lock_outline,
              eyebrow: 'No access',
              title: 'Cartons is for packing and owners',
              tone: FoStatusTone.info,
              actions: <Widget>[
                FoButton(
                  label: 'Go to Today',
                  variant: FoButtonVariant.primary,
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ),
      );
      expect(find.text('NO ACCESS'), findsOneWidget);
      expect(find.text('Go to Today'), findsOneWidget);
    });

    testWidgets('a shortfall is a warning, enough is a quiet success', (
      WidgetTester tester,
    ) async {
      await pumpFo(
        tester,
        child: const SizedBox(
          width: 420,
          child: Column(
            children: <Widget>[
              FoShortfallCard(
                title: '6% short for cutting',
                have: 394.8,
                need: 420,
                semanticValue: '394.8 of 420 kg',
                lines: <FoShortfallLine>[
                  FoShortfallLine(
                    label: 'Short',
                    value: '25.2 kg',
                    emphasis: true,
                  ),
                ],
              ),
              FoShortfallCard(
                title: 'Enough to cut',
                have: 430,
                need: 420,
                semanticValue: '430 of 420 kg',
              ),
            ],
          ),
        ),
      );
      expect(find.byIcon(Icons.warning_amber_outlined), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
      expect(
        tester.widget<Text>(find.text('25.2 kg')).style?.color,
        FoColors.light.warning,
      );
    });

    testWidgets('a checklist opens the current step and counts progress', (
      WidgetTester tester,
    ) async {
      await pumpFo(
        tester,
        surfaceSize: _desktop,
        child: SizedBox(
          width: 700,
          child: FoChecklist(
            copy: FoChecklistCopy(
              title: 'Set up Unit 02',
              progressLabel: (int d, int t) => '$d of $t done',
              doneLabel: 'Done',
            ),
            steps: const <FoChecklistStep>[
              FoChecklistStep(title: 'Add sizes', done: true),
              FoChecklistStep(
                title: 'Add colours',
                done: false,
                body: Text('Colour form'),
              ),
              FoChecklistStep(title: 'Invite people', done: false),
            ],
          ),
        ),
      );
      expect(find.text('1 of 3 done'), findsOneWidget);
      expect(find.text('Colour form'), findsOneWidget);
      expect(find.text('Done'), findsOneWidget);
    });

    testWidgets('a metric card warns on the figure that is the problem', (
      WidgetTester tester,
    ) async {
      await pumpFo(
        tester,
        surfaceSize: _desktop,
        child: const SizedBox(
          width: 360,
          child: FoMetricCard(
            title: 'Line 3',
            subtitle: 'Anjali Rao',
            metrics: <FoMetric>[
              FoMetric(label: 'On the line', value: '420', warning: true),
              FoMetric(label: 'Sewn today', value: '212'),
            ],
            meterLabel: 'Efficiency',
            meterValue: 212,
            meterMax: 329,
            meterCaption: '64%',
            meterTone: FoStatusTone.warning,
          ),
        ),
      );
      expect(
        tester.widget<Text>(find.text('420')).style?.color,
        FoColors.light.warning,
      );
      expect(find.byType(FoProgressBar), findsOneWidget);
    });

    testWidgets('a capacity grid tells full from part', (
      WidgetTester tester,
    ) async {
      await pumpFo(
        tester,
        child: const SizedBox(
          width: 500,
          child: FoCapacityGrid(
            tiles: <FoCapacityTile>[
              FoCapacityTile(
                label: 'M',
                amount: 20,
                capacity: 20,
                amountLabel: '20 of 20',
                statusLabel: 'Full',
                repeat: 2,
              ),
              FoCapacityTile(
                label: 'L',
                amount: 12,
                capacity: 20,
                amountLabel: '12 of 20',
                statusLabel: 'Filling',
              ),
            ],
          ),
        ),
      );
      expect(find.text('2 × M'), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('an attachment grid names every tile and offers add', (
      WidgetTester tester,
    ) async {
      int adds = 0;
      await pumpFo(
        tester,
        child: SizedBox(
          width: 400,
          child: FoAttachmentGrid(
            items: const <FoAttachment>[
              FoAttachment(
                caption: 'Invoice',
                semanticLabel: 'Open the supplier invoice',
              ),
            ],
            addLabel: 'Take photo',
            onAdd: () => adds++,
          ),
        ),
      );
      expect(
          find.bySemanticsLabel('Open the supplier invoice'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('Take photo'));
      expect(adds, 1);
    });

    testWidgets('a print preview is one named image', (
      WidgetTester tester,
    ) async {
      await pumpFo(
        tester,
        child: const SizedBox(
          width: 400,
          child: FoPrintPreview(
            title: 'Label preview',
            spec: '100 × 150 mm',
            semanticLabel: 'Label for carton CTN-121',
            child: SizedBox(height: 120, child: Text('CTN-121')),
          ),
        ),
      );
      expect(find.bySemanticsLabel('Label for carton CTN-121'), findsOneWidget);
    });
  });

  group('FoQuantityMatrix', () {
    test('a split by ratio always adds up to the total', () {
      expect(
        FoQuantityMatrix.splitByRatio(720, <int>[2, 4, 4, 3, 2]),
        <int>[96, 192, 192, 144, 96],
      );
      for (final int total in <int>[1, 7, 100, 999, 1201]) {
        final List<int> parts =
            FoQuantityMatrix.splitByRatio(total, <int>[2, 4, 4, 3, 2]);
        expect(parts.fold<int>(0, (int a, int b) => a + b), total);
      }
      expect(FoQuantityMatrix.splitByRatio(5, <int>[0, 0]), <int>[3, 2]);
    });

    test('a paste matches rows by name and keeps 1,200 whole', () {
      final FoQuantityPaste paste = FoQuantityMatrix.parsePaste(
        'deep navy\t120\t1,200\t240\nTeal\t1\t2\nEcru, 96, 192',
        rowLabels: <String>['Deep Navy', 'Ecru'],
        columnCount: 3,
      );
      expect(paste.rows[0], <int>[120, 1200, 240]);
      expect(paste.rows[1], <int>[96, 192, 0]);
      expect(paste.unknown, <String>['Teal']);
    });

    testWidgets('typing a total splits it; totals and floors show live', (
      WidgetTester tester,
    ) async {
      List<int> navy = <int>[0, 0, 0];
      await _app(
        tester,
        child: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) =>
              FoQuantityMatrix(
            columns: const <String>['S', 'M', 'L'],
            ratio: const <int>[1, 2, 1],
            rows: <FoQuantityRow>[
              FoQuantityRow(label: 'Deep Navy', values: navy),
              const FoQuantityRow(
                label: 'Sage',
                values: <int>[10, 10, 10],
                floors: <int>[0, 0, 20],
              ),
            ],
            onRowChanged: (int r, List<int> v) {
              if (r == 0) setState(() => navy = v);
            },
            copy: FoQuantityMatrixCopy(
              rowHeader: 'Colour',
              totalLabel: 'Colour total',
              allRowsLabel: 'All colours',
              ratioLabel: 'Size ratio',
              cellLabel: (String r, String c) => '$r, size $c',
              rowTotalLabel: (String r) => '$r total',
              floorCaption: (int f) => 'cut $f',
              belowFloorMessage: (String r, String c, int f) =>
                  '$r $c can\'t go below $f.',
            ),
          ),
        ),
      );
      final Finder navyTotal = find.descendant(
        of: find.bySemanticsLabel('Deep Navy total'),
        matching: find.byType(TextField),
      );
      await tester.enterText(navyTotal, '40');
      await tester.pump();
      expect(navy, <int>[10, 20, 10]);
      expect(find.text('Sage L can\'t go below 20.'), findsOneWidget);
      expect(find.text('70'), findsOneWidget, reason: 'the grand total');
    });
  });

  group('FoEntryListEditor', () {
    testWidgets('adds, repeats and removes lines', (WidgetTester tester) async {
      final List<double> rolls = <double>[28.4];
      int repeats = 0;
      await _app(
        tester,
        child: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) =>
              FoEntryListEditor(
            columns: const <FoEntryColumn>[
              FoEntryColumn(label: 'Weight', numeric: true),
            ],
            lineCount: rolls.length,
            lineCells: (int i) => <Widget>[Text('${rolls[i]} kg')],
            entryCells: const <Widget>[Text('entry')],
            onAdd: () => setState(() => rolls.add(30)),
            addLabel: 'Add roll',
            onRepeatLast: () => repeats++,
            repeatLastLabel: 'Repeat last, 28.4 kg',
            removeLabel: (int i) => 'Remove roll ${i + 1}',
            onRemove: (int i) => setState(() => rolls.removeAt(i)),
          ),
        ),
      );
      await tester.tap(find.text('Add roll'));
      await tester.pump();
      expect(find.text('30.0 kg'), findsOneWidget);
      await tester.tap(find.text('Repeat last, 28.4 kg'));
      expect(repeats, 1);
      await tester.tap(find.bySemanticsLabel('Remove roll 1'));
      await tester.pump();
      expect(find.text('28.4 kg'), findsNothing);
    });
  });

  group('scanning', () {
    testWidgets('Enter submits, upper-cases, clears and keeps focus', (
      WidgetTester tester,
    ) async {
      final List<String> codes = <String>[];
      await pumpFo(
        tester,
        child: SizedBox(
          width: 500,
          child: FoScanField(
            label: 'Scan or type a bundle number',
            submitLabel: 'Add bundle',
            onSubmitted: codes.add,
          ),
        ),
      );
      await tester.enterText(find.byType(TextField), ' bndl-1005-m-001 ');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      expect(codes, <String>['BNDL-1005-M-001']);
      final TextField field = tester.widget<TextField>(find.byType(TextField));
      expect(field.controller!.text, isEmpty);
      expect(field.focusNode!.hasFocus, isTrue);
    });

    testWidgets('a viewfinder with a tap is a named button', (
      WidgetTester tester,
    ) async {
      int taps = 0;
      await pumpFo(
        tester,
        child: SizedBox(
          width: 360,
          child: FoScanViewfinder(
            title: 'Tap to scan the next bundle',
            semanticLabel: 'Camera. Scan a bundle ticket.',
            onTap: () => taps++,
          ),
        ),
      );
      await tester.tap(find.bySemanticsLabel('Camera. Scan a bundle ticket.'));
      expect(taps, 1);
    });
  });

  group('FoDateRangePicker', () {
    testWidgets('a preset or two taps make a range; the future is shut', (
      WidgetTester tester,
    ) async {
      DateTimeRange? result;
      final DateTime today = DateTime(2026, 10, 2);
      await _app(
        tester,
        child: _opener(
          (BuildContext context) async => result = await FoDateRangePicker.show(
            context,
            firstDate: DateTime(2026),
            lastDate: today,
            presets: <FoDateRangePreset>[
              FoDateRangePreset(
                label: 'Last 7 days',
                range: DateTimeRange(start: DateTime(2026, 9, 26), end: today),
              ),
            ],
            copy: FoDateRangeCopy(
              confirmLabel: 'Use these dates',
              cancelLabel: 'Cancel',
              previousMonthLabel: 'Previous month',
              nextMonthLabel: 'Next month',
              rangeLabel: (DateTimeRange r) => '${r.duration.inDays + 1} days',
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Last 7 days'));
      await tester.pump();
      expect(find.text('7 days'), findsOneWidget);

      await tester.tap(find.text('1').first);
      await tester.tap(find.text('2').first);
      await tester.pump();
      expect(find.text('2 days'), findsOneWidget);
      // 3 October is after "today": tapping it changes nothing.
      await tester.tap(find.text('3').first);
      await tester.pump();
      expect(find.text('2 days'), findsOneWidget);
      await tester.tap(find.text('Use these dates'));
      await tester.pumpAndSettle();
      expect(result, isNotNull);
      expect(result!.end.isAfter(today), isFalse);
    });
  });

  group('FoSearchPalette', () {
    testWidgets('groups results; arrows and Enter open the highlighted one', (
      WidgetTester tester,
    ) async {
      final List<String> opened = <String>[];
      await _app(
        tester,
        child: _opener(
          (BuildContext context) => FoSearchPalette.show(
            context,
            search: (String q) async => <FoSearchGroup>[
              FoSearchGroup(
                title: 'Orders',
                results: <FoSearchResult>[
                  FoSearchResult(
                    title: 'Heavyweight Crew Tee',
                    onSelected: () => opened.add('order'),
                  ),
                ],
              ),
              FoSearchGroup(
                title: 'Entries',
                results: <FoSearchResult>[
                  FoSearchResult(
                    title: 'PRS-00415',
                    onSelected: () => opened.add('entry'),
                  ),
                ],
              ),
              const FoSearchGroup(
                title: 'People',
                results: <FoSearchResult>[],
                emptyText: 'No people match.',
              ),
            ],
            copy: FoSearchPaletteCopy(
              fieldLabel: 'Search',
              closeLabel: 'Close search',
              noResultsText: (String q) => 'Nothing matches "$q".',
              errorText: "Couldn't search.",
              retryLabel: 'Try again',
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'crew');
      await tester.pump(FoMotion.searchDebounce);
      await tester.pumpAndSettle();

      expect(find.text('ORDERS'), findsOneWidget);
      expect(find.text('No people match.'), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(opened, <String>['entry']);
    });

    testWidgets('a failed search says so and never "nothing found"', (
      WidgetTester tester,
    ) async {
      final Completer<List<FoSearchGroup>> never =
          Completer<List<FoSearchGroup>>();
      await _app(
        tester,
        size: _phone,
        child: _opener(
          (BuildContext context) => FoSearchPalette.show(
            context,
            search: (String q) => q == 'slow'
                ? never.future
                : Future<List<FoSearchGroup>>.error(StateError('offline')),
            copy: FoSearchPaletteCopy(
              fieldLabel: 'Search',
              closeLabel: 'Close search',
              noResultsText: (String q) => 'Nothing matches "$q".',
              errorText: "Couldn't search.",
              retryLabel: 'Try again',
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'crew');
      await tester.pump(FoMotion.searchDebounce);
      await tester.pumpAndSettle();
      expect(find.text("Couldn't search."), findsOneWidget);
      expect(find.textContaining('Nothing matches'), findsNothing);
    });
  });

  group('help', () {
    testWidgets('the vote thanks a yes, and asks after a no', (
      WidgetTester tester,
    ) async {
      final List<bool> votes = <bool>[];
      final List<String> notes = <String>[];
      Widget vote() => SizedBox(
            width: 500,
            child: FoHelpfulVote(
              onVote: votes.add,
              onSendNote: (String n) async => notes.add(n),
              copy: const FoHelpfulVoteCopy(
                question: 'Was this helpful?',
                yesLabel: 'Yes',
                noLabel: 'No',
                thanksYes: 'Thanks. Glad it helped.',
                noPrompt: 'What were you trying to do?',
                sendLabel: 'Send',
                sentMessage: 'Sent.',
              ),
            ),
          );
      await pumpFo(tester, child: vote());
      await tester.tap(find.text('No'));
      await tester.pump();
      await tester.enterText(find.byType(TextField), 'Find the lock');
      await tester.tap(find.text('Send'));
      await tester.pumpAndSettle();
      expect(votes, <bool>[false]);
      expect(notes, <String>['Find the lock']);
      expect(find.text('Sent.'), findsOneWidget);
    });

    testWidgets('a marked screenshot scales the marker with the picture', (
      WidgetTester tester,
    ) async {
      await pumpFo(
        tester,
        child: const SizedBox(
          width: 720,
          child: FoMarkedScreenshot(
            image: ColoredBox(color: Color(0x00000000)),
            sourceSize: Size(1440, 1000),
            semanticLabel: 'The Pressing page. Record pressing is marked 1.',
            markers: <FoScreenMarker>[
              FoScreenMarker(
                number: 1,
                rect: Rect.fromLTWH(1237, 161, 171, 44),
              ),
            ],
          ),
        ),
      );
      expect(
        find.bySemanticsLabel(
            'The Pressing page. Record pressing is marked 1.'),
        findsOneWidget,
      );
      // 1237 × 0.5 − 4 = 614.5 from the frame's left.
      final Rect ring = tester.getRect(
        find
            .descendant(
              of: find.byType(FoMarkedScreenshot),
              matching: find.byType(Positioned),
            )
            .at(1),
      );
      final Rect frame = tester.getRect(find.byType(FoMarkedScreenshot));
      expect(ring.left - frame.left, closeTo(614.5, 0.5));
      expect(ring.width, closeTo(93.5, 0.5));
    });

    testWidgets('the guide has an eyebrow and a footer that stays', (
      WidgetTester tester,
    ) async {
      final GlobalKey section = GlobalKey();
      await _app(
        tester,
        child: _opener(
          (BuildContext context) => FoHelpGuide.show(
            context,
            eyebrow: 'Help · Stage 8 of 9',
            title: 'Pressing',
            closeLabel: 'Close help',
            scrollTo: section,
            body: Column(
              children: <Widget>[
                const SizedBox(height: 2000),
                FoGuideStep(
                  key: section,
                  number: 2,
                  title: 'Count by size',
                  body: const Text('Use Fill all ready.'),
                ),
              ],
            ),
            actions: <Widget>[
              FoButton(
                label: 'Open full guide',
                variant: FoButtonVariant.secondary,
                onPressed: () {},
              ),
            ],
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.text('HELP · STAGE 8 OF 9'), findsOneWidget);
      expect(find.text('Open full guide'), findsOneWidget);
      // Opened at the section, which is far below the fold.
      expect(tester.getTopLeft(find.text('Count by size')).dy, lessThan(900));
    });
  });

  group('extensions', () {
    testWidgets('a password field shows and hides with a named toggle', (
      WidgetTester tester,
    ) async {
      await pumpFo(
        tester,
        child: const SizedBox(
          width: 400,
          child: FoTextField(
            label: 'Password',
            obscureText: true,
            revealLabel: 'Show password',
            concealLabel: 'Hide password',
          ),
        ),
      );
      bool obscured() =>
          tester.widget<EditableText>(find.byType(EditableText)).obscureText;
      expect(obscured(), isTrue);
      await tester.tap(find.bySemanticsLabel('Show password'));
      await tester.pump();
      expect(obscured(), isFalse);
      expect(find.bySemanticsLabel('Hide password'), findsOneWidget);
    });

    testWidgets('the filter bar in apply mode says the figures are stale', (
      WidgetTester tester,
    ) async {
      int applied = 0;
      await pumpFo(
        tester,
        surfaceSize: _desktop,
        child: SizedBox(
          width: 900,
          child: FoFilterBar(
            hasActiveFilters: true,
            clearLabel: 'Clear',
            onClear: () {},
            onApply: () => applied++,
            applyLabel: 'Apply',
            pendingMessage: 'You changed the dates. Press Apply.',
            children: <Widget>[
              FoFilterButton(value: 'Last 7 days', onPressed: () {}),
            ],
          ),
        ),
      );
      expect(find.text('You changed the dates. Press Apply.'), findsOneWidget);
      await tester.tap(find.text('Apply'));
      expect(applied, 1);
    });

    testWidgets('a compact bar chart is one named image', (
      WidgetTester tester,
    ) async {
      await pumpFo(
        tester,
        child: const SizedBox(
          width: 400,
          height: 140,
          child: FoBarChart(
            compact: true,
            showValues: true,
            targetValue: 47,
            semanticLabel: 'Sewn each hour on Line 3: 24, 30, 34.',
            seriesLabels: <String>['Sewn'],
            groups: <FoBarGroup>[
              FoBarGroup(label: '8', values: <num>[24]),
              FoBarGroup(label: '9', values: <num>[30]),
              FoBarGroup(label: '10', values: <num>[34]),
            ],
          ),
        ),
      );
      expect(
        find.bySemanticsLabel('Sewn each hour on Line 3: 24, 30, 34.'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('the labelled rail prints names on a tablet', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(820, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          theme: FoTheme.light(),
          home: FoShellScaffold(
            railLabels: true,
            selectedItemId: 'today',
            groups: <FoNavGroup>[
              FoNavGroup(
                items: <FoNavItem>[
                  FoNavItem(
                    id: 'today',
                    label: 'Today',
                    icon: Icons.home_outlined,
                    selectedIcon: Icons.home,
                    onSelected: () {},
                  ),
                ],
              ),
            ],
            body: const SizedBox.shrink(),
          ),
        ),
      );
      expect(find.text('Today'), findsOneWidget);
      expect(find.byType(Tooltip), findsNothing);
    });

    testWidgets('an unseen alert says so in words', (
      WidgetTester tester,
    ) async {
      await pumpFo(
        tester,
        child: const SizedBox(
          width: 400,
          child: FoAttentionItem(
            icon: Icons.warning_amber_outlined,
            title: 'Line 3 has 420 pieces on the line',
            unseen: true,
            unseenLabel: 'New',
          ),
        ),
      );
      // Read as part of the item, never as a bare dot.
      expect(find.bySemanticsLabel(RegExp('New')), findsOneWidget);
    });

    testWidgets('a key hint hides on a phone', (WidgetTester tester) async {
      await pumpFo(tester, surfaceSize: _phone, child: const FoKeyHint('Esc'));
      expect(find.text('Esc'), findsNothing);
      await pumpFo(tester,
          surfaceSize: _desktop, child: const FoKeyHint('Esc'));
      expect(find.text('Esc'), findsOneWidget);
    });

    testWidgets('an avatar reads as the person', (WidgetTester tester) async {
      await pumpFo(
        tester,
        child: const FoAvatar(initials: 'IS', name: 'Imran Sheikh'),
      );
      expect(find.bySemanticsLabel('Imran Sheikh'), findsOneWidget);
    });
  });

  group('layout rules from the owner review', () {
    testWidgets('1. a stepper value is typed between − and +', (
      WidgetTester tester,
    ) async {
      await pumpFo(
        tester,
        child: FoNumberField(
          value: 30,
          onChanged: (_) {},
          semanticLabel: 'Pressed, size M',
          decreaseSemanticLabel: 'One fewer, size M',
          increaseSemanticLabel: 'One more, size M',
        ),
      );
      final double minus =
          tester.getCenter(find.bySemanticsLabel('One fewer, size M')).dx;
      final double plus =
          tester.getCenter(find.bySemanticsLabel('One more, size M')).dx;
      final double box = tester.getCenter(find.byType(TextField)).dx;
      expect(box, inExclusiveRange(minus, plus));
      expect(
        tester.widget<TextField>(find.byType(TextField)).keyboardType,
        TextInputType.number,
      );
    });

    testWidgets('2. tabs stay in one row on a wide window', (
      WidgetTester tester,
    ) async {
      await pumpFo(
        tester,
        surfaceSize: _desktop,
        child: SizedBox(
          width: 300,
          child: FoStatusTabs(
            semanticLabel: 'Status',
            selectedIndex: 0,
            onSelected: (_) {},
            tabs: const <FoStatusTab>[
              FoStatusTab(label: 'All', count: 418),
              FoStatusTab(label: 'Drafts', count: 3),
              FoStatusTab(label: 'Change requested', count: 3),
              FoStatusTab(label: 'Submitted', count: 412),
            ],
          ),
        ),
      );
      expect(
        tester.getTopLeft(find.text('All')).dy,
        tester.getTopLeft(find.text('Submitted')).dy,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('3. search and filters share one row; search flexes', (
      WidgetTester tester,
    ) async {
      Future<void> at(double width) => pumpFo(
            tester,
            surfaceSize: _desktop,
            child: SizedBox(
              width: width,
              child: FoToolbar(
                search: const SizedBox(height: 48, child: Placeholder()),
                filters: <Widget>[
                  for (final String f in <String>['Order: All', 'Line: All'])
                    FoFilterButton(value: f, onPressed: () {}),
                ],
              ),
            ),
          );
      await at(900);
      final double wideSearch = tester.getSize(find.byType(Placeholder)).width;
      expect(
        tester.getTopLeft(find.text('Line: All')).dy,
        tester.getTopLeft(find.text('Order: All')).dy,
      );
      await at(600);
      expect(
        tester.getSize(find.byType(Placeholder)).width,
        lessThan(wideSearch),
      );
      await at(320);
      // Too narrow: the search holds its minimum and the row scrolls.
      expect(tester.getSize(find.byType(Placeholder)).width, 220);
      expect(
        tester.getTopLeft(find.text('Line: All')).dy,
        tester.getTopLeft(find.text('Order: All')).dy,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('4. the list fills the height beside the panel', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = _desktop;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          theme: FoTheme.light(),
          home: Scaffold(
            body: SizedBox(
              height: 700,
              child: FoListDetailLayout(
                list: const FoListCard(
                  header: Text('Tabs'),
                  body: Text('Rows'),
                  footer: Text('Pages'),
                ),
                detail: FoSidePanel(
                  title: 'PRS-00416',
                  child: Column(
                    children: List<Widget>.generate(
                      30,
                      (int i) => Text('Line $i'),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      final Rect list = tester.getRect(find.byType(FoListCard));
      final Rect panel = tester.getRect(find.byType(FoSidePanel));
      expect(list.height, panel.height);
      expect(
        tester.getBottomLeft(find.text('Pages')).dy,
        closeTo(list.bottom, 1),
      );
    });

    testWidgets('5. cards in a row are equal height', (
      WidgetTester tester,
    ) async {
      await pumpFo(
        tester,
        surfaceSize: _desktop,
        child: const SizedBox(
          width: 1000,
          child: FoEqualHeightRow(
            children: <Widget>[
              FoCard(child: Text('Short')),
              FoCard(child: Text('Tall\nTall\nTall\nTall')),
            ],
          ),
        ),
      );
      final List<double> heights = tester
          .widgetList(find.byType(FoCard))
          .map((Widget w) => tester.getSize(find.byWidget(w)).height)
          .toList();
      expect(heights[0], heights[1]);
    });

    testWidgets('6. a circle stays a circle when squeezed', (
      WidgetTester tester,
    ) async {
      await pumpFo(
        tester,
        child: const SizedBox(
          width: 300,
          height: 40,
          child: FoAvatar(initials: 'IS', name: 'Imran Sheikh'),
        ),
      );
      final Size avatar = tester.getSize(
        find.descendant(
          of: find.byType(FoAvatar),
          matching: find.byType(Container),
        ),
      );
      expect(avatar.width, avatar.height);

      await pumpFo(
        tester,
        child: const SizedBox(width: 300, height: 30, child: FoDisc(size: 20)),
      );
      expect(
        tester.getSize(find.byType(DecoratedBox).last),
        const Size(20, 20),
      );
    });
  });
}

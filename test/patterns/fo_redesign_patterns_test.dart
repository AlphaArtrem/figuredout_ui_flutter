import 'dart:async';

import 'package:figuredout_ui/figuredout_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/pump.dart';

const Size _phone = Size(400, 860);
const Size _desktop = Size(1280, 900);

/// Mounts [child] at [size] with a navigator it can push onto.
Future<void> _pumpApp(
  WidgetTester tester, {
  required Widget child,
  Size size = _desktop,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  // A fresh tree each time, so a route left open by a previous pump in the
  // same test cannot survive into this one.
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pumpWidget(
    MaterialApp(
      theme: FoTheme.light(),
      home: Scaffold(body: child),
    ),
  );
}

FoSizeCountCopy _copy() => FoSizeCountCopy(
      sizeLabel: 'Size',
      readyLabel: 'Ready',
      countLabel: 'Pressed now',
      remainingLabel: 'Still to press',
      totalLabel: 'Total',
      fillAllLabel: 'Fill all ready',
      inputSemanticLabel: (String size) => 'Pressed, size $size',
      decreaseSemanticLabel: (String size) => 'One fewer, size $size',
      increaseSemanticLabel: (String size) => 'One more, size $size',
      overLimitMessage: (String size, int over) =>
          'Size $size is $over more than ready.',
    );

/// A grid with its own state, so a fill or a step is visible on screen.
class _Grid extends StatefulWidget {
  const _Grid();

  @override
  State<_Grid> createState() => _GridState();
}

class _GridState extends State<_Grid> {
  List<FoSizeCount> sizes = const <FoSizeCount>[
    FoSizeCount(size: 'S', ready: 16, value: 0),
    FoSizeCount(size: 'M', ready: 36, value: 30),
    FoSizeCount(size: 'L', ready: 42, value: 44),
  ];

  void _set(int i, int v) => setState(() {
        sizes = <FoSizeCount>[
          for (int j = 0; j < sizes.length; j++)
            j == i
                ? FoSizeCount(
                    size: sizes[j].size, ready: sizes[j].ready, value: v)
                : sizes[j],
        ];
      });

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        child: FoSizeCountGrid(
          sizes: sizes,
          copy: _copy(),
          onChanged: _set,
          onFillAll: () => setState(() {
            sizes = <FoSizeCount>[
              for (final FoSizeCount s in sizes)
                FoSizeCount(size: s.size, ready: s.ready, value: s.ready!),
            ];
          }),
        ),
      );
}

void main() {
  group('FoSizeCountGrid', () {
    test('totals add up', () {
      const List<FoSizeCount> sizes = <FoSizeCount>[
        FoSizeCount(size: 'S', ready: 16, value: 16),
        FoSizeCount(size: 'M', ready: 36, value: 30),
        FoSizeCount(size: 'L', ready: 42, value: 44),
      ];
      expect(FoSizeCountGrid.totalOf(sizes), 90);
      expect(FoSizeCountGrid.readyTotalOf(sizes), 94);
      expect(sizes[2].over, 2);
      expect(sizes[1].over, 0);
      expect(const FoSizeCount(size: 'S', value: 9).over, 0);
    });

    testWidgets('over ready is a warning that says why, not an error', (
      WidgetTester tester,
    ) async {
      await _pumpApp(tester, size: _phone, child: const _Grid());

      expect(find.text('Size L is 2 more than ready.'), findsOneWidget);
      expect(find.text('Size M is 0 more than ready.'), findsNothing);
      // Nothing blocks: the count is still editable and nothing is red.
      expect(find.byIcon(Icons.error_outline), findsNothing);
    });

    testWidgets('Fill all ready fills every box, and the warning clears', (
      WidgetTester tester,
    ) async {
      await _pumpApp(tester, size: _phone, child: const _Grid());

      await tester.tap(find.text('Fill all ready'));
      await tester.pump();

      expect(find.text('16'), findsWidgets);
      expect(find.text('36'), findsWidgets);
      expect(find.text('42'), findsWidgets);
      expect(find.text('Size L is 2 more than ready.'), findsNothing);
    });

    testWidgets('a phone gets steppers named by size', (
      WidgetTester tester,
    ) async {
      await _pumpApp(tester, size: _phone, child: const _Grid());

      expect(find.bySemanticsLabel('One more, size S'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('One more, size S'));
      await tester.pump();
      expect(find.text('1'), findsOneWidget);
    });

    testWidgets('a wide window gets a table with a total row', (
      WidgetTester tester,
    ) async {
      await _pumpApp(tester, child: const _Grid());

      expect(find.bySemanticsLabel('One more, size S'), findsNothing);
      expect(find.text('TOTAL'), findsNothing, reason: 'labels keep case');
      expect(find.text('Total'), findsOneWidget);
      // 16 + 36 + 42 ready, 0 + 30 + 44 counted, 94 − 74 still to do.
      expect(find.text('94'), findsOneWidget);
      expect(find.text('74'), findsOneWidget);
      expect(find.text('20'), findsOneWidget);
      // The over-count reads as a deficit with a real minus sign.
      expect(find.text('−2'), findsOneWidget);
    });
  });

  group('FoStepFlow', () {
    List<FoStep> steps(VoidCallback onEdit) => <FoStep>[
          FoStep(
            label: 'Order and colour',
            summary: 'JOB-2026-10024 · Deep Navy',
            onEdit: onEdit,
            editLabel: 'Change',
          ),
          const FoStep(label: 'Count by size'),
          const FoStep(label: 'Check and submit'),
        ];

    Widget flow({
      required VoidCallback onClose,
      VoidCallback? onBack,
      VoidCallback? onEdit,
    }) =>
        FoStepFlowScaffold(
          title: 'Record pressing',
          eyebrow: 'Pressing · Stage 8 of 9',
          stepLabel: 'Step 2 of 3 · Count by size',
          steps: steps(onEdit ?? () {}),
          currentStep: 1,
          body: const Text('Body'),
          footer: FoButton(
            label: 'Next: check',
            variant: FoButtonVariant.primary,
            onPressed: () {},
          ),
          onClose: onClose,
          closeSemanticLabel: 'Close',
          onBack: onBack,
          backSemanticLabel: 'Back to the previous step',
        );

    testWidgets('wide: the full stepper, with the done step editable', (
      WidgetTester tester,
    ) async {
      int edits = 0;
      await _pumpApp(
        tester,
        child: flow(onClose: () {}, onEdit: () => edits++),
      );

      expect(find.text('Order and colour'), findsOneWidget);
      expect(find.text('JOB-2026-10024 · Deep Navy'), findsOneWidget);
      expect(find.byIcon(Icons.check), findsOneWidget);
      await tester.tap(find.text('Change'));
      expect(edits, 1);
      // The phone's step line is not shown on a wide window.
      expect(find.text('Step 2 of 3 · Count by size'), findsNothing);
    });

    testWidgets('phone: a progress bar, the step in words, and Back', (
      WidgetTester tester,
    ) async {
      int backs = 0;
      await _pumpApp(
        tester,
        size: _phone,
        child: flow(onClose: () {}, onBack: () => backs++),
      );

      expect(find.text('Step 2 of 3 · Count by size'), findsOneWidget);
      expect(find.text('Order and colour'), findsNothing);
      // After step one, back replaces close.
      expect(find.bySemanticsLabel('Close'), findsNothing);
      await tester.tap(find.bySemanticsLabel('Back to the previous step'));
      expect(backs, 1);
      // The footer sits below the body, never over it.
      expect(
        tester.getTopLeft(find.text('Next: check')).dy,
        greaterThan(tester.getBottomLeft(find.text('Body')).dy),
      );
    });

    testWidgets('show: a dialog on a wide window, a page on a phone', (
      WidgetTester tester,
    ) async {
      for (final (Size size, bool dialog) in <(Size, bool)>[
        (_desktop, true),
        (_phone, false),
      ]) {
        await _pumpApp(
          tester,
          size: size,
          child: Builder(
            builder: (BuildContext context) => TextButton(
              onPressed: () => FoStepFlow.show<void>(
                context,
                builder: (_) => flow(onClose: () {}),
              ),
              child: const Text('Open'),
            ),
          ),
        );
        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();
        expect(find.byType(Dialog), dialog ? findsOneWidget : findsNothing);
        expect(find.text('Record pressing'), findsOneWidget);
      }
    });
  });

  group('FoStatusTabs', () {
    testWidgets('names each tab with its count and reports a new pick', (
      WidgetTester tester,
    ) async {
      final List<int> picked = <int>[];
      await pumpFo(
        tester,
        surfaceSize: _desktop,
        child: FoStatusTabs(
          semanticLabel: 'Status',
          selectedIndex: 0,
          onSelected: picked.add,
          countFormatter: (int n) => n == 1401 ? '1,401' : '$n',
          tabs: const <FoStatusTab>[
            FoStatusTab(label: 'All', count: 1401),
            FoStatusTab(label: 'Drafts', count: 3),
            FoStatusTab(label: 'Submitted'),
          ],
        ),
      );

      expect(find.bySemanticsLabel('All, 1,401'), findsOneWidget);
      expect(find.bySemanticsLabel('Drafts, 3'), findsOneWidget);
      expect(find.bySemanticsLabel('Submitted'), findsOneWidget);

      await tester.tap(find.text('All'));
      expect(picked, isEmpty, reason: 'the current tab is where you are');
      await tester.tap(find.text('Drafts'));
      expect(picked, <int>[1]);
    });

    testWidgets('on a phone they scroll sideways rather than wrap', (
      WidgetTester tester,
    ) async {
      await pumpFo(
        tester,
        surfaceSize: _phone,
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
      );
      expect(
        find.ancestor(
          of: find.text('Submitted'),
          matching: find.byType(SingleChildScrollView),
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('FoActionBar', () {
    testWidgets('sits below the content instead of covering it', (
      WidgetTester tester,
    ) async {
      await _pumpApp(
        tester,
        size: _phone,
        child: Column(
          children: <Widget>[
            Expanded(
              child: ListView(
                children: const <Widget>[
                  SizedBox(height: 2000, child: Text('List')),
                ],
              ),
            ),
            FoActionBar(
              actions: <Widget>[
                FoButton(
                  label: 'Record pressing',
                  variant: FoButtonVariant.primary,
                  size: FoButtonSize.large,
                  onPressed: () {},
                ),
              ],
            ),
          ],
        ),
      );

      final Rect bar = tester.getRect(find.byType(FoActionBar));
      final Rect list = tester.getRect(find.byType(ListView));
      expect(bar.top, greaterThanOrEqualTo(list.bottom));
      // One action and no context: it takes the full width for a thumb.
      expect(
        tester.getSize(find.byType(FilledButton)).width,
        greaterThan(_phone.width - 64),
      );
    });
  });

  group('FoListDetailLayout', () {
    testWidgets('shows the panel beside the list only on a wide window', (
      WidgetTester tester,
    ) async {
      Widget layout() => FoListDetailLayout(
            list: const Text('List'),
            detail: FoSidePanel(
              eyebrow: 'Pressing entry',
              title: 'PRS-00416',
              titleIsCode: true,
              onClose: () {},
              closeSemanticLabel: 'Close the panel',
              child: const Text('Detail'),
            ),
          );

      await _pumpApp(tester, child: layout());
      expect(find.text('Detail'), findsOneWidget);
      expect(find.text('PRESSING ENTRY'), findsOneWidget);
      expect(find.bySemanticsLabel('Close the panel'), findsOneWidget);

      await _pumpApp(tester, size: _phone, child: layout());
      expect(find.text('Detail'), findsNothing);
      expect(find.text('List'), findsOneWidget);
    });

    testWidgets(
        'open() pushes a page on a phone and uses the panel on a wide '
        'window', (WidgetTester tester) async {
      for (final (Size size, bool panel) in <(Size, bool)>[
        (_desktop, true),
        (_phone, false),
      ]) {
        int shownInPanel = 0;
        await _pumpApp(
          tester,
          size: size,
          child: Builder(
            builder: (BuildContext context) => TextButton(
              onPressed: () => FoListDetailLayout.open(
                context,
                showInPanel: () => shownInPanel++,
                pageBuilder: (_) => const Scaffold(body: Text('Record page')),
              ),
              child: const Text('Open'),
            ),
          ),
        );
        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();
        expect(shownInPanel, panel ? 1 : 0);
        expect(find.text('Record page'), panel ? findsNothing : findsOneWidget);
      }
    });
  });

  group('FoInfoBanner', () {
    testWidgets('offline says what happens to the work, and what is waiting', (
      WidgetTester tester,
    ) async {
      await pumpFo(
        tester,
        child: FoInfoBanner.offline(
          title: "You're offline.",
          message: 'New entries are kept on this phone.',
          pending: '2 waiting to send',
        ),
      );
      expect(find.byIcon(Icons.wifi_off), findsOneWidget);
      expect(find.text('2 waiting to send'), findsOneWidget);
      expect(
        find.textContaining("You're offline.", findRichText: true),
        findsOneWidget,
      );
    });

    testWidgets('locked offers Request a change as a needs-approval action', (
      WidgetTester tester,
    ) async {
      int requests = 0;
      await pumpFo(
        tester,
        child: FoInfoBanner.locked(
          title: 'Locked after submitting',
          message: 'Submitted entries are locked so totals stay right.',
          requestChangeLabel: 'Request a change',
          onRequestChange: () => requests++,
        ),
      );
      expect(find.byIcon(Icons.lock_outline), findsOneWidget);
      final FoButton button = tester.widget<FoButton>(find.byType(FoButton));
      expect(button.variant, FoButtonVariant.warning);
      await tester.tap(find.text('Request a change'));
      expect(requests, 1);
    });
  });

  group('FoEmptyState', () {
    testWidgets('couldn\'t-load and no-matches never look like first use', (
      WidgetTester tester,
    ) async {
      Future<FoButtonVariant> variantOf(Widget state) async {
        await pumpFo(tester, child: SizedBox(height: 500, child: state));
        return tester.widget<FoButton>(find.byType(FoButton)).variant;
      }

      expect(
        await variantOf(
          FoEmptyState(
            icon: Icons.inbox_outlined,
            title: 'No pressing entries yet',
            actionLabel: 'Record pressing',
            onAction: () {},
          ),
        ),
        FoButtonVariant.primary,
      );
      expect(
        await variantOf(
          FoEmptyState.noResults(
            title: 'Nothing matches these filters',
            actionLabel: 'Clear filters',
            onAction: () {},
          ),
        ),
        FoButtonVariant.secondary,
      );
      expect(
        await variantOf(
          FoEmptyState.error(
            title: "Couldn't load pressing entries",
            actionLabel: 'Try again',
            onAction: () {},
          ),
        ),
        FoButtonVariant.secondary,
      );
      expect(find.byIcon(Icons.refresh), findsOneWidget);
    });
  });

  group('FoDialog', () {
    testWidgets('is a bottom sheet on a phone and resolves the choice', (
      WidgetTester tester,
    ) async {
      bool? answer;
      await _pumpApp(
        tester,
        size: _phone,
        child: Builder(
          builder: (BuildContext context) => TextButton(
            onPressed: () async => answer = await FoDialog.destructive(
              context,
              title: 'Delete the draft from 2 Oct, 10:42?',
              message: 'The 64 Ecru pieces in this draft will be removed.',
              confirmLabel: 'Delete draft',
              cancelLabel: 'Keep draft',
            ),
            child: const Text('Open'),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.byType(BottomSheet), findsOneWidget);
      expect(find.byType(Dialog), findsNothing);
      await tester.tap(find.text('Delete draft'));
      await tester.pumpAndSettle();
      expect(answer, isTrue);
    });

    testWidgets('is a dialog on a wide window', (WidgetTester tester) async {
      bool? answer;
      await _pumpApp(
        tester,
        child: Builder(
          builder: (BuildContext context) => TextButton(
            onPressed: () async => answer = await FoDialog.confirm(
              context,
              title: 'Submit 114 pieces?',
              message: 'Submitted entries are locked.',
              confirmLabel: 'Submit',
              cancelLabel: 'Keep editing',
            ),
            child: const Text('Open'),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsOneWidget);
      await tester.tap(find.text('Keep editing'));
      await tester.pumpAndSettle();
      expect(answer, isFalse);
    });
  });

  group('FoHint.guide', () {
    testWidgets('opens a drawer on a wide window and a sheet on a phone', (
      WidgetTester tester,
    ) async {
      for (final (Size size, bool sheet) in <(Size, bool)>[
        (_desktop, false),
        (_phone, true),
      ]) {
        await _pumpApp(
          tester,
          size: size,
          child: const Center(
            child: FoHint.guide(
              buttonLabel: 'What is Midline?',
              guideTitle: 'What is Midline?',
              guideBody: Text('A check part-way down the line.'),
              closeLabel: 'Close the guide',
            ),
          ),
        );
        await tester.tap(find.bySemanticsLabel('What is Midline?'));
        await tester.pumpAndSettle();

        expect(find.text('A check part-way down the line.'), findsOneWidget);
        expect(find.byType(BottomSheet), sheet ? findsOneWidget : findsNothing);
        // The close button; on the drawer the scrim carries the same name, so
        // it can be dismissed by somebody who cannot see where the edge is.
        await tester.tap(find.widgetWithIcon(FoIconButton, Icons.close));
        await tester.pumpAndSettle();
        expect(find.text('A check part-way down the line.'), findsNothing);
      }
    });
  });

  group('FoAttentionList', () {
    testWidgets('each item has one way to act', (WidgetTester tester) async {
      int opened = 0;
      int tapped = 0;
      await pumpFo(
        tester,
        surfaceSize: _desktop,
        child: SizedBox(
          width: 600,
          child: FoAttentionList(
            items: <FoAttentionItem>[
              FoAttentionItem(
                icon: Icons.warning_amber_outlined,
                tone: FoStatusTone.danger,
                title: 'Slim Chino is due in 7 days',
                subtitle: '1,140 of 2,400 pieces still to pack',
                actionLabel: 'Open order',
                onAction: () => opened++,
              ),
              FoAttentionItem(
                icon: Icons.schedule,
                tone: FoStatusTone.info,
                title: 'Change request is with the owner',
                onTap: () => tapped++,
              ),
            ],
          ),
        ),
      );
      expect(find.byType(Divider), findsOneWidget);
      await tester.tap(find.text('Open order'));
      await tester.tap(find.text('Change request is with the owner'));
      expect((opened, tapped), (1, 1));
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    });

    testWidgets('an empty list renders nothing', (WidgetTester tester) async {
      await pumpFo(
        tester,
        child: const FoAttentionList(items: <FoAttentionItem>[]),
      );
      expect(find.byType(Divider), findsNothing);
    });
  });

  group('FoStageRail', () {
    const List<FoStage> stages = <FoStage>[
      FoStage(
          number: 7,
          label: 'Thread cut',
          value: '1,320',
          state: FoStageState.done),
      FoStage(
        number: 8,
        label: 'Pressing',
        value: '1,012',
        detail: '308 waiting',
        detailIsWarning: true,
        state: FoStageState.current,
      ),
      FoStage(
          number: 9,
          label: 'Packing',
          value: '860',
          state: FoStageState.upcoming),
    ];

    testWidgets('marks the current stage selected', (
      WidgetTester tester,
    ) async {
      await pumpFo(
        tester,
        surfaceSize: _desktop,
        child: const SizedBox(width: 900, child: FoStageRail(stages: stages)),
      );
      expect(find.byType(FoStageTile), findsNWidgets(3));
      expect(
        tester.getSemantics(find.byType(FoStageTile).at(1)),
        isSemantics(isSelected: true),
      );
      expect(
        tester.widget<Text>(find.text('308 waiting')).style?.color,
        FoColors.light.warning,
      );
    });

    testWidgets('tiles in a row share a height', (WidgetTester tester) async {
      await pumpFo(
        tester,
        surfaceSize: _desktop,
        child: const SizedBox(width: 900, child: FoStageRail(stages: stages)),
      );
      final double first =
          tester.getSize(find.byType(FoStageTile).at(0)).height;
      final double second =
          tester.getSize(find.byType(FoStageTile).at(1)).height;
      expect(first, second);
    });

    testWidgets('a phone gets a list, not nine tiles', (
      WidgetTester tester,
    ) async {
      await pumpFo(
        tester,
        surfaceSize: _phone,
        child: const SizedBox(width: 360, child: FoStageRail(stages: stages)),
      );
      expect(find.byType(FoStageTile), findsNothing);
      expect(find.text('Pressing'), findsOneWidget);
    });
  });

  group('FoLookupPicker', () {
    const FoEntityPickerCopy copy = FoEntityPickerCopy(
      searchHint: 'Job number, article or buyer',
      emptyText: 'No orders match.',
      errorText: "Couldn't load orders.",
      clearTooltip: 'Clear',
      requiredMessage: 'Choose an order.',
      closeLabel: 'Close',
      recentLabel: 'Recent',
      resultsLabel: 'Orders with pieces ready',
      scanLabel: 'Scan the job card',
      retryLabel: 'Try again',
    );
    const FoEntityPickerOption polo = FoEntityPickerOption(
      id: '10024',
      label: 'Pique Polo',
      supportingText: 'JOB-2026-10024',
      meta: '146 ready',
    );
    const FoEntityPickerOption chino = FoEntityPickerOption(
      id: '10019',
      label: 'Slim Chino',
      supportingText: 'JOB-2026-10019',
    );

    Future<FoEntityPickerOption?> open(
      WidgetTester tester, {
      required Size size,
      required Future<List<FoEntityPickerOption>> Function(String) search,
      Future<FoEntityPickerOption?> Function()? onScan,
    }) async {
      FoEntityPickerOption? picked;
      await _pumpApp(
        tester,
        size: size,
        child: Builder(
          builder: (BuildContext context) => TextButton(
            onPressed: () async => picked = await FoLookupPicker.show(
              context,
              title: 'Order',
              search: search,
              copy: copy,
              recent: const <FoEntityPickerOption>[chino],
              onScan: onScan,
            ),
            child: const Text('Open'),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      return picked;
    }

    testWidgets('a phone gets a full screen with recent choices first', (
      WidgetTester tester,
    ) async {
      await open(
        tester,
        size: _phone,
        search: (String q) async => <FoEntityPickerOption>[polo],
      );
      expect(find.byType(Dialog), findsNothing);
      expect(find.text('RECENT'), findsOneWidget);
      expect(find.text('ORDERS WITH PIECES READY'), findsOneWidget);
      expect(
        tester.getTopLeft(find.text('Slim Chino')).dy,
        lessThan(tester.getTopLeft(find.text('Pique Polo')).dy),
      );
      expect(find.text('146 ready'), findsOneWidget);
    });

    testWidgets('a wide window gets a dialog; picking resolves the option', (
      WidgetTester tester,
    ) async {
      FoEntityPickerOption? picked;
      await _pumpApp(
        tester,
        child: Builder(
          builder: (BuildContext context) => TextButton(
            onPressed: () async => picked = await FoLookupPicker.show(
              context,
              title: 'Order',
              search: (String q) async => <FoEntityPickerOption>[polo],
              copy: copy,
            ),
            child: const Text('Open'),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsOneWidget);

      await tester.tap(find.text('Pique Polo'));
      await tester.pumpAndSettle();
      expect(picked?.id, '10024');
    });

    testWidgets('searches as you type, and a slow old answer never wins', (
      WidgetTester tester,
    ) async {
      final Completer<List<FoEntityPickerOption>> slow =
          Completer<List<FoEntityPickerOption>>();
      final List<String> queries = <String>[];
      await open(
        tester,
        size: _desktop,
        search: (String q) {
          queries.add(q);
          if (q == 'po') return slow.future;
          return Future<List<FoEntityPickerOption>>.value(
            q.isEmpty
                ? <FoEntityPickerOption>[polo, chino]
                : <FoEntityPickerOption>[chino],
          );
        },
      );

      await tester.enterText(find.byType(TextField), 'po');
      await tester.pump(FoMotion.searchDebounce);
      await tester.enterText(find.byType(TextField), 'slim');
      await tester.pump(FoMotion.searchDebounce);
      await tester.pumpAndSettle();
      slow.complete(<FoEntityPickerOption>[polo]);
      await tester.pumpAndSettle();

      expect(queries, <String>['', 'po', 'slim']);
      expect(find.text('Slim Chino'), findsOneWidget);
      expect(find.text('Pique Polo'), findsNothing);
    });

    testWidgets('a failed search says so and can be retried', (
      WidgetTester tester,
    ) async {
      int calls = 0;
      await open(
        tester,
        size: _desktop,
        search: (String q) async {
          calls++;
          if (calls == 1) throw StateError('offline');
          return <FoEntityPickerOption>[polo];
        },
      );
      expect(find.text("Couldn't load orders."), findsOneWidget);
      expect(find.text('No orders match.'), findsNothing);

      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();
      expect(find.text('Pique Polo'), findsOneWidget);
    });

    testWidgets('scan resolves straight to the option it read', (
      WidgetTester tester,
    ) async {
      FoEntityPickerOption? picked;
      await _pumpApp(
        tester,
        child: Builder(
          builder: (BuildContext context) => TextButton(
            onPressed: () async => picked = await FoLookupPicker.show(
              context,
              title: 'Order',
              search: (String q) async => <FoEntityPickerOption>[],
              copy: copy,
              onScan: () async => polo,
            ),
            child: const Text('Open'),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Scan the job card'));
      await tester.pumpAndSettle();
      expect(picked?.id, '10024');
    });
  });

  group('FoFilterButton', () {
    testWidgets('says its filter and its value', (WidgetTester tester) async {
      int presses = 0;
      await pumpFo(
        tester,
        child: FoFilterButton(
          label: 'Order',
          value: 'All',
          onPressed: () => presses++,
        ),
      );
      expect(find.bySemanticsLabel('Order: All'), findsOneWidget);
      await tester.tap(find.byType(FoFilterButton));
      expect(presses, 1);
      expect(
        tester.getSize(find.byType(FoFilterButton)).height,
        greaterThanOrEqualTo(48),
      );
    });
  });

  group('FoPageHeader', () {
    testWidgets('carries a help accessory beside the title', (
      WidgetTester tester,
    ) async {
      await pumpFo(
        tester,
        surfaceSize: _desktop,
        child: const FoPageHeader(
          eyebrow: 'Production · Stage 8 of 9',
          title: 'Pressing',
          titleAccessory: FoHint.guide(
            buttonLabel: 'What is pressing?',
            guideTitle: 'Pressing',
            guideBody: Text('Pieces are ironed and shaped.'),
            closeLabel: 'Close',
          ),
        ),
      );
      final Offset title = tester.getCenter(find.text('Pressing'));
      final Offset help = tester.getCenter(
        find.bySemanticsLabel('What is pressing?'),
      );
      expect(help.dx, greaterThan(title.dx));
      expect((help.dy - title.dy).abs(), lessThan(24));
    });
  });

  group('FoToast', () {
    testWidgets('names the event and the record', (WidgetTester tester) async {
      await _pumpApp(
        tester,
        child: Builder(
          builder: (BuildContext context) => TextButton(
            onPressed: () => FoToast.success(
              context,
              '110 pieces of Deep Navy, JOB-2026-10024.',
              title: 'Pressing recorded',
            ),
            child: const Text('Save'),
          ),
        ),
      );
      await tester.tap(find.text('Save'));
      await tester.pump();
      expect(find.text('Pressing recorded'), findsOneWidget);
      expect(
        find.text('110 pieces of Deep Navy, JOB-2026-10024.'),
        findsOneWidget,
      );
    });
  });
}

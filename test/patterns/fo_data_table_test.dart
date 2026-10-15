import 'dart:ui' as ui;

import 'package:data_table_2/data_table_2.dart';
import 'package:figuredout_ui/figuredout_ui.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/pump.dart';

class _Row {
  const _Row(this.id, this.name, this.qty, [this.day]);
  final int id;
  final String name;
  final int qty;
  final String? day;
}

List<_Row> _rows(int count) => <_Row>[
      for (int i = 0; i < count; i++) _Row(i, 'Entry $i', i * 10),
    ];

List<FoTableColumn<_Row>> _columns({double? nameWidth, double? qtyWidth}) =>
    <FoTableColumn<_Row>>[
      FoTableColumn<_Row>(
        label: const Text('Entry'),
        size: FoColumnSize.l,
        width: nameWidth,
        cellBuilder: (BuildContext c, _Row r) => Text(r.name),
        cardValueBuilder: (_Row r) => r.name,
      ),
      FoTableColumn<_Row>(
        label: const Text('Quantity'),
        numeric: true,
        sortable: true,
        width: qtyWidth,
        cellBuilder: (BuildContext c, _Row r) => Text('${r.qty}'),
        cardValueBuilder: (_Row r) => '${r.qty}',
      ),
    ];

FoDataTable<_Row> _table({
  required List<_Row> rows,
  FoTableSizing sizing = FoTableSizing.content,
  bool framed = true,
  List<FoTableColumn<_Row>>? columns,
  bool Function(_Row)? isSelected,
  Key Function(_Row)? rowKey,
  String? Function(_Row)? sectionOf,
  void Function(_Row)? onRowTap,
  void Function(int, bool)? onSort,
  double? minWidth,
  bool loading = false,
}) =>
    FoDataTable<_Row>(
      columns: columns ?? _columns(),
      rows: rows,
      loading: loading,
      errorTitle: 'Could not load',
      retryLabel: 'Retry',
      sizing: sizing,
      framed: framed,
      isSelected: isSelected,
      rowKey: rowKey,
      sectionOf: sectionOf,
      onRowTap: onRowTap,
      onSort: onSort,
      minWidth: minWidth,
    );

/// A page: the one vertical scroll view, with a table in it that is given
/// unbounded height — which `DataTable2` asserts on.
Widget _page(Widget table) => SingleChildScrollView(child: table);

/// Pumps [child] in the page scroll. The caller sets the window size first.
Future<void> _pump(WidgetTester tester, Widget child) => tester.pumpWidget(
      MaterialApp(
        theme: FoTheme.light(),
        home: Scaffold(body: _page(child)),
      ),
    );

/// The vertical scrollables inside the table (the page's own is outside it).
Iterable<Element> _verticalScrollablesIn(WidgetTester tester) => find
    .descendant(
      of: find.byType(FoDataTable<_Row>),
      matching: find.byType(Scrollable),
    )
    .evaluate()
    .where(
      (Element e) =>
          (e.widget as Scrollable).axisDirection == AxisDirection.down ||
          (e.widget as Scrollable).axisDirection == AxisDirection.up,
    );

void main() {
  group('FoDataTable sizing: content', () {
    testWidgets(
      'grows with its rows in an unbounded parent and never scrolls itself',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1280, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await _pump(tester, _table(rows: _rows(30)));

        expect(tester.takeException(), isNull);
        expect(find.byType(DataTable2), findsNothing);
        expect(_verticalScrollablesIn(tester), isEmpty);
        // Heading band 36 + 30 rows of at least 48 (the hairline is a
        // foreground decoration and takes no room).
        final double height =
            tester.getSize(find.byType(FoDataTable<_Row>)).height;
        expect(height, greaterThanOrEqualTo(36 + 30 * 48));
        // The last row exists and is far below the fold: the page scrolls, the
        // table does not.
        expect(tester.getTopLeft(find.text('Entry 29')).dy, greaterThan(900));
      },
    );

    testWidgets('a row is one line of at least 48, the heading band 36', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await _pump(tester, _table(rows: _rows(3)));

      final Rect first = tester.getRect(
        find.ancestor(of: find.text('Entry 0'), matching: find.byType(InkWell)),
      );
      final Rect second = tester.getRect(
        find.ancestor(of: find.text('Entry 1'), matching: find.byType(InkWell)),
      );
      expect(first.height, 48);
      expect(second.top, first.bottom, reason: 'rows are stacked edge to edge');
      final Rect heading = tester.getRect(
        find
            .ancestor(
              of: find.text('ENTRY'),
              matching: find.byType(ConstrainedBox),
            )
            .first,
      );
      expect(heading.height, 36);
    });

    testWidgets('headings are mono captions in upper case', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await _pump(tester, _table(rows: _rows(2)));

      expect(find.text('ENTRY'), findsOneWidget);
      expect(find.text('QUANTITY'), findsOneWidget);
      expect(find.text('Entry'), findsNothing);
      final TextStyle style = tester.widget<Text>(find.text('ENTRY')).style!;
      expect(style.fontFamily, contains('GeistMono'));
      expect(style.letterSpacing, FoTokens.captionLetterSpacing);
    });

    testWidgets('the open row is selected for a screen reader and painted', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final SemanticsHandle handle = tester.ensureSemantics();
      await _pump(
        tester,
        _table(
          rows: _rows(3),
          isSelected: (_Row r) => r.id == 1,
          onRowTap: (_) {},
        ),
      );

      Finder rowOf(String text) => find.ancestor(
            of: find.text(text),
            matching: find.byWidgetPredicate(
              (Widget w) => w is Semantics && w.properties.selected != null,
            ),
          );
      expect(
        tester.getSemantics(rowOf('Entry 1')),
        isSemantics(hasSelectedState: true, isSelected: true),
      );
      expect(
        tester.getSemantics(rowOf('Entry 0')),
        isSemantics(hasSelectedState: true, isSelected: false),
      );

      Color? fillOf(String text) => tester
          .widget<Material>(
            find
                .ancestor(of: find.text(text), matching: find.byType(Material))
                .first,
          )
          .color;
      expect(fillOf('Entry 1'), FoColors.light.primarySoft);
      expect(fillOf('Entry 0'), Colors.transparent);
      handle.dispose();
    });

    group('a focused or picked row', () {
      testWidgets('reached with Tab it has a 2 px ring and no fill', (
        WidgetTester tester,
      ) async {
        FocusManager.instance.highlightStrategy =
            FocusHighlightStrategy.alwaysTraditional;
        addTearDown(
          () => FocusManager.instance.highlightStrategy =
              FocusHighlightStrategy.automatic,
        );
        tester.view.physicalSize = const Size(1280, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await _pump(
          tester,
          _table(
            rows: _rows(2),
            onRowTap: (_Row r) {},
            rowKey: (_Row r) => ValueKey<int>(r.id),
          ),
        );

        // The sortable heading is the first stop; the first row the second.
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();

        final Finder first = find.byKey(const ValueKey<int>(1));
        expect(
          tester
              .widget<InkWell>(
                find.descendant(of: first, matching: find.byType(InkWell)),
              )
              .focusColor,
          Colors.transparent,
        );
        BoxDecoration ringOf(Finder row) => tester
            .widgetList<DecoratedBox>(
              find.descendant(of: row, matching: find.byType(DecoratedBox)),
            )
            .map((DecoratedBox d) => d.decoration)
            .whereType<BoxDecoration>()
            .firstWhere(
              (BoxDecoration d) =>
                  d.border is Border && (d.border! as Border).left.width > 0,
              orElse: () => const BoxDecoration(),
            );
        final Border border = ringOf(first).border! as Border;
        expect(border.top.width, 2);
        expect(border.top.color, FoColors.light.focusRing);
        expect(ringOf(find.byKey(const ValueKey<int>(2))).border, isNull);
      });

      testWidgets('a row picked under the pointer stays a light tint', (
        WidgetTester tester,
      ) async {
        tester.view.physicalSize = const Size(1280, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final GlobalKey boundary = GlobalKey();
        int? picked;
        await tester.pumpWidget(
          MaterialApp(
            theme: FoTheme.light(),
            home: Scaffold(
              body: StatefulBuilder(
                builder: (BuildContext context, StateSetter set) =>
                    RepaintBoundary(
                  key: boundary,
                  child: ColoredBox(
                    color: FoColors.light.surface,
                    child: SingleChildScrollView(
                      child: _table(
                        rows: _rows(3),
                        onRowTap: (_Row r) => set(() => picked = r.id),
                        isSelected: (_Row r) => r.id == picked,
                        rowKey: (_Row r) => ValueKey<int>(r.id),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        final Offset empty =
            tester.getTopRight(find.byKey(const ValueKey<int>(2))) +
                const Offset(-300, 24);
        final TestGesture mouse = await tester.createGesture(
          kind: PointerDeviceKind.mouse,
        );
        await mouse.addPointer(location: Offset.zero);
        await mouse.moveTo(empty);
        await tester.pump(const Duration(milliseconds: 300));
        await mouse.down(empty);
        await tester.pump(const Duration(milliseconds: 50));
        await mouse.up();
        await tester.pump(const Duration(milliseconds: 2000));

        final RenderRepaintBoundary render = boundary.currentContext!
            .findRenderObject()! as RenderRepaintBoundary;
        final Offset at = empty - render.localToGlobal(Offset.zero);
        final ui.Image image =
            (await tester.runAsync<ui.Image>(() => render.toImage()))!;
        final ByteData data =
            (await tester.runAsync<ByteData?>(() => image.toByteData()))!;
        final int i = (at.dy.toInt() * image.width + at.dx.toInt()) * 4;
        final Color shown = Color.fromARGB(
          data.getUint8(i + 3),
          data.getUint8(i),
          data.getUint8(i + 1),
          data.getUint8(i + 2),
        );

        expect(picked, 2);
        expect(shown.a, 1.0);
        expect(shown, isNot(FoColors.light.primary));
        expect(
          (shown.computeLuminance() - FoColors.light.primary.computeLuminance())
              .abs(),
          greaterThan(0.3),
        );
      });
    });

    testWidgets('the whole row is the target', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final List<int> opened = <int>[];
      await _pump(
        tester,
        _table(rows: _rows(3), onRowTap: (_Row r) => opened.add(r.id)),
      );

      // The quantity cell, not the name: any part of the row opens it.
      await tester.tap(find.text('20'));
      expect(opened, <int>[2]);
    });

    testWidgets('sectionOf draws a full-width heading when the value changes', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      const List<_Row> rows = <_Row>[
        _Row(0, 'A', 1, 'Today'),
        _Row(1, 'B', 2, 'Today'),
        _Row(2, 'C', 3, 'Yesterday'),
        _Row(3, 'D', 4),
      ];
      await _pump(
        tester,
        _table(rows: rows, sectionOf: (_Row r) => r.day),
      );

      expect(find.text('Today'), findsOneWidget);
      expect(find.text('Yesterday'), findsOneWidget);
      final Rect today = tester.getRect(find.text('Today'));
      final Rect a = tester.getRect(find.text('A'));
      final Rect c = tester.getRect(find.text('C'));
      final Rect yesterday = tester.getRect(find.text('Yesterday'));
      expect(today.bottom, lessThan(a.top), reason: 'the heading comes first');
      expect(
        yesterday.top,
        greaterThan(tester.getRect(find.text('B')).bottom),
      );
      expect(yesterday.bottom, lessThan(c.top));
      // A null section draws none, and D stays under Yesterday's heading
      // rather than starting a new group.
      expect(find.text('null'), findsNothing);
    });

    for (final bool framed in <bool>[true, false]) {
      testWidgets('framed: $framed ${framed ? 'paints' : 'paints no'} border',
          (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1280, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await _pump(tester, _table(rows: _rows(2), framed: framed));

        // Rows carry only a top hairline; a frame is a border on all sides.
        final Iterable<DecoratedBox> frames = tester
            .widgetList<DecoratedBox>(find.byType(DecoratedBox))
            .where((DecoratedBox b) {
          final Decoration d = b.decoration;
          return d is BoxDecoration &&
              d.border != null &&
              d.border!.bottom != BorderSide.none;
        });
        expect(frames.isNotEmpty, framed);
        expect(
          find.descendant(
            of: find.byType(FoDataTable<_Row>),
            matching: find.byType(ClipRRect),
          ),
          framed ? findsOneWidget : findsNothing,
        );
      });
    }

    testWidgets('a fixed column width is kept; the rest share what is left', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await _pump(
        tester,
        _table(rows: _rows(2), columns: _columns(qtyWidth: 120)),
      );

      final Size qty = tester.getSize(
        find.ancestor(of: find.text('10'), matching: find.byType(Align)).first,
      );
      expect(qty.width, 120);
      final Size name = tester.getSize(
        find
            .ancestor(of: find.text('Entry 1'), matching: find.byType(Align))
            .first,
      );
      expect(name.width, greaterThan(800));
    });

    testWidgets('under minWidth it scrolls sideways, never down', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await _pump(tester, _table(rows: _rows(5), minWidth: 1600));

      expect(tester.takeException(), isNull);
      final Iterable<Element> scrollables = find
          .descendant(
            of: find.byType(FoDataTable<_Row>),
            matching: find.byType(Scrollable),
          )
          .evaluate();
      expect(scrollables, hasLength(1));
      expect(
        (scrollables.single.widget as Scrollable).axisDirection,
        AxisDirection.right,
      );
      expect(_verticalScrollablesIn(tester), isEmpty);
      expect(tester.getSize(find.byType(FoDataTable<_Row>)).width, 1280);
      final ScrollableState state = tester.state<ScrollableState>(
        find.descendant(
          of: find.byType(FoDataTable<_Row>),
          matching: find.byType(Scrollable),
        ),
      );
      expect(state.position.maxScrollExtent, 1600 - 1280);
    });

    testWidgets('a sortable heading reports a sort, flipping the direction', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final List<(int, bool)> sorts = <(int, bool)>[];
      await _pump(
        tester,
        FoDataTable<_Row>(
          columns: _columns(),
          rows: _rows(2),
          loading: false,
          errorTitle: 'Could not load',
          retryLabel: 'Retry',
          sizing: FoTableSizing.content,
          sortColumnIndex: 1,
          onSort: (int i, bool asc) => sorts.add((i, asc)),
        ),
      );
      await tester.tap(find.text('QUANTITY'));
      expect(sorts, <(int, bool)>[(1, false)]);
      await tester.tap(find.text('ENTRY'));
      expect(sorts.length, 1, reason: 'a column that is not sortable is inert');
    });

    testWidgets('rowKey keys each row', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await _pump(
        tester,
        _table(rows: _rows(3), rowKey: (_Row r) => ValueKey<int>(r.id)),
      );
      expect(find.byKey(const ValueKey<int>(2)), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const ValueKey<int>(2)),
          matching: find.text('Entry 2'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('loading is a column of skeletons, not a list', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await _pump(
        tester,
        _table(rows: const <_Row>[], loading: true, framed: false),
      );
      expect(tester.takeException(), isNull);
      expect(find.byType(FoSkeleton), findsWidgets);
      expect(_verticalScrollablesIn(tester), isEmpty);
    });

    testWidgets('on a phone it is a column of cards in the page scroll', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(420, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await _pump(
        tester,
        _table(
          rows: _rows(12),
          isSelected: (_Row r) => r.id == 0,
          rowKey: (_Row r) => ValueKey<int>(r.id),
          sectionOf: (_Row r) => r.id < 6 ? 'Morning' : 'Afternoon',
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(ListView), findsNothing);
      expect(find.byType(FoCard), findsNWidgets(12));
      expect(_verticalScrollablesIn(tester), isEmpty);
      expect(find.text('Morning'), findsOneWidget);
      expect(find.text('Afternoon'), findsOneWidget);
      expect(find.byKey(const ValueKey<int>(3)), findsOneWidget);
    });
  });

  group('FoDataTable sizing: fill (unchanged)', () {
    testWidgets('is still DataTable2 in a bounded box', (
      WidgetTester tester,
    ) async {
      await pumpFo(
        tester,
        surfaceSize: const Size(1280, 900),
        child: SizedBox(
          height: 600,
          child: _table(rows: _rows(30), sizing: FoTableSizing.fill),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.byType(DataTable2), findsOneWidget);
    });

    testWidgets('the default sizing is fill', (WidgetTester tester) async {
      await pumpFo(
        tester,
        surfaceSize: const Size(1280, 900),
        child: SizedBox(
          height: 600,
          child: FoDataTable<_Row>(
            columns: _columns(),
            rows: _rows(3),
            loading: false,
            errorTitle: 'Could not load',
            retryLabel: 'Retry',
          ),
        ),
      );
      expect(find.byType(DataTable2), findsOneWidget);
    });

    testWidgets('framed: false drops the frame, a column width is kept', (
      WidgetTester tester,
    ) async {
      await pumpFo(
        tester,
        surfaceSize: const Size(1280, 900),
        child: SizedBox(
          height: 600,
          child: _table(
            rows: _rows(3),
            sizing: FoTableSizing.fill,
            framed: false,
            columns: _columns(qtyWidth: 140),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.byType(ClipRRect), findsNothing);
      final DataTable2 table =
          tester.widget<DataTable2>(find.byType(DataTable2));
      expect((table.columns[1] as DataColumn2).fixedWidth, 140);
    });
  });
}

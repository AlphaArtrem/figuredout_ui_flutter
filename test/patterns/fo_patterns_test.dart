import 'package:figuredout_ui/figuredout_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/pump.dart';

/// A row for the table tests.
class _Row {
  const _Row(this.name, this.qty);
  final String name;
  final int qty;
}

List<FoTableColumn<_Row>> _columns() => <FoTableColumn<_Row>>[
      FoTableColumn<_Row>(
        label: const Text('Name'),
        size: FoColumnSize.l,
        cellBuilder: (BuildContext c, _Row r) => Text(r.name),
        cardValueBuilder: (_Row r) => r.name,
      ),
      FoTableColumn<_Row>(
        label: const Text('Quantity'),
        numeric: true,
        cellBuilder: (BuildContext c, _Row r) => Text('${r.qty}'),
        cardValueBuilder: (_Row r) => '${r.qty}',
      ),
    ];

void main() {
  group('FoDataTable', () {
    testWidgets('renders a table on a wide window and cards on a narrow one', (
      WidgetTester tester,
    ) async {
      Future<void> pumpAt(Size size) => pumpFo(
            tester,
            surfaceSize: size,
            child: FoDataTable<_Row>(
              columns: _columns(),
              rows: const <_Row>[_Row('Sleeve', 12), _Row('Collar', 8)],
              loading: false,
              errorTitle: 'Could not load',
              retryLabel: 'Retry',
            ),
          );

      await pumpAt(const Size(1280, 900));
      expect(find.byType(FoCard), findsNothing);
      expect(find.text('Sleeve'), findsOneWidget);

      await pumpAt(const Size(420, 900));
      // One card per row, and the same columns feed both — which is why this
      // is one component rather than two that can drift apart.
      expect(find.byType(FoCard), findsNWidgets(2));
    });

    testWidgets('an error renders in the rows\' place, not above the table', (
      WidgetTester tester,
    ) async {
      int retries = 0;
      await pumpFo(
        tester,
        surfaceSize: const Size(1280, 900),
        child: FoDataTable<_Row>(
          columns: _columns(),
          rows: const <_Row>[],
          loading: false,
          error: 'Connection refused',
          errorTitle: 'Could not load entries',
          retryLabel: 'Retry',
          onRetry: () => retries++,
        ),
      );

      // The screen keeps its search box and filters, so the user can change
      // what they asked for — an early-returned error banner destroys both.
      expect(find.text('Could not load entries'), findsOneWidget);
      expect(find.text('Connection refused'), findsOneWidget);
      await tester.tap(find.text('Retry'));
      expect(retries, 1);
    });

    testWidgets('loading shows skeletons shaped like the table', (
      WidgetTester tester,
    ) async {
      await pumpFo(
        tester,
        surfaceSize: const Size(1280, 900),
        child: FoDataTable<_Row>(
          columns: _columns(),
          rows: const <_Row>[],
          loading: true,
          errorTitle: 'Could not load',
          retryLabel: 'Retry',
        ),
      );
      await tester.pump();

      // Not a spinner: the layout must not jump when the rows land.
      expect(find.byType(FoSkeleton), findsWidgets);
    });

    testWidgets('the frame hairline survives the full-bleed heading row', (
      WidgetTester tester,
    ) async {
      await pumpFo(
        tester,
        surfaceSize: const Size(1280, 900),
        child: FoDataTable<_Row>(
          columns: _columns(),
          rows: const <_Row>[_Row('Sleeve', 12)],
          loading: false,
          errorTitle: 'Could not load',
          retryLabel: 'Retry',
        ),
      );

      // G3 again: the heading row paints its own background to the frame's
      // edges inside the clip, so a border in `decoration` loses its top edge.
      final Iterable<DecoratedBox> bordered = tester
          .widgetList<DecoratedBox>(find.byType(DecoratedBox))
          .where((DecoratedBox b) {
        final Decoration d = b.decoration;
        return d is BoxDecoration && d.border != null;
      });

      expect(bordered, isNotEmpty);
      expect(
        bordered.every(
          (DecoratedBox b) => b.position == DecorationPosition.foreground,
        ),
        isTrue,
        reason: 'the table frame must draw its hairline in the foreground',
      );
    });
  });

  group('FoInfoBanner', () {
    testWidgets('an empty message renders nothing at all', (
      WidgetTester tester,
    ) async {
      await pumpFo(tester, child: const FoInfoBanner(message: null));
      // So a screen can bind it straight to an optional error, with no `if`.
      expect(find.byType(Icon), findsNothing);
      expect(find.byType(Row), findsNothing);
    });

    testWidgets('an error banner is a live region and carries its retry', (
      WidgetTester tester,
    ) async {
      int retries = 0;
      await pumpFo(
        tester,
        child: FoInfoBanner.error(
          message: 'Could not save.',
          onRetry: () => retries++,
          retryLabel: 'Retry',
        ),
      );

      expect(
        tester.getSemantics(find.byType(FoInfoBanner)),
        isSemantics(isLiveRegion: true),
      );
      await tester.tap(find.text('Retry'));
      expect(retries, 1);
    });

    testWidgets('each tone grounds its ink on the matching -soft token', (
      WidgetTester tester,
    ) async {
      for (final (FoBannerTone tone, Color ground) in <(FoBannerTone, Color)>[
        (FoBannerTone.info, FoColors.light.infoSoft),
        (FoBannerTone.success, FoColors.light.successSoft),
        (FoBannerTone.warning, FoColors.light.warningSoft),
        (FoBannerTone.danger, FoColors.light.dangerSoft),
      ]) {
        await pumpFo(
          tester,
          child: FoInfoBanner(message: 'Something', tone: tone),
        );
        final Container box = tester.widget<Container>(
          find.descendant(
            of: find.byType(FoInfoBanner),
            matching: find.byType(Container),
          ),
        );
        expect((box.decoration! as BoxDecoration).color, ground);
      }
    });
  });

  group('FoInfoBanner at 200% text', () {
    testWidgets(
        'drops its action under the message rather than off the '
        'right', (WidgetTester tester) async {
      // A `Row` gave the action its natural width and the message whatever was
      // left, which is fine until the action alone is wider than the banner —
      // and then the `Expanded` collapses to nothing and the button is an
      // action nobody can reach. Found in a consuming app, at 200%.
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      await pumpFo(
        tester,
        surfaceSize: const Size(390, 844),
        child: FoInfoBanner.error(
          message: 'That did not save. Nothing has been lost.',
          retryLabel: 'Try again',
          onRetry: () {},
        ),
      );

      expect(tester.takeException(), isNull);
      // Reachable, and whole: the label is the only thing that says what the
      // button does.
      expect(find.text('Try again'), findsOneWidget);
      final Rect message = tester.getRect(
        find.text('That did not save. Nothing has been lost.'),
      );
      final Rect action = tester.getRect(find.text('Try again'));
      expect(action.top, greaterThanOrEqualTo(message.top));
      expect(action.right, lessThanOrEqualTo(390));
    });

    testWidgets('and keeps the action beside the message when it fits', (
      WidgetTester tester,
    ) async {
      // At ordinary size nothing moves: two children in one run sit at either
      // end, which is what the `Row` did.
      await pumpFo(
        tester,
        surfaceSize: const Size(900, 400),
        child: FoInfoBanner(
          message: 'Saved.',
          actionLabel: 'Undo',
          onAction: () {},
        ),
      );

      final Rect message = tester.getRect(find.text('Saved.'));
      final Rect action = tester.getRect(find.text('Undo'));
      expect(action.left, greaterThan(message.right));
    });
  });

  group('FoEmptyState', () {
    testWidgets('the error variant defaults its action to a retry mark', (
      WidgetTester tester,
    ) async {
      await pumpFo(
        tester,
        child: FoEmptyState.error(
          title: 'Could not load',
          actionLabel: 'Retry',
          onAction: () {},
        ),
      );
      expect(find.byIcon(Icons.refresh), findsOneWidget);
    });

    testWidgets('no action label means no button', (
      WidgetTester tester,
    ) async {
      await pumpFo(
        tester,
        child: const FoEmptyState(icon: Icons.inbox, title: 'Nothing yet'),
      );
      expect(find.byType(FoButton), findsNothing);
    });

    testWidgets('scrolls rather than overflowing at 200% text', (
      WidgetTester tester,
    ) async {
      // **The screen somebody at 200% is most likely to be reading**: an empty
      // state is what an app shows before there is any content to look at
      // instead. A mark, a title, a hint and a button stopped fitting on a
      // phone, and the column painted past the bottom of what it was given.
      //
      // The assertion is the absence of an exception — an overflow is reported
      // to `FlutterError.onError` during layout and fails the test on its own,
      // so nothing here names a pixel count and this survives a change of
      // copy or of the type scale.
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      await pumpFo(
        tester,
        surfaceSize: const Size(390, 500),
        child: FoEmptyState.error(
          title: 'Could not load this list',
          hint: 'Check your connection and try again. If it keeps failing, '
              'somebody may be working on it.',
          actionLabel: 'Try again',
          onAction: () {},
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Try again'), findsOneWidget);
    });

    testWidgets('and is still centred when it does fit', (
      WidgetTester tester,
    ) async {
      // The other half of the scroll view: `minHeight` is what keeps the
      // ordinary case identical, so a short state sits in the middle of the
      // viewport rather than pinned to the top of a scroll.
      await pumpFo(
        tester,
        surfaceSize: const Size(390, 800),
        child: const FoEmptyState(icon: Icons.inbox, title: 'Nothing yet'),
      );

      final Rect title = tester.getRect(find.text('Nothing yet'));
      expect(title.center.dy, closeTo(400, 60));
    });
  });

  group('FoPaginationBar', () {
    testWidgets('the ends are disabled, and totalPages clamps to one', (
      WidgetTester tester,
    ) async {
      await pumpFo(
        tester,
        surfaceSize: const Size(1280, 400),
        child: FoPaginationBar(
          page: 1,
          // An empty result must read "page 1 of 1", never "1 of 0".
          totalPages: 0,
          totalLabel: '0 entries',
          pageLabel: 'Page 1 of 1',
          previousTooltip: 'Previous',
          nextTooltip: 'Next',
          pageSemanticLabel: (int p) => 'page-$p',
          onPageChanged: (_) {},
        ),
      );

      final Iterable<IconButton> buttons = tester.widgetList<IconButton>(
        find.byType(IconButton),
      );
      expect(buttons.every((IconButton b) => b.onPressed == null), isTrue);
    });

    testWidgets('shows every page when the width has room for them all', (
      WidgetTester tester,
    ) async {
      await pumpFo(
        tester,
        surfaceSize: const Size(1400, 400),
        child: FoPaginationBar(
          page: 6,
          totalPages: 12,
          totalLabel: '12 entries',
          pageLabel: 'Page 6 of 12',
          previousTooltip: 'Previous',
          nextTooltip: 'Next',
          pageSemanticLabel: (int p) => 'page-$p',
          onPageChanged: (_) {},
        ),
      );

      for (int page = 1; page <= 12; page++) {
        expect(find.bySemanticsLabel('page-$page'), findsOneWidget);
      }
    });

    testWidgets(
        'drops the labels and shows fewer pages below the compact width',
        (WidgetTester tester) async {
      await pumpFo(
        tester,
        // Under FoPaginationBar's 480 threshold — arrows and track only.
        surfaceSize: const Size(400, 400),
        child: FoPaginationBar(
          page: 1,
          totalPages: 5,
          totalLabel: '5 entries',
          pageLabel: 'Page 1 of 5',
          previousTooltip: 'Previous',
          nextTooltip: 'Next',
          pageSemanticLabel: (int p) => 'page-$p',
          onPageChanged: (_) {},
        ),
      );

      expect(find.text('5 entries'), findsNothing);
      expect(find.text('Page 1 of 5'), findsNothing);
      expect(find.byType(IconButton), findsNWidgets(2));
      // Some pages still show — the track does not disappear, only the copy.
      expect(find.bySemanticsLabel('page-1'), findsOneWidget);
    });

    testWidgets(
        'a width above the threshold but too narrow for every tile still '
        'anchors on first, current and last', (WidgetTester tester) async {
      await pumpFo(
        tester,
        // Above the 480 compact threshold, but too narrow for 50 tiles.
        surfaceSize: const Size(700, 400),
        child: FoPaginationBar(
          page: 25,
          totalPages: 50,
          totalLabel: '50 entries',
          pageLabel: 'Page 25 of 50',
          previousTooltip: 'Previous',
          nextTooltip: 'Next',
          pageSemanticLabel: (int p) => 'page-$p',
          onPageChanged: (_) {},
        ),
      );

      expect(find.bySemanticsLabel('page-1'), findsOneWidget);
      expect(find.bySemanticsLabel('page-25'), findsOneWidget);
      expect(find.bySemanticsLabel('page-50'), findsOneWidget);
      // Not every page fits — the far side of the range is not anchored.
      expect(find.bySemanticsLabel('page-10'), findsNothing);
    });

    testWidgets('tapping a tile calls onPageChanged with its number', (
      WidgetTester tester,
    ) async {
      int? tapped;
      await pumpFo(
        tester,
        surfaceSize: const Size(1400, 400),
        child: FoPaginationBar(
          page: 1,
          totalPages: 5,
          totalLabel: '5 entries',
          pageLabel: 'Page 1 of 5',
          previousTooltip: 'Previous',
          nextTooltip: 'Next',
          pageSemanticLabel: (int p) => 'page-$p',
          onPageChanged: (int p) => tapped = p,
        ),
      );

      await tester.tap(find.bySemanticsLabel('page-3'));
      expect(tapped, 3);
    });
  });

  group('FoFilterBar', () {
    testWidgets('the clear action appears only when a filter is set', (
      WidgetTester tester,
    ) async {
      Future<void> pumpWith({required bool active}) => pumpFo(
            tester,
            surfaceSize: const Size(1280, 400),
            child: FoFilterBar(
              hasActiveFilters: active,
              clearLabel: 'Clear filters',
              onClear: () {},
              children: const <Widget>[Text('Line')],
            ),
          );

      // A permanently visible "Clear filters" gives no signal about whether
      // the list in front of you is the whole list.
      await pumpWith(active: false);
      expect(find.text('Clear filters'), findsNothing);

      await pumpWith(active: true);
      expect(find.text('Clear filters'), findsOneWidget);
    });
  });

  group('FoResponsiveTileGrid', () {
    testWidgets('the last partial row fills the width', (
      WidgetTester tester,
    ) async {
      await pumpFo(
        tester,
        surfaceSize: const Size(1200, 800),
        child: SizedBox(
          width: 1200,
          child: FoResponsiveTileGrid<int>(
            items: const <int>[1, 2, 3, 4, 5, 6],
            columnsBuilder: (_) => 4,
            itemBuilder: (BuildContext c, int i) =>
                SizedBox(height: 40, child: Text('Tile $i')),
          ),
        ),
      );

      final double firstRowTile = tester.getSize(find.text('Tile 1')).width;
      final double lastRowTile = tester.getSize(find.text('Tile 5')).width;

      // A GridView would give the final two tiles a quarter each and strand
      // them at the left, with a gap that reads as missing content.
      expect(lastRowTile, greaterThan(firstRowTile));
    });
  });

  group('FoScaffold', () {
    testWidgets('no controls means no controls bar', (
      WidgetTester tester,
    ) async {
      await pumpFo(
        tester,
        child: const FoScaffold(title: 'Entries', body: Text('Body')),
      );
      expect(find.text('Entries'), findsOneWidget);
      expect(find.text('Body'), findsOneWidget);
    });

    testWidgets('primaryActionBuilder runs inside the reactive wrapper', (
      WidgetTester tester,
    ) async {
      int wrapped = 0;
      final Widget Function(Widget Function(BuildContext)) original =
          FoScaffold.reactiveBuilder;
      addTearDown(() => FoScaffold.reactiveBuilder = original);

      FoScaffold.reactiveBuilder = (Widget Function(BuildContext) builder) {
        wrapped++;
        return Builder(builder: builder);
      };

      await pumpFo(
        tester,
        surfaceSize: const Size(1280, 900),
        child: FoScaffold(
          title: 'Entries',
          body: const Text('Body'),
          primaryActionBuilder: (BuildContext context) =>
              FoActionButton(label: 'New', onPressed: () {}),
        ),
      );

      // Without the wrapper an observable read here is untracked: it resolves
      // once, before the session exists, and the action never appears.
      expect(wrapped, greaterThan(0));
      expect(find.text('New'), findsOneWidget);
    });
  });
  group('FoSectionHeader', () {
    testWidgets('long-pressing the title is the hint\'s second route', (
      WidgetTester tester,
    ) async {
      int opened = 0;
      await pumpFo(
        tester,
        surfaceSize: const Size(420, 800),
        child: FoSectionHeader(
          title: 'Line status',
          // The dot is small and a tablet has no hover, so the title has to
          // reach the same explanation.
          onTitleLongPress: () => opened++,
        ),
      );

      await tester.longPress(find.text('Line status'));
      expect(opened, 1);
    });
  });
  group('FoEntityPickerField', () {
    testWidgets('an option row splashes inside the surface, not behind it', (
      WidgetTester tester,
    ) async {
      // The picker list sits on `foOverlaySurface`, which paints a fill. A
      // ListTile whose nearest Material is above that fill asserts — the same
      // shape of bug FoCard had, found the same way.
      final TextEditingController controller = TextEditingController();
      addTearDown(controller.dispose);

      await pumpFo(
        tester,
        surfaceSize: const Size(1000, 800),
        child: FoEntityPickerField(
          controller: controller,
          label: 'Order',
          selectedId: null,
          search: (String query) async => const <FoEntityPickerOption>[
            FoEntityPickerOption(id: '1', label: 'ORD-1001'),
          ],
          onSelected: (FoEntityPickerOption? _) {},
          copy: const FoEntityPickerCopy(
            searchHint: 'Search',
            emptyText: 'Nothing here yet',
            errorText: 'Could not load',
            clearTooltip: 'Clear',
            requiredMessage: 'This field is required',
            discardCopy: FoDiscardCopy(
              title: 'Discard changes?',
              message: 'Your edits have not been saved yet.',
              confirmLabel: 'Discard',
              cancelLabel: 'Keep editing',
            ),
          ),
        ),
      );

      await tester.tap(find.byType(TextFormField));
      await tester.pumpAndSettle();

      expect(find.text('ORD-1001'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('FoToast', () {
    testWidgets(
        'the action is a tinted button, not unfilled text, and dismisses '
        'before it runs', (WidgetTester tester) async {
      bool ran = false;
      await pumpFo(
        tester,
        child: Builder(
          builder: (BuildContext context) => ElevatedButton(
            onPressed: () => FoToast.info(
              context,
              'Synced two minutes ago.',
              action: FoToastAction(
                label: 'Undo',
                onPressed: () => ran = true,
              ),
            ),
            child: const Text('show'),
          ),
        ),
      );

      await tester.tap(find.text('show'));
      await tester.pumpAndSettle();

      // A ghost/clear TextButton is unfilled text, which is exactly what
      // ui-web's toast fix (db953bf) moved away from — the action is a
      // FoButton now, not a bare TextButton.
      expect(find.byType(FoButton), findsOneWidget);
      expect(find.byType(TextButton), findsNothing);

      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();
      expect(ran, isTrue);
      expect(find.text('Synced two minutes ago.'), findsNothing);
    });
  });
}

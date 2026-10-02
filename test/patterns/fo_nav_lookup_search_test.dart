import 'package:figuredout_ui/figuredout_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// 0.7.1: numbered nav items, the lookup picker's likely section, scopes, "no
/// filter" and total line, and the search palette's type tabs.
///
/// The board sizes are the canvas's: a 390 × 844 phone and a 1440 × 1000
/// desktop, in light and in Graphite dark.

const Size _phone = Size(390, 844);
const Size _desktop = Size(1440, 1000);
const Size _tablet = Size(820, 1180);

Future<void> _pumpApp(
  WidgetTester tester, {
  required Widget child,
  Size size = _desktop,
  ThemeData? theme,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pumpWidget(
    MaterialApp(
      theme: theme ?? FoTheme.light(),
      home: Scaffold(body: child),
    ),
  );
}

Widget _opener(Future<void> Function(BuildContext context) open) => Builder(
      builder: (BuildContext context) => Center(
        child: TextButton(
          onPressed: () => open(context),
          child: const Text('Open'),
        ),
      ),
    );

const List<String> _stages = <String>[
  'Cutting',
  'Line loading',
  'Midline',
  'Output',
  'QC',
  'Bartek',
  'Thread cutting',
  'Pressing',
  'Packing',
];

List<FoNavGroup> _shellGroups() => <FoNavGroup>[
      FoNavGroup(
        items: <FoNavItem>[
          FoNavItem(
            id: 'today',
            label: 'Today',
            icon: Icons.home_outlined,
            selectedIcon: Icons.home,
            onSelected: () {},
          ),
          FoNavItem(
            id: 'approvals',
            label: 'Approvals',
            icon: Icons.fact_check_outlined,
            selectedIcon: Icons.fact_check,
            onSelected: () {},
            badgeCount: 3,
            badgeSemanticLabel: '3 waiting for you',
          ),
        ],
      ),
      FoNavGroup(
        label: 'Production stages',
        items: <FoNavItem>[
          for (int i = 0; i < _stages.length; i++)
            FoNavItem(
              id: _stages[i],
              label: _stages[i],
              icon: Icons.circle_outlined,
              selectedIcon: Icons.circle,
              onSelected: () {},
              number: i + 1,
            ),
        ],
      ),
    ];

/// The disc carrying [number]: the nearest `FoDisc` above its text.
Finder _disc(int number) => find.ancestor(
      of: find.text('$number'),
      matching: find.byType(FoDisc),
    );

const FoEntityPickerCopy _copy = FoEntityPickerCopy(
  searchHint: 'Job number, article or buyer',
  emptyText: 'No orders match.',
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

const FoEntityPickerOption _polo = FoEntityPickerOption(
  id: '10024',
  label: 'Pique Polo',
  supportingText: 'JOB-2026-10024 · Hanworth & Vale',
  meta: '308 waiting',
);
const FoEntityPickerOption _chino = FoEntityPickerOption(
  id: '10019',
  label: 'Slim Chino',
  supportingText: 'JOB-2026-10019 · Meridian Basics Co.',
  meta: 'Due in 7 days',
);
const FoEntityPickerOption _tee = FoEntityPickerOption(
  id: '10031',
  label: 'Heavyweight Crew Tee',
  supportingText: 'JOB-2026-10031 · Kestrel Outfitters',
  meta: '96 waiting',
);
const FoEntityPickerOption _oxford = FoEntityPickerOption(
  id: '10027',
  label: 'Oxford Button-Down',
  supportingText: 'JOB-2026-10027 · Nordstrom Apparel Group',
  meta: 'Due 21 Oct',
);

const List<FoLookupScope> _scopes = <FoLookupScope>[
  FoLookupScope(label: 'Running', count: 22),
  FoLookupScope(label: 'All orders', count: 25),
];

/// Opens the picker the way the PickerWeb and PickerPhone boards show it.
Future<void> _openPicker(
  WidgetTester tester, {
  Size size = _desktop,
  ThemeData? theme,
  List<String>? queries,
  List<int>? scopeChanges,
  void Function(FoEntityPickerOption? picked)? onPicked,
  List<FoLookupScope> scopes = _scopes,
}) async {
  await _pumpApp(
    tester,
    size: size,
    theme: theme,
    child: _opener((BuildContext context) async {
      final FoEntityPickerOption? picked = await FoLookupPicker.show(
        context,
        title: 'Choose an order',
        subtitle: 'For the new fabric receipt',
        copy: _copy,
        search: (String q) async {
          queries?.add(q);
          return q.isEmpty
              ? const <FoEntityPickerOption>[_polo, _chino, _tee, _oxford]
              : const <FoEntityPickerOption>[_oxford];
        },
        recent: const <FoEntityPickerOption>[_polo, _chino],
        likely: const <FoEntityPickerOption>[_tee],
        scopes: scopes,
        onScopeChanged: scopeChanges?.add,
        noneLabel: 'No filter: all orders',
        onScan: () async => null,
        totalLabel: (int shown, int? total) => total == null || shown >= total
            ? null
            : 'Showing the first $shown of $total. Keep typing to narrow it '
                'down.',
      );
      onPicked?.call(picked);
    }),
  );
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
}

FoSearchPaletteCopy _paletteCopy() => FoSearchPaletteCopy(
      fieldLabel: 'Search orders, entries, fabric and people',
      closeLabel: 'Close search',
      noResultsText: (String q) => 'Nothing matches "$q".',
      errorText: "Couldn't search. Check the connection.",
      retryLabel: 'Try again',
      moveHint: 'move',
      openHint: 'open',
      everythingLabel: 'Everything',
      typesLabel: 'Show',
    );

List<FoSearchGroup> _searchGroups(List<String> opened) => <FoSearchGroup>[
      FoSearchGroup(
        title: 'Orders',
        results: <FoSearchResult>[
          FoSearchResult(
            title: 'Heavyweight Crew Tee',
            subtitle: 'JOB-2026-10031 · Kestrel Outfitters',
            icon: Icons.inventory_2_outlined,
            onSelected: () => opened.add('order'),
          ),
        ],
      ),
      FoSearchGroup(
        title: 'Entries',
        qualifier: 'newest first',
        total: 24,
        results: <FoSearchResult>[
          FoSearchResult(
            title: 'PRS-00415 · Pressing',
            subtitle: 'Jet Black · 96 pieces · 1 Oct · Imran Sheikh',
            onSelected: () => opened.add('PRS-00415'),
          ),
          FoSearchResult(
            title: 'TCUT-00212 · Thread cutting',
            subtitle: 'Jet Black · 120 pieces · 1 Oct · Fatima Bano',
            onSelected: () => opened.add('TCUT-00212'),
          ),
        ],
        seeAllLabel: 'See all 24 entries for Crew Tee',
        onSeeAll: () => opened.add('see all'),
      ),
      FoSearchGroup(
        title: 'Fabric received',
        results: <FoSearchResult>[
          FoSearchResult(
            title: 'GRN-00034 · Single Jersey 180',
            onSelected: () => opened.add('GRN-00034'),
          ),
        ],
      ),
      const FoSearchGroup(
        title: 'People',
        results: <FoSearchResult>[],
        emptyText: 'Nobody called "crew".',
      ),
    ];

Future<void> _openPalette(
  WidgetTester tester, {
  Size size = _desktop,
  ThemeData? theme,
  List<String>? opened,
}) async {
  final List<String> log = opened ?? <String>[];
  await _pumpApp(
    tester,
    size: size,
    theme: theme,
    child: _opener(
      (BuildContext context) => FoSearchPalette.show(
        context,
        search: (String q) async => _searchGroups(log),
        copy: _paletteCopy(),
      ),
    ),
  );
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
  await tester.enterText(find.byType(TextField), 'crew');
  await tester.pump(FoMotion.searchDebounce);
  await tester.pumpAndSettle();
}

void main() {
  group('FoNavItem.number', () {
    testWidgets('a numbered item leads with its number, filled when current', (
      WidgetTester tester,
    ) async {
      await _pumpApp(
        tester,
        child: FoShellScaffold(
          groups: _shellGroups(),
          selectedItemId: 'Pressing',
          body: const SizedBox(),
        ),
      );

      // Nine stage discs, and no stage icon in their place.
      for (int n = 1; n <= 9; n++) {
        expect(_disc(n), findsOneWidget);
      }
      expect(find.byIcon(Icons.circle_outlined), findsNothing);
      expect(find.byIcon(Icons.circle), findsNothing);

      final BuildContext context = tester.element(find.text('Pressing'));
      final FoDisc current = tester.widget<FoDisc>(_disc(8));
      final FoDisc other = tester.widget<FoDisc>(_disc(1));
      expect(current.color, context.foColors.primary);
      expect(current.borderColor, isNull);
      expect(other.color, isNull);
      expect(other.borderColor, context.foColors.edgeStrong);
    });

    testWidgets('the sidebar shows a count as a pill at the end of the row', (
      WidgetTester tester,
    ) async {
      await _pumpApp(
        tester,
        child: FoShellScaffold(
          groups: _shellGroups(),
          selectedItemId: 'today',
          body: const SizedBox(),
        ),
      );

      expect(find.byType(FoBadge), findsOneWidget);
      expect(find.byType(Badge), findsNothing);
      expect(find.bySemanticsLabel('3 waiting for you'), findsOneWidget);
      expect(
        tester.getCenter(find.byType(FoBadge)).dx,
        greaterThan(tester.getCenter(find.text('Approvals')).dx),
      );
    });

    testWidgets(
        'the labelled rail numbers stages too, and keeps the count on '
        'the mark', (WidgetTester tester) async {
      await _pumpApp(
        tester,
        size: _tablet,
        child: FoShellScaffold(
          groups: _shellGroups(),
          selectedItemId: 'Cutting',
          railLabels: true,
          body: const SizedBox(),
        ),
      );

      expect(_disc(1), findsOneWidget);
      expect(find.byType(Badge), findsOneWidget);
      expect(find.byType(FoBadge), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a number disc stays a circle at 200% text', (
      WidgetTester tester,
    ) async {
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      for (final (Size size, bool rail) in <(Size, bool)>[
        (_desktop, false),
        (_tablet, true),
      ]) {
        await _pumpApp(
          tester,
          size: size,
          child: FoShellScaffold(
            groups: _shellGroups(),
            selectedItemId: 'Packing',
            railLabels: rail,
            body: const SizedBox(),
          ),
        );
        expect(tester.takeException(), isNull);
        for (final int n in <int>[1, 9]) {
          final Size disc = tester.getSize(
            find.descendant(of: _disc(n), matching: find.byType(SizedBox)),
          );
          expect(disc.width, disc.height, reason: 'disc $n, rail: $rail');
          expect(disc.width, FoTokens.iconMedium);
        }
      }
    });

    testWidgets('a nav sheet row carries the same number', (
      WidgetTester tester,
    ) async {
      await _pumpApp(
        tester,
        size: _phone,
        child: FoShellScaffold(
          destinations: <FoNavDestination>[
            FoNavDestination(
              label: 'Today',
              icon: Icons.home_outlined,
              selectedIcon: Icons.home,
              onSelected: () {},
            ),
            FoNavDestination(
              label: 'Stages',
              icon: Icons.view_list_outlined,
              selectedIcon: Icons.view_list,
              sheet: FoNavSheet(
                title: 'Production stages',
                emptyLabel: 'No stages for your role',
                actions: <FoNavAction>[
                  for (int i = 0; i < _stages.length; i++)
                    FoNavAction(
                      label: _stages[i],
                      icon: Icons.circle_outlined,
                      onTap: () {},
                      number: i + 1,
                    ),
                ],
              ),
            ),
          ],
          body: const SizedBox(),
        ),
      );

      await tester.tap(find.text('Stages'));
      await tester.pumpAndSettle();
      expect(_disc(1), findsOneWidget);
      expect(find.byIcon(Icons.circle_outlined), findsNothing);
    });
  });

  group('FoLookupPicker 0.7.1', () {
    testWidgets('recent, then likely, then the rest, each once', (
      WidgetTester tester,
    ) async {
      await _openPicker(tester);

      final double recent =
          tester.getTopLeft(find.text('YOU USED RECENTLY')).dy;
      final double likely =
          tester.getTopLeft(find.text('PIECES WAITING AT PRESSING')).dy;
      final double rest = tester
          .getTopLeft(find.text('ALL RUNNING ORDERS, DUE SOONEST FIRST'))
          .dy;
      expect(recent, lessThan(likely));
      expect(likely, lessThan(rest));
      expect(
        tester.getTopLeft(find.text('Heavyweight Crew Tee')).dy,
        allOf(greaterThan(likely), lessThan(rest)),
      );
      // The search answered all four; the two recent and the likely one are
      // not repeated under the rest.
      expect(find.text('Pique Polo'), findsOneWidget);
      expect(find.text('Heavyweight Crew Tee'), findsOneWidget);
      expect(find.text('Oxford Button-Down'), findsOneWidget);
      final Finder total = find
          .text('Showing the first 4 of 22. Keep typing to narrow it down.');
      await tester.scrollUntilVisible(
        total,
        100,
        scrollable: find.descendant(
          of: find.byType(ListView),
          matching: find.byType(Scrollable),
        ),
      );
      expect(total, findsOneWidget);
    });

    testWidgets('scopes stay in one row and switching one searches again', (
      WidgetTester tester,
    ) async {
      final List<String> queries = <String>[];
      final List<int> changes = <int>[];
      await _openPicker(
        tester,
        size: _phone,
        queries: queries,
        scopeChanges: changes,
        scopes: const <FoLookupScope>[
          FoLookupScope(label: 'Running', count: 22),
          FoLookupScope(label: 'All orders', count: 25),
          FoLookupScope(label: 'On hold', count: 1),
          FoLookupScope(label: 'Completed this month', count: 12),
          FoLookupScope(label: 'New and not yet cut', count: 2),
        ],
      );

      final double rowY = tester.getTopLeft(find.text('Running')).dy;
      // Scroll, not wrap: every chip on one line, the last past the edge.
      for (final String label in <String>['All orders', 'On hold']) {
        expect(tester.getTopLeft(find.text(label)).dy, rowY);
      }
      expect(
        find.ancestor(
          of: find.text('Running'),
          matching: find.byWidgetPredicate(
            (Widget w) =>
                w is SingleChildScrollView &&
                w.scrollDirection == Axis.horizontal,
          ),
        ),
        findsOneWidget,
      );
      expect(
        tester.getTopLeft(find.text('New and not yet cut')).dx,
        greaterThan(_phone.width),
      );

      await tester.enterText(find.byType(TextField), 'oxford');
      await tester.pump(FoMotion.searchDebounce);
      await tester.pumpAndSettle();
      await tester.tap(find.text('All orders'));
      await tester.pumpAndSettle();

      expect(changes, <int>[1]);
      expect(queries, <String>['', 'oxford', 'oxford']);
      expect(tester.takeException(), isNull);
    });

    testWidgets('"No filter" resolves with the none sentinel, not null', (
      WidgetTester tester,
    ) async {
      FoEntityPickerOption? picked;
      bool resolved = false;
      await _openPicker(
        tester,
        onPicked: (FoEntityPickerOption? o) {
          picked = o;
          resolved = true;
        },
      );
      await tester.tap(find.text('No filter: all orders'));
      await tester.pumpAndSettle();

      expect(resolved, isTrue);
      expect(picked, isNotNull);
      expect(picked!.isNone, isTrue);
      expect(identical(picked, FoLookupPicker.none), isTrue);
      expect(_polo.isNone, isFalse);
    });

    testWidgets('a field cleared by "No filter" reports null', (
      WidgetTester tester,
    ) async {
      final TextEditingController controller =
          TextEditingController(text: 'Pique Polo');
      addTearDown(controller.dispose);
      final List<FoEntityPickerOption?> reported = <FoEntityPickerOption?>[];
      await _pumpApp(
        tester,
        child: Center(
          child: SizedBox(
            width: 360,
            child: FoEntityPickerField(
              controller: controller,
              label: 'Order',
              selectedId: '10024',
              copy: _copy,
              search: (String q) async => const <FoEntityPickerOption>[_polo],
              onSelected: reported.add,
              noneLabel: 'No filter: all orders',
            ),
          ),
        ),
      );
      await tester.tap(find.byType(TextFormField));
      await tester.pumpAndSettle();
      await tester.tap(find.text('No filter: all orders'));
      await tester.pumpAndSettle();

      expect(reported, <FoEntityPickerOption?>[null]);
      expect(controller.text, isEmpty);
    });

    testWidgets('wide: the subtitle is the caption, keys move and choose', (
      WidgetTester tester,
    ) async {
      FoEntityPickerOption? picked;
      await _openPicker(tester, onPicked: (FoEntityPickerOption? o) {
        picked = o;
      });

      expect(find.text('FOR THE NEW FABRIC RECEIPT'), findsOneWidget);
      expect(find.text('Enter'), findsOneWidget);
      expect(find.text('choose'), findsOneWidget);
      expect(find.text('Esc'), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      // Recent are first: Pique Polo, then Slim Chino.
      expect(picked?.id, '10019');
    });

    testWidgets('phone: the subtitle is a line under the title, no key hints', (
      WidgetTester tester,
    ) async {
      await _openPicker(tester, size: _phone);

      expect(find.byType(Dialog), findsNothing);
      expect(find.text('For the new fabric receipt'), findsOneWidget);
      expect(
        tester.getTopLeft(find.text('For the new fabric receipt')).dy,
        greaterThan(tester.getTopLeft(find.text('Choose an order')).dy),
      );
      expect(find.text('Enter'), findsNothing);
      expect(find.text('No filter: all orders'), findsOneWidget);
    });

    for (final (String name, ThemeData Function() theme)
        in <(String, ThemeData Function())>[
      ('light', FoTheme.light),
      ('Graphite', () => FoTheme.dark(palette: FoDarkPalette.graphite)),
    ]) {
      for (final Size size in <Size>[_phone, _desktop]) {
        testWidgets('fits at ${size.width.toInt()}, $name', (
          WidgetTester tester,
        ) async {
          await _openPicker(tester, size: size, theme: theme());
          expect(tester.takeException(), isNull);
        });
      }
    }

    testWidgets('fits at 390 with 200% text', (WidgetTester tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await _openPicker(tester, size: _phone);
      expect(tester.takeException(), isNull);
      // The phone's scan button is a named glyph, not a labelled button.
      expect(find.bySemanticsLabel('Scan job card'), findsOneWidget);
    });
  });

  group('FoSearchPalette type tabs', () {
    testWidgets('tabs count each group and filter the results in place', (
      WidgetTester tester,
    ) async {
      final List<String> opened = <String>[];
      await _openPalette(tester, opened: opened);

      // Everything is the groups' totals: 1 + 24 + 1 + 0.
      expect(find.bySemanticsLabel('Everything, 26'), findsOneWidget);
      expect(find.bySemanticsLabel('Entries, 24'), findsOneWidget);
      expect(find.bySemanticsLabel('People, 0'), findsOneWidget);
      expect(find.text('ORDERS'), findsOneWidget);
      expect(find.text('FABRIC RECEIVED'), findsOneWidget);

      await tester.tap(find.bySemanticsLabel('Entries, 24'));
      await tester.pumpAndSettle();
      expect(find.text('ORDERS'), findsNothing);
      expect(find.text('FABRIC RECEIVED'), findsNothing);
      expect(find.text('ENTRIES · NEWEST FIRST'), findsOneWidget);

      // The keys walk only what the tab lets through.
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(opened, <String>['PRS-00415']);
    });

    testWidgets('Everything brings every group back', (
      WidgetTester tester,
    ) async {
      await _openPalette(tester, size: _phone);
      await tester.ensureVisible(find.bySemanticsLabel('Fabric received, 1'));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Fabric received, 1'));
      await tester.pumpAndSettle();
      expect(find.text('ORDERS'), findsNothing);

      await tester.ensureVisible(find.bySemanticsLabel('Everything, 26'));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Everything, 26'));
      await tester.pumpAndSettle();
      expect(find.text('ORDERS'), findsOneWidget);
      expect(find.text('FABRIC RECEIVED'), findsOneWidget);
    });

    testWidgets('fits at 390 with 200% text', (WidgetTester tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await _openPalette(tester, size: _phone);
      expect(find.byType(FoStatusTabs), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('no tabs without everythingLabel', (WidgetTester tester) async {
      await _pumpApp(
        tester,
        child: _opener(
          (BuildContext context) => FoSearchPalette.show(
            context,
            search: (String q) async => _searchGroups(<String>[]),
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
      expect(find.byType(FoStatusTabs), findsNothing);
    });

    for (final (String name, ThemeData Function() theme)
        in <(String, ThemeData Function())>[
      ('light', FoTheme.light),
      ('Graphite', () => FoTheme.dark(palette: FoDarkPalette.graphite)),
    ]) {
      for (final Size size in <Size>[_phone, _desktop]) {
        testWidgets('fits at ${size.width.toInt()}, $name', (
          WidgetTester tester,
        ) async {
          await _openPalette(tester, size: size, theme: theme());
          expect(find.byType(FoStatusTabs), findsOneWidget);
          expect(tester.takeException(), isNull);
        });
      }
    }
  });
}

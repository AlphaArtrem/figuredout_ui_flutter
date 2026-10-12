import 'package:figuredout_ui/figuredout_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/pump.dart';

/// What a screen reader is handed for the shell: each destination a named
/// button that says whether it is the current one, inside a navigation
/// container. Reported by Luxe (P4-3 / P4b-2) against the expanded sidebar.

const Size _expanded = Size(1280, 900);
const Size _medium = Size(760, 900);
const Size _compact = Size(400, 800);

Widget _shell({bool railLabels = false}) => FoShellScaffold(
      navigationSemanticLabel: 'Main navigation',
      railLabels: railLabels,
      groups: <FoNavGroup>[
        FoNavGroup(
          items: <FoNavItem>[
            FoNavItem(
              id: 'dashboard',
              label: 'Dashboard',
              icon: Icons.dashboard_outlined,
              selectedIcon: Icons.dashboard,
              onSelected: () {},
              badgeCount: 3,
              badgeSemanticLabel: '3 open alerts',
            ),
            FoNavItem(
              id: 'orders',
              label: 'Orders',
              icon: Icons.receipt_long_outlined,
              selectedIcon: Icons.receipt_long,
              onSelected: () {},
              number: 2,
            ),
          ],
        ),
      ],
      selectedItemId: 'dashboard',
      footer: FoNavAction(label: 'Sign out', icon: Icons.logout, onTap: () {}),
      destinations: <FoNavDestination>[
        FoNavDestination(
          label: 'Home',
          icon: Icons.home_outlined,
          selectedIcon: Icons.home,
          onSelected: () {},
        ),
        FoNavDestination(
          label: 'More',
          icon: Icons.more_horiz,
          selectedIcon: Icons.more_horiz,
          onSelected: () {},
        ),
      ],
      body: const SizedBox(),
    );

/// The `Semantics` the shell wraps a destination in, found by its name.
Finder _destination(String label) => find.byWidgetPredicate(
      (Widget w) =>
          w is Semantics &&
          w.properties.label == label &&
          w.properties.button == true,
    );

Future<void> _pump(
  WidgetTester tester,
  Size size, {
  bool railLabels = false,
}) =>
    pumpFo(tester, surfaceSize: size, child: _shell(railLabels: railLabels));

void _expectNamedButton(
  WidgetTester tester,
  String label, {
  required bool selected,
}) {
  expect(
    tester.getSemantics(_destination(label)),
    isSemantics(
      label: label,
      isButton: true,
      hasTapAction: true,
      isFocusable: true,
      hasSelectedState: true,
      isSelected: selected,
    ),
  );
}

void main() {
  group('FoShellScaffold semantics', () {
    testWidgets('the sidebar: buttons with names, the current one selected', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await _pump(tester, _expanded);

      _expectNamedButton(tester, 'Dashboard', selected: true);
      _expectNamedButton(tester, 'Orders', selected: false);
      // The footer is a button too, and never the current one.
      _expectNamedButton(tester, 'Sign out', selected: false);
      handle.dispose();
    });

    testWidgets('the sidebar is a named navigation container', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await _pump(tester, _expanded);

      final Finder region = find.byWidgetPredicate(
        (Widget w) =>
            w is Semantics &&
            w.properties.label == 'Main navigation' &&
            w.container,
      );
      expect(region, findsOneWidget);
      // explicitChildNodes keeps the items as nodes of their own, so the
      // region does not read as one run of text.
      expect(tester.widget<Semantics>(region).explicitChildNodes, isTrue);
      expect(
        tester.getSemantics(region),
        isSemantics(label: 'Main navigation'),
      );
      expect(
        find.semantics.byLabel('Dashboard'),
        findsOneWidget,
        reason: 'the item is its own node, not merged into the region',
      );
      handle.dispose();
    });

    testWidgets('a count keeps its own announcement beside the name', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await _pump(tester, _expanded);

      expect(find.bySemanticsLabel('3 open alerts'), findsOneWidget);
      // The number disc says a position, not a name: the item is read as
      // "Orders", never "2 Orders".
      _expectNamedButton(tester, 'Orders', selected: false);
      handle.dispose();
    });

    testWidgets('the collapsed rail still names its buttons', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await _pump(tester, _medium);

      // No text is drawn on the rail; the name comes from the label, and the
      // tooltip remains a hint for a pointer.
      expect(find.text('Orders'), findsNothing);
      _expectNamedButton(tester, 'Dashboard', selected: true);
      _expectNamedButton(tester, 'Orders', selected: false);
      _expectNamedButton(tester, 'Sign out', selected: false);
      expect(
        tester.widget<Semantics>(_destination('Orders')).properties.label,
        'Orders',
      );
      expect(find.byType(Tooltip), findsWidgets);
      expect(
        find.byWidgetPredicate(
          (Widget w) =>
              w is Semantics &&
              w.properties.label == 'Main navigation' &&
              w.explicitChildNodes,
        ),
        findsOneWidget,
      );
      handle.dispose();
    });

    testWidgets('the labelled rail is the same button, not a lesser one', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await _pump(tester, _medium, railLabels: true);

      expect(find.text('Orders'), findsOneWidget);
      _expectNamedButton(tester, 'Dashboard', selected: true);
      _expectNamedButton(tester, 'Orders', selected: false);
      handle.dispose();
    });

    testWidgets('the bottom bar: selected buttons in a named container', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await _pump(tester, _compact);

      expect(
        tester.getSemantics(find.text('Home')),
        isSemantics(
          label: 'Home\nTab 1 of 2',
          isButton: true,
          hasTapAction: true,
          isFocusable: true,
          hasSelectedState: true,
          isSelected: true,
        ),
      );
      expect(
        tester.getSemantics(find.text('More')),
        isSemantics(
          label: 'More\nTab 2 of 2',
          isButton: true,
          hasTapAction: true,
          isFocusable: true,
          hasSelectedState: true,
          isSelected: false,
        ),
      );
      expect(
        find.byWidgetPredicate(
          (Widget w) =>
              w is Semantics &&
              w.properties.label == 'Main navigation' &&
              w.explicitChildNodes,
        ),
        findsOneWidget,
      );
      handle.dispose();
    });

    testWidgets('without a label the container is unnamed, not absent', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pumpFo(
        tester,
        surfaceSize: _expanded,
        child: FoShellScaffold(
          groups: <FoNavGroup>[
            FoNavGroup(
              items: <FoNavItem>[
                FoNavItem(
                  id: 'a',
                  label: 'Alpha',
                  icon: Icons.circle_outlined,
                  selectedIcon: Icons.circle,
                  onSelected: () {},
                ),
              ],
            ),
          ],
          selectedItemId: 'a',
          body: const SizedBox(),
        ),
      );

      expect(
        tester.getSemantics(_destination('Alpha')),
        isSemantics(label: 'Alpha', isButton: true, isSelected: true),
      );
      handle.dispose();
    });
  });

  group('shell top bar semantics', () {
    testWidgets('the account menu is a button named for the person', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pumpFo(
        tester,
        child: FoAccountMenuButton(
          userName: 'Yash',
          items: <FoAccountMenuItem>[
            FoAccountMenuItem(
              label: 'Sign out',
              icon: Icons.logout,
              onSelected: () {},
            ),
          ],
        ),
      );

      expect(
        tester.getSemantics(find.byType(IconButton)),
        isSemantics(label: 'Yash', isButton: true, hasTapAction: true),
      );
      // The drawn initial is decoration; it is not the name.
      expect(find.bySemanticsLabel('Y'), findsNothing);
      handle.dispose();
    });

    testWidgets('the title is a header and the actions are named buttons', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(
        MaterialApp(
          theme: FoTheme.light(),
          home: Scaffold(
            appBar: FoShellAppBar(
              title: 'Luxe',
              actions: <Widget>[
                IconButton(
                  icon: const Icon(Icons.sync),
                  tooltip: 'Sync',
                  onPressed: () {},
                ),
              ],
              accountMenu: FoAccountMenuButton(
                userName: 'Yash',
                items: <FoAccountMenuItem>[
                  FoAccountMenuItem(
                    label: 'Sign out',
                    icon: Icons.logout,
                    onSelected: () {},
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      expect(
        tester.getSemantics(find.text('Luxe')),
        isSemantics(label: 'Luxe', isHeader: true),
      );
      expect(
        tester.getSemantics(find.byIcon(Icons.sync)),
        isSemantics(isButton: true, hasTapAction: true, tooltip: 'Sync'),
      );
      handle.dispose();
    });
  });
}

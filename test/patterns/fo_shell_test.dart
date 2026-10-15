import 'package:figuredout_ui/figuredout_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/pump.dart';

List<FoNavGroup> _groups(void Function(String id) onSelect) => <FoNavGroup>[
      FoNavGroup(
        items: <FoNavItem>[
          FoNavItem(
            id: 'dashboard',
            label: 'Dashboard',
            icon: Icons.dashboard_outlined,
            selectedIcon: Icons.dashboard,
            onSelected: () => onSelect('dashboard'),
            badgeCount: 3,
            badgeSemanticLabel: '3 open alerts',
          ),
        ],
      ),
      FoNavGroup(
        label: 'Production',
        items: <FoNavItem>[
          FoNavItem(
            id: 'orders',
            label: 'Orders',
            icon: Icons.receipt_long_outlined,
            selectedIcon: Icons.receipt_long,
            onSelected: () => onSelect('orders'),
          ),
        ],
      ),
    ];

void main() {
  group('FoShellScaffold', () {
    testWidgets('is a sidebar, a rail and a bottom bar at the three bands', (
      WidgetTester tester,
    ) async {
      Future<void> pumpAt(Size size) => pumpFo(
            tester,
            surfaceSize: size,
            child: FoShellScaffold(
              groups: _groups((String _) {}),
              selectedItemId: 'dashboard',
              destinations: <FoNavDestination>[
                FoNavDestination(
                  label: 'Dashboard',
                  icon: Icons.dashboard_outlined,
                  selectedIcon: Icons.dashboard,
                  onSelected: () {},
                ),
                FoNavDestination(
                  label: 'More',
                  icon: Icons.more_horiz_outlined,
                  selectedIcon: Icons.more_horiz,
                  onSelected: () {},
                ),
              ],
              body: const SizedBox(),
            ),
          );

      await pumpAt(const Size(1280, 900));
      expect(find.byType(NavigationBar), findsNothing);
      // Labels and group headings, because there is room for them.
      expect(find.text('Orders'), findsOneWidget);
      expect(find.text('PRODUCTION'), findsOneWidget);

      await pumpAt(const Size(760, 900));
      expect(find.byType(NavigationBar), findsNothing);
      // The rail drops the labels and the headings; the label survives as the
      // tooltip, which is the only way to read it there.
      expect(find.text('Orders'), findsNothing);
      expect(find.text('PRODUCTION'), findsNothing);
      expect(
        tester.widget<Tooltip>(find.byType(Tooltip).first).message,
        'Dashboard',
      );

      await pumpAt(const Size(420, 900));
      expect(find.byType(NavigationBar), findsOneWidget);
    });

    testWidgets('a sidebar destination reports its own id', (
      WidgetTester tester,
    ) async {
      String? selected;
      await pumpFo(
        tester,
        surfaceSize: const Size(1280, 900),
        child: FoShellScaffold(
          groups: _groups((String id) => selected = id),
          selectedItemId: 'dashboard',
          body: const SizedBox(),
        ),
      );

      await tester.tap(find.text('Orders'));
      expect(selected, 'orders');
    });

    testWidgets('a badge count announces what it counts', (
      WidgetTester tester,
    ) async {
      await pumpFo(
        tester,
        surfaceSize: const Size(1280, 900),
        child: FoShellScaffold(
          groups: _groups((String _) {}),
          selectedItemId: 'dashboard',
          body: const SizedBox(),
        ),
      );

      // A bare number on an icon tells a screen reader nothing about its
      // subject.
      expect(find.bySemanticsLabel('3 open alerts'), findsOneWidget);
    });

    testWidgets('a compact destination can raise a sheet instead of moving', (
      WidgetTester tester,
    ) async {
      String? tapped;
      await pumpFo(
        tester,
        surfaceSize: const Size(420, 900),
        child: FoShellScaffold(
          destinations: <FoNavDestination>[
            FoNavDestination(
              label: 'Dashboard',
              icon: Icons.dashboard_outlined,
              selectedIcon: Icons.dashboard,
              onSelected: () => tapped = 'dashboard',
            ),
            FoNavDestination(
              label: 'Worklists',
              icon: Icons.view_list_outlined,
              selectedIcon: Icons.view_list,
              sheet: FoNavSheet(
                title: 'Worklists',
                emptyLabel: 'No destinations available',
                actions: <FoNavAction>[
                  FoNavAction(
                    label: 'Orders',
                    icon: Icons.receipt_long_outlined,
                    onTap: () => tapped = 'orders',
                  ),
                ],
              ),
            ),
          ],
          body: const SizedBox(),
        ),
      );

      await tester.tap(find.text('Worklists'));
      await tester.pumpAndSettle();
      expect(find.text('Orders'), findsOneWidget);

      await tester.tap(find.text('Orders'));
      await tester.pumpAndSettle();
      expect(tapped, 'orders');
      // The sheet closes before the action runs, so the page it navigated to
      // is not left underneath a sheet the user has to dismiss.
      expect(find.byType(BottomSheet), findsNothing);
    });

    testWidgets('an empty sheet says so rather than opening blank', (
      WidgetTester tester,
    ) async {
      await pumpFo(
        tester,
        surfaceSize: const Size(420, 900),
        child: FoShellScaffold(
          destinations: <FoNavDestination>[
            FoNavDestination(
              label: 'Dashboard',
              icon: Icons.dashboard_outlined,
              selectedIcon: Icons.dashboard,
              onSelected: () {},
            ),
            const FoNavDestination(
              label: 'More',
              icon: Icons.more_horiz_outlined,
              selectedIcon: Icons.more_horiz,
              // Every member behind a permission this user does not have —
              // which happens for real, and reads as a bug without a word.
              sheet: FoNavSheet(
                title: 'More',
                emptyLabel: 'No destinations available',
                actions: <FoNavAction>[],
              ),
            ),
          ],
          body: const SizedBox(),
        ),
      );

      await tester.tap(find.text('More'));
      await tester.pumpAndSettle();
      expect(find.text('No destinations available'), findsOneWidget);
    });

    testWidgets('a destination that both navigates and opens a sheet is a bug',
        (WidgetTester tester) async {
      expect(
        () => FoNavDestination(
          label: 'Both',
          icon: Icons.abc,
          selectedIcon: Icons.abc,
          onSelected: () {},
          sheet: const FoNavSheet(
            title: 'Both',
            emptyLabel: 'Nothing',
            actions: <FoNavAction>[],
          ),
        ),
        throwsAssertionError,
      );
    });

    testWidgets('the footer sits below the destinations and fires', (
      WidgetTester tester,
    ) async {
      int cycles = 0;
      await pumpFo(
        tester,
        surfaceSize: const Size(1280, 900),
        child: FoShellScaffold(
          groups: _groups((String _) {}),
          selectedItemId: 'dashboard',
          footer: FoNavAction(
            label: 'Auto',
            icon: Icons.brightness_auto_outlined,
            onTap: () => cycles++,
          ),
          body: const SizedBox(),
        ),
      );

      final double footerY = tester.getTopLeft(find.text('Auto')).dy;
      final double lastItemY = tester.getTopLeft(find.text('Orders')).dy;
      expect(footerY, greaterThan(lastItemY));

      await tester.tap(find.text('Auto'));
      expect(cycles, 1);
    });
  });

  // F51 in Luxe: thirteen-plus destinations do not fit a short window, the
  // list scrolled, and nothing said so — the scrollbar of a desktop browser is
  // hidden until the pointer is over it, and the last rows were just cut off.
  group('FoShellScaffold sidebar overflow', () {
    Future<List<String>> pumpWith(
      WidgetTester tester,
      int count,
      Size size, {
      Widget body = const SizedBox(),
    }) async {
      final List<String> selected = <String>[];
      await pumpFo(
        tester,
        surfaceSize: size,
        child: FoShellScaffold(
          groups: <FoNavGroup>[
            FoNavGroup(
              items: <FoNavItem>[
                for (int i = 0; i < count; i++)
                  FoNavItem(
                    id: 'item-$i',
                    label: 'Destination $i',
                    icon: Icons.circle_outlined,
                    selectedIcon: Icons.circle,
                    onSelected: () => selected.add('item-$i'),
                  ),
              ],
            ),
          ],
          selectedItemId: 'item-0',
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
          body: body,
        ),
      );
      await tester.pump();
      return selected;
    }

    Finder fade() => find.byWidgetPredicate(
          (Widget w) =>
              w is DecoratedBox &&
              w.decoration is BoxDecoration &&
              (w.decoration as BoxDecoration).gradient != null,
        );

    testWidgets(
      'with more destinations than fit, the scrollbar stays visible and the '
      'bottom edge fades until the end is reached',
      (WidgetTester tester) async {
        final List<String> selected =
            await pumpWith(tester, 20, const Size(1440, 720));

        expect(tester.widget<Scrollbar>(find.byType(Scrollbar)).thumbVisibility,
            isTrue,
            reason: 'a hidden-until-hover scrollbar says nothing is below');
        expect(fade(), findsOneWidget);

        // The last destination is reachable by scrolling and can be chosen.
        await tester.scrollUntilVisible(
          find.text('Destination 19'),
          100,
          scrollable: find.descendant(
            of: find.byType(Scrollbar),
            matching: find.byType(Scrollable),
          ),
        );
        await tester.pump();
        await tester.tap(find.text('Destination 19'));
        expect(selected, <String>['item-19']);

        // At the end there is nothing more below, so no fade.
        expect(fade(), findsNothing);
      },
    );

    testWidgets(
      'the page body is the primary scroll; the sidebar has its own controller',
      (WidgetTester tester) async {
        const Key bodyKey = Key('page-body');
        await pumpWith(
          tester,
          20,
          const Size(1440, 720),
          body: ListView(
            key: bodyKey,
            primary: true,
            children: <Widget>[
              for (int i = 0; i < 60; i++)
                SizedBox(height: 50, child: Text('$i')),
            ],
          ),
        );

        final ScrollController primary = PrimaryScrollController.of(
          tester.element(find.byKey(bodyKey)),
        );
        expect(primary.positions, hasLength(1));
        expect(
          find.descendant(
            of: find.byKey(bodyKey),
            matching: find.byType(Scrollable),
          ),
          findsOneWidget,
        );
        expect(
          primary.position.context.storageContext,
          tester.element(
            find.descendant(
              of: find.byKey(bodyKey),
              matching: find.byType(Scrollable),
            ),
          ),
        );

        // The sidebar still scrolls, with its own scrollbar controller.
        final Scrollbar bar = tester.widget<Scrollbar>(find.byType(Scrollbar));
        expect(bar.controller, isNotNull);
        expect(bar.controller, isNot(same(primary)));
        expect(bar.controller!.positions, hasLength(1));
        await tester.drag(find.text('Destination 5'), const Offset(0, -300));
        await tester.pump();
        expect(bar.controller!.offset, greaterThan(0));
        expect(primary.offset, 0);
      },
    );

    testWidgets('with few destinations there is no scrollbar and no fade', (
      WidgetTester tester,
    ) async {
      await pumpWith(tester, 5, const Size(1440, 720));

      expect(
        tester.widget<Scrollbar>(find.byType(Scrollbar)).thumbVisibility,
        isNot(isTrue),
      );
      expect(fade(), findsNothing);
    });

    testWidgets('the icon rail has the same cue; the bottom bar has no list', (
      WidgetTester tester,
    ) async {
      await pumpWith(tester, 20, const Size(760, 720));
      expect(tester.takeException(), isNull);
      expect(
        tester.widget<Scrollbar>(find.byType(Scrollbar)).thumbVisibility,
        isTrue,
      );
      expect(fade(), findsOneWidget);

      await pumpWith(tester, 20, const Size(400, 800));
      expect(tester.takeException(), isNull);
      expect(find.byType(Scrollbar), findsNothing);
      expect(fade(), findsNothing);
    });
  });

  group('FoAccountMenuButton', () {
    testWidgets('renders nothing until somebody is signed in', (
      WidgetTester tester,
    ) async {
      await pumpFo(
        tester,
        child: FoAccountMenuButton(
          userName: null, // ignore: avoid_redundant_argument_values
          items: <FoAccountMenuItem>[
            FoAccountMenuItem(
              label: 'Sign out',
              icon: Icons.logout,
              onSelected: () {},
            ),
          ],
        ),
      );

      // Session restore resolves after the first frame, so the signed-out
      // state is the one every shell renders first.
      expect(find.byType(PopupMenuButton<FoAccountMenuItem>), findsNothing);
    });

    testWidgets('the avatar carries the initial and the menu the actions', (
      WidgetTester tester,
    ) async {
      String? chose;
      await pumpFo(
        tester,
        child: FoAccountMenuButton(
          userName: 'priya nair',
          items: <FoAccountMenuItem>[
            FoAccountMenuItem(
              label: 'Sign out',
              icon: Icons.logout,
              onSelected: () => chose = 'sign out',
            ),
          ],
        ),
      );

      expect(find.text('P'), findsOneWidget);

      await tester.tap(find.byType(PopupMenuButton<FoAccountMenuItem>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sign out'));
      await tester.pumpAndSettle();

      expect(chose, 'sign out');
    });
  });

  group('FoShellAppBar', () {
    testWidgets('pins the account menu last, after the app\'s own actions', (
      WidgetTester tester,
    ) async {
      await pumpFo(
        tester,
        surfaceSize: const Size(900, 700),
        child: Scaffold(
          appBar: FoShellAppBar(
            title: 'Luxe',
            actions: const <Widget>[Icon(Icons.help_outline)],
            accountMenu: FoAccountMenuButton(
              userName: 'Priya',
              items: <FoAccountMenuItem>[
                FoAccountMenuItem(
                  label: 'Sign out',
                  icon: Icons.logout,
                  onSelected: () {},
                ),
              ],
            ),
          ),
          body: const SizedBox(),
        ),
      );

      expect(find.text('Luxe'), findsOneWidget);
      // The same corner on every screen, whatever else the app puts up there.
      expect(
        tester.getCenter(find.byType(CircleAvatar)).dx,
        greaterThan(tester.getCenter(find.byIcon(Icons.help_outline)).dx),
      );
    });

    testWidgets('status sits beside the title, not among the actions', (
      WidgetTester tester,
    ) async {
      await pumpFo(
        tester,
        surfaceSize: const Size(900, 700),
        child: const Scaffold(
          appBar: FoShellAppBar(
            title: 'Luxe',
            status: Chip(label: Text('Offline')),
          ),
          body: SizedBox(),
        ),
      );

      expect(find.text('Luxe'), findsOneWidget);
      expect(find.text('Offline'), findsOneWidget);
      // Beside, not instead of: the title survives status being present.
      expect(
        tester.getCenter(find.text('Offline')).dx,
        greaterThan(tester.getCenter(find.text('Luxe')).dx),
      );
    });
  });
}

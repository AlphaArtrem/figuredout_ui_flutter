import 'package:figuredout_ui/figuredout_ui.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

/// The shell in all three of its layouts.
///
/// Resize with the viewport addon: expanded gets the labelled sidebar, medium
/// the icon-only rail, and compact the bottom bar. One navigation model feeds
/// all three — the point of the component, and the thing an app that builds
/// its phone navigation separately from its desktop navigation loses.
class Shells extends StatefulWidget {
  /// Creates the example.
  const Shells({super.key});

  @override
  State<Shells> createState() => _ShellsState();
}

class _ShellsState extends State<Shells> {
  String _selectedId = 'pressing';

  static const List<(String, String)> _stages = <(String, String)>[
    ('cutting', 'Cutting'),
    ('loading', 'Line loading'),
    ('midline', 'Midline'),
    ('output', 'Output'),
    ('qc', 'QC'),
    ('bartek', 'Bartek'),
    ('thread', 'Thread cutting'),
    ('pressing', 'Pressing'),
    ('packing', 'Packing'),
  ];
  int _selectedIndex = 0;
  String _lastAction = '—';
  ThemeMode _mode = ThemeMode.system;

  void _go(String id) => setState(() {
        _selectedId = id;
        _lastAction = id;
      });

  List<FoNavGroup> get _groups => <FoNavGroup>[
        FoNavGroup(
          items: <FoNavItem>[
            FoNavItem(
              id: 'dashboard',
              label: 'Dashboard',
              icon: Icons.dashboard_outlined,
              selectedIcon: Icons.dashboard,
              onSelected: () => _go('dashboard'),
              badgeCount: 3,
              badgeSemanticLabel: '3 open alerts',
            ),
          ],
        ),
        FoNavGroup(
          items: <FoNavItem>[
            FoNavItem(
              id: 'orders',
              label: 'Orders',
              icon: Icons.receipt_long_outlined,
              selectedIcon: Icons.receipt_long,
              onSelected: () => _go('orders'),
            ),
            FoNavItem(
              id: 'approvals',
              label: 'Approvals',
              icon: Icons.fact_check_outlined,
              selectedIcon: Icons.fact_check,
              onSelected: () => _go('approvals'),
              // A pill at the end of the sidebar row; on the rail, a count
              // on the icon.
              badgeCount: 3,
              badgeSemanticLabel: '3 waiting for you',
            ),
          ],
        ),
        FoNavGroup(
          label: 'Production stages',
          items: <FoNavItem>[
            // Numbered: the stages are an order, so each leads with its
            // place in it rather than a picture.
            for (int i = 0; i < _stages.length; i++)
              FoNavItem(
                id: _stages[i].$1,
                label: _stages[i].$2,
                icon: Icons.circle_outlined,
                selectedIcon: Icons.circle,
                onSelected: () => _go(_stages[i].$1),
                number: i + 1,
              ),
          ],
        ),
        FoNavGroup(
          label: 'Admin',
          items: <FoNavItem>[
            FoNavItem(
              id: 'users',
              label: 'Users',
              icon: Icons.people_outline,
              selectedIcon: Icons.people,
              onSelected: () => _go('users'),
            ),
          ],
        ),
      ];

  List<FoNavDestination> get _destinations => <FoNavDestination>[
        FoNavDestination(
          label: 'Dashboard',
          icon: Icons.dashboard_outlined,
          selectedIcon: Icons.dashboard,
          onSelected: () => setState(() {
            _selectedIndex = 0;
            _lastAction = 'dashboard';
          }),
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
                  label: _stages[i].$2,
                  icon: Icons.circle_outlined,
                  onTap: () => _go(_stages[i].$1),
                  number: i + 1,
                ),
            ],
          ),
        ),
        const FoNavDestination(
          label: 'More',
          icon: Icons.more_horiz_outlined,
          selectedIcon: Icons.more_horiz,
          // A group whose every member is behind a permission this user does
          // not have. The empty label is why that does not read as a bug.
          sheet: FoNavSheet(
            title: 'More',
            emptyLabel: 'No destinations available',
            actions: <FoNavAction>[],
          ),
        ),
      ];

  @override
  Widget build(BuildContext context) {
    return FoShellScaffold(
      groups: _groups,
      selectedItemId: _selectedId,
      destinations: _destinations,
      selectedDestinationIndex: _selectedIndex,
      footer: FoNavAction(
        label: switch (_mode) {
          ThemeMode.light => 'Light',
          ThemeMode.dark => 'Dark',
          ThemeMode.system => 'Auto',
        },
        icon: switch (_mode) {
          ThemeMode.light => Icons.light_mode_outlined,
          ThemeMode.dark => Icons.dark_mode_outlined,
          ThemeMode.system => Icons.brightness_auto_outlined,
        },
        onTap: () => setState(() {
          _mode = ThemeMode.values[(_mode.index + 1) % ThemeMode.values.length];
        }),
      ),
      body: FoScaffold(
        title: 'Pressing',
        actions: <Widget>[
          FoAccountMenuButton(
            userName: 'Priya Nair',
            items: <FoAccountMenuItem>[
              FoAccountMenuItem(
                label: 'Sign out',
                icon: Icons.logout,
                onSelected: () => setState(() => _lastAction = 'sign out'),
              ),
            ],
          ),
        ],
        body: Padding(
          padding: EdgeInsets.all(context.foSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('Last selection', style: context.foText.caption),
              SizedBox(height: context.foSpacing.xs),
              Text(_lastAction, style: context.foText.title),
            ],
          ),
        ),
      ),
    );
  }
}

/// The shell: sidebar, rail and bottom bar from one model.
@widgetbook.UseCase(
  name: 'Shell scaffold',
  type: FoShellScaffold,
  path: '03 Patterns',
)
Widget buildShells(BuildContext context) => const Shells();

/// The application app bar with its account menu.
@widgetbook.UseCase(
  name: 'Shell app bar',
  type: FoShellAppBar,
  path: '03 Patterns',
)
Widget buildShellAppBar(BuildContext context) => Scaffold(
      appBar: FoShellAppBar(
        title: 'Luxe',
        // Ambient state for the app as a whole — a sync indicator, an
        // environment tag — sits beside the title rather than among the
        // actions on the right.
        status: Chip(
          label: const Text('Offline'),
          visualDensity: VisualDensity.compact,
          backgroundColor: context.foColors.warningSoft,
        ),
        accountMenu: const FoAccountMenuButton(
          userName: 'Priya Nair',
          items: <FoAccountMenuItem>[
            FoAccountMenuItem(
              label: 'Sign out',
              icon: Icons.logout,
              onSelected: _noop,
            ),
          ],
        ),
      ),
      body: Center(
        child: Text(
          'The shell app bar titles the application. FoAppBar titles a page.',
          textAlign: TextAlign.center,
          style: context.foText.body,
        ),
      ),
    );

void _noop() {}

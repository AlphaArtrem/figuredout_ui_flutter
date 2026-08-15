import 'package:flutter/material.dart';

import '../primitives/fo_focus_ring.dart';
import '../theme/fo_context.dart';
import '../theme/fo_window_class.dart';
import '../tokens/fo_layout.dart';

/// One destination in the shell's sidebar.
///
/// The item carries no route and no permission. Which destinations exist, and
/// which of them this user may see, is the app's business — so the app filters
/// the list and hands over what is left, and [onSelected] does whatever
/// navigation the app does. A design system that knew about routes would have
/// to know about one app's router.
@immutable
class FoNavItem {
  /// Creates a sidebar destination.
  const FoNavItem({
    required this.id,
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.onSelected,
    this.badgeCount,
    this.badgeSemanticLabel,
  });

  /// Identifies the item, and is what [FoShellScaffold.selectedItemId] is
  /// matched against.
  final String id;

  /// The destination's name. Caller-supplied, so it can be localized. It is
  /// also the rail's tooltip, which is the only way to read it there.
  final String label;

  /// The resting icon.
  final IconData icon;

  /// The icon while this destination is the current one.
  final IconData selectedIcon;

  /// Navigates.
  final VoidCallback onSelected;

  /// A count on the icon — unread alerts, pending approvals. Zero and null
  /// both mean no badge.
  final int? badgeCount;

  /// What the count means: "3 unread alerts". Without it a screen reader
  /// announces a bare number with nothing attaching it to its subject.
  final String? badgeSemanticLabel;
}

/// A labelled group of sidebar destinations.
@immutable
class FoNavGroup {
  /// Creates a group.
  const FoNavGroup({required this.items, this.label});

  /// The group's heading. Caller-supplied, so it can be localized. Null for a
  /// group that needs no heading — the one destination above the rest.
  ///
  /// Not rendered on the collapsed rail, which has no room for it.
  final String? label;

  /// The group's destinations, in order.
  final List<FoNavItem> items;
}

/// A leaf action in the shell: a row in a nav sheet, or the sidebar's footer.
@immutable
class FoNavAction {
  /// Creates an action.
  const FoNavAction({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  /// What it does. Caller-supplied, so it can be localized.
  final String label;

  /// Its icon.
  final IconData icon;

  /// Performs it.
  final VoidCallback onTap;
}

/// A sheet of actions raised by a compact destination.
///
/// The compact band has five slots and an app has more than five places to
/// be, so a slot can stand for a group instead of a page. The sheet is how
/// that group is reached.
@immutable
class FoNavSheet {
  /// Creates a sheet.
  const FoNavSheet({
    required this.title,
    required this.actions,
    required this.emptyLabel,
  });

  /// The sheet's heading. Caller-supplied, so it can be localized.
  final String title;

  /// The rows.
  final List<FoNavAction> actions;

  /// What to say when [actions] is empty — which happens for real, when a
  /// user's permissions leave a whole group with nothing in it. An empty
  /// sheet with no explanation reads as a bug.
  final String emptyLabel;
}

/// One slot in the compact bottom bar.
@immutable
class FoNavDestination {
  /// Creates a bottom-bar slot. Pass exactly one of [onSelected] and [sheet].
  const FoNavDestination({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    this.onSelected,
    this.sheet,
  }) : assert(
          (onSelected == null) != (sheet == null),
          'A destination either navigates or opens a sheet, not both.',
        );

  /// The slot's name. Caller-supplied, so it can be localized.
  final String label;

  /// The resting icon.
  final IconData icon;

  /// The icon while this slot is the current one.
  final IconData selectedIcon;

  /// Navigates straight there.
  final VoidCallback? onSelected;

  /// Opens a sheet of destinations or actions instead of navigating.
  final FoNavSheet? sheet;
}

/// The application shell: one navigation model, three layouts.
///
/// Expanded gets a labelled sidebar, medium an icon-only rail, and compact a
/// bottom bar. **One model feeds all three**, which is the point — an app that
/// builds its phone navigation separately from its desktop navigation ends up
/// with two that disagree about what exists.
///
/// Everything here is props in, callbacks out. Permissions, routes and the
/// app's own vocabulary stay in the app: it filters [groups] and
/// [destinations] to what this user may see and passes the result. If that
/// filtering reads observable state, do the reading in the app's own observer
/// around this widget — a value captured outside one resolves before session
/// restore completes and never updates.
class FoShellScaffold extends StatelessWidget {
  /// Creates a shell.
  const FoShellScaffold({
    required this.body,
    this.groups = const <FoNavGroup>[],
    this.selectedItemId,
    this.destinations = const <FoNavDestination>[],
    this.selectedDestinationIndex = 0,
    this.footer,
    super.key,
  }) : assert(
          destinations.length != 1,
          'A bottom bar needs at least two destinations — with one there is '
          'nothing to choose. Pass none to drop the bar entirely.',
        );

  /// The current page.
  final Widget body;

  /// The sidebar's destinations, grouped. Used on the medium and expanded
  /// bands.
  final List<FoNavGroup> groups;

  /// Which of [groups]' items is current, by [FoNavItem.id]. Null highlights
  /// nothing, which is right for a page that is not a destination.
  final String? selectedItemId;

  /// The compact band's bottom bar — two to five slots, or none at all.
  final List<FoNavDestination> destinations;

  /// Which of [destinations] is current.
  final int selectedDestinationIndex;

  /// A pinned action at the foot of the sidebar — a theme toggle, a sign-out.
  final FoNavAction? footer;

  /// The labelled sidebar's width.
  static const double sidebarWidth = 240;

  /// The collapsed rail's width.
  ///
  /// 600–900 is too narrow to spend 240 on labels and still show a table
  /// beside them, so the medium band gets the rail: every destination stays
  /// reachable, and the label survives as the tooltip.
  static const double railWidth = 72;

  @override
  Widget build(BuildContext context) {
    final FoWindowClass windowClass = context.foWindowClass;

    if (windowClass == FoWindowClass.compact) {
      return _CompactShell(
        body: body,
        destinations: destinations,
        selectedIndex: selectedDestinationIndex,
      );
    }

    return _ExpandedShell(
      body: body,
      groups: groups,
      selectedItemId: selectedItemId,
      footer: footer,
      collapsed: windowClass == FoWindowClass.medium,
    );
  }
}

class _ExpandedShell extends StatelessWidget {
  const _ExpandedShell({
    required this.body,
    required this.groups,
    required this.selectedItemId,
    required this.footer,
    required this.collapsed,
  });

  final Widget body;
  final List<FoNavGroup> groups;
  final String? selectedItemId;
  final FoNavAction? footer;
  final bool collapsed;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: <Widget>[
          SizedBox(
            width: collapsed
                ? FoShellScaffold.railWidth
                : FoShellScaffold.sidebarWidth,
            child: DecoratedBox(
              decoration: BoxDecoration(color: context.foColors.surface),
              // Rule §3.1: a selected tile paints its own ground to the full
              // width of the column, so a trailing border in the same
              // decoration as the fill would be covered wherever a tile is
              // selected — a divider that disappears one row at a time.
              child: DecoratedBox(
                position: DecorationPosition.foreground,
                decoration: BoxDecoration(
                  border: Border(
                    right: BorderSide(color: context.foColors.edge),
                  ),
                ),
                child: Column(
                  children: <Widget>[
                    Expanded(
                      // Thirteen destinations do not fit an 800pt-tall
                      // window; the list has always scrolled, but with
                      // nothing to say so.
                      child: Scrollbar(
                        child: ListView(
                          primary: true,
                          padding: EdgeInsets.symmetric(
                            vertical: context.foSpacing.sm,
                          ),
                          children: <Widget>[
                            for (final FoNavGroup group in groups) ...<Widget>[
                              if (!collapsed &&
                                  group.label != null &&
                                  group.items.isNotEmpty)
                                _SidebarGroupLabel(label: group.label!),
                              for (final FoNavItem item in group.items)
                                _SidebarTile(
                                  label: item.label,
                                  icon: _NavIcon(
                                    item: item,
                                    isSelected: item.id == selectedItemId,
                                  ),
                                  isSelected: item.id == selectedItemId,
                                  onTap: item.onSelected,
                                  collapsed: collapsed,
                                ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    if (footer != null) ...<Widget>[
                      const Divider(),
                      _SidebarTile(
                        label: footer!.label,
                        icon: Icon(
                          footer!.icon,
                          color: context.foColors.fgMuted,
                        ),
                        isSelected: false,
                        onTap: footer!.onTap,
                        collapsed: collapsed,
                      ),
                      SizedBox(height: context.foSpacing.sm),
                    ],
                  ],
                ),
              ),
            ),
          ),
          Expanded(child: body),
        ],
      ),
    );
  }
}

class _SidebarGroupLabel extends StatelessWidget {
  const _SidebarGroupLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        context.foSpacing.lg,
        context.foSpacing.lg,
        context.foSpacing.lg,
        context.foSpacing.xs,
      ),
      // The mono uppercase caption names what follows rather than saying
      // anything itself — rule §3.3.
      child: Text(label.toUpperCase(), style: context.foText.caption),
    );
  }
}

/// One sidebar row, in both of its shapes.
///
/// Deliberately not a `ListTile`: the two shapes share their ground, their
/// ink, their focus ring and their 48dp floor, and building them from two
/// different Material widgets is how a rail ends up with a selected state that
/// does not match the sidebar's.
class _SidebarTile extends StatelessWidget {
  const _SidebarTile({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    required this.collapsed,
  });

  final String label;
  final Widget icon;
  final bool isSelected;
  final VoidCallback onTap;
  final bool collapsed;

  @override
  Widget build(BuildContext context) {
    final BorderRadius radius = BorderRadius.circular(context.foRadii.md);

    final Widget tile = Material(
      type: MaterialType.transparency,
      child: FoFocusRing(
        borderRadius: radius,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: Ink(
            height: FoLayout.minTouchTarget,
            decoration: BoxDecoration(
              color: isSelected ? context.foColors.primarySoft : null,
              borderRadius: radius,
            ),
            child: collapsed
                ? Center(child: icon)
                : Row(
                    children: <Widget>[
                      SizedBox(width: context.foSpacing.md),
                      icon,
                      SizedBox(width: context.foSpacing.md),
                      Expanded(
                        child: Text(
                          label,
                          overflow: TextOverflow.ellipsis,
                          style: context.foText.body.copyWith(
                            color: isSelected
                                ? context.foColors.primary
                                : context.foColors.fg,
                            fontWeight:
                                isSelected ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                      ),
                      SizedBox(width: context.foSpacing.sm),
                    ],
                  ),
          ),
        ),
      ),
    );

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: context.foSpacing.sm,
        vertical: context.foSpacing.xs,
      ),
      // The label is gone from the rail, so it has to be reachable somehow.
      child: collapsed ? Tooltip(message: label, child: tile) : tile,
    );
  }
}

class _NavIcon extends StatelessWidget {
  const _NavIcon({required this.item, required this.isSelected});

  final FoNavItem item;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final Widget icon = Icon(
      isSelected ? item.selectedIcon : item.icon,
      color: isSelected ? context.foColors.primary : context.foColors.fgMuted,
    );

    final int count = item.badgeCount ?? 0;
    if (count == 0) return icon;

    return Semantics(
      container: true,
      label: item.badgeSemanticLabel,
      excludeSemantics: item.badgeSemanticLabel != null,
      child: Badge.count(
        count: count,
        backgroundColor: context.foColors.danger,
        textColor: context.foColors.dangerFg,
        child: icon,
      ),
    );
  }
}

class _CompactShell extends StatelessWidget {
  const _CompactShell({
    required this.body,
    required this.destinations,
    required this.selectedIndex,
  });

  final Widget body;
  final List<FoNavDestination> destinations;
  final int selectedIndex;

  @override
  Widget build(BuildContext context) {
    if (destinations.isEmpty) return Scaffold(body: body);

    return Scaffold(
      body: body,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex.clamp(0, destinations.length - 1),
        onDestinationSelected: (int index) => _select(context, index),
        destinations: <Widget>[
          for (final FoNavDestination destination in destinations)
            NavigationDestination(
              icon: Icon(destination.icon),
              selectedIcon: Icon(destination.selectedIcon),
              label: destination.label,
            ),
        ],
      ),
    );
  }

  void _select(BuildContext context, int index) {
    final FoNavDestination destination = destinations[index];
    final FoNavSheet? sheet = destination.sheet;
    if (sheet == null) {
      destination.onSelected!();
      return;
    }
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (BuildContext sheetContext) => _NavSheetList(
        sheet: sheet,
        onTap: (FoNavAction action) {
          // Pop first: the action navigates, and a sheet still mounted over
          // the page it navigated to is a sheet the user has to dismiss to
          // see what they asked for.
          Navigator.of(sheetContext).pop();
          action.onTap();
        },
      ),
    );
  }
}

class _NavSheetList extends StatelessWidget {
  const _NavSheetList({required this.sheet, required this.onTap});

  final FoNavSheet sheet;
  final void Function(FoNavAction action) onTap;

  /// How much of the window a sheet of destinations may take. Beyond this it
  /// stops reading as a sheet over the page and starts reading as a page.
  static const double _maxHeightFraction = 0.75;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * _maxHeightFraction,
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            context.foSpacing.lg,
            context.foSpacing.sm,
            context.foSpacing.lg,
            context.foSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(sheet.title, style: context.foText.subtitle),
              SizedBox(height: context.foSpacing.md),
              if (sheet.actions.isEmpty)
                Text(
                  sheet.emptyLabel,
                  style: context.foText.body.copyWith(
                    color: context.foColors.fgMuted,
                  ),
                )
              else
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: <Widget>[
                      for (final FoNavAction action in sheet.actions)
                        ListTile(
                          leading: Icon(action.icon),
                          title: Text(action.label),
                          onTap: () => onTap(action),
                          minTileHeight: FoLayout.minTouchTarget,
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

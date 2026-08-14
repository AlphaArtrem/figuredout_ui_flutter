import 'package:flutter/material.dart';

import '../theme/fo_context.dart';

/// The standard top app bar.
///
/// A wrapper so screens never build an `AppBar` directly and so the theme's
/// `AppBarTheme` — flat, untinted, on `surface` — is the only place its
/// appearance is decided.
class FoAppBar extends StatelessWidget implements PreferredSizeWidget {
  /// Creates an app bar.
  const FoAppBar({
    required this.title,
    this.actions,
    this.leading,
    this.centerTitle = false,
    super.key,
  });

  /// The page's name. Caller-supplied, so it can be localized.
  final String title;

  /// Trailing actions.
  final List<Widget>? actions;

  /// The leading widget — a back button, a menu.
  final Widget? leading;

  /// Centres the title. Off by default: a left-aligned title reads faster in a
  /// list of screens, and a centred one loses room to its actions.
  final bool centerTitle;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) => AppBar(
        title: Text(title),
        actions: actions,
        leading: leading,
        centerTitle: centerTitle,
      );
}

/// A page: app bar, an optional controls row, and the body.
///
/// The controls row is the point. Left to themselves, list screens put their
/// search box, their filter and their New button in three different places and
/// at three different widths. Passing them here puts them in one, and gets the
/// compact layout — everything stacked full-width — for free.
class FoScaffold extends StatelessWidget {
  /// Creates a page scaffold.
  const FoScaffold({
    required this.title,
    required this.body,
    this.actions,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.leading,
    this.searchField,
    this.dropdown,
    this.customWidgets,
    this.primaryAction,
    this.primaryActionBuilder,
    super.key,
  }) : assert(
          primaryAction == null || primaryActionBuilder == null,
          'Pass either primaryAction or primaryActionBuilder, not both.',
        );

  /// The page's name. Caller-supplied, so it can be localized.
  final String title;

  /// The page's content.
  final Widget body;

  /// App-bar actions.
  final List<Widget>? actions;

  /// A floating action button.
  final Widget? floatingActionButton;

  /// Bottom navigation.
  final Widget? bottomNavigationBar;

  /// The app bar's leading widget.
  final Widget? leading;

  /// The search field, first in the controls row.
  final Widget? searchField;

  /// A filter dropdown, after the search field.
  final Widget? dropdown;

  /// Anything else in the controls row.
  final List<Widget>? customWidgets;

  /// The page's primary action, at the end of the controls row.
  final Widget? primaryAction;

  /// A [primaryAction] that depends on state which resolves *after* the first
  /// frame — a permission check against a session that is still restoring.
  ///
  /// It is evaluated inside [reactiveBuilder], so an app with an observable
  /// store sets that hook once and every scaffold's action then appears when
  /// the permission arrives, instead of each call site having to remember to
  /// wrap itself. Reading an observable in a plain `build` that is not inside
  /// the observer is an untracked read: it resolves once, before the session
  /// exists, and the action never appears.
  final Widget? Function(BuildContext context)? primaryActionBuilder;

  /// How [primaryActionBuilder] is wrapped so its reads are tracked.
  ///
  /// Defaults to a plain [Builder] — correct for an app with no reactive
  /// store. An app using MobX sets this once at startup:
  ///
  /// ```dart
  /// FoScaffold.reactiveBuilder = (builder) => Observer(builder: builder);
  /// ```
  ///
  /// The package deliberately does not depend on any state library; this hook
  /// is how the reactive boundary stays inside the design system without one.
  static Widget Function(Widget Function(BuildContext context) builder)
      reactiveBuilder =
      (Widget Function(BuildContext) builder) => Builder(builder: builder);

  @override
  Widget build(BuildContext context) {
    final Widget? Function(BuildContext)? builder = primaryActionBuilder;
    if (builder == null) return _build(context, primaryAction);
    return reactiveBuilder(
      (BuildContext context) => _build(context, builder(context)),
    );
  }

  Widget _build(BuildContext context, Widget? resolvedAction) {
    final bool hasControls = searchField != null ||
        dropdown != null ||
        (customWidgets?.isNotEmpty ?? false) ||
        resolvedAction != null;

    return Scaffold(
      appBar: FoAppBar(title: title, actions: actions, leading: leading),
      body: hasControls
          ? Column(
              children: <Widget>[
                _ControlsBar(
                  searchField: searchField,
                  dropdown: dropdown,
                  customWidgets: customWidgets ?? const <Widget>[],
                  primaryAction: resolvedAction,
                ),
                Expanded(child: body),
              ],
            )
          : body,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
    );
  }
}

class _ControlsBar extends StatelessWidget {
  const _ControlsBar({
    required this.searchField,
    required this.dropdown,
    required this.customWidgets,
    required this.primaryAction,
  });

  final Widget? searchField;
  final Widget? dropdown;
  final List<Widget> customWidgets;
  final Widget? primaryAction;

  /// The dropdown's width in the wide row. Fixed, so the search box beside it
  /// does not resize every time the filter's selected value changes length.
  static const double _dropdownWidth = 220;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: context.foSpacing.lg,
        vertical: context.foSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: context.foColors.surface,
        border: Border(bottom: BorderSide(color: context.foColors.edge)),
      ),
      child: context.foWindowClass.isAtLeastMedium
          ? _wide(context)
          : _compact(context),
    );
  }

  Widget _wide(BuildContext context) => Row(
        children: <Widget>[
          Expanded(
            child: Row(
              children: <Widget>[
                if (searchField != null) Flexible(flex: 2, child: searchField!),
                if (searchField != null && dropdown != null)
                  SizedBox(width: context.foSpacing.md),
                if (dropdown != null)
                  SizedBox(width: _dropdownWidth, child: dropdown!),
                if (dropdown != null && customWidgets.isNotEmpty)
                  SizedBox(width: context.foSpacing.lg),
                for (int i = 0; i < customWidgets.length; i++) ...<Widget>[
                  customWidgets[i],
                  if (i != customWidgets.length - 1)
                    SizedBox(width: context.foSpacing.md),
                ],
              ],
            ),
          ),
          if (primaryAction != null) primaryAction!,
        ],
      );

  Widget _compact(BuildContext context) {
    final bool hasFilters =
        searchField != null || dropdown != null || customWidgets.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (searchField != null) searchField!,
        if (searchField != null && dropdown != null)
          SizedBox(height: context.foSpacing.sm),
        if (dropdown != null) dropdown!,
        if ((searchField != null || dropdown != null) &&
            customWidgets.isNotEmpty)
          SizedBox(height: context.foSpacing.sm),
        if (customWidgets.isNotEmpty)
          Wrap(
            spacing: context.foSpacing.md,
            runSpacing: context.foSpacing.sm,
            children: customWidgets,
          ),
        if (hasFilters && primaryAction != null)
          SizedBox(height: context.foSpacing.sm),
        if (primaryAction != null)
          SizedBox(width: double.infinity, child: primaryAction!),
      ],
    );
  }
}

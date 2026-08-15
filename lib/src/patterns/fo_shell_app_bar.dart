import 'package:flutter/material.dart';

import '../primitives/fo_focus_ring.dart';
import '../theme/fo_context.dart';
import '../tokens/fo_tokens.dart';

/// One row of a [FoAccountMenuButton]'s menu.
@immutable
class FoAccountMenuItem {
  /// Creates a menu row.
  const FoAccountMenuItem({
    required this.label,
    required this.icon,
    required this.onSelected,
  });

  /// What it does. Caller-supplied, so it can be localized.
  final String label;

  /// Its icon.
  final IconData icon;

  /// Performs it.
  ///
  /// Anything irreversible confirms here, in the app: whether signing out
  /// needs a confirmation, and what that confirmation says, is a product
  /// decision rather than a design-system one.
  final VoidCallback onSelected;
}

/// The avatar that opens the account menu.
///
/// The initial is derived from [userName] rather than being passed in, so one
/// user is one avatar everywhere. A signed-out shell passes a null name and
/// gets nothing — which is why the caller never has to branch around it.
class FoAccountMenuButton extends StatelessWidget {
  /// Creates an account menu.
  const FoAccountMenuButton({
    required this.userName,
    required this.items,
    super.key,
  });

  /// Who is signed in. Null renders nothing at all.
  final String? userName;

  /// The menu's rows.
  final List<FoAccountMenuItem> items;

  /// The avatar's radius. Inside a 48dp touch target, not instead of one.
  static const double _avatarRadius = 16;

  @override
  Widget build(BuildContext context) {
    final String? name = userName;
    if (name == null || items.isEmpty) return const SizedBox.shrink();

    return FoFocusRing(
      borderRadius: BorderRadius.circular(context.foRadii.card),
      child: PopupMenuButton<FoAccountMenuItem>(
        tooltip: name,
        icon: CircleAvatar(
          radius: _avatarRadius,
          backgroundColor: context.foColors.primarySoft,
          child: Text(
            name.isEmpty ? '?' : name.characters.first.toUpperCase(),
            style: context.foText.label.copyWith(
              color: context.foColors.primary,
            ),
          ),
        ),
        onSelected: (FoAccountMenuItem item) => item.onSelected(),
        itemBuilder: (BuildContext context) =>
            <PopupMenuEntry<FoAccountMenuItem>>[
          for (final FoAccountMenuItem item in items)
            PopupMenuItem<FoAccountMenuItem>(
              value: item,
              child: Row(
                children: <Widget>[
                  Icon(item.icon, size: FoTokens.iconSmall),
                  SizedBox(width: context.foSpacing.sm),
                  Text(item.label),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// The shell's own app bar: the app's name, and who is signed in.
///
/// Distinct from `FoAppBar`, which titles a *page*. This one titles the
/// application, so it carries the account menu and sits above the shell rather
/// than above a screen.
class FoShellAppBar extends StatelessWidget implements PreferredSizeWidget {
  /// Creates a shell app bar.
  const FoShellAppBar({
    required this.title,
    this.accountMenu,
    this.actions,
    super.key,
  });

  /// The application's name, or the current unit's. Caller-supplied, so it can
  /// be localized.
  final String title;

  /// The account menu, pinned last so it is in the same corner on every
  /// screen.
  ///
  /// A `Widget` rather than a [FoAccountMenuButton] because the name it shows
  /// is nearly always reactive — it resolves when session restore completes,
  /// after the first frame — so an app wraps the button in its own observer
  /// and passes that.
  final Widget? accountMenu;

  /// Anything else, before the account menu.
  final List<Widget>? actions;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title),
      actions: <Widget>[
        ...?actions,
        if (accountMenu != null) ...<Widget>[
          accountMenu!,
          SizedBox(width: context.foSpacing.sm),
        ],
      ],
    );
  }
}

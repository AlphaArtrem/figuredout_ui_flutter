import 'package:flutter/widgets.dart';

/// State a `FoFormSurface` shares with the form it is presenting.
///
/// Two things the surface owns but only the form body knows about:
///
/// * **footer** — a form declares its actions at the end of its body, where
///   they read naturally, and the surface pins them below the scroll area so
///   Save never scrolls out of reach. `FoFormActions` publishes itself here.
/// * **dirty** — whether the user has typed anything yet, so dismissing the
///   surface can ask before throwing the edits away. `FoTextField` and
///   `FoDropdownField` set it on change, so a form gets the guard without
///   opting in — which matters, because the forms that most need it are the
///   ones nobody remembered to wire up.
class FoFormController {
  /// The action row hoisted out of the scrolling body.
  final ValueNotifier<Widget?> footer = ValueNotifier<Widget?>(null);

  /// Whether the user has edited anything.
  final ValueNotifier<bool> dirty = ValueNotifier<bool>(false);

  Object? _footerOwner;

  /// Whether [owner] may publish the pinned footer.
  ///
  /// The first claimant keeps the slot for as long as it is mounted. A second
  /// `FoFormActions` in the same surface renders inline instead of fighting
  /// over it — losing the fight would make a whole action row vanish, and a
  /// form with an invisible Save is worse than one with two rows.
  bool claimFooter(Object owner) {
    if (_footerOwner != null && !identical(_footerOwner, owner)) return false;
    _footerOwner = owner;
    return true;
  }

  /// Publishes [child] into the pinned footer, if [owner] holds the slot.
  void publishFooter(Object owner, Widget child) {
    if (!identical(_footerOwner, owner)) return;
    footer.value = child;
  }

  /// Gives up the slot.
  void releaseFooter(Object owner) {
    if (!identical(_footerOwner, owner)) return;
    _footerOwner = null;
    footer.value = null;
  }

  /// Records that the user has edited the form.
  void markDirty() => dirty.value = true;

  /// Releases both notifiers.
  void dispose() {
    footer.dispose();
    dirty.dispose();
  }
}

/// Publishes the enclosing form surface's [FoFormController] to its subtree.
class FoFormScope extends InheritedWidget {
  /// Creates a form scope.
  const FoFormScope({
    required this.controller,
    required super.child,
    super.key,
  });

  /// The shared controller.
  final FoFormController controller;

  /// The controller of the nearest enclosing form surface, if any.
  ///
  /// Null for a form rendered as a full page rather than inside a surface,
  /// which is why every caller has to tolerate its absence.
  static FoFormController? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<FoFormScope>()?.controller;

  /// Records that the user has edited the form, if one is presenting it.
  ///
  /// Safe to call from an `onChanged` handler: it only ever flips a flag, and
  /// nothing rebuilds on it except the dismiss guard's listener.
  static void markDirty(BuildContext context) {
    // getInheritedWidgetOfExactType, not dependOn: an onChanged callback runs
    // outside build, where registering a dependency is not allowed.
    context
        .getInheritedWidgetOfExactType<FoFormScope>()
        ?.controller
        .markDirty();
  }

  @override
  bool updateShouldNotify(FoFormScope oldWidget) =>
      controller != oldWidget.controller;
}

import 'package:flutter/material.dart';

import '../theme/fo_context.dart';
import 'fo_dialog.dart';
import 'fo_form_scope.dart';
import 'fo_form_surface.dart';

/// The copy the dismiss guard needs.
///
/// Required rather than defaulted, because the package holds no user-facing
/// strings — and because "Discard changes?" is one of the few places where the
/// exact wording is worth an app's attention.
@immutable
class FoDiscardCopy {
  /// Creates the discard-confirmation copy.
  const FoDiscardCopy({
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.cancelLabel,
  });

  /// The question, e.g. "Discard changes?".
  final String title;

  /// What discarding costs.
  final String message;

  /// The destructive choice, e.g. "Discard".
  final String confirmLabel;

  /// The safe choice, e.g. "Keep editing".
  final String cancelLabel;
}

/// The one way to present a form.
///
/// Every modal goes through here — never `showDialog` or
/// `showModalBottomSheet` from a feature. This owns three things that are easy
/// to get wrong once each and impossible to get right thirty times:
///
/// * **the dialog-versus-sheet breakpoint** — a dialog on a wide window, a
///   bottom sheet on a phone;
/// * **the root navigator** — a modal belongs to the app, not to the shell
///   branch that opened it. On the nearest navigator the shell's bottom nav
///   stays live behind the scrim, so sheets stack on each other and a route
///   change leaves the dialog orphaned over a screen it knows nothing about;
/// * **the dirty-form guard** — dismissing a form with unsaved edits asks
///   first, including via the barrier and the system back gesture.
abstract final class FoFormPresenter {
  /// Presents [child] as a form and resolves with whatever it pops.
  static Future<T?> show<T>(
    BuildContext context, {
    required String title,
    required Widget child,
    required FoDiscardCopy discardCopy,
    String? subtitle,
    Widget? footer,
    double maxWidth = 720,
    double maxHeight = 760,
    bool scrollable = true,
  }) {
    final Widget surface = _GuardedSurface(
      title: title,
      subtitle: subtitle,
      footer: footer,
      scrollable: scrollable,
      discardCopy: discardCopy,
      child: child,
    );

    if (context.foWindowClass.isAtLeastMedium) {
      // showDialog already uses the root navigator. The barrier stays
      // dismissible: it pops through Navigator.maybePop, which the guard's
      // PopScope intercepts while the form is dirty.
      return showDialog<T>(
        context: context,
        builder: (_) => Dialog(
          insetPadding: const EdgeInsets.all(24),
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: maxWidth,
              maxHeight: maxHeight,
            ),
            child: surface,
          ),
        ),
      );
    }

    return showModalBottomSheet<T>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      builder: (_) => Padding(
        // The keyboard's inset, so a focused field is not under it.
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: surface,
        ),
      ),
    );
  }
}

/// [FoFormSurface] plus the dismiss guard.
///
/// Owns the [FoFormController] so the [PopScope] above the surface and the
/// form body below it read the same dirty flag.
class _GuardedSurface extends StatefulWidget {
  const _GuardedSurface({
    required this.title,
    required this.child,
    required this.scrollable,
    required this.discardCopy,
    this.subtitle,
    this.footer,
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final Widget? footer;
  final bool scrollable;
  final FoDiscardCopy discardCopy;

  @override
  State<_GuardedSurface> createState() => _GuardedSurfaceState();
}

class _GuardedSurfaceState extends State<_GuardedSurface> {
  final FoFormController _controller = FoFormController();
  final FocusScopeNode _focusScopeNode = FocusScopeNode();
  bool _dirty = false;
  bool _confirming = false;

  @override
  void initState() {
    super.initState();
    _controller.dirty.addListener(_onDirtyChanged);
  }

  void _onDirtyChanged() {
    final bool dirty = _controller.dirty.value;
    if (dirty == _dirty || !mounted) return;
    setState(() => _dirty = dirty);
  }

  @override
  void dispose() {
    _controller.dirty.removeListener(_onDirtyChanged);
    _controller.dispose();
    _focusScopeNode.dispose();
    super.dispose();
  }

  Future<void> _requestClose() async {
    if (!_dirty) {
      Navigator.of(context).pop();
      return;
    }
    // Guard against a second close arriving while the confirmation is open —
    // a barrier tap behind the dialog, say — which would stack two of them.
    if (_confirming) return;
    _confirming = true;
    final bool discard = await FoDialog.destructive(
      context,
      title: widget.discardCopy.title,
      message: widget.discardCopy.message,
      confirmLabel: widget.discardCopy.confirmLabel,
      cancelLabel: widget.discardCopy.cancelLabel,
    );
    _confirming = false;
    if (!mounted || !discard) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (bool didPop, _) {
        if (didPop) return;
        _requestClose();
      },
      // Focus trap: tabbing must cycle inside the open modal rather than
      // walking off into the screen behind the scrim, which is unreachable by
      // pointer but was still in the traversal order.
      child: FocusScope(
        node: _focusScopeNode,
        child: FocusTraversalGroup(
          child: FoFormSurface(
            title: widget.title,
            subtitle: widget.subtitle,
            footer: widget.footer,
            scrollable: widget.scrollable,
            controller: _controller,
            onClose: _requestClose,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

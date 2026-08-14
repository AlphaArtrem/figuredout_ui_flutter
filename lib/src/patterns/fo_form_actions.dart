import 'package:flutter/material.dart';

import '../primitives/fo_button.dart';
import '../theme/fo_context.dart';
import 'fo_form_scope.dart';

/// One action in a [FoFormActions] row.
@immutable
class FoFormAction {
  /// Creates a form action.
  const FoFormAction({
    required this.label,
    required this.variant,
    required this.onPressed,
    this.isLoading = false,
  });

  /// The button's text. Caller-supplied, so it can be localized.
  final String label;

  /// What the action is worth.
  final FoButtonVariant variant;

  /// What it does. Null disables it.
  final VoidCallback? onPressed;

  /// Shows a spinner and blocks the tap.
  final bool isLoading;
}

/// The Cancel/Save row at the end of a form.
///
/// Inside a `FoFormSurface` the row is **hoisted** out of the scrolling body
/// into the surface's pinned footer, so Save stays reachable on a long form
/// instead of sitting below the fold. Forms keep declaring it at the end of
/// the body — where it reads naturally, and where it stays if the form is
/// later rendered as a full page — and it renders in place unchanged anywhere
/// there is no surface to hoist it into.
///
/// On a compact window the buttons stack full-width; a 48dp target in a row of
/// three is not 48dp wide.
class FoFormActions extends StatefulWidget {
  /// Creates an action row.
  const FoFormActions({required this.actions, super.key});

  /// The actions, in reading order. The primary one goes last.
  final List<FoFormAction> actions;

  @override
  State<FoFormActions> createState() => _FoFormActionsState();
}

class _FoFormActionsState extends State<FoFormActions> {
  FoFormController? _controller;
  bool _hoisted = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final FoFormController? controller = FoFormScope.maybeOf(context);
    if (identical(controller, _controller)) return;
    _release();
    _controller = controller;
    _hoisted = controller?.claimFooter(this) ?? false;
  }

  @override
  void dispose() {
    _release();
    super.dispose();
  }

  void _release() {
    if (_hoisted) _controller?.releaseFooter(this);
    _hoisted = false;
  }

  @override
  Widget build(BuildContext context) {
    final Widget row = _ActionRow(actions: widget.actions);
    if (!_hoisted) return row;

    // The footer lives in a sibling subtree, so publishing has to wait for
    // this build to finish — setting it now would rebuild the surface
    // mid-build.
    final FoFormController controller = _controller!;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) controller.publishFooter(this, row);
    });
    return const SizedBox.shrink();
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({required this.actions});

  final List<FoFormAction> actions;

  @override
  Widget build(BuildContext context) {
    Widget button(FoFormAction action, {bool fullWidth = false}) => FoButton(
          label: action.label,
          variant: action.variant,
          onPressed: action.onPressed,
          isLoading: action.isLoading,
          fullWidth: fullWidth,
        );

    if (!context.foWindowClass.isAtLeastMedium) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          for (int i = 0; i < actions.length; i++) ...<Widget>[
            button(actions[i], fullWidth: true),
            if (i < actions.length - 1) SizedBox(height: context.foSpacing.sm),
          ],
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: <Widget>[
        for (int i = 0; i < actions.length; i++) ...<Widget>[
          Flexible(child: button(actions[i])),
          if (i < actions.length - 1) SizedBox(width: context.foSpacing.sm),
        ],
      ],
    );
  }
}

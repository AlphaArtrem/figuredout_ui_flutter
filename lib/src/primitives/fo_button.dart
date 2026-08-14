import 'package:flutter/material.dart';

import '../theme/fo_context.dart';
import '../tokens/fo_colors.dart';
import '../tokens/fo_layout.dart';
import '../tokens/fo_tokens.dart';
import 'fo_focus_ring.dart';
import 'fo_spinner.dart';

/// What a button is for, which is not the same as what it looks like.
///
/// Reach for the one that matches the action's weight; the appearance follows
/// from that. A screen with two primaries has not decided what it is for.
enum FoButtonVariant {
  /// The one action the screen exists to perform.
  primary,

  /// A real action that is not the main one. Outlined on `surface`.
  secondary,

  /// Something destructive. Carries its own ink — see [FoButton].
  destructive,

  /// An action with no chrome at all: cancel, dismiss, a link in a row.
  clear,

  /// A quiet filled action — a soft wash of primary, for a third-rank action
  /// that still needs to look pressable.
  tertiary,
}

/// The standard button.
///
/// Two things are worth knowing before changing it:
///
/// **Destructive carries its own ink.** It fills with `danger` and writes in
/// `dangerFg`, never `primaryFg` and never `surface`. `primaryFg` is the ink
/// for PRIMARY, and in dark mode it is a near-black green — on a light red
/// that is unreadable. The web package learned this one the hard way.
///
/// **Focus is the ring, not a border swap.** Material's default is a tinted
/// overlay, and Luxe's original drew a 2dp rule in the button's own
/// foreground — a second focus vocabulary either way. This composes
/// [FoFocusRing] so a focused button looks like every other focused thing.
class FoButton extends StatelessWidget {
  /// Creates a button.
  const FoButton({
    required this.label,
    required this.variant,
    required this.onPressed,
    this.icon,
    this.tooltip,
    this.fullWidth = false,
    this.isLoading = false,
    super.key,
  });

  /// Visible text. Caller-supplied, so it can be localized.
  final String label;

  /// What the action is worth. See [FoButtonVariant].
  final FoButtonVariant variant;

  /// Tap handler. A null handler disables the button; so does [isLoading].
  final VoidCallback? onPressed;

  /// Optional leading icon.
  final IconData? icon;

  /// Optional hover/long-press explanation.
  final String? tooltip;

  /// Stretches the button to the available width.
  final bool fullWidth;

  /// Replaces the label with a spinner and disables the button. The button
  /// keeps its width, so a row of actions does not reflow mid-submit.
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final VoidCallback? handler = isLoading ? null : onPressed;
    final _Palette palette = _paletteFor(context, variant);
    final Widget child = _buildChild(context, palette);
    final ButtonStyle style = _styleFor(context, palette);

    final Widget button = switch (variant) {
      FoButtonVariant.primary ||
      FoButtonVariant.destructive ||
      FoButtonVariant.tertiary =>
        FilledButton(
          onPressed: handler,
          style: style,
          child: child,
        ),
      FoButtonVariant.secondary => OutlinedButton(
          onPressed: handler,
          style: style,
          child: child,
        ),
      FoButtonVariant.clear => TextButton(
          onPressed: handler,
          style: style,
          child: child,
        ),
    };

    final Widget ringed = FoFocusRing(
      borderRadius: BorderRadius.circular(context.foRadii.md),
      enabled: handler != null,
      child: button,
    );

    final Widget sized =
        fullWidth ? SizedBox(width: double.infinity, child: ringed) : ringed;

    if (tooltip == null || tooltip!.trim().isEmpty) return sized;
    return Tooltip(message: tooltip!, child: sized);
  }

  _Palette _paletteFor(BuildContext context, FoButtonVariant variant) {
    final FoColors c = context.foColors;
    return switch (variant) {
      FoButtonVariant.primary => _Palette(
          foreground: c.primaryFg,
          background: c.primary,
          border: BorderSide.none,
        ),
      // G4: danger's own ink, not primaryFg and not surface.
      FoButtonVariant.destructive => _Palette(
          foreground: c.dangerFg,
          background: c.danger,
          border: BorderSide.none,
        ),
      FoButtonVariant.secondary => _Palette(
          foreground: c.fg,
          background: c.surface,
          border: BorderSide(color: c.edgeStrong),
        ),
      FoButtonVariant.tertiary => _Palette(
          foreground: c.primary,
          background: c.primarySoft,
          border: BorderSide.none,
        ),
      FoButtonVariant.clear => _Palette(
          foreground: c.primary,
          background: Colors.transparent,
          border: BorderSide.none,
        ),
    };
  }

  ButtonStyle _styleFor(BuildContext context, _Palette palette) {
    return ButtonStyle(
      minimumSize: const WidgetStatePropertyAll<Size>(
        Size(0, FoLayout.minTouchTarget),
      ),
      padding: WidgetStatePropertyAll<EdgeInsetsGeometry>(
        EdgeInsets.symmetric(
          horizontal: context.foSpacing.lg,
          vertical: context.foSpacing.md,
        ),
      ),
      textStyle: WidgetStatePropertyAll<TextStyle>(context.foText.subtitle),
      elevation: const WidgetStatePropertyAll<double>(0),
      shadowColor: const WidgetStatePropertyAll<Color>(Colors.transparent),
      foregroundColor: WidgetStateProperty.resolveWith((
        Set<WidgetState> states,
      ) {
        if (states.contains(WidgetState.disabled)) {
          return palette.foreground.withValues(
            alpha: FoTokens.disabledInkOpacity,
          );
        }
        return palette.foreground;
      }),
      backgroundColor: WidgetStateProperty.resolveWith((
        Set<WidgetState> states,
      ) {
        if (palette.background == Colors.transparent) return Colors.transparent;
        if (states.contains(WidgetState.disabled)) {
          return palette.background.withValues(
            alpha: FoTokens.disabledFillOpacity,
          );
        }
        return palette.background;
      }),
      // Hover and press are one idea at two strengths, drawn in the button's
      // own ink so every variant reacts the same amount.
      overlayColor: WidgetStateProperty.resolveWith((Set<WidgetState> states) {
        if (states.contains(WidgetState.pressed)) {
          return palette.foreground.withValues(
            alpha: FoTokens.pressedOverlayOpacity,
          );
        }
        if (states.contains(WidgetState.hovered)) {
          return palette.foreground.withValues(
            alpha: FoTokens.hoverOverlayOpacity,
          );
        }
        return Colors.transparent;
      }),
      shape: WidgetStatePropertyAll<OutlinedBorder>(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(context.foRadii.md),
        ),
      ),
      // Focus is FoFocusRing's job. Pinning the side here stops Material
      // swapping in a focus border of its own underneath the ring.
      side: WidgetStatePropertyAll<BorderSide>(palette.border),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  Widget _buildChild(BuildContext context, _Palette palette) {
    final Widget content = _content(context);
    if (!isLoading) return content;

    // The label is kept in the tree at zero opacity so the button holds its
    // width while submitting. Swapping it for a bare spinner shrinks the
    // button to spinner-width, which reflows every other action in the row
    // at the exact moment the user is watching to see whether the tap took.
    return Stack(
      alignment: Alignment.center,
      children: <Widget>[
        Visibility(
          visible: false,
          maintainSize: true,
          maintainAnimation: true,
          maintainState: true,
          child: content,
        ),
        FoSpinner(color: palette.foreground, semanticsLabel: label),
      ],
    );
  }

  Widget _content(BuildContext context) {
    final Widget labelWidget = _labelText(label);
    if (icon == null) return labelWidget;

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Icon(icon, size: FoTokens.iconSmall),
        SizedBox(width: context.foSpacing.sm),
        Flexible(child: labelWidget),
      ],
    );
  }
}

Widget _labelText(String label) => Text(
      label,
      maxLines: 1,
      softWrap: false,
      overflow: TextOverflow.fade,
      textAlign: TextAlign.center,
    );

/// The resolved colours for one variant.
@immutable
class _Palette {
  const _Palette({
    required this.foreground,
    required this.background,
    required this.border,
  });

  final Color foreground;
  final Color background;
  final BorderSide border;
}

/// The page-level primary action.
///
/// A [FoButton] with the variant already decided, so a screen's main call to
/// action cannot accidentally be styled as a secondary one.
class FoActionButton extends StatelessWidget {
  /// Creates the primary action button.
  const FoActionButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.tooltip,
    this.fullWidth = false,
    super.key,
  });

  /// Visible text.
  final String label;

  /// Tap handler.
  final VoidCallback? onPressed;

  /// Optional leading icon.
  final IconData? icon;

  /// Optional hover explanation.
  final String? tooltip;

  /// Stretches to the available width.
  final bool fullWidth;

  @override
  Widget build(BuildContext context) => FoButton(
        label: label,
        variant: FoButtonVariant.primary,
        onPressed: onPressed,
        icon: icon,
        tooltip: tooltip,
        fullWidth: fullWidth,
      );
}

/// A primary action that submits something.
///
/// The same button as [FoActionButton] with [isLoading] threaded through; it
/// exists so a submit site cannot forget that submitting takes time.
class FoLoadingButton extends StatelessWidget {
  /// Creates a submitting button.
  const FoLoadingButton({
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.fullWidth = true,
    super.key,
  });

  /// Visible text.
  final String label;

  /// Tap handler. Ignored while [isLoading].
  final VoidCallback? onPressed;

  /// Shows a spinner in place of the label and disables the button.
  final bool isLoading;

  /// Optional leading icon, shown when not loading.
  final IconData? icon;

  /// Stretches to the available width. Defaults to true — a submit button
  /// usually ends a form.
  final bool fullWidth;

  @override
  Widget build(BuildContext context) => FoButton(
        label: label,
        variant: FoButtonVariant.primary,
        onPressed: onPressed,
        icon: icon,
        fullWidth: fullWidth,
        isLoading: isLoading,
      );
}

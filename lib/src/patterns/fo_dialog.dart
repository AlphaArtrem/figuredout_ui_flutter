import 'package:flutter/material.dart';

import '../primitives/fo_button.dart';
import '../theme/fo_context.dart';
import '../theme/fo_window_class.dart';
import '../tokens/fo_tokens.dart';

/// The single choke point for confirmation and info dialogs.
///
/// Call these instead of building an [AlertDialog]. As with `FoToast`, the
/// point is consistency rather than convenience: hand-built dialogs disagree
/// about button order, about which one is destructive, and about whether the
/// dangerous action is on the left or the right — and that disagreement is how
/// someone deletes the wrong thing.
///
/// The layout is tuned for a gloved finger: a marked header, plain-language
/// body, and full-width stacked buttons on a compact window with the
/// confirming action on top, where the thumb already is.
abstract final class FoDialog {
  /// A yes/no question. Resolves true when the user confirms.
  static Future<bool> confirm(
    BuildContext context, {
    required String title,
    required String message,
    required String confirmLabel,
    required String cancelLabel,
    IconData icon = Icons.help_outline,
  }) =>
      _show(
        context,
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        icon: icon,
        destructive: false,
      );

  /// A confirmation for something irreversible. The confirming button is
  /// filled in `danger` and writes in `dangerFg`.
  static Future<bool> destructive(
    BuildContext context, {
    required String title,
    required String message,
    required String confirmLabel,
    required String cancelLabel,
    IconData icon = Icons.warning_amber_outlined,
  }) =>
      _show(
        context,
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        icon: icon,
        destructive: true,
      );

  /// A statement with one way out.
  static Future<void> info(
    BuildContext context, {
    required String title,
    required String message,
    required String closeLabel,
    IconData icon = Icons.info_outline,
  }) =>
      _show(
        context,
        title: title,
        message: message,
        confirmLabel: closeLabel,
        cancelLabel: null,
        icon: icon,
        destructive: false,
        tone: _Tone.info,
      );

  static Future<bool> _show(
    BuildContext context, {
    required String title,
    required String message,
    required String confirmLabel,
    required String? cancelLabel,
    required IconData icon,
    required bool destructive,
    _Tone tone = _Tone.neutral,
  }) async {
    final bool? result = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) {
        final Color accent = switch ((destructive, tone)) {
          (true, _) => ctx.foColors.danger,
          (_, _Tone.info) => ctx.foColors.info,
          _ => ctx.foColors.primary,
        };
        final bool stacked =
            ctx.foWindowClass == FoWindowClass.compact || cancelLabel == null;

        final Widget confirmButton = FoButton(
          label: confirmLabel,
          variant: destructive
              ? FoButtonVariant.destructive
              : FoButtonVariant.primary,
          fullWidth: true,
          onPressed: () => Navigator.of(ctx).pop(true),
        );

        final Widget? cancelButton = cancelLabel == null
            ? null
            : FoButton(
                label: cancelLabel,
                variant: FoButtonVariant.secondary,
                fullWidth: true,
                onPressed: () => Navigator.of(ctx).pop(false),
              );

        return AlertDialog(
          backgroundColor: ctx.foColors.surfaceRaised,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ctx.foRadii.lg),
            side: BorderSide(color: ctx.foColors.edge),
          ),
          title: Column(
            children: <Widget>[
              Container(
                width: _markSize,
                height: _markSize,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: FoTokens.softWashAlpha),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: accent, size: FoTokens.iconMedium),
              ),
              SizedBox(height: ctx.foSpacing.md),
              Text(
                title,
                textAlign: TextAlign.center,
                style: ctx.foText.title,
              ),
            ],
          ),
          content: Text(
            message,
            textAlign: TextAlign.center,
            style: ctx.foText.body.copyWith(color: ctx.foColors.fgMuted),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actionsPadding: EdgeInsets.fromLTRB(
            ctx.foSpacing.xl,
            0,
            ctx.foSpacing.xl,
            ctx.foSpacing.xl,
          ),
          actions: <Widget>[
            if (stacked)
              // Confirm on top: on a phone that is where the thumb already is,
              // and the cancel below it is still the easier miss.
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  confirmButton,
                  if (cancelButton != null) ...<Widget>[
                    SizedBox(height: ctx.foSpacing.sm),
                    cancelButton,
                  ],
                ],
              )
            else
              Row(
                children: <Widget>[
                  Expanded(child: cancelButton!),
                  SizedBox(width: ctx.foSpacing.md),
                  Expanded(child: confirmButton),
                ],
              ),
          ],
        );
      },
    );
    // A dismissed dialog is a "no". Never treat the barrier as consent.
    return result ?? false;
  }

  static const double _markSize = 56;
}

enum _Tone { neutral, info }

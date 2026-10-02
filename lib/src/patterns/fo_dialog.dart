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
///
/// **On a compact window it is a bottom sheet, not a dialog** — the same
/// words, rising from where the thumb is rather than floating in the middle
/// of the screen. On every width it opens on the root navigator, so a shell's
/// bottom navigation is not live behind it.
///
/// **Name the record and the consequence.** "Delete the draft from 2 Oct,
/// 10:42?" with "The 64 Ecru pieces in this draft will be removed. This can't
/// be undone." — never "Are you sure?". Somebody deleting the wrong draft was
/// asked a question that did not say which one.
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
    final bool compact = context.foWindowClass == FoWindowClass.compact;

    Widget content(BuildContext ctx, {required bool stacked}) => _Body(
          title: title,
          message: message,
          confirmLabel: confirmLabel,
          cancelLabel: cancelLabel,
          icon: icon,
          destructive: destructive,
          tone: tone,
          stacked: stacked,
        );

    final bool? result = compact
        ? await showModalBottomSheet<bool>(
            context: context,
            useRootNavigator: true,
            isScrollControlled: true,
            useSafeArea: true,
            backgroundColor: context.foColors.surfaceRaised,
            elevation: 0,
            builder: (BuildContext ctx) => SingleChildScrollView(
              padding: EdgeInsets.all(ctx.foSpacing.xl),
              child: content(ctx, stacked: true),
            ),
          )
        : await showDialog<bool>(
            context: context,
            builder: (BuildContext ctx) => Dialog(
              backgroundColor: ctx.foColors.surfaceRaised,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(ctx.foRadii.lg),
                side: BorderSide(color: ctx.foColors.edge),
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: _maxWidth),
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(ctx.foSpacing.xl),
                  child: content(ctx, stacked: cancelLabel == null),
                ),
              ),
            ),
          );
    // A dismissed dialog is a "no". Never treat the barrier as consent.
    return result ?? false;
  }

  /// The widest the dialog gets: a question, not a document.
  static const double _maxWidth = 440;
}

enum _Tone { neutral, info }

/// The question itself — identical in the dialog and the sheet.
class _Body extends StatelessWidget {
  const _Body({
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.cancelLabel,
    required this.icon,
    required this.destructive,
    required this.tone,
    required this.stacked,
  });

  final String title;
  final String message;
  final String confirmLabel;
  final String? cancelLabel;
  final IconData icon;
  final bool destructive;
  final _Tone tone;
  final bool stacked;

  static const double _markSize = 56;

  @override
  Widget build(BuildContext context) {
    final (Color accent, Color ground) = switch ((destructive, tone)) {
      (true, _) => (context.foColors.danger, context.foColors.dangerSoft),
      (_, _Tone.info) => (context.foColors.info, context.foColors.infoSoft),
      _ => (context.foColors.primary, context.foColors.primarySoft),
    };

    final Widget confirmButton = FoButton(
      label: confirmLabel,
      variant:
          destructive ? FoButtonVariant.destructive : FoButtonVariant.primary,
      fullWidth: true,
      onPressed: () => Navigator.of(context).pop(true),
    );

    final Widget? cancelButton = cancelLabel == null
        ? null
        : FoButton(
            label: cancelLabel!,
            variant: FoButtonVariant.secondary,
            fullWidth: true,
            onPressed: () => Navigator.of(context).pop(false),
          );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Center(
          child: Container(
            width: _markSize,
            height: _markSize,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: ground, shape: BoxShape.circle),
            child: Icon(icon, color: accent, size: FoTokens.iconMedium),
          ),
        ),
        SizedBox(height: context.foSpacing.md),
        Semantics(
          header: true,
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: context.foText.title,
          ),
        ),
        SizedBox(height: context.foSpacing.sm),
        Text(
          message,
          textAlign: TextAlign.center,
          style: context.foText.body.copyWith(color: context.foColors.fgMuted),
        ),
        SizedBox(height: context.foSpacing.xl),
        if (stacked || cancelButton == null)
          // Confirm on top: on a phone that is where the thumb already is,
          // and the cancel below it is still the easier miss.
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              confirmButton,
              if (cancelButton != null) ...<Widget>[
                SizedBox(height: context.foSpacing.sm),
                cancelButton,
              ],
            ],
          )
        else
          Row(
            children: <Widget>[
              Expanded(child: cancelButton),
              SizedBox(width: context.foSpacing.md),
              Expanded(child: confirmButton),
            ],
          ),
      ],
    );
  }
}

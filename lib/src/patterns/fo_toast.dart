import 'package:flutter/material.dart';

import '../primitives/fo_button.dart';
import '../theme/fo_context.dart';
import '../tokens/fo_motion.dart';
import '../tokens/fo_tokens.dart';

/// The single choke point for transient feedback.
///
/// Call these instead of building a [SnackBar]. The point is not convenience —
/// it is that a `SnackBar` built at a call site picks its own colour, its own
/// duration and its own shape, and thirty call sites produce thirty toasts.
///
/// The treatment is a floating card on `surfaceRaised` with the semantic mark
/// in a disc of its own wash, rather than a full-bleed coloured bar. A bar has
/// to solve legible-text-on-a-saturated-ground in both themes; a mark on its
/// wash is the pairing the contrast test already measures. (Until 0.7.0 it was
/// a coloured rule down the leading edge — the left-border accent card the
/// redesign retired everywhere.)
///
/// **Say what happened, and to which record.** Pass `title` for the event
/// ("Pressing recorded") and the message for the record ("110 pieces of Deep
/// Navy, JOB-2026-10024."). A toast that says only "Saved" leaves somebody
/// wondering which of the three things they touched it means.
///
/// Errors and warnings run longer than successes: a success confirms something
/// the user already knows they did, and a failure is news.
abstract final class FoToast {
  /// How long a confirmation stays.
  static const Duration shortDuration = FoMotion.toastShort;

  /// How long something the user has to read stays.
  static const Duration longDuration = FoMotion.toastLong;

  /// Something worked.
  static void success(
    BuildContext context,
    String message, {
    FoToastAction? action,
    String? title,
  }) =>
      _show(
        context,
        message,
        title: title,
        color: context.foColors.success,
        icon: Icons.check_circle_outline,
        action: action,
      );

  /// Something failed.
  static void error(
    BuildContext context,
    String message, {
    FoToastAction? action,
    String? title,
  }) =>
      _show(
        context,
        message,
        title: title,
        color: context.foColors.danger,
        icon: Icons.error_outline,
        action: action,
        duration: longDuration,
      );

  /// Something needs attention.
  static void warning(
    BuildContext context,
    String message, {
    FoToastAction? action,
    String? title,
  }) =>
      _show(
        context,
        message,
        title: title,
        color: context.foColors.warning,
        icon: Icons.warning_amber_outlined,
        action: action,
        duration: longDuration,
      );

  /// Something the user should know.
  static void info(
    BuildContext context,
    String message, {
    FoToastAction? action,
    String? title,
  }) =>
      _show(
        context,
        message,
        title: title,
        color: context.foColors.info,
        icon: Icons.info_outline,
        action: action,
      );

  static void _show(
    BuildContext context,
    String message, {
    required String? title,
    required Color color,
    required IconData icon,
    FoToastAction? action,
    Duration duration = shortDuration,
  }) {
    final BorderRadius radius = BorderRadius.circular(context.foRadii.card);
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          duration: duration,
          // A toast covers the page, so it is the top of the ladder.
          backgroundColor: context.foColors.surfaceRaised,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: radius,
            side: BorderSide(color: context.foColors.edge),
          ),
          padding: EdgeInsets.zero,
          content: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: context.foSpacing.lg,
              vertical: context.foSpacing.md,
            ),
            child: Row(
              children: <Widget>[
                Container(
                  width: _markSize,
                  height: _markSize,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: FoTokens.softWashAlpha),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: FoTokens.iconSmall),
                ),
                SizedBox(width: context.foSpacing.md),
                Expanded(
                  child: title == null
                      ? Text(message, style: context.foText.body)
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Text(title, style: context.foText.label),
                            SizedBox(height: context.foSpacing.xs),
                            Text(
                              message,
                              style: context.foText.body.copyWith(
                                color: context.foColors.fgMuted,
                              ),
                            ),
                          ],
                        ),
                ),
                if (action != null) ...<Widget>[
                  SizedBox(width: context.foSpacing.sm),
                  // `tertiary`, not a bare TextButton: unfilled text right
                  // after the message reads as padding that failed to line
                  // up with the line above it, not as a button — ported
                  // from ui-web's toast fix (db953bf), which moved the
                  // same action from `ghost` to a filled-at-rest variant.
                  // The tint is what gives the padding somewhere to
                  // belong.
                  FoButton(
                    label: action.label,
                    variant: FoButtonVariant.tertiary,
                    onPressed: () {
                      // Dismiss first: the action usually navigates, and a
                      // toast left floating over the next screen looks like
                      // it belongs to it.
                      messenger.hideCurrentSnackBar();
                      action.onPressed();
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
      );
  }

  /// The mark's disc — the same size as the icon button glyph beside a line
  /// of body text.
  static const double _markSize = 28;
}

/// An action on a toast — "View", "Undo", "Retry".
@immutable
class FoToastAction {
  /// Creates a toast action.
  const FoToastAction({required this.label, required this.onPressed});

  /// The button's text. Caller-supplied, so it can be localized.
  final String label;

  /// What it does. The toast dismisses itself first.
  final VoidCallback onPressed;
}

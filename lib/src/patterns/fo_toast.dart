import 'package:flutter/material.dart';

import '../theme/fo_context.dart';
import '../tokens/fo_layout.dart';
import '../tokens/fo_motion.dart';

/// The single choke point for transient feedback.
///
/// Call these instead of building a [SnackBar]. The point is not convenience —
/// it is that a `SnackBar` built at a call site picks its own colour, its own
/// duration and its own shape, and thirty call sites produce thirty toasts.
///
/// The treatment is a floating card on `surfaceRaised` with a semantic mark
/// and a coloured rule down the leading edge, rather than a full-bleed
/// coloured bar. A bar has to solve legible-text-on-a-saturated-ground in both
/// themes; a rule does not, so it stays AA-safe without tuning.
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
  }) =>
      _show(
        context,
        message,
        color: context.foColors.success,
        icon: Icons.check_circle_outline,
        action: action,
      );

  /// Something failed.
  static void error(
    BuildContext context,
    String message, {
    FoToastAction? action,
  }) =>
      _show(
        context,
        message,
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
  }) =>
      _show(
        context,
        message,
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
  }) =>
      _show(
        context,
        message,
        color: context.foColors.info,
        icon: Icons.info_outline,
        action: action,
      );

  static void _show(
    BuildContext context,
    String message, {
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
          content: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: radius,
              border: Border(
                left: BorderSide(
                  color: color,
                  width: FoLayout.accentRuleWidth,
                ),
              ),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: context.foSpacing.lg,
                vertical: context.foSpacing.md,
              ),
              child: Row(
                children: <Widget>[
                  Icon(icon, color: color),
                  SizedBox(width: context.foSpacing.md),
                  Expanded(
                    child: Text(message, style: context.foText.body),
                  ),
                  if (action != null) ...<Widget>[
                    SizedBox(width: context.foSpacing.sm),
                    TextButton(
                      style: TextButton.styleFrom(
                        minimumSize: const Size(
                          FoLayout.minTouchTarget,
                          FoLayout.minTouchTarget,
                        ),
                      ),
                      onPressed: () {
                        // Dismiss first: the action usually navigates, and a
                        // toast left floating over the next screen looks like
                        // it belongs to it.
                        messenger.hideCurrentSnackBar();
                        action.onPressed();
                      },
                      child: Text(action.label),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      );
  }
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

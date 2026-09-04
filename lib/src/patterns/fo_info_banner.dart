import 'package:flutter/material.dart';

import '../primitives/fo_button.dart';
import '../theme/fo_context.dart';
import '../tokens/fo_layout.dart';

/// An inline banner reporting the state of something on the page.
///
/// The distinction worth keeping: a **toast** reports the result of an action
/// the user just took and then leaves; a banner reports a condition that is
/// still true and stays until it is not. A banner that needs dismissing after
/// three seconds should have been a toast.
///
/// Renders nothing when [message] is null or empty, so a screen can bind it
/// straight to an optional error without an enclosing `if`.
///
/// It is a live region: a message appearing after the page has settled is
/// announced rather than sitting there silently.
class FoInfoBanner extends StatelessWidget {
  /// Creates a banner.
  const FoInfoBanner({
    required this.message,
    this.tone = FoBannerTone.info,
    this.onAction,
    this.actionLabel,
    this.icon,
    super.key,
  }) : assert(
          onAction == null || actionLabel != null,
          'actionLabel is required when onAction is set — a banner with an '
          'unlabelled action is a dead end.',
        );

  /// A banner reporting a failure, with a retry.
  ///
  /// **Without [onRetry] an error banner is a dead end**: it tells the user
  /// something broke and gives them nothing to do about it.
  const FoInfoBanner.error({
    required this.message,
    VoidCallback? onRetry,
    String? retryLabel,
    super.key,
  })  : tone = FoBannerTone.danger,
        onAction = onRetry,
        actionLabel = retryLabel,
        icon = null,
        assert(
          onRetry == null || retryLabel != null,
          'retryLabel is required when onRetry is set.',
        );

  /// The text. Null or empty renders nothing at all.
  final String? message;

  /// What kind of condition this is.
  final FoBannerTone tone;

  /// The recovery action.
  final VoidCallback? onAction;

  /// The action's label. Caller-supplied, so it can be localized.
  final String? actionLabel;

  /// Overrides the tone's default mark.
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final String? text = message;
    if (text == null || text.isEmpty) return const SizedBox.shrink();

    final (Color ink, Color ground, IconData defaultIcon) = switch (tone) {
      FoBannerTone.info => (
          context.foColors.info,
          context.foColors.infoSoft,
          Icons.info_outline,
        ),
      FoBannerTone.success => (
          context.foColors.success,
          context.foColors.successSoft,
          Icons.check_circle_outline,
        ),
      FoBannerTone.warning => (
          context.foColors.warning,
          context.foColors.warningSoft,
          Icons.warning_amber_outlined,
        ),
      FoBannerTone.danger => (
          context.foColors.danger,
          context.foColors.dangerSoft,
          Icons.error_outline,
        ),
    };

    return Semantics(
      liveRegion: true,
      container: true,
      child: Container(
        padding: EdgeInsets.all(context.foSpacing.md),
        decoration: BoxDecoration(
          color: ground,
          borderRadius: BorderRadius.circular(context.foRadii.md),
        ),
        // The hairline goes on top for the same reason it does on a card: the
        // ground below is a child's fill as far as the painter is concerned.
        foregroundDecoration: BoxDecoration(
          borderRadius: BorderRadius.circular(context.foRadii.md),
          border: Border.all(
            color: ink.withValues(alpha: FoLayout.bannerEdgeOpacity),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(icon ?? defaultIcon, color: ink),
            SizedBox(width: context.foSpacing.sm),
            // **The message and the action are a `Wrap`, and the icon is
            // not.** A `Row` gave the action its natural width and the message
            // whatever was left, which is fine until the action alone is wider
            // than the banner: at twice the system text size the `Expanded`
            // collapsed to nothing and the button ran off the right, which is
            // an action nobody can reach.
            //
            // Inside a `Wrap` the button drops under the message the moment
            // the two stop fitting — at whatever text size, or message length,
            // that turns out to be. `Expanded` supplies the tight width
            // `spaceBetween` needs to have anything to put between, and the
            // icon stays a sibling of it so it keeps its place at the top
            // left rather than joining the shuffle.
            Expanded(
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: context.foSpacing.sm,
                runSpacing: context.foSpacing.sm,
                children: <Widget>[
                  Text(
                    text,
                    style: context.foText.body.copyWith(color: ink),
                  ),
                  if (onAction != null)
                    FoButton(
                      label: actionLabel!,
                      variant: FoButtonVariant.clear,
                      icon: tone == FoBannerTone.danger ? Icons.refresh : null,
                      onPressed: onAction,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// What kind of condition a [FoInfoBanner] is reporting.
enum FoBannerTone {
  /// Something the user should know.
  info,

  /// Something went right and stays right.
  success,

  /// Something needs attention but is not broken.
  warning,

  /// Something is broken.
  danger,
}

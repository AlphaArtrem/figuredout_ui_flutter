import 'package:flutter/material.dart';

import '../primitives/fo_badge.dart';
import '../primitives/fo_button.dart';
import '../primitives/fo_status_chip.dart';
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
///
/// Two shapes of the same thing are named constructors, so they read the same
/// on every screen:
///
/// * [FoInfoBanner.offline] — the connection is gone, and what is happening to
///   the user's work meanwhile ("kept on this phone, sent later");
/// * [FoInfoBanner.locked] — a record cannot be edited, why, and the one way
///   out, which asks an owner rather than failing.
class FoInfoBanner extends StatelessWidget {
  /// Creates a banner.
  const FoInfoBanner({
    required this.message,
    this.tone = FoBannerTone.info,
    this.onAction,
    this.actionLabel,
    this.icon,
    this.title,
    this.trailing,
    this.actionVariant = FoButtonVariant.clear,
    super.key,
  })  : _stackTitle = false,
        assert(
          onAction == null || actionLabel != null,
          'actionLabel is required when onAction is set — a banner with an '
          'unlabelled action is a dead end.',
        );

  /// A banner reporting a failure, with a retry.
  ///
  /// **Without [onRetry] an error banner is a dead end**: it tells the user
  /// something broke and gives them nothing to do about it.
  ///
  /// [title] names *what* failed — "Couldn't check today's defects" — when
  /// the banner sits among other things that did not fail, so one failed
  /// check never reads as the whole page failing, or as "all clear".
  const FoInfoBanner.error({
    required this.message,
    VoidCallback? onRetry,
    String? retryLabel,
    this.title,
    super.key,
  })  : tone = FoBannerTone.danger,
        onAction = onRetry,
        actionLabel = retryLabel,
        icon = null,
        trailing = null,
        actionVariant = FoButtonVariant.clear,
        _stackTitle = false,
        assert(
          onRetry == null || retryLabel != null,
          'retryLabel is required when onRetry is set.',
        );

  /// The device is offline: what is happening to the user's work meanwhile.
  ///
  /// [title] is the fact ("You're offline."), [message] the consequence ("New
  /// entries are kept on this phone and sent when the connection is back."),
  /// and [pending] an optional count of what is waiting — "2 waiting to send".
  /// Warning, not danger: nothing is lost, and saying otherwise teaches
  /// somebody to stop recording on a bad connection.
  FoInfoBanner.offline({
    required String this.title,
    required this.message,
    String? pending,
    super.key,
  })  : tone = FoBannerTone.warning,
        icon = Icons.wifi_off,
        onAction = null,
        actionLabel = null,
        actionVariant = FoButtonVariant.clear,
        _stackTitle = false,
        trailing = pending == null
            ? null
            : FoBadge(label: pending, tone: FoStatusTone.warning);

  /// A record that cannot be edited, why, and the way out.
  ///
  /// A locked record is not an error, so it is info rather than danger, with
  /// a lock. The way out is [onRequestChange] — a `warning` button, because
  /// an owner has to say yes to it. Leave it null where the user cannot ask,
  /// and say who can in [message] instead.
  const FoInfoBanner.locked({
    required String this.title,
    required this.message,
    VoidCallback? onRequestChange,
    String? requestChangeLabel,
    super.key,
  })  : tone = FoBannerTone.info,
        icon = Icons.lock_outline,
        onAction = onRequestChange,
        actionLabel = requestChangeLabel,
        actionVariant = FoButtonVariant.warning,
        trailing = null,
        _stackTitle = true,
        assert(
          onRequestChange == null || requestChangeLabel != null,
          'requestChangeLabel is required when onRequestChange is set.',
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

  /// A short lead-in in the semibold weight — the fact — with [message] as
  /// the sentence after it. Optional; most banners are one sentence.
  final String? title;

  /// Something small at the end of the message — a count of what is waiting.
  /// It wraps under the message when the two stop fitting.
  final Widget? trailing;

  /// How the action is drawn. A bare `clear` link by default; `warning` when
  /// the action asks an owner for something, as [FoInfoBanner.locked]'s does.
  final FoButtonVariant actionVariant;

  /// Whether [title] sits on its own line (a locked notice, which is read as
  /// a heading) or leads the sentence (an offline banner, which is one line).
  final bool _stackTitle;

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
      FoBannerTone.neutral => (
          context.foColors.fgMuted,
          context.foColors.surfaceSunken,
          Icons.info_outline,
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
                  _message(context, text, ink),
                  if (trailing != null) trailing!,
                  if (onAction != null)
                    FoButton(
                      label: actionLabel!,
                      variant: actionVariant,
                      icon: tone == FoBannerTone.danger
                          ? Icons.refresh
                          : actionVariant == FoButtonVariant.warning
                              ? Icons.edit_outlined
                              : null,
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

extension on FoInfoBanner {
  /// The title, when there is one, leads the sentence in the semibold weight;
  /// one `Text.rich` so a screen reader reads it as one sentence.
  Widget _message(BuildContext context, String text, Color ink) {
    final TextStyle style = context.foText.body.copyWith(color: ink);
    final String? lead = title;
    if (lead == null) return Text(text, style: style);
    if (_stackTitle) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(lead, style: context.foText.subtitle.copyWith(color: ink)),
          SizedBox(height: context.foSpacing.xs),
          Text(text, style: style),
        ],
      );
    }
    return Text.rich(
      TextSpan(
        children: <InlineSpan>[
          TextSpan(
            text: '$lead ',
            style: style.copyWith(fontWeight: FontWeight.w600),
          ),
          TextSpan(text: text),
        ],
      ),
      style: style,
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

  /// Nothing is wrong and nothing is news — "Already scanned. Nothing
  /// changed.", "Removed BNDL-1005-M-001". Quieter than info, so a scan
  /// result that changed nothing does not shout.
  neutral,
}

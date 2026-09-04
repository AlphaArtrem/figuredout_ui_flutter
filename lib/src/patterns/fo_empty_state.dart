import 'package:flutter/material.dart';

import '../primitives/fo_button.dart';
import '../theme/fo_context.dart';
import '../tokens/fo_tokens.dart';

/// The placeholder for empty, no-results and failed surfaces.
///
/// One component for all three because they are the same moment from the
/// user's side — *there is nothing here* — and only the reason differs. Left
/// to separate components they drift, and a screen ends up telling you three
/// different ways that it has no rows.
///
/// **An error state without an action is a dead end.** `FoEmptyState.error`
/// takes [onAction] as its retry; a screen that cannot retry should say what
/// the user should do instead.
class FoEmptyState extends StatelessWidget {
  /// Nothing here yet — first use.
  const FoEmptyState({
    required this.icon,
    required this.title,
    this.hint,
    this.actionLabel,
    this.onAction,
    this.actionIcon,
    super.key,
  }) : _isError = false;

  /// A search or filter produced no rows.
  const FoEmptyState.noResults({
    required this.title,
    this.icon = Icons.search_off_outlined,
    this.hint,
    this.actionLabel,
    this.onAction,
    this.actionIcon,
    super.key,
  }) : _isError = false;

  /// Loading failed. [onAction] is the retry.
  const FoEmptyState.error({
    required this.title,
    this.icon = Icons.cloud_off_outlined,
    this.hint,
    this.actionLabel,
    this.onAction,
    this.actionIcon,
    super.key,
  }) : _isError = true;

  /// The mark at the top. Something recognisable at a glance, not decorative.
  final IconData icon;

  /// One line saying what is missing. Caller-supplied, so it can be localized.
  final String title;

  /// One more line saying what to do about it.
  final String? hint;

  /// The action's label. Both this and [onAction] are needed for a button.
  final String? actionLabel;

  /// What the action does.
  final VoidCallback? onAction;

  /// The action's icon. Defaults to a refresh arrow on an error and a plus
  /// elsewhere — pass it whenever the action is not "add something".
  final IconData? actionIcon;

  final bool _isError;

  /// The circle's diameter, and the icon's size inside it.
  static const double _markSize = 64;

  @override
  Widget build(BuildContext context) {
    final Color accent =
        _isError ? context.foColors.danger : context.foColors.primary;

    final Widget content = Center(
      child: Padding(
        padding: EdgeInsets.all(context.foSpacing.xl),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: _markSize,
                height: _markSize,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: FoTokens.softWashAlpha),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: FoTokens.iconMedium, color: accent),
              ),
              SizedBox(height: context.foSpacing.lg),
              Text(
                title,
                textAlign: TextAlign.center,
                style: context.foText.subtitle,
              ),
              if (hint != null) ...<Widget>[
                SizedBox(height: context.foSpacing.sm),
                Text(
                  hint!,
                  textAlign: TextAlign.center,
                  style: context.foText.body.copyWith(
                    color: context.foColors.fgMuted,
                  ),
                ),
              ],
              if (actionLabel != null && onAction != null) ...<Widget>[
                SizedBox(height: context.foSpacing.xl),
                FoButton(
                  label: actionLabel!,
                  variant: FoButtonVariant.primary,
                  icon: actionIcon ?? (_isError ? Icons.refresh : Icons.add),
                  onPressed: onAction,
                ),
              ],
            ],
          ),
        ),
      ),
    );

    // **It scrolls when it does not fit, and is centred when it does.**
    //
    // The column is `MainAxisSize.min`, so it takes what it needs and paints
    // past the bottom of whatever it was given. At twice the system text size
    // a mark, a title, a hint and a button no longer fit on a phone, and an
    // empty state is exactly the screen somebody at that text size is most
    // likely to be reading — it is what the app shows before there is any
    // content to look at instead.
    //
    // `minHeight` is what keeps the ordinary case identical: a `Center` under
    // an unbounded height shrink-wraps to its child and is then stretched to
    // the constraint, so a short state sits in the middle of the viewport
    // exactly as it did before.
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints viewport) {
        // **An unbounded height is not an error here.** This pattern is put
        // inside a `Column` and inside a `ListView` by callers; a scroll view
        // in either would assert, and there is nothing to overflow in the
        // first place because the parent is already growing to fit.
        if (!viewport.hasBoundedHeight) return content;

        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: viewport.maxHeight),
            child: content,
          ),
        );
      },
    );
  }
}

import 'package:flutter/material.dart';

import '../primitives/fo_button.dart';
import '../primitives/fo_focus_ring.dart';
import '../theme/fo_context.dart';
import '../tokens/fo_layout.dart';
import '../tokens/fo_tokens.dart';
import 'fo_info_banner.dart';
import 'fo_toolbar.dart';

/// The row of filter controls above a list, with a clear-all action.
///
/// The clear action appears only when something is actually filtered. A
/// permanently visible "Clear filters" reads as an available action and gives
/// no signal about whether the list in front of you is the whole list — which
/// is the one question a filter bar exists to answer.
///
/// **Filters apply on change**, by default: a list narrows the moment a value
/// is picked. A report whose query is expensive sets [onApply] instead — the
/// filters are staged, an Apply button runs them, and [pendingMessage] says,
/// while staged changes are not yet applied, that the figures below are still
/// for the last ones — "You changed the dates. The numbers below are still
/// for the dates you applied. Press Apply to update them." Never let a page
/// show figures for one set of filters under another without saying so.
class FoFilterBar extends StatelessWidget {
  /// Creates a filter bar.
  const FoFilterBar({
    required this.children,
    required this.hasActiveFilters,
    required this.clearLabel,
    this.onClear,
    this.onApply,
    this.applyLabel,
    this.pendingMessage,
    super.key,
  }) : assert(
          onApply == null || applyLabel != null,
          'applyLabel is required when onApply is set.',
        );

  /// The filter controls.
  final List<Widget> children;

  /// Whether any filter is set. Drives the clear action's visibility.
  final bool hasActiveFilters;

  /// The clear action's label. Caller-supplied, so it can be localized.
  final String clearLabel;

  /// Clears every filter.
  final VoidCallback? onClear;

  /// Runs staged filters — the apply-mode bar. Null applies on change.
  final VoidCallback? onApply;

  /// The apply button's word — "Apply".
  final String? applyLabel;

  /// Shown under the bar while staged filters are not yet applied.
  final String? pendingMessage;

  @override
  Widget build(BuildContext context) {
    final Widget? clearAction = hasActiveFilters && onClear != null
        ? TextButton.icon(
            onPressed: onClear,
            icon: const Icon(Icons.clear, size: FoTokens.iconSmall),
            label: Text(clearLabel),
          )
        : null;

    // One row, never wrapped: filters that do not fit scroll sideways.
    final Widget controls = FoToolbar(
      filters: <Widget>[
        ...children,
        if (onApply != null)
          FoButton(
            label: applyLabel!,
            variant: FoButtonVariant.primary,
            icon: Icons.refresh,
            onPressed: onApply,
          ),
        if (clearAction != null) clearAction,
      ],
    );

    final Widget bar = Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: context.foSpacing.lg,
        vertical: context.foSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: context.foColors.surface,
        border: Border(bottom: BorderSide(color: context.foColors.edge)),
      ),
      child: controls,
    );

    final String? pending = pendingMessage;
    if (pending == null) return bar;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        bar,
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: context.foSpacing.lg,
            vertical: context.foSpacing.sm,
          ),
          child: FoInfoBanner(message: pending),
        ),
      ],
    );
  }
}

/// One filter, as a button that says its current value — "Order: All",
/// "Last 7 days".
///
/// A filter **applies on change**: pressing this opens whatever chooses the
/// value (the app wires [onPressed] to `FoLookupPicker.show`, a menu, a date
/// range), and the list narrows the moment a value is picked — there is no
/// separate Apply. Showing the value on the button is what makes a set filter
/// impossible to forget: "Order: Slim Chino" is in front of somebody wondering
/// why the list is short.
///
/// [isActive] marks a value that is not the default, on the primary wash, so
/// a row of filters shows at a glance which ones are narrowing the list.
class FoFilterButton extends StatelessWidget {
  /// Creates a filter button.
  const FoFilterButton({
    required this.value,
    required this.onPressed,
    this.label,
    this.icon,
    this.isActive = false,
    super.key,
  });

  /// What is being filtered — "Order". Null for a filter whose value names
  /// itself ("Last 7 days").
  final String? label;

  /// The current value — "All". Caller-supplied.
  final String value;

  /// Opens the chooser.
  final VoidCallback? onPressed;

  /// A leading glyph — a calendar for a date range.
  final IconData? icon;

  /// The value is not the default, so this filter is narrowing the list.
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final BorderRadius radius = BorderRadius.circular(context.foRadii.md);
    final Color ink = isActive ? context.foColors.primary : context.foColors.fg;
    final String name = label == null ? value : '$label: $value';

    return Semantics(
      button: true,
      label: name,
      onTap: onPressed,
      excludeSemantics: true,
      child: FoFocusRing(
        borderRadius: radius,
        enabled: onPressed != null,
        child: Material(
          color: isActive
              ? context.foColors.primarySoft
              : context.foColors.surfaceRaised,
          borderRadius: radius,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onPressed,
            child: Container(
              constraints: const BoxConstraints(
                minHeight: FoLayout.minTouchTarget,
              ),
              padding: EdgeInsets.symmetric(horizontal: context.foSpacing.md),
              foregroundDecoration: BoxDecoration(
                borderRadius: radius,
                border: Border.all(
                  color: isActive
                      ? context.foColors.primary.withValues(
                          alpha: FoLayout.bannerEdgeOpacity,
                        )
                      : context.foColors.edgeStrong,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  if (icon != null) ...<Widget>[
                    Icon(icon, size: FoTokens.iconSmall, color: ink),
                    SizedBox(width: context.foSpacing.sm),
                  ],
                  Flexible(
                    child: Text.rich(
                      TextSpan(
                        children: <InlineSpan>[
                          if (label != null)
                            TextSpan(
                              text: '$label: ',
                              style: TextStyle(
                                color: context.foColors.fgMuted,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          TextSpan(text: value),
                        ],
                      ),
                      style: context.foText.body.copyWith(
                        color: ink,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  SizedBox(width: context.foSpacing.xs),
                  Icon(
                    Icons.expand_more,
                    size: FoTokens.iconSmall,
                    color: context.foColors.fgMuted,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The narrow search field that sits in a scaffold's control row.
///
/// Deliberately not a `FoTextField`: that one is a form field with a floating
/// label and a 56dp height, and a search box in a toolbar is neither.
class FoListSearchField extends StatelessWidget {
  /// Creates a search field.
  const FoListSearchField({
    required this.controller,
    required this.hintText,
    required this.onChanged,
    this.onSubmitted,
    this.width = 200,
    this.showBorder = true,
    super.key,
  });

  /// The text being searched for.
  final TextEditingController controller;

  /// The placeholder. Caller-supplied, so it can be localized.
  final String hintText;

  /// Called on every keystroke. Debouncing is the caller's job — the field
  /// cannot know whether the search is local or a request.
  final ValueChanged<String> onChanged;

  /// Called on submit.
  final ValueChanged<String>? onSubmitted;

  /// How wide. Fixed rather than flexible so a toolbar's other controls keep
  /// their positions as the query changes.
  final double width;

  /// Draws the field's outline. Off when the field sits inside something that
  /// already frames it.
  final bool showBorder;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: TextField(
        controller: controller,
        style: context.foText.body,
        decoration: InputDecoration(
          isDense: true,
          prefixIcon: const Icon(Icons.search, size: FoTokens.iconSmall),
          hintText: hintText,
          border: showBorder ? const OutlineInputBorder() : InputBorder.none,
        ),
        onChanged: onChanged,
        onSubmitted: onSubmitted,
      ),
    );
  }
}

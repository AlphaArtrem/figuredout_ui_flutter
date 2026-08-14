import 'package:flutter/material.dart';

import '../theme/fo_context.dart';
import '../tokens/fo_tokens.dart';

/// The row of filter controls above a list, with a clear-all action.
///
/// The clear action appears only when something is actually filtered. A
/// permanently visible "Clear filters" reads as an available action and gives
/// no signal about whether the list in front of you is the whole list — which
/// is the one question a filter bar exists to answer.
class FoFilterBar extends StatelessWidget {
  /// Creates a filter bar.
  const FoFilterBar({
    required this.children,
    required this.hasActiveFilters,
    required this.clearLabel,
    this.onClear,
    super.key,
  });

  /// The filter controls.
  final List<Widget> children;

  /// Whether any filter is set. Drives the clear action's visibility.
  final bool hasActiveFilters;

  /// The clear action's label. Caller-supplied, so it can be localized.
  final String clearLabel;

  /// Clears every filter.
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final Widget? clearAction = hasActiveFilters && onClear != null
        ? TextButton.icon(
            onPressed: onClear,
            icon: const Icon(Icons.clear, size: FoTokens.iconSmall),
            label: Text(clearLabel),
          )
        : null;

    final Widget controls = Wrap(
      spacing: context.foSpacing.md,
      runSpacing: context.foSpacing.sm,
      children: children,
    );

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: context.foSpacing.lg,
        vertical: context.foSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: context.foColors.surface,
        border: Border(bottom: BorderSide(color: context.foColors.edge)),
      ),
      child: context.foWindowClass.isAtLeastMedium
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(child: controls),
                if (clearAction != null) ...<Widget>[
                  SizedBox(width: context.foSpacing.md),
                  clearAction,
                ],
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                controls,
                if (clearAction != null) ...<Widget>[
                  SizedBox(height: context.foSpacing.sm),
                  Align(alignment: Alignment.centerLeft, child: clearAction),
                ],
              ],
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

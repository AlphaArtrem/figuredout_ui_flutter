import 'package:flutter/material.dart';

import '../primitives/fo_focus_ring.dart';
import '../theme/fo_context.dart';
import '../tokens/fo_layout.dart';
import '../tokens/fo_motion.dart';

/// One tab in a [FoStatusTabs] row.
@immutable
class FoStatusTab {
  /// Creates a tab.
  const FoStatusTab({required this.label, this.count});

  /// The status, in plain words — "Drafts", "Change requested". Never a raw
  /// slug. Caller-supplied, so it can be localized.
  final String label;

  /// How many records are in it. Null shows nothing rather than a zero: a
  /// count that has not loaded and a count of none are different things.
  final int? count;
}

/// The status tabs above a list: "All 418 · Drafts 3 · Change requested 3 ·
/// Submitted 412".
///
/// **Not a `FoSegmentedControl`.** A segment is one of two or three
/// *destinations*; these narrow the list you are already on, there are often
/// four or more, and each carries a count, because "is there anything in
/// Change requested?" is the question the row exists to answer at a glance.
///
/// On a wide window they are tabs, the current one on the primary wash; on a
/// phone, chips, the current one filled. At every width they stay in **one
/// row that scrolls sideways** — a row that wraps onto three lines pushes the
/// list itself below the fold.
///
/// The count is formatted by [countFormatter] when given — "1,401" — and is
/// read as part of the tab's name, so a screen reader hears "Drafts, 3".
class FoStatusTabs extends StatelessWidget {
  /// Creates a row of status tabs.
  const FoStatusTabs({
    required this.tabs,
    required this.selectedIndex,
    required this.onSelected,
    required this.semanticLabel,
    this.countFormatter,
    super.key,
  }) : assert(tabs.length > 0, 'a row of no tabs selects nothing');

  /// The tabs, in order. The first is usually "All".
  final List<FoStatusTab> tabs;

  /// The current tab. Out-of-range values clamp: a row showing no tab as
  /// current is a list whose user cannot tell what it is showing.
  final int selectedIndex;

  /// Called with the tab the user picked. Not called for the current one.
  final ValueChanged<int> onSelected;

  /// What the row filters — "Status". Read before the tabs.
  final String semanticLabel;

  /// Formats a count — thousands separators, say. Defaults to plain digits.
  final String Function(int count)? countFormatter;

  @override
  Widget build(BuildContext context) {
    final int current = selectedIndex.clamp(0, tabs.length - 1);
    final bool compact = !context.foWindowClass.isAtLeastMedium;

    final List<Widget> children = <Widget>[
      for (int i = 0; i < tabs.length; i++)
        _Tab(
          tab: tabs[i],
          selected: i == current,
          chip: compact,
          countText: tabs[i].count == null
              ? null
              : (countFormatter ?? (int n) => '$n')(tabs[i].count!),
          onTap: i == current ? null : () => onSelected(i),
        ),
    ];

    // **Tabs never wrap**, at any width: a second line of tabs reads as a
    // second set of tabs, and pushes the list down every time a count grows.
    // What does not fit scrolls sideways in the one row.
    final Widget row = SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: <Widget>[
          for (int i = 0; i < children.length; i++) ...<Widget>[
            if (i > 0)
              SizedBox(
                width: compact ? context.foSpacing.sm : context.foSpacing.xs,
              ),
            children[i],
          ],
        ],
      ),
    );

    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: semanticLabel,
      child: row,
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.tab,
    required this.selected,
    required this.chip,
    required this.countText,
    required this.onTap,
  });

  final FoStatusTab tab;
  final bool selected;
  final bool chip;
  final String? countText;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final BorderRadius radius = BorderRadius.circular(
      chip ? context.foRadii.pill : context.foRadii.md,
    );

    // Wide: the current tab rests on the primary wash. Phone: it is filled,
    // and the others are lifted chips with a findable edge, so a row of them
    // on a busy screen still reads as controls.
    final (Color fill, Color ink, Color countInk, Color? edge) = switch ((
      chip,
      selected,
    )) {
      (false, true) => (
          context.foColors.primarySoft,
          context.foColors.primary,
          context.foColors.primary,
          null,
        ),
      (false, false) => (
          Colors.transparent,
          context.foColors.fgMuted,
          context.foColors.fgSubtle,
          null,
        ),
      (true, true) => (
          context.foColors.primary,
          context.foColors.primaryFg,
          context.foColors.primaryFg,
          null,
        ),
      (true, false) => (
          context.foColors.surfaceRaised,
          context.foColors.fg,
          context.foColors.fgSubtle,
          context.foColors.edgeStrong,
        ),
    };

    final TextStyle labelStyle = context.foText.body.copyWith(
      color: ink,
      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
    );

    return Semantics(
      button: true,
      selected: selected,
      inMutuallyExclusiveGroup: true,
      label: countText == null ? tab.label : '${tab.label}, $countText',
      // Declared here as well as on the InkWell, because `excludeSemantics`
      // drops the InkWell's own.
      onTap: onTap,
      excludeSemantics: true,
      child: FoFocusRing(
        borderRadius: radius,
        child: Material(
          color: Colors.transparent,
          borderRadius: radius,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            borderRadius: radius,
            child: AnimatedContainer(
              duration: FoMotion.fast,
              curve: FoMotion.standard,
              constraints: const BoxConstraints(
                minHeight: FoLayout.minTouchTarget,
              ),
              padding: EdgeInsets.symmetric(horizontal: context.foSpacing.md),
              decoration: BoxDecoration(color: fill, borderRadius: radius),
              foregroundDecoration: edge == null
                  ? null
                  : BoxDecoration(
                      borderRadius: radius,
                      border: Border.all(color: edge),
                    ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  // In a sideways scroll there is no width to flex against,
                  // so the label sizes itself and never wraps.
                  Text(tab.label, style: labelStyle, softWrap: false),
                  if (countText != null) ...<Widget>[
                    SizedBox(width: context.foSpacing.sm),
                    Text(
                      countText!,
                      style: context.foText.numeric.copyWith(
                        fontSize: context.foText.caption.fontSize,
                        color: countInk,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

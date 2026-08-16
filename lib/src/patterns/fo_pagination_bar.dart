import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../primitives/fo_focus_ring.dart';
import '../theme/fo_context.dart';
import '../tokens/fo_layout.dart';

/// The footer of a paged list or table.
///
/// The counts are formatted by the caller rather than here: "1–20 of 340" is a
/// sentence, and building it from parts inside a design system produces the
/// kind of string that cannot be translated into a language that orders it
/// differently.
///
/// The numbered track shows as many pages as the widget's own width can hold
/// — anchored on first, current and last — and drops [totalLabel] /
/// [pageLabel] below [_compactWidth] so the track keeps the room. This is
/// measured on the widget, not the window: `@figuredout/ui-web`'s
/// `Pagination` learned that the hard way (`db953bf`) — a bar can be handed a
/// narrow column on a wide screen, and the window's width says nothing about
/// that. Flutter gets the equivalent of that fix for the price of one
/// `Expanded` + `LayoutBuilder`: unlike a browser, a `Row` already subtracts
/// its inflexible siblings' widths before handing a flex child its
/// constraints, so there is no ResizeObserver-style measurement to hand-roll.
///
/// The arrows stay icon-only at every width — Luxe's original never grew a
/// visible "Previous" / "Next" label, and adding one now would mean new
/// required copy this design does not otherwise need.
class FoPaginationBar extends StatelessWidget {
  /// Creates a pagination bar.
  const FoPaginationBar({
    required this.page,
    required this.totalPages,
    required this.totalLabel,
    required this.pageLabel,
    required this.previousTooltip,
    required this.nextTooltip,
    required this.pageSemanticLabel,
    required this.onPageChanged,
    super.key,
  });

  /// The current page, 1-based.
  final int page;

  /// How many pages there are. Clamped to at least one, so an empty result
  /// reads "page 1 of 1" rather than "1 of 0".
  final int totalPages;

  /// The total, already worded — "340 entries". Hidden below
  /// [_compactWidth].
  final String totalLabel;

  /// The position, already worded — "Page 2 of 17". Hidden below
  /// [_compactWidth] — the track's own highlighted tile carries the same
  /// information at that width.
  final String pageLabel;

  /// The back button's tooltip.
  final String previousTooltip;

  /// The forward button's tooltip.
  final String nextTooltip;

  /// One page tile's accessible name — `(page) => 'Page $page'`.
  /// Caller-supplied, so it can be localized; a bare number read by a screen
  /// reader announces nothing about what it is a number of.
  final String Function(int page) pageSemanticLabel;

  /// Called with the new page number.
  final ValueChanged<int> onPageChanged;

  /// Below this width the labels drop and only the arrows and the numbered
  /// track remain. Mirrors the web package's `COMPACT_WIDTH`.
  static const double _compactWidth = 480;

  /// A page tile's side, and the touch target it sits inside — the shop-floor
  /// minimum, same as everywhere else a tap target is sized.
  static const double _pageTile = FoLayout.minTouchTarget;

  /// The gap between tiles inside the track.
  static const double _tileGap = 4;

  /// The track's own padding, all four sides.
  static const double _trackPadding = 4;

  /// The most either label may claim before it ellipsises. Generous for
  /// "340 entries" / "Page 2 of 17" in any locale this package ships copy
  /// for, and small enough that it never meaningfully competes with the
  /// track for the row's leftover width.
  static const double _labelCap = 160;

  @override
  Widget build(BuildContext context) {
    final int pages = math.max(1, totalPages);
    final int current = page.clamp(1, pages);
    final FoSpacing spacing = context.foSpacing;

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints outer) {
        final bool compact = outer.maxWidth < _compactWidth;

        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: spacing.lg,
            vertical: spacing.sm,
          ),
          decoration: BoxDecoration(
            color: context.foColors.surface,
            border: Border(top: BorderSide(color: context.foColors.edge)),
          ),
          child: Row(
            children: <Widget>[
              if (!compact) ...<Widget>[
                // A capped ConstrainedBox, not Flexible: `Flexible` defaults
                // to the same flex weight as the track's `Expanded` below,
                // so the two would split the leftover space evenly rather
                // than the track getting what these short strings do not
                // need. The cap only bites on a pathologically long string —
                // "340 entries" never gets near it — and is what still
                // shrinks one gracefully rather than overflowing the row.
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: _labelCap),
                  child: Text(
                    totalLabel,
                    style: context.foText.label,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(width: spacing.md),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: _labelCap),
                  child: Text(
                    pageLabel,
                    style: context.foText.numeric,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(width: spacing.lg),
              ],
              IconButton(
                icon: const Icon(Icons.chevron_left),
                tooltip: previousTooltip,
                onPressed:
                    current > 1 ? () => onPageChanged(current - 1) : null,
              ),
              SizedBox(width: spacing.sm),
              // `Expanded` is what makes this a leftover-space measurement
              // rather than a full-width one: a Row already subtracts the
              // fixed-size arrows either side before this LayoutBuilder sees
              // its constraints.
              Expanded(
                child: LayoutBuilder(
                  builder: (BuildContext context, BoxConstraints trackBox) {
                    final int slots = _slotsFor(trackBox.maxWidth);
                    final List<int> visible =
                        _visiblePages(current, pages, slots);
                    return Align(
                      alignment: compact
                          ? Alignment.center
                          : AlignmentDirectional.centerEnd,
                      child: _Track(
                        pages: visible,
                        current: current,
                        pageSemanticLabel: pageSemanticLabel,
                        onSelect: onPageChanged,
                      ),
                    );
                  },
                ),
              ),
              SizedBox(width: spacing.sm),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                tooltip: nextTooltip,
                onPressed:
                    current < pages ? () => onPageChanged(current + 1) : null,
              ),
            ],
          ),
        );
      },
    );
  }

  /// How many page tiles fit in [availableWidth].
  static int _slotsFor(double availableWidth) {
    if (!availableWidth.isFinite || availableWidth <= 0) return 1;
    final double inner = availableWidth - _trackPadding * 2;
    final double raw = (inner + _tileGap) / (_pageTile + _tileGap);
    return math.max(1, raw.floor());
  }

  /// The pages worth showing when only [slots] of them fit.
  ///
  /// First and last are the anchors — the last one doubles as the total —
  /// and the rest of the budget grows outwards from [current]. Ported from
  /// `@figuredout/ui-web`'s `getVisiblePages` (`db953bf`).
  static List<int> _visiblePages(int current, int total, int slots) {
    final int budget = math.max(1, math.min(slots, total));
    final Set<int> pages = <int>{current};

    if (budget >= 2) pages.add(total);
    if (budget >= 3) pages.add(1);

    int low = current;
    int high = current;
    while (pages.length < budget && (low > 1 || high < total)) {
      if (high < total) {
        high += 1;
        pages.add(high);
      }
      if (pages.length < budget && low > 1) {
        low -= 1;
        pages.add(low);
      }
    }

    return pages.toList()..sort();
  }
}

/// The numbered track — the same sunken-well idiom as a segmented control,
/// with the current page raised out of it.
class _Track extends StatelessWidget {
  const _Track({
    required this.pages,
    required this.current,
    required this.pageSemanticLabel,
    required this.onSelect,
  });

  final List<int> pages;
  final int current;
  final String Function(int page) pageSemanticLabel;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.foColors.surfaceSunken,
        borderRadius: BorderRadius.circular(context.foRadii.card),
        border: Border.all(color: context.foColors.edge),
      ),
      child: Padding(
        padding: const EdgeInsets.all(FoPaginationBar._trackPadding),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            for (final int page in pages) ...<Widget>[
              _PageTile(
                page: page,
                selected: page == current,
                semanticLabel: pageSemanticLabel(page),
                onTap: () => onSelect(page),
              ),
              if (page != pages.last)
                const SizedBox(width: FoPaginationBar._tileGap),
            ],
          ],
        ),
      ),
    );
  }
}

/// One tile in the track.
class _PageTile extends StatelessWidget {
  const _PageTile({
    required this.page,
    required this.selected,
    required this.semanticLabel,
    required this.onTap,
  });

  final int page;
  final bool selected;
  final String semanticLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final BorderRadius radius = BorderRadius.circular(context.foRadii.md);

    return Semantics(
      button: true,
      selected: selected,
      label: semanticLabel,
      excludeSemantics: true,
      child: FoFocusRing(
        borderRadius: radius,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onTap,
            borderRadius: radius,
            child: Container(
              constraints: const BoxConstraints(
                minWidth: FoPaginationBar._pageTile,
                minHeight: FoPaginationBar._pageTile,
              ),
              alignment: Alignment.center,
              padding: EdgeInsets.symmetric(
                horizontal: context.foSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: selected ? context.foColors.primary : null,
                borderRadius: radius,
              ),
              child: Text(
                '$page',
                style: context.foText.numeric.copyWith(
                  color: selected
                      ? context.foColors.primaryFg
                      : context.foColors.fgMuted,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

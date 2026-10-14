import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../primitives/fo_focus_ring.dart';
import '../theme/fo_context.dart';
import '../tokens/fo_layout.dart';
import '../tokens/fo_tokens.dart';

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
/// **Rows per page (0.8.0, optional).** Pass [pageSize], [pageSizeOptions],
/// [onPageSizeChanged], [pageSizeLabel] and [pageSizeSemanticLabel] together
/// and a compact menu — "20 per page" — is drawn left of the numbered track.
/// The package holds no words for it: every string is the caller's. It is left
/// out below the compact width, and wherever the room left of the arrows
/// could not hold it and still leave the track three tiles. Pass none of them
/// and the bar is exactly what it was.
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
    this.pageSize,
    this.pageSizeOptions = const <int>[],
    this.onPageSizeChanged,
    this.pageSizeLabel,
    this.pageSizeSemanticLabel,
    super.key,
  })  : assert(
          (pageSize == null) == (onPageSizeChanged == null) &&
              (pageSize == null) == (pageSizeLabel == null) &&
              (pageSize == null) == (pageSizeSemanticLabel == null),
          'pageSize, onPageSizeChanged, pageSizeLabel and '
          'pageSizeSemanticLabel go together: a rows-per-page menu needs a '
          'value, a callback and the caller\'s words.',
        ),
        assert(
          pageSize == null || pageSizeOptions.length > 0,
          'pageSizeOptions must list the choices.',
        );

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

  /// Rows per page now. Null (the default) draws no rows-per-page menu.
  final int? pageSize;

  /// The sizes the menu offers — `[20, 50, 100]`. The current [pageSize] is
  /// ticked when it is one of them.
  final List<int> pageSizeOptions;

  /// Called with the size picked. The caller decides whether that returns to
  /// page 1 (it almost always should).
  final ValueChanged<int>? onPageSizeChanged;

  /// A size worded — `(n) => '$n per page'`. Caller-supplied, so it can be
  /// localized; it names the menu's button and each of its choices.
  final String Function(int size)? pageSizeLabel;

  /// The menu button's accessible name and tooltip — "Rows per page".
  final String? pageSizeSemanticLabel;

  /// The widest the rows-per-page button gets before its label ellipsises.
  static const double _sizeMenuMaxWidth = 148;

  /// The fewest page tiles the track keeps when the menu takes room: below
  /// this the menu is left out rather than the track squeezed to one tile.
  static const int _minSlotsWithMenu = 3;

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
                    final int? size = pageSize;
                    // The menu is measured against the room left of the
                    // arrows, not the window: it stays only if the track
                    // still holds [_minSlotsWithMenu] tiles beside it.
                    final bool sizeMenu = !compact &&
                        size != null &&
                        _slotsFor(
                              trackBox.maxWidth -
                                  _sizeMenuMaxWidth -
                                  spacing.md,
                            ) >=
                            _minSlotsWithMenu;
                    final int slots = _slotsFor(
                      sizeMenu
                          ? trackBox.maxWidth - _sizeMenuMaxWidth - spacing.md
                          : trackBox.maxWidth,
                    );
                    final List<int> visible =
                        _visiblePages(current, pages, slots);
                    final Widget track = Align(
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
                    if (!sizeMenu) return track;
                    return Row(
                      children: <Widget>[
                        ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxWidth: _sizeMenuMaxWidth,
                          ),
                          child: _PageSizeMenu(
                            value: size,
                            options: pageSizeOptions,
                            label: pageSizeLabel!,
                            semanticLabel: pageSizeSemanticLabel!,
                            onChanged: onPageSizeChanged!,
                          ),
                        ),
                        SizedBox(width: spacing.md),
                        Expanded(child: track),
                      ],
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

/// The rows-per-page menu: a sunken button naming the size, a menu of sizes.
class _PageSizeMenu extends StatelessWidget {
  const _PageSizeMenu({
    required this.value,
    required this.options,
    required this.label,
    required this.semanticLabel,
    required this.onChanged,
  });

  final int value;
  final List<int> options;
  final String Function(int size) label;
  final String semanticLabel;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final BorderRadius radius = BorderRadius.circular(context.foRadii.md);
    return FoFocusRing(
      borderRadius: radius,
      child: PopupMenuButton<int>(
        tooltip: semanticLabel,
        initialValue: value,
        onSelected: onChanged,
        itemBuilder: (BuildContext context) => <PopupMenuEntry<int>>[
          for (final int option in options)
            CheckedPopupMenuItem<int>(
              value: option,
              checked: option == value,
              child: Text(label(option)),
            ),
        ],
        child: Semantics(
          button: true,
          label: semanticLabel,
          value: label(value),
          excludeSemantics: true,
          child: Container(
            constraints: const BoxConstraints(
              minHeight: FoPaginationBar._pageTile,
            ),
            padding: EdgeInsets.only(left: context.foSpacing.md),
            decoration: BoxDecoration(
              color: context.foColors.surfaceSunken,
              borderRadius: radius,
              border: Border.all(color: context.foColors.edge),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Flexible(
                  child: Text(
                    label(value),
                    style: context.foText.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(
                  Icons.arrow_drop_down,
                  size: FoTokens.iconMedium,
                  color: context.foColors.fgMuted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
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

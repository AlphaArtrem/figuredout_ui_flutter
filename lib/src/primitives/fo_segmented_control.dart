import 'package:flutter/material.dart';

import '../theme/fo_context.dart';
import '../tokens/fo_layout.dart';
import '../tokens/fo_motion.dart';
import 'fo_focus_ring.dart';

/// Two or three named destinations, side by side, with exactly one selected.
///
/// **A segment is a destination, not a filter**, and that distinction is the
/// whole reason this is a component rather than two buttons. A filter is
/// something you set and can forget you set; a segment is a place you are, it
/// is always visible, and the one you are in is legible without opening
/// anything. The consuming app's rule says it directly: *"if someone needs a
/// set of records regularly, it is a tab or a segment — a fixed place, always
/// in the same spot, labelled in plain words."*
///
/// Three things here are decisions rather than details.
///
/// **The track is `surfaceSunken` and the selected segment is `surface`.**
/// That is rule 6 read literally: the track is a hole and the current segment
/// rests in it. `docs/components.md` has reserved
/// `surfaceSunken` for "segmented-control tracks" since before this existed —
/// the token was waiting for the component.
///
/// **There is no unselected state and no third state.** [selectedIndex] is
/// required and non-null, because a segmented control showing neither option as
/// current is a control whose user cannot tell where they are. A screen that
/// genuinely has a "neither" needs a filter, which is a different component and
/// a different promise.
///
/// **Two or three segments.** Four is a tab bar, and at four the labels stop
/// fitting on a phone in a script that runs longer than English — asserted
/// rather than left to a reviewer.
///
/// The component holds no copy: every label is caller-supplied so it can be
/// localized, and it wraps rather than ellipsises, because a Devanagari label
/// is longer than the English one it was sized against.
class FoSegmentedControl extends StatelessWidget {
  /// Creates a segmented control.
  const FoSegmentedControl({
    required this.segments,
    required this.selectedIndex,
    required this.onSelected,
    this.semanticLabel,
    super.key,
  })  : assert(
          segments.length >= 2 && segments.length <= 3,
          'A segmented control carries two or three destinations. One has '
          'nothing to choose; four is a tab bar, and four labels do not fit a '
          'phone in a script that runs longer than English.',
        ),
        assert(
          selectedIndex >= 0,
          'A segmented control always has a current segment. There is no '
          '"neither" — a control that shows no destination as current is one '
          'whose user cannot tell where they are.',
        );

  /// The destinations, in order. Two or three.
  final List<FoSegment> segments;

  /// Which one the user is in. Always one of them.
  final int selectedIndex;

  /// Called with the index the user asked for. Not called for the current one:
  /// tapping where you already are is not a navigation.
  final ValueChanged<int> onSelected;

  /// What a screen reader announces for the group — "Case list". Each segment
  /// announces its own label and whether it is selected.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final int current = selectedIndex.clamp(0, segments.length - 1);

    return Semantics(
      container: true,
      label: semanticLabel,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: context.foColors.surfaceSunken,
          borderRadius: BorderRadius.circular(context.foRadii.md),
        ),
        child: Padding(
          padding: EdgeInsets.all(context.foSpacing.xs),
          child: Row(
            children: <Widget>[
              for (int i = 0; i < segments.length; i++)
                Expanded(
                  child: _Segment(
                    segment: segments[i],
                    selected: i == current,
                    // Tapping the current segment does nothing, deliberately.
                    // It is where you already are, and firing the callback
                    // would reload a list under somebody's thumb.
                    onTap: i == current ? null : () => onSelected(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One destination in a [FoSegmentedControl].
@immutable
class FoSegment {
  /// Creates a segment.
  const FoSegment({required this.label, this.count, this.icon});

  /// The destination's name, in plain words. Caller-supplied, so it can be
  /// localized.
  final String label;

  /// How many records are in it, shown after the label.
  ///
  /// Optional and worth having: *"Disposed"* is a place, *"Disposed 41"* tells
  /// somebody whether it is worth going there. Null shows nothing at all
  /// rather than a zero — a count that is not loaded yet and a count of none
  /// are different things, and a bare zero reads as the second.
  final int? count;

  /// An optional glyph before the label.
  final IconData? icon;
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.segment,
    required this.selected,
    required this.onTap,
  });

  final FoSegment segment;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final BorderRadius radius = BorderRadius.circular(context.foRadii.sm);
    final Color fg = selected ? context.foColors.fg : context.foColors.fgMuted;

    return Semantics(
      button: true,
      selected: selected,
      label: segment.label,
      // Declared here as well as on the InkWell, because `excludeSemantics`
      // drops the InkWell's own — and without it a screen-reader user could
      // read the segments and activate none of them. The package's test caught
      // that; a review would not have.
      onTap: onTap,
      // One button, not a button containing a label and a splash. The count is
      // folded into the label above rather than announced as a second node.
      excludeSemantics: true,
      child: FoFocusRing(
        borderRadius: radius,
        child: Material(
          // Transparent, not a surface: the selected fill is the animated
          // container below, so that moving between segments is one crossfade
          // rather than two.
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
              alignment: Alignment.center,
              padding: EdgeInsets.symmetric(
                horizontal: context.foSpacing.sm,
                vertical: context.foSpacing.xs,
              ),
              decoration: BoxDecoration(
                // The selected segment *rests* in the hole. Rule 6: never a
                // lighter surface for emphasis — this one is emphatic because
                // it is on a different step of the ladder, not because it is
                // brighter.
                color: selected ? context.foColors.surface : Colors.transparent,
                borderRadius: radius,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  if (segment.icon != null) ...<Widget>[
                    Icon(segment.icon, size: 18, color: fg),
                    SizedBox(width: context.foSpacing.xs),
                  ],
                  Flexible(
                    child: Text(
                      segment.count == null
                          ? segment.label
                          : '${segment.label} ${segment.count}',
                      textAlign: TextAlign.center,
                      // Wraps rather than ellipsises. A Devanagari label is
                      // longer than the English one it was sized against, and
                      // "निस्ता…" is not a destination anybody can read.
                      style: (selected
                              ? context.foText.subtitle
                              : context.foText.body)
                          .copyWith(color: fg),
                    ),
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

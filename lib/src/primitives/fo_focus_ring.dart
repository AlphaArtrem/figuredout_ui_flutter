import 'package:flutter/material.dart';

import '../theme/fo_context.dart';
import '../tokens/fo_layout.dart';

/// The one focus treatment: a 4dp ring in `focusRing`.
///
/// Flutter has no global focus ring — every Material widget invents its own,
/// which is how an app ends up with a blue overlay on a `TextButton`, a
/// coloured border on an `IconButton` and nothing at all on a custom tile.
/// Every interactive Fo component composes this instead, so keyboard focus
/// looks like one idea rather than five.
///
/// The ring is painted through `foregroundDecoration` (rule §3.1): a child
/// that paints its own full-bleed background — a filled button, a tinted
/// chip — would otherwise cover a ring drawn beneath it.
///
/// It reports focus for the whole subtree, so wrapping a `FilledButton` works
/// without threading a [FocusNode] through: the wrapper's node is not itself
/// focusable, it only observes.
class FoFocusRing extends StatefulWidget {
  /// Wraps [child] in the standard focus ring.
  const FoFocusRing({
    required this.child,
    this.borderRadius,
    this.enabled = true,
    super.key,
  });

  /// The interactive thing being focused.
  final Widget child;

  /// The ring's corners. Defaults to the button/field radius, which is the
  /// shape most things that take focus already have.
  final BorderRadius? borderRadius;

  /// When false the ring never paints — for a control that is disabled, or
  /// one that draws its own (a text field's focused border, say).
  final bool enabled;

  @override
  State<FoFocusRing> createState() => _FoFocusRingState();
}

class _FoFocusRingState extends State<FoFocusRing> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final BorderRadius radius =
        widget.borderRadius ?? BorderRadius.circular(context.foRadii.md);
    final bool show = widget.enabled && _focused;

    return Focus(
      // Observe only: this node must never take focus itself, or it would
      // insert a stop into the traversal order that the user cannot see.
      canRequestFocus: false,
      skipTraversal: true,
      onFocusChange: (bool hasFocus) {
        if (hasFocus == _focused) return;
        setState(() => _focused = hasFocus);
      },
      child: DecoratedBox(
        position: DecorationPosition.foreground,
        decoration: show
            ? BoxDecoration(
                borderRadius: radius,
                border: Border.all(
                  color: context.foColors.focusRing,
                  width: FoLayout.focusRingWidth,
                ),
              )
            : const BoxDecoration(),
        child: widget.child,
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../theme/fo_context.dart';
import 'fo_focus_ring.dart';

/// The resting surface: a card, a panel, a framed region.
///
/// Deliberately **not** built on Material's [Card]. Two reasons, and both are
/// rules rather than preferences:
///
/// **The hairline goes in `foregroundDecoration`, never `decoration.border`.**
/// `Card`'s hairline comes from its `shape`, which paints *under* its
/// children. A card whose child paints a full-bleed band — a tinted header, a
/// footer bar, a table's header row — loses its hairline along that edge, and
/// the symptom (a card that looks like it is missing one line) is nothing like
/// the cause. `FoSectionSurface` is exactly that shape, which is why this is
/// load-bearing and not fussiness.
///
/// **Elevation is painted here, not by Material.** `Card(elevation:)` draws a
/// black shadow plus a primary-hued surface tint. On a tinted ground the black
/// greys out the colour beneath it and reads as dirt, and the tint fights the
/// surface ladder. `FoShadows` is hue-matched instead.
///
/// A card with an [onTap] lifts on hover — `surfaceRaised` with
/// `FoShadows.hover` — because a hovered thing has been picked up. That is the
/// ladder doing its job, not decoration.
class FoCard extends StatefulWidget {
  /// Creates a card.
  const FoCard({
    required this.child,
    this.padding,
    this.onTap,
    this.semanticLabel,
    this.tone = FoCardTone.resting,
    super.key,
  });

  /// The card's contents.
  final Widget child;

  /// Inner padding. Defaults to `foSpacing.lg` on all sides; pass
  /// [EdgeInsets.zero] when the child owns its own edges, as
  /// `FoSectionSurface` does.
  final EdgeInsetsGeometry? padding;

  /// Makes the whole card one tap target. Adds the hover lift and a focus
  /// ring; without it the card is inert and takes no focus.
  final VoidCallback? onTap;

  /// What tapping the card does, for a screen reader. Only meaningful with
  /// [onTap].
  final String? semanticLabel;

  /// Which step of the ladder the card sits on. [FoCardTone.raised] is for a
  /// card that *is* the overlay — a dialog's body, a menu's frame — not for a
  /// card that wants a bit more emphasis. Reaching for a lighter surface to
  /// create emphasis is the one thing the ladder forbids.
  final FoCardTone tone;

  @override
  State<FoCard> createState() => _FoCardState();
}

class _FoCardState extends State<FoCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final BorderRadius radius = BorderRadius.circular(context.foRadii.card);
    final bool interactive = widget.onTap != null;
    final bool lifted = interactive && _hovered;

    final Widget content = Padding(
      padding: widget.padding ?? EdgeInsets.all(context.foSpacing.lg),
      child: widget.child,
    );

    final bool raised = widget.tone == FoCardTone.raised;
    final Widget surface = DecoratedBox(
      decoration: BoxDecoration(
        color: raised || lifted
            ? context.foColors.surfaceRaised
            : context.foColors.surface,
        borderRadius: radius,
        boxShadow: raised
            ? context.foShadows.overlay
            : lifted
                ? context.foShadows.hover
                : context.foShadows.raised,
      ),
      // Rule §3.1. The clip below means a child's own background would cover
      // a border drawn in `decoration`; painting it in the foreground puts it
      // back on top where a hairline belongs.
      child: DecoratedBox(
        position: DecorationPosition.foreground,
        decoration: BoxDecoration(
          borderRadius: radius,
          border: Border.all(color: context.foColors.edge),
        ),
        child: ClipRRect(
          borderRadius: radius,
          // InkWell needs a Material ancestor to splash into, and this card
          // is not built on one. Material's own Card supplied it implicitly;
          // dropping it left an interactive card crashing anywhere outside a
          // Scaffold, which is exactly what a design-system component must
          // not do. Transparent, so the fill above still shows through.
          child: interactive
              ? Material(
                  type: MaterialType.transparency,
                  child: InkWell(
                    onTap: widget.onTap,
                    onHover: (bool value) {
                      if (value == _hovered) return;
                      setState(() => _hovered = value);
                    },
                    child: content,
                  ),
                )
              : content,
        ),
      ),
    );

    if (!interactive) return surface;

    return Semantics(
      button: true,
      label: widget.semanticLabel,
      child: FoFocusRing(borderRadius: radius, child: surface),
    );
  }
}

/// Which step of the surface ladder a [FoCard] sits on.
enum FoCardTone {
  /// On the page: a card, a panel, a framed region. The default, and almost
  /// always the right answer.
  resting,

  /// Covering the page: the body of a dialog or a sheet. Pairs `surfaceRaised`
  /// with the overlay shadow, which is the same treatment `foOverlaySurface`
  /// gives a menu — the two are the same object seen from different sides.
  raised,
}

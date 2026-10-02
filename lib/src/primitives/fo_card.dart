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
    this.labelReplacesContent = false,
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
  ///
  /// By default it is **merged** with the card's content: the announcement is
  /// the label, then everything the content says. A label that repeats the
  /// content's own words is therefore read twice ("Roles, Roles") — see
  /// [labelReplacesContent].
  final String? semanticLabel;

  /// Whether [semanticLabel] **replaces** the content in the announcement,
  /// the way `aria-label` replaces a button's text on the web, so a labelled
  /// card is read once.
  ///
  /// Opt-in, because replacing drops everything the content would have said
  /// — a status chip, a count, a date — **and makes any button inside the
  /// card unreachable to a screen reader**. Set it only where the label is
  /// the card's complete summary and the card holds nothing tappable of its
  /// own. A consuming app's audit found most of its labelled cards were
  /// neither, which is why replacing is not the default.
  final bool labelReplacesContent;

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

    // A card whose label replaces its content is one control with one name.
    // The content's own semantics are excluded *inside* the InkWell, so the
    // tap action, the button role and focus survive while the words are not
    // read a second time after the label.
    final bool labelled = interactive &&
        widget.semanticLabel != null &&
        widget.labelReplacesContent;
    final Widget content = Padding(
      padding: widget.padding ?? EdgeInsets.all(context.foSpacing.lg),
      child: ExcludeSemantics(excluding: labelled, child: widget.child),
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
          // A Material *inside* the fill, always — not only when the card is
          // interactive. Two things need it. An InkWell has nothing to splash
          // into otherwise, so a tappable card crashed anywhere outside a
          // Scaffold. And any Material child the caller puts in — a ListTile,
          // a Switch — paints its ink on the nearest Material ancestor, which
          // without this is *above* the fill above, so the ink lands behind
          // the card and Flutter asserts about it. Transparent, so the fill
          // still shows through.
          child: Material(
            type: MaterialType.transparency,
            child: interactive
                ? InkWell(
                    onTap: widget.onTap,
                    onHover: (bool value) {
                      if (value == _hovered) return;
                      setState(() => _hovered = value);
                    },
                    child: content,
                  )
                : content,
          ),
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

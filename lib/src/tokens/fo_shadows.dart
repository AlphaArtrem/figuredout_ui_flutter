import 'package:flutter/material.dart';

import 'fo_tokens.dart';

/// The three elevation steps, exposed via `context.foShadows`.
///
/// **Three, and no more.** [raised] rests, [hover] is picked up, [overlay]
/// covers something else. There is deliberately no fourth step and no
/// `Material(elevation:)` anywhere in the package: Material's elevation model
/// paints a black shadow plus a surface tint, and a black shadow on a tinted
/// ground greys out the colour beneath it and reads as dirt. These are
/// hue-matched to the ground instead, which is also why they can run at a
/// lower opacity — they are not fighting pure white to be seen.
///
/// A note on porting: CSS `blur-radius` and Flutter's [BoxShadow.blurRadius]
/// do not describe the same Gaussian (CSS σ = r/2, Flutter σ ≈ 0.577r + 0.5),
/// so these render slightly *tighter* than the web original. The numbers are
/// ported 1:1 for now; compare a `FoCard` against the web `Card` side by side
/// in the Widgetbook before scaling the large radii.
@immutable
class FoShadows {
  /// Creates an elevation set. Prefer [FoShadows.light] / [FoShadows.dark].
  const FoShadows({
    required this.raised,
    required this.hover,
    required this.overlay,
  });

  /// Something at rest on the page: a card, a table, a panel.
  final List<BoxShadow> raised;

  /// Something picked up: a hovered card, a dragged row.
  final List<BoxShadow> hover;

  /// Something covering something else: a dialog, a menu, a toast, a tooltip.
  final List<BoxShadow> overlay;

  /// The light theme's elevation.
  static const FoShadows light = FoShadows(
    raised: <BoxShadow>[
      BoxShadow(
        color: FoTokens.shadowRaisedNear,
        offset: Offset(0, 1),
        blurRadius: 2,
      ),
      BoxShadow(
        color: FoTokens.shadowRaisedFar,
        offset: Offset(0, 12),
        blurRadius: 32,
      ),
    ],
    hover: <BoxShadow>[
      BoxShadow(
        color: FoTokens.shadowHoverNear,
        offset: Offset(0, 1),
        blurRadius: 2,
      ),
      BoxShadow(
        color: FoTokens.shadowHoverFar,
        offset: Offset(0, 18),
        blurRadius: 44,
      ),
    ],
    overlay: <BoxShadow>[
      BoxShadow(
        color: FoTokens.shadowOverlayNear,
        offset: Offset(0, 2),
        blurRadius: 8,
      ),
      BoxShadow(
        color: FoTokens.shadowOverlayFar,
        offset: Offset(0, 26),
        blurRadius: 64,
      ),
    ],
  );

  /// The dark theme's elevation. Black here, not hue-matched: on a near-black
  /// ground a tinted shadow has nothing to tint.
  static const FoShadows dark = FoShadows(
    raised: <BoxShadow>[
      BoxShadow(
        color: FoTokens.shadowRaisedNearDark,
        offset: Offset(0, 1),
        blurRadius: 2,
      ),
      BoxShadow(
        color: FoTokens.shadowRaisedFarDark,
        offset: Offset(0, 18),
        blurRadius: 40,
      ),
    ],
    hover: <BoxShadow>[
      BoxShadow(
        color: FoTokens.shadowHoverNearDark,
        offset: Offset(0, 1),
        blurRadius: 2,
      ),
      BoxShadow(
        color: FoTokens.shadowHoverFarDark,
        offset: Offset(0, 22),
        blurRadius: 56,
      ),
    ],
    overlay: <BoxShadow>[
      BoxShadow(
        color: FoTokens.shadowOverlayNearDark,
        offset: Offset(0, 4),
        blurRadius: 12,
      ),
      BoxShadow(
        color: FoTokens.shadowOverlayFarDark,
        offset: Offset(0, 28),
        blurRadius: 80,
      ),
    ],
  );

  /// Every step, by name — the basis of the Widgetbook elevation use case.
  Map<String, List<BoxShadow>> toMap() => <String, List<BoxShadow>>{
        'raised': raised,
        'hover': hover,
        'overlay': overlay,
      };

  /// Interpolates every step.
  static FoShadows lerp(FoShadows a, FoShadows b, double t) => FoShadows(
        raised: BoxShadow.lerpList(a.raised, b.raised, t)!,
        hover: BoxShadow.lerpList(a.hover, b.hover, t)!,
        overlay: BoxShadow.lerpList(a.overlay, b.overlay, t)!,
      );
}

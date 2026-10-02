import 'package:flutter/material.dart';

import '../theme/fo_context.dart';

/// A garment colour, as a dot: Deep Navy, Ecru, Sage.
///
/// The colour is **data**, not a token — it comes from the app's master list,
/// which is the one place a literal colour is allowed to enter a screen. The
/// dot always carries the theme's `swatchRing` — dark on a light theme, light
/// (white at 0.35) on every dark palette — so a light colour (Ecru on a white
/// card) and a dark one (Deep Navy, Jet Black on a dark card) both keep an
/// edge.
///
/// It is never the only way a colour is named: pass [semanticLabel] when the
/// dot stands alone, or leave it null when the colour's name is printed beside
/// it — then the dot is decoration and is hidden from a screen reader.
class FoColourSwatch extends StatelessWidget {
  /// Creates a swatch.
  const FoColourSwatch({
    required this.color,
    this.size = 14,
    this.semanticLabel,
    super.key,
  });

  /// The garment colour. Data from the app, not a design token.
  final Color color;

  /// The dot's diameter — 12 inline with a caption, 14 in a table, 24–28 on a
  /// choice.
  final double size;

  /// The colour's name, when nothing beside the dot says it.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final Widget dot = Center(
// A circle stays a circle under any constraints (see FoDisc).
      widthFactor: 1,
      heightFactor: 1,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        foregroundDecoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: context.foColors.swatchRing),
        ),
      ),
    );
    if (semanticLabel == null) return ExcludeSemantics(child: dot);
    return Semantics(label: semanticLabel, image: true, child: dot);
  }
}

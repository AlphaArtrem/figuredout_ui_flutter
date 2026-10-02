import 'package:flutter/material.dart';

/// A circle that stays a circle: a numbered stage, an icon's tinted ground,
/// a status dot.
///
/// A fixed-size `Container` with a circle shape becomes an oval the moment
/// its parent hands it tight constraints — a stretched column, an expanded
/// cell, a row squeezed at 200% text. This sizes itself as a square of
/// [size] whatever it is given, centred in any extra room, and never
/// shrinks. Every round mark in the package is one of these.
class FoDisc extends StatelessWidget {
  /// Creates a disc.
  const FoDisc({
    required this.size,
    this.color,
    this.borderColor,
    this.borderWidth = 1,
    this.child,
    super.key,
  });

  /// The diameter.
  final double size;

  /// The fill. Null leaves it transparent.
  final Color? color;

  /// An outline, for an "upcoming" or "empty" mark.
  final Color? borderColor;

  /// The outline's width.
  final double borderWidth;

  /// What sits in the middle — a number, a glyph.
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Center(
      widthFactor: 1,
      heightFactor: 1,
      child: SizedBox.square(
        dimension: size,
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            border: borderColor == null
                ? null
                : Border.all(color: borderColor!, width: borderWidth),
          ),
          child: child == null ? null : Center(child: child),
        ),
      ),
    );
  }
}

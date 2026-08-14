import 'package:flutter/material.dart';

import '../tokens/fo_chart_colors.dart';
import '../tokens/fo_colors.dart';
import '../tokens/fo_layout.dart';
import '../tokens/fo_shadows.dart';
import '../tokens/fo_typography.dart';

/// The design system, attached to [ThemeData.extensions] and read through
/// `context.foColors` / `.foText` / `.foShadows` / `.foSpacing` / `.foRadii`.
///
/// [lerp] is the dangerous method in this file. A field that is theme-varying
/// and missing from `lerp` freezes at its `from` value for the whole of every
/// theme animation, and nothing in the analyzer catches it —
/// `test/theme/fo_theme_ext_test.dart` does, by parsing `FoColors`'s field
/// list and checking each name reaches `FoColors.lerp`.
///
/// [spacing] and [radii] are deliberately *not* interpolated: they are
/// theme-invariant, so there is nothing to move.
@immutable
class FoThemeExt extends ThemeExtension<FoThemeExt> {
  /// Creates the extension. Prefer [FoThemeExt.light] / [FoThemeExt.dark].
  const FoThemeExt({
    required this.colors,
    required this.text,
    required this.charts,
    required this.shadows,
    this.spacing = const FoSpacing(),
    this.radii = const FoRadii(),
  });

  /// The semantic colour set.
  final FoColors colors;

  /// The type ramp.
  final FoTextStyles text;

  /// The chart palette.
  final FoChartColors charts;

  /// The three elevation steps.
  final FoShadows shadows;

  /// The spacing scale. Theme-invariant.
  final FoSpacing spacing;

  /// The radius scale. Theme-invariant.
  final FoRadii radii;

  /// The light theme's extension.
  factory FoThemeExt.light() => FoThemeExt(
        colors: FoColors.light,
        text: FoTextStyles.forColors(
          fg: FoColors.light.fg,
          fgMuted: FoColors.light.fgMuted,
        ),
        charts: FoChartColors.light,
        shadows: FoShadows.light,
      );

  /// The dark theme's extension.
  factory FoThemeExt.dark() => FoThemeExt(
        colors: FoColors.dark,
        text: FoTextStyles.forColors(
          fg: FoColors.dark.fg,
          fgMuted: FoColors.dark.fgMuted,
        ),
        charts: FoChartColors.dark,
        shadows: FoShadows.dark,
      );

  @override
  FoThemeExt copyWith({
    FoColors? colors,
    FoTextStyles? text,
    FoChartColors? charts,
    FoShadows? shadows,
    FoSpacing? spacing,
    FoRadii? radii,
  }) =>
      FoThemeExt(
        colors: colors ?? this.colors,
        text: text ?? this.text,
        charts: charts ?? this.charts,
        shadows: shadows ?? this.shadows,
        spacing: spacing ?? this.spacing,
        radii: radii ?? this.radii,
      );

  @override
  FoThemeExt lerp(ThemeExtension<FoThemeExt>? other, double t) {
    if (other is! FoThemeExt) return this;
    return FoThemeExt(
      colors: FoColors.lerp(colors, other.colors, t),
      text: FoTextStyles.lerp(text, other.text, t),
      charts: FoChartColors.lerp(charts, other.charts, t),
      shadows: FoShadows.lerp(shadows, other.shadows, t),
      spacing: spacing,
      radii: radii,
    );
  }
}

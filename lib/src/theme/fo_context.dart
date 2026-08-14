import 'package:flutter/material.dart';

import '../tokens/fo_chart_colors.dart';
import '../tokens/fo_colors.dart';
import '../tokens/fo_layout.dart';
import '../tokens/fo_shadows.dart';
import '../tokens/fo_typography.dart';
import 'fo_theme_ext.dart';
import 'fo_window_class.dart';

/// Ergonomic access to the design system from any [BuildContext].
///
/// `context.foColors.primary`, `context.foText.title`, `context.foSpacing.lg`,
/// `context.foRadii.card`, `context.foShadows.overlay`.
///
/// This is the only supported way for a widget to reach a design value. Going
/// through `FoTokens` directly skips the theme, so the widget will not follow
/// a light/dark switch — and `test/tokens/no_literals_test.dart` will fail it.
extension FoThemeContext on BuildContext {
  /// The whole extension. Falls back to the light theme in release if it was
  /// never registered, and asserts in debug so the mistake is loud in dev.
  FoThemeExt get foTheme {
    final FoThemeExt? ext = Theme.of(this).extension<FoThemeExt>();
    assert(
      ext != null,
      'FoThemeExt missing — build your ThemeData with FoTheme.light() / '
      'FoTheme.dark(), or add FoThemeExt to ThemeData.extensions.',
    );
    return ext ?? FoThemeExt.light();
  }

  /// The semantic colour set.
  FoColors get foColors => foTheme.colors;

  /// The type ramp.
  FoTextStyles get foText => foTheme.text;

  /// The chart palette.
  FoChartColors get foCharts => foTheme.charts;

  /// The three elevation steps.
  FoShadows get foShadows => foTheme.shadows;

  /// The spacing scale.
  FoSpacing get foSpacing => foTheme.spacing;

  /// The radius scale.
  FoRadii get foRadii => foTheme.radii;

  /// The layout band for this context's width.
  FoWindowClass get foWindowClass => FoWindowClass.of(this);

  /// The page's horizontal padding at this context's width.
  double get foGutter => FoLayout.gutter(MediaQuery.sizeOf(this).width);
}

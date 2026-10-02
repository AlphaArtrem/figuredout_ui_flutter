import 'package:flutter/material.dart';

import 'fo_tokens.dart';

/// Categorical and structural colours for charts, exposed via
/// `context.foCharts`.
///
/// Series hues **never** carry status meaning — a series is not "the red one",
/// it is series 4. Status uses the semantic palette in `FoColors`, and the two
/// sets are deliberately allowed to share a hue without sharing a meaning.
@immutable
class FoChartColors {
  /// Creates a chart palette. Prefer [FoChartColors.light] / `.dark`.
  const FoChartColors({
    required this.categorical,
    required this.sequential,
    required this.grid,
    required this.axisLabel,
    required this.targetLine,
    required this.track,
  });

  /// The six categorical hues, in order.
  final List<Color> categorical;

  /// The single hue a sequential (intensity) scale ramps through.
  final Color sequential;

  /// The chart's own grid rules.
  final Color grid;

  /// Axis tick labels.
  final Color axisLabel;

  /// A target or threshold rule. Flutter-only — the web package has no
  /// equivalent, so it is marked Flutter-only in the manifest.
  final Color targetLine;

  /// `--chart-track`: the unfilled part of a meter — the rest of a progress
  /// bar, an empty step. Not a hairline, and not `surfaceSunken` by name,
  /// because a track and a hole are different jobs that happen to share a
  /// value in light mode.
  final Color track;

  /// The light theme's chart palette.
  static const FoChartColors light = FoChartColors(
    categorical: FoTokens.chartCategorical,
    sequential: FoTokens.chartSequential,
    grid: FoTokens.chartGrid,
    axisLabel: FoTokens.chartAxisLabel,
    targetLine: FoTokens.chartTargetLine,
    track: FoTokens.chartTrack,
  );

  /// The dark theme's chart palette.
  static const FoChartColors dark = FoChartColors(
    categorical: FoTokens.chartCategoricalDark,
    sequential: FoTokens.chartSequentialDark,
    grid: FoTokens.chartGridDark,
    axisLabel: FoTokens.chartAxisLabelDark,
    targetLine: FoTokens.chartTargetLineDark,
    track: FoTokens.chartTrackDark,
  );

  /// The Graphite dark palette's chart colours. The track follows the
  /// sunken step, as the palette's notes ask.
  static const FoChartColors graphite = FoChartColors(
    categorical: FoTokens.chartCategoricalGraphite,
    sequential: FoTokens.primaryGraphite,
    grid: FoTokens.chartGridGraphite,
    axisLabel: FoTokens.chartAxisLabelGraphite,
    targetLine: FoTokens.chartTargetLineGraphite,
    track: FoTokens.surfaceSunkenGraphite,
  );

  /// The series colour at [index], cycling past the palette's length.
  Color series(int index) => categorical[index % categorical.length];

  /// Interpolates every field.
  static FoChartColors lerp(FoChartColors a, FoChartColors b, double t) =>
      FoChartColors(
        categorical: List<Color>.generate(
          a.categorical.length,
          (int i) => Color.lerp(
            a.categorical[i],
            b.categorical[i % b.categorical.length],
            t,
          )!,
        ),
        sequential: Color.lerp(a.sequential, b.sequential, t)!,
        grid: Color.lerp(a.grid, b.grid, t)!,
        axisLabel: Color.lerp(a.axisLabel, b.axisLabel, t)!,
        targetLine: Color.lerp(a.targetLine, b.targetLine, t)!,
        track: Color.lerp(a.track, b.track, t)!,
      );
}

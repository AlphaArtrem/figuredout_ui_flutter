import 'package:flutter/material.dart';

import '../theme/fo_context.dart';
import 'fo_status_chip.dart';

/// One value toward a known total, as a bar: "1,260 / 2,400 packed",
/// a line at 92% efficiency.
///
/// It is a meter, not a loading indicator — nothing here moves on its own.
/// The fill is in [tone] over the chart track, and [trailing] carries the
/// figure in words beside the bar, because **a bar is never the only way to
/// read its own number**: the web package's rule for every chart, and the
/// reason [semanticValue] is required rather than derived.
///
/// A value past [max] fills the bar and stops; the figure in [trailing] is
/// what says by how much.
class FoProgressBar extends StatelessWidget {
  /// Creates a progress bar.
  const FoProgressBar({
    required this.value,
    required this.max,
    required this.semanticLabel,
    required this.semanticValue,
    this.trailing,
    this.tone = FoStatusTone.primary,
    super.key,
  }) : assert(max > 0, 'max must be positive — a bar out of nothing is empty');

  /// How much is done.
  final double value;

  /// The total the bar is out of.
  final double max;

  /// What is being measured — "Slim Chino, packed". Caller-supplied.
  final String semanticLabel;

  /// The reading in words — "1,260 of 2,400". Caller-supplied, so it is
  /// formatted the way the app formats its numbers.
  final String semanticValue;

  /// The figure beside the bar, usually mono tabular text. Visual only: the
  /// bar's semantics already carry [semanticValue].
  final Widget? trailing;

  /// The fill's tone. Primary by default; a status only when the bar *is* a
  /// status — a line under target, say.
  final FoStatusTone tone;

  /// The bar's thickness.
  static const double thickness = 8;

  @override
  Widget build(BuildContext context) {
    final double fraction = (value / max).clamp(0.0, 1.0);
    final Color fill = switch (tone) {
      FoStatusTone.neutral => context.foColors.fgSubtle,
      FoStatusTone.primary => context.foColors.primary,
      FoStatusTone.success => context.foColors.success,
      FoStatusTone.warning => context.foColors.warning,
      FoStatusTone.danger => context.foColors.danger,
      FoStatusTone.info => context.foColors.info,
    };
    final BorderRadius radius = BorderRadius.circular(thickness / 2);

    final Widget bar = ClipRRect(
      borderRadius: radius,
      child: SizedBox(
        height: thickness,
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            ColoredBox(color: context.foCharts.track),
            FractionallySizedBox(
              alignment: AlignmentDirectional.centerStart,
              widthFactor: fraction,
              child: DecoratedBox(
                decoration: BoxDecoration(color: fill, borderRadius: radius),
              ),
            ),
          ],
        ),
      ),
    );

    return Semantics(
      container: true,
      label: semanticLabel,
      value: semanticValue,
      child: ExcludeSemantics(
        child: trailing == null
            ? bar
            : Row(
                children: <Widget>[
                  Expanded(child: bar),
                  SizedBox(width: context.foSpacing.md),
                  // Flexible, so a long figure at 200% text wraps rather than
                  // pushing the bar to nothing.
                  Flexible(child: trailing!),
                ],
              ),
      ),
    );
  }
}

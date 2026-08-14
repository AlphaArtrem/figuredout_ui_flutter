import 'package:flutter/material.dart';

import '../theme/fo_context.dart';
import '../tokens/fo_tokens.dart';

/// A busy indicator at one of two sizes, in the system's own ink.
///
/// Two sizes and no more: [FoSpinnerSize.small] sits inside a control beside
/// text, [FoSpinnerSize.medium] stands in for a region. A spinner larger than
/// that is a sign the screen wants a skeleton — `FoSkeleton` keeps the layout
/// from jumping when the data lands, which a spinner cannot.
class FoSpinner extends StatelessWidget {
  /// Creates a spinner.
  const FoSpinner({
    this.size = FoSpinnerSize.small,
    this.color,
    this.semanticsLabel,
    super.key,
  });

  /// Which of the two sizes.
  final FoSpinnerSize size;

  /// Overrides the ink. A spinner inside a filled button needs the button's
  /// foreground, not the page's primary — otherwise it disappears.
  final Color? color;

  /// What is loading, for a screen reader. Caller-supplied, so it can be
  /// localized; without it the spinner is announced as an unlabelled progress
  /// indicator.
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final double dimension = switch (size) {
      FoSpinnerSize.small => FoTokens.spinnerSmall,
      FoSpinnerSize.medium => FoTokens.spinnerMedium,
    };

    return SizedBox.square(
      dimension: dimension,
      child: CircularProgressIndicator(
        strokeWidth: FoTokens.spinnerStroke,
        color: color ?? context.foColors.primary,
        semanticsLabel: semanticsLabel,
      ),
    );
  }
}

/// The two spinner sizes.
enum FoSpinnerSize {
  /// Inside a control, beside text.
  small,

  /// Standing in for a region.
  medium,
}

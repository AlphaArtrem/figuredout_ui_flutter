import 'package:figuredout_ui/figuredout_ui.dart';
import 'package:flutter/material.dart';

/// The frame every Foundations use case sits in: the page ground, the page
/// gutter, and a scroll region, so a use case never has to restate them.
class DocPage extends StatelessWidget {
  /// Creates a documentation page.
  const DocPage({
    required this.title,
    required this.lede,
    required this.children,
    super.key,
  });

  /// What this page shows.
  final String title;

  /// Why it is a rule rather than a preference — one or two sentences.
  final String lede;

  /// The page's blocks, usually [DocSection]s.
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: context.foColors.bg,
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: context.foGutter,
          vertical: context.foSpacing.xxl,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: FoLayout.measure),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(title, style: context.foText.display),
                SizedBox(height: context.foSpacing.sm),
                Text(
                  lede,
                  style: context.foText.body.copyWith(
                    color: context.foColors.fgMuted,
                  ),
                ),
                SizedBox(height: context.foSpacing.xl),
                ...children,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A titled block inside a [DocPage].
class DocSection extends StatelessWidget {
  /// Creates a section.
  const DocSection({required this.title, required this.child, super.key});

  /// The section's name — set in the mono uppercase caption, because it names
  /// what follows rather than saying anything itself.
  final String title;

  /// The section's content.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: context.foSpacing.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title.toUpperCase(), style: context.foText.caption),
          SizedBox(height: context.foSpacing.md),
          child,
        ],
      ),
    );
  }
}

/// WCAG relative-contrast ratio between two opaque colours.
///
/// `test/tokens/contrast_test.dart` in the library is the authority — it
/// measures every pair, asserts the thresholds and generates
/// `docs/contrast-report.md`. This copy exists so the palette can print the
/// number beside the swatch it belongs to; if the two ever disagree, the test
/// is right.
double contrastRatio(Color a, Color b) {
  final double la = a.computeLuminance();
  final double lb = b.computeLuminance();
  final double hi = la > lb ? la : lb;
  final double lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

/// `#RRGGBB`, or `#RRGGBB @ NN%` when the colour carries alpha.
String hexOf(Color color) {
  String channel(double value) =>
      (value * 255).round().toRadixString(16).padLeft(2, '0').toUpperCase();
  final String rgb =
      '#${channel(color.r)}${channel(color.g)}${channel(color.b)}';
  if (color.a >= 1.0) return rgb;
  return '$rgb @ ${(color.a * 100).round()}%';
}

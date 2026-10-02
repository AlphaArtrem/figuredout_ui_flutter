import 'package:figuredout_ui/figuredout_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/pump.dart';

/// WCAG AA for what a component **actually paints**, not for a token pair.
///
/// `test/tokens/contrast_test.dart` measures tokens against tokens, and it
/// waives `primary` on its own wash. That waiver was true and beside the point:
/// two components painted exactly that pair as text — the tertiary `FoButton`
/// (every "Cancel" in a consuming app's sheets, 4.27:1) and
/// `FoStatusChip.tone(primary)` (4.10:1). A consuming app's accessibility tour
/// found them (legal_app traps §110). This reads the ink and the fill off the
/// rendered widget and composites the fill over every ground the component
/// can sit on, so a waiver on a token cannot hide a failing component again.
void main() {
  const double aaBody = 4.5;

  for (final bool isDark in <bool>[false, true]) {
    final String theme = isDark ? 'dark' : 'light';
    final FoColors c = isDark ? FoColors.dark : FoColors.light;
    final Map<String, Color> grounds = <String, Color>{
      'bg': c.bg,
      'surface': c.surface,
      'surfaceRaised': c.surfaceRaised,
    };

    testWidgets('$theme: a tertiary FoButton label clears AA on every ground', (
      WidgetTester tester,
    ) async {
      await pumpFo(
        tester,
        isDark: isDark,
        child: FoButton(
          label: 'Cancel',
          variant: FoButtonVariant.tertiary,
          onPressed: () {},
        ),
      );

      final Color ink = _inkOf(tester, 'Cancel');
      final Color fill = tester
          .widget<Material>(
            find.descendant(
              of: find.byType(FilledButton),
              matching: find.byType(Material),
            ),
          )
          .color!;

      for (final MapEntry<String, Color> ground in grounds.entries) {
        final double ratio =
            _contrast(ink, Color.alphaBlend(fill, ground.value));
        expect(
          ratio,
          greaterThanOrEqualTo(aaBody),
          reason: '$theme: tertiary label over ${ground.key} is '
              '${ratio.toStringAsFixed(2)}:1',
        );
      }
    });

    for (final FoStatusTone tone in FoStatusTone.values) {
      testWidgets('$theme: FoStatusChip.tone(${tone.name}) clears AA', (
        WidgetTester tester,
      ) async {
        await pumpFo(
          tester,
          isDark: isDark,
          child: FoStatusChip.tone(label: 'Principal', tone: tone),
        );

        final Color ink = _inkOf(tester, 'Principal');
        final Color wash = (tester
                .widget<Container>(
                  find.descendant(
                    of: find.byType(FoStatusChip),
                    matching: find.byType(Container),
                  ),
                )
                .decoration! as BoxDecoration)
            .color!;

        for (final MapEntry<String, Color> ground in grounds.entries) {
          final double ratio =
              _contrast(ink, Color.alphaBlend(wash, ground.value));
          expect(
            ratio,
            greaterThanOrEqualTo(aaBody),
            reason: '$theme: ${tone.name} chip over ${ground.key} is '
                '${ratio.toStringAsFixed(2)}:1',
          );
        }
      });
    }
  }
}

Color _inkOf(WidgetTester tester, String text) {
  final RenderParagraph paragraph =
      tester.renderObject<RenderParagraph>(find.text(text));
  return paragraph.text.style!.color!;
}

double _contrast(Color a, Color b) {
  final double la = a.computeLuminance();
  final double lb = b.computeLuminance();
  final double hi = la > lb ? la : lb;
  final double lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

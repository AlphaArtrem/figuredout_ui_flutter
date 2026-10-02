import 'dart:math' as math;

import 'package:figuredout_ui/figuredout_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The Graphite dark palette against the checks it was chosen on — every row
/// of the contrast table in the Luxe canvas's `notes/dark-themes.md`.
///
/// Stricter than `contrast_test.dart`, which holds every palette to AA:
/// body text at 7:1, hairlines that can be seen (1.5:1) and input rings that
/// can be found (3:1, WCAG 1.4.11), real steps between surfaces (CIELAB ΔL*,
/// because contrast ratios bunch up near black), and washes that read as
/// pills (ΔE76 from the raised surface). If one fails, the palette has drifted
/// from what its owner signed off.
void main() {
  const FoColors g = FoColors.graphite;
  const FoChartColors charts = FoChartColors.graphite;
  final Map<String, Color> surfaces = <String, Color>{
    'page': g.bg,
    'card': g.surface,
    'raised': g.surfaceRaised,
    'sunken': g.surfaceSunken,
    'selected row': g.primarySoft,
  };

  group('Graphite text', () {
    for (final MapEntry<String, Color> on in surfaces.entries) {
      test('body text on ${on.key} ≥ 7:1', () {
        expect(_ratio(g.fg, on.value), greaterThanOrEqualTo(7));
      });
      test('muted and subtle text on ${on.key} ≥ 4.5:1', () {
        expect(_ratio(g.fgMuted, on.value), greaterThanOrEqualTo(4.5));
        expect(_ratio(g.fgSubtle, on.value), greaterThanOrEqualTo(4.5));
      });
    }

    for (final String on in <String>['page', 'card', 'raised']) {
      test('primary, success, warning, danger, info text on $on ≥ 4.5:1', () {
        for (final Color ink in <Color>[
          g.primary,
          g.success,
          g.warning,
          g.danger,
          g.info,
        ]) {
          expect(_ratio(ink, surfaces[on]!), greaterThanOrEqualTo(4.5));
        }
      });
    }

    test('every badge ink on its own wash ≥ 4.5:1', () {
      final Map<Color, Color> pairs = <Color, Color>{
        g.fgMuted: g.surfaceSunken,
        g.primary: g.primarySoft,
        g.success: g.successSoft,
        g.warning: g.warningSoft,
        g.danger: g.dangerSoft,
        g.info: g.infoSoft,
      };
      for (final MapEntry<Color, Color> p in pairs.entries) {
        expect(_ratio(p.key, p.value), greaterThanOrEqualTo(4.5));
      }
    });

    test('ink on the primary and danger fills ≥ 4.5:1', () {
      expect(_ratio(g.primaryFg, g.primary), greaterThanOrEqualTo(4.5));
      expect(_ratio(g.primaryFg, g.primaryHover), greaterThanOrEqualTo(4.5));
      expect(_ratio(g.dangerFg, g.danger), greaterThanOrEqualTo(4.5));
      expect(_ratio(g.accentFg, g.accent), greaterThanOrEqualTo(4.5));
    });
  });

  group('Graphite edges and marks', () {
    for (final String on in <String>['page', 'card', 'raised']) {
      test('hairline vs $on ≥ 1.5:1', () {
        expect(_ratio(g.edge, surfaces[on]!), greaterThanOrEqualTo(1.5));
      });
    }
    for (final String on in <String>['card', 'raised']) {
      test('strong hairline (input ring) vs $on ≥ 3:1', () {
        expect(_ratio(g.edgeStrong, surfaces[on]!), greaterThanOrEqualTo(3));
      });
    }
    test('the needs-approval ring and the warning ink vs raised ≥ 3:1', () {
      expect(
        _ratio(
          Color.alphaBlend(g.warningRing, g.surfaceRaised),
          g.surfaceRaised,
        ),
        greaterThanOrEqualTo(3),
      );
      expect(_ratio(g.warning, g.surfaceRaised), greaterThanOrEqualTo(3));
    });
    test('the focus ring vs raised ≥ 3:1', () {
      expect(
        _ratio(Color.alphaBlend(g.focusRing, g.surfaceRaised), g.surfaceRaised),
        greaterThanOrEqualTo(3),
      );
    });
    test('a primary bar on its track ≥ 3:1', () {
      expect(_ratio(g.primary, charts.track), greaterThanOrEqualTo(3));
    });
    // The ring is a hairline, so it is held to the hairline rule (1.5:1);
    // without it these dots measure 1.0–1.4:1 and disappear.
    test('the swatch ring keeps Deep Navy and Jet Black visible', () {
      for (final Color dot in <Color>[
        const Color(0xFF1E293B),
        const Color(0xFF111111),
      ]) {
        final Color ring = Color.alphaBlend(g.swatchRing, dot);
        expect(_ratio(dot, g.surfaceRaised), lessThan(1.5));
        expect(_ratio(ring, g.surfaceRaised), greaterThanOrEqualTo(1.5));
      }
    });
    test('series 6 is not the axis ink', () {
      expect(charts.categorical, isNot(contains(charts.axisLabel)));
    });
  });

  group('Graphite surfaces', () {
    test('the ladder is in order: sunken < page < card < raised', () {
      final List<double> l = <Color>[
        g.surfaceSunken,
        g.bg,
        g.surface,
        g.surfaceRaised,
      ].map(_lStar).toList();
      for (int i = 1; i < l.length; i++) {
        expect(l[i], greaterThan(l[i - 1]));
      }
    });
    test('page → card and card → raised step ≥ 3.5 ΔL*', () {
      expect(_lStar(g.surface) - _lStar(g.bg), greaterThanOrEqualTo(3.5));
      expect(
        _lStar(g.surfaceRaised) - _lStar(g.surface),
        greaterThanOrEqualTo(3.5),
      );
    });
    test('sunken → card ≥ 5 ΔL*, so a track reads as a hole', () {
      expect(
        _lStar(g.surface) - _lStar(g.surfaceSunken),
        greaterThanOrEqualTo(5),
      );
    });
    test('the selected row stands off the card ≥ 6 ΔE', () {
      expect(_deltaE(g.primarySoft, g.surface), greaterThanOrEqualTo(6));
    });
    test('every wash reads as a pill on raised ≥ 6 ΔE', () {
      for (final Color wash in <Color>[
        g.surfaceSunken,
        g.primarySoft,
        g.successSoft,
        g.warningSoft,
        g.dangerSoft,
        g.infoSoft,
      ]) {
        expect(_deltaE(wash, g.surfaceRaised), greaterThanOrEqualTo(6));
      }
    });
  });

  group('FoDarkPalette', () {
    test('ink/sky stays the default and the web package\'s', () {
      expect(
        FoTheme.dark().extension<FoThemeExt>()!.colors,
        FoColors.dark,
      );
      expect(FoColors.dark.bg, const Color(0xFF030A0E));
    });

    test('graphite is opt-in, all the way through', () {
      final ThemeData theme = FoTheme.dark(palette: FoDarkPalette.graphite);
      final FoThemeExt ext = theme.extension<FoThemeExt>()!;
      expect(ext.colors, FoColors.graphite);
      expect(ext.charts, FoChartColors.graphite);
      expect(theme.scaffoldBackgroundColor, FoColors.graphite.bg);
      expect(theme.brightness, Brightness.dark);
      expect(ext.text.body.color, FoColors.graphite.fg);
    });

    testWidgets('a swatch has a light ring on every dark palette', (
      WidgetTester tester,
    ) async {
      for (final FoDarkPalette palette in FoDarkPalette.values) {
        await tester.pumpWidget(
          MaterialApp(
            theme: FoTheme.dark(palette: palette),
            home: const Center(
              child: FoColourSwatch(color: Color(0xFF111111)),
            ),
          ),
        );
        final Container dot = tester.widget<Container>(
          find.descendant(
            of: find.byType(FoColourSwatch),
            matching: find.byType(Container),
          ),
        );
        final Border border =
            (dot.foregroundDecoration! as BoxDecoration).border! as Border;
        expect(border.top.color, FoTokens.swatchRingDark);
      }
    });
  });
}

double _lin(double c) =>
    c <= 0.04045 ? c / 12.92 : math.pow((c + 0.055) / 1.055, 2.4).toDouble();

double _ratio(Color a, Color b) {
  final double la = a.computeLuminance();
  final double lb = b.computeLuminance();
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

/// CIELAB from sRGB, D65.
List<double> _lab(Color c) {
  final double r = _lin(c.r), g = _lin(c.g), b = _lin(c.b);
  final double x = (0.4124 * r + 0.3576 * g + 0.1805 * b) / 0.95047;
  final double y = 0.2126 * r + 0.7152 * g + 0.0722 * b;
  final double z = (0.0193 * r + 0.1192 * g + 0.9505 * b) / 1.08883;
  double f(double t) =>
      t > 0.008856 ? math.pow(t, 1 / 3).toDouble() : 7.787 * t + 16 / 116;
  return <double>[116 * f(y) - 16, 500 * (f(x) - f(y)), 200 * (f(y) - f(z))];
}

double _lStar(Color c) => _lab(c)[0];

double _deltaE(Color a, Color b) {
  final List<double> p = _lab(a), q = _lab(b);
  return math.sqrt(
    math.pow(p[0] - q[0], 2) +
        math.pow(p[1] - q[1], 2) +
        math.pow(p[2] - q[2], 2),
  );
}

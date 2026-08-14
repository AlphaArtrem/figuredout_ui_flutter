import 'package:figuredout_ui/figuredout_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  /// G2: `TextStyle(fontFamily: 'Geist')` without `package: 'figuredout_ui'`
  /// resolves against the *consuming app's* font manifest, finds nothing, and
  /// falls back to Roboto — with no warning, in the consuming app only, so it
  /// is invisible from inside this package. Flutter records the package by
  /// prefixing the family, which is what makes it assertable here.
  group('fonts are package-qualified', () {
    for (final MapEntry<String, TextStyle> entry in FoTextStyles.forColors(
      fg: FoColors.light.fg,
      fgMuted: FoColors.light.fgMuted,
    ).toMap().entries) {
      test('${entry.key} resolves inside figuredout_ui', () {
        expect(
          entry.value.fontFamily,
          startsWith('packages/${FoTokens.fontPackage}/'),
          reason: 'FoTextStyles.${entry.key} is missing '
              'package: FoTokens.fontPackage — it will silently be Roboto in '
              'every consuming app.',
        );
      });
    }

    test('the ramp uses both families, and mono only where it means one', () {
      final FoTextStyles t = FoTextStyles.forColors(
        fg: FoColors.light.fg,
        fgMuted: FoColors.light.fgMuted,
      );
      const String mono = 'packages/figuredout_ui/${FoTokens.fontMono}';
      const String sans = 'packages/figuredout_ui/${FoTokens.fontSans}';

      // Mono names a value (caption) or is one (numeric). Nothing else.
      expect(t.caption.fontFamily, mono);
      expect(t.numeric.fontFamily, mono);
      for (final TextStyle style in <TextStyle>[
        t.display,
        t.title,
        t.subtitle,
        t.body,
        t.label,
      ]) {
        expect(style.fontFamily, sans);
      }
    });

    test('numeric figures are tabular, so digits align down a column', () {
      final FoTextStyles t = FoTextStyles.forColors(
        fg: FoColors.light.fg,
        fgMuted: FoColors.light.fgMuted,
      );
      expect(
        t.numeric.fontFeatures,
        contains(const FontFeature.tabularFigures()),
      );
    });
  });

  group('FoTheme', () {
    test('registers FoThemeExt in both brightnesses', () {
      expect(FoTheme.light().extension<FoThemeExt>()?.colors, FoColors.light);
      expect(FoTheme.dark().extension<FoThemeExt>()?.colors, FoColors.dark);
    });

    /// Rule §3.2: three elevation steps, painted by this package. Material's
    /// own elevation draws a black shadow plus a primary-hued surface tint,
    /// both of which fight a tinted ground.
    test('every Material elevation is flat', () {
      for (final ThemeData theme in <ThemeData>[
        FoTheme.light(),
        FoTheme.dark(),
      ]) {
        expect(theme.cardTheme.elevation, 0);
        expect(theme.appBarTheme.elevation, 0);
        expect(theme.appBarTheme.scrolledUnderElevation, 0);
        expect(theme.dialogTheme.elevation, 0);
        expect(theme.bottomSheetTheme.elevation, 0);
        expect(theme.popupMenuTheme.elevation, 0);
        expect(theme.snackBarTheme.elevation, 0);
        expect(theme.colorScheme.surfaceTint, Colors.transparent);
      }
    });

    /// Rule §3.5, and G5: the ladder, in the order that is its meaning. A
    /// dialog sits on `surfaceRaised`, not on `surface`; a field is a hole.
    test('the surface ladder is wired to the right Material slots', () {
      final ThemeData theme = FoTheme.light();
      expect(theme.scaffoldBackgroundColor, FoColors.light.bg);
      expect(theme.cardTheme.color, FoColors.light.surface);
      expect(theme.dialogTheme.backgroundColor, FoColors.light.surfaceRaised);
      expect(theme.popupMenuTheme.color, FoColors.light.surfaceRaised);
      expect(
        theme.inputDecorationTheme.fillColor,
        FoColors.light.surfaceSunken,
      );
    });

    test('white is the top of the ladder, not the resting surface', () {
      expect(FoColors.light.surfaceRaised, const Color(0xFFFFFFFF));
      expect(FoColors.light.surface, isNot(const Color(0xFFFFFFFF)));
    });

    test('focus has one treatment, and it is not Material blue', () {
      expect(FoTheme.light().focusColor, FoColors.light.focusRing);
      expect(FoTheme.dark().focusColor, FoColors.dark.focusRing);
    });
  });

  group('FoWindowClass', () {
    test('splits on 600 and 900', () {
      expect(FoWindowClass.forWidth(599), FoWindowClass.compact);
      expect(FoWindowClass.forWidth(600), FoWindowClass.medium);
      expect(FoWindowClass.forWidth(899), FoWindowClass.medium);
      expect(FoWindowClass.forWidth(900), FoWindowClass.expanded);
    });

    test('isAtLeastMedium means "not a phone", not "expanded"', () {
      expect(FoWindowClass.compact.isAtLeastMedium, isFalse);
      expect(FoWindowClass.medium.isAtLeastMedium, isTrue);
      expect(FoWindowClass.expanded.isAtLeastMedium, isTrue);
    });
  });

  group('FoLayout.gutter', () {
    test('clamps between 16 and 40', () {
      expect(FoLayout.gutter(320), 16);
      expect(FoLayout.gutter(800), 32);
      expect(FoLayout.gutter(1600), 40);
    });
  });

  group('context extension', () {
    testWidgets('reads the theme that is actually mounted', (
      WidgetTester tester,
    ) async {
      late FoColors seen;
      late FoWindowClass band;
      await tester.pumpWidget(
        MaterialApp(
          theme: FoTheme.dark(),
          home: Builder(
            builder: (BuildContext context) {
              seen = context.foColors;
              band = context.foWindowClass;
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      expect(seen.bg, FoColors.dark.bg);
      // The default test surface is 800x600, which is the medium band.
      expect(band, FoWindowClass.medium);
    });
  });
}

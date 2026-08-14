import 'dart:io';

import 'package:figuredout_ui/figuredout_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// G1: `ThemeExtension.lerp` is where new tokens go to die.
///
/// Add a colour to [FoColors] and forget it in `FoColors.lerp` and it silently
/// freezes at its `from` value for the whole of every theme animation. The
/// analyzer cannot see it, a widget test will not notice it, and it looks like
/// a rendering glitch when someone finally does. So this file checks it two
/// ways: behaviourally, that every colour actually moves at `t = 0.5`; and
/// structurally, by reading `fo_colors.dart` and requiring every declared
/// field to appear in both `toMap` and `lerp` — which is what catches a field
/// that was forgotten in *both* places.
void main() {
  group('FoColors.lerp', () {
    test('moves every colour at t = 0.5', () {
      const FoColors a = FoColors.light;
      const FoColors b = FoColors.dark;
      final FoColors mid = FoColors.lerp(a, b, 0.5);

      final Map<String, Color> from = a.toMap();
      final Map<String, Color> to = b.toMap();
      final Map<String, Color> midMap = mid.toMap();

      final List<String> frozen = <String>[];
      for (final String name in from.keys) {
        if (from[name] == to[name]) continue; // nothing to move
        if (midMap[name] == from[name]) frozen.add(name);
      }

      expect(
        frozen,
        isEmpty,
        reason:
            'These colours are stuck at their light value halfway through a '
            'theme animation, which means they are missing from '
            'FoColors.lerp: ${frozen.join(', ')}',
      );
    });

    test('every declared field reaches toMap and lerp', () {
      final List<String> declared = _declaredColorFields(
        File('lib/src/tokens/fo_colors.dart').readAsStringSync(),
      );
      expect(
        declared.length,
        greaterThan(20),
        reason: 'the field parser found almost nothing — it has drifted',
      );

      final Set<String> inMap = FoColors.light.toMap().keys.toSet();
      final String lerpBody = _bodyOf(
        File('lib/src/tokens/fo_colors.dart').readAsStringSync(),
        'static FoColors lerp(',
      );

      final List<String> missingFromMap =
          declared.where((String f) => !inMap.contains(f)).toList();
      final List<String> missingFromLerp = declared
          .where((String f) => !lerpBody.contains('$f: Color.lerp(a.$f,'))
          .toList();

      expect(
        missingFromMap,
        isEmpty,
        reason: 'FoColors.toMap() is missing: ${missingFromMap.join(', ')}',
      );
      expect(
        missingFromLerp,
        isEmpty,
        reason: 'FoColors.lerp does not interpolate: '
            '${missingFromLerp.join(', ')} — they will freeze during a theme '
            'animation.',
      );
    });
  });

  group('FoThemeExt', () {
    test('lerp interpolates colours, type, charts and shadows', () {
      final FoThemeExt light = FoThemeExt.light();
      final FoThemeExt dark = FoThemeExt.dark();
      final FoThemeExt mid = light.lerp(dark, 0.5);

      expect(mid.colors.surface, isNot(light.colors.surface));
      expect(mid.text.body.color, isNot(light.text.body.color));
      expect(mid.charts.grid, isNot(light.charts.grid));
      expect(
        mid.shadows.raised.first.color,
        isNot(light.shadows.raised.first.color),
      );
    });

    test('spacing and radii are theme-invariant, so lerp leaves them', () {
      final FoThemeExt light = FoThemeExt.light();
      final FoThemeExt mid = light.lerp(FoThemeExt.dark(), 0.5);
      expect(mid.spacing.lg, light.spacing.lg);
      expect(mid.radii.card, light.radii.card);
    });

    test('copyWith replaces only what it is given', () {
      final FoThemeExt light = FoThemeExt.light();
      final FoThemeExt swapped = light.copyWith(colors: FoColors.dark);
      expect(swapped.colors.bg, FoColors.dark.bg);
      expect(swapped.charts.grid, light.charts.grid);
    });
  });
}

/// Field names declared as `final Color <name>;` in [source].
List<String> _declaredColorFields(String source) => RegExp(
      r'^\s*final\s+Color\s+(\w+);',
      multiLine: true,
    ).allMatches(source).map((RegExpMatch m) => m.group(1)!).toList();

/// The source text from [marker] to the end of the enclosing statement.
String _bodyOf(String source, String marker) {
  final int start = source.indexOf(marker);
  if (start == -1) return '';
  final int end = source.indexOf('\n}', start);
  return source.substring(start, end == -1 ? source.length : end);
}

import 'dart:io';

import 'package:figuredout_ui/figuredout_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// WCAG contrast for every semantic ink, in both themes, **and against its
/// `-soft` companion composited over the surface** — that composite is what a
/// badge or an info banner actually produces, and it is where the web package
/// found `--color-success` failing AA at 2.77:1.
///
/// On a green run this rewrites `docs/contrast-report.md`, so the report can
/// never go stale: it is a build artefact of the check, not a document someone
/// remembers to update.
void main() {
  const double aaBody = 4.5;
  const double aaLarge = 3.0;

  final List<_Row> rows = <_Row>[];

  void check({
    required String theme,
    required String ink,
    required String on,
    required Color inkColor,
    required Color onColor,
    required double threshold,
    required String note,
  }) {
    final double ratio = _contrast(inkColor, onColor);
    final _Waiver? waiver = _waivers['$theme/$ink on $on'];
    rows.add(
      _Row(
        theme: theme,
        ink: ink,
        on: on,
        ratio: ratio,
        threshold: threshold,
        waiver: waiver,
        note: note,
      ),
    );

    if (waiver == null) {
      expect(
        ratio,
        greaterThanOrEqualTo(threshold),
        reason: '$theme: $ink on $on is ${ratio.toStringAsFixed(2)}:1, below '
            '$threshold:1. Fix the colour in @figuredout/ui-web first so the '
            'two packages stay in step, then re-port it — do not adjust it '
            'here, and do not lower the threshold.',
      );
      return;
    }

    // A waived pair is allowed to be below the threshold, but it may not drift
    // further down, and once it clears the threshold the waiver must go —
    // otherwise waivers outlive the problem they document.
    expect(
      ratio,
      greaterThanOrEqualTo(waiver.floor),
      reason: '$theme: $ink on $on regressed to ${ratio.toStringAsFixed(2)}:1, '
          'below its recorded floor of ${waiver.floor}:1.',
    );
    expect(
      ratio,
      lessThan(threshold),
      reason: '$theme: $ink on $on now clears $threshold:1 — delete its entry '
          'from _waivers in this test and from docs/contrast-report.md.',
    );
  }

  void measureTheme(String theme, FoColors c, FoChartColors charts) {
    final Map<String, Color> surfaces = <String, Color>{
      'bg': c.bg,
      'surface': c.surface,
      'surfaceRaised': c.surfaceRaised,
      'surfaceSunken': c.surfaceSunken,
    };

    final Map<String, Color> neutralInk = <String, Color>{
      'fg': c.fg,
      'fgMuted': c.fgMuted,
      'fgSubtle': c.fgSubtle,
    };

    final Map<String, Color> semanticInk = <String, Color>{
      'primary': c.primary,
      'primaryHover': c.primaryHover,
      'success': c.success,
      'warning': c.warning,
      'danger': c.danger,
      'info': c.info,
      'accent': c.accent,
    };

    for (final MapEntry<String, Color> ink in <MapEntry<String, Color>>[
      ...neutralInk.entries,
      ...semanticInk.entries,
    ]) {
      for (final MapEntry<String, Color> surface in surfaces.entries) {
        check(
          theme: theme,
          ink: ink.key,
          on: surface.key,
          inkColor: ink.value,
          onColor: surface.value,
          threshold: aaBody,
          note: 'body text',
        );
      }
    }

    // The composite a badge, a chip or an info banner produces: the ink on its
    // own wash, over the surface the wash is painted on. See G10.
    final Map<String, Color> washes = <String, Color>{
      'primary': c.primarySoft,
      'success': c.successSoft,
      'warning': c.warningSoft,
      'danger': c.dangerSoft,
      'info': c.infoSoft,
    };
    for (final MapEntry<String, Color> wash in washes.entries) {
      check(
        theme: theme,
        ink: wash.key,
        on: '${wash.key}Soft over surface',
        inkColor: semanticInk[wash.key]!,
        onColor: Color.alphaBlend(wash.value, c.surface),
        threshold: aaBody,
        note: 'body text on its own wash',
      );
    }

    // Ink that rides on a solid semantic fill — a filled button, a solid chip.
    final List<List<Object>> solids = <List<Object>>[
      <Object>['primaryFg', c.primaryFg, 'primary', c.primary],
      <Object>['primaryFg', c.primaryFg, 'primaryHover', c.primaryHover],
      <Object>['dangerFg', c.dangerFg, 'danger', c.danger],
      <Object>['accentFg', c.accentFg, 'accent', c.accent],
    ];
    for (final List<Object> solid in solids) {
      check(
        theme: theme,
        ink: solid[0] as String,
        on: solid[2] as String,
        inkColor: solid[1] as Color,
        onColor: solid[3] as Color,
        threshold: aaBody,
        note: 'ink on a solid fill',
      );
    }

    // Chart series are large marks, not body text: 3:1 is the bar.
    for (int i = 0; i < charts.categorical.length; i++) {
      check(
        theme: theme,
        ink: 'chartCat${i + 1}',
        on: 'surface',
        inkColor: charts.series(i),
        onColor: c.surface,
        threshold: aaLarge,
        note: 'chart series',
      );
    }
  }

  test('every semantic ink clears WCAG AA on its surfaces and its wash', () {
    measureTheme('light', FoColors.light, FoChartColors.light);
    measureTheme('dark', FoColors.dark, FoChartColors.dark);
    expect(rows, isNotEmpty);
  });

  tearDownAll(() {
    if (rows.isEmpty) return;
    File('docs/contrast-report.md').writeAsStringSync(_report(rows));
  });
}

/// Pairs that are below their threshold, measured, accepted for now, and
/// **owned by the web package** — the colours are ported verbatim from
/// `styles/tokens.css` (plan §2), so the fix belongs there, not here.
///
/// Both entries are light-mode `primary` (`#15803d`), which is the same shape
/// of problem the web package already fixed once for `--color-success`.
const Map<String, _Waiver> _waivers = <String, _Waiver>{
  'light/primary on surfaceSunken': _Waiver(
    floor: 4.0,
    why: 'primary #15803d reaches only 4.16:1 on the sunken step. Primary as '
        'body text inside a well is rare; primary as a large mark or an icon '
        'there still clears 3:1.',
  ),
  'light/primary on primarySoft over surface': _Waiver(
    floor: 4.0,
    why: 'primary #15803d on its own 12% wash reaches 4.11:1 — the exact '
        'composite a chip or a badge produces. Fix in @figuredout/ui-web by '
        'darkening primary the way --color-success was darkened, then re-port.',
  ),
};

@immutable
class _Waiver {
  const _Waiver({required this.floor, required this.why});

  /// The ratio this pair may not fall below.
  final double floor;
  final String why;
}

class _Row {
  _Row({
    required this.theme,
    required this.ink,
    required this.on,
    required this.ratio,
    required this.threshold,
    required this.waiver,
    required this.note,
  });

  final String theme;
  final String ink;
  final String on;
  final double ratio;
  final double threshold;
  final _Waiver? waiver;
  final String note;

  String get verdict {
    if (waiver != null) return '⚠︎ waived';
    return ratio >= threshold ? '✅' : '❌';
  }
}

double _contrast(Color a, Color b) {
  final double la = a.computeLuminance();
  final double lb = b.computeLuminance();
  final double hi = la > lb ? la : lb;
  final double lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

String _report(List<_Row> rows) {
  final StringBuffer out = StringBuffer()
    ..writeln('# Contrast report')
    ..writeln()
    ..writeln(
      'Generated by `test/tokens/contrast_test.dart`. Do not edit by hand — '
      'run `flutter test` and it is rewritten.',
    )
    ..writeln()
    ..writeln(
      'Body text is measured at 4.5:1 and chart series at 3:1. Semantic ink '
      'is also measured against its `-soft` companion composited over '
      '`surface`, because that is the ground a badge or an info banner '
      'actually gives it.',
    )
    ..writeln();

  for (final String theme in <String>['light', 'dark']) {
    out
      ..writeln('## ${theme[0].toUpperCase()}${theme.substring(1)}')
      ..writeln()
      ..writeln('| Ink | On | Ratio | Target | | Kind |')
      ..writeln('| --- | --- | ---: | ---: | --- | --- |');
    for (final _Row row in rows.where((_Row r) => r.theme == theme)) {
      out.writeln(
        '| `${row.ink}` | `${row.on}` | ${row.ratio.toStringAsFixed(2)}:1 '
        '| ${row.threshold.toStringAsFixed(1)}:1 | ${row.verdict} '
        '| ${row.note} |',
      );
    }
    out.writeln();
  }

  final Iterable<_Row> waived = rows.where((_Row r) => r.waiver != null);
  if (waived.isNotEmpty) {
    out
      ..writeln('## Waived')
      ..writeln()
      ..writeln(
        'These are below AA, measured, and accepted for now. The colours are '
        'ported verbatim from `@figuredout/ui-web`, so the fix belongs in that '
        'package first — see the plan, §2.',
      )
      ..writeln();
    for (final _Row row in waived) {
      out.writeln(
        '- **${row.theme}: `${row.ink}` on `${row.on}` — '
        '${row.ratio.toStringAsFixed(2)}:1** (floor '
        '${row.waiver!.floor.toStringAsFixed(1)}:1). ${row.waiver!.why}',
      );
    }
    out.writeln();
  }

  return out.toString();
}

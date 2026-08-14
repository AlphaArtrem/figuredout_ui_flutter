import 'package:figuredout_ui/figuredout_ui.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

import '../../support/doc_page.dart';

/// The spacing and radius scales at true size, plus the two measurements that
/// are not negotiable on a shop floor: the 48dp touch target and the 56dp
/// field.
class SpacingRuler extends StatelessWidget {
  /// Creates the spacing page.
  const SpacingRuler({super.key});

  static const Map<String, String> _purpose = <String, String>{
    'xs': 'Between a label and the thing it labels.',
    'sm': 'Inside a control.',
    'md': 'Between controls in a row.',
    'lg': 'A card’s padding, a form’s row gap.',
    'xl': 'Between sections.',
    'xxl': 'Between page regions.',
    'xxxl': 'A page’s own edges on a wide window.',
  };

  @override
  Widget build(BuildContext context) {
    return const DocPage(
      title: 'Spacing',
      lede:
          'Kept from Luxe rather than ported from the web package: these apps '
          'are used with a gloved finger on a tablet, so the rem-based, '
          'pointer-tuned web scale does not transfer.',
      children: <Widget>[
        DocSection(title: 'Scale', child: _SpacingBars()),
        DocSection(title: 'Radii', child: _RadiusRow()),
        DocSection(title: 'Non-negotiables', child: _Minimums()),
        DocSection(title: 'Gutter', child: _GutterTable()),
      ],
    );
  }

  /// Exposed for [_SpacingBars]; kept beside the scale it annotates.
  static String purposeOf(String step) => _purpose[step] ?? '';
}

class _SpacingBars extends StatelessWidget {
  const _SpacingBars();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: context.foSpacing.toMap().entries.map((
        MapEntry<String, double> e,
      ) {
        return Padding(
          padding: EdgeInsets.only(bottom: context.foSpacing.md),
          child: Row(
            children: <Widget>[
              SizedBox(
                width: 56,
                child: Text(e.key, style: context.foText.caption),
              ),
              SizedBox(
                width: 56,
                child: Text(
                  '${e.value.round()}',
                  style: context.foText.numeric,
                ),
              ),
              Container(
                width: e.value,
                height: 16,
                color: context.foColors.primary,
              ),
              SizedBox(width: context.foSpacing.lg),
              Expanded(
                child: Text(
                  SpacingRuler.purposeOf(e.key),
                  style: context.foText.body.copyWith(
                    color: context.foColors.fgSubtle,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _RadiusRow extends StatelessWidget {
  const _RadiusRow();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: context.foSpacing.lg,
      runSpacing: context.foSpacing.lg,
      children: context.foRadii.toMap().entries.map((
        MapEntry<String, double> e,
      ) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 96,
              height: 64,
              decoration: BoxDecoration(
                color: context.foColors.surface,
                borderRadius: BorderRadius.circular(e.value),
                border: Border.all(color: context.foColors.edgeStrong),
              ),
            ),
            SizedBox(height: context.foSpacing.xs),
            Text(e.key, style: context.foText.caption),
            Text('${e.value.round()}', style: context.foText.numeric),
          ],
        );
      }).toList(),
    );
  }
}

class _Minimums extends StatelessWidget {
  const _Minimums();

  static const double _columnWidth = 200;

  static const List<(String, double, String)> _entries =
      <(String, double, String)>[
    (
      'minTouchTarget',
      FoLayout.minTouchTarget,
      'Never shrink it for a denser desktop layout — the same build runs '
          'on the tablet.',
    ),
    (
      'singleLineFieldHeight',
      FoLayout.singleLineFieldHeight,
      'One line of text plus enough room to hit it without looking.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    // Each box is drawn at its true height but centred in a band as tall as
    // the tallest, so the boxes share a centre line and the captions below
    // them share a baseline. Sizing the band off the entries rather than
    // hardcoding 56 means a third measurement cannot silently break the row.
    final double band = _entries
        .map(((String, double, String) e) => e.$2)
        .reduce((double a, double b) => a > b ? a : b);

    Widget box(String label, double height, String why) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SizedBox(
              width: _columnWidth,
              height: band,
              child: Center(
                child: Container(
                  height: height,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: context.foColors.primarySoft,
                    borderRadius: BorderRadius.circular(context.foRadii.md),
                    border: Border.all(color: context.foColors.primary),
                  ),
                  child: Text(
                    '${height.round()}dp',
                    style: context.foText.numeric.copyWith(
                      color: context.foColors.primary,
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: context.foSpacing.xs),
            Text(label.toUpperCase(), style: context.foText.caption),
            SizedBox(
              width: _columnWidth,
              child: Text(
                why,
                style: context.foText.body.copyWith(
                  color: context.foColors.fgSubtle,
                ),
              ),
            ),
          ],
        );

    return Wrap(
      spacing: context.foSpacing.xxl,
      runSpacing: context.foSpacing.xl,
      children: _entries
          .map(((String, double, String) e) => box(e.$1, e.$2, e.$3))
          .toList(),
    );
  }
}

/// `FoLayout.gutter` is the Dart form of the web's
/// `--gut: clamp(1rem, 4vw, 2.5rem)`; the three window classes are shown so
/// the clamp's shape is visible rather than trusted.
class _GutterTable extends StatelessWidget {
  const _GutterTable();

  @override
  Widget build(BuildContext context) {
    const List<double> widths = <double>[360, 480, 760, 1280, 1600];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widths.map((double w) {
        final FoWindowClass band = FoWindowClass.forWidth(w);
        return Padding(
          padding: EdgeInsets.only(bottom: context.foSpacing.xs),
          child: Text(
            '${w.round().toString().padLeft(5)} → gutter '
            '${FoLayout.gutter(w).round().toString().padLeft(2)}   '
            '${band.name}',
            style: context.foText.numeric,
          ),
        );
      }).toList(),
    );
  }
}

/// The scales at true size, and the two minimums the shop floor imposes.
@widgetbook.UseCase(
  name: 'Spacing ruler',
  type: SpacingRuler,
  path: '01 Foundations',
)
Widget buildSpacingRuler(BuildContext context) => const SpacingRuler();

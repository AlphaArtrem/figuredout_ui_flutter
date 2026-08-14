import 'package:figuredout_ui/figuredout_ui.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

import '../../support/doc_page.dart';

/// The seven steps of the ramp, each labelled with what it is *for* — the
/// question that decides which one to reach for is never "how big".
class TypeRamp extends StatelessWidget {
  /// Creates the type page.
  const TypeRamp({super.key});

  static const Map<String, String> _purpose = <String, String>{
    'display': 'The page-level scale. Two or three per screen, at most.',
    'title': 'A section.',
    'subtitle': 'A subsection, or a control that carries its own heading.',
    'body': 'Prose, table cells, everything unmarked.',
    'label': 'A form label — it instructs, so it stays sans.',
    'caption': 'Mono, uppercase: it NAMES a value.',
    'numeric': 'Mono, tabular: it IS a value.',
  };

  static const Map<String, String> _sample = <String, String>{
    'display': 'Production overview',
    'title': 'Cutting plans',
    'subtitle': 'Open entries',
    'body': 'Every stage carries its own planned and actual quantity.',
    'label': 'Order quantity',
    'caption': 'Rejected',
    'numeric': '1,204,880  /  0.318  /  17:42',
  };

  @override
  Widget build(BuildContext context) {
    final FoTextStyles t = context.foText;
    return DocPage(
      title: 'Type',
      lede:
          'Geist and Geist Mono, bundled with the package rather than fetched, '
          'because the consuming apps are offline-first. Two families, and the '
          'split carries meaning: mono uppercase captions name values, mono '
          'tabular figures are values.',
      children: <Widget>[
        DocSection(
          title: 'The ramp',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: t.toMap().entries.map((MapEntry<String, TextStyle> e) {
              final bool isCaption = e.key == 'caption';
              return Padding(
                padding: EdgeInsets.only(bottom: context.foSpacing.xl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        SizedBox(
                          width: 96,
                          child: Text(e.key, style: t.caption),
                        ),
                        Text(
                          '${e.value.fontSize?.round()} · '
                          'w${e.value.fontWeight?.value ?? 400}',
                          style: t.caption,
                        ),
                      ],
                    ),
                    SizedBox(height: context.foSpacing.xs),
                    Text(
                      isCaption
                          ? _sample[e.key]!.toUpperCase()
                          : _sample[e.key]!,
                      style: e.value,
                    ),
                    SizedBox(height: context.foSpacing.xs),
                    Text(
                      _purpose[e.key]!,
                      style: t.body.copyWith(color: context.foColors.fgSubtle),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
        const DocSection(
          title: 'Tabular figures',
          child: _TabularProof(),
        ),
        const DocSection(
          title: 'The font actually resolved',
          child: _FontProof(),
        ),
      ],
    );
  }
}

/// Why `numeric` exists: the same column of figures, set in body and in
/// numeric. Body digits are proportional, so the column will not line up.
class _TabularProof extends StatelessWidget {
  const _TabularProof();

  static const List<String> _rows = <String>['1,111', '4,890', '11,004', '999'];

  @override
  Widget build(BuildContext context) {
    Widget column(String heading, TextStyle style) => Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            Text(heading.toUpperCase(), style: context.foText.caption),
            SizedBox(height: context.foSpacing.sm),
            ..._rows.map((String r) => Text(r, style: style)),
          ],
        );

    return Row(
      children: <Widget>[
        column('body — drifts', context.foText.body),
        SizedBox(width: context.foSpacing.xxl),
        column('numeric — aligns', context.foText.numeric),
      ],
    );
  }
}

/// G2: without `package: 'figuredout_ui'` a family resolves against the
/// consuming app's manifest and falls back to Roboto, silently. The resolved
/// family is printed here so the fallback is visible rather than merely
/// asserted in a test the consuming app never runs.
class _FontProof extends StatelessWidget {
  const _FontProof();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: context.foText.toMap().entries.map((
        MapEntry<String, TextStyle> e,
      ) {
        return Text(
          '${e.key.padRight(10)} ${e.value.fontFamily}',
          style: context.foText.numeric.copyWith(
            fontSize: FoTokens.fontCaption,
            color: context.foColors.fgMuted,
          ),
        );
      }).toList(),
    );
  }
}

/// The ramp, with the purpose of each step. Raise the text-scale addon to 1.6
/// before calling a layout done.
@widgetbook.UseCase(
  name: 'Type ramp',
  type: TypeRamp,
  path: '01 Foundations',
)
Widget buildTypeRamp(BuildContext context) => const TypeRamp();

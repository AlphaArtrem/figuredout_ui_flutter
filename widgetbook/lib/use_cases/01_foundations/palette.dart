import 'package:figuredout_ui/figuredout_ui.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

import '../../support/doc_page.dart';

/// The colour set, with every ratio measured against the ground it is actually
/// painted on. Switch the theme addon to see both.
class Palette extends StatelessWidget {
  /// Creates the palette page.
  const Palette({super.key});

  @override
  Widget build(BuildContext context) {
    final FoColors c = context.foColors;
    return DocPage(
      title: 'Palette',
      lede: 'Ported verbatim from @figuredout/ui-web. Every ratio below is '
          'measured at render time, so a token change shows up here at the '
          'same moment it shows up in docs/contrast-report.md.',
      children: <Widget>[
        DocSection(
          title: 'The surface ladder',
          child: _SurfaceLadder(colors: c),
        ),
        DocSection(
          title: 'Ink',
          child: _Swatches(
            entries: <_Entry>[
              _Entry('fg', c.fg, c.surface),
              _Entry('fgMuted', c.fgMuted, c.surface),
              _Entry('fgSubtle', c.fgSubtle, c.surface),
              _Entry('edge', c.edge, c.surface, measured: false),
              _Entry('edgeStrong', c.edgeStrong, c.surface, measured: false),
            ],
          ),
        ),
        DocSection(
          title: 'Semantic',
          child: _Swatches(
            entries: <_Entry>[
              _Entry('primary', c.primary, c.surface),
              _Entry('primaryHover', c.primaryHover, c.surface),
              _Entry('success', c.success, c.surface),
              _Entry('warning', c.warning, c.surface),
              _Entry('danger', c.danger, c.surface),
              _Entry('info', c.info, c.surface),
              _Entry('accent', c.accent, c.surface),
            ],
          ),
        ),
        DocSection(
          title: 'Ink on its own wash',
          child: _WashRow(colors: c),
        ),
        DocSection(
          title: 'Ink on a solid fill',
          child: Wrap(
            spacing: context.foSpacing.md,
            runSpacing: context.foSpacing.md,
            children: <Widget>[
              _SolidChip(label: 'primaryFg', ink: c.primaryFg, on: c.primary),
              _SolidChip(label: 'dangerFg', ink: c.dangerFg, on: c.danger),
              _SolidChip(label: 'accentFg', ink: c.accentFg, on: c.accent),
            ],
          ),
        ),
      ],
    );
  }
}

/// The four steps, in the order that is their meaning. Each sits inside the
/// one below it, so the separation you can see here is the separation a real
/// component gets — hairlines included.
class _SurfaceLadder extends StatelessWidget {
  const _SurfaceLadder({required this.colors});

  final FoColors colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(context.foSpacing.lg),
      color: colors.bg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _label(context, 'bg — the page', colors.bg),
          SizedBox(height: context.foSpacing.md),
          _step(
            context,
            'surface — cards, tables, panels',
            colors.surface,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _step(
                  context,
                  'surfaceRaised — dialog, menu, toast, hovered row',
                  colors.surfaceRaised,
                ),
                SizedBox(height: context.foSpacing.md),
                _step(
                  context,
                  'surfaceSunken — fields, tracks, wells',
                  colors.surfaceSunken,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _step(
    BuildContext context,
    String name,
    Color color, {
    Widget? child,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(context.foSpacing.lg),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(context.foRadii.card),
        border: Border.all(color: colors.edge),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _label(context, name, color),
          if (child != null) ...<Widget>[
            SizedBox(height: context.foSpacing.md),
            child,
          ],
        ],
      ),
    );
  }

  /// A Wrap rather than a Row: at the compact viewport the deepest step's name
  /// plus its hex is wider than the step it sits in, and a Row would clip the
  /// hex rather than move it.
  Widget _label(BuildContext context, String name, Color color) => Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: context.foSpacing.sm,
        children: <Widget>[
          Text(name, style: context.foText.label),
          Text(hexOf(color), style: context.foText.caption),
        ],
      );
}

class _Entry {
  const _Entry(this.name, this.color, this.on, {this.measured = true});

  final String name;
  final Color color;
  final Color on;

  /// False for hairlines: a 1dp rule is not text and has no AA target, so
  /// printing a ratio beside it would invite someone to "fix" it.
  final bool measured;
}

class _Swatches extends StatelessWidget {
  const _Swatches({required this.entries});

  final List<_Entry> entries;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: context.foSpacing.md,
      runSpacing: context.foSpacing.md,
      children: entries.map((_Entry e) => _Swatch(entry: e)).toList(),
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({required this.entry});

  final _Entry entry;

  @override
  Widget build(BuildContext context) {
    final double ratio = contrastRatio(entry.color, entry.on);
    return Container(
      width: 220,
      padding: EdgeInsets.all(context.foSpacing.md),
      decoration: BoxDecoration(
        color: context.foColors.surface,
        borderRadius: BorderRadius.circular(context.foRadii.card),
        border: Border.all(color: context.foColors.edge),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            height: 48,
            decoration: BoxDecoration(
              color: entry.color,
              borderRadius: BorderRadius.circular(context.foRadii.sm),
              border: Border.all(color: context.foColors.edge),
            ),
          ),
          SizedBox(height: context.foSpacing.sm),
          Text(entry.name, style: context.foText.label),
          Text(hexOf(entry.color), style: context.foText.caption),
          if (entry.measured)
            Text(
              '${ratio.toStringAsFixed(2)}:1 on surface',
              style: context.foText.numeric.copyWith(
                fontSize: FoTokens.fontCaption,
                color: ratio >= 4.5
                    ? context.foColors.success
                    : context.foColors.warning,
              ),
            )
          else
            Text('hairline — not text', style: context.foText.caption),
        ],
      ),
    );
  }
}

/// G10: semantic ink is measured against its soft wash composited over the
/// surface, not against the surface. That composite is what a chip or an info
/// banner actually produces, and it is where the web package found
/// `--color-success` failing AA.
class _WashRow extends StatelessWidget {
  const _WashRow({required this.colors});

  final FoColors colors;

  @override
  Widget build(BuildContext context) {
    final List<List<Object>> pairs = <List<Object>>[
      <Object>['primary', colors.primary, colors.primarySoft],
      <Object>['success', colors.success, colors.successSoft],
      <Object>['warning', colors.warning, colors.warningSoft],
      <Object>['danger', colors.danger, colors.dangerSoft],
      <Object>['info', colors.info, colors.infoSoft],
    ];
    return Wrap(
      spacing: context.foSpacing.md,
      runSpacing: context.foSpacing.md,
      children: pairs.map((List<Object> pair) {
        final String name = pair[0] as String;
        final Color ink = pair[1] as Color;
        final Color wash = pair[2] as Color;
        final Color composite = Color.alphaBlend(wash, colors.surface);
        final double ratio = contrastRatio(ink, composite);
        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: context.foSpacing.md,
            vertical: context.foSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: composite,
            borderRadius: BorderRadius.circular(context.foRadii.sm),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                name,
                style: context.foText.label.copyWith(color: ink),
              ),
              Text(
                '${ratio.toStringAsFixed(2)}:1',
                style: context.foText.numeric.copyWith(
                  fontSize: FoTokens.fontCaption,
                  color: ink,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _SolidChip extends StatelessWidget {
  const _SolidChip({required this.label, required this.ink, required this.on});

  final String label;
  final Color ink;
  final Color on;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.foSpacing.lg,
        vertical: context.foSpacing.md,
      ),
      decoration: BoxDecoration(
        color: on,
        borderRadius: BorderRadius.circular(context.foRadii.md),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(label, style: context.foText.label.copyWith(color: ink)),
          Text(
            '${contrastRatio(ink, on).toStringAsFixed(2)}:1',
            style: context.foText.numeric.copyWith(
              fontSize: FoTokens.fontCaption,
              color: ink,
            ),
          ),
        ],
      ),
    );
  }
}

/// The whole colour set with live contrast ratios. Flip the theme addon: a
/// token that only reads in one theme is not finished.
@widgetbook.UseCase(
  name: 'Palette',
  type: Palette,
  path: '01 Foundations',
)
Widget buildPalette(BuildContext context) => const Palette();

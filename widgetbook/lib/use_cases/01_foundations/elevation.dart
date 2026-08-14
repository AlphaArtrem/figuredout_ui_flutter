import 'package:figuredout_ui/figuredout_ui.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

import '../../support/doc_page.dart';

/// The three elevation steps, on the surface each one belongs to. There is no
/// fourth step, and no `Material(elevation:)` anywhere in the package.
class Elevation extends StatelessWidget {
  /// Creates the elevation page.
  const Elevation({super.key});

  @override
  Widget build(BuildContext context) {
    return const DocPage(
      title: 'Elevation',
      lede: 'Three steps: raised rests, hover is picked up, overlay covers '
          'something else. They are hue-matched to the ground rather than '
          'black, because a black shadow on a tinted surface greys out the '
          'colour beneath it and reads as dirt.',
      children: <Widget>[
        DocSection(title: 'The three steps', child: _Steps()),
        DocSection(title: 'Hairline placement', child: _HairlineDemo()),
      ],
    );
  }
}

class _Steps extends StatelessWidget {
  const _Steps();

  static const Map<String, String> _purpose = <String, String>{
    'raised': 'At rest on the page: a card, a table, a panel.',
    'hover': 'Picked up: a hovered card, a dragged row.',
    'overlay': 'Covering something else: a dialog, a menu, a toast.',
  };

  @override
  Widget build(BuildContext context) {
    // overlay sits on the raised step, because that is where an overlay lives.
    const Set<String> onRaised = <String>{'overlay'};

    return Wrap(
      spacing: context.foSpacing.xxl,
      runSpacing: context.foSpacing.xxl,
      children: context.foShadows.toMap().entries.map((
        MapEntry<String, List<BoxShadow>> e,
      ) {
        final Color surface = onRaised.contains(e.key)
            ? context.foColors.surfaceRaised
            : context.foColors.surface;
        return SizedBox(
          width: 260,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                height: 120,
                margin: EdgeInsets.only(bottom: context.foSpacing.lg),
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(context.foRadii.card),
                  boxShadow: e.value,
                ),
                foregroundDecoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(context.foRadii.card),
                  border: Border.all(color: context.foColors.edge),
                ),
              ),
              Text(e.key.toUpperCase(), style: context.foText.caption),
              SizedBox(height: context.foSpacing.xs),
              Text(
                _purpose[e.key]!,
                style: context.foText.body.copyWith(
                  color: context.foColors.fgSubtle,
                ),
              ),
              SizedBox(height: context.foSpacing.xs),
              Text(
                e.value
                    .map(
                      (BoxShadow s) =>
                          '0 ${s.offset.dy.round()} ${s.blurRadius.round()}',
                    )
                    .join('  ·  '),
                style: context.foText.numeric.copyWith(
                  fontSize: FoTokens.fontCaption,
                  color: context.foColors.fgMuted,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

/// Rule §3.1 / G3, shown rather than described: a `ClipRRect`-clipped child
/// that paints a full-bleed band covers the parent's `decoration.border` along
/// that edge. The same card is drawn twice — the left one uses
/// `decoration.border` and loses its top hairline; the right one uses
/// `foregroundDecoration` and keeps it.
class _HairlineDemo extends StatelessWidget {
  const _HairlineDemo();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: context.foSpacing.xxl,
      runSpacing: context.foSpacing.xl,
      children: <Widget>[
        _card(context, foreground: false, label: 'decoration.border — wrong'),
        _card(context, foreground: true, label: 'foregroundDecoration — right'),
      ],
    );
  }

  Widget _card(
    BuildContext context, {
    required bool foreground,
    required String label,
  }) {
    final BoxDecoration hairline = BoxDecoration(
      borderRadius: BorderRadius.circular(context.foRadii.card),
      border: Border.all(color: context.foColors.edgeStrong),
    );
    final Widget body = ClipRRect(
      borderRadius: BorderRadius.circular(context.foRadii.card),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          // The full-bleed band. This is what eats the parent's border.
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(context.foSpacing.md),
            color: context.foColors.primarySoft,
            child: Text(
              'Header band',
              style: context.foText.label.copyWith(
                color: context.foColors.primary,
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(context.foSpacing.lg),
            child: Text('Body', style: context.foText.body),
          ),
        ],
      ),
    );

    return SizedBox(
      width: 280,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            decoration: foreground
                ? BoxDecoration(
                    color: context.foColors.surface,
                    borderRadius: BorderRadius.circular(context.foRadii.card),
                  )
                : hairline.copyWith(color: context.foColors.surface),
            foregroundDecoration: foreground ? hairline : null,
            child: body,
          ),
          SizedBox(height: context.foSpacing.sm),
          Text(label.toUpperCase(), style: context.foText.caption),
        ],
      ),
    );
  }
}

/// The three steps, and the reason a hairline goes in `foregroundDecoration`.
@widgetbook.UseCase(
  name: 'Elevation',
  type: Elevation,
  path: '01 Foundations',
)
Widget buildElevation(BuildContext context) => const Elevation();

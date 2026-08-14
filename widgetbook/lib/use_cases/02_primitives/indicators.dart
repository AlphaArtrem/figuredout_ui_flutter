import 'package:figuredout_ui/figuredout_ui.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

import '../../support/doc_page.dart';

/// The status chip, both ways of building one.
class StatusChips extends StatelessWidget {
  /// Creates the chip page.
  const StatusChips({super.key});

  @override
  Widget build(BuildContext context) {
    return DocPage(
      title: 'Status chip',
      lede: 'The chip holds no status-to-colour mapping — that vocabulary '
          'belongs to the app, which is the only place that knows what '
          '"submitted" means here.',
      children: <Widget>[
        DocSection(
          title: 'Tones — ink and ground both from tokens',
          child: Wrap(
            spacing: context.foSpacing.md,
            runSpacing: context.foSpacing.md,
            children: <Widget>[
              for (final FoStatusTone tone in FoStatusTone.values)
                FoStatusChip.tone(
                  label: tone.name,
                  tone: tone,
                  semanticPrefix: 'Status',
                ),
            ],
          ),
        ),
        DocSection(
          title: 'An arbitrary accent',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Wrap(
                spacing: context.foSpacing.md,
                children: <Widget>[
                  FoStatusChip(
                    label: 'Custom',
                    color: context.foColors.accent,
                  ),
                  FoStatusChip(
                    label: 'Also custom',
                    color: context.foColors.fgSubtle,
                  ),
                ],
              ),
              SizedBox(height: context.foSpacing.sm),
              Text(
                'Same weight, but the pairing is not one contrast_test '
                'measures — prefer a tone where one fits, and own the '
                'contrast yourself where none does.',
                style: context.foText.body.copyWith(
                  color: context.foColors.fgSubtle,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Skeletons and spinners, and when each is the right answer.
class LoadingStates extends StatelessWidget {
  /// Creates the loading page.
  const LoadingStates({super.key});

  @override
  Widget build(BuildContext context) {
    return DocPage(
      title: 'Loading',
      lede: 'A spinner tells you to wait; a skeleton tells you what you are '
          'waiting for, and holds the layout still so nothing jumps when the '
          'data lands. Reach for the skeleton unless the thing loading is a '
          'control.',
      children: <Widget>[
        DocSection(
          title: 'Skeletons',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const FoSkeleton.line(width: 220),
              SizedBox(height: context.foSpacing.sm),
              const FoSkeleton.line(width: 160),
              SizedBox(height: context.foSpacing.lg),
              const FoSkeleton.box(height: 80),
              SizedBox(height: context.foSpacing.lg),
              const FoSkeleton.card(),
            ],
          ),
        ),
        const DocSection(
          title: 'A loading list',
          child: FoSkeletonList(itemCount: 3),
        ),
        DocSection(
          title: 'Spinners',
          child: Row(
            children: <Widget>[
              const FoSpinner(semanticsLabel: 'Loading'),
              SizedBox(width: context.foSpacing.xl),
              const FoSpinner(
                size: FoSpinnerSize.medium,
                semanticsLabel: 'Loading',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// The boolean cell and the hint dot — two small things that exist so the same
/// fact is not shown two ways.
class Cells extends StatelessWidget {
  /// Creates the cells page.
  const Cells({super.key});

  @override
  Widget build(BuildContext context) {
    return DocPage(
      title: 'Cells and hints',
      lede: 'A boolean cell shows a mark and announces the word, so a dense '
          'table stays scannable without losing anything to a screen reader. '
          'A hint dot explains a term where the term is.',
      children: <Widget>[
        DocSection(
          title: 'Boolean cell',
          child: Row(
            children: <Widget>[
              const FoBooleanCell(
                value: true,
                yesLabel: 'Yes',
                noLabel: 'No',
                label: 'Active',
              ),
              SizedBox(width: context.foSpacing.xl),
              const FoBooleanCell(
                value: false,
                yesLabel: 'Yes',
                noLabel: 'No',
                label: 'Active',
              ),
              SizedBox(width: context.foSpacing.xl),
              Expanded(
                child: Text(
                  'False is muted ink, not danger — it is not a failure.',
                  style: context.foText.body.copyWith(
                    color: context.foColors.fgSubtle,
                  ),
                ),
              ),
            ],
          ),
        ),
        DocSection(
          title: 'Hint',
          child: Row(
            children: <Widget>[
              Flexible(
                child: Text('Rejected quantity', style: context.foText.label),
              ),
              const FoHint(
                message: 'The quantity discarded after cutting, not counted in '
                    'the stage output.',
                buttonLabel: 'What is this?',
              ),
              SizedBox(width: context.foSpacing.lg),
              Expanded(
                child: Text(
                  'Hover it on a wide window. Switch the viewport addon to '
                  'Compact 480 and the tooltip goes away — there is no '
                  'pointer to hover with, so the message routes to the app\'s '
                  'toast through onCompactTap instead.',
                  style: context.foText.body.copyWith(
                    color: context.foColors.fgSubtle,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// The focus ring on its own, so the one treatment can be seen in isolation.
class FocusRings extends StatelessWidget {
  /// Creates the focus-ring page.
  const FocusRings({super.key});

  @override
  Widget build(BuildContext context) {
    return DocPage(
      title: 'Focus ring',
      lede: 'Flutter has no global focus ring — every Material widget invents '
          'its own. Every interactive Fo component composes this one instead. '
          'Tab through the buttons below: the ring is identical on all of '
          'them, which is the entire point.',
      children: <Widget>[
        DocSection(
          title: 'Tab through these',
          child: Wrap(
            spacing: context.foSpacing.md,
            runSpacing: context.foSpacing.md,
            children: <Widget>[
              FoButton(
                label: 'Primary',
                variant: FoButtonVariant.primary,
                onPressed: () {},
              ),
              FoButton(
                label: 'Secondary',
                variant: FoButtonVariant.secondary,
                onPressed: () {},
              ),
              FoButton(
                label: 'Clear',
                variant: FoButtonVariant.clear,
                onPressed: () {},
              ),
            ],
          ),
        ),
        DocSection(
          title: 'Around anything',
          child: FoFocusRing(
            child: Focus(
              child: Builder(
                builder: (BuildContext context) => GestureDetector(
                  onTap: () => Focus.of(context).requestFocus(),
                  child: Container(
                    padding: EdgeInsets.all(context.foSpacing.lg),
                    decoration: BoxDecoration(
                      color: context.foColors.surfaceSunken,
                      borderRadius: BorderRadius.circular(context.foRadii.md),
                    ),
                    child: const Text('Tap me, then look at the ring'),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// The floating surface, stated once — menus, tooltips, toasts and popovers
/// all take it rather than each restating it.
class OverlaySurfaces extends StatelessWidget {
  /// Creates the overlay-surface page.
  const OverlaySurfaces({super.key});

  @override
  Widget build(BuildContext context) {
    return DocPage(
      title: 'Overlay surface',
      lede: 'surfaceRaised, the overlay shadow and a hairline — three things '
          'together, and all three matter. Reach for foOverlaySurface instead '
          'of assembling a BoxDecoration in a new component.',
      children: <Widget>[
        DocSection(
          title: 'On the page',
          child: Container(
            padding: EdgeInsets.all(context.foSpacing.xxl),
            color: context.foColors.bg,
            child: Center(
              child: Container(
                width: 260,
                padding: EdgeInsets.all(context.foSpacing.lg),
                decoration: foOverlaySurface(context),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text('Menu', style: context.foText.label),
                    SizedBox(height: context.foSpacing.sm),
                    Text('Duplicate entry', style: context.foText.body),
                    Text('Export as CSV', style: context.foText.body),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// The six tones, and the escape hatch for an app's own vocabulary.
@widgetbook.UseCase(
  name: 'Status chip',
  type: FoStatusChip,
  path: '02 Primitives',
)
Widget buildStatusChips(BuildContext context) => const StatusChips();

/// Skeletons and spinners, and when each one is right.
@widgetbook.UseCase(name: 'Skeleton', type: FoSkeleton, path: '02 Primitives')
Widget buildLoadingStates(BuildContext context) => const LoadingStates();

/// Both spinner sizes, in the system's own ink.
@widgetbook.UseCase(name: 'Spinner', type: FoSpinner, path: '02 Primitives')
Widget buildSpinners(BuildContext context) => const LoadingStates();

/// A yes/no value in a table, and the hint dot beside a term.
@widgetbook.UseCase(
  name: 'Boolean cell',
  type: FoBooleanCell,
  path: '02 Primitives',
)
Widget buildCells(BuildContext context) => const Cells();

/// The adaptive hint: a tooltip where there is a pointer, a toast where there
/// is not.
@widgetbook.UseCase(name: 'Hint', type: FoHint, path: '02 Primitives')
Widget buildHints(BuildContext context) => const Cells();

/// The one focus treatment, in isolation and on real controls.
@widgetbook.UseCase(
  name: 'Focus ring',
  type: FoFocusRing,
  path: '02 Primitives',
)
Widget buildFocusRings(BuildContext context) => const FocusRings();

/// The floating surface every overlay shares.
@widgetbook.UseCase(
  name: 'Overlay surface',
  type: OverlaySurfaces,
  path: '02 Primitives',
)
Widget buildOverlaySurfaces(BuildContext context) => const OverlaySurfaces();

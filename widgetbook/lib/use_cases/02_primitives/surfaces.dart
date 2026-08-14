import 'package:figuredout_ui/figuredout_ui.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

import '../../support/doc_page.dart';

/// `FoCard` at rest, tappable, and holding a full-bleed band — the last of
/// which is the case rule §3.1 exists for.
class Cards extends StatelessWidget {
  /// Creates the card page.
  const Cards({super.key});

  @override
  Widget build(BuildContext context) {
    return DocPage(
      title: 'Card',
      lede: 'The resting surface. Not a Material Card: its hairline lives in '
          'foregroundDecoration so a clipped child cannot cover it, and its '
          'elevation is painted from FoShadows rather than by Material.',
      children: <Widget>[
        const DocSection(
          title: 'At rest',
          child: FoCard(
            child: Text('A card sits on `surface`, one step under white.'),
          ),
        ),
        DocSection(
          title: 'Tappable — hover it',
          child: FoCard(
            onTap: () {},
            semanticLabel: 'Open order 1024',
            child: const Text(
              'Hovering lifts this to `surfaceRaised` with the hover shadow. '
              'A picked-up thing moves up the ladder; that is the ladder '
              'doing its job, not decoration.',
            ),
          ),
        ),
        DocSection(
          title: 'Holding a full-bleed band',
          child: FoCard(
            padding: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Container(
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
                  child: const Text(
                    'The hairline survives along the top edge. Drawn in '
                    'decoration.border it would not — see Foundations › '
                    'Elevation for the two side by side.',
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// `FoSectionSurface` — a titled card whose content runs edge to edge.
class SectionSurfaces extends StatelessWidget {
  /// Creates the section-surface page.
  const SectionSurfaces({super.key});

  @override
  Widget build(BuildContext context) {
    Widget rows(int count) => Column(
          children: <Widget>[
            for (int i = 0; i < count; i++)
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(context.foSpacing.lg),
                decoration: BoxDecoration(
                  border: Border(
                    top: i == 0
                        ? BorderSide.none
                        : BorderSide(color: context.foColors.edge),
                  ),
                ),
                child: Text('Row ${i + 1}', style: context.foText.body),
              ),
          ],
        );

    return DocPage(
      title: 'Section surface',
      lede: 'A framed section: header, rule, then content that reaches the '
          'edges. This is the shape rule §3.1 was written for — the content '
          'is usually a table that paints its own header row full width.',
      children: <Widget>[
        DocSection(
          title: 'Title, subtitle and an action',
          child: FoSectionSurface(
            title: 'Cut entries',
            subtitle: 'Everything logged against this plan today.',
            trailing: FoActionButton(
              label: 'New',
              icon: Icons.add,
              onPressed: () {},
            ),
            child: rows(3),
          ),
        ),
        DocSection(
          title: 'No header',
          child: FoSectionSurface(child: rows(2)),
        ),
      ],
    );
  }
}

/// `FoSectionHeader` at both widths — it stacks off its own width, not the
/// window's.
class SectionHeaders extends StatelessWidget {
  /// Creates the section-header page.
  const SectionHeaders({super.key});

  @override
  Widget build(BuildContext context) {
    // ConstrainedBox, not SizedBox: these widths demonstrate the stacking
    // threshold, and a fixed width wider than the viewport would just
    // overflow at Compact 480 and demonstrate nothing.
    Widget sample(double width) => ConstrainedBox(
          constraints: BoxConstraints(maxWidth: width),
          child: FoCard(
            child: FoSectionHeader(
              title: 'Cut entries',
              hint: const FoHint(
                message: 'The quantity cut before any rejection is recorded.',
                buttonLabel: 'What is this?',
              ),
              trailing: FoActionButton(label: 'New entry', onPressed: () {}),
            ),
          ),
        );

    return DocPage(
      title: 'Section header',
      lede: 'Title, an optional hint dot, an optional action. The title is '
          'marked as a header, which is what lets a screen-reader user jump '
          'between sections instead of reading every card top to bottom.',
      children: <Widget>[
        DocSection(title: 'Wide — inline', child: sample(720)),
        DocSection(
          title: 'Narrow — stacked',
          child: sample(360),
        ),
        const DocSection(
          title: 'No action',
          child: FoCard(child: FoSectionHeader(title: 'Cut entries')),
        ),
      ],
    );
  }
}

/// Card at rest, tappable and holding a banded child.
@widgetbook.UseCase(name: 'Card', type: FoCard, path: '02 Primitives')
Widget buildCards(BuildContext context) => const Cards();

/// A framed section with header, rule and edge-to-edge content.
@widgetbook.UseCase(
  name: 'Section surface',
  type: FoSectionSurface,
  path: '02 Primitives',
)
Widget buildSectionSurfaces(BuildContext context) => const SectionSurfaces();

/// The header, inline and stacked. The threshold is the header's own width.
@widgetbook.UseCase(
  name: 'Section header',
  type: FoSectionHeader,
  path: '02 Primitives',
)
Widget buildSectionHeaders(BuildContext context) => const SectionHeaders();

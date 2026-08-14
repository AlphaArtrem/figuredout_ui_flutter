import 'package:figuredout_ui/figuredout_ui.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

import '../../support/doc_page.dart';

/// Stats, seams and the page header — the dashboard vocabulary.
class DashboardParts extends StatelessWidget {
  /// Creates the dashboard page.
  const DashboardParts({super.key});

  @override
  Widget build(BuildContext context) {
    return DocPage(
      title: 'Stats and seams',
      lede: 'Four stat cards are four shadows the eye has to relate to each '
          'other. One seamed block is a single figure with four parts. Reach '
          'for the grid whenever the numbers belong to the same subject.',
      children: <Widget>[
        const DocSection(
          title: 'A set — one object',
          child: FoSeamGrid(
            children: <Widget>[
              FoSeamCell(
                child: FoStatCardContent(
                  label: 'Cut today',
                  value: '1,290',
                  note: 'up 130 on yesterday',
                  trend: FoTrend.up,
                ),
              ),
              FoSeamCell(
                child: FoStatCardContent(
                  label: 'Stitched',
                  value: '1,150',
                  note: 'down 60',
                  trend: FoTrend.down,
                ),
              ),
              FoSeamCell(
                child: FoStatCardContent(
                  label: 'Rejected',
                  value: '18',
                  note: 'unchanged',
                  trend: FoTrend.flat,
                ),
              ),
              FoSeamCell(
                child: FoStatCardContent(label: 'Open plans', value: '7'),
              ),
            ],
          ),
        ),
        DocSection(
          title: 'One figure on its own',
          child: SizedBox(
            width: 280,
            child: FoStatCard(
              label: 'Cut today',
              value: '1,290',
              note: 'up 130 on yesterday',
              trend: FoTrend.up,
              onTap: () {},
              chart: const FoSparkline(
                values: <num>[1240, 1180, 1310, 980, 1420, 1360, 1290],
              ),
            ),
          ),
        ),
        DocSection(
          title: 'Badges — they count, they do not state',
          child: Wrap(
            spacing: context.foSpacing.md,
            runSpacing: context.foSpacing.md,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              for (final FoStatusTone tone in FoStatusTone.values)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(tone.name, style: context.foText.body),
                    SizedBox(width: context.foSpacing.xs),
                    FoBadge(
                      label: '3',
                      tone: tone,
                      semanticLabel: '3 ${tone.name}',
                    ),
                  ],
                ),
              SizedBox(
                width: double.infinity,
                child: Text(
                  'A chip carries a record\'s state and stands on its own; a '
                  'badge counts the thing it is attached to and is never the '
                  'only place a fact appears.',
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

/// The page header and the description list — the detail-view vocabulary.
class DetailParts extends StatelessWidget {
  /// Creates the detail page.
  const DetailParts({super.key});

  @override
  Widget build(BuildContext context) {
    return DocPage(
      title: 'Page header and detail',
      lede:
          'A page has exactly one FoPageHeader, and it is the only place that '
          'gets the display scale — reserve it, or the scale stops meaning '
          '"this is the page". FoSectionHeader names a region inside one.',
      children: <Widget>[
        DocSection(
          title: 'Page header',
          child: FoPageHeader(
            eyebrow: 'Production · Line A',
            title: 'Cut entries',
            lede: 'Everything logged against this plan today, across all three '
                'shifts.',
            actions: <Widget>[
              FoButton(
                label: 'Export',
                variant: FoButtonVariant.secondary,
                icon: Icons.download_outlined,
                onPressed: () {},
              ),
              FoActionButton(
                label: 'New entry',
                icon: Icons.add,
                onPressed: () {},
              ),
            ],
          ),
        ),
        DocSection(
          title: 'Description list',
          child: FoCard(
            child: FoDescriptionList(
              items: <FoDescriptionItem>[
                FoDescriptionItem(
                  label: 'Line',
                  value: Text('Line A', style: context.foText.body),
                ),
                FoDescriptionItem(
                  label: 'Shift',
                  value: Text('Morning', style: context.foText.body),
                ),
                const FoDescriptionItem(
                  label: 'Status',
                  value: FoStatusChip.tone(
                    label: 'Submitted',
                    tone: FoStatusTone.success,
                    semanticPrefix: 'Status',
                  ),
                ),
                const FoDescriptionItem(
                  label: 'Verified',
                  value: FoBooleanCell(
                    value: true,
                    yesLabel: 'Yes',
                    noLabel: 'No',
                    label: 'Verified',
                  ),
                ),
                FoDescriptionItem(
                  label: 'Quantity',
                  value: Text('1,290', style: context.foText.numeric),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// The theme toggle, on its own so the three states are the whole subject.
class ThemeToggles extends StatefulWidget {
  /// Creates the theme-toggle page.
  const ThemeToggles({super.key});

  @override
  State<ThemeToggles> createState() => _ThemeTogglesState();
}

class _ThemeTogglesState extends State<ThemeToggles> {
  ThemeMode _mode = ThemeMode.system;

  @override
  Widget build(BuildContext context) {
    return DocPage(
      title: 'Theme toggle',
      lede: 'Three states, not two. An app that ignores the platform\'s '
          'preference is one the user has to correct every time they change '
          'it — and a two-state toggle cannot express "follow the system" at '
          'all, so defaulting to light silently overrides it.',
      children: <Widget>[
        DocSection(
          title: 'Pick one',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              FoThemeToggle(
                mode: _mode,
                lightLabel: 'Light',
                darkLabel: 'Dark',
                systemLabel: 'System',
                onChanged: (ThemeMode m) => setState(() => _mode = m),
              ),
              SizedBox(height: context.foSpacing.md),
              Text(
                'Selected: ${_mode.name}. The toggle reports the choice; '
                'storing it and applying it to MaterialApp.themeMode is the '
                'app\'s job.',
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

/// A set of related figures as one seamed object.
@widgetbook.UseCase(name: 'Seam grid', type: FoSeamGrid, path: '05 Dashboard')
Widget buildSeamGrid(BuildContext context) => const DashboardParts();

/// One figure, with its trend and a sparkline.
@widgetbook.UseCase(name: 'Stat card', type: FoStatCard, path: '05 Dashboard')
Widget buildStatCard(BuildContext context) => const DashboardParts();

/// Counts attached to something else.
@widgetbook.UseCase(name: 'Badge', type: FoBadge, path: '05 Dashboard')
Widget buildBadge(BuildContext context) => const DashboardParts();

/// The one header a page is named by.
@widgetbook.UseCase(
  name: 'Page header',
  type: FoPageHeader,
  path: '05 Dashboard',
)
Widget buildPageHeader(BuildContext context) => const DetailParts();

/// Term and value pairs — the detail view of one record.
@widgetbook.UseCase(
  name: 'Description list',
  type: FoDescriptionList,
  path: '05 Dashboard',
)
Widget buildDescriptionList(BuildContext context) => const DetailParts();

/// Light, dark and system.
@widgetbook.UseCase(
  name: 'Theme toggle',
  type: FoThemeToggle,
  path: '05 Dashboard',
)
Widget buildThemeToggle(BuildContext context) => const ThemeToggles();

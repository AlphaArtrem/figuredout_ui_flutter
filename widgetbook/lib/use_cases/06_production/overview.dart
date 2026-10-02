import 'package:figuredout_ui/figuredout_ui.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

import '../../support/doc_page.dart';

/// Stages, what needs attention, and progress toward a total.
class OverviewParts extends StatelessWidget {
  /// Creates the overview page.
  const OverviewParts({super.key});

  static const List<(String, String, String)> _order =
      <(String, String, String)>[
    ('Cutting', '2,180', '40 waiting'),
    ('Loading', '1,960', '220 waiting'),
    ('Midline', '1,880', '80 waiting'),
    ('Output', '1,720', '160 waiting'),
    ('QC', '1,610', '110 waiting'),
    ('Bartek', '1,480', '130 waiting'),
    ('Thread cut', '1,320', '160 waiting'),
    ('Pressing', '1,012', '308 waiting'),
    ('Packing', '860', '152 waiting'),
  ];

  @override
  Widget build(BuildContext context) {
    const int current = 7;

    return DocPage(
      title: 'Stages and attention',
      lede: 'An order\'s nine stages in production order, each with its '
          'figure; the unit\'s day as KPI tiles; what needs somebody, with '
          'one way to act on each; and progress toward a total, never only as '
          'a bar.',
      children: <Widget>[
        DocSection(
          title: 'Stage rail — one order',
          child: FoStageRail(
            stages: <FoStage>[
              for (int i = 0; i < _order.length; i++)
                FoStage(
                  number: i + 1,
                  label: _order[i].$1,
                  value: _order[i].$2,
                  detail: i == current ? _order[i].$3 : null,
                  detailIsWarning: i == current,
                  state: i < current
                      ? FoStageState.done
                      : i == current
                          ? FoStageState.current
                          : FoStageState.upcoming,
                ),
            ],
          ),
        ),
        const DocSection(
          title: 'Stage KPI tiles — the unit today',
          child: FoStageRail(
            prominent: true,
            stages: <FoStage>[
              FoStage(
                number: 1,
                label: 'Cutting',
                value: '1,840',
                caption: 'done today',
                detail: '6,480 waiting',
                badge: FoStatusChip.tone(
                  label: 'Piling up',
                  tone: FoStatusTone.warning,
                ),
              ),
              FoStage(
                number: 2,
                label: 'Loading',
                value: '1,260',
                caption: 'done today',
                detail: '1,920 waiting',
              ),
              FoStage(
                number: 3,
                label: 'Midline',
                value: '1,190',
                caption: 'done today',
                detail: '410 waiting',
              ),
            ],
          ),
        ),
        DocSection(
          title: 'Needs your attention',
          child: FoCard(
            child: FoAttentionList(
              items: <FoAttentionItem>[
                FoAttentionItem(
                  icon: Icons.warning_amber_outlined,
                  tone: FoStatusTone.danger,
                  title: 'Slim Chino is due in 7 days',
                  subtitle: 'JOB-2026-10019 · 1,140 of 2,400 pieces still to '
                      'pack',
                  actionLabel: 'Open order',
                  onAction: () {},
                ),
                FoAttentionItem(
                  icon: Icons.edit_outlined,
                  title: '3 change requests are waiting for you',
                  subtitle: 'Those entries stay locked until you approve or '
                      'decline.',
                  actionLabel: 'Review',
                  onAction: () {},
                ),
                FoAttentionItem(
                  icon: Icons.schedule,
                  tone: FoStatusTone.info,
                  title: 'Change request is with the owner',
                  subtitle: 'PRS-00415 · Jet Black · asked 1 Oct',
                  onTap: () {},
                ),
              ],
            ),
          ),
        ),
        DocSection(
          title: 'Progress',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              FoProgressBar(
                value: 1260,
                max: 2400,
                semanticLabel: 'Slim Chino, packed',
                semanticValue: '1,260 of 2,400',
                trailing: Text(
                  '1,260 / 2,400 packed',
                  style: context.foText.numeric,
                ),
              ),
              SizedBox(height: context.foSpacing.md),
              FoProgressBar(
                value: 64,
                max: 100,
                tone: FoStatusTone.warning,
                semanticLabel: 'Line 3 efficiency',
                semanticValue: '64%',
                trailing: Text('64%', style: context.foText.numeric),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// An order's stages, or the unit's day, in production order.
@widgetbook.UseCase(
  name: 'Stage rail',
  type: FoStageRail,
  path: '06 Production',
)
Widget buildStageRail(BuildContext context) => const OverviewParts();

/// What needs somebody, with one way to act on each.
@widgetbook.UseCase(
  name: 'Attention list',
  type: FoAttentionList,
  path: '06 Production',
)
Widget buildAttentionList(BuildContext context) => const OverviewParts();

/// One value toward a known total.
@widgetbook.UseCase(
  name: 'Progress bar',
  type: FoProgressBar,
  path: '02 Primitives',
)
Widget buildProgressBar(BuildContext context) => const OverviewParts();

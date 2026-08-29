import 'package:figuredout_ui/figuredout_ui.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

import '../../support/doc_page.dart';

/// The switch row in every state a form actually produces — including the two
/// that are easy to get wrong.
class SwitchTiles extends StatefulWidget {
  /// Creates the switch-tile page.
  const SwitchTiles({super.key});

  @override
  State<SwitchTiles> createState() => _SwitchTilesState();
}

class _SwitchTilesState extends State<SwitchTiles> {
  bool _filterable = false;
  bool _required = true;
  bool _active = true;

  @override
  Widget build(BuildContext context) {
    return DocPage(
      title: 'Switch tile',
      lede: 'A boolean is a row, not a control floating beside a label. The '
          'whole row is the tap target, because a 48dp switch at the end of a '
          'line is a small thing to hit one-handed — and the switch inside is '
          'only a rendering of the value.',
      children: <Widget>[
        DocSection(
          title: 'Ordinary',
          child: Column(
            children: <Widget>[
              FoSwitchTile(
                value: _active,
                title: 'Active',
                subtitle: 'Inactive entries stay on old records and drop out '
                    'of every picker.',
                onChanged: (bool value) => setState(() => _active = value),
              ),
              SizedBox(height: context.foSpacing.md),
              FoSwitchTile(
                value: _required,
                title: 'Required',
                semanticLabel: 'Insurer is a required field',
                onChanged: (bool value) => setState(() => _required = value),
              ),
              SizedBox(height: context.foSpacing.md),
              FoSwitchTile(
                value: _filterable,
                title: 'Filterable',
                subtitle: 'Let people filter the list by this — a little '
                    'slower to save.',
                onChanged: (bool value) => setState(() => _filterable = value),
              ),
            ],
          ),
        ),
        DocSection(
          title: 'Locked',
          child: Column(
            children: <Widget>[
              const FoSwitchTile(
                value: true,
                title: 'Manage the firm’s lists',
                subtitle: 'Edit courts, locations, case types and stages.',
                onChanged: null,
                lock: FoSwitchTileLock(
                  label: 'Always on',
                  reason: 'The Principal keeps this, so the firm can never '
                      'lock itself out.',
                ),
              ),
              SizedBox(height: context.foSpacing.md),
              const FoSwitchTile(
                value: false,
                title: 'Two-factor sign-in',
                onChanged: null,
                lock: FoSwitchTileLock(label: 'Set by your firm'),
              ),
              SizedBox(height: context.foSpacing.md),
              Text(
                'A locked value is a word, never a greyed switch. A disabled '
                'Material Switch that is ON paints a grey track with the thumb '
                'to the right, which reads as OFF at a glance — a consuming '
                'app shipped five permissions labelled “always on” beside a '
                'control that looked off, and only a run on a real phone '
                'caught it. Compare the two rows above with the dimmed pair '
                'below: those still show their state, these say it.',
                style: context.foText.body.copyWith(
                  color: context.foColors.fgSubtle,
                ),
              ),
            ],
          ),
        ),
        DocSection(
          title: 'Read-only',
          child: Column(
            children: <Widget>[
              const FoSwitchTile(
                value: true,
                title: 'On, while the form saves',
                onChanged: null,
              ),
              SizedBox(height: context.foSpacing.md),
              const FoSwitchTile(
                value: false,
                title: 'Off, while the form saves',
                onChanged: null,
              ),
              SizedBox(height: context.foSpacing.md),
              Text(
                'A null onChanged means “not now”, not “not ever”. The row '
                'dims as a whole and the switch keeps its on and off colours, '
                'so the two rows above are still telling you different things '
                '— which is exactly what handing Material a null onChanged '
                'would destroy. For a value that can never change, pass a '
                'lock instead.',
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

/// Every state of the switch row. Raise the text-scale addon: the row grows
/// downward and the switch stays put, which is the behaviour to check.
@widgetbook.UseCase(
  name: 'Switch tile',
  type: FoSwitchTile,
  path: '02 Primitives',
)
Widget buildSwitchTiles(BuildContext context) => const SwitchTiles();

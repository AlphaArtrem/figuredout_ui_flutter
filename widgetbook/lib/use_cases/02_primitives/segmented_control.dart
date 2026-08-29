import 'package:figuredout_ui/figuredout_ui.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

import '../../support/doc_page.dart';

/// Two or three destinations, side by side, with exactly one current.
class SegmentedControls extends StatefulWidget {
  /// Creates the segmented-control page.
  const SegmentedControls({super.key});

  @override
  State<SegmentedControls> createState() => _SegmentedControlsState();
}

class _SegmentedControlsState extends State<SegmentedControls> {
  int _cases = 0;
  int _counted = 0;
  int _three = 1;
  int _hindi = 0;

  @override
  Widget build(BuildContext context) {
    return DocPage(
      title: 'Segmented control',
      lede: 'A segment is a **destination**, not a filter. A filter is '
          'something you set and can forget you set; a segment is a place you '
          'are, it is always visible, and the one you are in is legible '
          'without opening anything. That is why the track is surfaceSunken '
          'and the current segment rests in it on surface — rule 6, read '
          'literally.',
      children: <Widget>[
        DocSection(
          title: 'Two destinations',
          child: FoSegmentedControl(
            segments: const <FoSegment>[
              FoSegment(label: 'Active'),
              FoSegment(label: 'Disposed'),
            ],
            selectedIndex: _cases,
            onSelected: (int index) => setState(() => _cases = index),
            semanticLabel: 'Case list',
          ),
        ),
        DocSection(
          title: 'With counts',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              FoSegmentedControl(
                segments: const <FoSegment>[
                  FoSegment(label: 'Active', count: 12),
                  FoSegment(label: 'Disposed', count: 41),
                ],
                selectedIndex: _counted,
                onSelected: (int index) => setState(() => _counted = index),
              ),
              SizedBox(height: context.foSpacing.md),
              Text(
                '"Disposed" is a place; "Disposed 41" tells somebody whether '
                'it is worth going there. A null count shows nothing at all '
                'rather than a zero — a count that has not loaded and a count '
                'of none are different things, and a bare zero reads as the '
                'second.',
                style: context.foText.body.copyWith(
                  color: context.foColors.fgSubtle,
                ),
              ),
            ],
          ),
        ),
        DocSection(
          title: 'Three, with glyphs',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              FoSegmentedControl(
                segments: const <FoSegment>[
                  FoSegment(label: 'Day', icon: Icons.today_outlined),
                  FoSegment(label: 'Week', icon: Icons.date_range_outlined),
                  FoSegment(
                      label: 'Month', icon: Icons.calendar_month_outlined),
                ],
                selectedIndex: _three,
                onSelected: (int index) => setState(() => _three = index),
              ),
              SizedBox(height: context.foSpacing.md),
              Text(
                'Three is the ceiling, asserted rather than advised. Four is a '
                'tab bar, and four labels do not fit a phone in a script that '
                'runs longer than English.',
                style: context.foText.body.copyWith(
                  color: context.foColors.fgSubtle,
                ),
              ),
            ],
          ),
        ),
        DocSection(
          title: 'A longer script',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              SizedBox(
                width: 300,
                child: FoSegmentedControl(
                  segments: const <FoSegment>[
                    FoSegment(label: 'सक्रिय'),
                    FoSegment(label: 'निस्तारित मामले'),
                  ],
                  selectedIndex: _hindi,
                  onSelected: (int index) => setState(() => _hindi = index),
                ),
              ),
              SizedBox(height: context.foSpacing.md),
              Text(
                'The label wraps; it never ellipsises. A Devanagari label is '
                'longer than the English one it was sized against, and a '
                'truncated destination is not one anybody can read. Narrow the '
                'device addon and watch the track grow taller rather than the '
                'words disappear.',
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

/// Every shape the control takes. Raise the text-scale addon and narrow the
/// device: the segments grow downward and the labels stay whole, which is the
/// behaviour to check.
@widgetbook.UseCase(
  name: 'Segmented control',
  type: FoSegmentedControl,
  path: '02 Primitives',
)
Widget buildSegmentedControls(BuildContext context) =>
    const SegmentedControls();

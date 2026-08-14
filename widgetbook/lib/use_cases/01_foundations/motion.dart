import 'package:figuredout_ui/figuredout_ui.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

import '../../support/doc_page.dart';

/// One duration pair and one curve, run side by side against the curves they
/// replace — the difference is the whole argument for banning the others.
class Motion extends StatefulWidget {
  /// Creates the motion page.
  const Motion({super.key});

  @override
  State<Motion> createState() => _MotionState();
}

class _MotionState extends State<Motion> {
  bool _out = false;

  @override
  Widget build(BuildContext context) {
    return DocPage(
      title: 'Motion',
      lede: 'FoMotion.normal with FoMotion.standard for anything the eye '
          'follows, FoMotion.fast for anything under 200ms. A system with four '
          'curves has no curve at all, so easeInOut, linear and any literal '
          'Duration are banned outside fo_motion.dart — and a test enforces it.',
      children: <Widget>[
        DocSection(
          title: 'Run it',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              FilledButton(
                onPressed: () => setState(() => _out = !_out),
                child: Text(_out ? 'Move back' : 'Move'),
              ),
              SizedBox(height: context.foSpacing.xl),
              _Track(
                label: 'fast · 150ms · standard',
                duration: FoMotion.fast,
                curve: FoMotion.standard,
                out: _out,
              ),
              _Track(
                label: 'normal · 250ms · standard',
                duration: FoMotion.normal,
                curve: FoMotion.standard,
                out: _out,
              ),
              _Track(
                label: 'normal · 250ms · easeInOut — banned, for comparison',
                duration: FoMotion.normal,
                curve: Curves.easeInOut,
                out: _out,
                banned: true,
              ),
              _Track(
                label: 'normal · 250ms · linear — banned, for comparison',
                duration: FoMotion.normal,
                curve: Curves.linear,
                out: _out,
                banned: true,
              ),
            ],
          ),
        ),
        DocSection(
          title: 'Which one',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'fast — a change the user already knows about, because they '
                'caused it: a press, a hover, a focus ring arriving.',
                style: context.foText.body,
              ),
              SizedBox(height: context.foSpacing.sm),
              Text(
                'normal — a change the user has to notice: something entering, '
                'leaving, expanding or moving.',
                style: context.foText.body,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Track extends StatelessWidget {
  const _Track({
    required this.label,
    required this.duration,
    required this.curve,
    required this.out,
    this.banned = false,
  });

  final String label;
  final Duration duration;
  final Curve curve;
  final bool out;
  final bool banned;

  @override
  Widget build(BuildContext context) {
    final Color ink =
        banned ? context.foColors.fgSubtle : context.foColors.primary;
    return Padding(
      padding: EdgeInsets.only(bottom: context.foSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(label.toUpperCase(), style: context.foText.caption),
          SizedBox(height: context.foSpacing.xs),
          Container(
            height: 40,
            decoration: BoxDecoration(
              color: context.foColors.surfaceSunken,
              borderRadius: BorderRadius.circular(context.foRadii.sm),
            ),
            child: AnimatedAlign(
              duration: duration,
              curve: curve,
              alignment: out ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: ink,
                  borderRadius: BorderRadius.circular(context.foRadii.sm),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The two durations and the one curve, against the curves they replace.
@widgetbook.UseCase(
  name: 'Motion',
  type: Motion,
  path: '01 Foundations',
)
Widget buildMotion(BuildContext context) => const Motion();

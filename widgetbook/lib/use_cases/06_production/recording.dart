import 'package:figuredout_ui/figuredout_ui.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

import '../../support/doc_page.dart';

const List<String> _sizes = <String>['S', 'M', 'L', 'XL', 'XXL'];
const List<int> _ready = <int>[16, 36, 42, 30, 22];

FoSizeCountCopy _copy() => FoSizeCountCopy(
      sizeLabel: 'Size',
      readyLabel: 'Ready',
      readyHelper: 'Thread-cut, not pressed',
      countLabel: 'Pressed now',
      countHelper: 'Good pieces you pressed',
      remainingLabel: 'Still to press',
      remainingHelper: 'After this entry',
      totalLabel: 'Total',
      fillAllLabel: 'Fill all ready (146)',
      inputSemanticLabel: (String size) => 'Pressed, size $size',
      decreaseSemanticLabel: (String size) => 'One fewer, size $size',
      increaseSemanticLabel: (String size) => 'One more, size $size',
      overLimitMessage: (String size, int over) =>
          'Size $size is $over more than ready. You can still send it; an '
          'owner will need to approve before it counts.',
    );

/// Counting by size: the same grid at every stage, only the words change.
class SizeCounts extends StatefulWidget {
  /// Creates the size-count page.
  const SizeCounts({super.key});

  @override
  State<SizeCounts> createState() => _SizeCountsState();
}

class _SizeCountsState extends State<SizeCounts> {
  List<int> _counts = <int>[16, 30, 44, 24, 0];
  List<int> _repress = <int>[0, 1, 0, 0, 0];
  bool _extra = false;
  int _single = 30;

  List<FoSizeCount> get _rows => <FoSizeCount>[
        for (int i = 0; i < _sizes.length; i++)
          FoSizeCount(size: _sizes[i], ready: _ready[i], value: _counts[i]),
      ];

  @override
  Widget build(BuildContext context) {
    return DocPage(
      title: 'Counting by size',
      lede: 'Each size shows what is Ready — worked out from the stage '
          'before — and one tap fills them all. Over the ready count is a '
          'warning that asks for approval, never an error that refuses. On a '
          'phone each size is a card with steppers; on a wide window it is a '
          'table with a total row. Resize the viewport.',
      children: <Widget>[
        DocSection(
          title: 'The grid',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              FoSizeCountGrid(
                sizes: _rows,
                copy: _copy(),
                onChanged: (int i, int v) =>
                    setState(() => _counts = List<int>.of(_counts)..[i] = v),
                onFillAll: () => setState(() => _counts = List<int>.of(_ready)),
                showExtraColumns: _extra,
                extraColumns: <FoSizeCountColumn>[
                  FoSizeCountColumn(
                    label: 'Re-press',
                    helper: 'Need another pass',
                    values: _repress,
                    onChanged: (int i, int v) => setState(
                      () => _repress = List<int>.of(_repress)..[i] = v,
                    ),
                    inputSemanticLabel: (String size) => 'Re-press, size $size',
                  ),
                ],
              ),
              SizedBox(height: context.foSpacing.md),
              FoButton(
                label:
                    _extra ? 'Hide re-press' : 'Any re-press pieces? (phone)',
                variant: FoButtonVariant.clear,
                onPressed: () => setState(() => _extra = !_extra),
              ),
              Text(
                'Total ${FoSizeCountGrid.totalOf(_rows)} — on a phone the '
                'total lives in the flow\'s fixed footer.',
                style: context.foText.body.copyWith(
                  color: context.foColors.fgSubtle,
                ),
              ),
            ],
          ),
        ),
        DocSection(
          title: 'Number field',
          child: Wrap(
            spacing: context.foSpacing.xl,
            runSpacing: context.foSpacing.md,
            children: <Widget>[
              FoNumberField(
                value: _single,
                onChanged: (int v) => setState(() => _single = v),
                semanticLabel: 'Pressed, size M',
                decreaseSemanticLabel: 'One fewer, size M',
                increaseSemanticLabel: 'One more, size M',
              ),
              FoNumberField(
                value: 44,
                onChanged: (_) {},
                warning: true,
                semanticLabel: 'Pressed, size L',
                showSteppers: false,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// The three-step record flow, at both widths.
class StepFlows extends StatefulWidget {
  /// Creates the step-flow page.
  const StepFlows({super.key});

  @override
  State<StepFlows> createState() => _StepFlowsState();
}

class _StepFlowsState extends State<StepFlows> {
  int _step = 1;

  List<FoStep> _steps(VoidCallback toFirst) => <FoStep>[
        FoStep(
          label: 'Order and colour',
          summary: 'JOB-2026-10024 · Deep Navy',
          onEdit: toFirst,
          editLabel: 'Change',
        ),
        const FoStep(label: 'Count by size'),
        const FoStep(label: 'Check and submit'),
      ];

  @override
  Widget build(BuildContext context) {
    return DocPage(
      title: 'Record flow',
      lede: 'Recording work is one three-step flow at every stage: choose the '
          'order, count by size, check and submit. On a wide window it is a '
          'dialog with the full stepper and a pinned footer; on a phone it is '
          'the whole screen with a segmented progress bar and a fixed footer. '
          'The stepper below is the wide form; open the flow to see the one '
          'that fits the viewport.',
      children: <Widget>[
        DocSection(
          title: 'Stepper',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              FoStepper(
                steps: _steps(() => setState(() => _step = 0)),
                currentStep: _step,
                compact: false,
              ),
              SizedBox(height: context.foSpacing.lg),
              FoStepper(
                steps: _steps(() {}),
                currentStep: _step,
                compact: true,
              ),
              SizedBox(height: context.foSpacing.md),
              Wrap(
                spacing: context.foSpacing.sm,
                children: <Widget>[
                  FoButton(
                    label: 'Back',
                    variant: FoButtonVariant.secondary,
                    onPressed:
                        _step == 0 ? null : () => setState(() => _step--),
                  ),
                  FoButton(
                    label: 'Next',
                    variant: FoButtonVariant.primary,
                    onPressed:
                        _step == 2 ? null : () => setState(() => _step++),
                  ),
                ],
              ),
            ],
          ),
        ),
        DocSection(
          title: 'Presented',
          child: FoButton(
            label: 'Record pressing',
            variant: FoButtonVariant.primary,
            icon: Icons.add,
            onPressed: () => FoStepFlow.show<void>(
              context,
              builder: (_) => const _DemoFlow(),
            ),
          ),
        ),
      ],
    );
  }
}

class _DemoFlow extends StatefulWidget {
  const _DemoFlow();

  @override
  State<_DemoFlow> createState() => _DemoFlowState();
}

class _DemoFlowState extends State<_DemoFlow> {
  int _step = 1;
  List<int> _counts = <int>[16, 30, 40, 24, 0];

  @override
  Widget build(BuildContext context) {
    final List<FoSizeCount> rows = <FoSizeCount>[
      for (int i = 0; i < _sizes.length; i++)
        FoSizeCount(size: _sizes[i], ready: _ready[i], value: _counts[i]),
    ];
    final bool compact = !context.foWindowClass.isAtLeastMedium;
    final int total = FoSizeCountGrid.totalOf(rows);

    return FoStepFlowScaffold(
      eyebrow: 'Pressing · Stage 8 of 9',
      title: 'Record pressing',
      subtitle: 'Count the pieces pressed for one colour of one order.',
      stepLabel: 'Step ${_step + 1} of 3',
      steps: <FoStep>[
        FoStep(
          label: 'Order and colour',
          summary: 'JOB-2026-10024 · Deep Navy',
          onEdit: () => setState(() => _step = 0),
          editLabel: 'Change',
        ),
        const FoStep(label: 'Count by size'),
        const FoStep(label: 'Check and submit'),
      ],
      currentStep: _step,
      onClose: () => Navigator.of(context).pop(),
      closeSemanticLabel: 'Close',
      onBack: () => setState(() => _step = (_step - 1).clamp(0, 2)),
      backSemanticLabel: 'Back to the previous step',
      body: _step == 1
          ? FoSizeCountGrid(
              sizes: rows,
              copy: _copy(),
              onChanged: (int i, int v) =>
                  setState(() => _counts = List<int>.of(_counts)..[i] = v),
              onFillAll: () => setState(() => _counts = List<int>.of(_ready)),
            )
          : Text(
              _step == 0 ? 'Choose the order.' : 'Check and submit $total.',
            ),
      footer: compact
          ? FoButton(
              label: 'Next: $total pieces',
              variant: FoButtonVariant.primary,
              size: FoButtonSize.large,
              trailingIcon: Icons.arrow_forward,
              onPressed: () => setState(() => _step = (_step + 1).clamp(0, 2)),
            )
          : Wrap(
              alignment: WrapAlignment.end,
              spacing: context.foSpacing.sm,
              runSpacing: context.foSpacing.sm,
              children: <Widget>[
                FoButton(
                  label: 'Save as draft',
                  variant: FoButtonVariant.clear,
                  onPressed: () {},
                ),
                FoButton(
                  label: 'Back',
                  variant: FoButtonVariant.secondary,
                  onPressed: () =>
                      setState(() => _step = (_step - 1).clamp(0, 2)),
                ),
                FoButton(
                  label: 'Next: check and submit',
                  variant: FoButtonVariant.primary,
                  trailingIcon: Icons.arrow_forward,
                  onPressed: () =>
                      setState(() => _step = (_step + 1).clamp(0, 2)),
                ),
              ],
            ),
    );
  }
}

/// Ready per size, a count, fill all ready, and the over-limit warning.
@widgetbook.UseCase(
  name: 'Size count grid',
  type: FoSizeCountGrid,
  path: '06 Production',
)
Widget buildSizeCounts(BuildContext context) => const SizeCounts();

/// A controlled count with − and + steppers.
@widgetbook.UseCase(
  name: 'Number field',
  type: FoNumberField,
  path: '02 Primitives',
)
Widget buildNumberField(BuildContext context) => const SizeCounts();

/// The three-step record flow: dialog on a wide window, full screen on a phone.
@widgetbook.UseCase(
  name: 'Record flow',
  type: FoStepFlowScaffold,
  path: '06 Production',
)
Widget buildStepFlows(BuildContext context) => const StepFlows();

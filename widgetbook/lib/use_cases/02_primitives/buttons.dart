import 'package:figuredout_ui/figuredout_ui.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

import '../../support/doc_page.dart';

/// Every variant in every state, so a palette change cannot quietly make one
/// of them unreadable.
class Buttons extends StatelessWidget {
  /// Creates the button page.
  const Buttons({super.key});

  static const Map<FoButtonVariant, String> _purpose =
      <FoButtonVariant, String>{
    FoButtonVariant.primary: 'The one action the screen exists to perform.',
    FoButtonVariant.secondary: 'A real action that is not the main one.',
    FoButtonVariant.destructive:
        'Something destructive. Carries its own ink — dangerFg, never '
            'primaryFg.',
    FoButtonVariant.tertiary:
        'A third-rank action that still needs to look pressable.',
    FoButtonVariant.clear: 'No chrome at all: cancel, dismiss, a row link.',
  };

  @override
  Widget build(BuildContext context) {
    return DocPage(
      title: 'Buttons',
      lede: 'Pick the variant that matches what the action is worth; the '
          'appearance follows. A screen with two primaries has not decided '
          'what it is for.',
      children: <Widget>[
        for (final FoButtonVariant variant in FoButtonVariant.values)
          DocSection(
            title: variant.name,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  _purpose[variant]!,
                  style: context.foText.body.copyWith(
                    color: context.foColors.fgSubtle,
                  ),
                ),
                SizedBox(height: context.foSpacing.md),
                Wrap(
                  spacing: context.foSpacing.md,
                  runSpacing: context.foSpacing.md,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: <Widget>[
                    FoButton(
                      label: 'Default',
                      variant: variant,
                      onPressed: () {},
                    ),
                    FoButton(
                      label: 'With icon',
                      variant: variant,
                      icon: Icons.add,
                      onPressed: () {},
                    ),
                    FoButton(
                      label: 'Loading',
                      variant: variant,
                      isLoading: true,
                      onPressed: () {},
                    ),
                    FoButton(
                      label: 'Disabled',
                      variant: variant,
                      onPressed: null,
                    ),
                  ],
                ),
              ],
            ),
          ),
        DocSection(
          title: 'Full width',
          child: FoButton(
            label: 'Submit entry',
            variant: FoButtonVariant.primary,
            fullWidth: true,
            onPressed: () {},
          ),
        ),
      ],
    );
  }
}

/// Every variant, with and without an icon, loading and disabled. Tab through
/// this page: the focus ring is the same on all five, which is the point.
@widgetbook.UseCase(name: 'Variants', type: FoButton, path: '02 Primitives')
Widget buildButtons(BuildContext context) => const Buttons();

/// The page-level primary action and the submit button, which are the same
/// button with the variant already decided.
@widgetbook.UseCase(
  name: 'Action and loading',
  type: FoActionButton,
  path: '02 Primitives',
)
Widget buildActionButtons(BuildContext context) => _ActionButtons();

class _ActionButtons extends StatefulWidget {
  @override
  State<_ActionButtons> createState() => _ActionButtonsState();
}

class _ActionButtonsState extends State<_ActionButtons> {
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    return DocPage(
      title: 'Action and loading',
      lede: 'FoActionButton is the page-level primary; FoLoadingButton is the '
          'same button that knows submitting takes time. Neither can be '
          'styled as anything else, which is the whole reason they exist.',
      children: <Widget>[
        DocSection(
          title: 'FoActionButton',
          child: FoActionButton(
            label: 'New cut entry',
            icon: Icons.add,
            onPressed: () {},
          ),
        ),
        DocSection(
          title: 'FoLoadingButton',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              FoLoadingButton(
                label: 'Save entry',
                isLoading: _saving,
                onPressed: () => setState(() => _saving = !_saving),
              ),
              SizedBox(height: context.foSpacing.sm),
              Text(
                'Tap it — the button keeps its width while loading, so a row '
                'of actions does not reflow mid-submit.',
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

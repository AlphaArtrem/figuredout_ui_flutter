import 'package:figuredout_ui/figuredout_ui.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

import '../../support/doc_page.dart';

/// The two form fields, in every state a form actually produces.
class Fields extends StatefulWidget {
  /// Creates the fields page.
  const Fields({super.key});

  @override
  State<Fields> createState() => _FieldsState();
}

class _FieldsState extends State<Fields> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  String? _line = 'A';

  static const List<String> _lines = <String>['A', 'B', 'C'];

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: DocPage(
        title: 'Fields',
        lede: 'A field is a hole in the page, so it is filled with '
            'surfaceSunken. Everything visual comes from the theme — a field '
            'restyled onto surface stops reading as somewhere you can type.',
        children: <Widget>[
          DocSection(
            title: 'Text',
            child: Column(
              children: <Widget>[
                const FoTextField(label: 'Batch reference'),
                SizedBox(height: context.foSpacing.lg),
                const FoTextField(label: 'Operator', isRequired: true),
                SizedBox(height: context.foSpacing.lg),
                const FoTextField(
                  label: 'Rejected quantity',
                  helperText: 'Leave empty to record none.',
                ),
                SizedBox(height: context.foSpacing.lg),
                const FoTextField(
                  label: 'Notes',
                  maxLines: 3,
                  hintText: 'Anything the next shift should know',
                ),
                SizedBox(height: context.foSpacing.lg),
                const FoTextField(
                  label: 'Locked field',
                  initialValue: 'Set upstream',
                  enabled: false,
                ),
              ],
            ),
          ),
          DocSection(
            title: 'Validation',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                FoTextField(
                  label: 'Quantity',
                  isRequired: true,
                  validator: (String? value) =>
                      (value ?? '').isEmpty ? 'Enter a quantity.' : null,
                ),
                SizedBox(height: context.foSpacing.md),
                FoButton(
                  label: 'Validate',
                  variant: FoButtonVariant.secondary,
                  onPressed: () => _formKey.currentState?.validate(),
                ),
              ],
            ),
          ),
          DocSection(
            title: 'Dropdown',
            child: Column(
              children: <Widget>[
                FoDropdownField<String>(
                  label: 'Line',
                  value: _line,
                  isRequired: true,
                  items: _lines
                      .map(
                        (String line) => DropdownMenuItem<String>(
                          value: line,
                          child: Text('Line $line'),
                        ),
                      )
                      .toList(),
                  onChanged: (String? value) => setState(() => _line = value),
                ),
                SizedBox(height: context.foSpacing.lg),
                const FoDropdownField<String>.placeholder(
                  label: 'Machine',
                  loadingText: 'Loading machines…',
                  isLoading: true,
                  isRequired: true,
                ),
                SizedBox(height: context.foSpacing.sm),
                Text(
                  'A placeholder keeps the label and the field shape while a '
                  'lookup runs, so a required field never collapses into a '
                  'bare spinner or vanishes from the form.',
                  style: context.foText.body.copyWith(
                    color: context.foColors.fgSubtle,
                  ),
                ),
                SizedBox(height: context.foSpacing.lg),
                const FoDropdownField<String>.placeholder(
                  label: 'Machine',
                  loadingText: 'Loading machines…',
                  isLoading: false,
                  isRequired: true,
                ),
                SizedBox(height: context.foSpacing.sm),
                Text(
                  'Once the lookup has failed it goes quiet rather than '
                  'spinning forever — explaining why is the error banner\'s '
                  'job, not the field\'s.',
                  style: context.foText.body.copyWith(
                    color: context.foColors.fgSubtle,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Both fields, every state a form produces. Raise the text-scale addon to
/// 1.6: the fixed single-line height is the first thing that breaks.
@widgetbook.UseCase(name: 'Text', type: FoTextField, path: '02 Primitives')
Widget buildFields(BuildContext context) => const Fields();

/// The dropdown, including the placeholder that holds a form's shape while a
/// lookup runs.
@widgetbook.UseCase(
  name: 'Dropdown',
  type: FoDropdownField,
  path: '02 Primitives',
)
Widget buildDropdownFields(BuildContext context) => const Fields();

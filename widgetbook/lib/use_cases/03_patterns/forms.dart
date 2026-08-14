import 'package:figuredout_ui/figuredout_ui.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

import '../../support/doc_page.dart';

const FoDiscardCopy _discardCopy = FoDiscardCopy(
  title: 'Discard changes?',
  message: 'Your edits to this entry will be lost.',
  confirmLabel: 'Discard',
  cancelLabel: 'Keep editing',
);

/// The presented form: surface, sections, hoisted footer and dismiss guard.
class Forms extends StatefulWidget {
  /// Creates the forms page.
  const Forms({super.key});

  @override
  State<Forms> createState() => _FormsState();
}

class _FormsState extends State<Forms> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _saving = false;

  Widget _body(BuildContext context) => Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            FoFormSection(
              title: 'What was cut',
              helper: 'Everything here is recorded against the current shift.',
              children: <Widget>[
                const FoTextField(label: 'Part', isRequired: true),
                FoFormInlineRow(
                  stackOnCompact: true,
                  items: <FoFormInlineItem>[
                    FoFormInlineItem(
                      flex: 2,
                      child: FoDropdownField<String>(
                        label: 'Line',
                        value: 'A',
                        isRequired: true,
                        items: const <DropdownMenuItem<String>>[
                          DropdownMenuItem<String>(
                            value: 'A',
                            child: Text('Line A'),
                          ),
                          DropdownMenuItem<String>(
                            value: 'B',
                            child: Text('Line B'),
                          ),
                        ],
                        onChanged: (_) {},
                      ),
                    ),
                    const FoFormInlineItem(
                      child: FoTextField(label: 'Quantity', isRequired: true),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: context.foSpacing.xxl),
            const FoFormSection(
              title: 'Anything unusual',
              children: <Widget>[
                FoTextField(
                  label: 'Notes',
                  maxLines: 3,
                  helperText: 'Leave empty if the run was routine.',
                ),
              ],
            ),
            SizedBox(height: context.foSpacing.xxl),
            // Declared at the end of the body, where it reads naturally — and
            // hoisted into the surface's pinned footer so it stays reachable.
            FoFormActions(
              actions: <FoFormAction>[
                FoFormAction(
                  label: 'Cancel',
                  variant: FoButtonVariant.clear,
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
                FoFormAction(
                  label: 'Save entry',
                  variant: FoButtonVariant.primary,
                  isLoading: _saving,
                  onPressed: () => setState(() => _saving = !_saving),
                ),
              ],
            ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    return DocPage(
      title: 'Forms',
      lede: 'Every modal goes through FoFormPresenter — a dialog on a wide '
          'window, a bottom sheet on a phone, the root navigator either way, '
          'and the dirty-form guard on all of it. Type something, then try to '
          'close it.',
      children: <Widget>[
        DocSection(
          title: 'Presented',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              FoActionButton(
                label: 'Open the form',
                icon: Icons.add,
                onPressed: () => FoFormPresenter.show<void>(
                  context,
                  title: 'New cut entry',
                  subtitle: 'Line A · morning shift',
                  discardCopy: _discardCopy,
                  child: Builder(builder: _body),
                ),
              ),
              SizedBox(height: context.foSpacing.sm),
              Text(
                'Type into a field and then press Escape, tap the barrier, or '
                'use the close button — the guard asks before discarding. The '
                'fields mark the form dirty themselves, so a form gets that '
                'without opting in.',
                style: context.foText.body.copyWith(
                  color: context.foColors.fgSubtle,
                ),
              ),
            ],
          ),
        ),
        DocSection(
          title: 'In place',
          child: SizedBox(
            height: 560,
            child: FoFormSurface(
              title: 'New cut entry',
              subtitle: 'The same surface, mounted rather than presented.',
              onClose: () {},
              child: Builder(builder: _body),
            ),
          ),
        ),
      ],
    );
  }
}

/// A page rendered by FoScaffold, with its controls row.
class Scaffolds extends StatefulWidget {
  /// Creates the scaffold page.
  const Scaffolds({super.key});

  @override
  State<Scaffolds> createState() => _ScaffoldsState();
}

class _ScaffoldsState extends State<Scaffolds> {
  final TextEditingController _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FoScaffold(
      title: 'Cut entries',
      searchField: FoListSearchField(
        controller: _search,
        hintText: 'Search entries',
        onChanged: (_) {},
      ),
      dropdown: FoDropdownField<String>(
        label: 'Line',
        value: 'A',
        items: const <DropdownMenuItem<String>>[
          DropdownMenuItem<String>(value: 'A', child: Text('Line A')),
        ],
        onChanged: (_) {},
      ),
      primaryAction: FoActionButton(
        label: 'New entry',
        icon: Icons.add,
        onPressed: () {},
      ),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(context.foSpacing.xl),
          child: Text(
            'The controls row above is the point: without it, list screens put '
            'their search box, their filter and their New button in three '
            'different places at three different widths. Switch to Compact '
            '480 — everything stacks full-width.',
            textAlign: TextAlign.center,
            style: context.foText.body.copyWith(
              color: context.foColors.fgMuted,
            ),
          ),
        ),
      ),
    );
  }
}

/// The presented form, its sections and the hoisted footer.
@widgetbook.UseCase(
  name: 'Form presenter',
  type: FoFormPresenter,
  path: '03 Patterns',
)
Widget buildForms(BuildContext context) => const Forms();

/// The surface on its own, mounted rather than presented.
@widgetbook.UseCase(
  name: 'Form surface',
  type: FoFormSurface,
  path: '03 Patterns',
)
Widget buildFormSurfaces(BuildContext context) => const Forms();

/// A page with its controls row.
@widgetbook.UseCase(name: 'Scaffold', type: FoScaffold, path: '03 Patterns')
Widget buildScaffolds(BuildContext context) => const Scaffolds();

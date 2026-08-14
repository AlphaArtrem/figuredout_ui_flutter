import 'package:flutter/material.dart';

import '../primitives/fo_button.dart';
import '../primitives/fo_text_field.dart';
import '../theme/fo_context.dart';
import 'fo_form_actions.dart';
import 'fo_form_presenter.dart';

/// Asks for one piece of text and returns it.
///
/// A dialog with a single field is common enough — a reason, a note, a name —
/// that hand-rolling it every time produces a different validation rule and a
/// different button order each time. This goes through `FoFormPresenter`, so
/// it gets the dialog-versus-sheet breakpoint, the root navigator and the
/// dirty-form guard for free.
///
/// Resolves with the text, or null if the user backed out. When
/// [requireNonEmpty] the confirming button stays disabled until there is
/// something to submit, and the result is trimmed.
Future<String?> showFoTextPrompt(
  BuildContext context, {
  required String title,
  required String fieldLabel,
  required String confirmLabel,
  required String cancelLabel,
  required FoDiscardCopy discardCopy,
  String? subtitle,
  String? hintText,
  String? helperText,
  String? initialValue,
  int maxLines = 1,
  FoButtonVariant confirmVariant = FoButtonVariant.primary,
  TextInputType? keyboardType,
  bool requireNonEmpty = true,
  double maxWidth = 560,
}) {
  return FoFormPresenter.show<String?>(
    context,
    title: title,
    subtitle: subtitle,
    maxWidth: maxWidth,
    discardCopy: discardCopy,
    child: _TextPromptBody(
      fieldLabel: fieldLabel,
      hintText: hintText,
      helperText: helperText,
      initialValue: initialValue,
      confirmLabel: confirmLabel,
      cancelLabel: cancelLabel,
      maxLines: maxLines,
      confirmVariant: confirmVariant,
      keyboardType: keyboardType,
      requireNonEmpty: requireNonEmpty,
    ),
  );
}

class _TextPromptBody extends StatefulWidget {
  const _TextPromptBody({
    required this.fieldLabel,
    required this.confirmLabel,
    required this.cancelLabel,
    required this.maxLines,
    required this.confirmVariant,
    required this.requireNonEmpty,
    this.hintText,
    this.helperText,
    this.initialValue,
    this.keyboardType,
  });

  final String fieldLabel;
  final String confirmLabel;
  final String cancelLabel;
  final String? hintText;
  final String? helperText;
  final String? initialValue;
  final int maxLines;
  final FoButtonVariant confirmVariant;
  final TextInputType? keyboardType;
  final bool requireNonEmpty;

  @override
  State<_TextPromptBody> createState() => _TextPromptBodyState();
}

class _TextPromptBodyState extends State<_TextPromptBody> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialValue ?? '',
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: _controller,
      builder: (BuildContext context, TextEditingValue value, _) {
        final String trimmed = value.text.trim();
        final bool canConfirm = !widget.requireNonEmpty || trimmed.isNotEmpty;

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            FoTextField(
              controller: _controller,
              label: widget.fieldLabel,
              hintText: widget.hintText,
              helperText: widget.helperText,
              maxLines: widget.maxLines,
              keyboardType: widget.keyboardType,
              isRequired: widget.requireNonEmpty,
            ),
            SizedBox(height: context.foSpacing.xl),
            FoFormActions(
              actions: <FoFormAction>[
                FoFormAction(
                  label: widget.cancelLabel,
                  variant: FoButtonVariant.clear,
                  // Pops with null, which is what "backed out" means here —
                  // distinct from an empty string the user actually submitted.
                  onPressed: () => Navigator.of(context).pop<String?>(),
                ),
                FoFormAction(
                  label: widget.confirmLabel,
                  variant: widget.confirmVariant,
                  onPressed: canConfirm
                      ? () => Navigator.of(context).pop<String?>(
                            widget.requireNonEmpty ? trimmed : value.text,
                          )
                      : null,
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

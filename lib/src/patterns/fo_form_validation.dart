import 'package:flutter/material.dart';

import '../tokens/fo_motion.dart';
import 'fo_toast.dart';

/// One submit-time validation behaviour for every form.
///
/// Forms drift here if left alone: some toast on an invalid submit, some only
/// paint errors — and an error painted above the fold, off screen, makes Save
/// look dead. This runs the validators, scrolls the first invalid field into
/// view, and shows the same toast everywhere.
abstract final class FoFormValidation {
  /// Validates [formKey]'s fields.
  ///
  /// Returns true when the form may be submitted. Otherwise reveals the first
  /// error, toasts [message], and returns false.
  ///
  /// [context] must be inside the form's scroll view for the scroll to happen;
  /// with no enclosing [Scrollable] only the toast is shown. [message] is
  /// required because the package holds no user-facing copy.
  static bool validate(
    BuildContext context,
    GlobalKey<FormState> formKey, {
    required String message,
  }) {
    if (formKey.currentState?.validate() ?? false) return true;

    final BuildContext? firstInvalid = _firstInvalidFieldContext(
      formKey.currentContext,
    );
    if (firstInvalid != null && Scrollable.maybeOf(firstInvalid) != null) {
      Scrollable.ensureVisible(
        firstInvalid,
        // Not 0.0: a field flush against the top edge reads as cropped, and
        // its label is the thing that explains the error.
        alignment: 0.1,
        duration: FoMotion.normal,
        curve: FoMotion.standard,
      );
    }

    FoToast.error(context, message);
    return false;
  }

  /// A depth-first walk of the form's element tree — which follows visual
  /// order — for the first field currently reporting an error.
  static BuildContext? _firstInvalidFieldContext(BuildContext? formContext) {
    if (formContext == null) return null;
    BuildContext? found;

    void visit(Element element) {
      if (found != null) return;
      if (element is StatefulElement) {
        final State<StatefulWidget> state = element.state;
        if (state is FormFieldState && state.hasError) {
          found = element;
          return;
        }
      }
      element.visitChildren(visit);
    }

    formContext.visitChildElements(visit);
    return found;
  }
}

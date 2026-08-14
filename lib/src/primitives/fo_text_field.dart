import 'package:flutter/material.dart';

import '../patterns/fo_form_scope.dart';
import '../tokens/fo_layout.dart';

/// The standard text input.
///
/// Borders, fill and padding come entirely from the theme's
/// `InputDecorationTheme` — **do not restyle them inline.** A field is a hole
/// in the page, so it is filled with `surfaceSunken`; a field restyled onto
/// `surface` stops reading as somewhere you can type.
///
/// The `*` required marker is applied here rather than concatenated at the
/// call site, so one convention holds across every form in every app.
///
/// Typing marks the enclosing `FoFormSurface` dirty, so dismissing it asks
/// before discarding the edits. A form gets that without opting in — which
/// matters, because the forms that most need the guard are the ones nobody
/// remembered to wire up. Outside a surface it is a no-op.
class FoTextField extends StatelessWidget {
  /// Creates a text field.
  const FoTextField({
    required this.label,
    this.controller,
    this.initialValue,
    this.validator,
    this.enabled = true,
    this.obscureText = false,
    this.keyboardType,
    this.suffixIcon,
    this.onChanged,
    this.maxLines = 1,
    this.hintText,
    this.helperText,
    this.isRequired = false,
    super.key,
  });

  /// Floating label. Caller-supplied, so it can be localized.
  final String label;

  /// Controls the text when the caller owns field state. Mutually exclusive
  /// with [initialValue].
  final TextEditingController? controller;

  /// Starting text for uncontrolled use.
  final String? initialValue;

  /// Validator, used inside a [Form].
  final String? Function(String?)? validator;

  /// When false the field is read-only and visually disabled.
  final bool enabled;

  /// Hides input, for a password.
  final bool obscureText;

  /// Soft-keyboard hint.
  final TextInputType? keyboardType;

  /// Trailing widget — a visibility toggle, a unit, a clear button.
  final Widget? suffixIcon;

  /// Called on every change.
  final void Function(String)? onChanged;

  /// Maximum visible lines. One by default.
  final int? maxLines;

  /// Placeholder shown while empty.
  final String? hintText;

  /// Always-visible guidance below the field, for a rule the user cannot
  /// infer — what an empty optional field will do, for instance.
  final String? helperText;

  /// Appends the app-wide `*` marker to [label].
  final bool isRequired;

  @override
  Widget build(BuildContext context) {
    assert(
      controller == null || initialValue == null,
      'Provide either controller or initialValue, not both.',
    );

    final int? effectiveMaxLines = obscureText ? 1 : maxLines;

    final Widget field = TextFormField(
      controller: controller,
      initialValue: controller == null ? initialValue : null,
      validator: validator,
      enabled: enabled,
      obscureText: obscureText,
      keyboardType: keyboardType,
      onChanged: (String value) {
        FoFormScope.markDirty(context);
        onChanged?.call(value);
      },
      maxLines: effectiveMaxLines,
      decoration: InputDecoration(
        labelText: isRequired ? '$label *' : label,
        hintText: hintText,
        helperText: helperText,
        suffixIcon: suffixIcon,
      ),
    );

    // The fixed single-line height has no room for helper text underneath, so
    // a field carrying one sizes itself instead.
    if (effectiveMaxLines != 1 || helperText != null) return field;

    return SizedBox(height: FoLayout.singleLineFieldHeight, child: field);
  }
}

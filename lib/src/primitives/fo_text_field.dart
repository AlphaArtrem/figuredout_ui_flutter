import 'package:flutter/material.dart';

import '../patterns/fo_form_scope.dart';
import '../tokens/fo_layout.dart';
import 'fo_icon_button.dart';

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
    this.revealLabel,
    this.concealLabel,
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

  /// With [obscureText], adds a show/hide toggle named by this — "Show
  /// password". A password nobody can check is a password typed twice; the
  /// toggle is how somebody on a shop-floor tablet sees what they typed.
  final String? revealLabel;

  /// The toggle's name while the text is shown — "Hide password".
  final String? concealLabel;

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
    if (obscureText && revealLabel != null && concealLabel != null) {
      return _RevealableField(field: this);
    }
    return _build(context, obscureText, suffixIcon);
  }

  Widget _build(BuildContext context, bool obscure, Widget? suffix) {
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
      obscureText: obscure,
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
        suffixIcon: suffix,
      ),
    );

    // The fixed single-line height has no room for helper text underneath, so
    // a field carrying one sizes itself instead.
    if (effectiveMaxLines != 1 || helperText != null) return field;

    return SizedBox(height: FoLayout.singleLineFieldHeight, child: field);
  }
}

/// A password field with its show/hide toggle. The shown state is the only
/// state here; everything else is the wrapped field's.
class _RevealableField extends StatefulWidget {
  const _RevealableField({required this.field});

  final FoTextField field;

  @override
  State<_RevealableField> createState() => _RevealableFieldState();
}

class _RevealableFieldState extends State<_RevealableField> {
  bool _shown = false;

  @override
  Widget build(BuildContext context) {
    final FoTextField f = widget.field;
    return f._build(
      context,
      !_shown,
      FoIconButton(
        icon:
            _shown ? Icons.visibility_off_outlined : Icons.visibility_outlined,
        semanticLabel: _shown ? f.concealLabel! : f.revealLabel!,
        onPressed: () => setState(() => _shown = !_shown),
      ),
    );
  }
}

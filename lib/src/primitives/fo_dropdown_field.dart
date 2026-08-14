import 'package:flutter/material.dart';

import '../patterns/fo_form_scope.dart';
import '../theme/fo_context.dart';
import '../tokens/fo_layout.dart';
import 'fo_spinner.dart';

/// The standard dropdown, for filters and forms.
///
/// Like `FoTextField`, everything visual comes from the theme's
/// `InputDecorationTheme`, and picking a value marks the enclosing
/// `FoFormSurface` dirty so dismissing it asks first.
class FoDropdownField<T> extends StatelessWidget {
  /// Creates a dropdown.
  const FoDropdownField({
    required this.items,
    required this.onChanged,
    this.label,
    this.value,
    this.hintText,
    this.enabled = true,
    this.isExpanded = true,
    this.isRequired = false,
    super.key,
  }) : loading = false;

  /// A field whose options are not available yet.
  ///
  /// Keeps the label and the field's shape while blocking input, so a required
  /// field never collapses into a bare spinner or vanishes from the form —
  /// which would silently change what the form looks like it is asking for.
  ///
  /// The spinner and [loadingText] show only while [isLoading]. Once a lookup
  /// has failed the field goes quiet rather than spinning forever; explaining
  /// why is the caller's error banner's job, not this field's.
  const FoDropdownField.placeholder({
    required String loadingText,
    required bool isLoading,
    this.label,
    this.isRequired = false,
    super.key,
  })  : items = const <DropdownMenuItem<Never>>[],
        onChanged = null,
        value = null,
        hintText = isLoading ? loadingText : null,
        enabled = false,
        isExpanded = true,
        loading = isLoading;

  /// The options.
  final List<DropdownMenuItem<T>> items;

  /// Called when a value is picked. Null disables the field.
  final ValueChanged<T?>? onChanged;

  /// Floating label. Caller-supplied, so it can be localized.
  final String? label;

  /// The current selection.
  final T? value;

  /// Placeholder shown while nothing is selected.
  final String? hintText;

  /// When false the field is disabled.
  final bool enabled;

  /// Stretches the menu to the field's width.
  final bool isExpanded;

  /// Appends the app-wide `*` marker to [label].
  final bool isRequired;

  /// True only for a [FoDropdownField.placeholder] that is still loading.
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final ValueChanged<T?>? handler = onChanged;

    return SizedBox(
      height: FoLayout.singleLineFieldHeight,
      child: DropdownButtonFormField<T>(
        initialValue: value,
        isExpanded: isExpanded,
        decoration: InputDecoration(
          labelText: label == null || !isRequired ? label : '$label *',
          hintText: hintText,
          isDense: true,
          suffixIcon: loading
              ? Padding(
                  padding: EdgeInsets.all(context.foSpacing.md),
                  child: const FoSpinner(),
                )
              : null,
        ),
        items: items,
        onChanged: enabled && handler != null
            ? (T? value) {
                FoFormScope.markDirty(context);
                handler(value);
              }
            : null,
      ),
    );
  }
}

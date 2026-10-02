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
///
/// **It is controlled: [value] is read on every build.** It was not always.
/// This was built on `DropdownButtonFormField`, whose `initialValue` a
/// `FormField` seeds *once* — `FormFieldState.didUpdateWidget` re-applies
/// nothing — so the field was an uncontrolled widget wearing a controlled
/// widget's API, and every change made from outside it was silently dropped. A
/// consuming form that cleared a dependent picker, or selected a row the user
/// had just created, went on showing the previous choice while the store held
/// the new one; nothing threw and nothing logged. The `FormField` was never
/// earning its keep here anyway — this component has no validator — so it is
/// gone, and an `InputDecorator` gives the same frame with no state to seed.
///
/// **The whole field is the target, and it has one name.** The decorator is
/// drawn *around* the button, so on its own the button's tappable area is one
/// line of text — 24dp inside a 56dp field — and with nothing chosen its node
/// carries no label. A thumb on the frame opened nothing and a screen reader
/// met an unnamed button. The field now merges its label, its value and the
/// button into one semantics node the size of the frame, and a tap anywhere on
/// the frame opens the menu through the button's own `ActivateIntent` — the
/// path the keyboard already takes, so there is one way to open it.
class FoDropdownField<T> extends StatefulWidget {
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
  State<FoDropdownField<T>> createState() => _FoDropdownFieldState<T>();
}

class _FoDropdownFieldState<T> extends State<FoDropdownField<T>> {
  final FocusNode _buttonFocus = FocusNode(debugLabel: 'FoDropdownField');

  @override
  void dispose() {
    _buttonFocus.dispose();
    super.dispose();
  }

  /// Opens the menu as the keyboard does. The focus node's context sits
  /// under the button's own `Actions`, so the intent reaches its handler.
  void _open() {
    final BuildContext? button = _buttonFocus.context;
    if (button == null) return;
    Actions.maybeInvoke<ActivateIntent>(button, const ActivateIntent());
  }

  @override
  Widget build(BuildContext context) {
    final ValueChanged<T?>? handler = widget.onChanged;
    final bool interactive = widget.enabled && handler != null;
    final String? label = widget.label;

    // A value with no option behind it shows as unselected rather than
    // crashing. `DropdownButton` asserts on one, and the caller that hits that
    // assert is usually a list that has just been refiltered — a court whose
    // location changed a frame ago — where an empty field is the honest
    // rendering and an assert is a crash in front of a user.
    final T? selected = widget.items
            .any((DropdownMenuItem<T> item) => item.value == widget.value)
        ? widget.value
        : null;

    final Widget frame = SizedBox(
      height: FoLayout.singleLineFieldHeight,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label == null || !widget.isRequired ? label : '$label *',
          hintText: widget.hintText,
          isDense: true,
          enabled: interactive,
          suffixIcon: widget.loading
              ? Padding(
                  padding: EdgeInsets.all(context.foSpacing.md),
                  child: const FoSpinner(),
                )
              : null,
        ),
        // What makes the label float and the hint show. The decorator cannot
        // see inside the button, so it has to be told.
        isEmpty: selected == null,
        child: DropdownButtonHideUnderline(
          child: DropdownButton<T>(
            value: selected,
            items: widget.items,
            isExpanded: widget.isExpanded,
            isDense: true,
            focusNode: _buttonFocus,
            onChanged: interactive
                ? (T? next) {
                    FoFormScope.markDirty(context);
                    handler(next);
                  }
                : null,
          ),
        ),
      ),
    );

    // One node, the size of the frame: the floating label, the value or the
    // hint, and the button's role and tap. The frame's own tap goes through
    // the button (see [_open]); a tap on the text line is won by the button's
    // InkWell, which is deeper, so the menu never opens twice.
    return MergeSemantics(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        excludeFromSemantics: true,
        onTap: interactive ? _open : null,
        child: frame,
      ),
    );
  }
}

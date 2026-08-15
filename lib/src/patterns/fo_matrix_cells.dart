import 'package:flutter/material.dart';

import '../theme/fo_context.dart';
import 'fo_form_scope.dart';

/// A column heading for a `FoMatrixTable`.
///
/// A one-line wrapper rather than a bare `Text`, so every grid's headings agree
/// on their type and their alignment instead of each screen restating them.
class FoMatrixHeaderText extends StatelessWidget {
  /// Creates a heading.
  const FoMatrixHeaderText(
    this.label, {
    this.textAlign = TextAlign.center,
    super.key,
  });

  /// The column's name. Caller-supplied, so it can be localized.
  final String label;

  /// How the name sits when it wraps.
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) => Text(
        label,
        textAlign: textAlign,
        style: context.foText.label,
      );
}

/// An editable integer cell for a `FoMatrixTable`.
///
/// Dense on purpose: a `FoTextField` is 56dp tall and a matrix row is 48, and
/// a grid of full fields is unreadable anyway — the value is the point, not
/// its box.
///
/// Typing marks the enclosing `FoFormSurface` dirty, exactly as `FoTextField`
/// does, so a size grid inside a form is covered by the discard guard without
/// the screen having to remember it.
class FoMatrixNumericCell extends StatelessWidget {
  /// Creates an editable quantity cell.
  const FoMatrixNumericCell({
    required this.value,
    required this.onChanged,
    this.readOnly = false,
    this.label,
    this.emptyWhenZero = true,
    this.padding,
    super.key,
  });

  /// The current quantity.
  final int value;

  /// Called with the parsed quantity. Unparseable input reads as zero rather
  /// than as an error: a half-typed cell is not a mistake, it is a cell being
  /// typed into.
  final ValueChanged<int> onChanged;

  /// Renders the value without allowing edits.
  final bool readOnly;

  /// A floating label inside the cell, for a grid too narrow for headings.
  /// Caller-supplied, so it can be localized.
  final String? label;

  /// Shows an empty box instead of `0`.
  ///
  /// On by default, and it is what makes a sparse grid readable: a hundred
  /// zeroes hide the six cells that carry a quantity.
  final bool emptyWhenZero;

  /// Overrides the cell's own inset.
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          padding ?? EdgeInsets.symmetric(horizontal: context.foSpacing.xs),
      child: TextFormField(
        initialValue: emptyWhenZero && value == 0 ? '' : '$value',
        enabled: !readOnly,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        style: context.foText.numeric,
        decoration: InputDecoration(isDense: true, labelText: label),
        onChanged: (String raw) {
          FoFormScope.markDirty(context);
          onChanged(int.tryParse(raw) ?? 0);
        },
      ),
    );
  }
}

/// A computed total in a `FoMatrixTable` — a row's sum, a column's sum.
///
/// Carried in `FoTextStyles.numeric` so a column of them aligns on its digits,
/// and in `primary` so a derived figure is visibly not one that was typed.
class FoMatrixTotalText extends StatelessWidget {
  /// Creates a total.
  const FoMatrixTotalText(
    this.value, {
    this.textAlign = TextAlign.center,
    super.key,
  });

  /// The total.
  final int value;

  /// How the figure sits in its cell.
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) => Text(
        '$value',
        textAlign: textAlign,
        style: context.foText.numeric.copyWith(
          color: context.foColors.primary,
          fontWeight: FontWeight.w600,
        ),
      );
}

/// A per-cell or per-row validation message in a `FoMatrixTable`.
///
/// In `danger`, which carries its own ink — see rule §3.4 and gotcha G4.
class FoMatrixValidationText extends StatelessWidget {
  /// Creates a validation message.
  const FoMatrixValidationText(this.message, {super.key});

  /// What is wrong. Caller-supplied, so it can be localized.
  final String message;

  @override
  Widget build(BuildContext context) => Text(
        message,
        style: context.foText.caption.copyWith(color: context.foColors.danger),
      );
}

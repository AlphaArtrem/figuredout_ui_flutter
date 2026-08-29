import 'package:flutter/material.dart';

import 'fo_text_field.dart';

/// A calendar date, typed or picked.
///
/// **Both, deliberately.** Somebody entering a month of filings types faster
/// than any picker can be tapped, and somebody who does this twice a month
/// wants the calendar. A field that offers only one of the two is wrong for
/// half its users, and which half depends on the screen.
///
/// The value is the controller's **text**, and it is an ISO-8601 calendar date
/// — `2026-08-29`. That is a contract, not a default: it is the one written
/// form with no ambiguity between the day and the month, it sorts as a string,
/// and it is what every JSON API this package's consumers talk to already
/// exchanges. [foIsoDate] and [foParseIsoDate] convert, and nothing else needs
/// to know.
///
/// **A date is not an instant.** There is no time and no zone here on purpose:
/// stored as a timestamp, a hearing on the 26th shows as the 25th to someone
/// whose phone is set to another country. Whoever needs an instant derives it
/// from this date plus a zone they choose.
///
/// How the date is *worded* for reading — "29 Aug 2026", "२९ अगस्त" — is not
/// this field's job. This is an input, its text is the value, and a screen that
/// wants a prettier rendering is displaying rather than collecting.
class FoDateField extends StatelessWidget {
  /// Creates a date field.
  const FoDateField({
    required this.label,
    required this.controller,
    required this.pickSemanticLabel,
    this.firstDate,
    this.lastDate,
    this.isRequired = false,
    this.enabled = true,
    this.helperText,
    this.hintText,
    this.onChanged,
    this.pickerHelpText,
    this.confirmLabel,
    this.cancelLabel,
    super.key,
  });

  /// Floating label. Caller-supplied, so it can be localized.
  final String label;

  /// Holds the value. Its text is an ISO-8601 date, or empty.
  final TextEditingController controller;

  /// Names the calendar button for a screen reader.
  ///
  /// **Required, because the button is icon-only** and an unnamed icon is
  /// invisible to anyone not looking at it. The package holds no copy, so the
  /// sentence — "Pick the filing date from a calendar" — is the caller's.
  final String pickSemanticLabel;

  /// The earliest and latest dates the calendar offers.
  ///
  /// Defaulting to a century either side is not a guess about the caller's
  /// domain — it is the absence of one. A screen that knows its range says so;
  /// a screen that does not gets a window wide enough never to be the reason
  /// somebody cannot enter a real date.
  final DateTime? firstDate;
  final DateTime? lastDate;

  /// Appends the app-wide `*` marker to [label].
  final bool isRequired;

  /// When false the field is disabled and the calendar cannot be opened.
  final bool enabled;

  /// One line under the field. **It does not wrap** — `InputDecoration`
  /// ellipsises it — so keep it to a few words.
  final String? helperText;

  /// Placeholder shown while the field is empty. An example date reads better
  /// than a format string: `2026-08-29`, not `YYYY-MM-DD`.
  final String? hintText;

  /// Called with the field's text after it is typed or picked.
  final ValueChanged<String>? onChanged;

  /// Copy for the calendar itself. Null leaves Material's own localized
  /// strings, which is usually right — pass these only when the surrounding
  /// screen uses different words for the same acts.
  final String? pickerHelpText;
  final String? confirmLabel;
  final String? cancelLabel;

  @override
  Widget build(BuildContext context) {
    return FoTextField(
      label: label,
      controller: controller,
      isRequired: isRequired,
      enabled: enabled,
      helperText: helperText,
      hintText: hintText,
      onChanged: onChanged,
      keyboardType: TextInputType.datetime,
      suffixIcon: IconButton(
        onPressed: enabled ? () => _pick(context) : null,
        icon: const Icon(Icons.calendar_today_outlined),
        tooltip: pickSemanticLabel,
      ),
    );
  }

  Future<void> _pick(BuildContext context) async {
    final DateTime today = DateTime.now();
    final DateTime first = firstDate ?? DateTime(today.year - 100);
    final DateTime last = lastDate ?? DateTime(today.year + 100);

    // Whatever is already typed, when it is a date and inside the window.
    // Falling back to today rather than to `first` — a calendar that opens a
    // hundred years ago is a calendar nobody scrolls out of.
    final DateTime? typed = foParseIsoDate(controller.text);
    final DateTime initial =
        typed != null && !typed.isBefore(first) && !typed.isAfter(last)
            ? typed
            : (today.isBefore(first)
                ? first
                : (today.isAfter(last) ? last : today));

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: last,
      helpText: pickerHelpText,
      confirmText: confirmLabel,
      cancelText: cancelLabel,
    );
    if (picked == null) return;

    final String value = foIsoDate(picked);
    controller.text = value;
    onChanged?.call(value);
  }
}

/// [date]'s day as an ISO-8601 calendar date, ignoring its time and its zone.
String foIsoDate(DateTime date) {
  final String month = date.month.toString().padLeft(2, '0');
  final String day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
}

/// Parses `YYYY-MM-DD` into a local midnight, or returns null.
///
/// **Strict about the round trip**, because `DateTime.parse` accepts
/// `2024-02-31` and rolls it quietly into March. A date that does not come back
/// the way it went in is not the date somebody typed.
DateTime? foParseIsoDate(String? value) {
  if (value == null || value.length != 10) return null;
  final DateTime? parsed = DateTime.tryParse(value);
  if (parsed == null) return null;
  final DateTime date = DateTime(parsed.year, parsed.month, parsed.day);
  return foIsoDate(date) == value ? date : null;
}

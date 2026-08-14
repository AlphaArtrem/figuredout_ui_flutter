import 'package:flutter/material.dart';

import '../theme/fo_context.dart';
import '../tokens/fo_tokens.dart';

/// One rendering for a yes/no value in a table.
///
/// The point is that there is only one. Left alone, two screens will show the
/// same fact two ways — a bare green tick here, a "Yes"/"No" chip there — and
/// the same data starts looking like two different kinds of data.
///
/// The tick reads faster in a dense table, and the word is not lost: it goes
/// to the accessible label, which is why [yesLabel] and [noLabel] are required
/// rather than defaulted to English.
class FoBooleanCell extends StatelessWidget {
  /// Creates a boolean cell.
  const FoBooleanCell({
    required this.value,
    required this.yesLabel,
    required this.noLabel,
    this.label,
    super.key,
  });

  /// The value.
  final bool value;

  /// The word for true, localized by the caller.
  final String yesLabel;

  /// The word for false, localized by the caller.
  final String noLabel;

  /// What the value is about — "Active", say. Prefixes the announcement
  /// ("Active: Yes") so the cell is not read as a lone "Yes" with no subject.
  final String? label;

  @override
  Widget build(BuildContext context) {
    final String text = value ? yesLabel : noLabel;

    return Semantics(
      label: label == null ? text : '$label: $text',
      excludeSemantics: true,
      child: Icon(
        value ? Icons.check : Icons.close,
        size: FoTokens.iconSmall,
        // False is not a failure, so it is muted ink rather than danger.
        color: value ? context.foColors.success : context.foColors.fgMuted,
      ),
    );
  }
}

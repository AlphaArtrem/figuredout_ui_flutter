import 'package:flutter/material.dart';

import '../theme/fo_context.dart';

/// One line of a table cell: [primary] (a code, a name) then [secondary] in
/// muted ink after " · ", with the whole text in a tooltip.
///
/// When the line does not fit, the [primary] text stays whole and only the muted
/// [secondary] is ellipsised, so a code is never the part that gets cut. If the
/// [primary] alone does not fit, the whole line is ellipsised. The tooltip and
/// the semantics label are the full text. The package holds no copy: both
/// strings come from the caller, and " · " is punctuation, not a word.
///
/// It is the cell of a one-line `FoDataTable(sizing: content)` row.
class FoCellText extends StatelessWidget {
  /// Creates a cell's text.
  const FoCellText(
    this.primary, {
    super.key,
    this.secondary,
    this.mono = false,
  });

  /// The main text: a code, a name.
  final String primary;

  /// What goes with it, muted and after " · " ("2 Oct, 14:20 · Imran").
  final String? secondary;

  /// Draws [primary] as a code, in tabular figures.
  final bool mono;

  @override
  Widget build(BuildContext context) {
    final TextStyle strong = mono
        ? context.foText.numeric.copyWith(fontWeight: FontWeight.w600)
        : context.foText.body.copyWith(fontWeight: FontWeight.w500);
    final TextStyle muted = context.foText.body.copyWith(
      color: context.foColors.fgMuted,
    );
    final String? more =
        secondary == null || secondary!.isEmpty ? null : secondary;
    final String full = more == null
        ? primary
        : primary.isEmpty
            ? more
            : '$primary · $more';
    final Widget whole = Text.rich(
      TextSpan(
        children: <InlineSpan>[
          if (primary.isNotEmpty) TextSpan(text: primary, style: strong),
          if (more != null)
            TextSpan(
              text: primary.isEmpty ? more : ' · $more',
              style: muted,
            ),
        ],
      ),
      maxLines: 1,
      softWrap: false,
      overflow: TextOverflow.ellipsis,
    );
    if (more == null || primary.isEmpty) {
      return _tip(full, whole);
    }
    return _tip(
      full,
      LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final double room = constraints.maxWidth;
          if (!room.isFinite) return whole;
          final TextStyle base = DefaultTextStyle.of(context).style;
          double width(List<InlineSpan> spans) {
            final TextPainter painter = TextPainter(
              text: TextSpan(style: base, children: spans),
              maxLines: 1,
              textScaler: MediaQuery.textScalerOf(context),
              textDirection: Directionality.of(context),
            )..layout();
            final double w = painter.width;
            painter.dispose();
            return w;
          }

          final double all = width(<InlineSpan>[
            TextSpan(text: primary, style: strong),
            TextSpan(text: ' · $more', style: muted),
          ]);
          if (all <= room) return whole;
          final double code = width(<InlineSpan>[
            TextSpan(text: primary, style: strong),
          ]);
          // The code does not fit either: nothing to protect, cut as before.
          if (code > room) return whole;
          // The code stays whole; only what follows it gives way.
          return Semantics(
            label: full,
            excludeSemantics: true,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(primary, style: strong, maxLines: 1, softWrap: false),
                Flexible(
                  child: Text(
                    ' · $more',
                    style: muted,
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _tip(String full, Widget child) =>
      Tooltip(message: full, excludeFromSemantics: true, child: child);
}

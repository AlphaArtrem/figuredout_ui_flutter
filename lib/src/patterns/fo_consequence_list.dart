import 'package:flutter/material.dart';

import '../primitives/fo_status_chip.dart';
import '../theme/fo_context.dart';

/// One thing a decision will do.
@immutable
class FoConsequence {
  /// Creates a consequence.
  const FoConsequence({
    required this.text,
    this.figure,
    this.tone = FoStatusTone.neutral,
  });

  /// What happens, as a sentence — "Line 1 stops getting new bundles for this
  /// order." Caller-supplied.
  final String text;

  /// A figure leading the sentence — "32" go to Bartek. Mono, right-aligned,
  /// in the tone's ink. Null draws a toned dot instead.
  final String? figure;

  /// How much it matters: neutral, warning, danger — or success for "goes on
  /// to the next stage".
  final FoStatusTone tone;
}

/// What a decision will do, before somebody makes it: "What this change
/// does", "When you submit".
///
/// A confirmation that names the record is half the job; the other half is
/// saying what happens next — 32 go to Bartek, 5 go back to Line 1, the
/// buyer is not told. Each line is a sentence with either a toned dot or a
/// figure in the tone's ink. An optional [note] closes it — a warning that
/// the step cannot be undone.
class FoConsequenceList extends StatelessWidget {
  /// Creates a consequence list.
  const FoConsequenceList({
    required this.items,
    this.title,
    this.note,
    super.key,
  });

  /// The heading — "What this change does".
  final String? title;

  /// The consequences, most important first.
  final List<FoConsequence> items;

  /// A closing note under the list, usually a `FoInfoBanner`.
  final Widget? note;

  static Color _ink(BuildContext context, FoStatusTone tone) => switch (tone) {
        FoStatusTone.neutral => context.foColors.fgSubtle,
        FoStatusTone.primary => context.foColors.primary,
        FoStatusTone.success => context.foColors.success,
        FoStatusTone.warning => context.foColors.warning,
        FoStatusTone.danger => context.foColors.danger,
        FoStatusTone.info => context.foColors.info,
      };

  @override
  Widget build(BuildContext context) {
    final BorderRadius radius = BorderRadius.circular(context.foRadii.md);
    final bool figures = items.any((FoConsequence i) => i.figure != null);

    return Container(
      padding: EdgeInsets.all(context.foSpacing.lg),
      decoration: BoxDecoration(
        color: context.foColors.surface,
        borderRadius: radius,
      ),
      foregroundDecoration: BoxDecoration(
        borderRadius: radius,
        border: Border.all(color: context.foColors.edge),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (title != null) ...<Widget>[
            Semantics(
              header: true,
              child: Text(title!, style: context.foText.subtitle),
            ),
            SizedBox(height: context.foSpacing.md),
          ],
          for (int i = 0; i < items.length; i++) ...<Widget>[
            if (i > 0) SizedBox(height: context.foSpacing.sm),
            MergeSemantics(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  if (figures)
                    ConstrainedBox(
                      constraints: const BoxConstraints(minWidth: 32),
                      child: Text(
                        items[i].figure ?? '',
                        textAlign: TextAlign.end,
                        style: context.foText.numeric.copyWith(
                          fontWeight: FontWeight.w700,
                          color: _ink(context, items[i].tone),
                        ),
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.only(top: 7),
                      child: Center(
// A circle stays a circle under any constraints (see FoDisc).
                        widthFactor: 1,
                        heightFactor: 1,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _ink(context, items[i].tone),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                  SizedBox(width: context.foSpacing.sm),
                  Expanded(
                    child: Text(
                      items[i].text,
                      style: context.foText.body.copyWith(height: 1.5),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (note != null) ...<Widget>[
            SizedBox(height: context.foSpacing.md),
            note!,
          ],
        ],
      ),
    );
  }
}

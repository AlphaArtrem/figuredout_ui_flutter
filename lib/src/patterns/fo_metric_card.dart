import 'package:flutter/material.dart';

import '../primitives/fo_card.dart';
import '../primitives/fo_progress_bar.dart';
import '../primitives/fo_status_chip.dart';
import '../theme/fo_context.dart';
import '../tokens/fo_tokens.dart';

/// One figure on a [FoMetricCard].
@immutable
class FoMetric {
  /// Creates a metric.
  const FoMetric(
      {required this.label, required this.value, this.warning = false});

  /// What it is — "Sewn today". Caller-supplied.
  final String label;

  /// The figure, formatted.
  final String value;

  /// Draws it in the warning ink — the one figure that is the problem.
  final bool warning;
}

/// A thing with several figures and a verdict: a sewing line today, a
/// machine, a table — "Line 3 · Anjali Rao · Behind target".
///
/// Distinct from `FoStatCard`, which is one figure: this is a small panel
/// about one *thing*, read as a unit — who runs it, what it is working on,
/// three or four figures, and how it is doing against a target as a bar with
/// the numbers beside it. The whole card is the target when [onTap] is set
/// (it opens the thing), and [selected] marks the one open in the side panel.
class FoMetricCard extends StatelessWidget {
  /// Creates a metric card.
  const FoMetricCard({
    required this.title,
    required this.metrics,
    this.subtitle,
    this.status,
    this.subject,
    this.meterLabel,
    this.meterValue,
    this.meterMax,
    this.meterCaption,
    this.meterTone = FoStatusTone.primary,
    this.onTap,
    this.selected = false,
    super.key,
  });

  /// The thing — "Line 3". Caller-supplied.
  final String title;

  /// Who runs it — "Anjali Rao".
  final String? subtitle;

  /// Its verdict — a `FoStatusChip` "Behind target".
  final Widget? status;

  /// What it is working on — a swatch and "Oxford Button-Down · Slate Blue".
  final Widget? subject;

  /// The figures, three or four.
  final List<FoMetric> metrics;

  /// The meter's name — "Efficiency".
  final String? meterLabel;

  /// The meter's reading.
  final double? meterValue;

  /// The meter's target.
  final double? meterMax;

  /// The reading in words — "212 of 329 target so far · 64%". Also its
  /// semantic value.
  final String? meterCaption;

  /// The meter's fill — warning when behind.
  final FoStatusTone meterTone;

  /// Opens the thing.
  final VoidCallback? onTap;

  /// Marks the card that is open beside the list.
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final Widget content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: context.foSpacing.sm,
          runSpacing: context.foSpacing.xs,
          children: <Widget>[
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(title, style: context.foText.title),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: context.foText.body.copyWith(
                      color: context.foColors.fgMuted,
                    ),
                  ),
              ],
            ),
            if (status != null) status!,
          ],
        ),
        if (subject != null) ...<Widget>[
          SizedBox(height: context.foSpacing.md),
          subject!,
        ],
        SizedBox(height: context.foSpacing.md),
        Wrap(
          spacing: context.foSpacing.xl,
          runSpacing: context.foSpacing.md,
          children: <Widget>[
            for (final FoMetric m in metrics)
              MergeSemantics(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      m.label,
                      style: context.foText.body.copyWith(
                        fontSize: FoTokens.fontCaption,
                        color: m.warning
                            ? context.foColors.warning
                            : context.foColors.fgSubtle,
                      ),
                    ),
                    Text(
                      m.value,
                      style: context.foText.numeric.copyWith(
                        fontSize: FoTokens.fontDisplay,
                        fontWeight:
                            m.warning ? FontWeight.w700 : FontWeight.w600,
                        color: m.warning ? context.foColors.warning : null,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        if (meterValue != null && meterMax != null) ...<Widget>[
          SizedBox(height: context.foSpacing.md),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            spacing: context.foSpacing.sm,
            children: <Widget>[
              if (meterLabel != null)
                Text(meterLabel!, style: context.foText.label),
              if (meterCaption != null)
                Text(
                  meterCaption!,
                  style: context.foText.body.copyWith(
                    fontSize: FoTokens.fontLabel,
                    color: context.foColors.fgMuted,
                  ),
                ),
            ],
          ),
          SizedBox(height: context.foSpacing.xs),
          FoProgressBar(
            value: meterValue!,
            max: meterMax!,
            tone: meterTone,
            semanticLabel: meterLabel ?? title,
            semanticValue: meterCaption ?? '',
          ),
        ],
      ],
    );

    final Widget card = FoCard(
      onTap: onTap,
      semanticLabel: onTap == null ? null : title,
      padding: EdgeInsets.all(context.foSpacing.lg),
      child: content,
    );

    if (!selected) return card;
    final BorderRadius radius = BorderRadius.circular(context.foRadii.card);
    return Semantics(
      selected: true,
      child: DecoratedBox(
        position: DecorationPosition.foreground,
        decoration: BoxDecoration(
          borderRadius: radius,
          border: Border.all(color: context.foColors.primary, width: 2),
        ),
        child: card,
      ),
    );
  }
}

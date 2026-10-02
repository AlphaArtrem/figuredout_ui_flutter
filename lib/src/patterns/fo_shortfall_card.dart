import 'package:flutter/material.dart';

import '../primitives/fo_icon_button.dart';
import '../theme/fo_context.dart';
import '../tokens/fo_layout.dart';
import '../tokens/fo_tokens.dart';

/// One line of a [FoShortfallCard]'s breakdown — "Received 401.2 kg".
@immutable
class FoShortfallLine {
  /// Creates a line.
  const FoShortfallLine({
    required this.label,
    required this.value,
    this.emphasis = false,
  });

  /// "Needed for the cutting plan". Caller-supplied.
  final String label;

  /// "420.0 kg". Formatted.
  final String value;

  /// The line the card is about — "Short" — in the state's ink.
  final bool emphasis;
}

/// Have versus need: is there enough fabric to cut, enough pieces to pack?
///
/// Short is a warning — the work can still go on, someone has to decide how
/// — and enough is a quiet success. The bar fills [have] against [need] with a
/// tick at the target, and the [lines] break the figure down so nobody has to
/// trust a percentage they cannot check. [actions] are what to do about it;
/// [suggestion] is a fix the system has already worked out ("Use 56 layers
/// (448 pieces)").
class FoShortfallCard extends StatelessWidget {
  /// Creates a shortfall card.
  const FoShortfallCard({
    required this.title,
    required this.have,
    required this.need,
    required this.semanticValue,
    this.message,
    this.lines = const <FoShortfallLine>[],
    this.actions = const <Widget>[],
    this.suggestion,
    this.onHelp,
    this.helpLabel,
    super.key,
  }) : assert(need > 0, 'a need of nothing is always met');

  /// The verdict — "6% short for cutting", "Enough to cut". Caller-supplied.
  final String title;

  /// What there is.
  final double have;

  /// What is needed.
  final double need;

  /// The reading in words — "394.8 of 420.0 kg usable".
  final String semanticValue;

  /// One or two sentences on what it means.
  final String? message;

  /// The breakdown.
  final List<FoShortfallLine> lines;

  /// What to do about it.
  final List<Widget> actions;

  /// A fix already worked out, shown above [actions].
  final Widget? suggestion;

  /// Opens "How is this worked out?".
  final VoidCallback? onHelp;

  /// The help button's name.
  final String? helpLabel;

  /// Whether there is enough.
  bool get isShort => have < need;

  @override
  Widget build(BuildContext context) {
    final bool short = isShort;
    final Color ink =
        short ? context.foColors.warning : context.foColors.success;
    final Color ground =
        short ? context.foColors.warningSoft : context.foColors.successSoft;
    final BorderRadius radius = BorderRadius.circular(context.foRadii.card);
    final double fraction = (have / need).clamp(0.0, 1.0);

    return Semantics(
      container: true,
      liveRegion: true,
      child: Container(
        padding: EdgeInsets.all(context.foSpacing.lg),
        decoration: BoxDecoration(color: ground, borderRadius: radius),
        foregroundDecoration: BoxDecoration(
          borderRadius: radius,
          border: Border.all(
            color: ink.withValues(alpha: FoLayout.bannerEdgeOpacity),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(
                  short
                      ? Icons.warning_amber_outlined
                      : Icons.check_circle_outline,
                  color: ink,
                  size: FoTokens.iconMedium - 2,
                ),
                SizedBox(width: context.foSpacing.sm),
                Expanded(
                  child: Text(
                    title,
                    style: context.foText.subtitle.copyWith(
                      color: ink,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (onHelp != null && helpLabel != null)
                  FoIconButton(
                    icon: Icons.help_outline,
                    tone: FoIconButtonTone.primary,
                    semanticLabel: helpLabel!,
                    onPressed: onHelp,
                  ),
              ],
            ),
            if (message != null) ...<Widget>[
              SizedBox(height: context.foSpacing.xs),
              Text(
                message!,
                style: context.foText.body.copyWith(
                  color: context.foColors.fgMuted,
                ),
              ),
            ],
            SizedBox(height: context.foSpacing.md),
            Semantics(
              label: title,
              value: semanticValue,
              child: ExcludeSemantics(
                child: SizedBox(
                  height: 20,
                  child: Stack(
                    alignment: AlignmentDirectional.centerStart,
                    children: <Widget>[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: SizedBox(
                          height: 12,
                          child: Stack(
                            fit: StackFit.expand,
                            children: <Widget>[
                              ColoredBox(color: context.foCharts.track),
                              FractionallySizedBox(
                                alignment: AlignmentDirectional.centerStart,
                                widthFactor: fraction,
                                child: ColoredBox(color: ink),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // The target tick, at the end: what "enough" is.
                      Align(
                        alignment: AlignmentDirectional.centerEnd,
                        child: Container(
                          width: 2,
                          height: 20,
                          color: context.foColors.fg,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (lines.isNotEmpty) ...<Widget>[
              SizedBox(height: context.foSpacing.md),
              for (final FoShortfallLine line in lines)
                MergeSemantics(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      vertical: context.foSpacing.xs / 2,
                    ),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            line.label,
                            style: context.foText.body.copyWith(
                              color: line.emphasis ? ink : null,
                              fontWeight:
                                  line.emphasis ? FontWeight.w700 : null,
                            ),
                          ),
                        ),
                        Text(
                          line.value,
                          style: context.foText.numeric.copyWith(
                            color: line.emphasis ? ink : null,
                            fontWeight: line.emphasis
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
            if (suggestion != null) ...<Widget>[
              SizedBox(height: context.foSpacing.md),
              suggestion!,
            ],
            if (actions.isNotEmpty) ...<Widget>[
              SizedBox(height: context.foSpacing.md),
              Wrap(
                spacing: context.foSpacing.sm,
                runSpacing: context.foSpacing.sm,
                children: actions,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

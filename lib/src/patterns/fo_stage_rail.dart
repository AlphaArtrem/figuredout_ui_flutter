import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/fo_context.dart';
import '../tokens/fo_layout.dart';
import '../tokens/fo_tokens.dart';

/// Where a stage stands relative to the one being looked at.
enum FoStageState {
  /// No stage is singled out — a dashboard's row of stages. Outlined number.
  neutral,

  /// Before the current stage. Filled number.
  done,

  /// The stage this screen is about. On the primary wash, ringed.
  current,

  /// After the current stage. Outlined number, quieter label, resting ground.
  upcoming,
}

/// One stage in a [FoStageRail] — or a stage figure on its own, as a
/// [FoStageTile].
@immutable
class FoStage {
  /// Creates a stage.
  const FoStage({
    required this.number,
    required this.label,
    required this.value,
    this.caption,
    this.detail,
    this.detailIsWarning = false,
    this.badge,
    this.state = FoStageState.neutral,
  });

  /// The stage's place in production order — 1 to 9. Shown in its disc,
  /// because the order is the thing somebody learns first.
  final int number;

  /// The stage's name as the floor says it — "Thread cutting".
  final String label;

  /// The figure, already formatted — "1,840". Mono.
  final String value;

  /// What the figure is — "done today". Under it.
  final String? caption;

  /// A second fact, under a hairline — "6,480 waiting".
  final String? detail;

  /// Draws [detail] in the warning ink — the current stage's pile.
  final bool detailIsWarning;

  /// A status for the stage as a whole — a `FoStatusChip` "Piling up".
  final Widget? badge;

  /// Where the stage stands.
  final FoStageState state;
}

/// One stage's figure as a tile: number and name, the figure, what it is, and
/// optionally a second fact and a status — a dashboard's stage KPI.
class FoStageTile extends StatelessWidget {
  /// Creates a stage tile.
  const FoStageTile({
    required this.stage,
    this.prominent = false,
    super.key,
  });

  /// The stage.
  final FoStage stage;

  /// Sets the figure at the KPI size. A rail of nine stages under an order
  /// uses the smaller size; a dashboard's "done today" row uses this.
  final bool prominent;

  /// The figure's size on a prominent tile.
  static const double _prominentValueSize = 24;

  @override
  Widget build(BuildContext context) {
    final bool current = stage.state == FoStageState.current;
    final bool upcoming = stage.state == FoStageState.upcoming;
    final BorderRadius radius = BorderRadius.circular(context.foRadii.md);

    final Color ground = current
        ? context.foColors.primarySoft
        : upcoming
            ? context.foColors.surface
            : context.foColors.surfaceRaised;

    return Semantics(
      container: true,
      selected: current,
      child: Container(
        padding: EdgeInsets.all(context.foSpacing.md),
        decoration: BoxDecoration(color: ground, borderRadius: radius),
        foregroundDecoration: BoxDecoration(
          borderRadius: radius,
          border: Border.all(
            color: current ? context.foColors.primary : context.foColors.edge,
            width: current ? 2 : FoLayout.hairlineWidth,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            _StageName(stage: stage),
            SizedBox(height: context.foSpacing.sm),
            Text(
              stage.value,
              style: context.foText.numeric.copyWith(
                fontSize:
                    prominent ? _prominentValueSize : FoTokens.fontSubtitle,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (stage.caption != null)
              Text(
                stage.caption!,
                style: context.foText.body.copyWith(
                  fontSize: FoTokens.fontCaption,
                  color: context.foColors.fgSubtle,
                ),
              ),
            if (stage.detail != null) ...<Widget>[
              if (prominent) ...<Widget>[
                SizedBox(height: context.foSpacing.sm),
                Divider(
                  height: FoLayout.hairlineWidth,
                  thickness: FoLayout.hairlineWidth,
                  color: context.foColors.edge,
                ),
              ],
              SizedBox(height: context.foSpacing.sm),
              _Detail(stage: stage),
            ],
            if (stage.badge != null) ...<Widget>[
              SizedBox(height: context.foSpacing.sm),
              stage.badge!,
            ],
          ],
        ),
      ),
    );
  }
}

/// An order's stages, or a unit's, in production order — each with its
/// figure.
///
/// **Two layouts, one list.** Wide: one row of equal tiles when they fit at
/// [minTileWidth], otherwise as many equal columns as fit, wrapping — never a
/// sideways scroll, because the stage furthest right is the one somebody
/// needs — and every tile in a row as tall as the tallest. Phone: a list, one
/// stage per line with its figure on the right, because nine tiles at 390
/// points are nine unreadable ones.
///
/// Each stage is one node for a screen reader, read in production order as
/// its number, name, figure and detail; the [FoStageState.current] one is
/// marked selected.
class FoStageRail extends StatelessWidget {
  /// Creates a stage rail.
  const FoStageRail({
    required this.stages,
    this.prominent = false,
    this.minTileWidth = 108,
    super.key,
  });

  /// The stages, in production order.
  final List<FoStage> stages;

  /// Sets the figures at KPI size — see [FoStageTile.prominent].
  final bool prominent;

  /// The narrowest a tile may be before the row wraps.
  final double minTileWidth;

  @override
  Widget build(BuildContext context) {
    if (stages.isEmpty) return const SizedBox.shrink();
    if (!context.foWindowClass.isAtLeastMedium) return _list(context);

    final double gap = context.foSpacing.sm;
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double width = constraints.maxWidth;
        final int columns = math.max(
          1,
          math.min(
            stages.length,
            ((width + gap) / (minTileWidth + gap)).floor(),
          ),
        );
        // Rows of equal-height tiles rather than a Wrap: a tile with a
        // badge is taller than one without, and a ragged row of figures reads
        // as figures that did not finish loading. Nine tiles at most, so the
        // intrinsic pass is cheap.
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            for (int start = 0;
                start < stages.length;
                start += columns) ...<Widget>[
              if (start > 0) SizedBox(height: gap),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    for (int i = start; i < start + columns; i++) ...<Widget>[
                      if (i > start) SizedBox(width: gap),
                      Expanded(
                        child: i < stages.length
                            ? FoStageTile(
                                stage: stages[i],
                                prominent: prominent,
                              )
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _list(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          for (int i = 0; i < stages.length; i++) ...<Widget>[
            if (i > 0)
              Divider(
                height: FoLayout.hairlineWidth,
                thickness: FoLayout.hairlineWidth,
                color: context.foColors.edge,
              ),
            _ListRow(stage: stages[i]),
          ],
        ],
      );
}

class _ListRow extends StatelessWidget {
  const _ListRow({required this.stage});

  final FoStage stage;

  @override
  Widget build(BuildContext context) {
    final bool current = stage.state == FoStageState.current;
    return Semantics(
      container: true,
      selected: current,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: FoLayout.minTouchTarget),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: context.foSpacing.sm),
          child: Row(
            children: <Widget>[
              Expanded(child: _StageName(stage: stage)),
              SizedBox(width: context.foSpacing.md),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      stage.value,
                      textAlign: TextAlign.end,
                      style: context.foText.numeric.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (stage.detail != null) _Detail(stage: stage),
                    if (stage.badge != null) ...<Widget>[
                      SizedBox(height: context.foSpacing.xs),
                      stage.badge!,
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The numbered disc and the stage's name.
class _StageName extends StatelessWidget {
  const _StageName({required this.stage});

  final FoStage stage;

  static const double _discSize = 20;

  @override
  Widget build(BuildContext context) {
    final bool filled =
        stage.state == FoStageState.done || stage.state == FoStageState.current;
    final bool current = stage.state == FoStageState.current;
    final bool upcoming = stage.state == FoStageState.upcoming;

    return Row(
      children: <Widget>[
        Center(
// A circle stays a circle under any constraints (see FoDisc).
          widthFactor: 1,
          heightFactor: 1,
          child: Container(
            width: _discSize,
            height: _discSize,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: filled ? context.foColors.primary : Colors.transparent,
            ),
            foregroundDecoration: filled
                ? null
                : BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: context.foColors.edgeStrong),
                  ),
            child: Text(
              '${stage.number}',
              style: context.foText.numeric.copyWith(
                fontSize: FoTokens.fontCaption,
                fontWeight: FontWeight.w600,
                color: filled
                    ? context.foColors.primaryFg
                    : context.foColors.fgSubtle,
              ),
            ),
          ),
        ),
        SizedBox(width: context.foSpacing.sm),
        Flexible(
          child: Text(
            stage.label,
            style: context.foText.label.copyWith(
              color: current
                  ? context.foColors.primary
                  : upcoming
                      ? context.foColors.fgMuted
                      : context.foColors.fg,
              fontWeight: current ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _Detail extends StatelessWidget {
  const _Detail({required this.stage});

  final FoStage stage;

  @override
  Widget build(BuildContext context) => Text(
        stage.detail!,
        style: context.foText.body.copyWith(
          fontSize: FoTokens.fontLabel,
          fontWeight: stage.detailIsWarning ? FontWeight.w600 : null,
          color: stage.detailIsWarning
              ? context.foColors.warning
              : context.foColors.fgMuted,
        ),
      );
}

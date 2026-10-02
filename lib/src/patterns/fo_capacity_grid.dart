import 'dart:ui' show PathMetric;

import 'package:flutter/material.dart';

import '../primitives/fo_status_chip.dart';
import '../theme/fo_context.dart';
import '../tokens/fo_layout.dart';
import '../tokens/fo_tokens.dart';

/// One container in a [FoCapacityGrid] — a carton, a bundle.
@immutable
class FoCapacityTile {
  /// Creates a tile.
  const FoCapacityTile({
    required this.label,
    required this.amount,
    required this.capacity,
    required this.amountLabel,
    this.statusLabel,
    this.caption,
    this.repeat = 1,
  });

  /// What is in it — "M", "Mixed". Caller-supplied.
  final String label;

  /// How many are in it.
  final int amount;

  /// How many it holds.
  final int capacity;

  /// "20 of 20". Formatted by the caller.
  final String amountLabel;

  /// "Full", "Filling".
  final String? statusLabel;

  /// What happens to it — "Closed, label ready", "Stays open".
  final String? caption;

  /// How many identical full ones this tile stands for — "3 × 20".
  final int repeat;

  /// Whether it is full.
  bool get full => amount >= capacity;
}

/// What a count will make: "2 full cartons and 3 part cartons", worked out
/// as the user counts.
///
/// A full container is drawn solid with a success chip; a part one has a
/// dashed edge and a neutral one, because it is not finished and will stay
/// open. The caller works out the containers (its packing rule) and writes
/// the summary; this draws them. [emptyText] stands in until there is
/// anything to show.
class FoCapacityGrid extends StatelessWidget {
  /// Creates a capacity grid.
  const FoCapacityGrid({
    required this.tiles,
    this.emptyText,
    this.minTileWidth = 150,
    super.key,
  });

  /// The containers.
  final List<FoCapacityTile> tiles;

  /// Shown when there are none — "Count some pieces and the cartons appear
  /// here."
  final String? emptyText;

  /// The narrowest a tile may be.
  final double minTileWidth;

  @override
  Widget build(BuildContext context) {
    if (tiles.isEmpty) {
      return Text(
        emptyText ?? '',
        style: context.foText.body.copyWith(color: context.foColors.fgMuted),
      );
    }
    final double gap = context.foSpacing.sm;
    return Semantics(
      liveRegion: true,
      container: true,
      explicitChildNodes: true,
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final int perRow =
              ((constraints.maxWidth + gap) / (minTileWidth + gap))
                  .floor()
                  .clamp(1, tiles.length);
          final double width =
              (constraints.maxWidth - gap * (perRow - 1)) / perRow;
          return Wrap(
            spacing: gap,
            runSpacing: gap,
            children: <Widget>[
              for (final FoCapacityTile t in tiles)
                SizedBox(width: width, child: _Tile(tile: t)),
            ],
          );
        },
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.tile});

  final FoCapacityTile tile;

  @override
  Widget build(BuildContext context) {
    final BorderRadius radius = BorderRadius.circular(context.foRadii.md);
    final bool full = tile.full;
    final double fraction =
        tile.capacity == 0 ? 0 : (tile.amount / tile.capacity).clamp(0.0, 1.0);

    final Widget content = Padding(
      padding: EdgeInsets.all(context.foSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: context.foSpacing.sm,
            runSpacing: context.foSpacing.xs,
            children: <Widget>[
              Text(
                tile.repeat > 1 ? '${tile.repeat} × ${tile.label}' : tile.label,
                style: context.foText.title,
              ),
              if (tile.statusLabel != null)
                FoStatusChip.tone(
                  label: tile.statusLabel!,
                  tone: full ? FoStatusTone.success : FoStatusTone.neutral,
                  icon: full ? Icons.check : null,
                ),
            ],
          ),
          SizedBox(height: context.foSpacing.xs),
          Text(
            tile.amountLabel,
            style: context.foText.numeric.copyWith(fontWeight: FontWeight.w600),
          ),
          SizedBox(height: context.foSpacing.xs),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: SizedBox(
              height: 6,
              child: Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  ColoredBox(color: context.foCharts.track),
                  FractionallySizedBox(
                    alignment: AlignmentDirectional.centerStart,
                    widthFactor: fraction,
                    child: ColoredBox(
                      color: full
                          ? context.foColors.primary
                          : context.foColors.edgeStrong,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (tile.caption != null) ...<Widget>[
            SizedBox(height: context.foSpacing.xs),
            Text(
              tile.caption!,
              style: context.foText.body.copyWith(
                fontSize: FoTokens.fontCaption,
                color: context.foColors.fgSubtle,
              ),
            ),
          ],
        ],
      ),
    );

    return MergeSemantics(
      child: full
          ? Container(
              decoration: BoxDecoration(
                color: context.foColors.surfaceRaised,
                borderRadius: radius,
              ),
              foregroundDecoration: BoxDecoration(
                borderRadius: radius,
                border: Border.all(color: context.foColors.edgeStrong),
              ),
              child: content,
            )
          : CustomPaint(
              // A part container has a dashed edge: open, not finished.
              foregroundPainter: _DashedBorder(
                color: context.foColors.edgeStrong,
                radius: context.foRadii.md,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: context.foColors.surfaceRaised,
                  borderRadius: radius,
                ),
                child: content,
              ),
            ),
    );
  }
}

class _DashedBorder extends CustomPainter {
  _DashedBorder({required this.color, required this.radius});

  final Color color;
  final double radius;

  static const double _dash = 5;
  static const double _gap = 4;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = FoLayout.hairlineWidth * 1.5;
    final Path outline = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Offset.zero & size,
          Radius.circular(radius),
        ),
      );
    for (final PathMetric metric in outline.computeMetrics()) {
      double d = 0;
      while (d < metric.length) {
        canvas.drawPath(metric.extractPath(d, d + _dash), paint);
        d += _dash + _gap;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorder old) =>
      old.color != color || old.radius != radius;
}

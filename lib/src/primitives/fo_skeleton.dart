import 'package:flutter/material.dart';

import '../theme/fo_context.dart';
import '../tokens/fo_motion.dart';
import '../tokens/fo_tokens.dart';

/// A loading placeholder shaped like the thing it stands in for.
///
/// Prefer this to a centred spinner: a skeleton holds the layout still, so
/// nothing jumps when the data lands. A spinner tells you to wait; a skeleton
/// tells you what you are waiting for.
///
/// It is filled with `surfaceSunken` — the hole in the ladder — because that
/// is what a skeleton is: a place where content will be. The pulse freezes at
/// a fixed midpoint when the platform asks for reduced motion, so it reads as
/// deliberate rather than stalled.
class FoSkeleton extends StatefulWidget {
  /// A single line of text.
  const FoSkeleton.line({this.width, double height = 14.0, super.key})
      : _height = height,
        _radius = null;

  /// A rectangular block: a chart, an image, a tile.
  const FoSkeleton.box({
    required double height,
    this.width,
    double? radius,
    super.key,
  })  : _height = height,
        _radius = radius;

  /// A card-sized block, using the card radius.
  const FoSkeleton.card({this.width, double height = 120.0, super.key})
      : _height = height,
        _radius = FoTokens.radiusCard;

  /// Width. Fills the available space when null.
  final double? width;

  final double _height;
  final double? _radius;

  @override
  State<FoSkeleton> createState() => _FoSkeletonState();
}

class _FoSkeletonState extends State<FoSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: FoMotion.pulse,
    lowerBound: FoTokens.skeletonPulseMin,
    upperBound: FoTokens.skeletonPulseMax,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
      _controller.value = FoTokens.skeletonPulseStill;
    } else if (!_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: Container(
        width: widget.width ?? double.infinity,
        height: widget._height,
        decoration: BoxDecoration(
          color: context.foColors.surfaceSunken,
          borderRadius: BorderRadius.circular(
            widget._radius ?? context.foRadii.sm,
          ),
        ),
      ),
    );
  }
}

/// A column of card skeletons standing in for a loading list.
///
/// **It fits the box it is given.** A skeleton is shown for the frame before
/// the rows arrive, often in whatever height is left under a header — and at
/// 200% text, a phone on its side or a zoomed browser window, that is less
/// than four 88dp cards. A fixed column of them overflowed and asserted there
/// on every loading screen of a consuming app. In a bounded height it now
/// shows as many whole rows as fit (at least one, shortened to the height if
/// even one does not fit); unbounded — inside a scroll view — it shows
/// [itemCount].
class FoSkeletonList extends StatelessWidget {
  /// Creates a list of skeletons.
  const FoSkeletonList({this.itemCount = 4, this.itemHeight = 88, super.key});

  /// How many placeholder rows, at most. Enough to fill the fold, not so many
  /// that the arriving list shrinks.
  final int itemCount;

  /// Each row's height.
  final double itemHeight;

  @override
  Widget build(BuildContext context) {
    final double gap = context.foSpacing.md;
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double available = constraints.maxHeight;
        int rows = itemCount;
        double height = itemHeight;
        if (available.isFinite) {
          // n rows take n * itemHeight + (n - 1) * gap.
          final int fit = ((available + gap) / (itemHeight + gap)).floor();
          rows = fit.clamp(1, itemCount < 1 ? 1 : itemCount);
          if (fit < 1) height = available;
        }
        if (itemCount < 1) return const SizedBox.shrink();

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            for (int i = 0; i < rows; i++) ...<Widget>[
              FoSkeleton.card(height: height),
              if (i < rows - 1) SizedBox(height: gap),
            ],
          ],
        );
      },
    );
  }
}

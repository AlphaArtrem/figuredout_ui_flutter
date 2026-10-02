import 'package:flutter/material.dart';

import '../primitives/fo_focus_ring.dart';
import '../theme/fo_context.dart';
import '../tokens/fo_tokens.dart';

/// One file in a [FoAttachmentGrid].
@immutable
class FoAttachment {
  /// Creates an attachment.
  const FoAttachment({
    required this.caption,
    required this.semanticLabel,
    this.thumbnail,
    this.onOpen,
  });

  /// Under the tile — "Roll R-09". Caller-supplied.
  final String caption;

  /// What opening it shows — "Open the photo of roll R-09, shade variation".
  final String semanticLabel;

  /// The picture, when it is one — the app's `Image`. Null draws a document
  /// tile.
  final Widget? thumbnail;

  /// Opens it.
  final VoidCallback? onOpen;
}

/// Photos and documents on a record — roll faults, the supplier's invoice —
/// as square tiles, with an "add" tile at the end.
///
/// The package draws the grid; the app supplies the pictures and decides
/// what "add" opens (the camera, the files). Every tile says what it is to a
/// screen reader, because a thumbnail is not a name.
class FoAttachmentGrid extends StatelessWidget {
  /// Creates an attachment grid.
  const FoAttachmentGrid({
    required this.items,
    this.onAdd,
    this.addLabel,
    this.columns = 4,
    super.key,
  }) : assert(
          onAdd == null || addLabel != null,
          'addLabel is required when onAdd is set.',
        );

  /// The files.
  final List<FoAttachment> items;

  /// Adds one. Null hides the add tile.
  final VoidCallback? onAdd;

  /// The add tile's word — "Take photo".
  final String? addLabel;

  /// Tiles per row.
  final int columns;

  @override
  Widget build(BuildContext context) {
    final List<Widget> tiles = <Widget>[
      for (final FoAttachment item in items)
        _Tile(
          caption: item.caption,
          semanticLabel: item.semanticLabel,
          onTap: item.onOpen,
          filled: item.thumbnail == null,
          child: item.thumbnail ??
              Icon(
                Icons.description_outlined,
                color: context.foColors.fgMuted,
              ),
        ),
      if (onAdd != null)
        _Tile(
          caption: addLabel!,
          semanticLabel: addLabel!,
          onTap: onAdd,
          add: true,
          child:
              Icon(Icons.add_a_photo_outlined, color: context.foColors.primary),
        ),
    ];
    final double gap = context.foSpacing.sm;
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double size =
            (constraints.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: <Widget>[
            for (final Widget tile in tiles) SizedBox(width: size, child: tile),
          ],
        );
      },
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.caption,
    required this.semanticLabel,
    required this.onTap,
    required this.child,
    this.filled = false,
    this.add = false,
  });

  final String caption;
  final String semanticLabel;
  final VoidCallback? onTap;
  final Widget child;
  final bool filled;
  final bool add;

  @override
  Widget build(BuildContext context) {
    final BorderRadius radius = BorderRadius.circular(context.foRadii.md);
    return Semantics(
      button: onTap != null,
      label: semanticLabel,
      onTap: onTap,
      excludeSemantics: true,
      child: FoFocusRing(
        borderRadius: radius,
        enabled: onTap != null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            AspectRatio(
              aspectRatio: 1,
              child: Material(
                color: add
                    ? context.foColors.surfaceRaised
                    : context.foColors.surfaceSunken,
                borderRadius: radius,
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: onTap,
                  child: Container(
                    alignment: Alignment.center,
                    foregroundDecoration: BoxDecoration(
                      borderRadius: radius,
                      border: Border.all(
                        color: add
                            ? context.foColors.edgeStrong
                            : context.foColors.edge,
                      ),
                    ),
                    child:
                        filled || add ? child : SizedBox.expand(child: child),
                  ),
                ),
              ),
            ),
            SizedBox(height: context.foSpacing.xs),
            Text(
              caption,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: context.foText.body.copyWith(
                fontSize: FoTokens.fontCaption,
                color:
                    add ? context.foColors.primary : context.foColors.fgMuted,
                fontWeight: add ? FontWeight.w600 : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

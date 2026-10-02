import 'package:flutter/material.dart';

import '../theme/fo_context.dart';
import '../tokens/fo_layout.dart';
import '../tokens/fo_tokens.dart';
import 'fo_focus_ring.dart';

/// Which ink an icon button is drawn in.
enum FoIconButtonTone {
  /// `fgMuted` — chrome: close, back, more.
  neutral,

  /// `primary` — an icon that leads somewhere worth going: the `?` beside a
  /// word that opens its guide.
  primary,
}

/// A button that is only a glyph: close, back, help, more.
///
/// Material's `IconButton` brings its own hover overlay and its own focus
/// highlight, which is a second focus vocabulary beside [FoFocusRing]. This
/// composes the ring instead, keeps the 48dp target however small the glyph
/// is, and **requires a name**: an icon nobody can read aloud is a control a
/// screen-reader user cannot find. The same words become the tooltip on a
/// pointer device, so the name is never something only one kind of user gets.
class FoIconButton extends StatelessWidget {
  /// Creates an icon button.
  const FoIconButton({
    required this.icon,
    required this.semanticLabel,
    required this.onPressed,
    this.tone = FoIconButtonTone.neutral,
    this.iconSize = FoTokens.iconMedium,
    super.key,
  });

  /// The glyph.
  final IconData icon;

  /// What pressing it does — "Close the panel", "What is pressing?". Also the
  /// tooltip. Caller-supplied, so it can be localized.
  final String semanticLabel;

  /// Tap handler. Null disables the button.
  final VoidCallback? onPressed;

  /// Which ink the glyph is drawn in.
  final FoIconButtonTone tone;

  /// The glyph's size. The target stays 48dp whatever this is.
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final BorderRadius radius = BorderRadius.circular(context.foRadii.md);
    final bool enabled = onPressed != null;
    final Color ink = switch (tone) {
      FoIconButtonTone.neutral => context.foColors.fgMuted,
      FoIconButtonTone.primary => context.foColors.primary,
    };

    return Semantics(
      button: true,
      enabled: enabled,
      label: semanticLabel,
      // Declared here as well as on the InkWell, because `excludeSemantics`
      // drops the InkWell's own — the lesson FoSegmentedControl's test taught.
      onTap: onPressed,
      excludeSemantics: true,
      child: Tooltip(
        message: semanticLabel,
        // The Semantics above already names it; a tooltip would say it twice.
        excludeFromSemantics: true,
        child: FoFocusRing(
          borderRadius: radius,
          enabled: enabled,
          child: Material(
            type: MaterialType.transparency,
            borderRadius: radius,
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onPressed,
              borderRadius: radius,
              hoverColor: ink.withValues(alpha: FoTokens.hoverOverlayOpacity),
              highlightColor: ink.withValues(
                alpha: FoTokens.pressedOverlayOpacity,
              ),
              child: SizedBox(
                width: FoLayout.minTouchTarget,
                height: FoLayout.minTouchTarget,
                child: Icon(
                  icon,
                  size: iconSize,
                  color: enabled
                      ? ink
                      : ink.withValues(alpha: FoTokens.disabledInkOpacity),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

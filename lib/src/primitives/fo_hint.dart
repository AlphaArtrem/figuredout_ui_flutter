import 'package:flutter/material.dart';

import '../patterns/fo_help_guide.dart';
import '../theme/fo_context.dart';
import '../tokens/fo_layout.dart';
import '../tokens/fo_motion.dart';
import '../tokens/fo_tokens.dart';
import 'fo_icon_button.dart';

/// A tappable "?" that explains a term in plain language.
///
/// Adaptive on purpose: a tooltip needs a pointer to hover, and on a shop-floor
/// tablet there is no pointer. So the expanded bands get a hover tooltip, and
/// the compact band routes the same words somewhere it can actually reach —
/// [onCompactTap], which the app wires to its toast.
///
/// The message is a plain string rather than a key into a registry: the
/// registry is the app's, not the design system's.
///
/// [FoHint.guide] is the stronger form, and the one to prefer for anything
/// longer than a phrase: the same `?`, opening a short guide
/// (`FoHelpGuide`) at **every** width — a drawer on a wide window, a sheet on
/// a phone — so no explanation lives only in a tooltip.
class FoHint extends StatelessWidget {
  /// Creates a hint dot.
  const FoHint({
    required this.message,
    required this.buttonLabel,
    this.onCompactTap,
    super.key,
  })  : _guideBody = null,
        _closeLabel = null;

  /// A `?` that opens a guide titled [guideTitle] at every width.
  ///
  /// [buttonLabel] names the button — "What is pressing?" — and is what a
  /// screen reader says; [closeLabel] names the guide's close button.
  const FoHint.guide({
    required this.buttonLabel,
    required String guideTitle,
    required Widget guideBody,
    required String closeLabel,
    super.key,
  })  : message = guideTitle,
        onCompactTap = null,
        _guideBody = guideBody,
        _closeLabel = closeLabel;

  /// The explanation, or the guide's title for [FoHint.guide].
  /// Caller-supplied, so it can be localized.
  final String message;

  /// What the button is, for a screen reader and for its own tooltip.
  final String buttonLabel;

  /// Where the message goes on a compact window, where a hover tooltip cannot
  /// be reached. Wire this to the app's toast. Without it the dot still
  /// announces itself but has nothing to show on a phone.
  final VoidCallback? onCompactTap;

  final Widget? _guideBody;
  final String? _closeLabel;

  @override
  Widget build(BuildContext context) {
    final Widget? guideBody = _guideBody;
    if (guideBody != null) {
      return FoIconButton(
        icon: Icons.help_outline,
        tone: FoIconButtonTone.primary,
        semanticLabel: buttonLabel,
        onPressed: () => FoHelpGuide.show(
          context,
          title: message,
          body: guideBody,
          closeLabel: _closeLabel!,
        ),
      );
    }

    final Widget button = SizedBox(
      width: FoLayout.minTouchTarget,
      height: FoLayout.minTouchTarget,
      child: IconButton(
        tooltip: buttonLabel,
        icon: Icon(
          Icons.help_outline,
          size: FoTokens.iconSmall,
          color: context.foColors.fgMuted,
        ),
        onPressed: onCompactTap,
      ),
    );

    if (!context.foWindowClass.isAtLeastMedium) return button;

    return Tooltip(
      message: message,
      waitDuration: FoMotion.normal,
      child: button,
    );
  }
}

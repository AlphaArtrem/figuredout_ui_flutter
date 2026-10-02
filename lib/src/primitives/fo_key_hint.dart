import 'package:flutter/material.dart';

import '../theme/fo_context.dart';

/// A key the reader can press — "Esc", "Enter", "Ctrl K", "↑ ↓".
///
/// Mono, hairlined, on no surface of its own: the web package's `Kbd`. One
/// per key or chord. It is a hint, never the only way to find an action — the
/// action it names is always a visible control as well — so it is shown only
/// on a wide window, where there is a keyboard to press it on; on a phone it
/// renders nothing.
class FoKeyHint extends StatelessWidget {
  /// Creates a key hint.
  const FoKeyHint(this.keys, {this.alwaysShow = false, super.key});

  /// The key or chord, as printed on the keycap. Caller-supplied.
  final String keys;

  /// Shows it on a phone too — for a page about keyboards.
  final bool alwaysShow;

  @override
  Widget build(BuildContext context) {
    if (!alwaysShow && !context.foWindowClass.isAtLeastMedium) {
      return const SizedBox.shrink();
    }
    final BorderRadius radius = BorderRadius.circular(context.foRadii.sm);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.foSpacing.sm - 2,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        borderRadius: radius,
        border: Border.all(color: context.foColors.edgeStrong),
      ),
      child: Text(
        keys,
        style: context.foText.caption.copyWith(
          letterSpacing: 0,
          color: context.foColors.fgSubtle,
        ),
      ),
    );
  }
}

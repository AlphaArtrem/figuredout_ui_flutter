import 'package:flutter/material.dart';

import '../theme/fo_context.dart';
import '../tokens/fo_tokens.dart';
import 'fo_focus_ring.dart';

/// A PIN typed on a big keypad: the floor's sign-in on a remembered phone.
///
/// A row of [length] dots over a 3 × 4 pad of 62-point keys — 1 to 9, then a
/// gap, 0 and delete. The PIN is the caller's state: [value] is what has been
/// typed so far and every press reports the next value through [onChanged].
/// When the last digit lands, [onCompleted] fires once with the whole PIN.
///
/// [errorText] is the wrong-PIN state: the dots turn danger, the sentence
/// under them says what happened and how many tries are left, and the next
/// key press starts again from empty rather than appending to a PIN that has
/// already been refused.
///
/// The dots are one node for a screen reader — "2 of 4 digits typed" — built
/// by [progressSemanticLabel]; the digits themselves are never announced.
class FoPinPad extends StatelessWidget {
  /// Creates a PIN pad.
  const FoPinPad({
    required this.value,
    required this.onChanged,
    required this.progressSemanticLabel,
    required this.deleteSemanticLabel,
    this.onCompleted,
    this.length = 4,
    this.errorText,
    super.key,
  }) : assert(length > 0, 'a PIN of no digits');

  /// The digits typed so far.
  final String value;

  /// Called with the PIN after each press.
  final ValueChanged<String> onChanged;

  /// Called once with the whole PIN when the last digit lands.
  final ValueChanged<String>? onCompleted;

  /// How many digits a PIN has.
  final int length;

  /// The wrong-PIN sentence — "That PIN is wrong. 4 tries left." Null when
  /// nothing is wrong.
  final String? errorText;

  /// "{typed} of {length} digits typed".
  final String Function(int typed, int length) progressSemanticLabel;

  /// The delete key's name — "Delete last digit".
  final String deleteSemanticLabel;

  /// A key's height.
  static const double keyHeight = 62;

  /// A dot's diameter.
  static const double _dotSize = 16;

  void _press(String digit) {
    // After a refusal the next press starts a fresh PIN.
    final String base = errorText != null ? '' : value;
    if (base.length >= length) return;
    final String next = base + digit;
    onChanged(next);
    if (next.length == length) onCompleted?.call(next);
  }

  void _delete() {
    if (errorText != null) {
      onChanged('');
      return;
    }
    if (value.isEmpty) return;
    onChanged(value.substring(0, value.length - 1));
  }

  @override
  Widget build(BuildContext context) {
    final bool error = errorText != null;
    final int typed = value.length.clamp(0, length);

    final Widget dots = Semantics(
      label: progressSemanticLabel(typed, length),
      liveRegion: true,
      excludeSemantics: true,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          for (int i = 0; i < length; i++) ...<Widget>[
            if (i > 0) SizedBox(width: context.foSpacing.lg),
            Center(
// A circle stays a circle under any constraints (see FoDisc).
              widthFactor: 1,
              heightFactor: 1,
              child: Container(
                width: _dotSize,
                height: _dotSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: error
                      ? context.foColors.danger
                      : i < typed
                          ? context.foColors.primary
                          : Colors.transparent,
                  border: i < typed || error
                      ? null
                      : Border.all(
                          color: context.foColors.edgeStrong, width: 2),
                ),
              ),
            ),
          ],
        ],
      ),
    );

    Widget key(String digit) => _Key(
          semanticLabel: digit,
          onTap: () => _press(digit),
          child: Text(
            digit,
            style: context.foText.numeric.copyWith(
              fontSize: 26,
              fontWeight: FontWeight.w500,
            ),
          ),
        );

    final List<Widget> keys = <Widget>[
      for (int d = 1; d <= 9; d++) key('$d'),
      const SizedBox.shrink(),
      key('0'),
      _Key(
        semanticLabel: deleteSemanticLabel,
        onTap: _delete,
        quiet: true,
        child: Icon(
          Icons.backspace_outlined,
          size: 26,
          color: context.foColors.fgMuted,
        ),
      ),
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        dots,
        if (error) ...<Widget>[
          SizedBox(height: context.foSpacing.md),
          Semantics(
            liveRegion: true,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(
                  Icons.error_outline,
                  size: FoTokens.iconSmall,
                  color: context.foColors.danger,
                ),
                SizedBox(width: context.foSpacing.xs),
                Flexible(
                  child: Text(
                    errorText!,
                    textAlign: TextAlign.center,
                    style: context.foText.label.copyWith(
                      color: context.foColors.danger,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        SizedBox(height: context.foSpacing.xl),
        for (int row = 0; row < 4; row++) ...<Widget>[
          if (row > 0) SizedBox(height: context.foSpacing.sm),
          Row(
            children: <Widget>[
              for (int col = 0; col < 3; col++) ...<Widget>[
                if (col > 0) SizedBox(width: context.foSpacing.sm),
                Expanded(child: keys[row * 3 + col]),
              ],
            ],
          ),
        ],
      ],
    );
  }
}

class _Key extends StatelessWidget {
  const _Key({
    required this.semanticLabel,
    required this.onTap,
    required this.child,
    this.quiet = false,
  });

  final String semanticLabel;
  final VoidCallback onTap;
  final Widget child;
  final bool quiet;

  @override
  Widget build(BuildContext context) {
    final BorderRadius radius = BorderRadius.circular(context.foRadii.card);
    return Semantics(
      button: true,
      label: semanticLabel,
      onTap: onTap,
      excludeSemantics: true,
      child: FoFocusRing(
        borderRadius: radius,
        child: Material(
          color: quiet ? Colors.transparent : context.foColors.surfaceRaised,
          borderRadius: radius,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Container(
              height: FoPinPad.keyHeight,
              alignment: Alignment.center,
              foregroundDecoration: quiet
                  ? null
                  : BoxDecoration(
                      borderRadius: radius,
                      border: Border.all(color: context.foColors.edge),
                    ),
              // Keys do not grow with the reader's text size: the pad is a
              // fixed-geometry instrument, and a 200% digit in a 62-point key
              // would overflow it.
              child: MediaQuery.withNoTextScaling(child: child),
            ),
          ),
        ),
      ),
    );
  }
}

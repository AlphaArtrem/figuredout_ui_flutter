import 'package:flutter/material.dart';

import '../theme/fo_context.dart';
import '../tokens/fo_layout.dart';
import '../tokens/fo_motion.dart';
import '../tokens/fo_tokens.dart';
import 'fo_focus_ring.dart';

/// A row that opens to show more: "If something goes wrong", "More details
/// (optional)", "How sending works".
///
/// For detail somebody may need and most people do not — never for the thing
/// a screen is for. The summary is a button with an expanded state, the
/// chevron turns as it opens, and the body lines up under the title, not
/// under the icon.
///
/// Uncontrolled by default ([initiallyExpanded]); pass [expanded] and
/// [onExpandedChanged] to drive it from outside — opening the step a help
/// link points at, say.
class FoDisclosure extends StatefulWidget {
  /// Creates a disclosure.
  const FoDisclosure({
    required this.title,
    required this.child,
    this.icon,
    this.iconColor,
    this.initiallyExpanded = false,
    this.expanded,
    this.onExpandedChanged,
    this.showDivider = true,
    super.key,
  });

  /// The summary — what opening it shows. Caller-supplied.
  final String title;

  /// What it shows when open.
  final Widget child;

  /// A leading mark — an alert for a problem, a book for more detail.
  final IconData? icon;

  /// The mark's ink. Defaults to `fgMuted`.
  final Color? iconColor;

  /// Whether it starts open, when uncontrolled.
  final bool initiallyExpanded;

  /// Drives it from outside. Null leaves it uncontrolled.
  final bool? expanded;

  /// Told when the user opens or closes it.
  final ValueChanged<bool>? onExpandedChanged;

  /// A hairline along the top — on in a stack of them, off on its own.
  final bool showDivider;

  @override
  State<FoDisclosure> createState() => _FoDisclosureState();
}

class _FoDisclosureState extends State<FoDisclosure> {
  late bool _open = widget.expanded ?? widget.initiallyExpanded;

  @override
  void didUpdateWidget(FoDisclosure oldWidget) {
    super.didUpdateWidget(oldWidget);
    final bool? controlled = widget.expanded;
    if (controlled != null && controlled != _open) _open = controlled;
  }

  void _toggle() {
    final bool next = !_open;
    if (widget.expanded == null) setState(() => _open = next);
    widget.onExpandedChanged?.call(next);
  }

  @override
  Widget build(BuildContext context) {
    final double indent =
        widget.icon == null ? 0 : FoTokens.iconSmall + context.foSpacing.sm;
    final BorderRadius radius = BorderRadius.circular(context.foRadii.sm);

    return DecoratedBox(
      decoration: BoxDecoration(
        border: widget.showDivider
            ? Border(top: BorderSide(color: context.foColors.edge))
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Semantics(
            button: true,
            expanded: _open,
            label: widget.title,
            onTap: _toggle,
            excludeSemantics: true,
            child: FoFocusRing(
              borderRadius: radius,
              child: Material(
                type: MaterialType.transparency,
                child: InkWell(
                  onTap: _toggle,
                  borderRadius: radius,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      minHeight: FoLayout.minTouchTarget + 4,
                    ),
                    child: Row(
                      children: <Widget>[
                        if (widget.icon != null) ...<Widget>[
                          Icon(
                            widget.icon,
                            size: FoTokens.iconSmall,
                            color: widget.iconColor ?? context.foColors.fgMuted,
                          ),
                          SizedBox(width: context.foSpacing.sm),
                        ],
                        Expanded(
                          child: Text(
                            widget.title,
                            style: context.foText.subtitle,
                          ),
                        ),
                        AnimatedRotation(
                          turns: _open ? 0.5 : 0,
                          duration: FoMotion.fast,
                          curve: FoMotion.standard,
                          child: Icon(
                            Icons.expand_more,
                            size: FoTokens.iconSmall,
                            color: context.foColors.fgSubtle,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (_open)
            Padding(
              padding: EdgeInsetsDirectional.only(
                start: indent,
                bottom: context.foSpacing.lg,
              ),
              child: DefaultTextStyle.merge(
                style: context.foText.body.copyWith(
                  color: context.foColors.fgMuted,
                ),
                child: widget.child,
              ),
            ),
        ],
      ),
    );
  }
}

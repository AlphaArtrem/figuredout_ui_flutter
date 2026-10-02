import 'package:flutter/material.dart';

import '../theme/fo_context.dart';

/// The bar pinned to the bottom of a screen that holds its one main action —
/// "Record pressing" above a phone list, "Next: check" under a flow's step.
///
/// **It never covers anything.** It is laid out *below* the scrolling content
/// — the last child of a `Column`, or `Scaffold.bottomNavigationBar` — never
/// floated over it in a `Stack` or as a floating action button. A floating
/// button covers the last card of a list and the pagination under it, which
/// is exactly where somebody is looking when they reach the end. Above a
/// shell's bottom menu it sits between the content and the menu.
///
/// It rests on `surface` with a hairline along its top edge, and pads itself
/// clear of the home indicator.
///
/// [leading] is optional context for the action — a running total, a status
/// chip. With no [leading] and one action, the action takes the full width,
/// which is where a thumb expects it. When the two stop fitting side by side
/// — at 200% text, or in a longer language — the actions drop onto their own
/// line rather than running off the edge.
class FoActionBar extends StatelessWidget {
  /// Creates an action bar.
  const FoActionBar({required this.actions, this.leading, super.key})
      : assert(actions.length > 0, 'an action bar with no action is a band');

  /// The actions, main one last. Usually one.
  final List<Widget> actions;

  /// Context for the action, at the start of the bar.
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final Widget content;
    if (leading == null && actions.length == 1) {
      content = SizedBox(width: double.infinity, child: actions.single);
    } else {
      // A tight width so spaceBetween has room to distribute — see the
      // components doc, "a Wrap in a Column shrink-wraps".
      content = SizedBox(
        width: double.infinity,
        child: Wrap(
          alignment:
              leading == null ? WrapAlignment.end : WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: context.foSpacing.md,
          runSpacing: context.foSpacing.sm,
          children: <Widget>[
            if (leading != null) leading!,
            Wrap(
              spacing: context.foSpacing.sm,
              runSpacing: context.foSpacing.sm,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: actions,
            ),
          ],
        ),
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.foColors.surface,
        border: Border(top: BorderSide(color: context.foColors.edge)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: context.foSpacing.lg,
            vertical: context.foSpacing.sm,
          ),
          child: content,
        ),
      ),
    );
  }
}

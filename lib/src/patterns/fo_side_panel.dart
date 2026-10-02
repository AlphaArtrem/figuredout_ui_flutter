import 'package:flutter/material.dart';

import '../primitives/fo_icon_button.dart';
import '../theme/fo_context.dart';
import '../theme/fo_window_class.dart';
import '../tokens/fo_layout.dart';

/// One record, opened beside the list it was picked from.
///
/// A header — an [eyebrow] naming the kind of record, the [title], an optional
/// [status] chip, and a close button — over a body that scrolls on its own and
/// an optional [footer] that does not. It is the content of
/// [FoListDetailLayout]'s side column on a wide window, and of the page that
/// is pushed in its place on a narrow one, so a record reads the same way at
/// every width.
///
/// It sits on `surfaceRaised` with the resting shadow: an open record has been
/// picked up off the list, which is what the top of the ladder is for.
class FoSidePanel extends StatelessWidget {
  /// Creates a side panel.
  const FoSidePanel({
    required this.title,
    required this.child,
    this.eyebrow,
    this.status,
    this.onClose,
    this.closeSemanticLabel,
    this.footer,
    this.titleIsCode = false,
    super.key,
  }) : assert(
          onClose == null || closeSemanticLabel != null,
          'closeSemanticLabel is required when onClose is set.',
        );

  /// The record's name — "PRS-00416". Caller-supplied.
  final String title;

  /// A mono uppercase caption naming the kind of record — "Pressing entry".
  final String? eyebrow;

  /// The record's state — a `FoStatusChip`, under the title.
  final Widget? status;

  /// Closes the panel. Null hides the button: a pushed page closes with its
  /// own back button.
  final VoidCallback? onClose;

  /// The close button's name — "Close the panel".
  final String? closeSemanticLabel;

  /// The panel's content. Scrolls inside the panel when the panel has a
  /// bounded height.
  final Widget child;

  /// Actions that stay put while the body scrolls.
  final Widget? footer;

  /// Sets the title in mono: a record *code* is a value, and mono is what
  /// values are set in (rule 3).
  final bool titleIsCode;

  @override
  Widget build(BuildContext context) {
    final BorderRadius radius = BorderRadius.circular(context.foRadii.card);
    final TextStyle titleStyle = titleIsCode
        ? context.foText.numeric.copyWith(
            fontSize: context.foText.title.fontSize,
            fontWeight: FontWeight.w600,
          )
        : context.foText.title;

    final Widget header = Padding(
      padding: EdgeInsets.fromLTRB(
        context.foSpacing.lg,
        context.foSpacing.lg,
        context.foSpacing.sm,
        context.foSpacing.md,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                if (eyebrow != null) ...<Widget>[
                  Text(eyebrow!.toUpperCase(), style: context.foText.caption),
                  SizedBox(height: context.foSpacing.xs),
                ],
                Semantics(
                  header: true,
                  child: Text(title, style: titleStyle),
                ),
                if (status != null) ...<Widget>[
                  SizedBox(height: context.foSpacing.sm),
                  status!,
                ],
              ],
            ),
          ),
          if (onClose != null)
            FoIconButton(
              icon: Icons.close,
              semanticLabel: closeSemanticLabel!,
              onPressed: onClose,
            ),
        ],
      ),
    );

    final Widget body = Padding(
      padding: EdgeInsets.fromLTRB(
        context.foSpacing.lg,
        0,
        context.foSpacing.lg,
        context.foSpacing.lg,
      ),
      child: child,
    );

    final Widget? bar = footer == null
        ? null
        : DecoratedBox(
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: context.foColors.edge)),
            ),
            child: Padding(
              padding: EdgeInsets.all(context.foSpacing.lg),
              child: footer,
            ),
          );

    return Semantics(
      container: true,
      explicitChildNodes: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: context.foColors.surfaceRaised,
          borderRadius: radius,
          boxShadow: context.foShadows.raised,
        ),
        // Rule 1: the footer paints a band of its own, so the hairline goes on
        // top of everything rather than under it.
        child: DecoratedBox(
          position: DecorationPosition.foreground,
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(color: context.foColors.edge),
          ),
          child: ClipRRect(
            borderRadius: radius,
            child: Material(
              type: MaterialType.transparency,
              child: LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  // Bounded: the body scrolls and the header and footer stay.
                  // Unbounded — a panel inside a page that scrolls as a whole —
                  // everything simply stacks; a scroll view here would assert.
                  if (!constraints.hasBoundedHeight) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[header, body, if (bar != null) bar],
                    );
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      header,
                      Expanded(child: SingleChildScrollView(child: body)),
                      if (bar != null) bar,
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A list with the record it opened beside it — on a wide window.
///
/// **One decision, made once:** on an expanded window (900 and up) a record
/// opens in a side column next to the list, so the user keeps their place; on
/// anything narrower it opens as a page of its own with a back button, because
/// a list squeezed beside a panel on a tablet is two things too narrow to
/// read. [open] makes that choice for the caller, so no screen re-derives it.
///
/// The selection is the app's state, not this widget's: pass [detail] when a
/// record is open in the panel and null when none is.
class FoListDetailLayout extends StatelessWidget {
  /// Creates a list-detail layout.
  const FoListDetailLayout({required this.list, this.detail, super.key});

  /// The list — tabs, search, table, pagination.
  final Widget list;

  /// The open record, usually a [FoSidePanel]. Shown only where
  /// [showsSidePanel] is true; ignored elsewhere.
  final Widget? detail;

  /// The side column's width.
  static const double panelWidth = 420;

  /// True where a record opens beside the list rather than as its own page.
  static bool showsSidePanel(BuildContext context) =>
      context.foWindowClass == FoWindowClass.expanded;

  /// Opens a record the right way for this width: [showInPanel] on a wide
  /// window, which should set the app's selection so [detail] appears; a
  /// pushed page built by [pageBuilder] everywhere else.
  static Future<void> open(
    BuildContext context, {
    required VoidCallback showInPanel,
    required WidgetBuilder pageBuilder,
  }) async {
    if (showsSidePanel(context)) {
      showInPanel();
      return;
    }
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: pageBuilder),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Widget? panel = detail;
    if (panel == null || !showsSidePanel(context)) return list;

    // **The list and the panel are the same height.** In a page with a
    // bounded height both stretch to fill it, so the list card never stops
    // halfway down beside a tall panel; give the list a `FoListCard` and its
    // pagination sits at the bottom. In a page that scrolls as a whole there
    // is no height to fill, and the two top-align instead.
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) => Row(
        crossAxisAlignment: constraints.hasBoundedHeight
            ? CrossAxisAlignment.stretch
            : CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(child: list),
          SizedBox(width: context.foSpacing.lg),
          SizedBox(width: panelWidth, child: panel),
        ],
      ),
    );
  }
}

/// A list's card: its header (tabs, toolbar), the rows, and its pagination
/// pinned to the bottom.
///
/// Given a bounded height — beside a [FoSidePanel] in a [FoListDetailLayout],
/// or filling a page — the rows take every point between the header and the
/// footer and scroll inside it, so the pagination bar is always at the foot
/// of the card rather than wherever the last row happened to end. In a page
/// that scrolls as a whole it simply stacks.
class FoListCard extends StatelessWidget {
  /// Creates a list card.
  const FoListCard({
    required this.body,
    this.header,
    this.footer,
    super.key,
  });

  /// Tabs and the toolbar.
  final Widget? header;

  /// The rows — a table, or a list of cards. Scrolls when the card is
  /// bounded; give it a scroll view of its own if it is long.
  final Widget body;

  /// The pagination bar.
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final BorderRadius radius = BorderRadius.circular(context.foRadii.card);
    Widget rule() => Divider(
          height: FoLayout.hairlineWidth,
          thickness: FoLayout.hairlineWidth,
          color: context.foColors.edge,
        );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.foColors.surface,
        borderRadius: radius,
        boxShadow: context.foShadows.raised,
      ),
      child: DecoratedBox(
        position: DecorationPosition.foreground,
        decoration: BoxDecoration(
          borderRadius: radius,
          border: Border.all(color: context.foColors.edge),
        ),
        child: ClipRRect(
          borderRadius: radius,
          child: Material(
            type: MaterialType.transparency,
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final bool bounded = constraints.hasBoundedHeight;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: bounded ? MainAxisSize.max : MainAxisSize.min,
                  children: <Widget>[
                    if (header != null) ...<Widget>[
                      Padding(
                        padding: EdgeInsets.all(context.foSpacing.lg),
                        child: header,
                      ),
                      rule(),
                    ],
                    if (bounded) Expanded(child: body) else body,
                    if (footer != null) ...<Widget>[rule(), footer!],
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

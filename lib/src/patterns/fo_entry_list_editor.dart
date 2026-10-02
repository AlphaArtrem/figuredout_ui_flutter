import 'package:flutter/material.dart';

import '../primitives/fo_button.dart';
import '../primitives/fo_icon_button.dart';
import '../theme/fo_context.dart';
import '../tokens/fo_layout.dart';
import '../tokens/fo_tokens.dart';

/// One column of a [FoEntryListEditor].
@immutable
class FoEntryColumn {
  /// Creates a column.
  const FoEntryColumn({
    required this.label,
    this.helper,
    this.flex = 1,
    this.numeric = false,
  });

  /// "Weight". Caller-supplied.
  final String label;

  /// "As weighed here" — what goes in it.
  final String? helper;

  /// Its share of the width on a wide window.
  final int flex;

  /// Right-aligns it, for figures.
  final bool numeric;
}

/// A list typed in one line at a time — rolls of fabric, bundles, cartons —
/// with an entry row that is always ready for the next one.
///
/// The entry row is last and never moves: type, press Enter (or [addLabel]),
/// and the row joins the list and the entry row clears for the next — the
/// caller's fields call [onAdd] on submit. [onRepeatLast] fills the entry row
/// from the previous line ("Repeat last, 28.4 kg"), because rolls from one
/// delivery are mostly alike. Every added line can be removed, and
/// [totalCells] sum the columns live.
///
/// The cells are the caller's widgets — a weight field, a fault picker, a
/// computed figure — so the editor owns the frame, the order, the add and
/// remove, and the totals row, not what a line is. On a wide window it is a
/// table; on a phone each line is a card of label–value pairs with the entry
/// row on top.
class FoEntryListEditor extends StatelessWidget {
  /// Creates an entry-list editor.
  const FoEntryListEditor({
    required this.columns,
    required this.lineCount,
    required this.lineCells,
    required this.entryCells,
    required this.onAdd,
    required this.addLabel,
    required this.removeLabel,
    required this.onRemove,
    this.onRepeatLast,
    this.repeatLastLabel,
    this.totalLabel,
    this.totalCells,
    this.message,
    this.highlightedLines = const <int>{},
    super.key,
  }) : assert(
          onRepeatLast == null || repeatLastLabel != null,
          'repeatLastLabel is required when onRepeatLast is set.',
        );

  /// The columns, in order.
  final List<FoEntryColumn> columns;

  /// How many lines there are.
  final int lineCount;

  /// The cells of line `index`, one per column.
  final List<Widget> Function(int index) lineCells;

  /// The entry row's fields, one per column.
  final List<Widget> entryCells;

  /// Adds what is in the entry row.
  final VoidCallback? onAdd;

  /// "Add roll".
  final String addLabel;

  /// Fills the entry row from the last line.
  final VoidCallback? onRepeatLast;

  /// "Repeat last, 28.4 kg".
  final String? repeatLastLabel;

  /// "Remove roll R-05".
  final String Function(int index) removeLabel;

  /// Removes line `index`.
  final ValueChanged<int> onRemove;

  /// "Total, 14 rolls".
  final String? totalLabel;

  /// The totals, one per column (an empty `SizedBox` where nothing sums).
  final List<Widget>? totalCells;

  /// What just happened — "Added R-14." — read aloud as it changes.
  final String? message;

  /// Lines to tint — a roll with a fault.
  final Set<int> highlightedLines;

  @override
  Widget build(BuildContext context) =>
      context.foWindowClass.isAtLeastMedium ? _table(context) : _cards(context);

  Widget _row(
    BuildContext context,
    List<Widget> cells, {
    Widget? leading,
    Widget? trailing,
    Color? fill,
    bool topRule = true,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: fill,
        border: topRule
            ? Border(top: BorderSide(color: context.foColors.edge))
            : null,
      ),
      constraints: const BoxConstraints(minHeight: FoLayout.minTouchTarget),
      padding: EdgeInsets.symmetric(
        horizontal: context.foSpacing.sm,
        vertical: context.foSpacing.xs,
      ),
      child: Row(
        children: <Widget>[
          SizedBox(width: 32, child: leading),
          for (int c = 0; c < columns.length; c++)
            Expanded(
              flex: columns[c].flex,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: context.foSpacing.xs),
                child: Align(
                  alignment: columns[c].numeric
                      ? AlignmentDirectional.centerEnd
                      : AlignmentDirectional.centerStart,
                  child: c < cells.length ? cells[c] : const SizedBox.shrink(),
                ),
              ),
            ),
          SizedBox(width: FoLayout.minTouchTarget, child: trailing),
        ],
      ),
    );
  }

  Widget _index(BuildContext context, int i, {bool entry = false}) => Text(
        '${i + 1}',
        style: context.foText.numeric.copyWith(
          fontSize: FoTokens.fontLabel,
          color: entry ? context.foColors.primary : context.foColors.fgSubtle,
          fontWeight: entry ? FontWeight.w600 : null,
        ),
      );

  Widget _actions(BuildContext context) => Wrap(
        spacing: context.foSpacing.sm,
        runSpacing: context.foSpacing.sm,
        children: <Widget>[
          if (onRepeatLast != null && lineCount > 0)
            FoButton(
              label: repeatLastLabel!,
              variant: FoButtonVariant.secondary,
              icon: Icons.replay,
              onPressed: onRepeatLast,
            ),
          FoButton(
            label: addLabel,
            variant: FoButtonVariant.primary,
            icon: Icons.add,
            onPressed: onAdd,
          ),
        ],
      );

  Widget _message(BuildContext context) => message == null
      ? const SizedBox.shrink()
      : Semantics(
          liveRegion: true,
          child: Padding(
            padding: EdgeInsets.only(top: context.foSpacing.sm),
            child: Text(
              message!,
              style: context.foText.body.copyWith(
                fontSize: FoTokens.fontLabel,
                color: context.foColors.fgMuted,
              ),
            ),
          ),
        );

  Widget _table(BuildContext context) {
    final BorderRadius radius = BorderRadius.circular(context.foRadii.md);
    final Widget header = Container(
      color: context.foColors.surfaceSunken,
      padding: EdgeInsets.symmetric(
        horizontal: context.foSpacing.sm,
        vertical: context.foSpacing.sm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          const SizedBox(width: 32),
          for (final FoEntryColumn c in columns)
            Expanded(
              flex: c.flex,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: context.foSpacing.xs),
                child: Column(
                  crossAxisAlignment: c.numeric
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(c.label.toUpperCase(), style: context.foText.caption),
                    if (c.helper != null)
                      Text(
                        c.helper!,
                        style: context.foText.body.copyWith(
                          fontSize: FoTokens.fontCaption,
                          color: context.foColors.fgSubtle,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          const SizedBox(width: FoLayout.minTouchTarget),
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        ClipRRect(
          borderRadius: radius,
          child: DecoratedBox(
            position: DecorationPosition.foreground,
            decoration: BoxDecoration(
              borderRadius: radius,
              border: Border.all(color: context.foColors.edge),
            ),
            child: Material(
              color: context.foColors.surfaceRaised,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  header,
                  for (int i = 0; i < lineCount; i++)
                    _row(
                      context,
                      lineCells(i),
                      leading: _index(context, i),
                      fill: highlightedLines.contains(i)
                          ? context.foColors.warningSoft
                          : null,
                      trailing: FoIconButton(
                        icon: Icons.close,
                        iconSize: FoTokens.iconSmall,
                        semanticLabel: removeLabel(i),
                        onPressed: () => onRemove(i),
                      ),
                    ),
                  // The entry row: always last, always ready.
                  Container(
                    decoration: BoxDecoration(
                      color: context.foColors.primarySoft,
                      border: Border(
                        top: BorderSide(
                          color: context.foColors.primary,
                          width: 2,
                        ),
                      ),
                    ),
                    child: _row(
                      context,
                      entryCells,
                      leading: _index(context, lineCount, entry: true),
                      topRule: false,
                    ),
                  ),
                  if (totalLabel != null && totalCells != null)
                    Container(
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(
                            color: context.foColors.edgeStrong,
                            width: 2,
                          ),
                        ),
                      ),
                      padding: EdgeInsets.all(context.foSpacing.sm),
                      child: Row(
                        children: <Widget>[
                          Flexible(
                            child: Text(
                              totalLabel!,
                              style: context.foText.label,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (totalLabel != null && totalCells != null)
                    _row(context, totalCells!, topRule: false),
                ],
              ),
            ),
          ),
        ),
        SizedBox(height: context.foSpacing.md),
        _actions(context),
        _message(context),
      ],
    );
  }

  Widget _cards(BuildContext context) {
    final BorderRadius radius = BorderRadius.circular(context.foRadii.md);
    Widget pairs(List<Widget> cells) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            for (int c = 0; c < columns.length && c < cells.length; c++)
              Padding(
                padding: EdgeInsets.symmetric(vertical: context.foSpacing.xs),
                child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: context.foSpacing.md,
                  runSpacing: context.foSpacing.xs,
                  children: <Widget>[
                    Text(
                      columns[c].label,
                      style: context.foText.body.copyWith(
                        color: context.foColors.fgMuted,
                      ),
                    ),
                    cells[c],
                  ],
                ),
              ),
          ],
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          padding: EdgeInsets.all(context.foSpacing.md),
          decoration: BoxDecoration(
            color: context.foColors.surfaceRaised,
            borderRadius: radius,
          ),
          foregroundDecoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(color: context.foColors.primary, width: 2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              pairs(entryCells),
              SizedBox(height: context.foSpacing.sm),
              _actions(context),
              _message(context),
            ],
          ),
        ),
        // Newest first on a phone: the line just added is the one to check.
        for (int i = lineCount - 1; i >= 0; i--) ...<Widget>[
          SizedBox(height: context.foSpacing.sm),
          Container(
            padding: EdgeInsets.fromLTRB(
              context.foSpacing.md,
              context.foSpacing.xs,
              context.foSpacing.xs,
              context.foSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: highlightedLines.contains(i)
                  ? context.foColors.warningSoft
                  : context.foColors.surfaceRaised,
              borderRadius: radius,
            ),
            foregroundDecoration: BoxDecoration(
              borderRadius: radius,
              border: Border.all(color: context.foColors.edge),
            ),
            child: Row(
              children: <Widget>[
                _index(context, i),
                SizedBox(width: context.foSpacing.md),
                Expanded(child: pairs(lineCells(i))),
                FoIconButton(
                  icon: Icons.close,
                  iconSize: FoTokens.iconSmall,
                  semanticLabel: removeLabel(i),
                  onPressed: () => onRemove(i),
                ),
              ],
            ),
          ),
        ],
        if (totalLabel != null && totalCells != null) ...<Widget>[
          SizedBox(height: context.foSpacing.md),
          Text(totalLabel!, style: context.foText.label),
          pairs(totalCells!),
        ],
      ],
    );
  }
}

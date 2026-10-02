import 'package:flutter/material.dart';

import '../theme/fo_context.dart';
import '../tokens/fo_layout.dart';
import '../tokens/fo_tokens.dart';

/// One key's before and after — a size, a colour-size pair, a field.
@immutable
class FoChange {
  /// Creates a change.
  const FoChange(
      {required this.key, required this.before, required this.after});

  /// What changed — "L", "Sage M". Caller-supplied.
  final String key;

  /// The value now.
  final int before;

  /// The value after the change.
  final int after;

  /// After minus before.
  int get delta => after - before;

  /// Whether anything changed.
  bool get changed => before != after;
}

/// How a [FoChangeDiff] is drawn.
enum FoChangeDiffLayout {
  /// Rows Now / After / Change over a column per key, with a total — a side
  /// panel on a wide window.
  table,

  /// One tile per key, the small figure now and the big one after — a phone.
  tiles,

  /// One line per *changed* key, "160 → 200   +40" — an edit summary.
  list,
}

/// The words a [FoChangeDiff] needs.
@immutable
class FoChangeDiffCopy {
  /// Creates the copy.
  const FoChangeDiffCopy({
    required this.beforeLabel,
    required this.afterLabel,
    this.changeLabel,
    this.totalLabel,
    this.measureLabel,
  });

  /// "Now".
  final String beforeLabel;

  /// "After", "Asked for".
  final String afterLabel;

  /// "Change". Null hides the change row in the table.
  final String? changeLabel;

  /// "Total". Null hides the total.
  final String? totalLabel;

  /// What is being counted — "Pressed" — over the table's first column.
  final String? measureLabel;
}

/// A change to a set of figures, before and after: an approval asking for L
/// to go from 30 to 18, an order edit moving Sage M from 160 to 200.
///
/// **Only what changed is loud.** Changed figures carry the warning wash and
/// the semibold weight; the rest stay quiet, so an owner deciding on a
/// 96-to-84 change sees the one size that moved rather than reading five.
/// A decrease reads with a real minus sign, never a hyphen.
///
/// Three layouts of the same data — see [FoChangeDiffLayout].
class FoChangeDiff extends StatelessWidget {
  /// Creates a change diff.
  const FoChangeDiff({
    required this.changes,
    required this.copy,
    this.layout = FoChangeDiffLayout.table,
    this.numberFormatter,
    this.semanticLabel,
    super.key,
  });

  /// One per key, in order.
  final List<FoChange> changes;

  /// The words.
  final FoChangeDiffCopy copy;

  /// How it is drawn.
  final FoChangeDiffLayout layout;

  /// Formats a figure. Defaults to plain digits.
  final String Function(int value)? numberFormatter;

  /// What the diff is about — "Before and after, by size".
  final String? semanticLabel;

  String _fmt(int v) => (numberFormatter ?? (int n) => '$n')(v);

  /// "+40", "−12", or "—" for no change.
  String _delta(int d) => d == 0
      ? '—'
      : d > 0
          ? '+${_fmt(d)}'
          : '−${_fmt(-d)}';

  @override
  Widget build(BuildContext context) {
    final Widget body = switch (layout) {
      FoChangeDiffLayout.table => _table(context),
      FoChangeDiffLayout.tiles => _tiles(context),
      FoChangeDiffLayout.list => _list(context),
    };
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: semanticLabel,
      child: body,
    );
  }

  TextStyle _figure(BuildContext context, {bool loud = false}) =>
      context.foText.numeric.copyWith(
        fontWeight: loud ? FontWeight.w700 : FontWeight.w500,
        color: loud ? context.foColors.warning : null,
      );

  Widget _table(BuildContext context) {
    final int beforeTotal =
        changes.fold<int>(0, (int s, FoChange c) => s + c.before);
    final int afterTotal =
        changes.fold<int>(0, (int s, FoChange c) => s + c.after);
    final bool total = copy.totalLabel != null;
    final BorderRadius radius = BorderRadius.circular(context.foRadii.md);

    Widget cell(Widget child, {Color? fill, bool start = false}) => Container(
          color: fill,
          padding: EdgeInsets.symmetric(
            horizontal: context.foSpacing.sm,
            vertical: context.foSpacing.sm,
          ),
          alignment: start
              ? AlignmentDirectional.centerStart
              : AlignmentDirectional.centerEnd,
          child: child,
        );

    TableRow row(
      String label,
      List<Widget> values, {
      bool header = false,
      List<Color?>? fills,
    }) =>
        TableRow(
          decoration: BoxDecoration(
            color: header ? context.foColors.surfaceSunken : null,
            border: header
                ? null
                : Border(top: BorderSide(color: context.foColors.edge)),
          ),
          children: <Widget>[
            cell(
              Text(
                header ? label.toUpperCase() : label,
                style: header ? context.foText.caption : context.foText.label,
              ),
              start: true,
            ),
            for (int i = 0; i < values.length; i++)
              cell(values[i], fill: fills?[i]),
          ],
        );

    final List<Color?> afterFills = <Color?>[
      for (final FoChange c in changes)
        c.changed ? context.foColors.warningSoft : null,
      if (total)
        afterTotal != beforeTotal ? context.foColors.warningSoft : null,
    ];

    return ClipRRect(
      borderRadius: radius,
      child: DecoratedBox(
        position: DecorationPosition.foreground,
        decoration: BoxDecoration(
          borderRadius: radius,
          border: Border.all(color: context.foColors.edge),
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Table(
            defaultColumnWidth: const IntrinsicColumnWidth(),
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            children: <TableRow>[
              row(
                copy.measureLabel ?? '',
                <Widget>[
                  for (final FoChange c in changes)
                    Text(c.key.toUpperCase(), style: context.foText.caption),
                  if (total)
                    Text(
                      copy.totalLabel!.toUpperCase(),
                      style: context.foText.caption,
                    ),
                ],
                header: true,
              ),
              row(copy.beforeLabel, <Widget>[
                for (final FoChange c in changes)
                  Text(_fmt(c.before), style: _figure(context)),
                if (total) Text(_fmt(beforeTotal), style: _figure(context)),
              ]),
              row(
                copy.afterLabel,
                <Widget>[
                  for (final FoChange c in changes)
                    Text(
                      _fmt(c.after),
                      style: c.changed
                          ? _figure(context, loud: true)
                          : _figure(context).copyWith(
                              color: context.foColors.fgSubtle,
                            ),
                    ),
                  if (total)
                    Text(
                      _fmt(afterTotal),
                      style: _figure(context, loud: afterTotal != beforeTotal),
                    ),
                ],
                fills: afterFills,
              ),
              if (copy.changeLabel != null)
                row(copy.changeLabel!, <Widget>[
                  for (final FoChange c in changes)
                    Text(_delta(c.delta), style: _figure(context)),
                  if (total)
                    Text(
                      _delta(afterTotal - beforeTotal),
                      style: _figure(context),
                    ),
                ]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tiles(BuildContext context) {
    final BorderRadius radius = BorderRadius.circular(context.foRadii.md);
    final double gap = context.foSpacing.xs + 2;
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final int perRow =
            ((constraints.maxWidth + gap) / (56 + gap)).floor().clamp(
                  1,
                  changes.length,
                );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            for (int start = 0;
                start < changes.length;
                start += perRow) ...<Widget>[
              if (start > 0) SizedBox(height: gap),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    for (int i = start; i < start + perRow; i++) ...<Widget>[
                      if (i > start) SizedBox(width: gap),
                      Expanded(
                        child: i >= changes.length
                            ? const SizedBox.shrink()
                            : Semantics(
                                container: true,
                                label: '${changes[i].key}: '
                                    '${copy.beforeLabel} '
                                    '${_fmt(changes[i].before)}, '
                                    '${copy.afterLabel} '
                                    '${_fmt(changes[i].after)}',
                                excludeSemantics: true,
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    vertical: context.foSpacing.sm,
                                  ),
                                  decoration: BoxDecoration(
                                    color: changes[i].changed
                                        ? context.foColors.warningSoft
                                        : context.foColors.surfaceRaised,
                                    borderRadius: radius,
                                  ),
                                  foregroundDecoration: BoxDecoration(
                                    borderRadius: radius,
                                    border: Border.all(
                                      color: changes[i].changed
                                          ? context.foColors.warning
                                          : context.foColors.edge,
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: <Widget>[
                                      Text(
                                        changes[i].key.toUpperCase(),
                                        style: context.foText.caption,
                                      ),
                                      Text(
                                        _fmt(changes[i].before),
                                        style: context.foText.numeric.copyWith(
                                          fontSize: FoTokens.fontCaption,
                                          color: context.foColors.fgSubtle,
                                        ),
                                      ),
                                      Text(
                                        _fmt(changes[i].after),
                                        style: context.foText.numeric.copyWith(
                                          fontSize: FoTokens.fontSubtitle + 1,
                                          fontWeight: FontWeight.w700,
                                          color: changes[i].changed
                                              ? context.foColors.warning
                                              : null,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _list(BuildContext context) {
    final List<FoChange> moved =
        changes.where((FoChange c) => c.changed).toList();
    final int delta = moved.fold<int>(0, (int s, FoChange c) => s + c.delta);
    Widget line(String label, String fromTo, String change,
            {bool bold = false}) =>
        MergeSemantics(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: context.foSpacing.xs),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    label,
                    style: bold ? context.foText.label : context.foText.body,
                  ),
                ),
                Text(fromTo, style: context.foText.numeric),
                SizedBox(width: context.foSpacing.md),
                SizedBox(
                  width: 56,
                  child: Text(
                    change,
                    textAlign: TextAlign.end,
                    style: context.foText.numeric.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (final FoChange c in moved)
          line(
            c.key,
            '${_fmt(c.before)} → ${_fmt(c.after)}',
            _delta(c.delta),
          ),
        if (copy.totalLabel != null && moved.isNotEmpty) ...<Widget>[
          Divider(
            height: context.foSpacing.md,
            thickness: FoLayout.hairlineWidth,
            color: context.foColors.edge,
          ),
          line(copy.totalLabel!, '', _delta(delta), bold: true),
        ],
      ],
    );
  }
}

import 'package:flutter/material.dart';

import '../primitives/fo_button.dart';
import '../primitives/fo_number_field.dart';
import '../theme/fo_context.dart';
import '../tokens/fo_layout.dart';
import '../tokens/fo_tokens.dart';

/// One size's count: the size, how many are ready for it, and how many the
/// user has counted.
@immutable
class FoSizeCount {
  /// Creates a size count.
  const FoSizeCount({required this.size, required this.value, this.ready});

  /// The size's name — "M", "32". Caller-supplied.
  final String size;

  /// How many the user has counted.
  final int value;

  /// How many are ready at this stage — computed from the stage before. Null
  /// where nothing comes before (the first stage), which hides "Ready" and
  /// the over-limit check for this size.
  final int? ready;

  /// How far [value] is over [ready]; zero when it is not, or when [ready] is
  /// unknown.
  int get over {
    final int? limit = ready;
    if (limit == null || value <= limit) return 0;
    return value - limit;
  }
}

/// A secondary count beside the main one — "Re-press", "Damaged".
@immutable
class FoSizeCountColumn {
  /// Creates a secondary count column.
  const FoSizeCountColumn({
    required this.label,
    required this.values,
    required this.onChanged,
    required this.inputSemanticLabel,
    this.helper,
  });

  /// The column's name — "Re-press". Caller-supplied.
  final String label;

  /// A short line saying what goes in it — "Need another pass".
  final String? helper;

  /// One value per size, in the grid's size order.
  final List<int> values;

  /// Called with a size's index and its new value.
  final void Function(int index, int value) onChanged;

  /// The box's name for one size — "Re-press, size M".
  final String Function(String size) inputSemanticLabel;
}

/// The words a [FoSizeCountGrid] needs. The package holds no copy.
@immutable
class FoSizeCountCopy {
  /// Creates the grid's copy.
  const FoSizeCountCopy({
    required this.sizeLabel,
    required this.readyLabel,
    required this.countLabel,
    required this.inputSemanticLabel,
    required this.decreaseSemanticLabel,
    required this.increaseSemanticLabel,
    required this.overLimitMessage,
    this.readyHelper,
    this.countHelper,
    this.remainingLabel,
    this.remainingHelper,
    this.totalLabel,
    this.fillAllLabel,
  });

  /// The size column's name — "Size".
  final String sizeLabel;

  /// "Ready".
  final String readyLabel;

  /// What "Ready" means at this stage — "Thread-cut, not pressed".
  final String? readyHelper;

  /// The main count's name — "Pressed now". The only word that changes from
  /// stage to stage: Cut, Loaded, Pressed, Packed.
  final String countLabel;

  /// What goes in the main count — "Good pieces you pressed".
  final String? countHelper;

  /// "Still to press" — ready minus counted, after this entry. Null hides the
  /// column.
  final String? remainingLabel;

  /// "After this entry".
  final String? remainingHelper;

  /// "Total", for the table's footer row on a wide window. Null hides the
  /// row. On a phone the total belongs in the flow's fixed footer instead —
  /// use [FoSizeCountGrid.totalOf].
  final String? totalLabel;

  /// "Fill all ready (146)" — the button that copies every Ready figure into
  /// its count. Null hides it.
  final String? fillAllLabel;

  /// The main box's name for one size — "Pressed, size M".
  final String Function(String size) inputSemanticLabel;

  /// "One fewer, size M".
  final String Function(String size) decreaseSemanticLabel;

  /// "One more, size M".
  final String Function(String size) increaseSemanticLabel;

  /// Why a size is flagged — "2 more than ready. You can still send it; an
  /// owner will need to approve." Given the size and how far over it is.
  final String Function(String size, int over) overLimitMessage;
}

/// One size on a phone: the size, its Ready figure, and a − / count / + row.
///
/// **Over the ready count is a warning, never an error.** The card gets a
/// warning ring and a sentence saying what happens next — an owner approves
/// it — and nothing stops the user sending it. Counting more than the system
/// thinks was ready is usually the system being behind the floor, not the
/// floor being wrong.
class FoSizeCountRow extends StatelessWidget {
  /// Creates a size-count row.
  const FoSizeCountRow({
    required this.count,
    required this.onChanged,
    required this.readyLabel,
    required this.inputSemanticLabel,
    required this.decreaseSemanticLabel,
    required this.increaseSemanticLabel,
    this.overLimitMessage,
    this.extra,
    super.key,
  });

  /// The size, its ready figure and its count.
  final FoSizeCount count;

  /// Called with the new count.
  final ValueChanged<int> onChanged;

  /// "Ready".
  final String readyLabel;

  /// "Pressed, size M".
  final String inputSemanticLabel;

  /// "One fewer, size M".
  final String decreaseSemanticLabel;

  /// "One more, size M".
  final String increaseSemanticLabel;

  /// The sentence shown while the count is over ready. Null shows the ring
  /// alone — always pass it.
  final String? overLimitMessage;

  /// Secondary counts for this size, under the main row.
  final Widget? extra;

  /// The size's type size: the thing somebody scans down the column for.
  static const double _sizeLabelSize = 24;

  @override
  Widget build(BuildContext context) {
    final bool over = count.over > 0;
    final BorderRadius radius = BorderRadius.circular(context.foRadii.card);

    final Widget heading = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          count.size,
          style: context.foText.display.copyWith(
            fontSize: _sizeLabelSize,
          ),
        ),
        if (count.ready != null)
          Text.rich(
            TextSpan(
              children: <InlineSpan>[
                TextSpan(text: '$readyLabel '),
                TextSpan(
                  text: '${count.ready}',
                  style: context.foText.numeric.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: FoTokens.fontLabel,
                  ),
                ),
              ],
            ),
            style: context.foText.body.copyWith(
              fontSize: FoTokens.fontLabel,
              color: context.foColors.fgSubtle,
            ),
          ),
      ],
    );

    return Container(
      padding: EdgeInsets.all(context.foSpacing.md),
      decoration: BoxDecoration(
        color: context.foColors.surfaceRaised,
        borderRadius: radius,
      ),
      foregroundDecoration: BoxDecoration(
        borderRadius: radius,
        border: Border.all(
          color: over ? context.foColors.warning : context.foColors.edge,
          width: over ? 2 : FoLayout.hairlineWidth,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          // The heading and the count row wrap rather than squeeze: at 200%
          // text the stepper drops under the size instead of off the edge.
          SizedBox(
            width: double.infinity,
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: context.foSpacing.md,
              runSpacing: context.foSpacing.sm,
              children: <Widget>[
                heading,
                FoNumberField(
                  value: count.value,
                  onChanged: onChanged,
                  warning: over,
                  semanticLabel: inputSemanticLabel,
                  decreaseSemanticLabel: decreaseSemanticLabel,
                  increaseSemanticLabel: increaseSemanticLabel,
                ),
              ],
            ),
          ),
          if (over && overLimitMessage != null) ...<Widget>[
            SizedBox(height: context.foSpacing.sm),
            _OverLimitLine(message: overLimitMessage!),
          ],
          if (extra != null) ...<Widget>[
            SizedBox(height: context.foSpacing.sm),
            extra!,
          ],
        ],
      ),
    );
  }
}

/// Counting by size, at every stage: one row per size with its Ready figure,
/// a count, and — over ready — a warning that asks for approval rather than
/// refusing.
///
/// **The same grid at every stage; only the words change** — Cut, Loaded,
/// Pressed, Packed — which is why every word is in [copy].
///
/// On a phone each size is a [FoSizeCountRow] card with a − / + stepper, and
/// [extraColumns] (re-press, damaged) appear inside each card when
/// [showExtraColumns] is set — the caller's "Any re-press or damaged pieces?"
/// toggle. On a wide window it is a table: Size, Ready, the count, each extra
/// column, what is still to do, and a total row, with the over-limit sentence
/// on a line of its own under the size it is about.
///
/// "Fill all ready" ([onFillAll]) is offered whenever a ready figure is known:
/// most entries are "everything that was ready", and typing five numbers to
/// say so is the friction this grid exists to remove.
///
/// It is controlled: [sizes] is the truth, and a fill is the caller setting
/// every value at once — which every box shows immediately.
class FoSizeCountGrid extends StatelessWidget {
  /// Creates a size-count grid.
  const FoSizeCountGrid({
    required this.sizes,
    required this.onChanged,
    required this.copy,
    this.onFillAll,
    this.extraColumns = const <FoSizeCountColumn>[],
    this.showExtraColumns = false,
    this.numberFormatter,
    super.key,
  });

  /// One entry per size, in order.
  final List<FoSizeCount> sizes;

  /// Called with a size's index and its new main count.
  final void Function(int index, int value) onChanged;

  /// Every word the grid shows.
  final FoSizeCountCopy copy;

  /// Copies every Ready figure into its count. Null, or no ready figures,
  /// hides the button.
  final VoidCallback? onFillAll;

  /// Secondary counts. Always shown as columns on a wide window; on a phone
  /// only while [showExtraColumns] is true.
  final List<FoSizeCountColumn> extraColumns;

  /// Shows [extraColumns] inside each card on a phone.
  final bool showExtraColumns;

  /// Formats a figure — thousands separators. Defaults to plain digits.
  final String Function(int value)? numberFormatter;

  /// The sum of every main count — for a flow's footer.
  static int totalOf(List<FoSizeCount> sizes) =>
      sizes.fold<int>(0, (int sum, FoSizeCount s) => sum + s.value);

  /// The sum of every known ready figure.
  static int readyTotalOf(List<FoSizeCount> sizes) =>
      sizes.fold<int>(0, (int sum, FoSizeCount s) => sum + (s.ready ?? 0));

  String _fmt(int value) => (numberFormatter ?? (int n) => '$n')(value);

  bool get _hasReady => sizes.any((FoSizeCount s) => s.ready != null);

  @override
  Widget build(BuildContext context) {
    final Widget? fill =
        onFillAll != null && copy.fillAllLabel != null && _hasReady
            ? FoButton(
                label: copy.fillAllLabel!,
                variant: FoButtonVariant.secondary,
                icon: Icons.check,
                onPressed: onFillAll,
              )
            : null;

    final Widget grid = context.foWindowClass.isAtLeastMedium
        ? _table(context)
        : _cards(context);

    if (fill == null) return grid;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        fill,
        SizedBox(height: context.foSpacing.lg),
        grid,
      ],
    );
  }

  // ─── Phone: one card per size ────────────────────────────────────────────

  Widget _cards(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          for (int i = 0; i < sizes.length; i++) ...<Widget>[
            if (i > 0) SizedBox(height: context.foSpacing.sm),
            FoSizeCountRow(
              count: sizes[i],
              onChanged: (int v) => onChanged(i, v),
              readyLabel: copy.readyLabel,
              inputSemanticLabel: copy.inputSemanticLabel(sizes[i].size),
              decreaseSemanticLabel: copy.decreaseSemanticLabel(sizes[i].size),
              increaseSemanticLabel: copy.increaseSemanticLabel(sizes[i].size),
              overLimitMessage: sizes[i].over > 0
                  ? copy.overLimitMessage(sizes[i].size, sizes[i].over)
                  : null,
              extra: showExtraColumns && extraColumns.isNotEmpty
                  ? _extraFields(context, i)
                  : null,
            ),
          ],
        ],
      );

  Widget _extraFields(BuildContext context, int i) => Wrap(
        spacing: context.foSpacing.lg,
        runSpacing: context.foSpacing.sm,
        children: <Widget>[
          for (final FoSizeCountColumn column in extraColumns)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Flexible(
                  child: Text(
                    column.label,
                    style: context.foText.body.copyWith(
                      color: context.foColors.fgMuted,
                    ),
                  ),
                ),
                SizedBox(width: context.foSpacing.sm),
                FoNumberField(
                  value: column.values[i],
                  onChanged: (int v) => column.onChanged(i, v),
                  semanticLabel: column.inputSemanticLabel(sizes[i].size),
                  showSteppers: false,
                ),
              ],
            ),
        ],
      );

  // ─── Wide: a table ───────────────────────────────────────────────────────

  /// The columns' minimum widths. Below their sum the table scrolls sideways
  /// rather than squeezing a box narrower than four digits.
  static const double _sizeColumn = 72;
  static const double _figureColumn = 104;
  static const double _inputColumn = FoNumberField.defaultBoxWidth + 32;

  Widget _table(BuildContext context) {
    final bool remaining = copy.remainingLabel != null;
    final int inputs = 1 + extraColumns.length;
    final double minWidth = _sizeColumn +
        _figureColumn +
        inputs * _inputColumn +
        (remaining ? _figureColumn : 0);

    final Widget table = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _row(
          context,
          header: true,
          size: _Header(copy.sizeLabel),
          ready: _Header(copy.readyLabel, helper: copy.readyHelper),
          inputs: <Widget>[
            _Header(copy.countLabel, helper: copy.countHelper),
            for (final FoSizeCountColumn column in extraColumns)
              _Header(column.label, helper: column.helper),
          ],
          remaining: remaining
              ? _Header(copy.remainingLabel!, helper: copy.remainingHelper)
              : null,
        ),
        for (int i = 0; i < sizes.length; i++) ...<Widget>[
          _row(
            context,
            size: Semantics(
              header: true,
              child: Text(sizes[i].size, style: context.foText.subtitle),
            ),
            ready: _Figure(
              sizes[i].ready == null ? '' : _fmt(sizes[i].ready!),
            ),
            inputs: <Widget>[
              FoNumberField(
                value: sizes[i].value,
                onChanged: (int v) => onChanged(i, v),
                warning: sizes[i].over > 0,
                semanticLabel: copy.inputSemanticLabel(sizes[i].size),
                showSteppers: false,
              ),
              for (final FoSizeCountColumn column in extraColumns)
                FoNumberField(
                  value: column.values[i],
                  onChanged: (int v) => column.onChanged(i, v),
                  semanticLabel: column.inputSemanticLabel(sizes[i].size),
                  showSteppers: false,
                ),
            ],
            remaining: remaining
                ? _Figure(
                    sizes[i].ready == null
                        ? ''
                        : _signed(sizes[i].ready! - sizes[i].value),
                    warning: sizes[i].over > 0,
                  )
                : null,
          ),
          if (sizes[i].over > 0)
            Padding(
              padding: EdgeInsets.fromLTRB(
                context.foSpacing.md,
                0,
                context.foSpacing.md,
                context.foSpacing.sm,
              ),
              child: _OverLimitLine(
                message: copy.overLimitMessage(sizes[i].size, sizes[i].over),
              ),
            ),
        ],
        if (copy.totalLabel != null)
          DecoratedBox(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: context.foColors.edgeStrong, width: 2),
              ),
            ),
            child: _row(
              context,
              size: Text(copy.totalLabel!, style: context.foText.label),
              ready: _Figure(_fmt(readyTotalOf(sizes)), strong: true),
              inputs: <Widget>[
                _Figure(_fmt(totalOf(sizes)), strong: true),
                for (final FoSizeCountColumn column in extraColumns)
                  _Figure(
                    _fmt(column.values.fold<int>(0, (int a, int b) => a + b)),
                    strong: true,
                  ),
              ],
              // The raw sum, so the column adds up: Ready total minus the
              // counted total, over-counts included.
              remaining: remaining
                  ? _Figure(
                      _signed(
                        sizes.fold<int>(
                          0,
                          (int sum, FoSizeCount s) =>
                              s.ready == null ? sum : sum + s.ready! - s.value,
                        ),
                      ),
                      strong: true,
                    )
                  : null,
            ),
          ),
      ],
    );

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        if (!constraints.hasBoundedWidth || constraints.maxWidth >= minWidth) {
          return table;
        }
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(width: minWidth, child: table),
        );
      },
    );
  }

  /// "−2" with a real minus sign, so an over-count reads as a deficit.
  String _signed(int value) => value < 0 ? '−${_fmt(-value)}' : _fmt(value);

  Widget _row(
    BuildContext context, {
    required Widget size,
    required Widget ready,
    required List<Widget> inputs,
    required Widget? remaining,
    bool header = false,
  }) {
    final EdgeInsets cell = EdgeInsets.symmetric(
      horizontal: context.foSpacing.sm,
      vertical: header ? context.foSpacing.sm : context.foSpacing.xs,
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        color: header ? context.foColors.surfaceSunken : null,
        border: header
            ? null
            : Border(top: BorderSide(color: context.foColors.edge)),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: header ? 0 : FoNumberField.controlHeight + 8,
        ),
        child: Row(
          crossAxisAlignment:
              header ? CrossAxisAlignment.end : CrossAxisAlignment.center,
          children: <Widget>[
            SizedBox(
              width: _sizeColumn,
              child: Padding(padding: cell, child: size),
            ),
            Expanded(
              child: Padding(
                padding: cell,
                child: Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: ready,
                ),
              ),
            ),
            for (final Widget input in inputs)
              Expanded(
                child: Padding(
                  padding: cell,
                  child: Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: input,
                  ),
                ),
              ),
            if (remaining != null)
              Expanded(
                child: Padding(
                  padding: cell,
                  child: Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: remaining,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// A column heading: a mono caption naming the column, and an optional line
/// saying what goes in it.
class _Header extends StatelessWidget {
  const _Header(this.label, {this.helper});

  final String label;
  final String? helper;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            label.toUpperCase(),
            textAlign: TextAlign.end,
            style: context.foText.caption,
          ),
          if (helper != null)
            Text(
              helper!,
              textAlign: TextAlign.end,
              style: context.foText.body.copyWith(
                fontSize: FoTokens.fontCaption,
                color: context.foColors.fgSubtle,
              ),
            ),
        ],
      );
}

/// A right-aligned mono figure.
class _Figure extends StatelessWidget {
  const _Figure(this.text, {this.strong = false, this.warning = false});

  final String text;
  final bool strong;
  final bool warning;

  @override
  Widget build(BuildContext context) => Text(
        text,
        textAlign: TextAlign.end,
        style: context.foText.numeric.copyWith(
          fontWeight: strong || warning ? FontWeight.w600 : FontWeight.w500,
          color: warning ? context.foColors.warning : null,
        ),
      );
}

/// The over-limit sentence, with its mark.
class _OverLimitLine extends StatelessWidget {
  const _OverLimitLine({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Semantics(
        liveRegion: true,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(
              Icons.warning_amber_outlined,
              size: FoTokens.iconSmall,
              color: context.foColors.warning,
            ),
            SizedBox(width: context.foSpacing.sm),
            Expanded(
              child: Text(
                message,
                style: context.foText.body.copyWith(
                  fontSize: FoTokens.fontLabel,
                  color: context.foColors.warning,
                ),
              ),
            ),
          ],
        ),
      );
}

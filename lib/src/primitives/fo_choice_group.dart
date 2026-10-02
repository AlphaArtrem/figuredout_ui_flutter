import 'package:flutter/material.dart';

import '../theme/fo_context.dart';
import '../tokens/fo_layout.dart';
import '../tokens/fo_tokens.dart';
import 'fo_focus_ring.dart';

/// One option in a [FoChoiceGroup].
@immutable
class FoChoice<T> {
  /// Creates a choice.
  const FoChoice({
    required this.value,
    required this.label,
    this.description,
    this.count,
    this.leading,
    this.enabled = true,
  });

  /// What choosing it stores.
  final T value;

  /// What it is called — "Loose stitch", "Line supervisor". Caller-supplied.
  final String label;

  /// One plain line under the label: what it means, or why it is disabled.
  /// Shown in the `cards` and `list` layouts.
  final String? description;

  /// How many already have it — the pieces given this defect so far. Null
  /// shows nothing; zero is hidden too, because "0" on every untouched chip
  /// is noise.
  final int? count;

  /// Something before the label — a colour swatch, a status chip.
  final Widget? leading;

  /// False greys the option out and takes it out of reach. Say why in
  /// [description]: an option that cannot be chosen, with no reason, reads as
  /// a fault.
  final bool enabled;
}

/// How a [FoChoiceGroup] lays its options out.
enum FoChoiceLayout {
  /// Pills in one row that scrolls sideways when it does not fit — quick
  /// reasons, scopes, sizes. The default, for a handful of short labels.
  chips,

  /// Equal tiles, two to a row on a phone, with the count on the right — a
  /// defect picker tapped once per piece.
  grid,

  /// Cards with a radio dot and a line of description — roles, statuses,
  /// kinds: choices somebody has to understand before picking.
  cards,

  /// Full-width rows with dividers — a language, a setting.
  list,
}

/// Pick one, or several, from a short closed list — the one control for every
/// "which of these" on a form.
///
/// A reason, a defect, a role, a status, a kind, a table, a line: until now
/// each screen drew its own chips, half with `aria-pressed` and half as
/// radios, half filled and half ringed. This is one control in four
/// [FoChoiceLayout]s, single ([FoChoiceGroup.single]) or multiple
/// ([FoChoiceGroup.multiple]).
///
/// **Selected is the primary wash with a 2-point primary ring and a check** in
/// every layout — the ring and the glyph mean selection never relies on
/// colour alone.
///
/// Every option is at least 48 points tall. A single group reads as radio
/// buttons to a screen reader (one checked, mutually exclusive); a multiple
/// one as checkboxes. [errorText] puts the group in its error state, with the
/// sentence under it saying what to do.
///
/// For a closed list of more than a dozen or so, use `FoLookupPicker`: a wall
/// of chips stops being scannable long before it stops fitting.
class FoChoiceGroup<T> extends StatelessWidget {
  /// One of [choices]; [value] null means none chosen yet.
  const FoChoiceGroup.single({
    required this.choices,
    required T? value,
    required ValueChanged<T> onChanged,
    required this.semanticLabel,
    this.layout = FoChoiceLayout.chips,
    this.errorText,
    this.minCardWidth = 220,
    super.key,
  })  : assert(choices.length > 0, 'a choice of nothing is not a question'),
        _selected = value,
        _values = null,
        _onSingle = onChanged,
        _onMultiple = null;

  /// Any number of [choices].
  const FoChoiceGroup.multiple({
    required this.choices,
    required Set<T> values,
    required ValueChanged<Set<T>> onChanged,
    required this.semanticLabel,
    this.layout = FoChoiceLayout.chips,
    this.errorText,
    this.minCardWidth = 220,
    super.key,
  })  : assert(choices.length > 0, 'a choice of nothing is not a question'),
        _selected = null,
        _values = values,
        _onSingle = null,
        _onMultiple = onChanged;

  /// The options, in order.
  final List<FoChoice<T>> choices;

  /// What the group asks — "What was wrong, size M". Read before the options.
  final String semanticLabel;

  /// How the options are laid out.
  final FoChoiceLayout layout;

  /// Puts the group in its error state — "Choose what was wrong with this
  /// piece to go on." Null when there is nothing wrong.
  final String? errorText;

  /// The narrowest a card may be before the cards stack (cards layout).
  final double minCardWidth;

  final T? _selected;
  final Set<T>? _values;
  final ValueChanged<T>? _onSingle;
  final ValueChanged<Set<T>>? _onMultiple;

  bool get _isMultiple => _values != null;

  bool _isSelected(T value) =>
      _isMultiple ? _values!.contains(value) : _selected == value;

  void _toggle(T value) {
    if (!_isMultiple) {
      if (_selected != value) _onSingle!(value);
      return;
    }
    final Set<T> next = Set<T>.of(_values!);
    if (!next.remove(value)) next.add(value);
    _onMultiple!(next);
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> options = <Widget>[
      for (final FoChoice<T> choice in choices)
        _Option(
          choice: choice,
          layout: layout,
          selected: _isSelected(choice.value),
          multiple: _isMultiple,
          error: errorText != null,
          onTap: choice.enabled ? () => _toggle(choice.value) : null,
        ),
    ];

    final Widget body = switch (layout) {
      // A chip row never wraps: what does not fit scrolls sideways in one
      // row. For more options than a row can hold, use `grid`.
      FoChoiceLayout.chips => SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: <Widget>[
              for (int i = 0; i < options.length; i++) ...<Widget>[
                if (i > 0) SizedBox(width: context.foSpacing.sm),
                options[i],
              ],
            ],
          ),
        ),
      FoChoiceLayout.grid => _columns(context, options, 2),
      FoChoiceLayout.cards => LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final int n = (constraints.maxWidth / minCardWidth).floor();
            return _columns(context, options, n.clamp(1, options.length));
          },
        ),
      FoChoiceLayout.list => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            for (int i = 0; i < options.length; i++) ...<Widget>[
              if (i > 0)
                Divider(
                  height: FoLayout.hairlineWidth,
                  thickness: FoLayout.hairlineWidth,
                  color: context.foColors.edge,
                ),
              options[i],
            ],
          ],
        ),
    };

    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: semanticLabel,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          body,
          if (errorText != null) ...<Widget>[
            SizedBox(height: context.foSpacing.sm),
            Semantics(
              liveRegion: true,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Icon(
                    Icons.error_outline,
                    size: FoTokens.iconSmall,
                    color: context.foColors.danger,
                  ),
                  SizedBox(width: context.foSpacing.xs),
                  Expanded(
                    child: Text(
                      errorText!,
                      style: context.foText.label.copyWith(
                        color: context.foColors.danger,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Equal columns of equal-height rows.
  Widget _columns(BuildContext context, List<Widget> options, int columns) {
    final double gap = context.foSpacing.sm;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (int start = 0;
            start < options.length;
            start += columns) ...<Widget>[
          if (start > 0) SizedBox(height: gap),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                for (int i = start; i < start + columns; i++) ...<Widget>[
                  if (i > start) SizedBox(width: gap),
                  Expanded(
                    child: i < options.length
                        ? options[i]
                        : const SizedBox.shrink(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _Option<T> extends StatelessWidget {
  const _Option({
    required this.choice,
    required this.layout,
    required this.selected,
    required this.multiple,
    required this.error,
    required this.onTap,
  });

  final FoChoice<T> choice;
  final FoChoiceLayout layout;
  final bool selected;
  final bool multiple;
  final bool error;
  final VoidCallback? onTap;

  /// A radio dot's or a checkbox's size.
  static const double _markSize = 18;

  @override
  Widget build(BuildContext context) {
    final bool enabled = onTap != null;
    final bool list = layout == FoChoiceLayout.list;
    final BorderRadius radius = BorderRadius.circular(
      layout == FoChoiceLayout.chips
          ? context.foRadii.pill
          : context.foRadii.md,
    );

    final Color ink = !enabled
        ? context.foColors.fg.withValues(alpha: FoTokens.disabledInkOpacity)
        : selected
            ? context.foColors.primary
            : context.foColors.fg;
    final TextStyle labelStyle = context.foText.body.copyWith(
      color: ink,
      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
      fontSize: layout == FoChoiceLayout.grid ? FoTokens.fontSubtitle : null,
    );

    final Widget? count = (choice.count ?? 0) > 0
        ? Container(
            constraints: const BoxConstraints(minWidth: 26),
            padding: EdgeInsets.symmetric(
              horizontal: context.foSpacing.sm,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: context.foColors.primary,
              borderRadius: BorderRadius.circular(context.foRadii.pill),
            ),
            child: Text(
              '${choice.count}',
              textAlign: TextAlign.center,
              style: context.foText.numeric.copyWith(
                fontSize: FoTokens.fontLabel,
                fontWeight: FontWeight.w600,
                color: context.foColors.primaryFg,
              ),
            ),
          )
        : null;

    final Widget label = Text(choice.label, style: labelStyle);
    final Widget content = switch (layout) {
      FoChoiceLayout.chips => Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (selected) ...<Widget>[
              Icon(Icons.check, size: FoTokens.iconSmall, color: ink),
              SizedBox(width: context.foSpacing.xs),
            ],
            if (choice.leading != null) ...<Widget>[
              choice.leading!,
              SizedBox(width: context.foSpacing.sm),
            ],
            label,
            if (count != null) ...<Widget>[
              SizedBox(width: context.foSpacing.sm),
              count,
            ],
          ],
        ),
      FoChoiceLayout.grid => Row(
          children: <Widget>[
            if (choice.leading != null) ...<Widget>[
              choice.leading!,
              SizedBox(width: context.foSpacing.sm),
            ],
            Expanded(child: label),
            if (count != null) ...<Widget>[
              SizedBox(width: context.foSpacing.sm),
              count,
            ],
          ],
        ),
      FoChoiceLayout.cards || FoChoiceLayout.list => Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: _Mark(
                selected: selected,
                multiple: multiple,
                enabled: enabled,
                size: _markSize,
              ),
            ),
            SizedBox(width: context.foSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      if (choice.leading != null) ...<Widget>[
                        choice.leading!,
                        SizedBox(width: context.foSpacing.sm),
                      ],
                      Flexible(child: label),
                    ],
                  ),
                  if (choice.description != null) ...<Widget>[
                    SizedBox(height: context.foSpacing.xs),
                    Text(
                      choice.description!,
                      style: context.foText.body.copyWith(
                        fontSize: FoTokens.fontLabel,
                        color: context.foColors.fgMuted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (count != null) ...<Widget>[
              SizedBox(width: context.foSpacing.sm),
              count,
            ],
          ],
        ),
    };

    final Color fill = list
        ? Colors.transparent
        : selected
            ? context.foColors.primarySoft
            : context.foColors.surfaceRaised;
    final Color? edge = list
        ? null
        : selected
            ? context.foColors.primary
            : error
                ? context.foColors.danger
                : layout == FoChoiceLayout.cards
                    ? context.foColors.edge
                    : context.foColors.edgeStrong;

    return Semantics(
      checked: selected,
      inMutuallyExclusiveGroup: !multiple,
      enabled: enabled,
      label: choice.count == null || choice.count == 0
          ? choice.label
          : '${choice.label}, ${choice.count}',
      hint: choice.description,
      onTap: onTap,
      excludeSemantics: true,
      child: FoFocusRing(
        borderRadius: radius,
        enabled: enabled,
        child: Material(
          color: Colors.transparent,
          borderRadius: radius,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            borderRadius: radius,
            child: Container(
              constraints: const BoxConstraints(
                minHeight: FoLayout.minTouchTarget,
              ),
              padding: EdgeInsets.symmetric(
                horizontal: list ? 0 : context.foSpacing.md,
                vertical: layout == FoChoiceLayout.chips
                    ? context.foSpacing.xs
                    : context.foSpacing.md,
              ),
              alignment: layout == FoChoiceLayout.chips
                  ? null
                  : AlignmentDirectional.centerStart,
              decoration: BoxDecoration(color: fill, borderRadius: radius),
              foregroundDecoration: edge == null
                  ? null
                  : BoxDecoration(
                      borderRadius: radius,
                      border: Border.all(
                        color: edge,
                        width: selected ? 2 : FoLayout.hairlineWidth,
                      ),
                    ),
              child: layout == FoChoiceLayout.chips
                  ? Center(widthFactor: 1, heightFactor: 1, child: content)
                  : content,
            ),
          ),
        ),
      ),
    );
  }
}

/// A radio dot, or a checkbox, drawn rather than borrowed from Material, so
/// it follows the ring-and-wash language of the rest of the option.
class _Mark extends StatelessWidget {
  const _Mark({
    required this.selected,
    required this.multiple,
    required this.enabled,
    required this.size,
  });

  final bool selected;
  final bool multiple;
  final bool enabled;
  final double size;

  @override
  Widget build(BuildContext context) {
    final Color on = context.foColors.primary;
    final BoxShape shape = multiple ? BoxShape.rectangle : BoxShape.circle;
    final BorderRadius? radius =
        multiple ? BorderRadius.circular(context.foRadii.sm) : null;
    return Opacity(
      opacity: enabled ? 1 : FoTokens.disabledInkOpacity,
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: shape,
          borderRadius: radius,
          color: selected && multiple ? on : context.foColors.surfaceRaised,
          border: Border.all(
            color: selected ? on : context.foColors.edgeStrong,
            width: selected && !multiple ? 5 : 1.5,
          ),
        ),
        child: selected && multiple
            ? Icon(
                Icons.check,
                size: size - 4,
                color: context.foColors.primaryFg,
              )
            : null,
      ),
    );
  }
}

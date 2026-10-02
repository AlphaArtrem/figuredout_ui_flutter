import 'package:flutter/material.dart';

import '../primitives/fo_button.dart';
import '../primitives/fo_focus_ring.dart';
import '../primitives/fo_icon_button.dart';
import '../theme/fo_context.dart';
import '../theme/fo_window_class.dart';
import '../tokens/fo_layout.dart';
import '../tokens/fo_tokens.dart';

/// A named range — "Last 7 days".
@immutable
class FoDateRangePreset {
  /// Creates a preset.
  const FoDateRangePreset({required this.label, required this.range});

  /// Its name. Caller-supplied.
  final String label;

  /// The days it covers, inclusive. Dates only — the time is ignored.
  final DateTimeRange range;
}

/// The words a [FoDateRangePicker] needs. Month and weekday names come from
/// the framework's own localizations.
@immutable
class FoDateRangeCopy {
  /// Creates the copy.
  const FoDateRangeCopy({
    required this.confirmLabel,
    required this.cancelLabel,
    required this.previousMonthLabel,
    required this.nextMonthLabel,
    required this.rangeLabel,
    this.presetsLabel,
    this.title,
  });

  /// "Use these dates".
  final String confirmLabel;

  /// "Cancel".
  final String cancelLabel;

  /// "Previous month".
  final String previousMonthLabel;

  /// "Next month".
  final String nextMonthLabel;

  /// The chosen range in words — "26 Sep – 2 Oct · 7 days". Also read
  /// aloud as the range changes.
  final String Function(DateTimeRange range) rangeLabel;

  /// "Quick picks".
  final String? presetsLabel;

  /// The dialog's title — "Dates".
  final String? title;
}

/// Pick a span of days: a quick pick, or a start and an end on a calendar.
///
/// For reports and lists filtered by date. **Presets first** — "Today", "Last
/// 7 days", "This month" — because almost every question asked of a report is
/// one of them; the calendar is for the rest. Tap a start, then an end (in
/// either order). Days after `lastDate` cannot be picked, because nothing has
/// happened on them yet.
///
/// A dialog on a wide window, a bottom sheet on a phone. Resolves with the
/// range, or null when cancelled. Dates are calendar days, not instants.
abstract final class FoDateRangePicker {
  /// Opens the picker.
  static Future<DateTimeRange?> show(
    BuildContext context, {
    required FoDateRangeCopy copy,
    required DateTime firstDate,
    required DateTime lastDate,
    DateTimeRange? initial,
    List<FoDateRangePreset> presets = const <FoDateRangePreset>[],
  }) {
    Widget body(BuildContext ctx) => _Picker(
          copy: copy,
          firstDate: _day(firstDate),
          lastDate: _day(lastDate),
          initial: initial,
          presets: presets,
        );
    if (context.foWindowClass == FoWindowClass.compact) {
      return showModalBottomSheet<DateTimeRange>(
        context: context,
        useRootNavigator: true,
        isScrollControlled: true,
        useSafeArea: true,
        elevation: 0,
        builder: body,
      );
    }
    return showDialog<DateTimeRange>(
      context: context,
      builder: (BuildContext ctx) => Dialog(
        backgroundColor: ctx.foColors.surfaceRaised,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ctx.foRadii.lg),
          side: BorderSide(color: ctx.foColors.edge),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 660),
          child: body(ctx),
        ),
      ),
    );
  }

  static DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);
}

class _Picker extends StatefulWidget {
  const _Picker({
    required this.copy,
    required this.firstDate,
    required this.lastDate,
    required this.initial,
    required this.presets,
  });

  final FoDateRangeCopy copy;
  final DateTime firstDate;
  final DateTime lastDate;
  final DateTimeRange? initial;
  final List<FoDateRangePreset> presets;

  @override
  State<_Picker> createState() => _PickerState();
}

class _PickerState extends State<_Picker> {
  late DateTime? _start = widget.initial == null
      ? null
      : FoDateRangePicker._day(widget.initial!.start);
  late DateTime? _end = widget.initial == null
      ? null
      : FoDateRangePicker._day(widget.initial!.end);
  late DateTime _month = DateTime(
    (_end ?? widget.lastDate).year,
    (_end ?? widget.lastDate).month,
  );

  DateTimeRange? get _range => _start == null
      ? null
      : DateTimeRange(start: _start!, end: _end ?? _start!);

  void _tap(DateTime day) {
    setState(() {
      if (_start == null || _end != null) {
        _start = day;
        _end = null;
      } else if (day.isBefore(_start!)) {
        _end = _start;
        _start = day;
      } else {
        _end = day;
      }
    });
  }

  void _preset(FoDateRangePreset p) {
    setState(() {
      _start = FoDateRangePicker._day(p.range.start);
      _end = FoDateRangePicker._day(p.range.end);
      _month = DateTime(_end!.year, _end!.month);
    });
  }

  bool _matches(FoDateRangePreset p) =>
      _range != null &&
      FoDateRangePicker._day(p.range.start) == _range!.start &&
      FoDateRangePicker._day(p.range.end) == _range!.end;

  @override
  Widget build(BuildContext context) {
    final bool wide = context.foWindowClass.isAtLeastMedium;
    final Widget presets = widget.presets.isEmpty
        ? const SizedBox.shrink()
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (widget.copy.presetsLabel != null) ...<Widget>[
                Text(
                  widget.copy.presetsLabel!.toUpperCase(),
                  style: context.foText.caption,
                ),
                SizedBox(height: context.foSpacing.sm),
              ],
              // A rail on a wide window; on a phone one row that scrolls
              // sideways, never wrapped.
              if (wide)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    for (final FoDateRangePreset p in widget.presets)
                      _PresetButton(
                        label: p.label,
                        selected: _matches(p),
                        onTap: () => _preset(p),
                      ),
                  ],
                )
              else
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: <Widget>[
                      for (final FoDateRangePreset p in widget.presets)
                        _PresetButton(
                          label: p.label,
                          selected: _matches(p),
                          onTap: () => _preset(p),
                        ),
                    ],
                  ),
                ),
            ],
          );

    final Widget calendar = _Month(
      month: _month,
      start: _start,
      end: _end,
      firstDate: widget.firstDate,
      lastDate: widget.lastDate,
      onTap: _tap,
      previousLabel: widget.copy.previousMonthLabel,
      nextLabel: widget.copy.nextMonthLabel,
      onMonth: (DateTime m) => setState(() => _month = m),
    );

    final DateTimeRange? range = _range;
    final Widget footer = Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: context.foSpacing.md,
      runSpacing: context.foSpacing.sm,
      children: <Widget>[
        Semantics(
          liveRegion: true,
          child: Text(
            range == null ? '' : widget.copy.rangeLabel(range),
            style: context.foText.numeric,
          ),
        ),
        Wrap(
          spacing: context.foSpacing.sm,
          children: <Widget>[
            FoButton(
              label: widget.copy.cancelLabel,
              variant: FoButtonVariant.clear,
              onPressed: () => Navigator.of(context).pop(),
            ),
            FoButton(
              label: widget.copy.confirmLabel,
              variant: FoButtonVariant.primary,
              onPressed:
                  range == null ? null : () => Navigator.of(context).pop(range),
            ),
          ],
        ),
      ],
    );

    return SingleChildScrollView(
      padding: EdgeInsets.all(context.foSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (widget.copy.title != null) ...<Widget>[
            Semantics(
              header: true,
              child: Text(widget.copy.title!, style: context.foText.title),
            ),
            SizedBox(height: context.foSpacing.lg),
          ],
          if (wide)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                SizedBox(width: 180, child: presets),
                SizedBox(width: context.foSpacing.xl),
                Expanded(child: calendar),
              ],
            )
          else ...<Widget>[
            presets,
            SizedBox(height: context.foSpacing.lg),
            calendar,
          ],
          SizedBox(height: context.foSpacing.lg),
          Divider(
            height: FoLayout.hairlineWidth,
            thickness: FoLayout.hairlineWidth,
            color: context.foColors.edge,
          ),
          SizedBox(height: context.foSpacing.md),
          footer,
        ],
      ),
    );
  }
}

class _PresetButton extends StatelessWidget {
  const _PresetButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final BorderRadius radius = BorderRadius.circular(context.foRadii.md);
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      onTap: onTap,
      excludeSemantics: true,
      child: FoFocusRing(
        borderRadius: radius,
        child: Material(
          color: selected ? context.foColors.primarySoft : Colors.transparent,
          borderRadius: radius,
          child: InkWell(
            onTap: onTap,
            borderRadius: radius,
            child: Container(
              constraints: const BoxConstraints(
                minHeight: FoLayout.minTouchTarget,
                minWidth: 120,
              ),
              alignment: AlignmentDirectional.centerStart,
              padding: EdgeInsets.symmetric(horizontal: context.foSpacing.md),
              child: Text(
                label,
                style: context.foText.body.copyWith(
                  color: selected ? context.foColors.primary : null,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Month extends StatelessWidget {
  const _Month({
    required this.month,
    required this.start,
    required this.end,
    required this.firstDate,
    required this.lastDate,
    required this.onTap,
    required this.previousLabel,
    required this.nextLabel,
    required this.onMonth,
  });

  final DateTime month;
  final DateTime? start;
  final DateTime? end;
  final DateTime firstDate;
  final DateTime lastDate;
  final ValueChanged<DateTime> onTap;
  final String previousLabel;
  final String nextLabel;
  final ValueChanged<DateTime> onMonth;

  static const double _cell = FoLayout.minTouchTarget;

  @override
  Widget build(BuildContext context) {
    final MaterialLocalizations l10n = MaterialLocalizations.of(context);
    final int first = l10n.firstDayOfWeekIndex; // 0 = Sunday
    final int days = DateUtils.getDaysInMonth(month.year, month.month);
    final int offset =
        (DateTime(month.year, month.month).weekday % 7 - first) % 7;
    final DateTime prev = DateTime(month.year, month.month - 1);
    final DateTime next = DateTime(month.year, month.month + 1);
    final bool canPrev =
        !prev.isBefore(DateTime(firstDate.year, firstDate.month));
    final bool canNext = !next.isAfter(DateTime(lastDate.year, lastDate.month));

    final List<Widget> cells = <Widget>[
      for (int i = 0; i < 7; i++)
        Center(
          child: ExcludeSemantics(
            child: Text(
              l10n.narrowWeekdays[(first + i) % 7],
              style: context.foText.caption,
            ),
          ),
        ),
      for (int i = 0; i < offset; i++) const SizedBox.shrink(),
      for (int d = 1; d <= days; d++)
        _Day(
          day: DateTime(month.year, month.month, d),
          start: start,
          end: end,
          enabled: !DateTime(month.year, month.month, d).isAfter(lastDate) &&
              !DateTime(month.year, month.month, d).isBefore(firstDate),
          onTap: onTap,
          label: l10n.formatFullDate(DateTime(month.year, month.month, d)),
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Row(
          children: <Widget>[
            FoIconButton(
              icon: Icons.chevron_left,
              semanticLabel: previousLabel,
              onPressed: canPrev ? () => onMonth(prev) : null,
            ),
            Expanded(
              child: Text(
                l10n.formatMonthYear(month),
                textAlign: TextAlign.center,
                style: context.foText.subtitle,
              ),
            ),
            FoIconButton(
              icon: Icons.chevron_right,
              semanticLabel: nextLabel,
              onPressed: canNext ? () => onMonth(next) : null,
            ),
          ],
        ),
        SizedBox(height: context.foSpacing.sm),
        LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final double cell = (constraints.maxWidth / 7).clamp(0, _cell);
            return Center(
              child: Wrap(
                children: <Widget>[
                  for (final Widget c in cells)
                    SizedBox(width: cell, height: _cell, child: c),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class _Day extends StatelessWidget {
  const _Day({
    required this.day,
    required this.start,
    required this.end,
    required this.enabled,
    required this.onTap,
    required this.label,
  });

  final DateTime day;
  final DateTime? start;
  final DateTime? end;
  final bool enabled;
  final ValueChanged<DateTime> onTap;
  final String label;

  @override
  Widget build(BuildContext context) {
    final bool isEnd = day == start || day == end;
    final bool inside = start != null &&
        end != null &&
        day.isAfter(start!) &&
        day.isBefore(end!);
    final Color fill = isEnd
        ? context.foColors.primary
        : inside
            ? context.foColors.primarySoft
            : Colors.transparent;
    final Color ink = !enabled
        ? context.foColors.fg.withValues(alpha: FoTokens.disabledInkOpacity)
        : isEnd
            ? context.foColors.primaryFg
            : inside
                ? context.foColors.primary
                : context.foColors.fg;
    final BorderRadius radius = BorderRadius.circular(context.foRadii.md);

    return Semantics(
      button: true,
      enabled: enabled,
      selected: isEnd || inside,
      label: label,
      onTap: enabled ? () => onTap(day) : null,
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: Material(
          color: fill,
          borderRadius: radius,
          child: InkWell(
            onTap: enabled ? () => onTap(day) : null,
            borderRadius: radius,
            child: Center(
              child: Text(
                '${day.day}',
                textScaler: TextScaler.noScaling,
                style: context.foText.numeric.copyWith(
                  color: ink,
                  fontWeight: isEnd ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

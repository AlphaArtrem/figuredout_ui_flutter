import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../primitives/fo_button.dart';
import '../primitives/fo_card.dart';
import '../primitives/fo_icon_button.dart';
import '../primitives/fo_key_hint.dart';
import '../primitives/fo_overlay_surface.dart';
import '../primitives/fo_spinner.dart';
import '../theme/fo_context.dart';
import '../tokens/fo_layout.dart';
import '../tokens/fo_motion.dart';
import '../tokens/fo_tokens.dart';
import 'fo_form_presenter.dart';
import 'fo_form_scope.dart';
import 'fo_info_banner.dart';
import 'fo_status_tabs.dart';

/// One option in a [FoEntityPickerField]'s list.
@immutable
class FoEntityPickerOption {
  /// Creates an option.
  const FoEntityPickerOption({
    required this.id,
    required this.label,
    this.supportingText,
    this.meta,
    this.leading,
  });

  /// The value that gets stored.
  final String id;

  /// What the user reads.
  final String label;

  /// A second line — a code, a location, whatever disambiguates two options
  /// with the same name.
  final String? supportingText;

  /// A short fact at the end of the row that helps somebody choose — "212
  /// ready", "Due in 7 days". Not a second label.
  final String? meta;

  /// Something before the label that is faster to recognise than a word — a
  /// colour swatch for a garment colour.
  final Widget? leading;

  /// Whether this is [FoLookupPicker.none], the "No filter" choice — not a
  /// record at all.
  bool get isNone => identical(this, FoLookupPicker.none);
}

/// The copy a [FoEntityPickerField] needs.
@immutable
class FoEntityPickerCopy {
  /// Creates the picker's copy.
  const FoEntityPickerCopy({
    required this.searchHint,
    required this.emptyText,
    required this.errorText,
    required this.clearTooltip,
    required this.requiredMessage,
    this.closeLabel,
    @Deprecated(
      'The picker no longer goes through FoFormPresenter, and a search has '
      'nothing to discard. Remove the argument; it is ignored.',
    )
    this.discardCopy,
    this.recentLabel,
    this.resultsLabel,
    this.scanLabel,
    this.retryLabel,
    this.likelyLabel,
    this.scopesLabel,
    this.moveHint,
    this.chooseHint,
    this.closeHint,
  });

  /// The search box's placeholder.
  final String searchHint;

  /// What to say when the search returned nothing.
  final String emptyText;

  /// What to say when the search failed.
  final String errorText;

  /// The clear button's tooltip.
  final String clearTooltip;

  /// The validation message when nothing is selected.
  final String requiredMessage;

  /// Ignored since 0.7.0 — see the constructor's deprecation.
  final FoDiscardCopy? discardCopy;

  /// The picker's close button — "Close". On a phone the picker is a full
  /// screen and this is its only way out, so it is never unnamed: null falls
  /// back to the framework's own localized "Close"
  /// (`MaterialLocalizations.closeButtonTooltip`).
  final String? closeLabel;

  /// The heading over [FoEntityPickerField.recent] — "Recent".
  final String? recentLabel;

  /// The heading over what the empty query returns — "Orders with pieces
  /// ready to press". Says *why* these come first.
  final String? resultsLabel;

  /// The scan button's name — "Scan the job card". Required when
  /// [FoEntityPickerField.onScan] is set.
  final String? scanLabel;

  /// The retry button under a failed search — "Try again". Without it the
  /// failure has no button and the user retries by retyping.
  final String? retryLabel;

  /// The heading over [FoLookupPicker.show]'s `likely` options — "Orders
  /// with pieces ready to press". Says *why* they come before the rest.
  final String? likelyLabel;

  /// What the scope row chooses between — "Which orders". Read before the
  /// scopes; falls back to the picker's title.
  final String? scopesLabel;

  /// "move" — beside the ↑ ↓ key hint, on a wide window.
  final String? moveHint;

  /// "choose" — beside the Enter key hint, on a wide window.
  final String? chooseHint;

  /// "close" — beside the Esc key hint, on a wide window.
  final String? closeHint;
}

/// One scope a [FoLookupPicker] can search in — "Running 22", "All orders
/// 25".
///
/// The picker shows the scopes as a row of chips that never wraps, and tells
/// the caller when the user switches (`onScopeChanged`); the caller's `search`
/// then answers for the new scope, and the picker runs it again with the same
/// query.
@immutable
class FoLookupScope {
  /// Creates a scope.
  const FoLookupScope({required this.label, this.count});

  /// "Running". Caller-supplied, so it can be localized.
  final String label;

  /// How many records are in it. Null shows nothing rather than a zero: a
  /// count that has not loaded and a count of none are different things.
  final int? count;
}

/// A field that picks one record out of many, by searching.
///
/// A dropdown stops working somewhere around thirty options; this is what
/// replaces it. It looks like a field and opens a searchable list.
///
/// **One picker for every lookup** — order, article, colour, line, buyer,
/// person. It opens [FoLookupPicker]: a dialog on a wide window and a full
/// screen on a phone (a half-height sheet leaves a keyboard and a list
/// fighting over the same 400 points). It searches the server as the user
/// types, shows [recent] choices first, and offers [onScan] where the thing
/// has a printed code — typing a job number off a card is the slowest way to
/// pick it.
///
/// Name the thing, never its key: the label is "Order", not "Order ID".
class FoEntityPickerField extends StatelessWidget {
  /// Creates a picker field.
  const FoEntityPickerField({
    required this.controller,
    required this.label,
    required this.selectedId,
    required this.search,
    required this.onSelected,
    required this.copy,
    this.enabled = true,
    this.isRequired = false,
    this.recent = const <FoEntityPickerOption>[],
    this.onScan,
    this.likely = const <FoEntityPickerOption>[],
    this.scopes = const <FoLookupScope>[],
    this.initialScope = 0,
    this.onScopeChanged,
    this.noneLabel,
    this.subtitle,
    this.totalLabel,
    super.key,
  });

  /// Holds the selected option's label. The field is read-only; this is what
  /// it displays.
  final TextEditingController controller;

  /// The field's label. Caller-supplied, so it can be localized.
  final String label;

  /// The selected option's id, for validation.
  final String? selectedId;

  /// Runs the search. Called with an empty query when the list opens.
  final Future<List<FoEntityPickerOption>> Function(String query) search;

  /// Called with the picked option, or null when the selection is cleared.
  final ValueChanged<FoEntityPickerOption?> onSelected;

  /// The picker's strings.
  final FoEntityPickerCopy copy;

  /// When false the field is read-only and cannot be opened.
  final bool enabled;

  /// Appends the app-wide `*` marker and validates that something is picked.
  final bool isRequired;

  /// What this user picked last, shown first while the search box is empty.
  /// The app keeps the list; the picker only shows it.
  final List<FoEntityPickerOption> recent;

  /// Reads a printed code — opens the app's scanner and resolves with the
  /// option it found, or null. Null hides the scan button.
  final Future<FoEntityPickerOption?> Function()? onScan;

  /// See [FoLookupPicker.show].
  final List<FoEntityPickerOption> likely;

  /// See [FoLookupPicker.show].
  final List<FoLookupScope> scopes;

  /// See [FoLookupPicker.show].
  final int initialScope;

  /// See [FoLookupPicker.show].
  final ValueChanged<int>? onScopeChanged;

  /// See [FoLookupPicker.show]. Choosing it clears the field and reports
  /// null, the same as the clear button.
  final String? noneLabel;

  /// See [FoLookupPicker.show].
  final String? subtitle;

  /// See [FoLookupPicker.show].
  final String? Function(int shown, int? total)? totalLabel;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: FoLayout.singleLineFieldHeight,
      child: TextFormField(
        controller: controller,
        readOnly: true,
        enabled: enabled,
        style: context.foText.body,
        decoration: InputDecoration(
          labelText: isRequired ? '$label *' : label,
          isDense: true,
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (enabled && controller.text.trim().isNotEmpty)
                IconButton(
                  onPressed: () {
                    controller.clear();
                    onSelected(null);
                    FoFormScope.markDirty(context);
                  },
                  icon: const Icon(Icons.clear),
                  tooltip: copy.clearTooltip,
                ),
              Padding(
                padding: EdgeInsets.only(right: context.foSpacing.md),
                child: const Icon(Icons.search),
              ),
            ],
          ),
        ),
        validator: !isRequired
            ? null
            : (_) => (selectedId == null || selectedId!.trim().isEmpty)
                ? copy.requiredMessage
                : null,
        onTap: !enabled
            ? null
            : () async {
                final FoEntityPickerOption? option = await FoLookupPicker.show(
                  context,
                  title: label,
                  search: search,
                  copy: copy,
                  recent: recent,
                  onScan: onScan,
                  likely: likely,
                  scopes: scopes,
                  initialScope: initialScope,
                  onScopeChanged: onScopeChanged,
                  noneLabel: noneLabel,
                  subtitle: subtitle,
                  totalLabel: totalLabel,
                );
                if (option == null) return;
                if (option.isNone) {
                  controller.clear();
                  onSelected(null);
                } else {
                  controller.text = option.label;
                  onSelected(option);
                }
                if (context.mounted) FoFormScope.markDirty(context);
              },
      ),
    );
  }
}

/// The lookup picker itself: a search box, recent and likely choices, server
/// results as the user types, scopes, and an optional scan button.
///
/// [show] presents it the right way for the width — a dialog on a wide window,
/// a full-screen route on a phone — on the root navigator, and resolves with
/// the picked option or null. `FoEntityPickerField` is the usual way in; call
/// [show] directly where the trigger is not a field — a filter button, a step
/// of a flow that is nothing but a choice.
///
/// The search is debounced by `FoMotion.searchDebounce`, and a failed search
/// says so and stays usable: the user can retype and it runs again. An empty
/// result is never shown as a failure, nor a failure as an empty result.
abstract final class FoLookupPicker {
  /// The dialog's size on a wide window.
  static const Size dialogSize = Size(660, 720);

  /// What [show] resolves with when the user chooses `noneLabel` — "No
  /// filter: all orders". Null still means the picker was closed without a
  /// choice, so the two never get confused. Test with
  /// [FoEntityPickerOption.isNone].
  static const FoEntityPickerOption none = FoEntityPickerOption(
    id: '\u0000fo-lookup-none',
    label: '',
  );

  /// Presents the picker. Resolves with the option picked, [none], or null.
  ///
  /// - [subtitle] says what the choice is for — "For the new fabric receipt".
  /// - [recent] and [likely] fill the empty search box, in that order, each
  ///   under its caption (`copy.recentLabel`, `copy.likelyLabel`); what
  ///   `search('')` returns follows under `copy.resultsLabel`, without the
  ///   options already shown above it.
  /// - [scopes] are chips over the list — "Running 22 · All orders 25" — that
  ///   stay in one row and scroll sideways rather than wrap. [initialScope]
  ///   is current at first; on a switch [onScopeChanged] fires and the
  ///   picker runs `search` again with the same query, so the caller's
  ///   `search` must answer for the scope it was last told.
  /// - [noneLabel] adds a "No filter: all orders" action that resolves with
  ///   [none].
  /// - [totalLabel] builds the line under the list — "Showing the first 8 of
  ///   22 · keep typing" — from how many options are shown and the current
  ///   scope's count; return null to show nothing.
  ///
  /// On a wide window the arrow keys move through the options, Enter chooses
  /// the highlighted one and Esc closes, with the keys shown in the footer
  /// when `copy.moveHint`, `chooseHint` or `closeHint` are given.
  static Future<FoEntityPickerOption?> show(
    BuildContext context, {
    required String title,
    required Future<List<FoEntityPickerOption>> Function(String query) search,
    required FoEntityPickerCopy copy,
    List<FoEntityPickerOption> recent = const <FoEntityPickerOption>[],
    Future<FoEntityPickerOption?> Function()? onScan,
    List<FoEntityPickerOption> likely = const <FoEntityPickerOption>[],
    List<FoLookupScope> scopes = const <FoLookupScope>[],
    int initialScope = 0,
    ValueChanged<int>? onScopeChanged,
    String? noneLabel,
    String? subtitle,
    String? Function(int shown, int? total)? totalLabel,
  }) {
    assert(
      onScan == null || copy.scanLabel != null,
      'copy.scanLabel is required when onScan is set.',
    );
    Widget body(BuildContext ctx) => _PickerBody(
          title: title,
          search: search,
          copy: copy,
          recent: recent,
          onScan: onScan,
          likely: likely,
          scopes: scopes,
          initialScope: initialScope,
          onScopeChanged: onScopeChanged,
          noneLabel: noneLabel,
          subtitle: subtitle,
          totalLabel: totalLabel,
        );

    if (context.foWindowClass.isAtLeastMedium) {
      return showDialog<FoEntityPickerOption>(
        context: context,
        builder: (BuildContext ctx) => Dialog(
          insetPadding: EdgeInsets.all(ctx.foSpacing.xl),
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: dialogSize.width,
              maxHeight: dialogSize.height,
            ),
            child: DecoratedBox(
              decoration: foOverlaySurface(ctx, radius: ctx.foRadii.lg),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(ctx.foRadii.lg),
                child: Material(
                  type: MaterialType.transparency,
                  child: body(ctx),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute<FoEntityPickerOption>(
        fullscreenDialog: true,
        builder: (BuildContext ctx) => Material(
          color: ctx.foColors.bg,
          child: SafeArea(child: body(ctx)),
        ),
      ),
    );
  }
}

class _PickerBody extends StatefulWidget {
  const _PickerBody({
    required this.title,
    required this.search,
    required this.copy,
    required this.recent,
    required this.onScan,
    required this.likely,
    required this.scopes,
    required this.initialScope,
    required this.onScopeChanged,
    required this.noneLabel,
    required this.subtitle,
    required this.totalLabel,
  });

  final String title;
  final Future<List<FoEntityPickerOption>> Function(String query) search;
  final FoEntityPickerCopy copy;
  final List<FoEntityPickerOption> recent;
  final Future<FoEntityPickerOption?> Function()? onScan;
  final List<FoEntityPickerOption> likely;
  final List<FoLookupScope> scopes;
  final int initialScope;
  final ValueChanged<int>? onScopeChanged;
  final String? noneLabel;
  final String? subtitle;
  final String? Function(int shown, int? total)? totalLabel;

  @override
  State<_PickerBody> createState() => _PickerBodyState();
}

class _PickerBodyState extends State<_PickerBody> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  List<FoEntityPickerOption> _options = const <FoEntityPickerOption>[];
  bool _loading = true;
  bool _failed = false;
  String _query = '';
  late int _scope = widget.scopes.isEmpty
      ? 0
      : widget.initialScope.clamp(0, widget.scopes.length - 1);

  /// The keyboard's place in [_visible], on a wide window.
  int _active = 0;

  /// Each search is numbered, and only the newest one's answer is shown — a
  /// slow reply to "PO" must not overwrite a fast reply to "POLO".
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load([String query = '']) async {
    final int generation = ++_generation;
    setState(() {
      _loading = true;
      _failed = false;
      _query = query;
    });
    try {
      final List<FoEntityPickerOption> options = await widget.search(query);
      if (!mounted || generation != _generation) return;
      setState(() {
        _options = options;
        _loading = false;
        _active = 0;
      });
    } on Object catch (_) {
      // The failure itself is the app's to log; the picker's job is to say so
      // and stay usable, so the user can retype and try again.
      if (!mounted || generation != _generation) return;
      setState(() {
        _failed = true;
        _loading = false;
      });
    }
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(FoMotion.searchDebounce, () => _load(value.trim()));
  }

  void _onScopeChanged(int index) {
    setState(() => _scope = index);
    widget.onScopeChanged?.call(index);
    _debounce?.cancel();
    _load(_searchController.text.trim());
  }

  Future<void> _scan() async {
    final FoEntityPickerOption? option = await widget.onScan!();
    if (option == null || !mounted) return;
    Navigator.of(context).pop(option);
  }

  bool get _browsing => _query.isEmpty;

  List<FoEntityPickerOption> get _recent =>
      _browsing ? widget.recent : const <FoEntityPickerOption>[];

  /// Likely options not already listed as recent.
  List<FoEntityPickerOption> get _likely {
    if (!_browsing) return const <FoEntityPickerOption>[];
    final Set<String> seen = <String>{
      for (final FoEntityPickerOption o in widget.recent) o.id,
    };
    return <FoEntityPickerOption>[
      for (final FoEntityPickerOption o in widget.likely)
        if (!seen.contains(o.id)) o,
    ];
  }

  /// The search's own answer, without what the sections above already show.
  List<FoEntityPickerOption> get _results {
    if (_loading || _failed) return const <FoEntityPickerOption>[];
    if (!_browsing) return _options;
    final Set<String> seen = <String>{
      for (final FoEntityPickerOption o in widget.recent) o.id,
      for (final FoEntityPickerOption o in widget.likely) o.id,
    };
    return <FoEntityPickerOption>[
      for (final FoEntityPickerOption o in _options)
        if (!seen.contains(o.id)) o,
    ];
  }

  /// Every option on screen, in reading order — what the arrow keys walk.
  List<FoEntityPickerOption> get _visible => <FoEntityPickerOption>[
        ..._recent,
        ..._likely,
        ..._results,
      ];

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final List<FoEntityPickerOption> visible = _visible;
    if (visible.isEmpty) return KeyEventResult.ignored;
    final int count = visible.length;
    final LogicalKeyboardKey key = event.logicalKey;
    if (key == LogicalKeyboardKey.arrowDown) {
      setState(() => _active = (_active + 1) % count);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowUp) {
      setState(() => _active = (_active - 1 + count) % count);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter) {
      Navigator.of(context).pop(visible[_active.clamp(0, count - 1)]);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final bool wide = context.foWindowClass.isAtLeastMedium;
    final FoEntityPickerCopy copy = widget.copy;
    final List<FoEntityPickerOption> recent = _recent;
    final List<FoEntityPickerOption> likely = _likely;
    // Only a wide window has a keyboard highlight to show.
    int index = 0;
    Widget row(FoEntityPickerOption option) {
      final int mine = index++;
      return _OptionRow(option: option, active: wide && mine == _active);
    }

    final List<Widget> list = <Widget>[
      if (recent.isNotEmpty) ...<Widget>[
        if (copy.recentLabel != null) _SectionCaption(copy.recentLabel!),
        for (final FoEntityPickerOption option in recent) row(option),
        SizedBox(height: context.foSpacing.lg),
      ],
      if (likely.isNotEmpty) ...<Widget>[
        if (copy.likelyLabel != null) _SectionCaption(copy.likelyLabel!),
        for (final FoEntityPickerOption option in likely) row(option),
        SizedBox(height: context.foSpacing.lg),
      ],
      ..._resultWidgets(context, row),
    ];

    return Semantics(
      scopesRoute: true,
      namesRoute: true,
      label: widget.title,
      explicitChildNodes: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _header(context, wide),
          Padding(
            padding: EdgeInsets.fromLTRB(
              context.foSpacing.lg,
              context.foSpacing.sm,
              context.foSpacing.lg,
              context.foSpacing.sm,
            ),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Focus(
                    onKeyEvent: _onKey,
                    child: TextField(
                      controller: _searchController,
                      autofocus: true,
                      style: context.foText.body,
                      textInputAction: TextInputAction.search,
                      decoration: InputDecoration(
                        hintText: copy.searchHint,
                        prefixIcon: const Icon(Icons.search),
                        isDense: true,
                      ),
                      onChanged: _onQueryChanged,
                    ),
                  ),
                ),
                if (widget.onScan != null) ...<Widget>[
                  SizedBox(width: context.foSpacing.sm),
                  // A phone gives the search box the width and the scanner a
                  // named glyph; a labelled button beside a field at 200%
                  // text does not fit 390 points.
                  if (wide)
                    FoButton(
                      label: copy.scanLabel!,
                      variant: FoButtonVariant.secondary,
                      icon: Icons.qr_code_scanner,
                      onPressed: _scan,
                    )
                  else
                    FoIconButton(
                      icon: Icons.qr_code_scanner,
                      tone: FoIconButtonTone.primary,
                      semanticLabel: copy.scanLabel!,
                      onPressed: _scan,
                    ),
                ],
              ],
            ),
          ),
          if (widget.scopes.isNotEmpty)
            Padding(
              padding: EdgeInsets.fromLTRB(
                context.foSpacing.lg,
                0,
                context.foSpacing.lg,
                context.foSpacing.sm,
              ),
              child: FoStatusTabs(
                tabs: <FoStatusTab>[
                  for (final FoLookupScope scope in widget.scopes)
                    FoStatusTab(label: scope.label, count: scope.count),
                ],
                selectedIndex: _scope,
                onSelected: _onScopeChanged,
                semanticLabel: copy.scopesLabel ?? widget.title,
              ),
            ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                context.foSpacing.lg,
                context.foSpacing.sm,
                context.foSpacing.lg,
                context.foSpacing.xl,
              ),
              children: list,
            ),
          ),
          ..._footer(context, wide),
        ],
      ),
    );
  }

  Widget _header(BuildContext context, bool wide) {
    final String? subtitle = widget.subtitle;
    final Widget title = Semantics(
      header: true,
      child: Text(widget.title, style: context.foText.title),
    );
    return Padding(
      padding: EdgeInsets.fromLTRB(
        context.foSpacing.xs,
        context.foSpacing.xs,
        context.foSpacing.lg,
        0,
      ),
      child: Row(
        children: <Widget>[
          FoIconButton(
            icon: Icons.close,
            semanticLabel: widget.copy.closeLabel ??
                MaterialLocalizations.of(context).closeButtonTooltip,
            onPressed: () => Navigator.of(context).pop(),
          ),
          SizedBox(width: context.foSpacing.xs),
          Expanded(
            child: subtitle == null
                ? title
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      // Wide: what the choice is for names the dialog, so it
                      // is the caption over the title. Phone: a plain line
                      // under it, where a full screen has room to say it.
                      if (wide)
                        Text(
                          subtitle.toUpperCase(),
                          style: context.foText.caption,
                        ),
                      title,
                      if (!wide)
                        Text(
                          subtitle,
                          style: context.foText.body.copyWith(
                            color: context.foColors.fgMuted,
                          ),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  List<Widget> _footer(BuildContext context, bool wide) {
    final FoEntityPickerCopy copy = widget.copy;
    final List<(String, String)> hints = <(String, String)>[
      if (wide && copy.moveHint != null) ('↑ ↓', copy.moveHint!),
      if (wide && copy.chooseHint != null) ('Enter', copy.chooseHint!),
      if (wide && copy.closeHint != null) ('Esc', copy.closeHint!),
    ];
    final String? noneLabel = widget.noneLabel;
    if (hints.isEmpty && noneLabel == null) return const <Widget>[];

    final TextStyle hintStyle = context.foText.body.copyWith(
      fontSize: FoTokens.fontCaption,
      color: context.foColors.fgSubtle,
    );
    return <Widget>[
      DecoratedBox(
        decoration: BoxDecoration(color: context.foColors.surface),
        child: DecoratedBox(
          // Rule 1: the hairline is a foreground decoration.
          position: DecorationPosition.foreground,
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: context.foColors.edge)),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: context.foSpacing.lg,
              vertical: context.foSpacing.xs,
            ),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Wrap(
                    spacing: context.foSpacing.md,
                    runSpacing: context.foSpacing.xs,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: <Widget>[
                      for (final (String keys, String what) in hints)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            FoKeyHint(keys),
                            SizedBox(width: context.foSpacing.xs),
                            Text(what, style: hintStyle),
                          ],
                        ),
                    ],
                  ),
                ),
                if (noneLabel != null)
                  Flexible(
                    flex: 2,
                    child: FoButton(
                      label: noneLabel,
                      variant: FoButtonVariant.clear,
                      onPressed: () =>
                          Navigator.of(context).pop(FoLookupPicker.none),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    ];
  }

  List<Widget> _resultWidgets(
    BuildContext context,
    Widget Function(FoEntityPickerOption option) row,
  ) {
    if (_loading) {
      return <Widget>[
        Padding(
          padding: EdgeInsets.all(context.foSpacing.xl),
          child: const Center(child: FoSpinner(size: FoSpinnerSize.medium)),
        ),
      ];
    }
    if (_failed) {
      return <Widget>[
        FoInfoBanner.error(
          message: widget.copy.errorText,
          onRetry: widget.copy.retryLabel == null ? null : () => _load(_query),
          retryLabel: widget.copy.retryLabel,
        ),
      ];
    }
    final List<FoEntityPickerOption> results = _results;
    if (_options.isEmpty) {
      return <Widget>[
        Padding(
          padding: EdgeInsets.all(context.foSpacing.xl),
          child: Text(
            widget.copy.emptyText,
            textAlign: TextAlign.center,
            style: context.foText.body.copyWith(
              color: context.foColors.fgMuted,
            ),
          ),
        ),
      ];
    }
    final int? total =
        widget.scopes.isEmpty ? null : widget.scopes[_scope].count;
    final String? totalText = widget.totalLabel?.call(_visible.length, total);
    return <Widget>[
      if (results.isNotEmpty) ...<Widget>[
        if (_browsing && widget.copy.resultsLabel != null)
          _SectionCaption(widget.copy.resultsLabel!),
        for (final FoEntityPickerOption option in results) row(option),
      ],
      if (totalText != null)
        Padding(
          padding: EdgeInsets.symmetric(vertical: context.foSpacing.sm),
          child: Text(
            totalText,
            style: context.foText.body.copyWith(
              fontSize: FoTokens.fontLabel,
              color: context.foColors.fgSubtle,
            ),
          ),
        ),
    ];
  }
}

class _SectionCaption extends StatelessWidget {
  const _SectionCaption(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.only(
          top: context.foSpacing.sm,
          bottom: context.foSpacing.sm,
        ),
        child: Semantics(
          header: true,
          child: Text(text.toUpperCase(), style: context.foText.caption),
        ),
      );
}

/// One choice: a lifted card the whole of which is the target. The keyboard's
/// current choice carries the primary ring.
class _OptionRow extends StatelessWidget {
  const _OptionRow({required this.option, this.active = false});

  final FoEntityPickerOption option;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final Widget card = FoCard(
      onTap: () => Navigator.of(context).pop(option),
      semanticLabel: <String>[
        option.label,
        if (option.supportingText != null) option.supportingText!,
        if (option.meta != null) option.meta!,
      ].join(', '),
      padding: EdgeInsets.symmetric(
        horizontal: context.foSpacing.lg,
        vertical: context.foSpacing.md,
      ),
      child: ExcludeSemantics(
        child: Row(
          children: <Widget>[
            if (option.leading != null) ...<Widget>[
              option.leading!,
              SizedBox(width: context.foSpacing.md),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(option.label, style: context.foText.subtitle),
                  if (option.supportingText != null)
                    Text(
                      option.supportingText!,
                      style: context.foText.numeric.copyWith(
                        fontSize: FoTokens.fontCaption,
                        color: context.foColors.fgSubtle,
                      ),
                    ),
                ],
              ),
            ),
            if (option.meta != null) ...<Widget>[
              SizedBox(width: context.foSpacing.md),
              Flexible(
                child: Text(
                  option.meta!,
                  textAlign: TextAlign.end,
                  style: context.foText.body.copyWith(
                    color: context.foColors.fgMuted,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
    return Padding(
      padding: EdgeInsets.only(bottom: context.foSpacing.sm),
      child: Semantics(
        selected: active,
        child: !active
            ? card
            : DecoratedBox(
                // Rule 1: the ring is a foreground decoration, so the card's
                // own ground never paints over it.
                position: DecorationPosition.foreground,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(context.foRadii.card),
                  border: Border.all(color: context.foColors.primary, width: 2),
                ),
                child: card,
              ),
      ),
    );
  }
}

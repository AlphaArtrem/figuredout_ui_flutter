import 'dart:async';

import 'package:flutter/material.dart';

import '../primitives/fo_button.dart';
import '../primitives/fo_card.dart';
import '../primitives/fo_icon_button.dart';
import '../primitives/fo_overlay_surface.dart';
import '../primitives/fo_spinner.dart';
import '../theme/fo_context.dart';
import '../tokens/fo_layout.dart';
import '../tokens/fo_motion.dart';
import '../tokens/fo_tokens.dart';
import 'fo_form_presenter.dart';
import 'fo_form_scope.dart';
import 'fo_info_banner.dart';

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
                );
                if (option == null) return;
                controller.text = option.label;
                onSelected(option);
                if (context.mounted) FoFormScope.markDirty(context);
              },
      ),
    );
  }
}

/// The lookup picker itself: a search box, recent choices, server results as
/// the user types, and an optional scan button.
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
  static const Size dialogSize = Size(560, 600);

  /// Presents the picker. Resolves with the option picked, or null.
  static Future<FoEntityPickerOption?> show(
    BuildContext context, {
    required String title,
    required Future<List<FoEntityPickerOption>> Function(String query) search,
    required FoEntityPickerCopy copy,
    List<FoEntityPickerOption> recent = const <FoEntityPickerOption>[],
    Future<FoEntityPickerOption?> Function()? onScan,
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
  });

  final String title;
  final Future<List<FoEntityPickerOption>> Function(String query) search;
  final FoEntityPickerCopy copy;
  final List<FoEntityPickerOption> recent;
  final Future<FoEntityPickerOption?> Function()? onScan;

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

  Future<void> _scan() async {
    final FoEntityPickerOption? option = await widget.onScan!();
    if (option == null || !mounted) return;
    Navigator.of(context).pop(option);
  }

  @override
  Widget build(BuildContext context) {
    final bool showRecent = _query.isEmpty && widget.recent.isNotEmpty;

    return Semantics(
      scopesRoute: true,
      namesRoute: true,
      label: widget.title,
      explicitChildNodes: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
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
                  child: Semantics(
                    header: true,
                    child: Text(widget.title, style: context.foText.title),
                  ),
                ),
              ],
            ),
          ),
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
                  child: TextField(
                    controller: _searchController,
                    autofocus: true,
                    style: context.foText.body,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: widget.copy.searchHint,
                      prefixIcon: const Icon(Icons.search),
                      isDense: true,
                    ),
                    onChanged: _onQueryChanged,
                  ),
                ),
                if (widget.onScan != null) ...<Widget>[
                  SizedBox(width: context.foSpacing.sm),
                  FoButton(
                    label: widget.copy.scanLabel!,
                    variant: FoButtonVariant.secondary,
                    icon: Icons.qr_code_scanner,
                    onPressed: _scan,
                  ),
                ],
              ],
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
              children: <Widget>[
                if (showRecent) ...<Widget>[
                  if (widget.copy.recentLabel != null)
                    _SectionCaption(widget.copy.recentLabel!),
                  for (final FoEntityPickerOption option in widget.recent)
                    _OptionRow(option: option),
                  SizedBox(height: context.foSpacing.lg),
                ],
                ..._results(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _results(BuildContext context) {
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
    return <Widget>[
      if (_query.isEmpty && widget.copy.resultsLabel != null)
        _SectionCaption(widget.copy.resultsLabel!),
      for (final FoEntityPickerOption option in _options)
        _OptionRow(option: option),
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

/// One choice: a lifted card the whole of which is the target.
class _OptionRow extends StatelessWidget {
  const _OptionRow({required this.option});

  final FoEntityPickerOption option;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: context.foSpacing.sm),
      child: FoCard(
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
      ),
    );
  }
}

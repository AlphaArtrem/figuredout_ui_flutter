import 'dart:async';

import 'package:flutter/material.dart';

import '../primitives/fo_spinner.dart';
import '../theme/fo_context.dart';
import '../tokens/fo_layout.dart';
import '../tokens/fo_motion.dart';
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
  });

  /// The value that gets stored.
  final String id;

  /// What the user reads.
  final String label;

  /// A second line — a code, a location, whatever disambiguates two options
  /// with the same name.
  final String? supportingText;
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
    required this.discardCopy,
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

  /// The dismiss guard's copy, since the picker is a presented surface.
  final FoDiscardCopy discardCopy;
}

/// A field that picks one record out of many, by searching.
///
/// A dropdown stops working somewhere around thirty options; this is what
/// replaces it. It looks like a field and opens a searchable list.
///
/// The list goes through `FoFormPresenter` rather than `showModalBottomSheet`,
/// so it honours the same dialog-versus-sheet breakpoint as every other modal
/// instead of always being a sheet — a searchable list is worse as a sheet on
/// a desktop window than a dialog is on a phone.
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

  /// The height the option list asks for when the surface has room.
  static const double _listHeight = 420;

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
                final FoEntityPickerOption? option =
                    await FoFormPresenter.show<FoEntityPickerOption>(
                  context,
                  title: label,
                  maxWidth: 560,
                  maxHeight: _listHeight + 160,
                  discardCopy: copy.discardCopy,
                  // The list sizes itself against the surface's bounded
                  // height, so it cannot live inside the surface's own
                  // scroll view — it would get infinite height.
                  scrollable: false,
                  child: _PickerList(
                    label: label,
                    search: search,
                    copy: copy,
                    maxHeight: _listHeight,
                  ),
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

class _PickerList extends StatefulWidget {
  const _PickerList({
    required this.label,
    required this.search,
    required this.copy,
    required this.maxHeight,
  });

  final String label;
  final Future<List<FoEntityPickerOption>> Function(String query) search;
  final FoEntityPickerCopy copy;
  final double maxHeight;

  @override
  State<_PickerList> createState() => _PickerListState();
}

class _PickerListState extends State<_PickerList> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  List<FoEntityPickerOption> _options = const <FoEntityPickerOption>[];
  bool _loading = true;
  String? _error;

  static const Duration _debounceDelay = FoMotion.searchDebounce;

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
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final List<FoEntityPickerOption> options = await widget.search(query);
      if (!mounted) return;
      setState(() {
        _options = options;
        _loading = false;
      });
    } on Object catch (_) {
      // The failure itself is the app's to log; the picker's job is to say so
      // and stay usable, so the user can retype and try again.
      if (!mounted) return;
      setState(() {
        _error = widget.copy.errorText;
        _loading = false;
      });
    }
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(_debounceDelay, () => _load(value));
  }

  @override
  Widget build(BuildContext context) {
    // Bounded rather than fixed: the presenting surface may have less room
    // than this on a short screen, and the list still needs a bound to scroll
    // inside.
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: widget.maxHeight),
      child: SizedBox(
        width: double.infinity,
        child: Column(
          children: <Widget>[
            Padding(
              padding: EdgeInsets.fromLTRB(
                context.foSpacing.lg,
                context.foSpacing.md,
                context.foSpacing.lg,
                context.foSpacing.sm,
              ),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                style: context.foText.body,
                decoration: InputDecoration(
                  labelText: widget.label,
                  hintText: widget.copy.searchHint,
                  prefixIcon: const Icon(Icons.search),
                  isDense: true,
                ),
                onChanged: _onQueryChanged,
              ),
            ),
            if (_error != null)
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: context.foSpacing.lg,
                ),
                child: FoInfoBanner.error(message: _error),
              ),
            Expanded(child: _body(context)),
          ],
        ),
      ),
    );
  }

  Widget _body(BuildContext context) {
    if (_loading) {
      return const Center(child: FoSpinner(size: FoSpinnerSize.medium));
    }
    if (_options.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(context.foSpacing.xl),
          child: Text(
            widget.copy.emptyText,
            textAlign: TextAlign.center,
            style: context.foText.body.copyWith(
              color: context.foColors.fgMuted,
            ),
          ),
        ),
      );
    }

    return ListView.separated(
      itemCount: _options.length,
      separatorBuilder: (BuildContext context, int index) => Divider(
        height: FoLayout.hairlineWidth,
        thickness: FoLayout.hairlineWidth,
        color: context.foColors.edge,
      ),
      itemBuilder: (BuildContext context, int index) {
        final FoEntityPickerOption option = _options[index];
        return ListTile(
          // A 48dp row, so a gloved finger can hit one option and not two.
          minTileHeight: FoLayout.minTouchTarget,
          title: Text(option.label, style: context.foText.body),
          subtitle: option.supportingText == null
              ? null
              : Text(option.supportingText!, style: context.foText.caption),
          onTap: () => Navigator.of(context).pop(option),
        );
      },
    );
  }
}

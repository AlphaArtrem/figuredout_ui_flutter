import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../primitives/fo_button.dart';
import '../primitives/fo_icon_button.dart';
import '../primitives/fo_key_hint.dart';
import '../primitives/fo_overlay_surface.dart';
import '../primitives/fo_spinner.dart';
import '../theme/fo_context.dart';
import '../tokens/fo_motion.dart';
import '../tokens/fo_tokens.dart';
import 'fo_info_banner.dart';
import 'fo_status_tabs.dart';

/// One hit in a [FoSearchPalette].
@immutable
class FoSearchResult {
  /// Creates a result.
  const FoSearchResult({
    required this.title,
    required this.onSelected,
    this.subtitle,
    this.icon,
    this.leading,
    this.trailing,
  });

  /// "Heavyweight Crew Tee". Caller-supplied.
  final String title;

  /// "JOB-2026-10031 · Kestrel Outfitters".
  final String? subtitle;

  /// The kind of thing — a box for an order, a person for a person.
  final IconData? icon;

  /// Instead of [icon] — a `FoAvatar`.
  final Widget? leading;

  /// A status chip.
  final Widget? trailing;

  /// Opens it. The palette closes first.
  final VoidCallback onSelected;
}

/// One kind of thing in a [FoSearchPalette]'s results — orders, entries,
/// people.
@immutable
class FoSearchGroup {
  /// Creates a group.
  const FoSearchGroup({
    required this.title,
    required this.results,
    this.qualifier,
    this.seeAllLabel,
    this.onSeeAll,
    this.emptyText,
    this.total,
  }) : assert(total == null || total >= 0, 'a count is not negative');

  /// "Orders". Caller-supplied.
  final String title;

  /// "newest first".
  final String? qualifier;

  /// The first few hits.
  final List<FoSearchResult> results;

  /// "See all 24 entries for "crew"". Shown with [onSeeAll].
  final String? seeAllLabel;

  /// Opens the full list.
  final VoidCallback? onSeeAll;

  /// Why the group is empty — "No people match. Search by first name." An
  /// empty group with no reason is hidden.
  final String? emptyText;

  /// How many hits the group has in all, of which [results] are the first
  /// few — "Entries 24". The count on the group's type tab, and its share of
  /// "Everything". Null counts [results].
  final int? total;

  int get _count => total ?? results.length;

  bool get _shown => results.isNotEmpty || emptyText != null;
}

/// The words a [FoSearchPalette] needs.
@immutable
class FoSearchPaletteCopy {
  /// Creates the copy.
  const FoSearchPaletteCopy({
    required this.fieldLabel,
    required this.closeLabel,
    required this.noResultsText,
    required this.errorText,
    required this.retryLabel,
    this.hint,
    this.recentLabel,
    this.scanLabel,
    this.moveHint,
    this.openHint,
    this.footerNote,
    this.everythingLabel,
    this.typesLabel,
  });

  /// "Search orders, entries, people".
  final String fieldLabel;

  /// "Close search".
  final String closeLabel;

  /// "Nothing matches "crew"." — given the query.
  final String Function(String query) noResultsText;

  /// "Couldn't search. Check the connection."
  final String errorText;

  /// "Try again".
  final String retryLabel;

  /// Placeholder in the box.
  final String? hint;

  /// "Recent searches".
  final String? recentLabel;

  /// "Scan a code".
  final String? scanLabel;

  /// "move" — beside the ↑ ↓ key hint.
  final String? moveHint;

  /// "open" — beside the Enter key hint.
  final String? openHint;

  /// "Codes work too: 10031, PRS-415".
  final String? footerNote;

  /// "Everything" — the first type tab. Setting it turns the type tabs on:
  /// "Everything 26 · Orders 1 · Entries 24 …", one tab per group with
  /// something to show, each with its [FoSearchGroup.total], filtering the
  /// results in place. Shown when a search returns two or more groups.
  final String? everythingLabel;

  /// What the type tabs choose — "Show". Read before the tabs; falls back to
  /// [fieldLabel].
  final String? typesLabel;
}

/// Search everything from one box — the Ctrl K palette on a wide window, a
/// full-screen search on a phone.
///
/// Results come back grouped by kind, a few of each, with "See all" for the
/// rest; a group with no hits can say why. On a wide window the arrow keys
/// move through every hit across groups and Enter opens the highlighted one,
/// with the keys shown in the footer. The search runs on the caller's
/// server, debounced, and only the newest query's answer is ever shown; a
/// failed search says so with a retry, and never shows as "nothing found".
/// `recentSearches` fill the empty box.
abstract final class FoSearchPalette {
  /// Opens the palette.
  static Future<void> show(
    BuildContext context, {
    required Future<List<FoSearchGroup>> Function(String query) search,
    required FoSearchPaletteCopy copy,
    List<String> recentSearches = const <String>[],
    VoidCallback? onScan,
  }) {
    Widget body(BuildContext ctx) => _Palette(
          search: search,
          copy: copy,
          recent: recentSearches,
          onScan: onScan,
        );
    if (context.foWindowClass.isAtLeastMedium) {
      return showDialog<void>(
        context: context,
        builder: (BuildContext ctx) => Align(
          alignment: const Alignment(0, -0.6),
          child: Padding(
            padding: EdgeInsets.all(ctx.foSpacing.xl),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760, maxHeight: 680),
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
        ),
      );
    }
    return Navigator.of(context, rootNavigator: true).push<void>(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (BuildContext ctx) => Material(
          color: ctx.foColors.bg,
          child: SafeArea(child: body(ctx)),
        ),
      ),
    );
  }
}

class _Palette extends StatefulWidget {
  const _Palette({
    required this.search,
    required this.copy,
    required this.recent,
    required this.onScan,
  });

  final Future<List<FoSearchGroup>> Function(String query) search;
  final FoSearchPaletteCopy copy;
  final List<String> recent;
  final VoidCallback? onScan;

  @override
  State<_Palette> createState() => _PaletteState();
}

class _PaletteState extends State<_Palette> {
  final TextEditingController _query = TextEditingController();
  final FocusNode _focus = FocusNode();
  Timer? _debounce;
  List<FoSearchGroup> _groups = const <FoSearchGroup>[];
  bool _loading = false;
  bool _failed = false;
  int _active = 0;
  int _generation = 0;

  /// The type tab in force, by group title; null is "Everything". Kept
  /// across searches while the new answer still has that group.
  String? _type;

  /// The groups with something to show — a hit, or a reason for none.
  List<FoSearchGroup> get _shownGroups =>
      _groups.where((FoSearchGroup g) => g._shown).toList();

  bool get _hasTypeTabs =>
      widget.copy.everythingLabel != null && _shownGroups.length >= 2;

  /// The groups the current type tab lets through.
  List<FoSearchGroup> get _filtered {
    final List<FoSearchGroup> shown = _shownGroups;
    if (!_hasTypeTabs || _type == null) return shown;
    return shown.where((FoSearchGroup g) => g.title == _type).toList();
  }

  List<FoSearchResult> get _flat => <FoSearchResult>[
        for (final FoSearchGroup g in _filtered) ...g.results,
      ];

  @override
  void dispose() {
    _debounce?.cancel();
    _query.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _changed(String q) {
    _debounce?.cancel();
    if (q.trim().isEmpty) {
      _generation++;
      setState(() {
        _groups = const <FoSearchGroup>[];
        _loading = false;
        _failed = false;
      });
      return;
    }
    _debounce = Timer(FoMotion.searchDebounce, () => _run(q.trim()));
  }

  Future<void> _run(String q) async {
    final int generation = ++_generation;
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      final List<FoSearchGroup> groups = await widget.search(q);
      if (!mounted || generation != _generation) return;
      setState(() {
        _groups = groups;
        _loading = false;
        _active = 0;
        if (!groups.any((FoSearchGroup g) => g.title == _type && g._shown)) {
          _type = null;
        }
      });
    } on Object catch (_) {
      // Logged by the caller's search; here it is said, with a retry.
      if (!mounted || generation != _generation) return;
      setState(() {
        _failed = true;
        _loading = false;
      });
    }
  }

  void _open(FoSearchResult r) {
    Navigator.of(context).pop();
    r.onSelected();
  }

  KeyEventResult _key(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final int count = _flat.length;
    if (count == 0) return KeyEventResult.ignored;
    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      setState(() => _active = (_active + 1) % count);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      setState(() => _active = (_active - 1 + count) % count);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.enter) {
      _open(_flat[_active.clamp(0, count - 1)]);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final FoSearchPaletteCopy copy = widget.copy;
    final bool wide = context.foWindowClass.isAtLeastMedium;
    final String q = _query.text.trim();

    final Widget field = Focus(
      onKeyEvent: _key,
      child: TextField(
        controller: _query,
        focusNode: _focus,
        autofocus: true,
        style: context.foText.subtitle,
        textInputAction: TextInputAction.search,
        onChanged: _changed,
        decoration: InputDecoration(
          labelText: copy.fieldLabel,
          floatingLabelBehavior: FloatingLabelBehavior.never,
          hintText: copy.hint,
          prefixIcon: const Icon(Icons.search),
        ),
      ),
    );

    final List<Widget> body = <Widget>[];
    if (q.isEmpty) {
      if (widget.recent.isNotEmpty && copy.recentLabel != null) {
        body.add(_Caption(copy.recentLabel!));
        body.add(
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: <Widget>[
                for (final String r in widget.recent) ...<Widget>[
                  SizedBox(width: context.foSpacing.xs),
                  FoButton(
                    label: r,
                    variant: FoButtonVariant.secondary,
                    icon: Icons.history,
                    onPressed: () {
                      _query.text = r;
                      _run(r);
                    },
                  ),
                ],
              ],
            ),
          ),
        );
      }
    } else if (_loading) {
      body.add(
        Padding(
          padding: EdgeInsets.all(context.foSpacing.xl),
          child: const Center(child: FoSpinner(size: FoSpinnerSize.medium)),
        ),
      );
    } else if (_failed) {
      body.add(
        FoInfoBanner.error(
          message: copy.errorText,
          onRetry: () => _run(q),
          retryLabel: copy.retryLabel,
        ),
      );
    } else if (_groups.every(
      (FoSearchGroup g) => g.results.isEmpty && g.emptyText == null,
    )) {
      body.add(
        Padding(
          padding: EdgeInsets.all(context.foSpacing.xl),
          child: Text(
            copy.noResultsText(q),
            textAlign: TextAlign.center,
            style:
                context.foText.body.copyWith(color: context.foColors.fgMuted),
          ),
        ),
      );
    } else {
      int index = 0;
      for (final FoSearchGroup g in _filtered) {
        body.add(
          _Caption(
              g.qualifier == null ? g.title : '${g.title} · ${g.qualifier}'),
        );
        if (g.results.isEmpty) {
          body.add(
            Text(
              g.emptyText!,
              style: context.foText.body.copyWith(
                color: context.foColors.fgMuted,
              ),
            ),
          );
        }
        for (final FoSearchResult r in g.results) {
          final int mine = index++;
          body.add(
            _ResultRow(
              result: r,
              active: wide && mine == _active,
              onTap: () => _open(r),
            ),
          );
        }
        if (g.onSeeAll != null && g.seeAllLabel != null) {
          body.add(
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: FoButton(
                label: g.seeAllLabel!,
                variant: FoButtonVariant.clear,
                trailingIcon: Icons.arrow_forward,
                onPressed: () {
                  Navigator.of(context).pop();
                  g.onSeeAll!();
                },
              ),
            ),
          );
        }
      }
    }

    return Semantics(
      scopesRoute: true,
      namesRoute: true,
      label: copy.fieldLabel,
      explicitChildNodes: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: EdgeInsets.all(context.foSpacing.md),
            child: Row(
              children: <Widget>[
                if (!wide)
                  FoIconButton(
                    icon: Icons.arrow_back,
                    semanticLabel: copy.closeLabel,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                Expanded(child: field),
                if (widget.onScan != null &&
                    copy.scanLabel != null) ...<Widget>[
                  SizedBox(width: context.foSpacing.sm),
                  FoIconButton(
                    icon: Icons.qr_code_scanner,
                    tone: FoIconButtonTone.primary,
                    semanticLabel: copy.scanLabel!,
                    onPressed: () {
                      Navigator.of(context).pop();
                      widget.onScan!();
                    },
                  ),
                ],
                if (wide) ...<Widget>[
                  SizedBox(width: context.foSpacing.sm),
                  FoIconButton(
                    icon: Icons.close,
                    semanticLabel: copy.closeLabel,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ],
            ),
          ),
          if (q.isNotEmpty && !_loading && !_failed && _hasTypeTabs)
            _typeTabs(context),
          Flexible(
            child: Semantics(
              liveRegion: true,
              child: ListView(
                shrinkWrap: true,
                padding: EdgeInsets.fromLTRB(
                  context.foSpacing.lg,
                  0,
                  context.foSpacing.lg,
                  context.foSpacing.lg,
                ),
                children: body,
              ),
            ),
          ),
          if (wide)
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: context.foSpacing.lg,
                vertical: context.foSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: context.foColors.surface,
                border: Border(top: BorderSide(color: context.foColors.edge)),
              ),
              child: Wrap(
                spacing: context.foSpacing.md,
                runSpacing: context.foSpacing.xs,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: <Widget>[
                  if (copy.moveHint != null) ...<Widget>[
                    const FoKeyHint('↑ ↓'),
                    Text(copy.moveHint!, style: _hintStyle(context)),
                  ],
                  if (copy.openHint != null) ...<Widget>[
                    const FoKeyHint('Enter'),
                    Text(copy.openHint!, style: _hintStyle(context)),
                  ],
                  if (copy.footerNote != null)
                    Text(copy.footerNote!, style: _hintStyle(context)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// "Everything 26 · Orders 1 · Entries 24 …" — one row that scrolls
  /// sideways, filtering the groups in place.
  Widget _typeTabs(BuildContext context) {
    final List<FoSearchGroup> shown = _shownGroups;
    final int current =
        _type == null ? 0 : 1 + shown.indexWhere((g) => g.title == _type);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        context.foSpacing.lg,
        0,
        context.foSpacing.lg,
        context.foSpacing.sm,
      ),
      child: FoStatusTabs(
        tabs: <FoStatusTab>[
          FoStatusTab(
            label: widget.copy.everythingLabel!,
            count: shown.fold<int>(0, (int sum, g) => sum + g._count),
          ),
          for (final FoSearchGroup g in shown)
            FoStatusTab(label: g.title, count: g._count),
        ],
        selectedIndex: current,
        onSelected: (int i) => setState(() {
          _type = i == 0 ? null : shown[i - 1].title;
          _active = 0;
        }),
        semanticLabel: widget.copy.typesLabel ?? widget.copy.fieldLabel,
      ),
    );
  }

  TextStyle _hintStyle(BuildContext context) => context.foText.body.copyWith(
        fontSize: FoTokens.fontCaption,
        color: context.foColors.fgSubtle,
      );
}

class _Caption extends StatelessWidget {
  const _Caption(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.only(
          top: context.foSpacing.md,
          bottom: context.foSpacing.sm,
        ),
        child: Semantics(
          header: true,
          child: Text(text.toUpperCase(), style: context.foText.caption),
        ),
      );
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({
    required this.result,
    required this.active,
    required this.onTap,
  });

  final FoSearchResult result;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final BorderRadius radius = BorderRadius.circular(context.foRadii.md);
    return Semantics(
      button: true,
      selected: active,
      label: result.subtitle == null
          ? result.title
          : '${result.title}, ${result.subtitle}',
      onTap: onTap,
      excludeSemantics: true,
      child: Material(
        color: active ? context.foColors.primarySoft : Colors.transparent,
        borderRadius: radius,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: Container(
            constraints: const BoxConstraints(minHeight: 56),
            padding: EdgeInsets.symmetric(
              horizontal: context.foSpacing.sm,
              vertical: context.foSpacing.xs,
            ),
            foregroundDecoration: active
                ? BoxDecoration(
                    borderRadius: radius,
                    border: Border.all(color: context.foColors.primary),
                  )
                : null,
            child: Row(
              children: <Widget>[
                result.leading ??
                    Container(
                      width: 36,
                      height: 36,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: active
                            ? context.foColors.surfaceRaised
                            : context.foColors.surfaceSunken,
                        borderRadius: BorderRadius.circular(context.foRadii.md),
                      ),
                      child: Icon(
                        result.icon ?? Icons.description_outlined,
                        size: FoTokens.iconSmall,
                        color: context.foColors.fgMuted,
                      ),
                    ),
                SizedBox(width: context.foSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(result.title, style: context.foText.label),
                      if (result.subtitle != null)
                        Text(
                          result.subtitle!,
                          style: context.foText.body.copyWith(
                            fontSize: FoTokens.fontLabel,
                            color: context.foColors.fgMuted,
                          ),
                        ),
                    ],
                  ),
                ),
                if (result.trailing != null) ...<Widget>[
                  SizedBox(width: context.foSpacing.sm),
                  result.trailing!,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

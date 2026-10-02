import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../theme/fo_context.dart';

/// A list's search and filters, in one row that never wraps.
///
/// The search box takes whatever width the filters leave, down to
/// [searchMinWidth]; below that the whole row scrolls sideways rather than
/// dropping a filter onto a line of its own — a lone dropdown under a search
/// box reads as a different control, and the list beneath jumps every time
/// the filter's value changes length. The filters keep their own widths.
///
/// `FoScaffold` and `FoFilterBar` lay their controls out with this; use it
/// directly for a list page that builds its own header.
class FoToolbar extends StatelessWidget {
  /// Creates a toolbar.
  const FoToolbar({
    this.search,
    this.filters = const <Widget>[],
    this.searchMinWidth = 220,
    super.key,
  });

  /// The search field. Flexible.
  final Widget? search;

  /// Filter buttons or dropdowns, in order. Each keeps its own width.
  final List<Widget> filters;

  /// The narrowest the search box may get before the row scrolls instead.
  final double searchMinWidth;

  @override
  Widget build(BuildContext context) {
    final double gap = context.foSpacing.sm;
    final Widget filterRow = Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (int i = 0; i < filters.length; i++) ...<Widget>[
          if (i > 0) SizedBox(width: gap),
          filters[i],
        ],
      ],
    );

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double available =
            constraints.hasBoundedWidth ? constraints.maxWidth : searchMinWidth;
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: _ToolbarRow(
            available: available,
            searchMinWidth: search == null ? 0 : searchMinWidth,
            gap: search == null || filters.isEmpty ? 0 : gap,
            children: <Widget>[search ?? const SizedBox.shrink(), filterRow],
          ),
        );
      },
    );
  }
}

/// Lays the filters out first at their own width, then gives the search
/// what is left — never less than its minimum — so the row is exactly as
/// wide as the window when it fits, and wider (scrolling) when it does not.
class _ToolbarRow extends MultiChildRenderObjectWidget {
  const _ToolbarRow({
    required this.available,
    required this.searchMinWidth,
    required this.gap,
    required super.children,
  });

  final double available;
  final double searchMinWidth;
  final double gap;

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderToolbarRow(
        available: available,
        searchMinWidth: searchMinWidth,
        gap: gap,
      );

  @override
  void updateRenderObject(
      BuildContext context, _RenderToolbarRow renderObject) {
    renderObject
      ..available = available
      ..searchMinWidth = searchMinWidth
      ..gap = gap;
  }
}

class _ToolbarParentData extends ContainerBoxParentData<RenderBox> {}

class _RenderToolbarRow extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _ToolbarParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _ToolbarParentData> {
  _RenderToolbarRow({
    required double available,
    required double searchMinWidth,
    required double gap,
  })  : _available = available,
        _searchMinWidth = searchMinWidth,
        _gap = gap;

  double _available;
  set available(double v) {
    if (v == _available) return;
    _available = v;
    markNeedsLayout();
  }

  double _searchMinWidth;
  set searchMinWidth(double v) {
    if (v == _searchMinWidth) return;
    _searchMinWidth = v;
    markNeedsLayout();
  }

  double _gap;
  set gap(double v) {
    if (v == _gap) return;
    _gap = v;
    markNeedsLayout();
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _ToolbarParentData) {
      child.parentData = _ToolbarParentData();
    }
  }

  @override
  void performLayout() {
    final RenderBox search = firstChild!;
    final RenderBox filters = childAfter(search)!;
    final BoxConstraints height =
        BoxConstraints(maxHeight: constraints.maxHeight);

    filters.layout(height, parentUsesSize: true);
    final double fw = filters.size.width;
    final double sw = _searchMinWidth == 0
        ? 0
        : math.max(_searchMinWidth, _available - fw - _gap);
    search.layout(height.tighten(width: sw), parentUsesSize: true);

    final double h = math.max(search.size.height, filters.size.height);
    (search.parentData! as _ToolbarParentData).offset =
        Offset(0, (h - search.size.height) / 2);
    (filters.parentData! as _ToolbarParentData).offset =
        Offset(sw + _gap, (h - filters.size.height) / 2);
    size = constraints.constrain(Size(sw + _gap + fw, h));
  }

  @override
  void paint(PaintingContext context, Offset offset) =>
      defaultPaint(context, offset);

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      defaultHitTestChildren(result, position: position);
}

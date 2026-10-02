import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../primitives/fo_card.dart';
import '../theme/fo_context.dart';
import '../tokens/fo_layout.dart';
import 'fo_form_scope.dart';

/// The frame a presented form lives in: header, scrolling body, pinned footer.
///
/// The footer is the reason this exists. A long form's Save button, declared at
/// the end of the body, scrolls out of reach exactly when the user is ready to
/// press it. `FoFormActions` hoists itself up here instead, so the form still
/// *reads* bottom-to-top while the action stays put.
///
/// It sits on `surfaceRaised` (via [FoCardTone.raised]) because a presented
/// form covers the page. The header rule and the footer rule are full-bleed
/// children, which is exactly the case rule §3.1 covers — `FoCard` keeps its
/// hairline on top of them.
///
/// **When the header and footer alone do not leave the body room, the whole
/// surface scrolls instead.** At 300% text on a phone a title and a subtitle
/// can be taller than the screen. A column with only the body flexible then
/// overflowed by the difference, and a sheet's own primary action sat below
/// the bottom edge where nobody could press it. The header and footer are now
/// measured first: while they leave the body a third of the height (or all it
/// needs), nothing changes — pinned header, scrolling body, pinned footer.
/// Otherwise header, body and footer scroll as one, so every part is reachable.
class FoFormSurface extends StatefulWidget {
  /// Creates a form surface.
  const FoFormSurface({
    required this.title,
    required this.child,
    this.subtitle,
    this.footer,
    this.onClose,
    this.controller,
    this.scrollable = true,
    super.key,
  });

  /// The form's name. Caller-supplied, so it can be localized.
  final String title;

  /// A line under the title.
  final String? subtitle;

  /// The form body.
  final Widget child;

  /// An explicit pinned footer. When null the surface renders whatever the
  /// body published through [FoFormController.footer].
  final Widget? footer;

  /// Shows a close affordance. The caller decides what closing means —
  /// `FoFormPresenter` routes it through the dirty-form guard.
  final VoidCallback? onClose;

  /// Shared footer/dirty state. Supply one when something above the surface
  /// needs to read the same flags; otherwise the surface owns a private one.
  final FoFormController? controller;

  /// When false the child owns its own scrolling and padding.
  ///
  /// Needed by a body that sizes itself against the surface's bounded height —
  /// a picker list, say — which cannot live inside a scroll view. It is given
  /// the height left under the header and above the footer, or one full
  /// viewport when those two alone do not leave it room.
  final bool scrollable;

  @override
  State<FoFormSurface> createState() => _FoFormSurfaceState();
}

class _FoFormSurfaceState extends State<FoFormSurface> {
  FoFormController? _ownController;

  FoFormController get _controller =>
      widget.controller ?? (_ownController ??= FoFormController());

  @override
  void dispose() {
    _ownController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Widget body = FoFormScope(
      controller: _controller,
      child: widget.scrollable
          ? SingleChildScrollView(
              padding: EdgeInsets.all(context.foSpacing.xl),
              child: widget.child,
            )
          : widget.child,
    );

    final Widget header = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Padding(
          padding: EdgeInsets.fromLTRB(
            context.foSpacing.xl,
            context.foSpacing.xl,
            widget.onClose == null
                ? context.foSpacing.xl
                : context.foSpacing.sm,
            context.foSpacing.lg,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Semantics(
                      header: true,
                      child: Text(
                        widget.title,
                        style: context.foText.title,
                      ),
                    ),
                    if (widget.subtitle?.trim().isNotEmpty ?? false) ...[
                      SizedBox(height: context.foSpacing.xs),
                      Text(
                        widget.subtitle!,
                        style: context.foText.body.copyWith(
                          color: context.foColors.fgMuted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (widget.onClose != null)
                IconButton(
                  icon: const Icon(Icons.close),
                  // Material's own localized copy: no app string is needed
                  // for the one control every dialog and sheet already has.
                  tooltip: MaterialLocalizations.of(
                    context,
                  ).closeButtonTooltip,
                  onPressed: widget.onClose,
                ),
            ],
          ),
        ),
        _rule(context),
      ],
    );

    return FoCard(
      tone: FoCardTone.raised,
      padding: EdgeInsets.zero,
      child: LayoutBuilder(
        // Scrolls only in the fallback. While the parts fit, the content is
        // no taller than the viewport and there is nothing to drag, so the
        // body's own scroll view is the one a finger moves. A shrink-wrapping
        // sliver list rather than a second SingleChildScrollView, so the body
        // stays the surface's one SingleChildScrollView for anything that
        // looks for it.
        builder: (BuildContext context, BoxConstraints constraints) =>
            CustomScrollView(
          primary: false,
          shrinkWrap: true,
          slivers: <Widget>[
            SliverToBoxAdapter(
              child: _SurfaceLayout(
                availableHeight: constraints.maxHeight,
                bodyScrolls: widget.scrollable,
                children: <Widget>[
                  header,
                  body,
                  _Footer(
                    controller: _controller,
                    explicitFooter: widget.footer,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _rule(BuildContext context) => Divider(
      height: FoLayout.hairlineWidth,
      thickness: FoLayout.hairlineWidth,
      color: context.foColors.edge,
    );

/// The pinned action row: the caller's explicit footer if there is one,
/// otherwise whatever the body hoisted out of its scroll area.
class _Footer extends StatelessWidget {
  const _Footer({required this.controller, required this.explicitFooter});

  final FoFormController controller;
  final Widget? explicitFooter;

  @override
  Widget build(BuildContext context) {
    if (explicitFooter != null) return _wrap(context, explicitFooter!);

    return ValueListenableBuilder<Widget?>(
      valueListenable: controller.footer,
      builder: (BuildContext context, Widget? hoisted, _) =>
          hoisted == null ? const SizedBox.shrink() : _wrap(context, hoisted),
    );
  }

  Widget _wrap(BuildContext context, Widget child) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _rule(context),
          Padding(
            padding: EdgeInsets.all(context.foSpacing.xl),
            child: child,
          ),
        ],
      );
}

/// Header, body and footer, stacked — with the body given what is left.
///
/// A `Column` cannot do this: it has no way to say "if the fixed parts do not
/// fit, stop pinning them". This measures the header and the footer at their
/// natural heights first. While they leave the body enough room
/// ([_SurfaceLayout.minBodyFraction] of the height, or the body's whole
/// natural height if that is less), the body is laid out in what remains and
/// scrolls itself — the ordinary form. Otherwise every part takes its natural
/// height (a body that owns its own scrolling gets one full viewport) and the
/// enclosing scroll view scrolls the lot.
class _SurfaceLayout extends MultiChildRenderObjectWidget {
  const _SurfaceLayout({
    required this.availableHeight,
    required this.bodyScrolls,
    required super.children,
  }) : assert(children.length == 3, 'header, body, footer');

  /// The height the surface was given, read outside the scroll view.
  final double availableHeight;

  /// Whether the body is the surface's own scroll view, and so can be
  /// measured at its natural height. A body that owns its scrolling — a
  /// picker list — cannot.
  final bool bodyScrolls;

  /// The share of the height the body must be left for the header and the
  /// footer to stay pinned.
  static const double minBodyFraction = 1 / 3;

  @override
  _RenderSurfaceLayout createRenderObject(BuildContext context) =>
      _RenderSurfaceLayout(
        availableHeight: availableHeight,
        bodyScrolls: bodyScrolls,
      );

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderSurfaceLayout renderObject,
  ) {
    renderObject
      ..availableHeight = availableHeight
      ..bodyScrolls = bodyScrolls;
  }
}

class _SurfaceParentData extends ContainerBoxParentData<RenderBox> {}

/// Lays a child out (or only measures it) and returns its size.
typedef _Sizer = Size Function(RenderBox child, BoxConstraints constraints);

class _RenderSurfaceLayout extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _SurfaceParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _SurfaceParentData> {
  _RenderSurfaceLayout({
    required double availableHeight,
    required bool bodyScrolls,
  })  : _availableHeight = availableHeight,
        _bodyScrolls = bodyScrolls;

  double _availableHeight;
  set availableHeight(double value) {
    if (value == _availableHeight) return;
    _availableHeight = value;
    markNeedsLayout();
  }

  bool _bodyScrolls;
  set bodyScrolls(bool value) {
    if (value == _bodyScrolls) return;
    _bodyScrolls = value;
    markNeedsLayout();
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _SurfaceParentData) {
      child.parentData = _SurfaceParentData();
    }
  }

  RenderBox get _header => firstChild!;
  RenderBox get _body => childAfter(_header)!;
  RenderBox get _footer => lastChild!;

  /// The header's, the body's and the footer's heights at [width].
  ///
  /// The body's constraints are decided last, so with a laying-out [size] the
  /// body ends up laid out with the constraints it is painted at.
  (double, double, double) _heights(double width, _Sizer size) {
    final BoxConstraints natural = BoxConstraints.tightFor(width: width);
    final double header = size(_header, natural).height;
    final double footer = size(_footer, natural).height;
    final double available = _availableHeight;
    if (!available.isFinite) {
      return (header, size(_body, natural).height, footer);
    }

    final double left = available - header - footer;
    final double floor = available * _SurfaceLayout.minBodyFraction;
    // Only a body this surface scrolls can be asked for its natural height;
    // a list that owns its scrolling would take whatever it is offered.
    final double needed =
        _bodyScrolls ? math.min(size(_body, natural).height, floor) : floor;

    if (left >= needed) {
      // The ordinary form: pinned header and footer, the body in between.
      final BoxConstraints rest = BoxConstraints(
        minWidth: width,
        maxWidth: width,
        maxHeight: left,
      );
      return (header, size(_body, rest).height, footer);
    }

    // The fallback: every part at its natural height, scrolled as one. A body
    // that scrolls itself is given one viewport, which is room to use it.
    final BoxConstraints body = _bodyScrolls
        ? natural
        : BoxConstraints.tightFor(width: width, height: available);
    return (header, size(_body, body).height, footer);
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    final (double h, double b, double f) = _heights(
      constraints.maxWidth,
      (RenderBox child, BoxConstraints c) => child.getDryLayout(c),
    );
    return constraints.constrain(Size(constraints.maxWidth, h + b + f));
  }

  @override
  void performLayout() {
    final double width = constraints.maxWidth;
    final (double h, double b, double f) = _heights(
      width,
      (RenderBox child, BoxConstraints c) {
        child.layout(c, parentUsesSize: true);
        return child.size;
      },
    );
    (_header.parentData! as _SurfaceParentData).offset = Offset.zero;
    (_body.parentData! as _SurfaceParentData).offset = Offset(0, h);
    (_footer.parentData! as _SurfaceParentData).offset = Offset(0, h + b);
    size = constraints.constrain(Size(width, h + b + f));
  }

  @override
  double computeMinIntrinsicWidth(double height) =>
      _fold((RenderBox c) => c.getMinIntrinsicWidth(double.infinity), math.max);

  @override
  double computeMaxIntrinsicWidth(double height) =>
      _fold((RenderBox c) => c.getMaxIntrinsicWidth(double.infinity), math.max);

  @override
  double computeMinIntrinsicHeight(double width) => _fold(
        (RenderBox c) => c.getMinIntrinsicHeight(width),
        (double a, double b) => a + b,
      );

  @override
  double computeMaxIntrinsicHeight(double width) => _fold(
        (RenderBox c) => c.getMaxIntrinsicHeight(width),
        (double a, double b) => a + b,
      );

  double _fold(
    double Function(RenderBox child) measure,
    double Function(double a, double b) combine,
  ) {
    double result = 0;
    for (RenderBox? child = firstChild;
        child != null;
        child = childAfter(child)) {
      result = combine(result, measure(child));
    }
    return result;
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      defaultHitTestChildren(result, position: position);

  @override
  void paint(PaintingContext context, Offset offset) =>
      defaultPaint(context, offset);
}

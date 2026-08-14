import 'package:flutter/material.dart';

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
  /// a picker list, say — which cannot live inside a scroll view.
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

    return FoCard(
      tone: FoCardTone.raised,
      padding: EdgeInsets.zero,
      child: Column(
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
          Flexible(child: body),
          _Footer(controller: _controller, explicitFooter: widget.footer),
        ],
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

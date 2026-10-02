import 'package:flutter/material.dart';

import '../primitives/fo_icon_button.dart';
import '../primitives/fo_overlay_surface.dart';
import '../theme/fo_context.dart';
import '../tokens/fo_layout.dart';
import '../tokens/fo_motion.dart';
import '../tokens/fo_tokens.dart';

/// A short guide to one word — a stage, a column, a status — opened from the
/// `?` beside it.
///
/// **Help sits next to the word.** No guided tours, and no tooltip is the
/// only place an explanation lives: a tooltip needs a pointer to hover, and a
/// shop-floor phone has none. So the guide is a surface of its own — a drawer
/// from the end edge on a wide window, where the page stays visible beside it,
/// and a bottom sheet on a phone. `FoHint.guide` is the `?` that opens it.
///
/// The body is the caller's widget, usually a few short paragraphs; the
/// package holds no copy.
abstract final class FoHelpGuide {
  /// The drawer's width on a wide window — wider than a record's side panel,
  /// because a guide is read rather than scanned.
  static const double drawerWidth = 460;

  /// Opens the guide. Resolves when it closes.
  ///
  /// [eyebrow] names where the guide is about ("Help · Stage 8 of 9");
  /// [actions] sit in a footer that does not scroll — "Open full guide",
  /// "All guides" on a wide window, "Open full guide" and "Got it" on a
  /// phone — with an optional [footerNote] ("Opens in a new tab").
  ///
  /// [scrollTo] opens the guide at a section: give the section's widget this
  /// key inside [body] and the guide scrolls it into view once it has laid
  /// out. A key that is not in the tree opens the guide at the top — a stale
  /// anchor degrades, it never breaks.
  static Future<void> show(
    BuildContext context, {
    required String title,
    required Widget body,
    required String closeLabel,
    String? eyebrow,
    List<Widget> actions = const <Widget>[],
    String? footerNote,
    GlobalKey? scrollTo,
  }) {
    if (!context.foWindowClass.isAtLeastMedium) {
      return showModalBottomSheet<void>(
        context: context,
        useRootNavigator: true,
        isScrollControlled: true,
        useSafeArea: true,
        showDragHandle: true,
        elevation: 0,
        builder: (BuildContext ctx) => ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(ctx).height * _sheetHeightFraction,
          ),
          child: _GuideContent(
            title: title,
            body: body,
            closeLabel: closeLabel,
            eyebrow: eyebrow,
            actions: actions,
            footerNote: footerNote,
            scrollTo: scrollTo,
            compact: true,
          ),
        ),
      );
    }

    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: closeLabel,
      barrierColor: context.foColors.fg.withValues(
        alpha: FoTokens.scrimOpacity,
      ),
      transitionDuration: FoMotion.normal,
      pageBuilder: (BuildContext ctx, _, __) => Align(
        alignment: AlignmentDirectional.centerEnd,
        child: SizedBox(
          width: drawerWidth,
          height: double.infinity,
          child: DecoratedBox(
            decoration: foOverlaySurface(ctx, radius: 0),
            child: SafeArea(
              child: Material(
                type: MaterialType.transparency,
                child: _GuideContent(
                  title: title,
                  body: body,
                  closeLabel: closeLabel,
                  eyebrow: eyebrow,
                  actions: actions,
                  footerNote: footerNote,
                  scrollTo: scrollTo,
                  compact: false,
                ),
              ),
            ),
          ),
        ),
      ),
      transitionBuilder: (
        BuildContext ctx,
        Animation<double> animation,
        _,
        Widget child,
      ) {
        final bool rtl = Directionality.of(ctx) == TextDirection.rtl;
        // Reduced motion: the drawer appears rather than sliding in.
        if (MediaQuery.disableAnimationsOf(ctx)) return child;
        return SlideTransition(
          position: Tween<Offset>(
            begin: Offset(rtl ? -1 : 1, 0),
            end: Offset.zero,
          ).animate(
            CurvedAnimation(parent: animation, curve: FoMotion.standard),
          ),
          child: child,
        );
      },
    );
  }

  /// How much of a phone's height the sheet may take.
  static const double _sheetHeightFraction = 0.85;
}

class _GuideContent extends StatefulWidget {
  const _GuideContent({
    required this.title,
    required this.body,
    required this.closeLabel,
    required this.eyebrow,
    required this.actions,
    required this.footerNote,
    required this.scrollTo,
    required this.compact,
  });

  final String title;
  final Widget body;
  final String closeLabel;
  final String? eyebrow;
  final List<Widget> actions;
  final String? footerNote;
  final GlobalKey? scrollTo;
  final bool compact;

  @override
  State<_GuideContent> createState() => _GuideContentState();
}

class _GuideContentState extends State<_GuideContent> {
  static const double _tileSize = 40;

  @override
  void initState() {
    super.initState();
    final GlobalKey? target = widget.scrollTo;
    if (target == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final BuildContext? section = target.currentContext;
      // An anchor that matches nothing opens at the top.
      if (section == null || !mounted) return;
      Scrollable.ensureVisible(
        section,
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : FoMotion.normal,
        curve: FoMotion.standard,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final Widget heading = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (widget.eyebrow != null)
          Text(widget.eyebrow!.toUpperCase(), style: context.foText.caption),
        Semantics(
          header: true,
          child: Text(widget.title, style: context.foText.title),
        ),
      ],
    );

    return Semantics(
      scopesRoute: true,
      namesRoute: true,
      label: widget.title,
      explicitChildNodes: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Padding(
            padding: EdgeInsets.fromLTRB(
              context.foSpacing.lg,
              context.foSpacing.sm,
              context.foSpacing.sm,
              context.foSpacing.sm,
            ),
            child: Row(
              children: <Widget>[
                if (!widget.compact) ...<Widget>[
                  Container(
                    width: _tileSize,
                    height: _tileSize,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: context.foColors.primarySoft,
                      borderRadius: BorderRadius.circular(context.foRadii.md),
                    ),
                    child: Icon(
                      Icons.menu_book_outlined,
                      size: FoTokens.iconSmall,
                      color: context.foColors.primary,
                    ),
                  ),
                  SizedBox(width: context.foSpacing.md),
                ],
                Expanded(child: heading),
                FoIconButton(
                  icon: Icons.close,
                  semanticLabel: widget.closeLabel,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          Divider(
            height: FoLayout.hairlineWidth,
            thickness: FoLayout.hairlineWidth,
            color: context.foColors.edge,
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                context.foSpacing.lg,
                context.foSpacing.lg,
                context.foSpacing.lg,
                context.foSpacing.xl,
              ),
              child: DefaultTextStyle.merge(
                style: context.foText.body.copyWith(
                  color: context.foColors.fgMuted,
                ),
                child: widget.body,
              ),
            ),
          ),
          if (widget.actions.isNotEmpty) ...<Widget>[
            Divider(
              height: FoLayout.hairlineWidth,
              thickness: FoLayout.hairlineWidth,
              color: context.foColors.edge,
            ),
            Padding(
              padding: EdgeInsets.all(context.foSpacing.lg),
              child: Wrap(
                spacing: context.foSpacing.sm,
                runSpacing: context.foSpacing.sm,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: <Widget>[
                  ...widget.actions,
                  if (widget.footerNote != null)
                    Text(
                      widget.footerNote!,
                      style: context.foText.body.copyWith(
                        fontSize: FoTokens.fontCaption,
                        color: context.foColors.fgSubtle,
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
}

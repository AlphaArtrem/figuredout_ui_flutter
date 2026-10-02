import 'package:flutter/material.dart';

import '../primitives/fo_icon_button.dart';
import '../primitives/fo_overlay_surface.dart';
import '../theme/fo_context.dart';
import '../tokens/fo_layout.dart';
import '../tokens/fo_motion.dart';
import '../tokens/fo_tokens.dart';
import 'fo_action_bar.dart';

/// One step of a [FoStepper] or a [FoStepFlowScaffold].
@immutable
class FoStep {
  /// Creates a step.
  const FoStep({
    required this.label,
    this.summary,
    this.onEdit,
    this.editLabel,
  }) : assert(
          onEdit == null || editLabel != null,
          'editLabel is required when onEdit is set.',
        );

  /// What the step is — "Count by size". Caller-supplied.
  final String label;

  /// What was chosen, once the step is done — "JOB-2026-10024 · Deep Navy".
  /// Shown under a finished step, so the choice stays visible while the user
  /// is two steps further on.
  final String? summary;

  /// Goes back to change this step's choice. Only offered on a done step.
  final VoidCallback? onEdit;

  /// The edit link's word — "Change".
  final String? editLabel;
}

/// Where somebody is in a short flow: done steps ticked, the current one
/// filled, the rest outlined — the web package's `Stepper`.
///
/// Two forms, chosen by width. On a wide window the full row of steps, with
/// a done step's [FoStep.summary] and its "Change" link under it. On a phone
/// a thin segmented bar — one segment per step — because three labelled
/// steps do not fit beside each other at 390 points, and the step's name is
/// already in the flow's own title bar.
class FoStepper extends StatelessWidget {
  /// Creates a stepper.
  const FoStepper({
    required this.steps,
    required this.currentStep,
    this.compact,
    super.key,
  }) : assert(steps.length > 1, 'a flow of one step is a form');

  /// The steps, in order.
  final List<FoStep> steps;

  /// The current step's index.
  final int currentStep;

  /// Forces a form. Null chooses by window class.
  final bool? compact;

  /// The segmented bar's thickness.
  static const double segmentHeight = 6;

  /// The step marker's diameter.
  static const double _discSize = 28;

  @override
  Widget build(BuildContext context) {
    final int current = currentStep.clamp(0, steps.length - 1);
    final bool asBar = compact ?? !context.foWindowClass.isAtLeastMedium;
    if (asBar) return _bar(context, current);

    return Semantics(
      container: true,
      explicitChildNodes: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          for (int i = 0; i < steps.length; i++) ...<Widget>[
            if (i > 0) SizedBox(width: context.foSpacing.md),
            Expanded(child: _step(context, i, current)),
          ],
        ],
      ),
    );
  }

  Widget _bar(BuildContext context, int current) {
    // Visual only: the flow's title bar says "Step 2 of 3 · Count by size" in
    // words, which is what a screen reader should hear.
    return ExcludeSemantics(
      child: Row(
        children: <Widget>[
          for (int i = 0; i < steps.length; i++) ...<Widget>[
            if (i > 0) SizedBox(width: context.foSpacing.xs),
            Expanded(
              child: AnimatedContainer(
                duration: FoMotion.normal,
                curve: FoMotion.standard,
                height: segmentHeight,
                decoration: BoxDecoration(
                  color: i <= current
                      ? context.foColors.primary
                      : context.foColors.edge,
                  borderRadius: BorderRadius.circular(segmentHeight / 2),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _step(BuildContext context, int i, int current) {
    final FoStep step = steps[i];
    final bool done = i < current;
    final bool isCurrent = i == current;

    final Widget disc = Center(
// A circle stays a circle under any constraints (see FoDisc).
      widthFactor: 1,
      heightFactor: 1,
      child: Container(
        width: _discSize,
        height: _discSize,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: done
              ? context.foColors.successSoft
              : isCurrent
                  ? context.foColors.primary
                  : Colors.transparent,
        ),
        foregroundDecoration: done || isCurrent
            ? null
            : BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: context.foColors.edgeStrong),
              ),
        child: done
            ? Icon(
                Icons.check,
                size: FoTokens.iconSmall,
                color: context.foColors.success,
              )
            : Text(
                '${i + 1}',
                style: context.foText.numeric.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isCurrent
                      ? context.foColors.primaryFg
                      : context.foColors.fgSubtle,
                ),
              ),
      ),
    );

    final TextStyle labelStyle = context.foText.body.copyWith(
      color: isCurrent
          ? context.foColors.primary
          : done
              ? context.foColors.fg
              : context.foColors.fgMuted,
      fontWeight: isCurrent
          ? FontWeight.w700
          : done
              ? FontWeight.w600
              : FontWeight.w500,
    );

    return Semantics(
      selected: isCurrent,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          disc,
          SizedBox(width: context.foSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                // Centred on the disc's first line.
                ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: _discSize),
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(step.label, style: labelStyle),
                  ),
                ),
                if (done && step.summary != null)
                  Text(
                    step.summary!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.foText.body.copyWith(
                      fontSize: FoTokens.fontCaption,
                      color: context.foColors.fgMuted,
                    ),
                  ),
                if (done && step.onEdit != null)
                  TextButton(
                    onPressed: step.onEdit,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, FoLayout.minTouchTarget),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      alignment: AlignmentDirectional.centerStart,
                      textStyle: context.foText.label,
                    ),
                    child: Text(step.editLabel!),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The frame of a short task flow — choose, count, check — at every width.
///
/// **One flow, two presentations, chosen by width** (the redesign's first
/// rule: recording work is the same three steps everywhere):
///
/// * **Wide** — a dialog over the list it was opened from: a header with the
///   [eyebrow], [title], [subtitle] and a close button; the full [FoStepper]
///   in a band under it; the [body], which scrolls; and the [footer] pinned
///   at the bottom, so "Save as draft · Back · Next" never scrolls away.
/// * **Compact** — the whole screen, with no bottom menu: a title bar with
///   close (step one) or back (later steps), the [title] and [stepLabel]; the
///   segmented progress bar; the [body]; and the [footer] fixed above the home
///   indicator, holding the total and the next action.
///
/// Present it with [FoStepFlow.show], which picks the dialog or the
/// full-screen route to match. The step state is the caller's: rebuild this
/// with a new [currentStep] and [body] as the user moves.
///
/// Closing with unsaved counts should ask first. That is the caller's
/// [onClose] — call `FoDialog.destructive` there — because only the caller
/// knows whether anything has been typed.
class FoStepFlowScaffold extends StatelessWidget {
  /// Creates a step-flow frame.
  const FoStepFlowScaffold({
    required this.title,
    required this.steps,
    required this.currentStep,
    required this.body,
    required this.footer,
    required this.onClose,
    required this.closeSemanticLabel,
    this.eyebrow,
    this.subtitle,
    this.stepLabel,
    this.onBack,
    this.backSemanticLabel,
    this.help,
    super.key,
  }) : assert(
          onBack == null || backSemanticLabel != null,
          'backSemanticLabel is required when onBack is set.',
        );

  /// The task — "Record pressing".
  final String title;

  /// A mono caption above the title on a wide window — "Pressing · Stage 8
  /// of 9".
  final String? eyebrow;

  /// One plain sentence under the title on a wide window.
  final String? subtitle;

  /// The steps, in order.
  final List<FoStep> steps;

  /// The current step's index.
  final int currentStep;

  /// Where the user is, in words, under the title on a phone — "Step 2 of 3 ·
  /// Count by size". Caller-supplied, because the package holds no copy.
  final String? stepLabel;

  /// The current step's content.
  final Widget body;

  /// The pinned footer's content — a `FoActionBar`'s worth of actions. Laid
  /// out below the body, never over it.
  final Widget footer;

  /// Closes the flow. Ask first when something has been typed.
  final VoidCallback onClose;

  /// The close button's name — "Close. You'll be asked before anything you
  /// typed is thrown away."
  final String closeSemanticLabel;

  /// Goes back one step. On a phone it replaces the close button after the
  /// first step; on a wide window "Back" belongs in the [footer].
  final VoidCallback? onBack;

  /// The back button's name — "Back to the previous step".
  final String? backSemanticLabel;

  /// The `?` beside the title — `FoHint.guide`.
  final Widget? help;

  @override
  Widget build(BuildContext context) => context.foWindowClass.isAtLeastMedium
      ? _wide(context)
      : _compact(context);

  Widget _wide(BuildContext context) {
    final double pad = context.foSpacing.xl;
    final Widget rule = Divider(
      height: FoLayout.hairlineWidth,
      thickness: FoLayout.hairlineWidth,
      color: context.foColors.edge,
    );

    return Semantics(
      scopesRoute: true,
      namesRoute: true,
      label: title,
      explicitChildNodes: true,
      child: DecoratedBox(
        decoration: foOverlaySurface(context, radius: context.foRadii.lg),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(context.foRadii.lg),
          child: Material(
            type: MaterialType.transparency,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Padding(
                  padding: EdgeInsets.fromLTRB(
                      pad, pad, context.foSpacing.md, context.foSpacing.lg),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Expanded(child: _heading(context)),
                      FoIconButton(
                        icon: Icons.close,
                        semanticLabel: closeSemanticLabel,
                        onPressed: onClose,
                      ),
                    ],
                  ),
                ),
                rule,
                ColoredBox(
                  color: context.foColors.surface,
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: pad,
                      vertical: context.foSpacing.md,
                    ),
                    child: FoStepper(
                      steps: steps,
                      currentStep: currentStep,
                      compact: false,
                    ),
                  ),
                ),
                rule,
                // Loose, so a short step makes a short dialog and a long one
                // scrolls inside the dialog's maximum height.
                Flexible(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(pad),
                    child: body,
                  ),
                ),
                rule,
                ColoredBox(
                  color: context.foColors.surface,
                  child: SafeArea(
                    top: false,
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: pad,
                        vertical: context.foSpacing.lg,
                      ),
                      child: footer,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _heading(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (eyebrow != null) ...<Widget>[
            Text(eyebrow!.toUpperCase(), style: context.foText.caption),
            SizedBox(height: context.foSpacing.xs),
          ],
          Row(
            children: <Widget>[
              Flexible(
                child: Semantics(
                  header: true,
                  child: Text(title, style: context.foText.display),
                ),
              ),
              if (help != null) ...<Widget>[
                SizedBox(width: context.foSpacing.xs),
                help!,
              ],
            ],
          ),
          if (subtitle != null) ...<Widget>[
            SizedBox(height: context.foSpacing.xs),
            Text(
              subtitle!,
              style: context.foText.body.copyWith(
                color: context.foColors.fgMuted,
              ),
            ),
          ],
        ],
      );

  Widget _compact(BuildContext context) {
    final bool showBack = onBack != null && currentStep > 0;

    return Material(
      color: context.foColors.bg,
      child: Semantics(
        scopesRoute: true,
        namesRoute: true,
        label: title,
        explicitChildNodes: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            DecoratedBox(
              decoration: BoxDecoration(
                color: context.foColors.surface,
                border: Border(
                  bottom: BorderSide(color: context.foColors.edge),
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    context.foSpacing.xs,
                    context.foSpacing.xs,
                    context.foSpacing.xs,
                    context.foSpacing.md,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          if (showBack)
                            FoIconButton(
                              icon: Icons.arrow_back,
                              semanticLabel: backSemanticLabel!,
                              onPressed: onBack,
                            )
                          else
                            FoIconButton(
                              icon: Icons.close,
                              semanticLabel: closeSemanticLabel,
                              onPressed: onClose,
                            ),
                          SizedBox(width: context.foSpacing.xs),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                Semantics(
                                  header: true,
                                  child: Text(
                                    title,
                                    style: context.foText.subtitle,
                                  ),
                                ),
                                if (stepLabel != null)
                                  Text(
                                    stepLabel!,
                                    style: context.foText.body.copyWith(
                                      fontSize: FoTokens.fontCaption,
                                      color: context.foColors.fgMuted,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          if (help != null) help!,
                        ],
                      ),
                      SizedBox(height: context.foSpacing.sm),
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: context.foSpacing.md,
                        ),
                        child: FoStepper(
                          steps: steps,
                          currentStep: currentStep,
                          compact: true,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(context.foSpacing.lg),
                child: body,
              ),
            ),
            FoActionBar(actions: <Widget>[footer]),
          ],
        ),
      ),
    );
  }
}

/// Presents a [FoStepFlowScaffold] the right way for the width: a dialog over
/// the page on a wide window, a full-screen route on a phone.
///
/// Both open on the root navigator, so a shell's bottom menu is not live
/// behind the flow — the menu "steps aside until you finish". The barrier does
/// not dismiss: a tap beside a half-counted entry is not a decision to throw
/// it away, so leaving goes through the flow's own close button.
abstract final class FoStepFlow {
  /// The dialog's widest — a table of sizes and four count columns.
  static const double maxDialogWidth = 940;

  /// The dialog's tallest, before its body scrolls.
  static const double maxDialogHeight = 860;

  /// Shows the flow [builder] builds, and resolves with whatever it pops.
  static Future<T?> show<T>(
    BuildContext context, {
    required WidgetBuilder builder,
  }) {
    if (context.foWindowClass.isAtLeastMedium) {
      return showDialog<T>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext ctx) => Dialog(
          insetPadding: EdgeInsets.all(ctx.foSpacing.xl),
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: maxDialogWidth,
              maxHeight: maxDialogHeight,
            ),
            child: builder(ctx),
          ),
        ),
      );
    }

    return Navigator.of(context, rootNavigator: true).push<T>(
      MaterialPageRoute<T>(fullscreenDialog: true, builder: builder),
    );
  }
}

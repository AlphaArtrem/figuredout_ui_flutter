import 'package:flutter/material.dart';

import '../primitives/fo_button.dart';
import '../primitives/fo_progress_bar.dart';
import '../primitives/fo_status_chip.dart';
import '../theme/fo_context.dart';
import '../tokens/fo_layout.dart';
import '../tokens/fo_tokens.dart';

/// One step of a [FoChecklist].
@immutable
class FoChecklistStep {
  /// Creates a step.
  const FoChecklistStep({
    required this.title,
    required this.done,
    this.description,
    this.doneDescription,
    this.actionLabel,
    this.onAction,
    this.editLabel,
    this.onEdit,
    this.body,
  });

  /// What to do — "Add your sizes". Caller-supplied.
  final String title;

  /// Whether it is done.
  final bool done;

  /// One line on what it involves.
  final String? description;

  /// What was done, once it is — "10 sizes: S to XXL, 28 to 40".
  final String? doneDescription;

  /// Starts a step that is not current — "Add sizes".
  final String? actionLabel;

  /// What [actionLabel] does.
  final VoidCallback? onAction;

  /// Changes a done step — "Edit".
  final String? editLabel;

  /// What [editLabel] does.
  final VoidCallback? onEdit;

  /// The step's own form, opened in place while it is the current one.
  final Widget? body;
}

/// The words a [FoChecklist] needs.
@immutable
class FoChecklistCopy {
  /// Creates the copy.
  const FoChecklistCopy({
    required this.title,
    required this.progressLabel,
    required this.doneLabel,
    this.hideLabel,
    this.allDoneTitle,
    this.allDoneMessage,
  });

  /// "Set up Unit 02".
  final String title;

  /// "{done} of {total} done".
  final String Function(int done, int total) progressLabel;

  /// The chip on a done step — "Done".
  final String doneLabel;

  /// "Hide for now". Null hides the button.
  final String? hideLabel;

  /// Shown instead of the steps when every one is done.
  final String? allDoneTitle;

  /// Under [allDoneTitle].
  final String? allDoneMessage;
}

/// A short list of things to do once, in order, with the current one open:
/// setting up a new unit, getting an order ready to dispatch.
///
/// A progress line over the steps — done ones ticked with what was done, the
/// current one ([current], or the first not done) ringed and opened in place
/// with its own [FoChecklistStep.body], later ones each with a button to jump
/// ahead. When every step is done the list gives way to [FoChecklistCopy.
/// allDoneTitle], so it never sits on a home screen fully ticked forever.
/// [onHide] lets somebody put it away and come back to it.
class FoChecklist extends StatelessWidget {
  /// Creates a checklist.
  const FoChecklist({
    required this.steps,
    required this.copy,
    this.current,
    this.onHide,
    this.allDoneAction,
    super.key,
  });

  /// The steps, in order.
  final List<FoChecklistStep> steps;

  /// The words.
  final FoChecklistCopy copy;

  /// The open step. Null opens the first one not done.
  final int? current;

  /// Puts the list away.
  final VoidCallback? onHide;

  /// The button under the all-done message — "Close this list".
  final Widget? allDoneAction;

  static const double _markSize = 32;

  @override
  Widget build(BuildContext context) {
    final int done = steps.where((FoChecklistStep s) => s.done).length;
    final bool allDone = done == steps.length;
    final int open = current != null && !steps[current!].done
        ? current!
        : steps.indexWhere((FoChecklistStep s) => !s.done);

    final Widget header = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: context.foSpacing.md,
          children: <Widget>[
            Semantics(
              header: true,
              child: Text(copy.title, style: context.foText.title),
            ),
            if (onHide != null && copy.hideLabel != null)
              FoButton(
                label: copy.hideLabel!,
                variant: FoButtonVariant.clear,
                onPressed: onHide,
              ),
          ],
        ),
        SizedBox(height: context.foSpacing.sm),
        FoProgressBar(
          value: done.toDouble(),
          max: steps.length.toDouble(),
          tone: allDone ? FoStatusTone.success : FoStatusTone.primary,
          semanticLabel: copy.title,
          semanticValue: copy.progressLabel(done, steps.length),
          trailing: Text(
            copy.progressLabel(done, steps.length),
            style: context.foText.body.copyWith(
              color: context.foColors.fgMuted,
            ),
          ),
        ),
      ],
    );

    if (allDone && copy.allDoneTitle != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          header,
          SizedBox(height: context.foSpacing.lg),
          Semantics(
            liveRegion: true,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const _Mark(state: _State.done, number: 0, size: _markSize),
                SizedBox(width: context.foSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        copy.allDoneTitle!,
                        style: context.foText.subtitle.copyWith(
                          color: context.foColors.success,
                        ),
                      ),
                      if (copy.allDoneMessage != null)
                        Text(copy.allDoneMessage!, style: context.foText.body),
                      if (allDoneAction != null) ...<Widget>[
                        SizedBox(height: context.foSpacing.md),
                        allDoneAction!,
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        header,
        SizedBox(height: context.foSpacing.lg),
        for (int i = 0; i < steps.length; i++) ...<Widget>[
          if (i > 0) SizedBox(height: context.foSpacing.sm),
          _StepRow(
            step: steps[i],
            number: i + 1,
            state: steps[i].done
                ? _State.done
                : i == open
                    ? _State.current
                    : _State.later,
            doneLabel: copy.doneLabel,
          ),
        ],
      ],
    );
  }
}

enum _State { done, current, later }

class _StepRow extends StatelessWidget {
  const _StepRow({
    required this.step,
    required this.number,
    required this.state,
    required this.doneLabel,
  });

  final FoChecklistStep step;
  final int number;
  final _State state;
  final String doneLabel;

  @override
  Widget build(BuildContext context) {
    final bool current = state == _State.current;
    final bool done = state == _State.done;
    final BorderRadius radius = BorderRadius.circular(context.foRadii.card);
    final String? line =
        done ? step.doneDescription ?? step.description : step.description;

    final Widget? trailing = switch (state) {
      _State.done => Wrap(
          spacing: context.foSpacing.xs,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: <Widget>[
            FoStatusChip.tone(
              label: doneLabel,
              tone: FoStatusTone.success,
              icon: Icons.check,
            ),
            if (step.onEdit != null && step.editLabel != null)
              Semantics(
                label: '${step.editLabel}: ${step.title}',
                excludeSemantics: true,
                button: true,
                child: FoButton(
                  label: step.editLabel!,
                  variant: FoButtonVariant.clear,
                  onPressed: step.onEdit,
                ),
              ),
          ],
        ),
      _State.later when step.onAction != null && step.actionLabel != null =>
        FoButton(
          label: step.actionLabel!,
          variant: FoButtonVariant.secondary,
          onPressed: step.onAction,
        ),
      _ => null,
    };

    return Semantics(
      container: true,
      selected: current,
      child: Container(
        padding: EdgeInsets.all(context.foSpacing.md),
        decoration: BoxDecoration(
          color: current
              ? context.foColors.surface
              : context.foColors.surfaceRaised,
          borderRadius: radius,
        ),
        foregroundDecoration: BoxDecoration(
          borderRadius: radius,
          border: Border.all(
            color: current ? context.foColors.primary : context.foColors.edge,
            width: current ? 2 : FoLayout.hairlineWidth,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _Mark(
                    state: state, number: number, size: FoChecklist._markSize),
                SizedBox(width: context.foSpacing.md),
                Expanded(
                  child: Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: context.foSpacing.md,
                    runSpacing: context.foSpacing.sm,
                    children: <Widget>[
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Text(
                            step.title,
                            style: context.foText.subtitle.copyWith(
                              color: done ? context.foColors.fgMuted : null,
                              fontWeight:
                                  done ? FontWeight.w500 : FontWeight.w600,
                            ),
                          ),
                          if (line != null)
                            Text(
                              line,
                              style: context.foText.body.copyWith(
                                fontSize: FoTokens.fontLabel,
                                color: context.foColors.fgMuted,
                              ),
                            ),
                        ],
                      ),
                      if (trailing != null) trailing,
                    ],
                  ),
                ),
              ],
            ),
            if (current && step.body != null)
              Padding(
                padding: EdgeInsetsDirectional.only(
                  start: FoChecklist._markSize + context.foSpacing.md,
                  top: context.foSpacing.lg,
                ),
                child: step.body,
              ),
          ],
        ),
      ),
    );
  }
}

class _Mark extends StatelessWidget {
  const _Mark({required this.state, required this.number, required this.size});

  final _State state;
  final int number;
  final double size;

  @override
  Widget build(BuildContext context) {
    final bool done = state == _State.done;
    final bool current = state == _State.current;
    return ExcludeSemantics(
      child: Center(
// A circle stays a circle under any constraints (see FoDisc).
        widthFactor: 1,
        heightFactor: 1,
        child: Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: done
                ? context.foColors.successSoft
                : current
                    ? context.foColors.primary
                    : Colors.transparent,
            border: done || current
                ? null
                : Border.all(color: context.foColors.edgeStrong),
          ),
          child: done
              ? Icon(
                  Icons.check,
                  size: FoTokens.iconSmall,
                  color: context.foColors.success,
                )
              : Text(
                  '$number',
                  style: context.foText.numeric.copyWith(
                    fontWeight: FontWeight.w600,
                    color: current
                        ? context.foColors.primaryFg
                        : context.foColors.fgSubtle,
                  ),
                ),
        ),
      ),
    );
  }
}

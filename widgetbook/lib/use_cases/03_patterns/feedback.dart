import 'package:figuredout_ui/figuredout_ui.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

import '../../support/doc_page.dart';

/// Banners, toasts and empty states — and which of the three a given moment
/// actually is.
class FeedbackPatterns extends StatelessWidget {
  /// Creates the feedback page.
  const FeedbackPatterns({super.key});

  @override
  Widget build(BuildContext context) {
    return DocPage(
      title: 'Feedback',
      lede: 'A toast reports the result of an action and leaves. A banner '
          'reports a condition that is still true and stays until it is not. '
          'An empty state says there is nothing here and what to do about it. '
          'A banner that needs dismissing after three seconds should have been '
          'a toast.',
      children: <Widget>[
        DocSection(
          title: 'Banners',
          child: Column(
            children: <Widget>[
              for (final FoBannerTone tone in FoBannerTone.values) ...<Widget>[
                FoInfoBanner(
                  tone: tone,
                  message:
                      'This is a ${tone.name} banner — a condition that is '
                      'still true right now.',
                ),
                SizedBox(height: context.foSpacing.md),
              ],
              FoInfoBanner.error(
                message: 'Could not reach the server.',
                onRetry: () {},
                retryLabel: 'Retry',
              ),
              SizedBox(height: context.foSpacing.sm),
              Text(
                'An error banner without a retry is a dead end: it tells the '
                'user something broke and gives them nothing to do about it.',
                style: context.foText.body.copyWith(
                  color: context.foColors.fgSubtle,
                ),
              ),
            ],
          ),
        ),
        DocSection(title: 'Toasts', child: _ToastButtons()),
        DocSection(
          title: 'Empty states',
          child: Column(
            children: <Widget>[
              _Framed(
                child: FoEmptyState(
                  icon: Icons.inbox_outlined,
                  title: 'No entries yet',
                  hint: 'Entries logged against this plan will appear here.',
                  actionLabel: 'New entry',
                  onAction: () {},
                ),
              ),
              SizedBox(height: context.foSpacing.lg),
              const _Framed(
                child: FoEmptyState.noResults(
                  title: 'No matching entries',
                  hint: 'Try a different search or clear the filters.',
                ),
              ),
              SizedBox(height: context.foSpacing.lg),
              _Framed(
                child: FoEmptyState.error(
                  title: 'Could not load entries',
                  hint: 'Connection refused',
                  actionLabel: 'Retry',
                  onAction: () {},
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Framed extends StatelessWidget {
  const _Framed({required this.child});

  final Widget child;

  /// Tall enough for the empty state's mark, title, hint and action at the
  /// compact viewport, where the hint wraps to three lines.
  static const double _height = 400;

  @override
  Widget build(BuildContext context) =>
      SizedBox(height: _height, child: FoCard(child: child));
}

class _ToastButtons extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: context.foSpacing.md,
      runSpacing: context.foSpacing.md,
      children: <Widget>[
        FoButton(
          label: 'Success',
          variant: FoButtonVariant.secondary,
          onPressed: () => FoToast.success(context, 'Entry saved.'),
        ),
        FoButton(
          label: 'Error',
          variant: FoButtonVariant.secondary,
          onPressed: () => FoToast.error(
            context,
            'Could not save the entry.',
            action: FoToastAction(label: 'Retry', onPressed: () {}),
          ),
        ),
        FoButton(
          label: 'Warning',
          variant: FoButtonVariant.secondary,
          onPressed: () =>
              FoToast.warning(context, 'This plan is already closed.'),
        ),
        FoButton(
          label: 'Info',
          variant: FoButtonVariant.secondary,
          onPressed: () => FoToast.info(context, 'Synced two minutes ago.'),
        ),
      ],
    );
  }
}

/// Dialogs — the three shapes, and why they are a choke point.
class Dialogs extends StatelessWidget {
  /// Creates the dialog page.
  const Dialogs({super.key});

  @override
  Widget build(BuildContext context) {
    return DocPage(
      title: 'Dialogs',
      lede:
          'Hand-built dialogs disagree about button order, about which one is '
          'destructive, and about whether the dangerous action is left or '
          'right — and that disagreement is how someone deletes the wrong '
          'thing. Switch to Compact 480: the buttons stack, confirm on top.',
      children: <Widget>[
        DocSection(
          title: 'The three shapes',
          child: Wrap(
            spacing: context.foSpacing.md,
            runSpacing: context.foSpacing.md,
            children: <Widget>[
              FoButton(
                label: 'Confirm',
                variant: FoButtonVariant.secondary,
                onPressed: () => FoDialog.confirm(
                  context,
                  title: 'Submit this entry?',
                  message: 'It will be visible to the next shift.',
                  confirmLabel: 'Submit',
                  cancelLabel: 'Cancel',
                ),
              ),
              FoButton(
                label: 'Destructive',
                variant: FoButtonVariant.destructive,
                onPressed: () => FoDialog.destructive(
                  context,
                  title: 'Delete this entry?',
                  message: 'This cannot be undone.',
                  confirmLabel: 'Delete',
                  cancelLabel: 'Keep it',
                ),
              ),
              FoButton(
                label: 'Info',
                variant: FoButtonVariant.clear,
                onPressed: () => FoDialog.info(
                  context,
                  title: 'About rejected quantity',
                  message:
                      'The quantity discarded after cutting, not counted in '
                      'the stage output.',
                  closeLabel: 'Got it',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Banners, toasts and empty states side by side.
@widgetbook.UseCase(name: 'Banner', type: FoInfoBanner, path: '03 Patterns')
Widget buildBanners(BuildContext context) => const FeedbackPatterns();

/// The four toasts. A failure runs longer than a confirmation.
@widgetbook.UseCase(name: 'Toast', type: FoToast, path: '03 Patterns')
Widget buildToasts(BuildContext context) => const FeedbackPatterns();

/// Nothing yet, nothing matching, and nothing loaded.
@widgetbook.UseCase(
  name: 'Empty state',
  type: FoEmptyState,
  path: '03 Patterns',
)
Widget buildEmptyStates(BuildContext context) => const FeedbackPatterns();

/// Confirm, destructive and info.
@widgetbook.UseCase(name: 'Dialog', type: FoDialog, path: '03 Patterns')
Widget buildDialogs(BuildContext context) => const Dialogs();

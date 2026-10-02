import 'package:flutter/material.dart';

import '../primitives/fo_status_chip.dart';
import '../theme/fo_context.dart';
import '../tokens/fo_tokens.dart';

/// Where an entry made offline is on its way to the server.
enum FoOutboxState {
  /// Kept on this phone, not sent yet — it will retry by itself.
  waiting,

  /// Sent and counted.
  sent,

  /// The server refused it and only the user can decide what to do — another
  /// entry used the same pieces while this phone was offline.
  needsYou,

  /// The user sent it on for an owner to approve.
  sentForApproval,
}

/// One entry in the "Waiting to send" list, after a phone has been offline.
///
/// **Nothing is ever silently lost or silently changed.** A [FoOutboxState.
/// waiting] entry says when it last tried and that it will try again, with a
/// way to try now; a [FoOutboxState.needsYou] entry is ringed in warning,
/// says exactly what clashed in [detail], and offers the ways out as
/// [actions] — fix it, send it for approval, remove it (behind a confirm that
/// names the pieces). The status word is the caller's [statusLabel], drawn as
/// a chip in the state's tone.
class FoOutboxItem extends StatelessWidget {
  /// Creates an outbox item.
  const FoOutboxItem({
    required this.state,
    required this.statusLabel,
    required this.title,
    this.origin,
    this.subtitle,
    this.figure,
    this.figureCaption,
    this.message,
    this.detail,
    this.actions = const <Widget>[],
    super.key,
  });

  /// Where it is.
  final FoOutboxState state;

  /// The state's word — "Not sent yet", "Sent", "Needs you". Caller-supplied.
  final String statusLabel;

  /// Where it came from — "Pressing · saved 11:10".
  final String? origin;

  /// The record — "Pique Polo".
  final String title;

  /// Which part of it — a swatch and "Sage · JOB-2026-10024".
  final Widget? subtitle;

  /// The count, formatted.
  final String? figure;

  /// What the count is — "pressed".
  final String? figureCaption;

  /// What is happening — "Last try at 11:24: the server didn't answer. We
  /// try again by itself every minute. Nothing is lost."
  final String? message;

  /// What clashed, for [FoOutboxState.needsYou] — usually a warning
  /// `FoInfoBanner` and a `FoSizeValueStrip` with the clashing size flagged.
  final Widget? detail;

  /// The ways on, main one first.
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final FoStatusTone tone = switch (state) {
      FoOutboxState.waiting => FoStatusTone.neutral,
      FoOutboxState.sent => FoStatusTone.success,
      FoOutboxState.needsYou => FoStatusTone.warning,
      FoOutboxState.sentForApproval => FoStatusTone.warning,
    };
    final bool flagged = state == FoOutboxState.needsYou;
    final BorderRadius radius = BorderRadius.circular(context.foRadii.card);

    return Semantics(
      container: true,
      child: Container(
        padding: EdgeInsets.all(context.foSpacing.lg),
        decoration: BoxDecoration(
          color: context.foColors.surfaceRaised,
          borderRadius: radius,
        ),
        foregroundDecoration: BoxDecoration(
          borderRadius: radius,
          border: Border.all(
            color: flagged ? context.foColors.warning : context.foColors.edge,
            width: flagged ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: context.foSpacing.sm,
              runSpacing: context.foSpacing.xs,
              children: <Widget>[
                if (origin != null)
                  Text(
                    origin!,
                    style: context.foText.body.copyWith(
                      fontSize: FoTokens.fontLabel,
                      color: context.foColors.fgSubtle,
                    ),
                  ),
                FoStatusChip.tone(
                  label: statusLabel,
                  tone: tone,
                  icon: switch (state) {
                    FoOutboxState.waiting => Icons.schedule,
                    FoOutboxState.sent => Icons.check,
                    FoOutboxState.needsYou => Icons.warning_amber_outlined,
                    FoOutboxState.sentForApproval =>
                      Icons.warning_amber_outlined,
                  },
                ),
              ],
            ),
            SizedBox(height: context.foSpacing.sm),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(title, style: context.foText.subtitle),
                      if (subtitle != null) ...<Widget>[
                        SizedBox(height: context.foSpacing.xs),
                        subtitle!,
                      ],
                    ],
                  ),
                ),
                if (figure != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        figure!,
                        style: context.foText.numeric.copyWith(
                          fontSize: FoTokens.fontDisplay,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (figureCaption != null)
                        Text(
                          figureCaption!,
                          style: context.foText.body.copyWith(
                            fontSize: FoTokens.fontCaption,
                            color: context.foColors.fgSubtle,
                          ),
                        ),
                    ],
                  ),
              ],
            ),
            if (message != null) ...<Widget>[
              SizedBox(height: context.foSpacing.md),
              Semantics(
                liveRegion: true,
                child: Text(
                  message!,
                  style: context.foText.body.copyWith(
                    color: context.foColors.fgMuted,
                  ),
                ),
              ),
            ],
            if (detail != null) ...<Widget>[
              SizedBox(height: context.foSpacing.md),
              detail!,
            ],
            if (actions.isNotEmpty) ...<Widget>[
              SizedBox(height: context.foSpacing.md),
              Wrap(
                spacing: context.foSpacing.sm,
                runSpacing: context.foSpacing.sm,
                children: actions,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

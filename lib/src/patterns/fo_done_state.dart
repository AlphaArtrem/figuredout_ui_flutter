import 'package:flutter/material.dart';

import '../primitives/fo_status_chip.dart';
import '../theme/fo_context.dart';

/// The end of a task flow: what happened, what it means, what next.
///
/// "110 pieces recorded", "Sent for approval", "Saved as a draft" — three
/// outcomes that must not look alike, so the mark's tone follows the
/// outcome: success for done, warning for waiting on somebody, neutral for
/// kept but not counted. The title names the result; the body says what it
/// means for the user; [actions] are the next thing to do — usually "Record
/// more" and "Back to home". It is a live region, so the result is announced
/// when the screen changes to it.
class FoDoneState extends StatelessWidget {
  /// Creates a done state.
  const FoDoneState({
    required this.title,
    required this.icon,
    this.tone = FoStatusTone.success,
    this.message,
    this.summary,
    this.actions = const <Widget>[],
    super.key,
  });

  /// The result — "110 pieces recorded". Caller-supplied.
  final String title;

  /// The mark — a check, a clock, a pencil.
  final IconData icon;

  /// What kind of result it is.
  final FoStatusTone tone;

  /// What it means, in one or two sentences.
  final String? message;

  /// A recap of the record — the order, the colour, the count.
  final Widget? summary;

  /// What to do next, main action first.
  final List<Widget> actions;

  static const double _markSize = 80;

  @override
  Widget build(BuildContext context) {
    final (Color ink, Color ground) = switch (tone) {
      FoStatusTone.neutral => (
          context.foColors.fgMuted,
          context.foColors.surfaceSunken,
        ),
      FoStatusTone.primary => (
          context.foColors.primary,
          context.foColors.primarySoft,
        ),
      FoStatusTone.success => (
          context.foColors.success,
          context.foColors.successSoft,
        ),
      FoStatusTone.warning => (
          context.foColors.warning,
          context.foColors.warningSoft,
        ),
      FoStatusTone.danger => (
          context.foColors.danger,
          context.foColors.dangerSoft,
        ),
      FoStatusTone.info => (context.foColors.info, context.foColors.infoSoft),
    };

    return Semantics(
      liveRegion: true,
      container: true,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Center(
                child: Container(
                  width: _markSize,
                  height: _markSize,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: ground,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 40, color: ink),
                ),
              ),
              SizedBox(height: context.foSpacing.xl),
              Semantics(
                header: true,
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: context.foText.display,
                ),
              ),
              if (message != null) ...<Widget>[
                SizedBox(height: context.foSpacing.sm),
                Text(
                  message!,
                  textAlign: TextAlign.center,
                  style: context.foText.body.copyWith(
                    color: context.foColors.fgMuted,
                  ),
                ),
              ],
              if (summary != null) ...<Widget>[
                SizedBox(height: context.foSpacing.xl),
                summary!,
              ],
              if (actions.isNotEmpty) ...<Widget>[
                SizedBox(height: context.foSpacing.xl),
                for (int i = 0; i < actions.length; i++) ...<Widget>[
                  if (i > 0) SizedBox(height: context.foSpacing.sm),
                  actions[i],
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

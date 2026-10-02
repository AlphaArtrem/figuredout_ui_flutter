import 'package:flutter/material.dart';

import '../primitives/fo_status_chip.dart';
import '../theme/fo_context.dart';

/// A whole page that cannot show what was asked for — no access, not found —
/// inside the app's normal shell, at the address the user opened.
///
/// Not an empty list (`FoEmptyState` is a region of a page that works): this
/// replaces the page's content and keeps the navigation, so the user is never
/// stranded on a blank screen with no way back. An [eyebrow] names the
/// situation, the [title] says it in a sentence, the [message] says why, and
/// [children] carry the specifics — who can open it, the address that
/// failed, the closest matches. [actions] are the ways on, main one first.
class FoPageState extends StatelessWidget {
  /// Creates a page state.
  const FoPageState({
    required this.icon,
    required this.title,
    this.eyebrow,
    this.message,
    this.tone = FoStatusTone.neutral,
    this.children = const <Widget>[],
    this.actions = const <Widget>[],
    this.footnote,
    super.key,
  });

  /// The mark.
  final IconData icon;

  /// A mono caption — "No access", "Page not found".
  final String? eyebrow;

  /// The situation as a sentence — "Cartons is for packing and owners".
  final String title;

  /// Why, and what it means.
  final String? message;

  /// The mark's tone — info for a lock, neutral for not-found.
  final FoStatusTone tone;

  /// The specifics, between the message and the actions.
  final List<Widget> children;

  /// Ways on, main one first.
  final List<Widget> actions;

  /// A quiet line under the card.
  final String? footnote;

  static const double _tileSize = 52;

  @override
  Widget build(BuildContext context) {
    final (Color ink, Color ground) = switch (tone) {
      FoStatusTone.info => (context.foColors.info, context.foColors.infoSoft),
      FoStatusTone.warning => (
          context.foColors.warning,
          context.foColors.warningSoft,
        ),
      FoStatusTone.danger => (
          context.foColors.danger,
          context.foColors.dangerSoft,
        ),
      FoStatusTone.primary => (
          context.foColors.primary,
          context.foColors.primarySoft,
        ),
      FoStatusTone.success => (
          context.foColors.success,
          context.foColors.successSoft,
        ),
      FoStatusTone.neutral => (
          context.foColors.fgMuted,
          context.foColors.surfaceSunken,
        ),
    };
    final BorderRadius radius = BorderRadius.circular(context.foRadii.card);

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: context.foGutter,
        vertical: context.foSpacing.xxxl,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Container(
                padding: EdgeInsets.all(context.foSpacing.xl),
                decoration: BoxDecoration(
                  color: context.foColors.surfaceRaised,
                  borderRadius: radius,
                  boxShadow: context.foShadows.raised,
                ),
                foregroundDecoration: BoxDecoration(
                  borderRadius: radius,
                  border: Border.all(color: context.foColors.edge),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Container(
                      width: _tileSize,
                      height: _tileSize,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: ground,
                        borderRadius: BorderRadius.circular(context.foRadii.md),
                      ),
                      child: Icon(icon, color: ink),
                    ),
                    SizedBox(height: context.foSpacing.lg),
                    if (eyebrow != null) ...<Widget>[
                      Text(
                        eyebrow!.toUpperCase(),
                        style: context.foText.caption,
                      ),
                      SizedBox(height: context.foSpacing.xs),
                    ],
                    Semantics(
                      header: true,
                      child: Text(title, style: context.foText.display),
                    ),
                    if (message != null) ...<Widget>[
                      SizedBox(height: context.foSpacing.sm),
                      Text(
                        message!,
                        style: context.foText.body.copyWith(
                          color: context.foColors.fgMuted,
                        ),
                      ),
                    ],
                    for (final Widget child in children) ...<Widget>[
                      SizedBox(height: context.foSpacing.lg),
                      child,
                    ],
                    if (actions.isNotEmpty) ...<Widget>[
                      SizedBox(height: context.foSpacing.xl),
                      Wrap(
                        spacing: context.foSpacing.sm,
                        runSpacing: context.foSpacing.sm,
                        children: actions,
                      ),
                    ],
                  ],
                ),
              ),
              if (footnote != null) ...<Widget>[
                SizedBox(height: context.foSpacing.lg),
                Text(
                  footnote!,
                  textAlign: TextAlign.center,
                  style: context.foText.body.copyWith(
                    fontSize: context.foText.label.fontSize,
                    color: context.foColors.fgSubtle,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

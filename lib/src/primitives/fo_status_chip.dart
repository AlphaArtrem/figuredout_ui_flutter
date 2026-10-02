import 'package:flutter/material.dart';

import '../theme/fo_context.dart';
import '../tokens/fo_tokens.dart';

/// A small pill carrying a status.
///
/// Prefer [FoStatusChip.tone], or one of the typed vocabularies —
/// [FoStatusChip.entry], [FoStatusChip.order], [FoStatusChip.due]. A tone
/// grounds the ink on the matching `-soft` token, which is the exact pairing
/// `test/tokens/contrast_test.dart` measures — ink on its own wash over the
/// surface is where the web package found `--color-success` failing AA, so it
/// is the pairing worth having covered.
///
/// **A vocabulary is one word and one colour per state, everywhere.** The
/// typed constructors exist so that "Submitted" cannot be green on one screen
/// and blue on the next: the app maps its own status slug onto the enum once,
/// and the tone and the glyph follow from it. The *word* is still the
/// caller's, because the package holds no copy.
///
/// The unnamed constructor takes an arbitrary accent and derives a wash from
/// it at [FoTokens.softWashAlpha]. Same weight, but nothing measures it, so
/// the caller owns the contrast. It exists because an app's own status
/// vocabulary does not always map onto six tones.
///
/// The shape is a pill — a shape no button or field on the page shares — so a
/// status reads as a word and never as something to press.
class FoStatusChip extends StatelessWidget {
  /// Creates a chip tinted from an arbitrary accent.
  const FoStatusChip({
    required this.label,
    required Color this.color,
    this.semanticPrefix,
    this.icon,
    super.key,
  }) : tone = null;

  /// Creates a chip from one of the semantic tones.
  const FoStatusChip.tone({
    required this.label,
    required FoStatusTone this.tone,
    this.semanticPrefix,
    this.icon,
    super.key,
  }) : color = null;

  /// A record's place in the entry workflow — Draft, Submitted, Change
  /// requested, Needs approval. The tone and the glyph come from [status].
  FoStatusChip.entry({
    required FoEntryStatus status,
    required this.label,
    this.semanticPrefix,
    super.key,
  })  : tone = status.tone,
        icon = status.icon,
        color = null;

  /// An order's lifecycle — New, Running, On hold, Completed, Cancelled.
  FoStatusChip.order({
    required FoOrderStatus status,
    required this.label,
    this.semanticPrefix,
    super.key,
  })  : tone = status.tone,
        icon = status.icon,
        color = null;

  /// How a deadline stands — "Due in 16 days", "Due in 7 days", "2 days late".
  /// Which bucket a date falls in is the app's rule; the colour is not.
  FoStatusChip.due({
    required FoDueStatus status,
    required this.label,
    this.semanticPrefix,
    super.key,
  })  : tone = status.tone,
        icon = null,
        color = null;

  /// Visible status text. Caller-supplied, so it can be localized.
  final String label;

  /// The accent. Null when built from a [tone].
  final Color? color;

  /// The semantic tone. Null when built from an explicit [color].
  final FoStatusTone? tone;

  /// Prefixes the announcement, e.g. "Status: Submitted", so the chip is not
  /// read as a lone word with no subject.
  final String? semanticPrefix;

  /// A glyph before the word. Never instead of it: colour and a glyph are
  /// both redundant with the label, which is what lets the label stand alone
  /// for somebody who can see neither.
  final IconData? icon;

  /// The glyph's size, matched to the caption-sized label beside it.
  static const double _iconSize = 14;

  @override
  Widget build(BuildContext context) {
    final (Color ink, Color ground) = tone == null
        ? (color!, color!.withValues(alpha: FoTokens.softWashAlpha))
        : _resolve(context, tone!);

    return Semantics(
      container: true,
      label: semanticPrefix == null ? label : '$semanticPrefix: $label',
      excludeSemantics: true,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: context.foSpacing.md,
          vertical: context.foSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: ground,
          borderRadius: BorderRadius.circular(context.foRadii.pill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (icon != null) ...<Widget>[
              Icon(icon, size: _iconSize, color: ink),
              SizedBox(width: context.foSpacing.xs),
            ],
            // Flexible, so a long word in a narrow cell wraps inside the pill
            // rather than running out of it at 200% text.
            Flexible(
              child: Text(
                label,
                style: context.foText.label.copyWith(color: ink),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static (Color, Color) _resolve(BuildContext context, FoStatusTone tone) =>
      switch (tone) {
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
        FoStatusTone.info => (
            context.foColors.info,
            context.foColors.infoSoft,
          ),
      };
}

/// The semantic tones a chip can carry.
///
/// There is deliberately no `accent` tone: accent is a brand hue for emphasis,
/// not a state, and a status that carries no judgement is [neutral].
enum FoStatusTone {
  /// No judgement — a state that simply is.
  neutral,

  /// Selected, active, current.
  primary,

  /// Done, passed, approved.
  success,

  /// Needs attention but is not broken.
  warning,

  /// Failed, rejected, blocked.
  danger,

  /// Informational.
  info,
}

/// A record's place in an entry workflow: the four states a size-wise entry
/// at any production stage can be in, and the only four.
///
/// Each carries its tone and its glyph, so the mapping lives here once rather
/// than in every list, card and side panel that shows one.
enum FoEntryStatus {
  /// Saved but not counted. Neutral, with a pencil — it is still being written.
  draft(FoStatusTone.neutral, Icons.edit_outlined),

  /// Counted and locked. Success, with a lock — the lock is the point.
  submitted(FoStatusTone.success, Icons.lock_outline),

  /// Somebody asked to change a submitted entry and an owner has not answered.
  /// Info, with a clock — it is waiting, not wrong.
  changeRequested(FoStatusTone.info, Icons.schedule),

  /// Over a limit — more than was ready — and held for an owner's yes.
  /// Warning, with an alert.
  needsApproval(FoStatusTone.warning, Icons.warning_amber_outlined);

  const FoEntryStatus(this.tone, this.icon);

  /// The tone this state is always shown in.
  final FoStatusTone tone;

  /// The glyph this state is always shown with.
  final IconData icon;
}

/// An order's lifecycle.
///
/// Running and Completed deliberately do not share a green: an order that is
/// moving and an order that is finished are the two states a production
/// manager scans a list to tell apart.
enum FoOrderStatus {
  /// Created, nothing done yet — usually worded "New". Neutral.
  notStarted(FoStatusTone.neutral, null),

  /// In production. Primary — current, not finished.
  running(FoStatusTone.primary, null),

  /// Paused on purpose. Warning.
  onHold(FoStatusTone.warning, null),

  /// Finished. Success, with a check.
  completed(FoStatusTone.success, Icons.check),

  /// Stopped for good. Danger.
  cancelled(FoStatusTone.danger, null);

  const FoOrderStatus(this.tone, this.icon);

  /// The tone this state is always shown in.
  final FoStatusTone tone;

  /// The glyph this state is shown with, if any.
  final IconData? icon;
}

/// How a deadline stands. Where the line between [onTrack] and [dueSoon]
/// falls is the app's rule; the colour each side of it gets is not.
enum FoDueStatus {
  /// Comfortably ahead. Neutral — a date that needs nothing is not news.
  onTrack(FoStatusTone.neutral),

  /// Close enough to need watching. Warning.
  dueSoon(FoStatusTone.warning),

  /// Past the date. Danger.
  overdue(FoStatusTone.danger);

  const FoDueStatus(this.tone);

  /// The tone this state is always shown in.
  final FoStatusTone tone;
}

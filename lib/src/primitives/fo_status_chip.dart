import 'package:flutter/material.dart';

import '../theme/fo_context.dart';
import '../tokens/fo_tokens.dart';

/// A small pill carrying a status.
///
/// Prefer [FoStatusChip.tone]. It grounds the ink on the matching `-soft`
/// token, which is the exact pairing `test/tokens/contrast_test.dart`
/// measures — ink on its own wash over the surface is where the web package
/// found `--color-success` failing AA, so it is the pairing worth having
/// covered.
///
/// The unnamed constructor takes an arbitrary accent and derives a wash from
/// it at [FoTokens.softWashAlpha]. Same weight, but nothing measures it, so
/// the caller owns the contrast. It exists because an app's own status
/// vocabulary does not always map onto six tones.
class FoStatusChip extends StatelessWidget {
  /// Creates a chip tinted from an arbitrary accent.
  const FoStatusChip({
    required this.label,
    required Color this.color,
    this.semanticPrefix,
    super.key,
  }) : tone = null;

  /// Creates a chip from one of the semantic tones.
  const FoStatusChip.tone({
    required this.label,
    required FoStatusTone this.tone,
    this.semanticPrefix,
    super.key,
  }) : color = null;

  /// Visible status text. Caller-supplied, so it can be localized.
  final String label;

  /// The accent. Null when built from a [tone].
  final Color? color;

  /// The semantic tone. Null when built from an explicit [color].
  final FoStatusTone? tone;

  /// Prefixes the announcement, e.g. "Status: Submitted", so the chip is not
  /// read as a lone word with no subject.
  final String? semanticPrefix;

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
          horizontal: context.foSpacing.sm,
          vertical: context.foSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: ground,
          borderRadius: BorderRadius.circular(context.foRadii.sm),
        ),
        child: Text(label, style: context.foText.label.copyWith(color: ink)),
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

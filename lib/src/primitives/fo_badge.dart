import 'package:flutter/material.dart';

import '../theme/fo_context.dart';
import '../tokens/fo_tokens.dart';
import 'fo_status_chip.dart';

/// A count or a very short label attached to something else.
///
/// The distinction from `FoStatusChip` is worth keeping, because they look
/// alike and are not: a **chip carries a record's state** and stands on its
/// own line or in its own table cell; a **badge counts or marks the thing it
/// is attached to** — the number on a tab, the dot on a nav item.
///
/// A badge is therefore always small, always secondary, and never the only
/// place a fact appears.
class FoBadge extends StatelessWidget {
  /// Creates a badge.
  const FoBadge({
    required this.label,
    this.tone = FoStatusTone.neutral,
    this.semanticLabel,
    super.key,
  });

  /// A count, or one or two words. Caller-supplied, so it can be localized.
  final String label;

  /// What kind of thing is being counted.
  final FoStatusTone tone;

  /// What the count means — "3 unread". Without it a screen reader announces
  /// a bare number with nothing attaching it to its subject.
  final String? semanticLabel;

  /// A dot with no label, for "there is something here" with no count.
  static const double _dotSize = 8;

  @override
  Widget build(BuildContext context) {
    final (Color ink, Color ground) = _resolve(context, tone);

    return Semantics(
      container: true,
      label: semanticLabel,
      excludeSemantics: semanticLabel != null,
      child: Container(
        constraints: const BoxConstraints(minWidth: _dotSize * 2.5),
        padding: EdgeInsets.symmetric(
          horizontal: context.foSpacing.xs,
          vertical: 1,
        ),
        decoration: BoxDecoration(
          color: ground,
          borderRadius: BorderRadius.circular(context.foRadii.sm),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: context.foText.numeric.copyWith(
            fontSize: FoTokens.fontCaption,
            color: ink,
          ),
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

/// The light/dark switch.
///
/// Three states rather than two: **system** is the default, because an app
/// that ignores the platform's preference is an app the user has to correct
/// every time they change it. A two-state toggle cannot express "follow the
/// system" at all, and defaulting to light silently overrides it.
class FoThemeToggle extends StatelessWidget {
  /// Creates a theme toggle.
  const FoThemeToggle({
    required this.mode,
    required this.onChanged,
    required this.lightLabel,
    required this.darkLabel,
    required this.systemLabel,
    super.key,
  });

  /// The current mode.
  final ThemeMode mode;

  /// Called with the new mode.
  final ValueChanged<ThemeMode> onChanged;

  /// The light option's label. Caller-supplied, so it can be localized.
  final String lightLabel;

  /// The dark option's label.
  final String darkLabel;

  /// The follow-the-system option's label.
  final String systemLabel;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<ThemeMode>(
      segments: <ButtonSegment<ThemeMode>>[
        ButtonSegment<ThemeMode>(
          value: ThemeMode.light,
          icon: const Icon(Icons.light_mode_outlined),
          label: Text(lightLabel),
          tooltip: lightLabel,
        ),
        ButtonSegment<ThemeMode>(
          value: ThemeMode.dark,
          icon: const Icon(Icons.dark_mode_outlined),
          label: Text(darkLabel),
          tooltip: darkLabel,
        ),
        ButtonSegment<ThemeMode>(
          value: ThemeMode.system,
          icon: const Icon(Icons.brightness_auto_outlined),
          label: Text(systemLabel),
          tooltip: systemLabel,
        ),
      ],
      selected: <ThemeMode>{mode},
      showSelectedIcon: false,
      onSelectionChanged: (Set<ThemeMode> selection) =>
          onChanged(selection.first),
      style: ButtonStyle(
        // The track is a hole in the page, which is what a segmented control
        // is: the selected segment sits on the surface above it.
        backgroundColor: WidgetStateProperty.resolveWith((
          Set<WidgetState> states,
        ) {
          return states.contains(WidgetState.selected)
              ? context.foColors.surface
              : context.foColors.surfaceSunken;
        }),
        foregroundColor: WidgetStateProperty.resolveWith((
          Set<WidgetState> states,
        ) {
          return states.contains(WidgetState.selected)
              ? context.foColors.primary
              : context.foColors.fgMuted;
        }),
        side: WidgetStatePropertyAll<BorderSide>(
          BorderSide(color: context.foColors.edge),
        ),
        textStyle: WidgetStatePropertyAll<TextStyle>(context.foText.label),
      ),
    );
  }
}

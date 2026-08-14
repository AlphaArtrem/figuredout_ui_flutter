import 'package:flutter/material.dart';

import 'fo_tokens.dart';

/// The semantic colour set, exposed via `context.foColors`.
///
/// The four surfaces are a **ladder, and the order is meaning**:
/// [surfaceSunken] is a hole, [bg] is the page, [surface] rests, and
/// [surfaceRaised] is lifted. Never reach for a lighter surface to create
/// emphasis — reach for the step that says what the thing *is*.
///
/// Every field must appear in [lerp]. A field missing from `lerp` silently
/// freezes at its `from` value for the whole of a theme animation, and nothing
/// in the analyzer will tell you — `test/theme/fo_theme_ext_test.dart` will.
@immutable
class FoColors {
  /// Creates a semantic colour set. Prefer [FoColors.light] / [FoColors.dark].
  const FoColors({
    required this.bg,
    required this.surface,
    required this.surfaceRaised,
    required this.surfaceSunken,
    required this.fg,
    required this.fgMuted,
    required this.fgSubtle,
    required this.edge,
    required this.edgeStrong,
    required this.primary,
    required this.primaryHover,
    required this.primaryFg,
    required this.primarySoft,
    required this.focusRing,
    required this.success,
    required this.successSoft,
    required this.warning,
    required this.warningSoft,
    required this.danger,
    required this.dangerFg,
    required this.dangerSoft,
    required this.info,
    required this.infoSoft,
    required this.accent,
    required this.accentFg,
  });

  /// The page itself.
  final Color bg;

  /// Cards, tables, panels — anything resting on the page.
  final Color surface;

  /// Anything lifted: a dialog, a menu, a toast, a hovered row, an open tile.
  final Color surfaceRaised;

  /// Holes: text fields, segmented-control tracks, wells.
  final Color surfaceSunken;

  /// Primary ink.
  final Color fg;

  /// Secondary ink.
  final Color fgMuted;

  /// Tertiary ink — the quietest step that is still body-legible.
  final Color fgSubtle;

  /// Hairlines.
  final Color edge;

  /// A hairline that has to be found rather than merely obeyed.
  final Color edgeStrong;

  /// The brand hue.
  final Color primary;

  /// [primary] under a pointer.
  final Color primaryHover;

  /// Ink on [primary].
  final Color primaryFg;

  /// A wash of [primary] — chips, selected rows, soft fills.
  final Color primarySoft;

  /// The one focus treatment: a ring in this colour.
  final Color focusRing;

  /// Success.
  final Color success;

  /// A wash of [success].
  final Color successSoft;

  /// Warning.
  final Color warning;

  /// A wash of [warning].
  final Color warningSoft;

  /// Danger.
  final Color danger;

  /// Ink on [danger]. Danger carries its own ink; [primaryFg] is not a
  /// substitute — in dark mode it is a near-black green and unreadable on red.
  final Color dangerFg;

  /// A wash of [danger].
  final Color dangerSoft;

  /// Information.
  final Color info;

  /// A wash of [info].
  final Color infoSoft;

  /// Accent.
  final Color accent;

  /// Ink on [accent].
  final Color accentFg;

  /// The light theme's colours.
  static const FoColors light = FoColors(
    bg: FoTokens.bg,
    surface: FoTokens.surface,
    surfaceRaised: FoTokens.surfaceRaised,
    surfaceSunken: FoTokens.surfaceSunken,
    fg: FoTokens.fg,
    fgMuted: FoTokens.fgMuted,
    fgSubtle: FoTokens.fgSubtle,
    edge: FoTokens.edge,
    edgeStrong: FoTokens.edgeStrong,
    primary: FoTokens.primary,
    primaryHover: FoTokens.primaryHover,
    primaryFg: FoTokens.primaryFg,
    primarySoft: FoTokens.primarySoft,
    focusRing: FoTokens.focusRing,
    success: FoTokens.success,
    successSoft: FoTokens.successSoft,
    warning: FoTokens.warning,
    warningSoft: FoTokens.warningSoft,
    danger: FoTokens.danger,
    dangerFg: FoTokens.dangerFg,
    dangerSoft: FoTokens.dangerSoft,
    info: FoTokens.info,
    infoSoft: FoTokens.infoSoft,
    accent: FoTokens.accent,
    accentFg: FoTokens.accentFg,
  );

  /// The dark theme's colours.
  static const FoColors dark = FoColors(
    bg: FoTokens.bgDark,
    surface: FoTokens.surfaceDark,
    surfaceRaised: FoTokens.surfaceRaisedDark,
    surfaceSunken: FoTokens.surfaceSunkenDark,
    fg: FoTokens.fgDark,
    fgMuted: FoTokens.fgMutedDark,
    fgSubtle: FoTokens.fgSubtleDark,
    edge: FoTokens.edgeDark,
    edgeStrong: FoTokens.edgeStrongDark,
    primary: FoTokens.primaryDark,
    primaryHover: FoTokens.primaryHoverDark,
    primaryFg: FoTokens.primaryFgDark,
    primarySoft: FoTokens.primarySoftDark,
    focusRing: FoTokens.focusRingDark,
    success: FoTokens.successDark,
    successSoft: FoTokens.successSoftDark,
    warning: FoTokens.warningDark,
    warningSoft: FoTokens.warningSoftDark,
    danger: FoTokens.dangerDark,
    dangerFg: FoTokens.dangerFgDark,
    dangerSoft: FoTokens.dangerSoftDark,
    info: FoTokens.infoDark,
    infoSoft: FoTokens.infoSoftDark,
    accent: FoTokens.accentDark,
    accentFg: FoTokens.accentFgDark,
  );

  /// Every field, by name — the basis of the light/dark tables in the
  /// Widgetbook palette use case and of the generated contrast report, and the
  /// list `test/theme/fo_theme_ext_test.dart` checks [lerp] against.
  ///
  /// Adding a field to this class means adding it here *and* to [lerp]; the
  /// test fails otherwise.
  Map<String, Color> toMap() => <String, Color>{
        'bg': bg,
        'surface': surface,
        'surfaceRaised': surfaceRaised,
        'surfaceSunken': surfaceSunken,
        'fg': fg,
        'fgMuted': fgMuted,
        'fgSubtle': fgSubtle,
        'edge': edge,
        'edgeStrong': edgeStrong,
        'primary': primary,
        'primaryHover': primaryHover,
        'primaryFg': primaryFg,
        'primarySoft': primarySoft,
        'focusRing': focusRing,
        'success': success,
        'successSoft': successSoft,
        'warning': warning,
        'warningSoft': warningSoft,
        'danger': danger,
        'dangerFg': dangerFg,
        'dangerSoft': dangerSoft,
        'info': info,
        'infoSoft': infoSoft,
        'accent': accent,
        'accentFg': accentFg,
      };

  /// Interpolates every field. **Keep this exhaustive** — see the class doc.
  static FoColors lerp(FoColors a, FoColors b, double t) => FoColors(
        bg: Color.lerp(a.bg, b.bg, t)!,
        surface: Color.lerp(a.surface, b.surface, t)!,
        surfaceRaised: Color.lerp(a.surfaceRaised, b.surfaceRaised, t)!,
        surfaceSunken: Color.lerp(a.surfaceSunken, b.surfaceSunken, t)!,
        fg: Color.lerp(a.fg, b.fg, t)!,
        fgMuted: Color.lerp(a.fgMuted, b.fgMuted, t)!,
        fgSubtle: Color.lerp(a.fgSubtle, b.fgSubtle, t)!,
        edge: Color.lerp(a.edge, b.edge, t)!,
        edgeStrong: Color.lerp(a.edgeStrong, b.edgeStrong, t)!,
        primary: Color.lerp(a.primary, b.primary, t)!,
        primaryHover: Color.lerp(a.primaryHover, b.primaryHover, t)!,
        primaryFg: Color.lerp(a.primaryFg, b.primaryFg, t)!,
        primarySoft: Color.lerp(a.primarySoft, b.primarySoft, t)!,
        focusRing: Color.lerp(a.focusRing, b.focusRing, t)!,
        success: Color.lerp(a.success, b.success, t)!,
        successSoft: Color.lerp(a.successSoft, b.successSoft, t)!,
        warning: Color.lerp(a.warning, b.warning, t)!,
        warningSoft: Color.lerp(a.warningSoft, b.warningSoft, t)!,
        danger: Color.lerp(a.danger, b.danger, t)!,
        dangerFg: Color.lerp(a.dangerFg, b.dangerFg, t)!,
        dangerSoft: Color.lerp(a.dangerSoft, b.dangerSoft, t)!,
        info: Color.lerp(a.info, b.info, t)!,
        infoSoft: Color.lerp(a.infoSoft, b.infoSoft, t)!,
        accent: Color.lerp(a.accent, b.accent, t)!,
        accentFg: Color.lerp(a.accentFg, b.accentFg, t)!,
      );
}

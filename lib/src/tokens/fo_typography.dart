import 'package:flutter/material.dart';

import 'fo_tokens.dart';

/// The type ramp, exposed via `context.foText`.
///
/// Two families, and the split carries meaning: **mono uppercase captions
/// *name* values, mono tabular figures *are* values.** A form [label]
/// instructs rather than names, so it stays sentence-case semibold sans.
///
/// Every style here passes `package: FoTokens.fontPackage` alongside its
/// family. Without it the family resolves against the consuming app's font
/// manifest, finds nothing, and falls back to Roboto with no warning.
@immutable
class FoTextStyles {
  /// Creates a type ramp. Prefer [FoTextStyles.forColors].
  const FoTextStyles({
    required this.display,
    required this.title,
    required this.subtitle,
    required this.body,
    required this.label,
    required this.caption,
    required this.numeric,
  });

  /// The page-level scale. Reserve it for the thing a page is navigated by.
  final TextStyle display;

  /// A section.
  final TextStyle title;

  /// A subsection, or a control's own heading.
  final TextStyle subtitle;

  /// Prose, table cells, everything unmarked.
  final TextStyle body;

  /// A form label. It instructs rather than names, so it stays sentence-case
  /// semibold sans — the one documented exception to the mono-caption rule.
  final TextStyle label;

  /// A mono uppercase caption that *names* a value.
  ///
  /// The uppercasing is the caller's job — Flutter has no `text-transform`.
  /// Uppercase the string at the call site (or use the `FoCaption` primitive
  /// once it lands) rather than shipping mixed-case text in this style.
  final TextStyle caption;

  /// A figure. Mono with tabular figures, so digits align down a column.
  final TextStyle numeric;

  /// Builds the ramp for a theme's ink.
  ///
  /// [fg] carries prose and headings; [fgMuted] carries the caption, which
  /// names rather than states and should never compete with the value beside
  /// it.
  ///
  /// [fontFamilyFallback] is the consuming app's own script coverage — a
  /// Devanagari face, say, which Geist does not have — tried in order after
  /// Geist for any glyph it lacks. The families are looked up in the
  /// **consuming app's** font manifest, as written.
  ///
  /// That is why it is a parameter and not something to `apply` afterwards.
  /// Every style here carries `package: 'figuredout_ui'`, and `TextStyle`
  /// applies the package **in its `fontFamilyFallback` getter**: a fallback
  /// added to one of these styles by `apply`, `copyWith` or `merge` comes back
  /// as `packages/figuredout_ui/<family>`, is looked up in this package's
  /// manifest, is not there, and the platform's own face is used instead —
  /// silently, at a different metric, so line heights jump between scripts.
  /// With a fallback, each style is built with no `package` and the family
  /// already resolved (`packages/figuredout_ui/Geist`), so Geist still comes
  /// from here and the fallback from the app.
  factory FoTextStyles.forColors({
    required Color fg,
    required Color fgMuted,
    List<String>? fontFamilyFallback,
  }) {
    final List<String>? fallback =
        fontFamilyFallback == null || fontFamilyFallback.isEmpty
            ? null
            : List<String>.unmodifiable(fontFamilyFallback);

    TextStyle style({
      required String family,
      required double size,
      required FontWeight weight,
      required Color color,
      double? letterSpacing,
      List<FontFeature>? fontFeatures,
    }) =>
        fallback == null
            ? TextStyle(
                fontFamily: family,
                package: FoTokens.fontPackage,
                fontSize: size,
                fontWeight: weight,
                letterSpacing: letterSpacing,
                color: color,
                fontFeatures: fontFeatures,
              )
            : TextStyle(
                // Resolved by hand, so no `package` is left to rewrite the
                // fallback below into this package's manifest.
                fontFamily: 'packages/${FoTokens.fontPackage}/$family',
                fontFamilyFallback: fallback,
                fontSize: size,
                fontWeight: weight,
                letterSpacing: letterSpacing,
                color: color,
                fontFeatures: fontFeatures,
              );

    return FoTextStyles(
      display: style(
        family: FoTokens.fontSans,
        size: FoTokens.fontDisplay,
        weight: FontWeight.w700,
        color: fg,
      ),
      title: style(
        family: FoTokens.fontSans,
        size: FoTokens.fontTitle,
        weight: FontWeight.w600,
        color: fg,
      ),
      subtitle: style(
        family: FoTokens.fontSans,
        size: FoTokens.fontSubtitle,
        weight: FontWeight.w600,
        color: fg,
      ),
      body: style(
        family: FoTokens.fontSans,
        size: FoTokens.fontBody,
        weight: FontWeight.w400,
        color: fg,
      ),
      label: style(
        family: FoTokens.fontSans,
        size: FoTokens.fontLabel,
        weight: FontWeight.w600,
        color: fg,
      ),
      caption: style(
        family: FoTokens.fontMono,
        size: FoTokens.fontCaption,
        weight: FontWeight.w500,
        letterSpacing: FoTokens.captionLetterSpacing,
        color: fgMuted,
      ),
      numeric: style(
        family: FoTokens.fontMono,
        size: FoTokens.fontBody,
        weight: FontWeight.w500,
        color: fg,
        fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
      ),
    );
  }

  /// Every style, by name — the basis of the Widgetbook type-ramp use case.
  Map<String, TextStyle> toMap() => <String, TextStyle>{
        'display': display,
        'title': title,
        'subtitle': subtitle,
        'body': body,
        'label': label,
        'caption': caption,
        'numeric': numeric,
      };

  /// Interpolates every style.
  static FoTextStyles lerp(FoTextStyles a, FoTextStyles b, double t) =>
      FoTextStyles(
        display: TextStyle.lerp(a.display, b.display, t)!,
        title: TextStyle.lerp(a.title, b.title, t)!,
        subtitle: TextStyle.lerp(a.subtitle, b.subtitle, t)!,
        body: TextStyle.lerp(a.body, b.body, t)!,
        label: TextStyle.lerp(a.label, b.label, t)!,
        caption: TextStyle.lerp(a.caption, b.caption, t)!,
        numeric: TextStyle.lerp(a.numeric, b.numeric, t)!,
      );
}

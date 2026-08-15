import 'package:flutter/material.dart';

import '../tokens/fo_colors.dart';
import '../tokens/fo_layout.dart';
import '../tokens/fo_tokens.dart';
import '../tokens/fo_typography.dart';
import 'fo_theme_ext.dart';
import 'fo_window_class.dart';

/// Builds the [ThemeData] the package's components live inside.
///
/// The Material theme it produces is deliberately flattened: **every**
/// elevation is zero and every surface tint is transparent, because elevation
/// in this system is painted by `FoShadows` through `BoxDecoration.boxShadow`,
/// not by Material. A `Card(elevation: 2)` anywhere in a consuming app is a
/// bug — it draws a black shadow that greys out the tinted ground beneath it.
///
/// The Material roles are wired up so that a stray framework widget (a
/// `Tooltip`, a `MenuAnchor`, a date picker) lands somewhere sane rather than
/// on Material's default purple. Package components read `context.foColors`
/// instead; the mapping here is a safety net, not the interface.
abstract final class FoTheme {
  /// The light theme.
  static ThemeData light() =>
      _build(FoColors.light, FoThemeExt.light(), Brightness.light);

  /// The dark theme.
  static ThemeData dark() =>
      _build(FoColors.dark, FoThemeExt.dark(), Brightness.dark);

  static ThemeData _build(FoColors c, FoThemeExt ext, Brightness brightness) {
    final ColorScheme scheme = ColorScheme.fromSeed(
      seedColor: c.primary,
      brightness: brightness,
      primary: c.primary,
      onPrimary: c.primaryFg,
      primaryContainer: c.primarySoft,
      onPrimaryContainer: c.fg,
      secondary: c.fgMuted,
      onSecondary: c.surface,
      secondaryContainer: c.surfaceSunken,
      onSecondaryContainer: c.fg,
      tertiary: c.accent,
      onTertiary: c.accentFg,
      error: c.danger,
      onError: c.dangerFg,
      errorContainer: c.dangerSoft,
      onErrorContainer: c.danger,
      surface: c.surface,
      onSurface: c.fg,
      onSurfaceVariant: c.fgMuted,
      outline: c.edge,
      outlineVariant: c.edge,
    ).copyWith(
      // M3 raises a surface by tinting it with the primary hue. This
      // system raises it by moving it up the surface ladder instead, so
      // the tint has to be switched off or the two fight.
      surfaceTint: Colors.transparent,
    );

    return ThemeData(
      colorScheme: scheme,
      extensions: <ThemeExtension<dynamic>>[ext],
      scaffoldBackgroundColor: c.bg,
      canvasColor: c.bg,
      textTheme: _textTheme(ext.text, c),
      // One focus treatment. Material widgets outside the package fall back to
      // a blue overlay otherwise, which is a second focus vocabulary.
      focusColor: c.focusRing,
      dividerColor: c.edge,
      dividerTheme: DividerThemeData(
        color: c.edge,
        thickness: FoLayout.hairlineWidth,
        space: FoLayout.hairlineWidth,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: c.surface,
        foregroundColor: c.fg,
        elevation: 0,
        scrolledUnderElevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: ext.text.title,
      ),
      cardTheme: CardThemeData(
        color: c.surface,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ext.radii.card),
          side: BorderSide(color: c.edge),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: c.surfaceRaised,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: ext.text.title,
        contentTextStyle: ext.text.body,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ext.radii.card),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c.surfaceRaised,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(ext.radii.lg),
          ),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: c.surfaceRaised,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        textStyle: ext.text.body,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ext.radii.md),
          side: BorderSide(color: c.edge),
        ),
      ),
      menuTheme: MenuThemeData(
        style: MenuStyle(
          backgroundColor: WidgetStatePropertyAll<Color>(c.surfaceRaised),
          elevation: const WidgetStatePropertyAll<double>(0),
          surfaceTintColor: const WidgetStatePropertyAll<Color>(
            Colors.transparent,
          ),
        ),
      ),
      // Left to Material this is elevation 3 over a tinted surface, which is
      // the one place in the app a shadow would appear that FoShadows did not
      // paint — rule §3.2. The bar is chrome beside the page, so it takes the
      // same resting surface the sidebar does.
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: c.surface,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        indicatorColor: c.primarySoft,
        iconTheme: WidgetStateProperty.resolveWith((Set<WidgetState> states) {
          return IconThemeData(
            color:
                states.contains(WidgetState.selected) ? c.primary : c.fgMuted,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((
          Set<WidgetState> states,
        ) {
          return ext.text.label.copyWith(
            color:
                states.contains(WidgetState.selected) ? c.primary : c.fgMuted,
          );
        }),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: c.surface,
        elevation: 0,
        indicatorColor: c.primarySoft,
        selectedIconTheme: IconThemeData(color: c.primary),
        unselectedIconTheme: IconThemeData(color: c.fgMuted),
        selectedLabelTextStyle: ext.text.label.copyWith(color: c.primary),
        unselectedLabelTextStyle: ext.text.label.copyWith(color: c.fgMuted),
      ),
      navigationDrawerTheme: NavigationDrawerThemeData(
        backgroundColor: c.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        indicatorColor: c.primarySoft,
      ),
      drawerTheme: DrawerThemeData(
        backgroundColor: c.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      // Fields are holes in the page: sunken, not raised.
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.surfaceSunken,
        labelStyle: ext.text.label.copyWith(color: c.fgMuted),
        hintStyle: ext.text.body.copyWith(color: c.fgSubtle),
        errorStyle: ext.text.label.copyWith(color: c.danger),
        contentPadding: EdgeInsets.symmetric(
          horizontal: ext.spacing.lg,
          vertical: ext.spacing.md,
        ),
        border: _fieldBorder(ext.radii.md, c.edge),
        enabledBorder: _fieldBorder(ext.radii.md, c.edge),
        focusedBorder: _fieldBorder(ext.radii.md, c.primary),
        errorBorder: _fieldBorder(ext.radii.md, c.danger),
        focusedErrorBorder: _fieldBorder(ext.radii.md, c.danger),
        disabledBorder: _fieldBorder(ext.radii.md, c.edge),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: c.primary,
          foregroundColor: c.primaryFg,
          disabledBackgroundColor: c.surfaceSunken,
          disabledForegroundColor: c.fgSubtle,
          elevation: 0,
          minimumSize: const Size(0, FoLayout.minTouchTarget),
          textStyle: ext.text.subtitle,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ext.radii.md),
          ),
        ),
      ),
      // ElevatedButton is a contradiction in a system with three painted
      // elevation steps. It is styled to be indistinguishable from
      // FilledButton so that reaching for it is harmless rather than
      // off-system.
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: c.primary,
          foregroundColor: c.primaryFg,
          elevation: 0,
          shadowColor: Colors.transparent,
          minimumSize: const Size(0, FoLayout.minTouchTarget),
          textStyle: ext.text.subtitle,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ext.radii.md),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: c.fg,
          minimumSize: const Size(0, FoLayout.minTouchTarget),
          textStyle: ext.text.subtitle,
          side: BorderSide(color: c.edgeStrong),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ext.radii.md),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: c.primary,
          minimumSize: const Size(0, FoLayout.minTouchTarget),
          textStyle: ext.text.subtitle,
        ),
      ),
      iconTheme: IconThemeData(color: c.fgMuted),
      chipTheme: ChipThemeData(
        backgroundColor: c.surfaceSunken,
        selectedColor: c.primarySoft,
        labelStyle: ext.text.label,
        side: BorderSide(color: c.edge),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ext.radii.sm),
        ),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: c.surfaceRaised,
          borderRadius: BorderRadius.circular(ext.radii.sm),
          border: Border.all(color: c.edge),
          boxShadow: ext.shadows.overlay,
        ),
        textStyle: ext.text.body,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: c.fg,
        contentTextStyle: ext.text.body.copyWith(color: c.bg),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ext.radii.card),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: c.primary,
        linearTrackColor: c.surfaceSunken,
        circularTrackColor: c.surfaceSunken,
      ),
      splashFactory: InkSparkle.splashFactory,
    );
  }

  static OutlineInputBorder _fieldBorder(double radius, Color color) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius),
        borderSide: BorderSide(color: color),
      );

  /// Maps the ramp onto Material's slots, so a framework widget that reads
  /// `Theme.of(context).textTheme` still gets Geist rather than Roboto.
  static TextTheme _textTheme(FoTextStyles t, FoColors c) => TextTheme(
        displayLarge: t.display,
        displayMedium: t.display,
        displaySmall: t.display,
        headlineLarge: t.display,
        headlineMedium: t.title,
        headlineSmall: t.title,
        titleLarge: t.title,
        titleMedium: t.subtitle,
        titleSmall: t.label,
        bodyLarge: t.body.copyWith(fontSize: FoTokens.fontSubtitle),
        bodyMedium: t.body,
        bodySmall: t.body.copyWith(
          fontSize: FoTokens.fontLabel,
          color: c.fgMuted,
        ),
        labelLarge: t.label,
        labelMedium: t.label,
        labelSmall: t.caption,
      );

  // ─── Window-class helpers ─────────────────────────────────────────────────

  /// The layout band for [context].
  static FoWindowClass windowClass(BuildContext context) =>
      FoWindowClass.of(context);

  /// True below 600 logical pixels.
  static bool isCompact(BuildContext context) =>
      windowClass(context) == FoWindowClass.compact;

  /// True in the 600–900 band.
  static bool isMedium(BuildContext context) =>
      windowClass(context) == FoWindowClass.medium;

  /// True for anything that is not a phone — see
  /// [FoWindowClass.isAtLeastMedium] for why this is not "at least expanded".
  static bool isExpanded(BuildContext context) =>
      windowClass(context).isAtLeastMedium;
}

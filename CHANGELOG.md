# Changelog

## Unreleased

### Added

- Tokens: `FoTokens`, `FoColors`, `FoTextStyles`, `FoShadows`, `FoMotion`, `FoLayout`
  (`FoSpacing` / `FoRadii`) and `FoChartColors`. Colours ported verbatim from
  `@figuredout/ui-web`'s `styles/tokens.css`; metrics kept from Luxe, because the consuming
  apps run on shop-floor tablets.
- Theme: `FoTheme.light()` / `.dark()`, `FoThemeExt`, `FoWindowClass` and the `context.fo*`
  extension. Every Material elevation is flattened to zero and every surface tint made
  transparent — elevation is painted by `FoShadows`, not by Material.
- Geist and Geist Mono static weights vendored into `lib/fonts/`, package-qualified so they
  resolve inside a consuming app.
- `test/tokens/contrast_test.dart`, which also generates `docs/contrast-report.md`;
  `test/tokens/no_literals_test.dart`; and `test/theme/` covering `lerp` completeness and
  the font-package argument.
- `widgetbook/` — a separate package carrying the Foundations use cases: palette with
  measured contrast, type ramp, spacing ruler, the three elevation steps, and motion.

### Known

- Light-mode `primary` (`#15803d`) is below AA on two grounds: 4.16:1 on `surfaceSunken`
  and 4.11:1 on its own 12% wash over `surface`. Both are waived and documented in
  `docs/contrast-report.md`. The colours are ported verbatim, so the fix belongs in
  `@figuredout/ui-web` first — the same way `--color-success` was darkened there.

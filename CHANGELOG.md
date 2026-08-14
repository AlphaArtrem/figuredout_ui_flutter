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

### Added — phase 3, primitives

- `FoButton` (+ `FoButtonVariant`), `FoActionButton`, `FoLoadingButton`. Destructive carries
  `dangerFg`, not `primaryFg` and not `surface` (G4). A loading button holds its label's width
  so a row of actions does not reflow mid-submit.
- `FoFocusRing` — the one focus treatment, a 4dp ring in `focusRing`, painted through
  `foregroundDecoration`. Every interactive component composes it, so keyboard focus is one
  idea rather than one per Material widget.
- `FoCard`, deliberately **not** built on Material's `Card`: its hairline lives in
  `foregroundDecoration` so a clipped child's full-bleed band cannot cover it (rule §3.1), and
  its elevation comes from `FoShadows` rather than Material's black shadow plus surface tint.
  A tappable card lifts to `surfaceRaised` on hover.
- `FoSectionSurface`, `FoSectionHeader`, `FoStatusChip` (+ `FoStatusTone`), `FoTextField`,
  `FoDropdownField`, `FoSkeleton` / `FoSkeletonList`, `FoBooleanCell`, `FoHint`, `FoSpinner`,
  and `foOverlaySurface` — the floating surface stated once, the analogue of the web package's
  `POPOVER_SURFACE`.
- Widgetbook: 14 Primitives use cases under `02 Primitives`, and the layout test extended to
  cover them.

### Changed from the Luxe originals

- `FoStatusChip.tone` grounds its ink on the real `-soft` token, which is the pairing
  `contrast_test.dart` measures. The arbitrary-colour constructor survives for an app's own
  status vocabulary but is not covered by that test.
- `FoBooleanCell` and `FoHint` take their strings from the caller rather than reaching into an
  app's l10n or hint registry — that vocabulary is the app's.
- `FoHint` takes an `onCompactTap` callback instead of calling a toast directly; the toast
  lands in phase 4.

### Deferred to phase 4

- The dirty-form hook. Luxe's fields called `LuxeFormScope.markDirty` on every change, so
  closing a form with unsaved edits asks first. `FoFormScope` ships with the forms group;
  until then a host form must watch `onChanged` itself. Noted on both field classes.

### Added — phase 4, patterns

- Feedback: `FoToast` (+ `FoToastAction`), `FoInfoBanner` (+ `FoBannerTone`, and an `.error`
  constructor that requires a retry), `FoEmptyState` with its three constructors.
- Overlays: `FoDialog` — confirm, destructive and info — and `FoFormPresenter`, the one way to
  present a form. It owns the dialog-versus-sheet breakpoint, the root navigator, and the
  dirty-form guard, all three of which are easy to get right once and impossible to get right
  thirty times.
- Forms: `FoFormScope` / `FoFormController`, `FoFormSurface`, `FoFormActions` (+ `FoFormAction`),
  `FoFormSection` / `FoFormInlineRow` / `FoFormInlineItem`, `FoFormValidation`.
- Data: `FoDataTable` (+ `FoTableColumn`, `FoColumnSize`) — a table on a wide window, cards on a
  narrow one, from one set of columns — plus `FoPaginationBar`, `FoFilterBar`,
  `FoListSearchField` and `FoResponsiveTileGrid`.
- Layout: `FoScaffold` and `FoAppBar`.
- `data_table_2` is now a dependency. Flutter's own `DataTable` cannot size columns
  proportionally or scroll a fixed header.
- Widgetbook: 11 use cases under `03 Patterns`, covered by the layout test.

### Fixed in the port

- The dirty-form hook deferred from phase 3 is wired: `FoTextField` and `FoDropdownField` mark
  the enclosing surface dirty on change, so closing a form with unsaved edits asks first.
- `FoDataTable`'s frame draws its hairline in `foregroundDecoration`. Luxe's original used
  `Border.all` inside a `ClipRRect`, so the heading row's own background covered the frame's
  top edge — the same §3.1 bug `FoCard` exists to prevent.
- `FoToast` and `FoDialog` sit on `surfaceRaised` rather than `surface`: both cover the page, and
  under the new ladder `surface` no longer means "lifted" (G5).
- `FoToast` drops `elevation: 3` for a painted overlay shadow, per rule §3.2.

### Changed from the Luxe originals

- `FoPaginationBar` takes its counts already worded. "1–20 of 340" is a sentence, and building
  one from parts inside a design system produces a string that cannot be reordered for another
  language.
- `FoFormPresenter` takes a `FoDiscardCopy` rather than reaching into an app's l10n.
- `FoScaffold.reactiveBuilder` is a static hook an app sets once, so `primaryActionBuilder`'s
  reads stay tracked without the package depending on MobX. Luxe's guardrail — permission-gated
  actions evaluated inside an observer *by the design system* — survives the port intact.

### Known

- Light-mode `primary` (`#15803d`) is below AA on two grounds: 4.16:1 on `surfaceSunken`
  and 4.11:1 on its own 12% wash over `surface`. Both are waived and documented in
  `docs/contrast-report.md`. The colours are ported verbatim, so the fix belongs in
  `@figuredout/ui-web` first — the same way `--color-success` was darkened there.

# Changelog

## 0.3.0

**Ported the responsive fixes from `@figuredout/ui-web`'s `db953bf`** ("Make the system hold
together on a phone") — the one web commit since the Flutter port's baseline (`c7e0e83`).

### Changed — breaking

- **`FoPaginationBar` gained a numbered track.** It used to be just
  `totalLabel · ‹ · pageLabel · ›`; it now shows as many page numbers as its own width holds,
  anchored on first, current and last, and drops `totalLabel` / `pageLabel` below 480 logical
  pixels — the track's own highlighted tile carries the same information at that width. Fitting
  is measured on the widget, not the window, the same reason web's version measures on the
  component rather than the viewport: a bar can be handed a narrow column on a wide screen.
  Adds a required `pageSemanticLabel` — the track needs a per-tile accessible name and the
  package holds no copy.

### Changed

- **`FoStageFunnel`'s label and count now sit above a full-width bar at every width**, not only
  below a 280px threshold. Between a fixed label and a fixed count the bar was the only flexible
  thing in the row, so it was what reached zero width first as the row narrowed.
- **`FoToast`'s action is `FoButton(variant: tertiary)`, not a bare `TextButton`.** Unfilled text
  right after a message reads as padding that failed to line up with the line above it; the tint
  gives the padding somewhere to belong.
- **`FoShellAppBar` gained an optional `status` slot**, beside the title — ambient state for the
  app as a whole (a sync indicator, an environment tag), rather than another action on the right.

## 0.2.1

### Fixed — found by Luxe consuming the package

Three defects the package's own tests could not have found, because all three
need a *consumer* to place a widget the package never places itself.

- **`FoCard` now carries a `Material` inside its fill, always** — not only when
  it is tappable. Any Material child a caller puts in (a `ListTile`, a `Switch`)
  paints its ink on the nearest Material ancestor, which without this sits
  *above* the card's fill, so the ink lands behind the card. Flutter asserts
  about it rather than merely looking wrong, so a form full of list rows failed
  all at once.
- **`FoEntityPickerField`'s option rows** had the same shape of bug against
  `foOverlaySurface`.
- **`FoShellAppBar.accountMenu` is a `Widget?`, not a `FoAccountMenuButton?`.**
  The name it shows resolves when session restore completes, after the first
  frame, so an app wraps the button in its own observer and passes that — which
  the tighter type made impossible.

### Added

- **`FoSectionHeader.onTitleLongPress`** — the hint's second route. The dot is
  small and a tablet has no hover, so long-pressing the title reaches the same
  explanation. Luxe had this and it would have been lost in the port.

## 0.2.0

**The Luxe port is complete.** Every `Luxe*` component in `apps/app/lib/design/` now has a
`Fo*` counterpart, which is what phase 8 — Luxe consuming the package — was waiting on.

### Added — completing the Luxe port

- `FoDetailTable` (+ `FoDetailTableSection`, `FoDetailTableItem`, `FoDetailTableColumn`,
  `FoDetailTableRow`) — grouped fields and small tables on a detail screen. Distinct from
  `FoDescriptionList`, which is one flat list of pairs.
- `FoEntityPickerField` (+ `FoEntityPickerOption`, `FoEntityPickerCopy`) — a searchable picker
  for when a dropdown has too many options. It presents through `FoFormPresenter`, so it honours
  the dialog-versus-sheet breakpoint instead of always being a sheet.
- `showFoTextPrompt` — the one-field dialog, also through the presenter.
- `FoMotion.searchDebounce`. The `no_literals` guard caught the picker's 300ms debounce, which
  is the guard doing exactly its job: a duration in a component is a duration nobody can find.

- `FoMatrixTable` (+ `FoMatrixColumn`, `FoMatrixRow`, `FoMatrixSection`, `FoMatrixSummaryRow`)
  and its cell parts `FoMatrixHeaderText`, `FoMatrixNumericCell`, `FoMatrixTotalText`,
  `FoMatrixValidationText` — the fixed-width grid a size breakdown takes. Distinct from
  `FoDataTable`: a data table is a list of records that happens to be tabular and reflows to
  cards; a matrix is a grid where a cell's position in two dimensions is its meaning, so it
  keeps its shape and scrolls sideways.

### Fixed in the matrix port

- The frame draws its hairline in `foregroundDecoration`. Luxe's original used `Border.all`
  inside a `ClipRRect`, so the heading row and the summary row covered the frame's top and
  bottom edges — the same §3.1 bug `FoDataTable` had.
- Heading cells and the group, section and summary bands sit on `surfaceSunken` rather than on
  `surface`, matching `FoDataTable`'s heading row. In Luxe they were `surface` and `background`,
  which under the new ladder would have left a header indistinguishable from a data row (G5).
- `FoMatrixNumericCell` marks the enclosing `FoFormSurface` dirty on change, exactly as
  `FoTextField` does. Luxe's cell did not, so closing a size grid discarded the edits without
  asking — the guard every other field gets for free.
- `FoMatrixTotalText` uses `FoTextStyles.numeric` rather than the subtitle scale, so a column of
  totals aligns on its digits.

- `FoShellScaffold` (+ `FoNavGroup`, `FoNavItem`, `FoNavDestination`, `FoNavSheet`,
  `FoNavAction`) — the application shell. **One navigation model, three layouts**: a labelled
  sidebar on expanded, an icon-only rail on medium, a bottom bar on compact. An app that builds
  its phone navigation separately from its desktop navigation ends up with two that disagree
  about what exists.
- `FoShellAppBar` and `FoAccountMenuButton` (+ `FoAccountMenuItem`). Distinct from `FoAppBar`,
  which titles a *page*; this one titles the application and carries the account menu.
- `navigationBarTheme`. Material's bottom bar defaults to elevation 3 over a tinted surface,
  which was the one place in a consuming app a shadow appeared that `FoShadows` had not painted.

### Changed from the Luxe originals

- The shell holds no routes, no permissions and no l10n. Luxe's version built a thirteen-item
  registry from `PermissionKeys`, `RouteNames`, `AppLocalizations` and four feature entry
  screens, all inside the widget. The package takes the finished model and the current
  `selectedItemId`; the registry stays in Luxe, which is where that vocabulary belongs.
- Sidebar rows are one widget in two shapes rather than a `ListTile` and a hand-rolled rail
  tile. The two shared a selected state that had already drifted, and the `ListTile` version
  carried a Material paint warning Luxe had a regression test for.
- The sidebar's trailing hairline moved to `foregroundDecoration` (§3.1): a selected tile paints
  its ground to the full width of the column, so a border in the same decoration as the fill
  disappeared one row at a time.
- `FoAccountMenuButton` takes `userName` and its items instead of reading `AuthStore` and
  raising its own sign-out confirmation. Whether signing out confirms, and what it says, is a
  product decision.
- Sidebar rows and the account button compose `FoFocusRing`, so the shell has the same keyboard
  focus treatment as everything else.
- A nav sheet whose actions are all behind permissions this user lacks now says so.
  `FoNavSheet.emptyLabel` is required; Luxe hardcoded the English string.

## 0.1.0

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

### Added — phase 5, charts

- `FoChartShell` (+ `FoChartShellCopy`, `FoChartTableRow`) — the frame every chart goes through.
  It owns loading, empty, error, and a **view-as-table** toggle that renders the same numbers as
  text. This is the highest-value thing borrowed from the web package: without it a chart is the
  only way to read its own numbers, and a chart cannot be read by a screen reader, at 1.6x text
  scale, or by anyone who needs the exact figure rather than the shape.
- `FoChartTheme` and `FoChartLegend` — the shared `fl_chart` building blocks. Axis labels take
  chrome ink, never a series colour: a label in a series colour looks like data.
- `FoTrendChart` (+ `FoTrendSeries`), `FoBarChart` (+ `FoBarGroup`), `FoSparkline`,
  `FoParetoChart` (+ `FoParetoItem`), `FoStageFunnel` (+ `FoFunnelStage`).
- `fl_chart` and `intl` are now dependencies.
- Widgetbook: 6 use cases under `04 Charts`, covered by the layout test.

### Changed from the Luxe originals

- **G6.** Every chart passes `Duration.zero`. Luxe animated entry at 250ms unless the platform
  asked for reduced motion; the web package disables it on all four wrappers unconditionally,
  because the animation also leaves a line invisible in a background tab, in print, and to
  screenshot tooling — none of which `disableAnimations` covers.
- `FoParetoChart` normalises its cumulative line onto the bars' scale so there is one y axis.
  Dual axes let the author choose where the line crosses the bars, which means the reader
  cannot trust the crossing — and the crossing is the whole point of a pareto.
- Tooltips sit on `surfaceRaised` rather than `surface` (G5).
- `positiveMax` returning 1.0 for an empty or all-zero dataset is now covered by a test: an axis
  whose max equals its min makes `fl_chart` divide by zero, which on web is a silent NaN and a
  blank plot rather than a crash.

### Added — phase 7, the doc set

- `AGENTS.md` — the package contract, the six rules in their Flutter form, and the list of
  things that have already bitten us.
- `docs/components.md` — the surface ladder, the five rules, a choosing-a-component table, and
  the two pairs that look alike and are not (chip/badge, toast/banner).
- `docs/migrating-from-luxe.md` — the full `Luxe*` → `Fo*` symbol map, the colour-field map, and
  the seven signatures that changed because the package holds no user-facing strings.
- `components.manifest.json` — 83 symbols, machine-readable, mirroring the web manifest.
- `test/barrel_test.dart` — **G8.** The web package shipped `ChartShell` documented and
  unexported for months. This checks the manifest, the barrel and `lib/src/` all agree, in both
  directions: a symbol in the manifest that is not exported fails, and so does a file under
  `lib/src/` that nothing exports.

### Added — phase 6, the Tier A gap components

- `FoSeamGrid` / `FoSeamCell` — a set of related figures as **one object**. Four stat cards are
  four shadows the eye has to relate to each other; one seamed block is a single figure with
  four parts. It reflows 4 → 2 → 1, each step a clean divisor of the one above, because a hole
  in a grid of hairlines reads as a figure that failed to load rather than as whitespace.
- `FoStatCard` / `FoStatCardContent` (+ `FoTrend`). Rule §3.3 made concrete: the mono uppercase
  caption names the figure, the mono tabular figure is it. A trend colours the note as well as
  the arrow, so the direction does not depend on the arrow alone.
- `FoDescriptionList` (+ `FoDescriptionItem`), `FoPageHeader`, `FoBadge`, `FoThemeToggle`.
- Widgetbook: 6 use cases under `05 Dashboard`, covered by the layout test.

### Fixed

- `FoDescriptionList` sized to its parent rather than its content. Left at the default
  `MainAxisSize.max` it filled whatever height it was given, so it never visibly stacked and
  anything below it in a Column was pushed off screen. Found by the test that checks it stacks.

### Notes on the new components

- `FoBadge` and `FoStatusChip` look alike and are not: a chip carries a record's state and
  stands on its own; a badge counts the thing it is attached to and is never the only place a
  fact appears.
- `FoThemeToggle` has three states. A two-state toggle cannot express "follow the system" at
  all, so defaulting to light silently overrides the platform's preference.
- `FoPageHeader` is the only place the display scale is used. `FoSectionHeader` names a region
  inside a page; reserve the page scale or it stops meaning "this is the page".

### Known

- Light-mode `primary` (`#15803d`) is below AA on two grounds: 4.16:1 on `surfaceSunken`
  and 4.11:1 on its own 12% wash over `surface`. Both are waived and documented in
  `docs/contrast-report.md`. The colours are ported verbatim, so the fix belongs in
  `@figuredout/ui-web` first — the same way `--color-success` was darkened there.

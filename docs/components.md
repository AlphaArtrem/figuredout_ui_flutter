# Components

`figuredout_ui` is the canonical UI surface for FiguredOut Flutter apps. Compose these instead
of reimplementing local button, form, overlay, table or header styling. When something is
missing, add it here rather than in app code.

The Widgetbook is the live surface — every component has a use case saying what it is for:

```bash
cd widgetbook && dart run build_runner build -d && flutter run -d chrome
```

## The surface ladder

Four steps, in both themes. **Which surface a thing sits on is its meaning, not a preference.**

| Token | What sits on it |
| --- | --- |
| `surfaceSunken` | Holes: text fields, segmented-control tracks, wells, table heading rows |
| `bg` | The page itself |
| `surface` | Cards, tables, panels — anything resting on the page |
| `surfaceRaised` | Anything lifted: a dialog, a menu, a toast, a hovered row, an open tile |

White is the top of that ladder in light mode, not the resting surface. A card on `surface`
separates from the page without leaning on its hairline, which is what leaves `surfaceRaised`
free to mean *lifted*.

## The five rules

1. A hairline is a **foreground decoration**, never `decoration.border`. On a container with a
   banded header or footer, a border is painted underneath the child's own background.
2. Three elevation steps: `FoShadows.raised` rests, `.hover` is picked up, `.overlay` covers
   something else. Reach for `foOverlaySurface(context)` rather than restating the floating
   surface.
3. Mono uppercase captions **name** values; mono tabular figures **are** values. A form label
   instructs rather than names, so it stays sentence-case semibold sans.
4. One duration and one curve: `FoMotion.normal` with `FoMotion.standard`, or `FoMotion.fast`
   under 200ms.
5. One focus treatment: a 4dp ring in `focusRing`, via `FoFocusRing`.

## Canonical

- **Primitives**: `FoButton`, `FoActionButton`, `FoLoadingButton`, `FoCard`, `FoTextField`,
  `FoDropdownField`, `FoStatusChip`, `FoBadge`, `FoSkeleton`, `FoSpinner`, `FoBooleanCell`,
  `FoHint`, `FoSectionHeader`, `FoSectionSurface`, `FoFocusRing`, `FoThemeToggle`,
  `foOverlaySurface`
- **Layout**: `FoScaffold`, `FoAppBar`, `FoPageHeader`, `FoResponsiveTileGrid`, `FoSeamGrid`
- **Data**: `FoDataTable`, `FoMatrixTable`, `FoPaginationBar`, `FoFilterBar`, `FoListSearchField`,
  `FoStatCard`, `FoDescriptionList`, `FoDetailTable`
- **Forms and overlays**: `FoFormPresenter`, `FoFormSurface`, `FoFormActions`, `FoFormSection`,
  `FoFormInlineRow`, `FoFormValidation`, `FoFormScope`, `FoDialog`
- **Feedback**: `FoToast`, `FoInfoBanner`, `FoEmptyState`
- **Charts**: `FoChartShell`, `FoTrendChart`, `FoBarChart`, `FoParetoChart`, `FoStageFunnel`,
  `FoSparkline`, `FoChartTheme`, `FoChartLegend`

## Choosing a component

| If you are… | Use |
| --- | --- |
| showing a row of related figures | `FoSeamGrid` + `FoStatCardContent` |
| showing one figure | `FoStatCard` |
| showing records | `FoDataTable` — it is a table on a wide window and cards on a narrow one |
| showing a grid where the cell's position is its meaning | `FoMatrixTable` — a size breakdown, a permission grid |
| showing one record's fields | `FoDescriptionList` |
| framing a page region with a title | `FoSectionSurface` |
| titling a page | `FoPageHeader` — exactly one per page |
| titling a region inside a page | `FoSectionHeader` |
| interrupting | `FoDialog.confirm`, or `.destructive` for something irreversible |
| collecting input | `FoFormPresenter.show` — never `showDialog` or `showModalBottomSheet` |
| reporting the result of an action | `FoToast` |
| reporting a condition that is still true | `FoInfoBanner` |
| saying there is nothing here | `FoEmptyState` |
| waiting for a control | `FoSpinner` |
| waiting for content | `FoSkeleton` — it holds the layout still |
| plotting anything | the chart, inside a `FoChartShell` |

Two pairs look alike and are not:

- A **chip** (`FoStatusChip`) carries a record's state and stands on its own line or in its own
  table cell. A **badge** (`FoBadge`) counts or marks the thing it is attached to, and is never
  the only place a fact appears.
- A **toast** reports the result of an action and leaves. A **banner** reports a condition that
  is still true and stays until it is not. A banner that needs dismissing after three seconds
  should have been a toast.

## Rules

- Reach design values through `context.foColors` / `.foText` / `.foSpacing` / `.foRadii` /
  `.foShadows` / `.foCharts`. Never `FoTokens` directly — that skips the theme, so the widget
  will not follow a light/dark switch.
- No hex literals, no `Colors.*` (except `transparent`), no black shadows, no `Curves.linear` or
  `Curves.easeInOut`, no non-zero `elevation:`. `test/tokens/no_literals_test.dart` enforces it.
- Keep components presentational: props in, callbacks out, no data fetching.
- Every user-facing string is a parameter. The package holds no copy.

## Dashboard and list patterns

- `FoScaffold` owns the controls row — search box, filter, primary action — so list screens stop
  putting those three in three different places at three different widths.
- `FoSeamGrid` makes a set of related figures read as one object. **Pass a child count that
  divides evenly by every step it reflows through** (4 → 2 → 1): a hole in a grid of hairlines
  reads as a figure that failed to load, not as whitespace.
- `FoMatrixTable` is not a `FoDataTable`. A data table is a list of records that happens to be
  tabular, so it reflows to cards on a phone. A matrix is a grid where a cell's position in two
  dimensions *is* its meaning, so it keeps its shape at every width and scrolls sideways instead.
  Set `pinLeadingColumn` once the columns outrun the window, or scrolling right takes the row
  labels with it and the user ends up typing into unlabelled rows.
- `FoDataTable` owns its own loading, error and empty states. Pass `error` and `onRetry` and let
  it render them in the rows' place — a screen that early-returns an error above the table
  destroys the search box and the filters with it, so the user cannot change what they asked for.
- Every chart goes through `FoChartShell`, so loading, empty and view-as-table behave the same
  everywhere and **no chart is the only way to read its own numbers**. A chart cannot be read by
  a screen reader, at 1.6× text scale, or by anyone who needs the exact figure.

## Gotchas worth knowing before you edit

- **A `ClipRRect` child eats the parent's border.** Any container whose header or footer paints
  its own surface needs its hairline in `foregroundDecoration`. `FoCard`, `FoSectionSurface`,
  `FoDataTable`, `FoMatrixTable` and `FoInfoBanner` all do; copy the pattern rather than reaching
  for a border.
- **`surface` is not white.** Code that used a white `surface` to mean "lifted above the page"
  must be re-pointed at `surfaceRaised`.
- **Danger carries its own ink.** `dangerFg`, never `primaryFg` — which in dark mode is a
  near-black green — and never `surface`.
- **The font `package:` argument is mandatory,** or the family silently falls back to Roboto in
  the consuming app only.
- **`ThemeExtension.lerp` is where new tokens go to die.** A colour missing from `FoColors.lerp`
  freezes at its light value through every theme animation.
- **`fl_chart` animates by default,** ignoring reduced-motion. Every chart passes
  `FoChartTheme.animation`.
- **An interactive widget needs a `Material` ancestor** for its ink. `FoCard` carries its own;
  a new interactive component built on a bare `DecoratedBox` will crash outside a `Scaffold`.
- **Semantic text is measured against its soft wash, not the surface.** See
  [`contrast-report.md`](contrast-report.md).

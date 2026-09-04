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
  `FoDropdownField`, `FoDateField`, `FoStatusChip`, `FoSwitchTile`, `FoSegmentedControl`,
  `FoBadge`,
  `FoSkeleton`, `FoSpinner`,
  `FoBooleanCell`, `FoHint`, `FoSectionHeader`, `FoSectionSurface`, `FoFocusRing`,
  `FoThemeToggle`, `foOverlaySurface`
- **Shell**: `FoShellScaffold`, `FoShellAppBar`, `FoAccountMenuButton`
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
| framing the whole app | `FoShellScaffold` — one nav model, three layouts |
| titling the app | `FoShellAppBar`; `FoAppBar` titles a page |
| titling a page | `FoPageHeader` — exactly one per page |
| titling a region inside a page | `FoSectionHeader` |
| interrupting | `FoDialog.confirm`, or `.destructive` for something irreversible |
| collecting input | `FoFormPresenter.show` — never `showDialog` or `showModalBottomSheet` |
| collecting a yes/no | `FoSwitchTile` — a boolean is a row, not a bare `Switch` beside a label |
| collecting a calendar date | `FoDateField` — typed *and* picked, and its text is the value |
| two or three places to be | `FoSegmentedControl` — a segment is a destination, never a filter |
| showing a yes/no you cannot change | `FoSwitchTile` with a `lock`, or `FoBooleanCell` in a table |
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
- A **switch tile** (`FoSwitchTile`) *collects* a boolean; a **boolean cell** (`FoBooleanCell`)
  *renders* one in a table. The tile is the input the cell never was, which is why five call
  sites across two apps had each grown their own out of `FoCard` and a Material `Switch`.
- A **segmented control** (`FoSegmentedControl`) is two or three *destinations*; a **filter bar**
  (`FoFilterBar`) narrows whatever destination you are already in. The difference is not
  cosmetic: a filter is something you set and can forget you set, and a segment is a place you
  are, always visible, with the current one legible without opening anything.

`FoSegmentedControl` has two rules of its own. **There is no unselected state**: `selectedIndex`
is required and an out-of-range one clamps, because a control showing neither option as current
is one whose user cannot tell where they are — a screen that genuinely has a "neither" wants a
filter. And **two or three segments, asserted**: four is a tab bar, and four labels do not fit a
phone in a script that runs longer than English. The track is `surfaceSunken` and the current
segment rests on `surface`, which is rule 6 read literally — this table had reserved the token
for "segmented-control tracks" for two releases before the component existed.

`FoDateField` has two rules of its own. **Its value is the controller's text, and that text is
an ISO-8601 date** — `2026-08-29`. That is a contract rather than a default: it is the one
written form with no ambiguity between the day and the month, it sorts as a string, and it is
what the JSON APIs behind these apps already exchange. `foIsoDate` and `foParseIsoDate` convert,
and the parse is strict about the round trip because `DateTime.parse` accepts `2024-02-31` and
rolls it quietly into March. And **a date is not an instant**: there is no time and no zone here,
because a hearing on the 26th stored as a timestamp shows as the 25th to somebody whose phone is
set to another country. It is also typed *and* picked on purpose — a clerk entering a month of
records is faster than any calendar, someone who does it twice a month wants the calendar, and
which of the two a screen has depends on the screen.

`FoSwitchTile` has one rule worth stating on its own. **A value that can never change is a word,
never a greyed switch.** Pass a `FoSwitchTileLock` and the switch is replaced by a chip carrying
the caller's word; a null `onChanged` means "not now" instead, and dims the row while keeping the
switch's on and off colours. The distinction is not stylistic: a *disabled* Material `Switch`
that is **on** paints a grey track with the thumb to the right, which reads as **off** at a
glance. A consuming app shipped five permissions labelled "always on" beside a control that
looked off, and only a live run on a phone caught it.

## Rules

- Reach design values through `context.foColors` / `.foText` / `.foSpacing` / `.foRadii` /
  `.foShadows` / `.foCharts`. Never `FoTokens` directly — that skips the theme, so the widget
  will not follow a light/dark switch.
- No hex literals, no `Colors.*` (except `transparent`), no black shadows, no `Curves.linear` or
  `Curves.easeInOut`, no non-zero `elevation:`. `test/tokens/no_literals_test.dart` enforces it.
- Keep components presentational: props in, callbacks out, no data fetching.
- Every user-facing string is a parameter. The package holds no copy.

## Dashboard and list patterns

- `FoShellScaffold` takes **one** navigation model and renders it three ways — labelled sidebar,
  icon-only rail, bottom bar. Build the model once. An app that builds its phone navigation
  separately from its desktop navigation ends up with two that disagree about what exists.
  Permissions and routes stay in the app: filter the groups and destinations before passing
  them, and do the filtering inside the app's own observer, not in a value captured outside one.
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

- **A `FormField` seeds from `initialValue` and never re-applies it.**
  `FormFieldState.didUpdateWidget` reacts to `forceErrorText` and to nothing else, so any
  wrapper that hands a caller's `value` to a `FormField` is an uncontrolled widget wearing a
  controlled widget's API — every change made from outside is dropped in silence. That is what
  `FoDropdownField` was until 0.6.0, and why it is now an `InputDecorator` around a plain
  `DropdownButton`. Reach for a `FormField` only when you actually want its validation.
- **A Material child needs a Material ancestor *inside* the fill.** A
  `ListTile` or a `Switch` paints its ink on the nearest `Material`, so one
  sitting above a painted background puts the ink behind that background —
  Flutter asserts rather than just looking wrong. `FoCard` and the picker's
  option list both carry a transparent `Material` inside their fill; copy that
  rather than assuming the enclosing `Scaffold` is close enough.
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
- **A `Row` holding something flexible beside something that is not is a text-scale bug.** A
  message beside a button, a title beside a chip: the `Expanded` collapses to nothing long
  before the fixed thing does, and at 200% the fixed thing runs off the right with its own
  words cut off — which is the whole point of a chip that never relies on colour alone. Use a
  `Wrap` with `WrapAlignment.spaceBetween`, give it a tight width (`Expanded`, or a
  `SizedBox(width: double.infinity)` when it is the whole row), and the second thing drops onto
  its own line at whatever size it stops fitting. **No threshold and no `LayoutBuilder`** — the
  same fix covers a long label in any language. `FoInfoBanner` does this; `FoSwitchTile` keeps
  its `Switch` in the `Row` and makes only the lock chip `Flexible`, because a fixed 60-point
  control never grows and a target that moves with the text size is one somebody has to look
  for.
- **A `Wrap` in a `Column` shrink-wraps, and `spaceBetween` then does nothing.** The column
  hands loose width, the wrap sizes to its content, and an alignment with no free space to
  distribute silently becomes `start`. Every test still passes; the only symptom is a chip
  pressed against the label it should be opposite.
- **A `MainAxisSize.min` column paints past whatever it was given.** `FoEmptyState` did, at
  200% on a phone — and an empty state is the screen somebody at that text size is most likely
  to be reading, because it is what an app shows before there is anything else to look at. It
  is a `SingleChildScrollView` over a `ConstrainedBox(minHeight: viewport)` now, so it is
  centred when it fits and scrolls when it does not. The `minHeight` is the half that keeps the
  ordinary case identical.
- **`widgetbook/test` pumps every page at 200% text**, at the compact viewport in light theme —
  the combination that runs out of room first, and one pass rather than a third dimension on
  the 3 × 2 matrix. The `Charts` page is exempt and says why in the test: `FoChartShell` gives
  its plot a fixed height because `fl_chart` fills its box and asserts on an unbounded one, so
  a self-sizing chart like `FoStageFunnel` overflows that slot at 200%. Fixing it means an
  opt-out on the shell, which is an API addition.
- **Semantic text is measured against its soft wash, not the surface.** See
  [`contrast-report.md`](contrast-report.md).

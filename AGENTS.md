# AGENTS.md

## Package Contract

- This repository is the standalone source for `figuredout_ui`, the Flutter sibling of
  `@figuredout/ui-web`. The two share a visual language; keep them in step.
- Keep components presentational: **props in, callbacks out, no data fetching.**
- Hold **no user-facing strings.** Every label, message and tooltip is passed in by the caller,
  so it can be localized. If a component seems to need copy of its own, it needs a parameter.
- Depend on no state-management library. Where a reactive boundary genuinely belongs inside the
  design system — `FoScaffold.primaryActionBuilder` — expose a hook the app wires up instead.
- Preserve the exports in `lib/figuredout_ui.dart` unless a breaking change is intentional and
  written into `CHANGELOG.md`.

## Read First

Before changing any component, read `docs/components.md`. It carries the surface ladder, the
five rules, and the gotchas that have already cost someone an afternoon. The Widgetbook is the
live surface: `cd widgetbook && dart run build_runner build -d && flutter run -d chrome`.

## The Rules Components Must Not Break

1. **A hairline is a foreground decoration, never `decoration.border`.** On a container whose
   child paints a full-bleed band — a card with a tinted header, a table with a heading row, a
   dialog with a footer bar — a border drawn in `decoration` is painted *under* that child and
   loses the edge it shares with it. Use `foregroundDecoration` or
   `DecoratedBox(position: DecorationPosition.foreground)`. See `FoCard`, `FoSectionSurface`,
   `FoDataTable`, `FoInfoBanner`.
2. **Three elevation steps, no more.** `FoShadows.raised` rests, `.hover` is picked up,
   `.overlay` covers something else. **Never** `Material(elevation:)`, `Card(elevation:)`, or a
   black shadow. Reach for `foOverlaySurface(context)` rather than restating the floating
   surface in a new component.
3. **Mono uppercase captions name values; mono tabular figures are values.** A form label
   instructs rather than names, so it stays sentence-case semibold sans — the one exception.
4. **One duration and one curve**: `FoMotion.normal` with `FoMotion.standard`, or `FoMotion.fast`
   under 200ms. `Curves.easeInOut`, `Curves.linear` and literal `Duration(...)` are banned
   outside `lib/src/tokens/`, and a test enforces it.
5. **One focus treatment**: a 4dp ring in `focusRing`, via `FoFocusRing`. Every interactive
   component composes it.
6. **Which surface something sits on is its meaning.** `surfaceSunken` is a hole, `bg` is the
   page, `surface` rests, `surfaceRaised` is lifted. Never reach for a lighter surface to create
   emphasis.

## Working Style

- Prefer small, focused changes and the existing patterns.
- Keep every literal in `lib/src/tokens/fo_tokens.dart`. A component must never hardcode a
  colour, a shadow, a duration or an opacity. `test/tokens/no_literals_test.dart` enforces the
  first three; the rest is on you.
- When adding a token, add it to `FoColors.toMap()` **and** `FoColors.lerp` in the same change,
  or it freezes during every theme animation. A test catches it, but the test is not the point.
- Update `README.md`, `docs/components.md` and `components.manifest.json` when public exports
  change — and add a Widgetbook use case, or the component is invisible to the next agent.

## Validation

```bash
flutter analyze && flutter test && dart format --output=none --set-exit-if-changed .
```

```bash
cd widgetbook && dart run build_runner build -d && flutter test && flutter build web --release
```

- `flutter build web` from `widgetbook/` after any use-case or component change. **It is the
  only check that compiles the use cases** — the exact Flutter twin of the web package's "`tsc`
  does not check the stories".
- `flutter test` from `widgetbook/` after any layout change: it pumps every use case at all
  three window classes in both themes and fails on overflow. The web build proves the use cases
  compile; it says nothing about whether they fit.
- After a token change, `flutter test` rewrites `docs/contrast-report.md`. Read the diff.
  Semantic ink is measured against its `-soft` companion composited over the surface, not
  against the surface: that is the composite a chip produces, and it is where the web package
  found `--color-success` failing AA.

## Things That Have Already Bitten Us

- **`flutter analyze` does not compile the Widgetbook.** A use case can be broken while the
  package is green. Run the web build.
- **A barrel can silently omit an export.** The web package shipped `ChartShell` documented and
  unexported for months. `test/barrel_test.dart` now checks the manifest, the barrel and
  `lib/src/` all agree — in both directions.
- **`ThemeExtension.lerp` is where new tokens go to die.** A colour missing from `FoColors.lerp`
  freezes at its light value for the whole of every theme animation, silently.
- **The font `package:` argument is mandatory.** `TextStyle(fontFamily: 'Geist')` without
  `package: 'figuredout_ui'` resolves against the *consuming app's* font manifest and falls back
  to Roboto with no warning — and only in the consuming app, so it is invisible from here.
- **A `ClipRRect` child eats the parent's border.** The reason for rule 1. If a card's header
  band looks like it is missing its top hairline, this is why.
- **Danger needs its own ink.** `primaryFg` in dark mode is a near-black green; on a light red it
  is unreadable. `FoButton`'s destructive variant uses `dangerFg`.
- **An interactive widget needs a `Material` ancestor.** Replacing Material's `Card` with a
  `DecoratedBox` left `FoCard`'s ink with nothing to splash into, and it crashed anywhere
  outside a `Scaffold`. `FoCard` now carries its own transparent `Material`.
- **`fl_chart` animates by default,** and that animation ignores reduced-motion, leaves a line
  invisible in a background tab and in print, and races screenshot tooling. Every chart passes
  `FoChartTheme.animation`, which is `Duration.zero`.
- **A `Column` at its default `MainAxisSize.max` fills whatever it is given.** `FoDescriptionList`
  did, so it never visibly stacked and pushed everything below it off screen.

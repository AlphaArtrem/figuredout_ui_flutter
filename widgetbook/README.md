# figuredout_ui_widgetbook

The live surface for `figuredout_ui` — Storybook's counterpart. A **separate package**, so
the library never carries `widgetbook` as a dependency, exactly as `@figuredout/ui-web`
keeps Storybook in `devDependencies` and out of `files`.

## Running it

```bash
dart run build_runner build -d && flutter run -d chrome
```

```bash
dart run build_runner build -d && flutter build web --release
```

The release build is a **CI gate, not a convenience**: `flutter analyze` on the library does
not compile the use cases, so a use case can be broken while the library is green.

```bash
flutter test
```

`test/use_cases_layout_test.dart` pumps every Foundations page at all three window classes
in both themes and fails on any overflow. The web build proves the use cases *compile*; it
does not prove they *fit*, and an overflow at the compact viewport otherwise slips past
every gate — the build is green, the analyzer is quiet, and the only symptom is a
yellow-and-black stripe nobody scrolls to.

`lib/main.directories.g.dart` is generated and gitignored, so CI must run `build_runner`
before `flutter build web`.

## Adding a use case

Annotate a builder function. Every component gets at least one, with a doc comment saying
what it is for — the web `AGENTS.md` is blunt about this: *add a story, or the component is
invisible to the next agent.*

```dart
/// What this is for, and when to reach for it instead of the alternative.
@widgetbook.UseCase(
  name: 'Primary',
  type: FoButton,
  path: '02 Primitives',
)
Widget buildFoButtonPrimary(BuildContext context) => FoButton(...);
```

### Sidebar order

The order mirrors Storybook's `storySort`:

**Introduction, Foundations, Primitives, Layout, Data, Navigation & input, Feedback &
overlays, Charts.**

Widgetbook sorts folders alphabetically, so the numeric prefix in `path:` is the sort key:
`01 Foundations`, `02 Primitives`, `03 Layout`, `04 Data`, `05 Navigation & input`,
`06 Feedback & overlays`, `07 Charts`.

Two notes on that:

- The `path:` argument is what sets the navigation entry, so file location and sidebar
  location are independent. Files still live under `lib/use_cases/<nn>_<section>/` so the
  two agree.
- Widgetbook 3.x has no hook for hiding a folder's sort prefix from its display name, so
  the number is visible in the sidebar. This is a deliberate, documented deviation from the
  plan's "strip the prefix in the display name" — the alternative is losing the order.

## Addons

| Addon | Why |
| --- | --- |
| `MaterialThemeAddon` — Light / Dark | The four-step surface ladder runs in both. A component that only reads right in one of them is not finished. |
| `ViewportAddon` — Compact 480, Medium 760, Expanded 1280 | Named for the three `FoWindowClass` bands rather than for devices, so a window-class branch is exercisable rather than merely plausible. |
| `TextScaleAddon` — 1.0 to 1.6 in steps of 0.1 | The accessibility check the web package gets from `@storybook/addon-a11y` and Flutter otherwise never gets. Raise it to 1.6 before calling a layout done. |
| `AlignmentAddon` | Shows whether a component sizes itself or fills what it is given. |
| `InspectorAddon` | The widget tree, in place. |

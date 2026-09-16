# State

Edit in place. No dated or per-session sections. Last derived from the repository on 2026-09-17
(branch `main`, head `84b48e3`, clean tree).

## What exists

- **Package `figuredout_ui` 0.6.1** (`pubspec.yaml`, tag `v0.6.1`, 2026-09-05). Not published
  (`publish_to: 'none'`); consumed by path/git.
- **Tokens, theme, primitives, patterns, charts** under `lib/src/`, all exported through the
  single barrel `lib/figuredout_ui.dart`. The export list is `components.manifest.json`.
- **The Luxe port is complete** as of 0.2.0 (2026-08-15, per `CHANGELOG.md`): every `Luxe*`
  component has a `Fo*` counterpart, including `FoShellScaffold`, `FoMatrixTable`,
  `FoDetailTable`, `FoEntityPickerField` and `showFoTextPrompt`.
- **Added since the port:** `FoSwitchTile` (0.4.0), `FoSegmentedControl` (0.5.0), `FoDateField`
  and a controlled `FoDropdownField` (0.6.0), 200%-text overflow fixes and test pass (0.6.1).
- **Widgetbook** in `widgetbook/`, a separate package; its `test/use_cases_layout_test.dart`
  pumps every registered page at three window classes, both themes, and once at 200% text.
- **Tests** in `test/`: barrel/manifest agreement, token contrast (rewrites
  `docs/contrast-report.md`), a no-literals ban, theme, primitives, patterns, charts.

## Settled decisions (why lives in the linked file)

- Presentational only, no user-facing strings, no state-management dependency — `AGENTS.md`.
- Fonts vendored, not fetched, because consuming apps are offline-first — `README.md`, Fonts.
- Charts render with `Duration.zero` animation — `AGENTS.md`, and the `fl_chart` note in `pubspec.yaml`.
- Luxe adopts the package through a typedef shim — `docs/migrating-from-luxe.md`.

## Invariants

| Invariant | What breaks silently if violated | Enforced by |
| --- | --- | --- |
| Barrel, manifest and `lib/src/` agree | A documented component is unimportable by consumers | `test/barrel_test.dart` |
| No colour, shadow or duration literal outside `lib/src/tokens/` | Component ignores theme switches | `test/tokens/no_literals_test.dart` |
| No opacity literal outside tokens | Same, for opacity | Nothing (review only) |
| Every token is in `FoColors.toMap()` and `FoColors.lerp` | Colour freezes during theme animation | A test (per `AGENTS.md`) |
| Font styles pass `package: 'figuredout_ui'` | Consumer falls back to Roboto, only in the consuming app | `test/theme/fo_theme_test.dart` |
| Semantic ink meets AA, including on its `-soft` wash | Unreadable chips and banners | `test/tokens/contrast_test.dart` (two waivers, below) |
| Every Widgetbook use case is registered in the layout test's page map | Use case compiles but is never checked for overflow | Nothing (hand-written map) |
| Use cases compile | Widgetbook broken while the package is green | `flutter build web` in `widgetbook/` only |

## Known gaps and drift

- **`FoStageFunnel` overflows at 200% text** inside `FoChartShell`'s fixed plot slot; the
  `Charts` page is skipped in the 200% pass (`CHANGELOG.md` 0.6.1, Known gap).
- **Light-mode `primary` fails AA** on `surfaceSunken` (4.16:1) and on its own wash (4.10:1);
  waived in `docs/contrast-report.md`. Fix is expected upstream in `@figuredout/ui-web` first.
- **`README.md` status block is stale:** it still lists `FoShellScaffold`, `FoMatrixTable`,
  `FoDetailTable`, `FoEntityPickerField` and `FoTextPrompt` as "still to port" and names a
  `COMPONENT_GUIDE.md` that does not exist. The code and `CHANGELOG.md` 0.2.0 say otherwise.
- **SDK constraint drift:** `pubspec.yaml` declares `flutter: '>=3.19.0'`, but `pubspec.lock`
  resolved packages requiring `flutter >=3.27.0` / `dart >=3.10.0-0`. See `external-facts.md`.
- **No licence chosen:** `LICENSE` is the `flutter create` placeholder.

## Next action

Not recorded in the repository. The smallest open item with a stated fix is the
`FoChartShell` "content sizes itself" opt-out, which would let the `Charts` page rejoin the 200%
pass. Confirm priority with the owner before starting.

## Predicted hazards

Predictions, not incidents. When one happens, move it to `AGENTS.md` "Things That Have Already
Bitten Us" with the concrete incident and delete it here.

- **Drift from `@figuredout/ui-web`.** The two packages share a visual language by convention
  only; nothing here checks token parity with the web package.
- **Declared SDK floor below what the lock needs.** A consumer on Flutter 3.19–3.26 may fail to
  resolve rather than get a clear constraint error.
- **Consumer-only failures.** Overflows at 200% text were found in a consuming app, not here
  (0.6.1); other consumer-environment differences (locale, text scale, missing `Material`
  ancestor) are likely to surface the same way.
- **Unpinned major bumps of `fl_chart` / `data_table_2`.** Both carry behaviour the components
  work around (animation default, column sizing); an upgrade may silently undo a workaround.

# State

Edit in place. No dated or per-session sections. Last derived on 2026-10-02 from `main` at
the 0.7.2 release (branch `fix/consumer-defects` from `0d8e1e4`, v0.7.1).

## What exists

- **Package `figuredout_ui` 0.7.2 on `main`** (tags v0.7.0, v0.7.1, v0.7.2). Not published
  (`publish_to: 'none'`); consumed by git tag. 0.7.0 ports the FiguredoutAI palette from
  `@figuredout/ui-web` and adds the production-floor components; 0.7.2 carries the nine fixes
  legal_app filed (`CHANGELOG.md` 0.7.2).
- **A 0.6 maintenance line**, branch `release/0.6.x` from v0.6.1, tag v0.6.2: the same fixes
  without 0.7.0's palette, for an app (legal_app) that has not taken the visual change. Fix on
  `main` first; backport to `release/0.6.x` only for a consumer still on 0.6.
- **Two dark palettes:** `FoDarkPalette.inkSky` (default, the web package's) and `.graphite`
  (opt-in, Luxe's choice). Graphite has no web-package counterpart; its values come from the Luxe
  canvas and are checked by `test/tokens/graphite_test.dart`.
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
| Semantic ink meets AA, including on its `-soft` wash | Unreadable chips and banners | `test/tokens/contrast_test.dart` (no waivers since 0.7.0; light, dark and Graphite) |
| Graphite keeps the checks it was chosen on | A dark palette that drifts back to invisible edges | `test/tokens/graphite_test.dart` |
| Every Widgetbook use case is registered in the layout test's page map | Use case compiles but is never checked for overflow | Nothing (hand-written map) |
| Use cases compile | Widgetbook broken while the package is green | `flutter build web` in `widgetbook/` only |

## Known gaps and drift

- **Chart series 6 equals the axis-label ink** in both themes — inherited verbatim from
  `@figuredout/ui-web`; recorded as a known exception in `test/charts/fo_charts_test.dart`.
- **Tokens were 0.6.1 green until 0.7.0** although the web package went teal in its `60926da`;
  parity is now re-ported from its `569b4a2`. Nothing checks it automatically (see hazards below).
- **SDK constraint drift:** `pubspec.yaml` declares `flutter: '>=3.19.0'`, but `pubspec.lock`
  resolved packages requiring `flutter >=3.27.0` / `dart >=3.10.0-0`. See `external-facts.md`.
- **No licence chosen:** `LICENSE` is the `flutter create` placeholder.

## Next action

Point Luxe at v0.7.2 and migrate its screens (`docs/migrating-from-luxe.md`, "0.7.0") — 0.7.2's
behaviour changes are listed in its CHANGELOG entry. `legal_app` pins `v0.6.2` and will change
colour when it moves to 0.7.x — its owner decides when.

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

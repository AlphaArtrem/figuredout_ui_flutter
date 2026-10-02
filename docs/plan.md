# Plan

Phased build order. Acceptance is a demonstration, not a passing suite. Status is taken from
`git log` and `CHANGELOG.md`; nothing below "Not started" has code in the repository.

| Phase | Scope | Acceptance demo | Status |
| --- | --- | --- | --- |
| 0–2 | Tokens, theme, Widgetbook Foundations surface | Foundations pages render in both themes in the running Widgetbook | Done, `5b178f3` (2026-08-14) |
| 3 | Primitives | Each primitive has a Widgetbook use case in both themes | Done, `fcb6305` |
| 4 | Patterns: feedback, overlays, forms, data, page layout | A form, a dialog and a data table are usable end to end in Widgetbook | Done, `baba7b7` |
| 5 | Charts, all routed through `FoChartShell` | Every chart shows loading, empty, error and data states | Done, `3a01457` |
| 6 | Tier A gap components | Each has a use case and a test | Done, `15540f8` |
| 7 | Doc set and manifest | Barrel test proves manifest, barrel and `lib/src/` agree | Done, `61eb44f` |
| Port | Remaining `Luxe*` components (shell, matrix, detail table, entity picker, text prompt) | Every `Luxe*` symbol maps to a `Fo*` symbol in `migrating-from-luxe.md` | Done, v0.2.0 (2026-08-15) |
| 8 | Luxe consumes the package through the typedef shim | Luxe runs on `figuredout_ui` with the shim; `flutter analyze` lists the rename worklist | In progress — fixes found by Luxe shipped in 0.2.1 and 0.6.1; completion is not recorded in this repo |
| Post-port | Additions requested by consumers (`FoSwitchTile`, `FoSegmentedControl`, `FoDateField`, controlled dropdown, 200% text) | Released with use case, test and changelog entry | Done through v0.6.1 |
| 9 | FiguredoutAI palette parity with `@figuredout/ui-web`; the production-floor components of the Luxe redesign; the owner's six layout rules | Widgetbook `06 Production` pages pumped at three widths, both themes and 200% text; contrast report with no waivers | Built on `feat/luxe-redesign-components`, uncommitted, 0.7.0 — not released |

## Not started (candidates found in the repo, not committed work)

| Item | Source | Acceptance demo |
| --- | --- | --- |
| `FoChartShell` opt-out for self-sizing content | `CHANGELOG.md` 0.6.1 Known gap | `Charts` page passes the 200% text pass with its skip removed |
| Chart series 6 ≠ axis ink | `CHANGELOG.md` 0.7.0 Known gap (owned by `@figuredout/ui-web`) | The known-collision exception in `test/charts/fo_charts_test.dart` deleted |
| Tablet rail "Stages" flyout group | Luxe `ShellTablet` board | A `FoNavGroup` collapses to one rail item with a flyout of counts |
| Choose a licence | `README.md` Licence | `LICENSE` is no longer the placeholder |

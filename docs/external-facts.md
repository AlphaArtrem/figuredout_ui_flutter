# External facts

Every external dependency the package rests on. Grades: **verified** (exercised and checked),
**documented** (stated in a repo file, not re-checked), **assumed** (inferred, no source).
Nothing below was run or fetched on the check date, so nothing is graded verified.

| Fact | Source | Checked | Grade |
| --- | --- | --- | --- |
| Declared SDK: Dart `>=3.3.0 <4.0.0`, Flutter `>=3.19.0` | `pubspec.yaml`, `widgetbook/pubspec.yaml` | 2026-09-17 | documented |
| Resolved dependencies require Dart `>=3.10.0-0`, Flutter `>=3.27.0` (higher than declared) | `pubspec.lock` `sdks:` | 2026-09-17 | documented |
| Project created on Flutter stable, revision `ad70ec46…` | `.metadata` | 2026-09-17 | documented |
| `fl_chart` 0.69.2 (constraint `^0.69.2`); entry animation ignores reduced-motion and hides lines in background tabs, print and screenshots, so charts pass `Duration.zero` | `pubspec.yaml`, `pubspec.lock`, `AGENTS.md` | 2026-09-17 | documented |
| `data_table_2` 2.7.2 (constraint `^2.5.14`); used because Flutter's `DataTable` cannot size columns proportionally or fix a scrolling header | `pubspec.yaml`, `pubspec.lock` | 2026-09-17 | documented |
| `intl` 0.20.3 (constraint `^0.20.2`), for compact and grouped number formatting | `pubspec.yaml`, `pubspec.lock` | 2026-09-17 | documented |
| `widgetbook` 3.25.0, `widgetbook_annotation` 3.11.0, `widgetbook_generator` 3.24.0 | `widgetbook/pubspec.lock` | 2026-09-17 | documented |
| Geist and Geist Mono v1.7.2, OFL-1.1, from vercel/geist-font, vendored as static weights | `README.md` Fonts, `lib/fonts/OFL.txt` | 2026-09-17 | documented |
| A `TextStyle.fontFamily` without `package:` resolves against the consuming app's font manifest and silently falls back | `AGENTS.md`, asserted in `test/theme/fo_theme_test.dart` | 2026-09-17 | documented |
| `ThemeExtension.lerp` must include every field or it freezes during theme animation | `AGENTS.md` | 2026-09-17 | documented |
| `@figuredout/ui-web` is the React sibling and the upstream for colour decisions | `README.md`, `AGENTS.md` | 2026-09-17 | assumed (repo not inspected) |
| WCAG AA thresholds: 4.5:1 body text, 3:1 chart series | `docs/contrast-report.md` header | 2026-09-17 | documented |

# Migrating Luxe onto `figuredout_ui`

Luxe adopts the package through a **shim**: `apps/app/lib/design/` becomes a set of re-exports
and `typedef`s, so all 167 feature files compile untouched and the renames happen in later
mechanical passes. Dart's generalised typedefs can be constructed and `const`-constructed, and
an enum typedef resolves its values, so this is transparent to call sites.

```dart
// apps/app/lib/design/components/luxe_button.dart
export 'package:figuredout_ui/figuredout_ui.dart' show FoButton, FoButtonVariant;

typedef LuxeButton = FoButton;
typedef LuxeButtonVariant = FoButtonVariant;
```

Mark the whole shim `@Deprecated('Use Fo… from package:figuredout_ui')` so the rename passes get
a machine-generated worklist out of `flutter analyze`.

## Symbols

| Luxe | Package | Note |
| --- | --- | --- |
| `LuxeTokens` | `FoTokens` | |
| `LuxeColors` | `FoColors` | Field names changed — see below |
| `LuxeTextStyles` | `FoTextStyles` | |
| `LuxeSpacing`, `LuxeRadii` | `FoSpacing`, `FoRadii` | |
| `LuxeChartColors` | `FoChartColors` | 6 categorical hues, not 5 |
| `LuxeThemeExt`, `LuxeTheme` | `FoThemeExt`, `FoTheme` | |
| `LuxeWindowClass` | `FoWindowClass` | |
| `LuxeButton`, `LuxeActionButton`, `LuxeLoadingButton` | `FoButton`, `FoActionButton`, `FoLoadingButton` | |
| `LuxeCard`, `LuxeSectionHeader`, `LuxeSectionSurface` | `FoCard`, `FoSectionHeader`, `FoSectionSurface` | |
| `LuxeTextField`, `LuxeDropdownField` | `FoTextField`, `FoDropdownField` | |
| `LuxeStatusChip`, `LuxeSkeleton`, `LuxeSkeletonList` | `FoStatusChip`, `FoSkeleton`, `FoSkeletonList` | |
| `LuxeHint`, `LuxeBooleanCell` | `FoHint`, `FoBooleanCell` | **Signature changed** — see below |
| `LuxeScaffold`, `LuxeAppBar` | `FoScaffold`, `FoAppBar` | |
| `LuxeResponsiveTileGrid` | `FoResponsiveTileGrid` | |
| `LuxeDataTable`, `LuxeTableColumn`, `LuxeColumnSize` | `FoDataTable`, `FoTableColumn`, `FoColumnSize` | **Signature changed** |
| `LuxeMatrixTable`, `LuxeMatrixColumn`, `LuxeMatrixRow`, `LuxeMatrixSection`, `LuxeMatrixSummaryRow` | `FoMatrixTable`, `FoMatrixColumn`, `FoMatrixRow`, `FoMatrixSection`, `FoMatrixSummaryRow` | |
| `LuxeMatrixHeaderText`, `LuxeMatrixNumericCell`, `LuxeMatrixTotalText`, `LuxeMatrixValidationText` | `FoMatrixHeaderText`, `FoMatrixNumericCell`, `FoMatrixTotalText`, `FoMatrixValidationText` | |
| `LuxePaginationBar`, `LuxeFilterBar`, `LuxeListSearchField` | `FoPaginationBar`, `FoFilterBar`, `FoListSearchField` | **Signature changed** |
| `LuxeFormPresenter`, `LuxeFormSurface`, `LuxeFormScope`, `LuxeFormController` | `FoFormPresenter`, `FoFormSurface`, `FoFormScope`, `FoFormController` | **Signature changed** |
| `LuxeFormActions`, `LuxeFormAction`, `LuxeFormSection`, `LuxeFormInlineRow`, `LuxeFormInlineItem` | `FoFormActions`, `FoFormAction`, `FoFormSection`, `FoFormInlineRow`, `FoFormInlineItem` | |
| `LuxeFormValidation` | `FoFormValidation` | **Signature changed** |
| `LuxeDialog`, `LuxeToast`, `LuxeToastAction` | `FoDialog`, `FoToast`, `FoToastAction` | |
| `LuxeErrorBanner` | `FoInfoBanner.error` | Renamed and generalised |
| `LuxeEmptyState` | `FoEmptyState` | |
| `LuxeBarChart`, `LuxeTrendChart`, `LuxeSparkline`, `LuxeParetoChart`, `LuxeStageFunnel` | `FoBarChart`, `FoTrendChart`, `FoSparkline`, `FoParetoChart`, `FoStageFunnel` | Wrap each in `FoChartShell` |
| `LuxeChartTheme`, `LuxeChartLegend` | `FoChartTheme`, `FoChartLegend` | |

Not ported — these are Luxe's domain vocabulary and stay in `apps/app/lib/design/`, composed
from `Fo*` parts: `LuxeWorkflowDetailLayout`, `LuxeWorkflowStatusFilter`,
`LuxeOverrideReasonPrompt`. Delete `lib/design/widgets/status_chip.dart`, a legacy duplicate of
`LuxeStatusChip`.

Still to port: `FoShellScaffold`. Until it lands, Luxe keeps its own.

## Colours

The context extension needs real code rather than a typedef, because the field names changed.
Keep a compat `LuxeColors` view in the shim:

| `context.luxeColors.…` | → `context.foColors.…` |
| --- | --- |
| `primary` | `primary` |
| `onPrimary` | `primaryFg` |
| `primaryContainer` | `primarySoft` |
| `secondary` | `fgMuted` |
| `secondaryContainer` | `surfaceSunken` |
| `surface` | `surface` — **but read the warning below** |
| `background` | `bg` |
| `onSurface` | `fg` |
| `onSurfaceVariant` | `fgMuted` |
| `outline` | `edge` |
| `error` | `danger` |
| `success` / `warning` / `info` | same |
| `statusDraft` / `statusSubmitted` | `warning` / `success` |

**The one that will bite:** Luxe's `surface` was `#FFFFFF` on an `#F8FAFC` page — a two-step
system where white was the resting surface. Here white is the *top* of a four-step ladder and
cards sit on `#f9fbf8`. Anything that used `colors.surface` to mean **lifted above the page**
now looks flat and needs re-pointing at `surfaceRaised`: dialogs, menus, toasts, hovered table
rows, the open state of a tile. The mapping above is right for the common case and wrong for
exactly those.

## Signatures that changed, and why

The package holds no user-facing strings and no app vocabulary, so anything that reached into
Luxe's l10n or its hint registry now takes a parameter.

| Component | Change |
| --- | --- |
| `FoBooleanCell` | `yesLabel` and `noLabel` are required |
| `FoHint` | Takes `message` and `buttonLabel` strings, not a `LuxeHintKey`; and `onCompactTap` instead of calling the toast itself |
| `FoSectionHeader` | `hint` is a `Widget?` (pass a `FoHint`), not a `LuxeHintKey?` |
| `FoDataTable` | `errorTitle` and `retryLabel` are required |
| `FoPaginationBar` | Takes `totalLabel` and `pageLabel` already worded, plus both tooltips |
| `FoFormPresenter.show` | Takes a `FoDiscardCopy` |
| `FoFormValidation.validate` | `message` is required |
| `FoScaffold` | No `usePrimaryActionAsFabOnCompact`; set `FoScaffold.reactiveBuilder` once at startup for `primaryActionBuilder` |

## Wiring it up

```yaml
# apps/app/pubspec.yaml
dependencies:
  figuredout_ui:
    git:
      url: git@github.com:<org>/figuredout_ui_flutter.git
      ref: v0.1.0
```

For local development use `apps/app/pubspec_overrides.yaml` — gitignored, so nobody commits a
machine-local path:

```yaml
dependency_overrides:
  figuredout_ui:
    path: ../../../figuredoutai/figuredout_ui_flutter
```

Then, once at startup, so `FoScaffold.primaryActionBuilder`'s observable reads stay tracked:

```dart
FoScaffold.reactiveBuilder = (builder) => Observer(builder: builder);
```

`apps/app/pubspec.lock` is currently gitignored, so a git dependency will not pin reproducibly
for CI. Start committing it once the external dependency exists.

## What the tests will and will not catch

Of Luxe's 118 test files only one asserts token identity —
`test/design/theme/luxe_theme_ext_test.dart` — and it asserts symbolically
(`expect(captured.luxeColors.primary, LuxeTokens.primary)`), so it keeps passing as long as the
shim exposes a `LuxeTokens` alias. Everything else asserts behaviour and semantics.

**That means the token swap is nearly test-transparent, which also means the tests will not
catch a visual regression.** The manual QA pass across light/dark × three window classes is not
optional.

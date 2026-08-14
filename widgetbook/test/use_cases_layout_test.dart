import 'package:figuredout_ui/figuredout_ui.dart';
import 'package:figuredout_ui_widgetbook/use_cases/01_foundations/elevation.dart';
import 'package:figuredout_ui_widgetbook/use_cases/01_foundations/motion.dart';
import 'package:figuredout_ui_widgetbook/use_cases/01_foundations/palette.dart';
import 'package:figuredout_ui_widgetbook/use_cases/01_foundations/spacing_ruler.dart';
import 'package:figuredout_ui_widgetbook/use_cases/01_foundations/type_ramp.dart';
import 'package:figuredout_ui_widgetbook/use_cases/02_primitives/buttons.dart';
import 'package:figuredout_ui_widgetbook/use_cases/02_primitives/fields.dart';
import 'package:figuredout_ui_widgetbook/use_cases/02_primitives/indicators.dart';
import 'package:figuredout_ui_widgetbook/use_cases/02_primitives/surfaces.dart';
import 'package:figuredout_ui_widgetbook/use_cases/03_patterns/data.dart';
import 'package:figuredout_ui_widgetbook/use_cases/03_patterns/detail.dart';
import 'package:figuredout_ui_widgetbook/use_cases/03_patterns/feedback.dart';
import 'package:figuredout_ui_widgetbook/use_cases/03_patterns/forms.dart';
import 'package:figuredout_ui_widgetbook/use_cases/04_charts/charts.dart';
import 'package:figuredout_ui_widgetbook/use_cases/05_dashboard/dashboard.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// `flutter build web` proves the use cases *compile*; it does not prove they
/// *fit*. An overflow at the compact viewport is exactly the failure that
/// slips past every other gate — the build is green, the analyzer is quiet,
/// and the only symptom is a yellow-and-black stripe nobody scrolls to.
///
/// Each page is pumped at all three window classes, in both themes, and any
/// overflow is a failure.
void main() {
  final Map<String, Widget> pages = <String, Widget>{
    'Palette': const Palette(),
    'Type': const TypeRamp(),
    'Spacing': const SpacingRuler(),
    'Elevation': const Elevation(),
    'Motion': const Motion(),
    'Buttons': const Buttons(),
    'Cards': const Cards(),
    'SectionSurfaces': const SectionSurfaces(),
    'SectionHeaders': const SectionHeaders(),
    'Fields': const Fields(),
    'StatusChips': const StatusChips(),
    'LoadingStates': const LoadingStates(),
    'Cells': const Cells(),
    'FocusRings': const FocusRings(),
    'OverlaySurfaces': const OverlaySurfaces(),
    'Feedback': const FeedbackPatterns(),
    'Dialogs': const Dialogs(),
    'DataTables': const DataTables(),
    'ListChrome': const ListChrome(),
    'Forms': const Forms(),
    'DetailTables': const DetailTables(),
    'PickersAndPrompts': const PickersAndPrompts(),
    'Scaffolds': const Scaffolds(),
    'Charts': const Charts(),
    'DashboardParts': const DashboardParts(),
    'DetailParts': const DetailParts(),
    'ThemeToggles': const ThemeToggles(),
  };

  // The three ViewportAddon entries in main.dart.
  const Map<String, double> viewports = <String, double>{
    'compact 480': 480,
    'medium 760': 760,
    'expanded 1280': 1280,
  };

  for (final MapEntry<String, Widget> page in pages.entries) {
    for (final MapEntry<String, double> viewport in viewports.entries) {
      for (final bool isDark in <bool>[false, true]) {
        final String theme = isDark ? 'dark' : 'light';
        testWidgets('${page.key} fits at ${viewport.key}, $theme', (
          WidgetTester tester,
        ) async {
          tester.view.physicalSize = Size(viewport.value, 2400);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);

          await tester.pumpWidget(
            MaterialApp(
              theme: isDark ? FoTheme.dark() : FoTheme.light(),
              home: page.value,
            ),
          );
          // pumpAndSettle would hang on FoSkeleton's deliberate forever-loop,
          // so pump a couple of frames instead — enough for a LayoutBuilder to
          // resolve and any overflow to be reported.
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 16));

          expect(tester.takeException(), isNull);
        });
      }
    }
  }
}

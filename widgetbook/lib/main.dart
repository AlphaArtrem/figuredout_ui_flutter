import 'package:figuredout_ui/figuredout_ui.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

import 'main.directories.g.dart';

void main() {
  runApp(const FiguredOutWidgetbook());
}

/// The live surface for `figuredout_ui` — the Flutter counterpart of the web
/// package's Storybook, and the only thing that compiles the use cases.
///
/// `flutter analyze` on the library does not look at this package, so a use
/// case can be broken while the library is green. `flutter build web --release`
/// from here is the gate that catches it.
@widgetbook.App()
class FiguredOutWidgetbook extends StatelessWidget {
  /// Creates the Widgetbook app.
  const FiguredOutWidgetbook({super.key});

  @override
  Widget build(BuildContext context) {
    return Widgetbook.material(
      directories: directories,
      addons: <WidgetbookAddon<dynamic>>[
        // The theme switcher is the whole point: the four-step surface ladder
        // runs in both themes and a component that only reads right in one of
        // them is not finished.
        MaterialThemeAddon(
          themes: <WidgetbookTheme<ThemeData>>[
            WidgetbookTheme<ThemeData>(name: 'Light', data: FoTheme.light()),
            WidgetbookTheme<ThemeData>(name: 'Dark', data: FoTheme.dark()),
          ],
        ),
        // Named for the three window classes rather than for devices, so a
        // FoWindowClass branch is exercisable rather than merely plausible.
        ViewportAddon(<ViewportData>[
          _viewport('Compact 480', 480, 900),
          _viewport('Medium 760', 760, 1024),
          _viewport('Expanded 1280', 1280, 900),
        ]),
        // The accessibility check the web package gets from
        // @storybook/addon-a11y and Flutter otherwise never gets. Steps of
        // 0.1 from 1.0, so 1.3 and 1.6 are both reachable.
        TextScaleAddon(min: 1.0, max: 1.6),
        AlignmentAddon(),
        InspectorAddon(),
      ],
    );
  }

  static ViewportData _viewport(String name, double width, double height) =>
      ViewportData(
        name: name,
        width: width,
        height: height,
        pixelRatio: 2,
        platform: TargetPlatform.android,
      );
}

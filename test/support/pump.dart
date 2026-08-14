import 'package:figuredout_ui/figuredout_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Mounts [child] inside a real `FoTheme`, which is the only environment the
/// components are designed for — `context.foColors` asserts without it.
Future<void> pumpFo(
  WidgetTester tester, {
  required Widget child,
  bool isDark = false,
  Size? surfaceSize,
}) async {
  if (surfaceSize != null) {
    tester.view.physicalSize = surfaceSize;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  await tester.pumpWidget(
    MaterialApp(
      theme: isDark ? FoTheme.dark() : FoTheme.light(),
      home: Scaffold(
        body: Center(child: child),
      ),
    ),
  );
}

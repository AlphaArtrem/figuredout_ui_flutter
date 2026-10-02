import 'package:figuredout_ui/figuredout_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Opens a [FoDialog] from a real `MaterialApp` at [size] and [scale], and
/// returns the future it resolves with.
Future<Future<bool>> _open(
  WidgetTester tester, {
  required Size size,
  required double scale,
  bool destructive = false,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  tester.platformDispatcher.textScaleFactorTestValue = scale;
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

  late BuildContext host;
  await tester.pumpWidget(
    MaterialApp(
      theme: FoTheme.light(),
      home: Scaffold(
        body: Builder(
          builder: (BuildContext context) {
            host = context;
            return const SizedBox.expand();
          },
        ),
      ),
    ),
  );

  final Future<bool> result = destructive
      ? FoDialog.destructive(
          host,
          title: 'Remove this member?',
          message: 'They lose access to every matter at once. Their past '
              'entries stay, under their name.',
          confirmLabel: 'Remove member',
          cancelLabel: 'Keep member',
        )
      : FoDialog.confirm(
          host,
          title: 'Leave without saving?',
          message: 'The changes you made on this screen are not saved yet.',
          confirmLabel: 'Leave',
          cancelLabel: 'Stay',
        );
  await tester.pumpAndSettle();
  return result;
}

void main() {
  /// Found by a consuming app's browser-zoom sweep (legal_app W5): at 300%
  /// zoom a 1280x800 window is 427x237, and the dialog's own column
  /// overflowed (`fo_dialog.dart:117`) on twenty tour runs — the mark, the
  /// title, the message and two stacked buttons are taller than the window.
  group('FoDialog in a small window', () {
    for (final (String name, Size size, double scale)
        in <(String, Size, double)>[
      ('a 300% browser zoom window', const Size(427, 237), 1),
      ('a phone at 300% text', const Size(390, 844), 3),
      ('a phone on its side at 200% text', const Size(844, 390), 2),
    ]) {
      testWidgets('on $name nothing overflows and confirm is reachable', (
        WidgetTester tester,
      ) async {
        final Future<bool> result = await _open(
          tester,
          size: size,
          scale: scale,
          destructive: true,
        );
        expect(tester.takeException(), isNull);

        final Finder confirm = find.text('Remove member');
        await tester.ensureVisible(confirm);
        await tester.pumpAndSettle();
        final Rect rect = tester.getRect(confirm);
        expect(rect.top, greaterThanOrEqualTo(0));
        expect(rect.bottom, lessThanOrEqualTo(size.height));
        await tester.tap(confirm);
        await tester.pumpAndSettle();
        expect(await result, isTrue);
      });
    }
  });

  group('FoDialog', () {
    testWidgets('cancel resolves false', (WidgetTester tester) async {
      final Future<bool> result = await _open(
        tester,
        size: const Size(1280, 800),
        scale: 1,
      );
      await tester.tap(find.text('Stay'));
      await tester.pumpAndSettle();
      expect(await result, isFalse);
    });

    testWidgets('the barrier is a no, never consent', (
      WidgetTester tester,
    ) async {
      final Future<bool> result = await _open(
        tester,
        size: const Size(1280, 800),
        scale: 1,
      );
      await tester.tapAt(const Offset(4, 4));
      await tester.pumpAndSettle();
      expect(await result, isFalse);
    });

    testWidgets('on a wide window the buttons sit side by side, cancel first',
        (WidgetTester tester) async {
      await _open(tester, size: const Size(1280, 800), scale: 1);
      final Rect stay = tester.getRect(find.text('Stay'));
      final Rect leave = tester.getRect(find.text('Leave'));
      expect(stay.center.dy, closeTo(leave.center.dy, 1));
      expect(stay.center.dx, lessThan(leave.center.dx));
    });

    testWidgets('on a phone they stack, confirm on top', (
      WidgetTester tester,
    ) async {
      await _open(tester, size: const Size(390, 844), scale: 1);
      final Rect stay = tester.getRect(find.text('Stay'));
      final Rect leave = tester.getRect(find.text('Leave'));
      expect(leave.center.dy, lessThan(stay.center.dy));
    });
  });
}

import 'package:figuredout_ui/figuredout_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/pump.dart';

/// `FoDateField`, and the two functions that define what its text means.
///
/// The value is the controller's text and it is ISO-8601. That is the whole
/// contract, so the tests are about the two ways a date gets in — typed and
/// picked — and about the parse refusing what only *looks* like a date.
void main() {
  group('foIsoDate and foParseIsoDate', () {
    test('round trip a real date', () {
      expect(foIsoDate(DateTime(2026, 8, 29)), '2026-08-29');
      expect(foParseIsoDate('2026-08-29'), DateTime(2026, 8, 29));
      // Zero-padded, because a string that sorts is half the reason for this
      // format.
      expect(foIsoDate(DateTime(2026, 1, 9)), '2026-01-09');
    });

    test('refuse a date that is not one', () {
      // The trap this parse exists for: `DateTime.parse` accepts this and
      // rolls it into 2 March, so a typo becomes a different date rather than
      // an error.
      expect(foParseIsoDate('2024-02-31'), isNull);
      expect(foParseIsoDate('2026-13-01'), isNull);
      expect(foParseIsoDate('29-08-2026'), isNull);
      expect(foParseIsoDate('2026-8-9'), isNull);
      expect(foParseIsoDate(''), isNull);
      expect(foParseIsoDate(null), isNull);
    });
  });

  group('FoDateField', () {
    testWidgets('takes what is typed, as the value', (
      WidgetTester tester,
    ) async {
      final TextEditingController controller = TextEditingController();
      addTearDown(controller.dispose);
      final List<String> changes = <String>[];

      await pumpFo(
        tester,
        child: FoDateField(
          label: 'Filed on',
          controller: controller,
          pickSemanticLabel: 'Pick the filing date',
          onChanged: changes.add,
        ),
      );

      await tester.enterText(find.byType(TextField), '2026-08-29');
      await tester.pumpAndSettle();

      // Typed, not picked: somebody entering a month of filings is faster than
      // any calendar, and the field must not get in their way.
      expect(controller.text, '2026-08-29');
      expect(changes.last, '2026-08-29');
    });

    testWidgets('the calendar writes the value in the same shape', (
      WidgetTester tester,
    ) async {
      final TextEditingController controller = TextEditingController(
        text: '2026-08-29',
      );
      addTearDown(controller.dispose);
      final List<String> changes = <String>[];

      await pumpFo(
        tester,
        surfaceSize: const Size(1280, 800),
        child: FoDateField(
          label: 'Filed on',
          controller: controller,
          pickSemanticLabel: 'Pick the filing date',
          firstDate: DateTime(2026),
          lastDate: DateTime(2026, 12, 31),
          onChanged: changes.add,
        ),
      );

      await tester.tap(find.byIcon(Icons.calendar_today_outlined));
      await tester.pumpAndSettle();

      // It opens on what is already in the field, so the calendar starts where
      // the user is rather than a hundred years ago.
      expect(find.text('August 2026'), findsOneWidget);

      await tester.tap(find.text('12'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      expect(controller.text, '2026-08-12');
      expect(changes.last, '2026-08-12');
    });

    testWidgets('the calendar button is named, and it goes with the field', (
      WidgetTester tester,
    ) async {
      final TextEditingController controller = TextEditingController();
      addTearDown(controller.dispose);

      await pumpFo(
        tester,
        child: FoDateField(
          label: 'Filed on',
          controller: controller,
          pickSemanticLabel: 'Pick the filing date',
          enabled: false,
        ),
      );

      // Icon-only, so it carries its own name — and the name is the caller's,
      // because this package holds no copy.
      final IconButton button = tester.widget<IconButton>(
        find.byType(IconButton),
      );
      expect(button.tooltip, 'Pick the filing date');
      // A disabled field cannot be picked around.
      expect(button.onPressed, isNull);
    });
  });
}

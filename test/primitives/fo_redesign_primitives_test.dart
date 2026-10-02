import 'package:figuredout_ui/figuredout_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/pump.dart';

/// The fill and ink a [FoStatusChip] actually paints, read off its widgets.
(Color?, Color?) _chipColours(WidgetTester tester, String label) {
  final Container box = tester.widget<Container>(
    find.ancestor(of: find.text(label), matching: find.byType(Container)).first,
  );
  final Text text = tester.widget<Text>(find.text(label));
  return ((box.decoration! as BoxDecoration).color, text.style?.color);
}

void main() {
  group('FoStatusChip vocabularies', () {
    testWidgets('an entry status maps to one tone and one glyph', (
      WidgetTester tester,
    ) async {
      await pumpFo(
        tester,
        child: Column(
          children: <Widget>[
            FoStatusChip.entry(status: FoEntryStatus.draft, label: 'Draft'),
            FoStatusChip.entry(
              status: FoEntryStatus.submitted,
              label: 'Submitted',
            ),
            FoStatusChip.entry(
              status: FoEntryStatus.changeRequested,
              label: 'Change requested',
            ),
            FoStatusChip.entry(
              status: FoEntryStatus.needsApproval,
              label: 'Needs approval',
            ),
          ],
        ),
      );

      const FoColors c = FoColors.light;
      expect(_chipColours(tester, 'Draft'), (c.surfaceSunken, c.fgMuted));
      expect(_chipColours(tester, 'Submitted'), (c.successSoft, c.success));
      expect(_chipColours(tester, 'Change requested'), (c.infoSoft, c.info));
      expect(
          _chipColours(tester, 'Needs approval'), (c.warningSoft, c.warning));

      // Colour is never the only signal: every entry state carries a glyph.
      expect(find.byIcon(Icons.lock_outline), findsOneWidget);
      expect(find.byIcon(Icons.edit_outlined), findsOneWidget);
      expect(find.byIcon(Icons.schedule), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber_outlined), findsOneWidget);
    });

    test('Running and Completed never share a tone', () {
      expect(FoOrderStatus.running.tone, FoStatusTone.primary);
      expect(FoOrderStatus.completed.tone, FoStatusTone.success);
      expect(FoOrderStatus.notStarted.tone, FoStatusTone.neutral);
      expect(FoOrderStatus.onHold.tone, FoStatusTone.warning);
      expect(FoOrderStatus.cancelled.tone, FoStatusTone.danger);
      expect(
        FoOrderStatus.values.map((FoOrderStatus s) => s.tone).toSet(),
        hasLength(FoOrderStatus.values.length),
        reason: 'each order state reads as itself',
      );
    });

    test('a deadline gets louder as it closes', () {
      expect(FoDueStatus.onTrack.tone, FoStatusTone.neutral);
      expect(FoDueStatus.dueSoon.tone, FoStatusTone.warning);
      expect(FoDueStatus.overdue.tone, FoStatusTone.danger);
    });

    testWidgets('a chip is a pill and announces its subject', (
      WidgetTester tester,
    ) async {
      await pumpFo(
        tester,
        child: FoStatusChip.order(
          status: FoOrderStatus.running,
          label: 'Running',
          semanticPrefix: 'Order status',
        ),
      );

      final Container box = tester.widget<Container>(
        find
            .ancestor(
                of: find.text('Running'), matching: find.byType(Container))
            .first,
      );
      expect(
        (box.decoration! as BoxDecoration).borderRadius,
        BorderRadius.circular(FoTokens.radiusPill),
      );
      expect(
        tester.getSemantics(find.byType(FoStatusChip)).label,
        'Order status: Running',
      );
    });
  });

  group('FoButton', () {
    testWidgets('warning is ink on its own wash, edged in the ink', (
      WidgetTester tester,
    ) async {
      await pumpFo(
        tester,
        child: FoButton(
          label: 'Request a change',
          variant: FoButtonVariant.warning,
          onPressed: () {},
        ),
      );

      final ButtonStyle style =
          tester.widget<FilledButton>(find.byType(FilledButton)).style!;
      expect(
        style.backgroundColor!.resolve(<WidgetState>{}),
        FoColors.light.warningSoft,
      );
      expect(
        style.foregroundColor!.resolve(<WidgetState>{}),
        FoColors.light.warning,
      );
      expect(
        style.side!.resolve(<WidgetState>{})!.color,
        FoColors.light.warningRing,
      );
    });

    testWidgets('large is 56 points tall — the phone action bar size', (
      WidgetTester tester,
    ) async {
      await pumpFo(
        tester,
        child: FoButton(
          label: 'Record pressing',
          variant: FoButtonVariant.primary,
          size: FoButtonSize.large,
          trailingIcon: Icons.arrow_forward,
          onPressed: () {},
        ),
      );

      expect(
        tester.getSize(find.byType(FilledButton)).height,
        greaterThanOrEqualTo(56),
      );
      expect(find.byIcon(Icons.arrow_forward), findsOneWidget);
    });
  });

  group('FoIconButton', () {
    testWidgets('is a named 48-point target however small its glyph', (
      WidgetTester tester,
    ) async {
      int taps = 0;
      await pumpFo(
        tester,
        child: FoIconButton(
          icon: Icons.close,
          iconSize: 16,
          semanticLabel: 'Close the panel',
          onPressed: () => taps++,
        ),
      );

      final Size size = tester.getSize(find.byType(FoIconButton));
      expect(size.width, greaterThanOrEqualTo(48));
      expect(size.height, greaterThanOrEqualTo(48));

      expect(find.bySemanticsLabel('Close the panel'), findsOneWidget);
      await tester.tap(find.byType(FoIconButton));
      expect(taps, 1);
    });
  });

  group('FoNumberField', () {
    Widget field({
      required int value,
      required ValueChanged<int> onChanged,
      int? max,
      bool warning = false,
    }) =>
        FoNumberField(
          value: value,
          onChanged: onChanged,
          max: max,
          warning: warning,
          semanticLabel: 'Pressed, size M',
          decreaseSemanticLabel: 'One fewer, size M',
          increaseSemanticLabel: 'One more, size M',
        );

    testWidgets('the steppers move the value by one, and stop at zero', (
      WidgetTester tester,
    ) async {
      final List<int> seen = <int>[];
      await pumpFo(tester, child: field(value: 0, onChanged: seen.add));

      await tester.tap(find.bySemanticsLabel('One fewer, size M'));
      expect(seen, isEmpty, reason: 'a count of pieces is never negative');

      await tester.tap(find.bySemanticsLabel('One more, size M'));
      expect(seen, <int>[1]);
    });

    testWidgets('a value set from outside is shown — it is controlled', (
      WidgetTester tester,
    ) async {
      // The bug FoMatrixNumericCell and the old FoDropdownField both had:
      // "Fill all ready" sets every value, and an uncontrolled field ignores it.
      int value = 3;
      late StateSetter setOuter;
      await pumpFo(
        tester,
        child: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            setOuter = setState;
            return field(value: value, onChanged: (int v) => value = v);
          },
        ),
      );
      expect(find.text('3'), findsOneWidget);

      setOuter(() => value = 36);
      await tester.pump();
      expect(find.text('36'), findsOneWidget);
    });

    testWidgets('typing reports the number, clamped to max', (
      WidgetTester tester,
    ) async {
      final List<int> seen = <int>[];
      await pumpFo(
        tester,
        child: field(value: 0, max: 99, onChanged: seen.add),
      );

      await tester.enterText(find.byType(TextField), '42');
      expect(seen.last, 42);

      await tester.enterText(find.byType(TextField), '500');
      expect(seen.last, 99);
    });

    testWidgets('an emptied box is a draft, not a zero', (
      WidgetTester tester,
    ) async {
      final List<int> seen = <int>[];
      await pumpFo(tester, child: field(value: 12, onChanged: seen.add));

      await tester.enterText(find.byType(TextField), '');
      expect(seen, isEmpty, reason: 'clearing to retype must not report 0');
    });

    testWidgets('over a limit draws a 2-point warning ring, not an error', (
      WidgetTester tester,
    ) async {
      await pumpFo(
        tester,
        child: field(value: 44, warning: true, onChanged: (_) {}),
      );

      final Container box = tester.widget<Container>(
        find
            .ancestor(
              of: find.byType(TextField),
              matching: find.byType(Container),
            )
            .first,
      );
      final Border border =
          (box.foregroundDecoration! as BoxDecoration).border! as Border;
      expect(border.top.color, FoColors.light.warning);
      expect(border.top.width, 2);
    });

    testWidgets('every stepper is at least 48 points wide', (
      WidgetTester tester,
    ) async {
      await pumpFo(tester, child: field(value: 1, onChanged: (_) {}));
      for (final String label in <String>[
        'One fewer, size M',
        'One more, size M',
      ]) {
        final Size size = tester.getSize(find.bySemanticsLabel(label));
        expect(size.width, greaterThanOrEqualTo(48));
        expect(size.height, greaterThanOrEqualTo(48));
      }
    });
  });

  group('FoProgressBar', () {
    testWidgets('fills its share and says the reading in words', (
      WidgetTester tester,
    ) async {
      await pumpFo(
        tester,
        child: const SizedBox(
          width: 400,
          child: FoProgressBar(
            value: 1260,
            max: 2400,
            semanticLabel: 'Slim Chino, packed',
            semanticValue: '1,260 of 2,400',
            trailing: Text('1,260 / 2,400 packed'),
          ),
        ),
      );

      final FractionallySizedBox fill = tester.widget<FractionallySizedBox>(
        find.byType(FractionallySizedBox),
      );
      expect(fill.widthFactor, closeTo(0.525, 0.001));

      final SemanticsNode node = tester.getSemantics(
        find.byType(FoProgressBar),
      );
      expect(node.label, 'Slim Chino, packed');
      expect(node.value, '1,260 of 2,400');
    });

    testWidgets('a value past max stops at full', (WidgetTester tester) async {
      await pumpFo(
        tester,
        child: const SizedBox(
          width: 200,
          child: FoProgressBar(
            value: 120,
            max: 100,
            semanticLabel: 'Line 1',
            semanticValue: '120%',
          ),
        ),
      );
      expect(
        tester
            .widget<FractionallySizedBox>(find.byType(FractionallySizedBox))
            .widthFactor,
        1,
      );
    });
  });
}

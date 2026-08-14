import 'package:figuredout_ui/figuredout_ui.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/pump.dart';

void main() {
  /// Rule §3.1 / G3 — the whole reason `FoCard` is not a Material `Card`.
  ///
  /// A card clips its children, so a child that paints a full-bleed band —
  /// `FoSectionSurface`'s header, a table's header row — covers a hairline
  /// drawn in `decoration`. The failure is silent and the symptom (one missing
  /// line along one edge) looks nothing like the cause, so it is worth pinning
  /// down here rather than trusting a reviewer to spot it.
  group('FoCard hairline', () {
    testWidgets('is a foreground decoration, never decoration.border', (
      WidgetTester tester,
    ) async {
      await pumpFo(tester, child: const FoCard(child: Text('Body')));

      final Iterable<DecoratedBox> boxes = tester.widgetList<DecoratedBox>(
        find.descendant(
          of: find.byType(FoCard),
          matching: find.byType(DecoratedBox),
        ),
      );

      final Iterable<DecoratedBox> bordered = boxes.where(
        (DecoratedBox b) => (b.decoration as BoxDecoration).border != null,
      );

      expect(
        bordered,
        isNotEmpty,
        reason: 'the card must draw a hairline somewhere',
      );
      for (final DecoratedBox box in bordered) {
        expect(
          box.position,
          DecorationPosition.foreground,
          reason: 'a hairline in decoration.border is painted under a clipped '
              "child's full-bleed background and disappears — see rule 3.1",
        );
      }
    });

    testWidgets('the fill is not the hairline layer', (
      WidgetTester tester,
    ) async {
      await pumpFo(tester, child: const FoCard(child: Text('Body')));

      final Iterable<DecoratedBox> filled = tester
          .widgetList<DecoratedBox>(
            find.descendant(
              of: find.byType(FoCard),
              matching: find.byType(DecoratedBox),
            ),
          )
          .where(
            (DecoratedBox b) => (b.decoration as BoxDecoration).color != null,
          );

      expect(filled, isNotEmpty);
      for (final DecoratedBox box in filled) {
        final BoxDecoration decoration = box.decoration as BoxDecoration;
        expect(decoration.color, FoColors.light.surface);
        expect(decoration.boxShadow, FoShadows.light.raised);
        expect(box.position, DecorationPosition.background);
      }
    });
  });

  group('FoCard surface', () {
    testWidgets('rests on surface, not on white', (WidgetTester tester) async {
      await pumpFo(tester, child: const FoCard(child: Text('Body')));

      final BoxDecoration decoration = _fillOf(tester);
      expect(decoration.color, FoColors.light.surface);
      expect(
        decoration.color,
        isNot(FoColors.light.surfaceRaised),
        reason:
            'G5 — white is the top of the ladder, not the resting surface. A '
            'card that sits on white leaves "raised" with nowhere to go.',
      );
    });

    testWidgets('lifts to surfaceRaised on hover when interactive', (
      WidgetTester tester,
    ) async {
      await pumpFo(
        tester,
        child: FoCard(onTap: () {}, child: const Text('Body')),
      );
      expect(_fillOf(tester).color, FoColors.light.surface);

      final TestGesture gesture = await tester.createGesture(
        kind: PointerDeviceKind.mouse,
      );
      addTearDown(gesture.removePointer);
      await gesture.addPointer(location: Offset.zero);
      await gesture.moveTo(tester.getCenter(find.byType(FoCard)));
      await tester.pumpAndSettle();

      final BoxDecoration hovered = _fillOf(tester);
      expect(hovered.color, FoColors.light.surfaceRaised);
      expect(
        hovered.boxShadow,
        FoShadows.light.hover,
        reason: 'a picked-up thing gets the hover step, not a fourth one',
      );
    });

    testWidgets('a non-interactive card never lifts and takes no focus', (
      WidgetTester tester,
    ) async {
      await pumpFo(tester, child: const FoCard(child: Text('Body')));
      expect(find.byType(FoFocusRing), findsNothing);
      expect(find.byType(InkWell), findsNothing);
    });

    testWidgets('an interactive card is announced as a button', (
      WidgetTester tester,
    ) async {
      await pumpFo(
        tester,
        child: FoCard(
          onTap: () {},
          semanticLabel: 'Open order 1024',
          child: const Text('Body'),
        ),
      );

      final SemanticsNode node = tester.getSemantics(find.byType(FoCard));

      // The label prefixes the card's own content rather than replacing it —
      // the announcement is "Open order 1024, Body", which is what a user
      // wants: what tapping does, then what they are tapping.
      expect(node.label, startsWith('Open order 1024'));
      expect(node.label, contains('Body'));
      expect(
        node,
        isSemantics(isButton: true, hasTapAction: true),
      );
    });
  });
}

BoxDecoration _fillOf(WidgetTester tester) {
  return tester
      .widgetList<DecoratedBox>(
        find.descendant(
          of: find.byType(FoCard),
          matching: find.byType(DecoratedBox),
        ),
      )
      .firstWhere(
        (DecoratedBox b) => (b.decoration as BoxDecoration).color != null,
      )
      .decoration as BoxDecoration;
}

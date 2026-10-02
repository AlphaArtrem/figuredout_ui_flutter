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

      // By default the label prefixes the card's own content rather than
      // replacing it — "Open order 1024, Body": nothing the content says is
      // lost, which is what an unaudited call site needs.
      expect(node.label, startsWith('Open order 1024'));
      expect(node.label, contains('Body'));
      expect(
        node,
        isSemantics(isButton: true, hasTapAction: true, isFocusable: true),
      );
    });

    // Found by a consuming app's accessibility tour (legal_app traps §84):
    // the label was merged with the content, so every card labelled with its
    // own words was read twice — `label: "Roles\nRoles"` — and a card labelled
    // with a summary read the summary and then the same facts again.
    testWidgets('labelReplacesContent: a card is announced once, by its label',
        (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      int taps = 0;
      await pumpFo(
        tester,
        child: FoCard(
          onTap: () => taps++,
          semanticLabel: 'Roles',
          labelReplacesContent: true,
          child: const Text('Roles'),
        ),
      );

      final SemanticsNode node = tester.getSemantics(find.byType(FoCard));
      expect(node.label, 'Roles');
      expect(find.bySemanticsLabel('Roles'), findsOneWidget);

      // The tap still reaches the card through the semantics action.
      tester.semantics.tap(find.semantics.byLabel('Roles'));
      expect(taps, 1);
      handle.dispose();
    });

    testWidgets('by default a button inside a labelled card stays reachable', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pumpFo(
        tester,
        child: FoCard(
          onTap: () {},
          semanticLabel: 'Principal',
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Text('Principal'),
              IconButton(
                tooltip: 'Delete role',
                icon: const Icon(Icons.delete_outline),
                onPressed: () {},
              ),
            ],
          ),
        ),
      );

      // Its own node, a button named by its tooltip, beside the card's.
      expect(
        tester.getSemantics(find.byTooltip('Delete role')),
        isSemantics(isButton: true, tooltip: 'Delete role', hasTapAction: true),
      );
      handle.dispose();
    });

    testWidgets('an unlabelled interactive card is named by its content', (
      WidgetTester tester,
    ) async {
      await pumpFo(
        tester,
        child: FoCard(onTap: () {}, child: const Text('Body')),
      );

      final SemanticsNode node = tester.getSemantics(find.byType(FoCard));
      expect(node.label, 'Body');
      expect(node, isSemantics(isButton: true, hasTapAction: true));
    });

    testWidgets('a Material child paints its ink inside the card, not behind', (
      WidgetTester tester,
    ) async {
      // The card paints a fill, so a ListTile whose nearest Material ancestor
      // is *above* that fill splashes behind the card. Flutter asserts about
      // it rather than merely looking wrong, which is how a whole form full of
      // list rows failed at once during the Luxe migration.
      await pumpFo(
        tester,
        child: FoCard(
          child: ListTile(title: const Text('Attach a photo'), onTap: () {}),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(
        find.descendant(
          of: find.byType(FoCard),
          matching: find.byType(Material),
        ),
        findsWidgets,
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

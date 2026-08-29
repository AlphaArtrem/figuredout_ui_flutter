import 'package:figuredout_ui/figuredout_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/pump.dart';

/// Every `Opacity` in the tile that is actually dimming something.
///
/// Material's own `Switch` builds an `Opacity` at 1.0, so counting the widget
/// type finds one whether the row is dimmed or not — which is a test that
/// passes for the wrong reason in both directions.
List<Opacity> _dimming(WidgetTester tester) => tester
    .widgetList<Opacity>(
      find.descendant(
        of: find.byType(FoSwitchTile),
        matching: find.byType(Opacity),
      ),
    )
    .where((Opacity o) => o.opacity < 1)
    .toList();

void main() {
  group('FoSwitchTile input', () {
    testWidgets('the row is the target, and it toggles once', (
      WidgetTester tester,
    ) async {
      final List<bool> asked = <bool>[];
      await pumpFo(
        tester,
        child: FoSwitchTile(
          value: false,
          title: 'Filterable',
          onChanged: asked.add,
        ),
      );

      // Tapping the *title* must work: the whole row is the control, because a
      // 48dp switch at the end of a row is a small target one-handed.
      await tester.tap(find.text('Filterable'));
      await tester.pumpAndSettle();
      expect(asked, <bool>[true]);

      // And tapping the switch itself fires once, not twice. The switch is
      // inside an IgnorePointer precisely so the card owns the gesture — with
      // both live, every tap on the control toggled and toggled back.
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      expect(asked, <bool>[true, true]);
    });

    testWidgets('asks for the opposite of the current value', (
      WidgetTester tester,
    ) async {
      final List<bool> asked = <bool>[];
      await pumpFo(
        tester,
        child: FoSwitchTile(
          value: true,
          title: 'Filterable',
          onChanged: asked.add,
        ),
      );

      await tester.tap(find.text('Filterable'));
      await tester.pumpAndSettle();
      expect(asked, <bool>[false]);
    });

    testWidgets('a null onChanged takes no input', (WidgetTester tester) async {
      await pumpFo(
        tester,
        child: const FoSwitchTile(
          value: true,
          title: 'Filterable',
          onChanged: null,
        ),
      );

      await tester.tap(find.text('Filterable'));
      await tester.pumpAndSettle();
      // Nothing to assert but the absence of a crash and of a callback — the
      // point is that the card is inert, which the semantics test below pins.
      expect(find.byType(Switch), findsOneWidget);
    });
  });

  /// The reason this component exists rather than each app composing its own.
  ///
  /// A *disabled* Material `Switch` that is **on** paints a grey track with
  /// the thumb to the right, which at a glance reads as off. A consuming app
  /// shipped five permissions labelled "always on" beside a control that
  /// looked off, and only a live run on a phone caught it.
  group('FoSwitchTile lock', () {
    testWidgets('replaces the switch with a word, never greys it', (
      WidgetTester tester,
    ) async {
      await pumpFo(
        tester,
        child: const FoSwitchTile(
          value: true,
          title: 'Manage the firm’s lists',
          onChanged: null,
          lock: FoSwitchTileLock(
            label: 'Always on',
            reason: 'The Principal keeps this.',
          ),
        ),
      );

      expect(find.byType(Switch), findsNothing);
      expect(find.text('Always on'), findsOneWidget);
      expect(find.text('The Principal keeps this.'), findsOneWidget);
    });

    testWidgets('the chip carries the value, not just the lock', (
      WidgetTester tester,
    ) async {
      await pumpFo(
        tester,
        child: const FoSwitchTile(
          value: false,
          title: 'Something off and fixed',
          onChanged: null,
          lock: FoSwitchTileLock(label: 'Set by your firm'),
        ),
      );

      final FoStatusChip chip = tester.widget<FoStatusChip>(
        find.byType(FoStatusChip),
      );
      // Off is not a failure and not a success — it simply is.
      expect(chip.tone, FoStatusTone.neutral);
    });

    testWidgets('a locked row is not dimmed — it is telling you something', (
      WidgetTester tester,
    ) async {
      await pumpFo(
        tester,
        child: const FoSwitchTile(
          value: true,
          title: 'Locked',
          onChanged: null,
          lock: FoSwitchTileLock(label: 'Always on'),
        ),
      );

      expect(
        _dimming(tester),
        isEmpty,
        reason: 'dimming says "not now"; a lock says "not ever" and has to '
            'stay fully legible',
      );
    });

    testWidgets('a read-only row dims instead, and keeps the switch', (
      WidgetTester tester,
    ) async {
      await pumpFo(
        tester,
        child: const FoSwitchTile(
          value: true,
          title: 'Saving',
          onChanged: null,
        ),
      );

      expect(find.byType(Switch), findsOneWidget);
      // The switch keeps a live onChanged so Material paints it in its on
      // colours; the dimming is applied uniformly to the row instead. Handing
      // Material a null onChanged is what greys both states into one.
      final Switch control = tester.widget<Switch>(find.byType(Switch));
      expect(control.onChanged, isNotNull);
      expect(_dimming(tester), hasLength(1));
    });
  });

  group('FoSwitchTile semantics', () {
    testWidgets('announces one toggle, not a button holding a switch', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pumpFo(
        tester,
        child: FoSwitchTile(
          value: true,
          title: 'Filterable',
          subtitle: 'A little slower to save.',
          onChanged: (_) {},
        ),
      );

      expect(
        tester.getSemantics(find.byType(FoSwitchTile)),
        isSemantics(
          label: 'Filterable',
          hint: 'A little slower to save.',
          hasToggledState: true,
          isToggled: true,
          isEnabled: true,
          hasTapAction: true,
          // FoCard announces itself as a button when it is tappable. That is
          // right for a card and wrong for a switch, so the row's own
          // semantics replace it rather than nesting inside it.
          isButton: false,
        ),
      );

      handle.dispose();
    });

    testWidgets('a semanticLabel overrides an ambiguous title', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pumpFo(
        tester,
        child: FoSwitchTile(
          value: false,
          title: 'Required',
          semanticLabel: 'Insurer is a required field',
          onChanged: (_) {},
        ),
      );

      expect(
        tester.getSemantics(find.byType(FoSwitchTile)).label,
        'Insurer is a required field',
      );
      handle.dispose();
    });

    testWidgets('a read-only row announces itself disabled', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pumpFo(
        tester,
        child: const FoSwitchTile(
          value: true,
          title: 'Saving',
          onChanged: null,
        ),
      );

      expect(
        tester.getSemantics(find.byType(FoSwitchTile)),
        isSemantics(
          isEnabled: false,
          // Still toggled: read-only does not mean valueless.
          hasToggledState: true,
          isToggled: true,
        ),
      );
      handle.dispose();
    });
  });

  testWidgets('the row clears the touch floor even with no subtitle', (
    WidgetTester tester,
  ) async {
    await pumpFo(
      tester,
      child: FoSwitchTile(value: false, title: 'On', onChanged: (_) {}),
    );

    expect(
      tester.getSize(find.byType(FoSwitchTile)).height,
      greaterThanOrEqualTo(FoLayout.minTouchTarget),
    );
  });
}

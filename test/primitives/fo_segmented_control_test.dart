import 'package:figuredout_ui/figuredout_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/pump.dart';

/// The fill of one segment, read off the widget rather than off a screenshot.
///
/// `AnimatedContainer` builds a `Container` whose decoration is what actually
/// paints, so the assertion has to reach the decoration — comparing rendered
/// pixels would make this a golden test of a thing that is about *which token*,
/// not about how it looks.
Color? _fillOf(WidgetTester tester, String label) {
  final Finder container = find
      .ancestor(
        of: find.text(label),
        matching: find.byType(AnimatedContainer),
      )
      .first;
  final AnimatedContainer widget = tester.widget<AnimatedContainer>(container);
  return (widget.decoration! as BoxDecoration).color;
}

void main() {
  const List<FoSegment> two = <FoSegment>[
    FoSegment(label: 'Active'),
    FoSegment(label: 'Disposed'),
  ];

  group('FoSegmentedControl selection', () {
    testWidgets('reports the segment the user asked for', (
      WidgetTester tester,
    ) async {
      final List<int> asked = <int>[];
      await pumpFo(
        tester,
        child: FoSegmentedControl(
          segments: two,
          selectedIndex: 0,
          onSelected: asked.add,
        ),
      );

      await tester.tap(find.text('Disposed'));
      await tester.pumpAndSettle();
      expect(asked, <int>[1]);
    });

    testWidgets('does not report the segment the user is already in', (
      WidgetTester tester,
    ) async {
      final List<int> asked = <int>[];
      await pumpFo(
        tester,
        child: FoSegmentedControl(
          segments: two,
          selectedIndex: 0,
          onSelected: asked.add,
        ),
      );

      // Tapping where you already are is not a navigation. Firing here would
      // reload a list under somebody's thumb, which reads as the app jumping.
      await tester.tap(find.text('Active'));
      await tester.pumpAndSettle();
      expect(asked, isEmpty);
    });

    testWidgets('always shows exactly one segment as current', (
      WidgetTester tester,
    ) async {
      await pumpFo(
        tester,
        child: FoSegmentedControl(
          segments: two,
          selectedIndex: 1,
          onSelected: (_) {},
        ),
      );

      // The whole promise of a segment over a filter: you can see where you
      // are without opening anything.
      expect(_fillOf(tester, 'Disposed'), isNot(Colors.transparent));
      expect(_fillOf(tester, 'Active'), Colors.transparent);
    });

    testWidgets('an out-of-range index still shows one as current', (
      WidgetTester tester,
    ) async {
      await pumpFo(
        tester,
        child: FoSegmentedControl(
          segments: two,
          selectedIndex: 7,
          onSelected: (_) {},
        ),
      );

      // A caller restoring a stale index must not produce a control with no
      // current destination — that is the one state this component says
      // cannot exist.
      expect(_fillOf(tester, 'Disposed'), isNot(Colors.transparent));
    });
  });

  group('FoSegmentedControl surfaces', () {
    testWidgets('the track is a hole and the current segment rests in it', (
      WidgetTester tester,
    ) async {
      late FoColors colors;
      await pumpFo(
        tester,
        child: Builder(
          builder: (BuildContext context) {
            colors = context.foColors;
            return FoSegmentedControl(
              segments: two,
              selectedIndex: 0,
              onSelected: (_) {},
            );
          },
        ),
      );

      // Rule 6, and the reason this is a component: `docs/components.md` has
      // reserved `surfaceSunken` for a segmented-control track since before one
      // existed. Emphasis comes from being on a different step of the ladder,
      // never from a lighter colour.
      final DecoratedBox track = tester.widget<DecoratedBox>(
        find
            .descendant(
              of: find.byType(FoSegmentedControl),
              matching: find.byType(DecoratedBox),
            )
            .first,
      );
      expect(
        (track.decoration as BoxDecoration).color,
        colors.surfaceSunken,
      );
      expect(_fillOf(tester, 'Active'), colors.surface);
    });
  });

  group('FoSegmentedControl labels', () {
    testWidgets('shows a count after the label when it has one', (
      WidgetTester tester,
    ) async {
      await pumpFo(
        tester,
        child: FoSegmentedControl(
          segments: const <FoSegment>[
            FoSegment(label: 'Active', count: 12),
            FoSegment(label: 'Disposed', count: 41),
          ],
          selectedIndex: 0,
          onSelected: (_) {},
        ),
      );

      // "Disposed" is a place; "Disposed 41" tells somebody whether it is
      // worth going there.
      expect(find.text('Active 12'), findsOneWidget);
      expect(find.text('Disposed 41'), findsOneWidget);
    });

    testWidgets(
        'shows nothing at all rather than a zero when the count is null', (
      WidgetTester tester,
    ) async {
      await pumpFo(
        tester,
        child: FoSegmentedControl(
          segments: two,
          selectedIndex: 0,
          onSelected: (_) {},
        ),
      );

      // A count that has not loaded and a count of none are different things,
      // and a bare zero reads as the second.
      expect(find.text('Active'), findsOneWidget);
      expect(find.text('Active 0'), findsNothing);
    });

    testWidgets('wraps a long label rather than ellipsising it', (
      WidgetTester tester,
    ) async {
      await pumpFo(
        tester,
        surfaceSize: const Size(320, 640),
        child: const FoSegmentedControlHarness(),
      );

      // A Devanagari label is longer than the English one it was sized
      // against, and "निस्ता…" is not a destination anybody can read.
      final Text text = tester.widget<Text>(find.text('निस्तारित मामले'));
      expect(text.overflow, isNot(TextOverflow.ellipsis));
    });
  });

  group('FoSegmentedControl accessibility', () {
    testWidgets('each segment announces itself and whether it is current', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pumpFo(
        tester,
        child: FoSegmentedControl(
          segments: two,
          selectedIndex: 1,
          onSelected: (_) {},
          semanticLabel: 'Case list',
        ),
      );

      // The current one announces *selected*, and carries no tap action —
      // honestly, because there is nothing to do there. A screen-reader user
      // needs to know where they are, which is the flag, not an action that
      // would do nothing.
      expect(
        tester.getSemantics(find.text('Disposed')),
        matchesSemantics(
          label: 'Disposed',
          isButton: true,
          isSelected: true,
          hasSelectedState: true,
        ),
      );

      // The other one is the actionable half. It carries the tap action
      // explicitly, because `excludeSemantics` drops the InkWell's — and
      // without that a screen-reader user could read the segments and activate
      // none of them.
      //
      // No `focus` action, and that is the trade `excludeSemantics` buys: one
      // node per segment rather than a button wrapping a focusable wrapping a
      // label. Keyboard traversal is unaffected — the InkWell is still in the
      // focus tree and `FoFocusRing` still paints (rule 5); it is only the
      // *semantic* focus node that is folded into the parent.
      expect(
        tester.getSemantics(find.text('Active')),
        matchesSemantics(
          label: 'Active',
          isButton: true,
          hasSelectedState: true,
          hasTapAction: true,
        ),
      );
      handle.dispose();
    });

    testWidgets('every segment clears the minimum touch target', (
      WidgetTester tester,
    ) async {
      await pumpFo(
        tester,
        child: FoSegmentedControl(
          segments: two,
          selectedIndex: 0,
          onSelected: (_) {},
        ),
      );

      // A clerk taps these standing up, one-handed, in a corridor.
      for (final String label in <String>['Active', 'Disposed']) {
        final Finder segment = find
            .ancestor(
              of: find.text(label),
              matching: find.byType(AnimatedContainer),
            )
            .first;
        expect(
          tester.getSize(segment).height,
          greaterThanOrEqualTo(44),
          reason: '$label is too small to hit',
        );
      }
    });
  });
}

/// A three-segment control with a label that runs long in Devanagari.
///
/// Its own widget so the `const` list can sit outside the test body, which is
/// what the analyzer's `prefer_const_constructors` wants and what keeps the
/// assertion above about the *label* rather than about the harness.
class FoSegmentedControlHarness extends StatelessWidget {
  const FoSegmentedControlHarness({super.key});

  @override
  Widget build(BuildContext context) => FoSegmentedControl(
        segments: const <FoSegment>[
          FoSegment(label: 'सक्रिय'),
          FoSegment(label: 'निस्तारित मामले'),
        ],
        selectedIndex: 0,
        onSelected: (_) {},
      );
}

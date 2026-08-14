import 'package:figuredout_ui/figuredout_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/pump.dart';

void main() {
  group('FoSeamGrid', () {
    testWidgets('is one object, not four cards', (WidgetTester tester) async {
      await pumpFo(
        tester,
        surfaceSize: const Size(1280, 800),
        child: const FoSeamGrid(
          children: <Widget>[
            FoSeamCell(child: Text('A')),
            FoSeamCell(child: Text('B')),
            FoSeamCell(child: Text('C')),
            FoSeamCell(child: Text('D')),
          ],
        ),
      );

      // Four separate cards would be four shadows the eye has to relate;
      // a seamed block is one figure with four parts.
      expect(find.byType(FoCard), findsOneWidget);
    });

    testWidgets('seams go between cells, never around the outside', (
      WidgetTester tester,
    ) async {
      await pumpFo(
        tester,
        surfaceSize: const Size(1280, 800),
        child: const FoSeamGrid(
          children: <Widget>[
            FoSeamCell(child: Text('A')),
            FoSeamCell(child: Text('B')),
          ],
        ),
      );

      // Each cell's own wrapper, not the card's hairline — which is a
      // descendant of the grid too and legitimately draws all four sides.
      final List<Border> seams = <Border>[
        for (int i = 0; i < 2; i++)
          (tester
                  .widgetList<DecoratedBox>(
                    find.ancestor(
                      of: find.byType(FoSeamCell).at(i),
                      matching: find.byType(DecoratedBox),
                    ),
                  )
                  .first
                  .decoration as BoxDecoration)
              .border! as Border,
      ];

      // An outer edge here would double up with the card's own hairline and
      // read as a heavier line on two sides than the other two.
      expect(seams.any((Border b) => b.left != BorderSide.none), isTrue);
      expect(seams.every((Border b) => b.right == BorderSide.none), isTrue);
      expect(seams.every((Border b) => b.bottom == BorderSide.none), isTrue);
    });

    testWidgets('reflows 4 to 2 to 1, so a set never leaves a hole', (
      WidgetTester tester,
    ) async {
      Future<double> heightAt(double width) async {
        await pumpFo(
          tester,
          surfaceSize: Size(width, 900),
          child: const FoSeamGrid(
            children: <Widget>[
              FoSeamCell(child: Text('A')),
              FoSeamCell(child: Text('B')),
              FoSeamCell(child: Text('C')),
              FoSeamCell(child: Text('D')),
            ],
          ),
        );
        return tester.getSize(find.byType(FoSeamGrid)).height;
      }

      // Each step is a clean divisor of the one above, so four cells fill
      // every layout exactly.
      final double wide = await heightAt(1280);
      final double medium = await heightAt(760);
      final double narrow = await heightAt(420);
      expect(medium, greaterThan(wide));
      expect(narrow, greaterThan(medium));
    });

    testWidgets('no children renders nothing at all', (
      WidgetTester tester,
    ) async {
      await pumpFo(tester, child: const FoSeamGrid(children: <Widget>[]));
      expect(find.byType(FoCard), findsNothing);
    });
  });

  group('FoStatCard', () {
    testWidgets('the caption names the value and the value is the value', (
      WidgetTester tester,
    ) async {
      await pumpFo(
        tester,
        child: const FoStatCard(label: 'Cut today', value: '1,290'),
      );

      // Rule 3.3 made concrete: mono uppercase names, mono tabular is.
      final Text label = tester.widget<Text>(find.text('CUT TODAY'));
      final Text value = tester.widget<Text>(find.text('1,290'));
      expect(label.style!.fontFamily, contains(FoTokens.fontMono));
      expect(value.style!.fontFamily, contains(FoTokens.fontMono));
      expect(value.style!.fontSize, greaterThan(label.style!.fontSize!));
    });

    testWidgets('a trend colours the note as well as the arrow', (
      WidgetTester tester,
    ) async {
      await pumpFo(
        tester,
        child: const FoStatCard(
          label: 'Rejected',
          value: '18',
          note: 'up 4 on yesterday',
          trend: FoTrend.up,
        ),
      );

      // So the direction is legible without relying on the arrow alone.
      expect(find.byIcon(Icons.arrow_upward), findsOneWidget);
      expect(
        tester.widget<Text>(find.text('up 4 on yesterday')).style!.color,
        FoColors.light.success,
      );
    });

    testWidgets('a tappable card announces its label and value together', (
      WidgetTester tester,
    ) async {
      await pumpFo(
        tester,
        child: FoStatCard(
          label: 'Cut today',
          value: '1,290',
          onTap: () {},
        ),
      );

      expect(
        tester.getSemantics(find.byType(FoStatCard)).label,
        startsWith('Cut today: 1,290'),
      );
    });
  });

  group('FoDescriptionList', () {
    testWidgets('each pair is one announcement', (WidgetTester tester) async {
      await pumpFo(
        tester,
        surfaceSize: const Size(1280, 800),
        child: const FoDescriptionList(
          items: <FoDescriptionItem>[
            FoDescriptionItem(label: 'Line', value: Text('Line A')),
          ],
        ),
      );

      // Otherwise a screen reader reads "Line" and "Line A" as two unrelated
      // fragments several beats apart.
      expect(find.byType(MergeSemantics), findsOneWidget);
    });

    testWidgets('stacks on a narrow window', (WidgetTester tester) async {
      Future<double> heightAt(double width) async {
        await pumpFo(
          tester,
          surfaceSize: Size(width, 800),
          child: const FoDescriptionList(
            items: <FoDescriptionItem>[
              FoDescriptionItem(label: 'Line', value: Text('Line A')),
              FoDescriptionItem(label: 'Shift', value: Text('Morning')),
            ],
          ),
        );
        return tester.getSize(find.byType(FoDescriptionList)).height;
      }

      // Two columns at a phone's width gives the value ~40% of the line, so
      // anything longer than a date wraps beside a one-line label.
      expect(await heightAt(420), greaterThan(await heightAt(1280)));
    });
  });

  group('FoPageHeader', () {
    testWidgets('the title is the page-level scale and a header', (
      WidgetTester tester,
    ) async {
      await pumpFo(
        tester,
        surfaceSize: const Size(1280, 800),
        child: const FoPageHeader(
          eyebrow: 'Production',
          title: 'Cut entries',
          lede: 'Everything logged today.',
        ),
      );

      final Text title = tester.widget<Text>(find.text('Cut entries'));
      expect(title.style!.fontSize, FoTokens.fontDisplay);
      expect(find.text('PRODUCTION'), findsOneWidget);
      expect(
        tester.getSemantics(find.text('Cut entries')),
        isSemantics(isHeader: true, label: 'Cut entries'),
      );
    });
  });

  group('FoBadge', () {
    testWidgets('a bare count gets a label that says what it counts', (
      WidgetTester tester,
    ) async {
      await pumpFo(
        tester,
        child: const FoBadge(
          label: '3',
          tone: FoStatusTone.danger,
          semanticLabel: '3 rejected',
        ),
      );

      // Without it a screen reader announces a bare number with nothing
      // attaching it to its subject.
      expect(tester.getSemantics(find.byType(FoBadge)).label, '3 rejected');
    });
  });

  group('FoThemeToggle', () {
    testWidgets('offers system, not just light and dark', (
      WidgetTester tester,
    ) async {
      ThemeMode? picked;
      await pumpFo(
        tester,
        surfaceSize: const Size(900, 400),
        child: FoThemeToggle(
          mode: ThemeMode.light,
          lightLabel: 'Light',
          darkLabel: 'Dark',
          systemLabel: 'System',
          onChanged: (ThemeMode m) => picked = m,
        ),
      );

      // A two-state toggle cannot express "follow the system" at all, and
      // defaulting to light silently overrides the platform's preference.
      expect(find.text('System'), findsOneWidget);
      await tester.tap(find.text('System'));
      await tester.pumpAndSettle();
      expect(picked, ThemeMode.system);
    });
  });
}

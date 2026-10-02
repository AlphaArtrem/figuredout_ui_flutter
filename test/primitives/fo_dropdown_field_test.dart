import 'package:figuredout_ui/figuredout_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/pump.dart';

/// One list, and a second that depends on it — the shape that found the bug.
class _DependentPickers extends StatefulWidget {
  const _DependentPickers();

  @override
  State<_DependentPickers> createState() => _DependentPickersState();
}

class _DependentPickersState extends State<_DependentPickers> {
  String? place;
  String? court;

  static const Map<String, List<String>> courts = <String, List<String>>{
    'Jaipur': <String>['MACT Jaipur', 'District Court Jaipur'],
    'Ajmer': <String>['MACT Ajmer'],
  };

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        FoDropdownField<String>(
          label: 'Place',
          value: place,
          items: courts.keys
              .map(
                (String k) =>
                    DropdownMenuItem<String>(value: k, child: Text(k)),
              )
              .toList(growable: false),
          onChanged: (String? next) => setState(() {
            place = next;
            // The line under test: a dependent value cleared from outside the
            // control it belongs to.
            court = null;
          }),
        ),
        FoDropdownField<String>(
          label: 'Court',
          value: court,
          items: (courts[place] ?? const <String>[])
              .map(
                (String k) =>
                    DropdownMenuItem<String>(value: k, child: Text(k)),
              )
              .toList(growable: false),
          onChanged: (String? next) => setState(() => court = next),
        ),
      ],
    );
  }
}

void main() {
  group('FoDropdownField is controlled', () {
    testWidgets('a value set from outside is shown', (
      WidgetTester tester,
    ) async {
      String? value;
      await pumpFo(
        tester,
        surfaceSize: const Size(1280, 800),
        child: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              FoDropdownField<String>(
                label: 'Line',
                value: value,
                items: const <DropdownMenuItem<String>>[
                  DropdownMenuItem<String>(value: 'A', child: Text('Line A')),
                  DropdownMenuItem<String>(value: 'B', child: Text('Line B')),
                ],
                onChanged: (String? next) => setState(() => value = next),
              ),
              TextButton(
                onPressed: () => setState(() => value = 'B'),
                child: const Text('choose for me'),
              ),
            ],
          ),
        ),
      );

      // Nothing picked, so the field is empty and the label has not floated.
      expect(find.text('Line B'), findsNothing);

      // The regression. This was built on `DropdownButtonFormField`, whose
      // `initialValue` a `FormField` seeds once — so a value set by anything
      // other than the user's own tap was dropped, in silence, and the field
      // went on showing the previous choice while the caller held the new one.
      await tester.tap(find.text('choose for me'));
      await tester.pumpAndSettle();
      expect(find.text('Line B'), findsOneWidget);
    });

    testWidgets('clearing a dependent picker clears what it shows', (
      WidgetTester tester,
    ) async {
      await pumpFo(
        tester,
        surfaceSize: const Size(1280, 800),
        child: const _DependentPickers(),
      );

      // Target `FoDropdownField`, not Material's internals: the label lives in
      // the `InputDecorator` and the menu in the `DropdownButton`, which are
      // siblings under our own widget rather than one inside the other. A
      // consuming test that reached for `DropdownButtonFormField` is what
      // v0.6.0's rewrite breaks, and this is what it should reach for instead.
      Future<void> pick(String label, String option) async {
        await tester.tap(
          find.ancestor(
            of: find.text(label),
            matching: find.byType(FoDropdownField<String>),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text(option).last);
        await tester.pumpAndSettle();
      }

      await pick('Place', 'Jaipur');
      await pick('Court', 'MACT Jaipur');
      expect(find.text('MACT Jaipur'), findsOneWidget);

      // Moving the parent clears the child. The field must stop showing a
      // court that is not in the place any more — on a form, the alternative
      // is a user pressing Save on two values they can see disagreeing.
      await pick('Place', 'Ajmer');
      expect(find.text('MACT Jaipur'), findsNothing);
    });

    testWidgets('a value with no option behind it renders empty, not a crash', (
      WidgetTester tester,
    ) async {
      await pumpFo(
        tester,
        child: FoDropdownField<String>(
          label: 'Line',
          // The state a refiltered list passes through for one frame.
          value: 'gone',
          items: const <DropdownMenuItem<String>>[
            DropdownMenuItem<String>(value: 'A', child: Text('Line A')),
          ],
          onChanged: (_) {},
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Line A'), findsNothing);
    });
  });

  /// Found by a consuming app's accessibility tour (legal_app traps §110).
  /// The field was an `isDense` `InputDecorator` around a `DropdownButton`, so
  /// the node that took the tap was one line of text — 24dp inside a field
  /// drawn 56dp tall — and with nothing chosen that node had no label at all.
  group('FoDropdownField tap target', () {
    Widget field({String? value, ValueChanged<String?>? onChanged}) => SizedBox(
          width: 320,
          child: FoDropdownField<String>(
            label: 'Period',
            value: value,
            items: const <DropdownMenuItem<String>>[
              DropdownMenuItem<String>(value: 'w', child: Text('This week')),
              DropdownMenuItem<String>(value: 'm', child: Text('This month')),
            ],
            onChanged: onChanged ?? (_) {},
          ),
        );

    for (final String? value in <String?>[null, 'm']) {
      final String state = value == null ? 'empty' : 'chosen';

      testWidgets('$state: the whole field is one labelled 48dp target', (
        WidgetTester tester,
      ) async {
        final SemanticsHandle handle = tester.ensureSemantics();
        await pumpFo(tester, child: field(value: value));

        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));

        final SemanticsNode node = tester.getSemantics(
          find.byType(FoDropdownField<String>),
        );
        expect(node.label, contains('Period'));
        expect(node.rect.height, greaterThanOrEqualTo(48));
        handle.dispose();
      });
    }

    testWidgets('a tap on the frame, off the text line, opens the menu once', (
      WidgetTester tester,
    ) async {
      String? picked;
      await pumpFo(
        tester,
        child: field(onChanged: (String? next) => picked = next),
      );

      final Rect frame = tester.getRect(find.byType(FoDropdownField<String>));
      // Just inside the bottom edge: below the button's own line of text.
      await tester.tapAt(Offset(frame.center.dx, frame.bottom - 4));
      await tester.pumpAndSettle();

      expect(
        find.byWidgetPredicate(
          (Widget w) => w.runtimeType.toString().startsWith('_DropdownMenu<'),
        ),
        findsOneWidget,
      );
      await tester.tap(find.text('This week').last);
      await tester.pumpAndSettle();
      expect(picked, 'w');
    });

    testWidgets('a tap on the text line still opens exactly one menu', (
      WidgetTester tester,
    ) async {
      await pumpFo(tester, child: field(value: 'm'));

      await tester.tap(find.text('This month'));
      await tester.pumpAndSettle();

      expect(
        find.byWidgetPredicate(
          (Widget w) => w.runtimeType.toString().startsWith('_DropdownMenu<'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('a disabled field opens nothing', (WidgetTester tester) async {
      await pumpFo(
        tester,
        child: const SizedBox(
          width: 320,
          child: FoDropdownField<String>(
            label: 'Period',
            items: <DropdownMenuItem<String>>[
              DropdownMenuItem<String>(value: 'w', child: Text('This week')),
            ],
            onChanged: null,
          ),
        ),
      );

      final Rect frame = tester.getRect(find.byType(FoDropdownField<String>));
      await tester.tapAt(Offset(frame.center.dx, frame.bottom - 4));
      await tester.pumpAndSettle();
      expect(
        find.byWidgetPredicate(
          (Widget w) => w.runtimeType.toString().startsWith('_DropdownMenu<'),
        ),
        findsNothing,
      );
    });
  });
}

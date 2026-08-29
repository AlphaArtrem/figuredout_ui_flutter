import 'package:figuredout_ui/figuredout_ui.dart';
import 'package:flutter/material.dart';
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
}

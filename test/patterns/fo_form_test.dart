import 'package:figuredout_ui/figuredout_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/pump.dart';

void main() {
  group('FoFormActions hoisting', () {
    testWidgets('inside a surface, the row moves to the pinned footer', (
      WidgetTester tester,
    ) async {
      await pumpFo(
        tester,
        surfaceSize: const Size(1280, 800),
        child: FoFormSurface(
          title: 'New entry',
          child: Column(
            children: <Widget>[
              const FoTextField(label: 'Quantity'),
              FoFormActions(
                actions: <FoFormAction>[
                  FoFormAction(
                    label: 'Save',
                    variant: FoButtonVariant.primary,
                    onPressed: () {},
                  ),
                ],
              ),
            ],
          ),
        ),
      );
      await tester.pump();

      // The point of the hoist: on a long form the action would otherwise sit
      // below the fold, inside the scroll view, exactly when the user wants it.
      final Finder scrollView = find.byType(SingleChildScrollView);
      expect(scrollView, findsOneWidget);
      expect(
        find.descendant(of: scrollView, matching: find.text('Save')),
        findsNothing,
        reason: 'the action must have left the scrolling body',
      );
      expect(find.text('Save'), findsOneWidget);
    });

    testWidgets('outside a surface it renders where it was declared', (
      WidgetTester tester,
    ) async {
      await pumpFo(
        tester,
        child: FoFormActions(
          actions: <FoFormAction>[
            FoFormAction(
              label: 'Save',
              variant: FoButtonVariant.primary,
              onPressed: () {},
            ),
          ],
        ),
      );

      // A full-page form has no surface to hoist into, and the row must not
      // simply vanish.
      expect(find.text('Save'), findsOneWidget);
    });

    testWidgets('a second row renders inline rather than fighting for the slot',
        (
      WidgetTester tester,
    ) async {
      await pumpFo(
        tester,
        surfaceSize: const Size(1280, 800),
        child: FoFormSurface(
          title: 'New entry',
          child: Column(
            children: <Widget>[
              FoFormActions(
                actions: <FoFormAction>[
                  FoFormAction(
                    label: 'First',
                    variant: FoButtonVariant.primary,
                    onPressed: () {},
                  ),
                ],
              ),
              FoFormActions(
                actions: <FoFormAction>[
                  FoFormAction(
                    label: 'Second',
                    variant: FoButtonVariant.secondary,
                    onPressed: () {},
                  ),
                ],
              ),
            ],
          ),
        ),
      );
      await tester.pump();

      // Losing the fight would make a whole action row disappear, and a form
      // with an invisible Save is worse than one with two rows.
      expect(find.text('First'), findsOneWidget);
      expect(find.text('Second'), findsOneWidget);
    });
  });

  group('the dirty-form hook', () {
    testWidgets('typing in a FoTextField marks the surface dirty', (
      WidgetTester tester,
    ) async {
      final FoFormController controller = FoFormController();
      addTearDown(controller.dispose);

      await pumpFo(
        tester,
        surfaceSize: const Size(1280, 800),
        child: FoFormSurface(
          title: 'New entry',
          controller: controller,
          child: const FoTextField(label: 'Quantity'),
        ),
      );

      expect(controller.dirty.value, isFalse);
      await tester.enterText(find.byType(TextField), '12');
      // A form gets the guard without opting in, which matters because the
      // forms that most need it are the ones nobody remembered to wire up.
      expect(controller.dirty.value, isTrue);
    });

    testWidgets('picking a dropdown value marks the surface dirty', (
      WidgetTester tester,
    ) async {
      final FoFormController controller = FoFormController();
      addTearDown(controller.dispose);

      await pumpFo(
        tester,
        surfaceSize: const Size(1280, 800),
        child: FoFormSurface(
          title: 'New entry',
          controller: controller,
          child: FoDropdownField<String>(
            label: 'Line',
            items: const <DropdownMenuItem<String>>[
              DropdownMenuItem<String>(value: 'A', child: Text('Line A')),
              DropdownMenuItem<String>(value: 'B', child: Text('Line B')),
            ],
            onChanged: (_) {},
          ),
        ),
      );

      expect(controller.dirty.value, isFalse);
      await tester.tap(find.byType(DropdownButton<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Line B').last);
      await tester.pumpAndSettle();
      expect(controller.dirty.value, isTrue);
    });

    testWidgets('markDirty outside a surface is a harmless no-op', (
      WidgetTester tester,
    ) async {
      await pumpFo(tester, child: const FoTextField(label: 'Quantity'));
      await tester.enterText(find.byType(TextField), '12');
      expect(tester.takeException(), isNull);
    });
  });

  group('FoFormSurface', () {
    testWidgets('sits on the raised step — a presented form covers the page', (
      WidgetTester tester,
    ) async {
      await pumpFo(
        tester,
        surfaceSize: const Size(1280, 800),
        child: const FoFormSurface(title: 'New entry', child: Text('Body')),
      );

      expect(
        tester.widget<FoCard>(find.byType(FoCard)).tone,
        FoCardTone.raised,
      );
    });

    testWidgets('scrollable: false lets the body own its bounds', (
      WidgetTester tester,
    ) async {
      await pumpFo(
        tester,
        surfaceSize: const Size(1280, 800),
        child: const FoFormSurface(
          title: 'Pick one',
          scrollable: false,
          child: Text('A list that sizes itself'),
        ),
      );

      // A body that measures itself against the surface's bounded height
      // cannot live inside a scroll view — it would get infinite height.
      expect(find.byType(SingleChildScrollView), findsNothing);
    });
  });

  group('FoFormValidation', () {
    testWidgets('a valid form submits and says nothing', (
      WidgetTester tester,
    ) async {
      final GlobalKey<FormState> formKey = GlobalKey<FormState>();
      late bool result;

      await pumpFo(
        tester,
        child: Form(
          key: formKey,
          child: Builder(
            builder: (BuildContext context) => Column(
              children: <Widget>[
                const FoTextField(label: 'Quantity'),
                FoButton(
                  label: 'Submit',
                  variant: FoButtonVariant.primary,
                  onPressed: () {
                    result = FoFormValidation.validate(
                      context,
                      formKey,
                      message: 'Fix the highlighted fields.',
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      );

      await tester.tap(find.text('Submit'));
      await tester.pump();
      expect(result, isTrue);
      expect(find.text('Fix the highlighted fields.'), findsNothing);
    });

    testWidgets('an invalid form is blocked and toasts once', (
      WidgetTester tester,
    ) async {
      final GlobalKey<FormState> formKey = GlobalKey<FormState>();
      late bool result;

      await pumpFo(
        tester,
        child: Form(
          key: formKey,
          child: Builder(
            builder: (BuildContext context) => Column(
              children: <Widget>[
                FoTextField(
                  label: 'Quantity',
                  isRequired: true,
                  validator: (String? v) =>
                      (v ?? '').isEmpty ? 'Enter a quantity.' : null,
                ),
                FoButton(
                  label: 'Submit',
                  variant: FoButtonVariant.primary,
                  onPressed: () {
                    result = FoFormValidation.validate(
                      context,
                      formKey,
                      message: 'Fix the highlighted fields.',
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      );

      await tester.tap(find.text('Submit'));
      await tester.pump();

      expect(result, isFalse);
      // One standard toast everywhere, so Save never just looks dead.
      expect(find.text('Fix the highlighted fields.'), findsOneWidget);
      expect(find.text('Enter a quantity.'), findsOneWidget);
    });
  });
}

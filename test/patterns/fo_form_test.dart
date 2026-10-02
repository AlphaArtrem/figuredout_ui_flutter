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

    for (final double scale in <double>[1, 3]) {
      testWidgets('a list body is given a bounded height at ${scale}x text', (
        WidgetTester tester,
      ) async {
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        await pumpFo(
          tester,
          surfaceSize: const Size(390, 600),
          child: SizedBox(
            height: 560,
            child: FoFormSurface(
              title: 'Pick a matter from the list below',
              subtitle: 'Only matters you can see are listed here.',
              scrollable: false,
              child: ListView(
                children: <Widget>[
                  for (int i = 0; i < 40; i++) Text('Matter $i'),
                ],
              ),
            ),
          ),
        );

        expect(tester.takeException(), isNull);
        final double listHeight = tester.getSize(find.byType(ListView)).height;
        expect(listHeight, greaterThan(0));
        expect(listHeight.isFinite, isTrue);
      });
    }

    /// Found by a consuming app's accessibility tour (legal_app traps §110):
    /// at 300% text on a phone the header and the pinned footer alone were
    /// taller than the sheet, the column overflowed by up to 287 points, and
    /// the invite sheet's own "Send invitation" was below the screen's edge.
    for (final (String name, Size size, double scale)
        in <(String, Size, double)>[
      ('a phone at 300% text', const Size(390, 844), 3),
      ('a phone on its side at 200% text', const Size(844, 390), 2),
      ('a 300% browser zoom window', const Size(427, 237), 1),
    ]) {
      testWidgets('presented on $name, nothing overflows and Send is reachable',
          (WidgetTester tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

        int sent = 0;
        await tester.pumpWidget(
          MaterialApp(
            theme: FoTheme.light(),
            home: Scaffold(
              body: Builder(
                builder: (BuildContext context) => TextButton(
                  onPressed: () => FoFormPresenter.show<void>(
                    context,
                    title: 'Invite a member',
                    subtitle: 'They get an email with a link that works once '
                        'and expires in seven days.',
                    discardCopy: const FoDiscardCopy(
                      title: 'Discard?',
                      message: 'The address you typed is lost.',
                      confirmLabel: 'Discard',
                      cancelLabel: 'Keep editing',
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        const FoTextField(
                          label: 'Email',
                          helperText: 'Their work address.',
                        ),
                        FoFormActions(
                          actions: <FoFormAction>[
                            FoFormAction(
                              label: 'Cancel',
                              variant: FoButtonVariant.tertiary,
                              onPressed: () {},
                            ),
                            FoFormAction(
                              label: 'Send invitation',
                              variant: FoButtonVariant.primary,
                              onPressed: () => sent++,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        // Reachable: on screen once scrolled to, and the tap lands on it.
        final Finder send = find.text('Send invitation');
        await tester.ensureVisible(send);
        await tester.pumpAndSettle();
        final Rect rect = tester.getRect(send);
        expect(rect.bottom, lessThanOrEqualTo(size.height));
        expect(rect.top, greaterThanOrEqualTo(0));
        await tester.tap(send);
        expect(sent, 1);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets(
        'a form that fits keeps its footer pinned under a scrolling body',
        (WidgetTester tester) async {
      await pumpFo(
        tester,
        surfaceSize: const Size(390, 600),
        child: SizedBox(
          height: 500,
          child: FoFormSurface(
            title: 'New entry',
            child: Column(
              children: <Widget>[
                for (int i = 0; i < 12; i++) FoTextField(label: 'Field $i'),
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
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);

      // The footer is outside the scrolling body and stays put when it scrolls.
      final Finder body = find.byType(SingleChildScrollView);
      expect(body, findsOneWidget);
      expect(
        find.descendant(of: body, matching: find.text('Save')),
        findsNothing,
      );
      final double before = tester.getRect(find.text('Save')).top;
      await tester.drag(body, const Offset(0, -300));
      await tester.pump();
      expect(tester.getRect(find.text('Save')).top, before);
      expect(find.text('New entry'), findsOneWidget);
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

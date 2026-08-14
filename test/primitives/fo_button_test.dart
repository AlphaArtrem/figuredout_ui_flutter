import 'package:figuredout_ui/figuredout_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/pump.dart';

void main() {
  group('FoButton', () {
    /// G4. The web package learned this one the hard way: `primaryFg` in dark
    /// mode is a near-black green, and on a light red it is unreadable. Luxe's
    /// original used `surface` as the destructive foreground, which fails the
    /// same way for the same reason.
    // One test per theme rather than a loop: MaterialApp animates a theme
    // change, so a second pump inside one test still reads the old ThemeData.
    for (final bool isDark in <bool>[false, true]) {
      final String theme = isDark ? 'dark' : 'light';
      testWidgets(
          'destructive writes in dangerFg, never primaryFg or '
          'surface ($theme)', (WidgetTester tester) async {
        final FoColors colors = isDark ? FoColors.dark : FoColors.light;
        await pumpFo(
          tester,
          isDark: isDark,
          child: FoButton(
            label: 'Delete',
            variant: FoButtonVariant.destructive,
            onPressed: () {},
          ),
        );

        final ButtonStyle style =
            tester.widget<FilledButton>(find.byType(FilledButton)).style!;
        final Color? ink = style.foregroundColor!.resolve(<WidgetState>{});

        expect(ink, colors.dangerFg);
        expect(style.backgroundColor!.resolve(<WidgetState>{}), colors.danger);
        expect(ink, isNot(colors.primaryFg));
        expect(ink, isNot(colors.surface));
      });
    }

    test('every variant has a foreground that is not its own background', () {
      // A variant whose ink matches its fill is invisible. Cheap to state,
      // and it is the failure a careless palette edit produces.
      for (final FoColors colors in <FoColors>[
        FoColors.light,
        FoColors.dark,
      ]) {
        expect(colors.primaryFg, isNot(colors.primary));
        expect(colors.dangerFg, isNot(colors.danger));
        expect(colors.accentFg, isNot(colors.accent));
      }
    });

    testWidgets('isLoading disables the button and shows a spinner', (
      WidgetTester tester,
    ) async {
      int taps = 0;
      await pumpFo(
        tester,
        child: FoButton(
          label: 'Save',
          variant: FoButtonVariant.primary,
          isLoading: true,
          onPressed: () => taps++,
        ),
      );

      expect(find.byType(FoSpinner), findsOneWidget);
      await tester.tap(find.byType(FilledButton));
      expect(taps, 0, reason: 'a loading button must not fire again');
    });

    testWidgets('the loading spinner takes the button\'s own ink', (
      WidgetTester tester,
    ) async {
      await pumpFo(
        tester,
        child: FoButton(
          label: 'Delete',
          variant: FoButtonVariant.destructive,
          isLoading: true,
          onPressed: () {},
        ),
      );

      // A spinner in the page's primary would vanish on a red fill.
      final FoSpinner spinner = tester.widget<FoSpinner>(
        find.byType(FoSpinner),
      );
      expect(spinner.color, FoColors.light.dangerFg);
    });

    testWidgets('every variant paints flat — elevation is FoShadows\' job', (
      WidgetTester tester,
    ) async {
      for (final FoButtonVariant variant in FoButtonVariant.values) {
        await pumpFo(
          tester,
          child: FoButton(
            label: 'Go',
            variant: variant,
            onPressed: () {},
          ),
        );
        // byType cannot match the abstract ButtonStyleButton, and each
        // variant renders a different concrete subclass.
        final ButtonStyleButton button = tester.widget<ButtonStyleButton>(
          find.byWidgetPredicate((Widget w) => w is ButtonStyleButton),
        );
        final ButtonStyle style = button.style!;
        expect(
          style.elevation!.resolve(<WidgetState>{}),
          0,
          reason: '$variant must not use Material elevation',
        );
      }
    });

    testWidgets('meets the shop-floor touch target', (
      WidgetTester tester,
    ) async {
      await pumpFo(
        tester,
        child: FoButton(
          label: 'Go',
          variant: FoButtonVariant.primary,
          onPressed: () {},
        ),
      );
      expect(
        tester.getSize(find.byType(FilledButton)).height,
        greaterThanOrEqualTo(FoLayout.minTouchTarget),
      );
    });

    testWidgets('composes the one focus treatment', (
      WidgetTester tester,
    ) async {
      await pumpFo(
        tester,
        child: FoButton(
          label: 'Go',
          variant: FoButtonVariant.primary,
          onPressed: () {},
        ),
      );
      expect(find.byType(FoFocusRing), findsOneWidget);
    });

    testWidgets('a disabled button gets no focus ring', (
      WidgetTester tester,
    ) async {
      await pumpFo(
        tester,
        child: const FoButton(
          label: 'Go',
          variant: FoButtonVariant.primary,
          onPressed: null,
        ),
      );
      expect(
        tester.widget<FoFocusRing>(find.byType(FoFocusRing)).enabled,
        isFalse,
      );
    });
  });

  testWidgets('a loading button keeps its width, so a row does not reflow', (
    WidgetTester tester,
  ) async {
    Future<double> widthWhen({required bool isLoading}) async {
      await pumpFo(
        tester,
        child: FoButton(
          label: 'Save entry',
          variant: FoButtonVariant.primary,
          isLoading: isLoading,
          onPressed: () {},
        ),
      );
      return tester.getSize(find.byType(FilledButton)).width;
    }

    // Swapping the label for a bare spinner shrinks the button to
    // spinner-width, reflowing every other action in the row at the exact
    // moment the user is watching to see whether their tap took.
    expect(await widthWhen(isLoading: true), await widthWhen(isLoading: false));
  });

  group('FoActionButton / FoLoadingButton', () {
    testWidgets('both are primary, and neither can be styled otherwise', (
      WidgetTester tester,
    ) async {
      await pumpFo(
        tester,
        child: Column(
          children: <Widget>[
            FoActionButton(label: 'New', onPressed: () {}),
            FoLoadingButton(label: 'Save', onPressed: () {}),
          ],
        ),
      );

      final Iterable<FoButton> buttons = tester.widgetList<FoButton>(
        find.byType(FoButton),
      );
      expect(buttons, hasLength(2));
      for (final FoButton button in buttons) {
        expect(button.variant, FoButtonVariant.primary);
      }
    });
  });
}

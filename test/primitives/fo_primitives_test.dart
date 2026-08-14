import 'package:figuredout_ui/figuredout_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/pump.dart';

void main() {
  group('FoStatusChip', () {
    testWidgets('a toned chip grounds its ink on the matching -soft token', (
      WidgetTester tester,
    ) async {
      await pumpFo(
        tester,
        child: const FoStatusChip.tone(
          label: 'Submitted',
          tone: FoStatusTone.success,
        ),
      );

      final Container chip = tester.widget<Container>(find.byType(Container));
      expect(
        (chip.decoration! as BoxDecoration).color,
        FoColors.light.successSoft,
        reason: 'the -soft tokens are the grounds contrast_test measures; '
            'deriving one instead silently leaves the pairing unmeasured',
      );
      expect(
        tester.widget<Text>(find.text('Submitted')).style!.color,
        FoColors.light.success,
      );
    });

    testWidgets('an untoned chip derives its ground at the wash alpha', (
      WidgetTester tester,
    ) async {
      const Color accent = Color(0xFF123456);
      await pumpFo(
        tester,
        child: const FoStatusChip(label: 'Custom', color: accent),
      );

      final Container chip = tester.widget<Container>(find.byType(Container));
      expect(
        (chip.decoration! as BoxDecoration).color!.a,
        closeTo(FoTokens.softWashAlpha, 0.01),
      );
    });

    testWidgets('the prefix gives the status a subject', (
      WidgetTester tester,
    ) async {
      await pumpFo(
        tester,
        child: const FoStatusChip.tone(
          label: 'Submitted',
          tone: FoStatusTone.success,
          semanticPrefix: 'Status',
        ),
      );
      // Without this a screen reader announces a bare "Submitted" and the
      // user has to infer what was submitted.
      expect(
        tester.getSemantics(find.byType(FoStatusChip)).label,
        'Status: Submitted',
      );
    });
  });

  group('FoBooleanCell', () {
    testWidgets('shows a mark but announces the word', (
      WidgetTester tester,
    ) async {
      await pumpFo(
        tester,
        child: const FoBooleanCell(
          value: true,
          yesLabel: 'Yes',
          noLabel: 'No',
          label: 'Active',
        ),
      );

      expect(find.byIcon(Icons.check), findsOneWidget);
      expect(find.text('Yes'), findsNothing);
      expect(
        tester.getSemantics(find.byType(FoBooleanCell)).label,
        'Active: Yes',
      );
    });

    testWidgets('false is muted, not danger — it is not a failure', (
      WidgetTester tester,
    ) async {
      await pumpFo(
        tester,
        child: const FoBooleanCell(
          value: false,
          yesLabel: 'Yes',
          noLabel: 'No',
        ),
      );

      final Icon icon = tester.widget<Icon>(find.byType(Icon));
      expect(icon.color, FoColors.light.fgMuted);
      expect(icon.color, isNot(FoColors.light.danger));
    });
  });

  group('FoSkeleton', () {
    testWidgets('fills with the sunken step — it is a hole, not a card', (
      WidgetTester tester,
    ) async {
      await pumpFo(tester, child: const FoSkeleton.line(width: 100));
      await tester.pump();

      final Container box = tester.widget<Container>(find.byType(Container));
      expect(
        (box.decoration! as BoxDecoration).color,
        FoColors.light.surfaceSunken,
      );
    });

    testWidgets('freezes when the platform asks for reduced motion', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: FoTheme.light(),
          home: const MediaQuery(
            data: MediaQueryData(disableAnimations: true),
            child: Scaffold(body: FoSkeleton.line(width: 100)),
          ),
        ),
      );

      // pumpAndSettle would hang on a repeating animation, so a frozen
      // skeleton settling at all is itself the assertion.
      await tester.pumpAndSettle();
      final FadeTransition fade = tester.widget<FadeTransition>(
        find.descendant(
          of: find.byType(FoSkeleton),
          matching: find.byType(FadeTransition),
        ),
      );
      expect(fade.opacity.value, FoTokens.skeletonPulseStill);
    });

    testWidgets('a list spaces its rows without a trailing gap', (
      WidgetTester tester,
    ) async {
      await pumpFo(tester, child: const FoSkeletonList(itemCount: 3));
      await tester.pump();

      expect(find.byType(FoSkeleton), findsNWidgets(3));
      expect(find.byType(SizedBox), findsNWidgets(2));
    });
  });

  group('FoHint', () {
    testWidgets('a compact window routes the message to the tap handler', (
      WidgetTester tester,
    ) async {
      int taps = 0;
      await pumpFo(
        tester,
        surfaceSize: const Size(480, 800),
        child: FoHint(
          message: 'The quantity cut before any rejection.',
          buttonLabel: 'What is this?',
          onCompactTap: () => taps++,
        ),
      );

      // No pointer to hover with, so the tooltip is not the affordance.
      expect(find.byType(Tooltip), findsOneWidget); // IconButton's own
      await tester.tap(find.byType(IconButton));
      expect(taps, 1);
    });

    testWidgets('a wide window wraps the dot in a hover tooltip', (
      WidgetTester tester,
    ) async {
      await pumpFo(
        tester,
        surfaceSize: const Size(1280, 800),
        child: const FoHint(
          message: 'The quantity cut before any rejection.',
          buttonLabel: 'What is this?',
        ),
      );

      final Iterable<Tooltip> tooltips = tester.widgetList<Tooltip>(
        find.byType(Tooltip),
      );
      expect(
        tooltips.map((Tooltip t) => t.message),
        contains('The quantity cut before any rejection.'),
      );
    });

    testWidgets('the dot is a full touch target', (WidgetTester tester) async {
      await pumpFo(
        tester,
        child: const FoHint(message: 'Why', buttonLabel: 'What is this?'),
      );
      expect(
        tester.getSize(find.byType(IconButton)).height,
        FoLayout.minTouchTarget,
      );
    });
  });

  group('FoSectionHeader', () {
    testWidgets('the title is a header, so it can be jumped to', (
      WidgetTester tester,
    ) async {
      await pumpFo(tester, child: const FoSectionHeader(title: 'Cut entries'));
      expect(
        tester.getSemantics(find.text('Cut entries')),
        isSemantics(isHeader: true, label: 'Cut entries'),
      );
    });

    testWidgets('the trailing action stacks when the header is narrow', (
      WidgetTester tester,
    ) async {
      Future<void> pumpAt(double width) => pumpFo(
            tester,
            child: SizedBox(
              width: width,
              child: FoSectionHeader(
                title: 'Cut entries',
                trailing: FoActionButton(label: 'New', onPressed: () {}),
              ),
            ),
          );

      // Measured against the header's own width, not the window's: a header
      // in a half-width panel needs to stack for the same reason a phone does.
      await pumpAt(400);
      expect(find.byType(Column), findsWidgets);
      final double stackedHeight =
          tester.getSize(find.byType(FoSectionHeader)).height;

      await pumpAt(900);
      final double inlineHeight =
          tester.getSize(find.byType(FoSectionHeader)).height;

      expect(stackedHeight, greaterThan(inlineHeight));
    });
  });

  group('FoSectionSurface', () {
    testWidgets('is a FoCard, so its hairline survives a banded child', (
      WidgetTester tester,
    ) async {
      await pumpFo(
        tester,
        child: const FoSectionSurface(
          title: 'Cut entries',
          child: Text('Rows'),
        ),
      );

      // The whole reason this is not a Material Card — see fo_card_test.
      expect(find.byType(FoCard), findsOneWidget);
      expect(find.byType(Card), findsNothing);
      expect(
        tester.widget<FoCard>(find.byType(FoCard)).padding,
        EdgeInsets.zero,
        reason: 'the content of a framed section reaches the edges',
      );
    });

    testWidgets('renders no header chrome when it has no header', (
      WidgetTester tester,
    ) async {
      await pumpFo(
        tester,
        child: const FoSectionSurface(child: Text('Rows')),
      );
      expect(find.byType(FoSectionHeader), findsNothing);
      expect(find.byType(Divider), findsNothing);
    });
  });

  group('FoSpinner', () {
    testWidgets('takes the theme ink by default and an override when given', (
      WidgetTester tester,
    ) async {
      await pumpFo(
        tester,
        child: const Column(
          children: <Widget>[
            FoSpinner(),
            FoSpinner(size: FoSpinnerSize.medium, color: Color(0xFF123456)),
          ],
        ),
      );

      final List<CircularProgressIndicator> indicators = tester
          .widgetList<CircularProgressIndicator>(
            find.byType(CircularProgressIndicator),
          )
          .toList();
      expect(indicators.first.color, FoColors.light.primary);
      expect(indicators.last.color, const Color(0xFF123456));
    });
  });

  group('foOverlaySurface', () {
    testWidgets('is the raised step, the overlay shadow and a hairline', (
      WidgetTester tester,
    ) async {
      late BoxDecoration decoration;
      await pumpFo(
        tester,
        child: Builder(
          builder: (BuildContext context) {
            decoration = foOverlaySurface(context);
            return const SizedBox.shrink();
          },
        ),
      );

      expect(decoration.color, FoColors.light.surfaceRaised);
      expect(decoration.boxShadow, FoShadows.light.overlay);
      expect(decoration.border, isNotNull);
    });
  });
}

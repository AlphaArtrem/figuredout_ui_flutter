import 'package:figuredout_ui/figuredout_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/pump.dart';

void main() {
  Future<void> pumpCell(WidgetTester tester, double width) => pumpFo(
        tester,
        surfaceSize: const Size(1280, 400),
        child: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: width,
            child: const FoCellText(
              'CUTPLAN-0123',
              mono: true,
              secondary: 'LAY-13 · 1 Oct, 08:30',
            ),
          ),
        ),
      );

  testWidgets('at 300 px the code is drawn whole and the rest gives way', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    await pumpCell(tester, 300);

    final RenderParagraph code = tester.renderObject<RenderParagraph>(
      find.text('CUTPLAN-0123', findRichText: true),
    );
    expect(code.didExceedMaxLines, isFalse);
    expect(code.size.width, lessThanOrEqualTo(300));
    final RenderParagraph rest = tester.renderObject<RenderParagraph>(
      find.textContaining('LAY-13', findRichText: true),
    );
    expect(rest.didExceedMaxLines, isTrue, reason: 'the secondary is cut');
    expect(
      find.byTooltip('CUTPLAN-0123 · LAY-13 · 1 Oct, 08:30'),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel('CUTPLAN-0123 · LAY-13 · 1 Oct, 08:30'),
      findsOneWidget,
    );
    handle.dispose();
  });

  testWidgets('at 1000 px it is the one line it always was', (
    WidgetTester tester,
  ) async {
    await pumpCell(tester, 1000);

    final Finder text = find.descendant(
      of: find.byType(FoCellText),
      matching: find.byType(RichText),
    );
    expect(text, findsOneWidget);
    expect(
      tester.widget<RichText>(text).text.toPlainText(),
      'CUTPLAN-0123 · LAY-13 · 1 Oct, 08:30',
    );
  });

  testWidgets('when even the code does not fit it is cut as before', (
    WidgetTester tester,
  ) async {
    await pumpCell(tester, 60);

    expect(
      find.descendant(
        of: find.byType(FoCellText),
        matching: find.byType(RichText),
      ),
      findsOneWidget,
    );
  });

  testWidgets('without a secondary it is the primary alone', (
    WidgetTester tester,
  ) async {
    await pumpFo(tester, child: const FoCellText('Crew neck tee'));

    expect(find.text('Crew neck tee'), findsOneWidget);
    expect(find.byTooltip('Crew neck tee'), findsOneWidget);
  });
}

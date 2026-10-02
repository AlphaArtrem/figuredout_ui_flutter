import 'package:flutter/material.dart';

import '../theme/fo_context.dart';
import '../tokens/fo_tokens.dart';

/// What will come out of the printer, before it does: a carton label, a page
/// of bundle tickets.
///
/// The frame, not the artwork. The label itself is the app's [child] — a
/// carton's barcode and contents are the app's business — drawn on white
/// "paper" with a hairline and a lifted shadow, centred on the page's ground,
/// under a [title] and its [spec] ("100 × 150 mm · 1 per carton"). [actions]
/// print it. The paper is one image to a screen reader, named by
/// [semanticLabel] ("Label for carton CTN-121").
class FoPrintPreview extends StatelessWidget {
  /// Creates a print preview.
  const FoPrintPreview({
    required this.title,
    required this.semanticLabel,
    required this.child,
    this.spec,
    this.actions = const <Widget>[],
    this.helperText,
    this.maxPaperWidth = 300,
    super.key,
  });

  /// "Label preview". Caller-supplied.
  final String title;

  /// "100 × 150 mm · 1 per carton".
  final String? spec;

  /// What the paper shows, read aloud.
  final String semanticLabel;

  /// The artwork, or a grid of tickets.
  final Widget child;

  /// Print, PDF.
  final List<Widget> actions;

  /// A line under the actions.
  final String? helperText;

  /// The widest the paper is drawn.
  final double maxPaperWidth;

  @override
  Widget build(BuildContext context) {
    final BorderRadius radius = BorderRadius.circular(context.foRadii.card);
    final BorderRadius paper = BorderRadius.circular(context.foRadii.sm);
    return Container(
      padding: EdgeInsets.all(context.foSpacing.lg),
      decoration:
          BoxDecoration(color: context.foColors.bg, borderRadius: radius),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            spacing: context.foSpacing.sm,
            children: <Widget>[
              Semantics(
                header: true,
                child: Text(title, style: context.foText.subtitle),
              ),
              if (spec != null)
                Text(
                  spec!,
                  style: context.foText.body.copyWith(
                    fontSize: FoTokens.fontCaption,
                    color: context.foColors.fgSubtle,
                  ),
                ),
            ],
          ),
          SizedBox(height: context.foSpacing.md),
          Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxPaperWidth),
              child: Semantics(
                image: true,
                label: semanticLabel,
                excludeSemantics: true,
                child: Container(
                  decoration: BoxDecoration(
                    color: context.foColors.surfaceRaised,
                    borderRadius: paper,
                    boxShadow: context.foShadows.hover,
                  ),
                  foregroundDecoration: BoxDecoration(
                    borderRadius: paper,
                    border: Border.all(color: context.foColors.edgeStrong),
                  ),
                  child: ClipRRect(borderRadius: paper, child: child),
                ),
              ),
            ),
          ),
          if (actions.isNotEmpty) ...<Widget>[
            SizedBox(height: context.foSpacing.md),
            Wrap(
              spacing: context.foSpacing.sm,
              runSpacing: context.foSpacing.sm,
              children: actions,
            ),
          ],
          if (helperText != null) ...<Widget>[
            SizedBox(height: context.foSpacing.sm),
            Text(
              helperText!,
              style: context.foText.body.copyWith(
                fontSize: FoTokens.fontCaption,
                color: context.foColors.fgSubtle,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

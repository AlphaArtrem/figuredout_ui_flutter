import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'fo_tokens.dart';

/// The spacing scale, exposed via `context.foSpacing`. Constant across themes.
@immutable
class FoSpacing {
  /// Creates the spacing scale.
  const FoSpacing();

  /// 4dp — between a label and the thing it labels.
  double get xs => FoTokens.space4;

  /// 8dp — inside a control.
  double get sm => FoTokens.space8;

  /// 12dp — between controls in a row.
  double get md => FoTokens.space12;

  /// 16dp — a card's padding, a form's row gap.
  double get lg => FoTokens.space16;

  /// 24dp — between sections.
  double get xl => FoTokens.space24;

  /// 32dp — between page regions.
  double get xxl => FoTokens.space32;

  /// 48dp — around a page's own edges on a wide window.
  double get xxxl => FoTokens.space48;

  /// Every step, by name — the basis of the Widgetbook spacing-ruler use case.
  Map<String, double> toMap() => <String, double>{
        'xs': xs,
        'sm': sm,
        'md': md,
        'lg': lg,
        'xl': xl,
        'xxl': xxl,
        'xxxl': xxxl,
      };
}

/// The corner-radius scale, exposed via `context.foRadii`. Constant across
/// themes.
@immutable
class FoRadii {
  /// Creates the radius scale.
  const FoRadii();

  /// 4dp — a chip, a table cell's selected state.
  double get sm => FoTokens.radiusSmall;

  /// 8dp — a button, a field.
  double get md => FoTokens.radiusDefault;

  /// 12dp — a card, a dialog.
  double get card => FoTokens.radiusCard;

  /// 16dp — a bottom sheet.
  double get lg => FoTokens.radiusLarge;

  /// Every step, by name.
  Map<String, double> toMap() => <String, double>{
        'sm': sm,
        'md': md,
        'card': card,
        'lg': lg,
      };
}

/// Page-level layout constants: the measure, the gutter, the touch floor and
/// the three window-class breakpoints.
///
/// The measure and gutter are ported from the web package, where every app
/// used to hardcode its own. The touch floor and field height are Luxe's:
/// these apps are used with a gloved finger on a shop floor.
abstract final class FoLayout {
  /// The widest a page's content column ever gets. Beyond this, add gutter,
  /// not line length.
  static const double measure = FoTokens.measure;

  /// The shop-floor minimum for anything tappable. Never shrink it for a
  /// denser desktop layout — the same build runs on the tablet.
  static const double minTouchTarget = FoTokens.minTouchTarget;

  /// The height of a single-line text or dropdown field.
  static const double singleLineFieldHeight = FoTokens.singleLineFieldHeight;

  /// The focus ring's width. One treatment, everywhere.
  static const double focusRingWidth = FoTokens.focusRingWidth;

  /// A hairline's width.
  static const double hairlineWidth = FoTokens.hairlineWidth;

  /// Upper bound of the compact band.
  static const double compactBreakpoint = FoTokens.compactBreakpoint;

  /// Lower bound of the expanded band.
  static const double expandedBreakpoint = FoTokens.expandedBreakpoint;

  /// The page's horizontal padding for a viewport [width], the Dart form of
  /// `--gut: clamp(1rem, 4vw, 2.5rem)`.
  static double gutter(double width) => math.min(
        FoTokens.gutterMax,
        math.max(FoTokens.gutterMin, width * FoTokens.gutterRatio),
      );
}

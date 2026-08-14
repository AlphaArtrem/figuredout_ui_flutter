import 'package:flutter/material.dart';

import '../tokens/fo_layout.dart';

/// The three layout bands, split on 600 and 900 logical pixels.
///
/// Three, not two: a tablet in portrait and a desktop window at half width
/// both land in [medium], which is wide enough for a two-column form but too
/// narrow for a sidebar alongside a table. Collapsing them loses that.
enum FoWindowClass {
  /// Below 600 — a phone.
  compact,

  /// 600 to 900 — a tablet, or a desktop window at half width.
  medium,

  /// 900 and up — a desktop window, or a tablet in landscape.
  expanded;

  /// The band for [width] logical pixels.
  static FoWindowClass forWidth(double width) {
    if (width < FoLayout.compactBreakpoint) return FoWindowClass.compact;
    if (width < FoLayout.expandedBreakpoint) return FoWindowClass.medium;
    return FoWindowClass.expanded;
  }

  /// The band for the nearest [MediaQuery]'s width.
  static FoWindowClass of(BuildContext context) =>
      forWidth(MediaQuery.sizeOf(context).width);

  /// True for anything that is not a phone — both [medium] and [expanded].
  ///
  /// Deliberately *not* "at least [expanded]". Call sites use this to choose
  /// two-column forms, wide tables and dialogs-over-sheets; narrowing it here
  /// would silently change all of them. Compare against [FoWindowClass.expanded]
  /// directly when you really do mean the top band.
  bool get isAtLeastMedium => this != FoWindowClass.compact;
}

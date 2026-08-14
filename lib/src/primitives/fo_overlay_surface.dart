import 'package:flutter/material.dart';

import '../theme/fo_context.dart';

/// The floating surface, stated once.
///
/// The analogue of the web package's `POPOVER_SURFACE`: a menu, a tooltip, a
/// toast, a popover and a dialog are all the same object — something lifted
/// off the page and covering what is behind it — so they get the same
/// treatment rather than each restating it slightly differently.
///
/// Three things together, and all three matter: `surfaceRaised` (the
/// top of the ladder, because that is what "covering something else" means),
/// `FoShadows.overlay`, and a hairline. Reach for this instead of assembling
/// a `BoxDecoration` in a new component.
///
/// ```dart
/// DecoratedBox(
///   decoration: foOverlaySurface(context),
///   child: menu,
/// )
/// ```
BoxDecoration foOverlaySurface(BuildContext context, {double? radius}) {
  return BoxDecoration(
    color: context.foColors.surfaceRaised,
    borderRadius: BorderRadius.circular(radius ?? context.foRadii.card),
    border: Border.all(color: context.foColors.edge),
    boxShadow: context.foShadows.overlay,
  );
}

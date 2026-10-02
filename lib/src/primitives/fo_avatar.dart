import 'package:flutter/material.dart';

import '../theme/fo_context.dart';

/// How big an avatar is.
enum FoAvatarSize {
  /// 28 — inline in a table row.
  small(28),

  /// 36 — a list row.
  medium(36),

  /// 44 — a card, a search result.
  large(44),

  /// 64 — a profile.
  xlarge(64);

  const FoAvatarSize(this.diameter);

  /// The circle's diameter.
  final double diameter;
}

/// A person, as their initials in a circle — "IS" for Imran Sheikh.
///
/// Initials rather than a photo: the floor's phones are shared, and nobody is
/// asked for a picture. The caller derives the [initials], because how a
/// name shortens is a question about the language the name is in, not about
/// layout. The circle reads as the person for a screen reader — [name] is
/// its label, and the letters themselves are hidden.
class FoAvatar extends StatelessWidget {
  /// Creates an avatar.
  const FoAvatar({
    required this.initials,
    required this.name,
    this.size = FoAvatarSize.medium,
    super.key,
  });

  /// One to three letters. Caller-supplied.
  final String initials;

  /// The person's name, read instead of the letters.
  final String name;

  /// How big it is.
  final FoAvatarSize size;

  @override
  Widget build(BuildContext context) {
    final double d = size.diameter;
    return Semantics(
      label: name,
      image: true,
      excludeSemantics: true,
      child: Center(
// A circle stays a circle under any constraints (see FoDisc).
        widthFactor: 1,
        heightFactor: 1,
        child: Container(
          width: d,
          height: d,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: context.foColors.primarySoft,
            shape: BoxShape.circle,
          ),
          child: Text(
            initials,
            maxLines: 1,
            // The text scales with the circle rather than with the reader's
            // text size: two letters in a fixed circle at 200% overflow it.
            textScaler: TextScaler.noScaling,
            style: context.foText.label.copyWith(
              color: context.foColors.primary,
              fontSize: d * 0.38,
            ),
          ),
        ),
      ),
    );
  }
}

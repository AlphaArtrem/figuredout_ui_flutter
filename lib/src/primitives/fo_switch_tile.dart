import 'package:flutter/material.dart';

import '../theme/fo_context.dart';
import '../tokens/fo_layout.dart';
import '../tokens/fo_tokens.dart';
import 'fo_card.dart';
import 'fo_status_chip.dart';

/// A row that carries one boolean: a title, an optional explanation, and a
/// switch.
///
/// The boolean *input* to `FoBooleanCell`'s output. Before this existed the
/// consuming apps each composed a [FoCard] with a Material [Switch], which is
/// the shape of a fork: same row, five call sites, no focus ring, and a
/// locked state each app had to invent for itself.
///
/// **The switch does not handle input; the card does.** The [Switch] here is a
/// rendering of [value] and nothing more — it sits inside an [IgnorePointer]
/// and an [ExcludeFocus], and the whole row is the tap target. Two reasons.
/// A switch inside a tappable card fires both handlers and toggles twice; and
/// a 48dp control at the end of a row is a small target for the thumb of
/// someone standing in a corridor, when the row itself is a large one.
/// [FoCard] brings the hover lift and the focus ring (rule 5) with it.
///
/// **A value that can never change is not a greyed switch.** Pass a [lock] and
/// the switch is replaced by a [FoStatusChip] carrying the caller's word. That
/// is not a stylistic choice: a *disabled* Material [Switch] that is **on**
/// paints a grey track with the thumb to the right, which at a glance reads as
/// off — a consuming app shipped five permissions labelled "always on" beside
/// a control that looked off, and only a live run on a phone caught it. A word
/// cannot be misread.
///
/// **[onChanged] of null is the other thing**, and the difference matters: it
/// means *not now* — a form that is saving, a screen the caller may read but
/// not edit — rather than *not ever*. The tile dims as a whole and the switch
/// keeps its on and off colours, because the misreading above comes from
/// Material greying both states into one, and dimming uniformly does not.
///
/// The component holds no copy. [title], [subtitle] and [FoSwitchTileLock] are
/// all caller-supplied so they can be localized.
class FoSwitchTile extends StatelessWidget {
  /// Creates a switch row.
  const FoSwitchTile({
    required this.value,
    required this.title,
    required this.onChanged,
    this.subtitle,
    this.semanticLabel,
    this.lock,
    super.key,
  });

  /// The current value.
  final bool value;

  /// What the switch is about. One line, sentence case.
  final String title;

  /// Called with the value the user is asking for — that is, `!value`.
  ///
  /// Null makes the row read-only *for now*: it dims and stops taking input.
  /// For a value that can never change, pass a [lock] instead, which says so
  /// in a word rather than leaving the user to work it out from a grey.
  final ValueChanged<bool>? onChanged;

  /// What turning it on actually does, in a sentence. Optional, but a switch
  /// whose title is not self-evident wants one.
  final String? subtitle;

  /// What a screen reader announces. Defaults to [title]; pass this when the
  /// title alone is ambiguous out of its section — "Required" in a list of
  /// fields, say.
  final String? semanticLabel;

  /// Why this value cannot be changed, and the word to show instead of the
  /// switch. Null for an ordinary row.
  final FoSwitchTileLock? lock;

  @override
  Widget build(BuildContext context) {
    final FoSwitchTileLock? lock = this.lock;
    final bool locked = lock != null;
    final bool interactive = !locked && onChanged != null;
    // Dimmed for "not now", never for "not ever" — a locked row is fully
    // legible, because it is telling the reader something.
    final bool dimmed = !locked && onChanged == null;

    final Widget content = ConstrainedBox(
      // The row is the tap target, so it owes the same floor a button does.
      constraints: const BoxConstraints(
        minHeight: FoLayout.minTouchTarget,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(title, style: context.foText.subtitle),
                if (subtitle != null) ...<Widget>[
                  SizedBox(height: context.foSpacing.xs),
                  Text(
                    subtitle!,
                    style: context.foText.body.copyWith(
                      color: context.foColors.fgMuted,
                    ),
                  ),
                ],
                if (lock?.reason != null) ...<Widget>[
                  SizedBox(height: context.foSpacing.xs),
                  Text(
                    // `body`, not `label`: rule 3 reserves the mono uppercase
                    // caption for naming a *value*, and this is a sentence.
                    lock!.reason!,
                    style: context.foText.body.copyWith(
                      color: context.foColors.fgMuted,
                    ),
                  ),
                ],
              ],
            ),
          ),
          SizedBox(width: context.foSpacing.md),
          if (locked)
            // **`Flexible`, because a chip's label is the caller's words at
            // the reader's text size.** A `Switch` is a fixed 60-odd points
            // and never grows; a chip grows with both, and at twice the system
            // text size *"Not available"* beside a title left the `Expanded`
            // with nothing and ran 38 points off the right. Constrained, the
            // chip's own `Text` wraps inside it — two lines of a readable
            // label rather than half of one off the edge of the screen.
            Flexible(
              child: FoStatusChip.tone(
                label: lock.label,
                // The chip carries the value as well as the lock: on is a
                // settled good state, off is simply how things are.
                tone: value ? FoStatusTone.success : FoStatusTone.neutral,
              ),
            )
          else
            // Never handed a null onChanged. Material greys an off *and* an on
            // switch to the same track when disabled, which is the misreading
            // this component exists to avoid; the tile's own dimming below
            // says "not now" without destroying the on/off difference.
            ExcludeFocus(
              child: IgnorePointer(
                child: Switch(value: value, onChanged: (_) {}),
              ),
            ),
        ],
      ),
    );

    final Widget card = FoCard(
      onTap: interactive ? () => onChanged!(!value) : null,
      child: dimmed
          ? Opacity(opacity: FoTokens.disabledInkOpacity, child: content)
          : content,
    );

    return Semantics(
      container: true,
      // Declared once, for the row. `excludeSemantics` drops both the inner
      // switch and the button role FoCard's own tap target announces — this is
      // one toggle, not a button containing a switch.
      excludeSemantics: true,
      toggled: value,
      enabled: interactive,
      label: semanticLabel ?? title,
      hint: subtitle,
      onTap: interactive ? () => onChanged!(!value) : null,
      child: card,
    );
  }
}

/// Why a [FoSwitchTile] cannot be moved, and the word shown instead of it.
///
/// A locked state belongs to the component rather than to each caller,
/// because the thing that goes wrong is the same everywhere: a disabled switch
/// that is on reads as off. What the component cannot own is the *words* —
/// they are domain copy and they have to be localizable — so they come in.
@immutable
class FoSwitchTileLock {
  /// Creates a lock.
  const FoSwitchTileLock({required this.label, this.reason});

  /// The word shown in place of the switch — "Always on", "Set by your firm".
  /// Short: it is a chip, not a sentence.
  final String label;

  /// Why, in a sentence, under the subtitle. Optional, but a lock the user
  /// cannot explain to themselves is one they will report as a bug.
  final String? reason;
}

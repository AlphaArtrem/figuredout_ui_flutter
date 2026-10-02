import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/fo_context.dart';
import '../tokens/fo_layout.dart';
import '../tokens/fo_tokens.dart';
import 'fo_focus_ring.dart';

/// A whole-number count: a numeric box between a − and a + button.
///
/// The Flutter twin of the web package's `NumberField`, built for counting
/// pieces on a phone: each stepper is a 48 × 52 target, the box is wide enough
/// for four digits at a size readable at arm's length, and typing is digits
/// only.
///
/// **It is controlled.** [value] is the truth and every change goes out
/// through [onChanged]; a value set from outside — "Fill all ready" filling
/// every size at once — is shown immediately. That is the bug
/// `FoMatrixNumericCell` and the old `FoDropdownField` both had: a
/// `FormField` seeds from `initialValue` once and never re-reads it.
///
/// **A half-typed draft is kept.** Clearing the box to type a new number does
/// not snap it to [min] mid-keystroke; an empty box reports nothing, and is
/// put back to [value] when focus leaves it.
///
/// [warning] is a state, not an error: a count over what was ready is
/// allowed, and needs an owner's approval rather than a correction. It draws a
/// 2dp warning ring and nothing else — the sentence saying why belongs beside
/// the field, which is `FoSizeCountRow`'s job.
class FoNumberField extends StatefulWidget {
  /// Creates a number field.
  const FoNumberField({
    required this.value,
    required this.onChanged,
    required this.semanticLabel,
    this.decreaseSemanticLabel,
    this.increaseSemanticLabel,
    this.min = 0,
    this.max,
    this.showSteppers = true,
    this.warning = false,
    this.error = false,
    this.enabled = true,
    this.boxWidth = FoNumberField.defaultBoxWidth,
    super.key,
  })  : assert(
          !showSteppers ||
              (decreaseSemanticLabel != null && increaseSemanticLabel != null),
          'decreaseSemanticLabel and increaseSemanticLabel are required when '
          'the steppers show — an unnamed "−" is two invisible buttons.',
        ),
        assert(max == null || max >= min, 'max must not be below min.');

  /// The current count.
  final int value;

  /// Called with the new count, already clamped to [min]–[max].
  final ValueChanged<int> onChanged;

  /// The box's name — "Pressed, size M". Caller-supplied, so it can be
  /// localized. Without the size in it, five boxes all read "Pressed".
  final String semanticLabel;

  /// The − button's name — "One fewer, size M".
  final String? decreaseSemanticLabel;

  /// The + button's name — "One more, size M".
  final String? increaseSemanticLabel;

  /// The smallest count. Defaults to zero; a count of pieces is never
  /// negative.
  final int min;

  /// The largest count, or null for none. **Not** the "ready" figure: going
  /// over ready is allowed and is what [warning] is for. This is a hard
  /// ceiling — a typo guard.
  final int? max;

  /// Shows the − and + buttons. Off in a dense table on a wide window, where
  /// a pointer and a keyboard make them noise.
  final bool showSteppers;

  /// Draws the warning ring — over a limit that is allowed but needs approval.
  final bool warning;

  /// Draws the danger ring — a value that cannot be saved, such as an order
  /// quantity below what is already cut. The sentence saying what to do sits
  /// beside the field; this is only the ring.
  final bool error;

  /// The box's width. Wider for a grand total, the default for a count.
  final double boxWidth;

  /// When false nothing can change.
  final bool enabled;

  /// The default box width: four digits at the count size, with room either
  /// side.
  static const double defaultBoxWidth = 76;

  /// The box's and the steppers' height — taller than the 48dp floor so a
  /// thumb landing a little low still hits.
  static const double controlHeight = 52;

  /// The count's type size — readable at arm's length on a bench.
  static const double _countSize = 22;

  @override
  State<FoNumberField> createState() => _FoNumberFieldState();
}

class _FoNumberFieldState extends State<FoNumberField> {
  late final TextEditingController _controller =
      TextEditingController(text: '${widget.value}');
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void didUpdateWidget(FoNumberField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // The controlled half. Only rewrite the text when it disagrees with the
    // value — rewriting it on every rebuild would move the caret under
    // somebody who is typing.
    if (int.tryParse(_controller.text) != widget.value &&
        !(_controller.text.isEmpty && _focusNode.hasFocus)) {
      _setText('${widget.value}');
    }
  }

  @override
  void dispose() {
    _focusNode
      ..removeListener(_onFocusChanged)
      ..dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    // A draft left empty goes back to the value it was standing in for.
    if (!_focusNode.hasFocus && int.tryParse(_controller.text) == null) {
      _setText('${widget.value}');
    }
  }

  void _setText(String text) {
    _controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  int _clamp(int value) {
    int next = value < widget.min ? widget.min : value;
    final int? max = widget.max;
    if (max != null && next > max) next = max;
    return next;
  }

  void _onTyped(String raw) {
    final int? parsed = int.tryParse(raw);
    if (parsed == null) return;
    final int clamped = _clamp(parsed);
    if (clamped != parsed) _setText('$clamped');
    if (clamped != widget.value) widget.onChanged(clamped);
  }

  void _step(int delta) {
    final int next = _clamp(widget.value + delta);
    if (next != widget.value) widget.onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    final bool canDecrease = widget.enabled && widget.value > widget.min;
    final int? max = widget.max;
    final bool canIncrease =
        widget.enabled && (max == null || widget.value < max);

    final Widget box = _Box(
      warning: widget.warning,
      error: widget.error,
      width: widget.boxWidth,
      enabled: widget.enabled,
      child: Semantics(
        label: widget.semanticLabel,
        child: TextField(
          controller: _controller,
          focusNode: _focusNode,
          enabled: widget.enabled,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          inputFormatters: <TextInputFormatter>[
            FilteringTextInputFormatter.digitsOnly,
          ],
          style: context.foText.numeric.copyWith(
            fontSize: FoNumberField._countSize,
            fontWeight: FontWeight.w600,
          ),
          decoration: const InputDecoration.collapsed(hintText: null),
          onChanged: _onTyped,
        ),
      ),
    );

    if (!widget.showSteppers) return box;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _Stepper(
          icon: Icons.remove,
          semanticLabel: widget.decreaseSemanticLabel!,
          onPressed: canDecrease ? () => _step(-1) : null,
        ),
        SizedBox(width: context.foSpacing.xs),
        box,
        SizedBox(width: context.foSpacing.xs),
        _Stepper(
          icon: Icons.add,
          semanticLabel: widget.increaseSemanticLabel!,
          onPressed: canIncrease ? () => _step(1) : null,
        ),
      ],
    );
  }
}

/// The numeric box: lifted, with a strong hairline, or a 2dp warning ring.
class _Box extends StatelessWidget {
  const _Box({
    required this.warning,
    required this.error,
    required this.width,
    required this.enabled,
    required this.child,
  });

  final bool warning;
  final bool error;
  final double width;
  final bool enabled;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final BorderRadius radius = BorderRadius.circular(context.foRadii.md);
    return FoFocusRing(
      borderRadius: radius,
      enabled: enabled,
      child: Container(
        width: width,
        height: FoNumberField.controlHeight,
        alignment: Alignment.center,
        padding: EdgeInsets.symmetric(horizontal: context.foSpacing.xs),
        decoration: BoxDecoration(
          color: context.foColors.surfaceRaised,
          borderRadius: radius,
        ),
        foregroundDecoration: BoxDecoration(
          borderRadius: radius,
          border: Border.all(
            color: error
                ? context.foColors.danger
                : warning
                    ? context.foColors.warning
                    : context.foColors.edgeStrong,
            width: error || warning ? 2 : FoLayout.hairlineWidth,
          ),
        ),
        child: child,
      ),
    );
  }
}

/// One of the − / + buttons.
class _Stepper extends StatelessWidget {
  const _Stepper({
    required this.icon,
    required this.semanticLabel,
    required this.onPressed,
  });

  final IconData icon;
  final String semanticLabel;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final BorderRadius radius = BorderRadius.circular(context.foRadii.md);
    final bool enabled = onPressed != null;
    final Color ink = enabled
        ? context.foColors.fg
        : context.foColors.fg.withValues(alpha: FoTokens.disabledInkOpacity);

    return Semantics(
      button: true,
      enabled: enabled,
      label: semanticLabel,
      onTap: onPressed,
      excludeSemantics: true,
      child: FoFocusRing(
        borderRadius: radius,
        enabled: enabled,
        child: Material(
          color: context.foColors.surfaceRaised,
          borderRadius: radius,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onPressed,
            child: Container(
              width: FoLayout.minTouchTarget,
              height: FoNumberField.controlHeight,
              alignment: Alignment.center,
              foregroundDecoration: BoxDecoration(
                borderRadius: radius,
                border: Border.all(color: context.foColors.edgeStrong),
              ),
              child: Icon(icon, size: FoTokens.iconMedium, color: ink),
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../primitives/fo_button.dart';
import '../primitives/fo_focus_ring.dart';
import '../theme/fo_context.dart';
import '../tokens/fo_tokens.dart';

/// How a [FoScanViewfinder] is drawn.
enum FoScanViewfinderStyle {
  /// A tappable area in the page, on the sunken step with primary corner
  /// brackets — "Tap to scan the next bundle". The camera opens on tap.
  inline,

  /// The camera itself, full-bleed and dark, with a light frame to aim at.
  camera,
}

/// Where a barcode is read from: the camera, framed, with what to do.
///
/// **The package never touches the camera.** The app supplies the live
/// preview as [camera] (from whichever scanner plugin it uses) and reports
/// what was read through its own callback; this draws the frame, the aiming
/// box and the words around them, so every scanner in every app aims the
/// same way. With no [camera] it is a placeholder the user taps to start one.
///
/// Scanning is never the only way in: pair it with a [FoScanField] for a
/// damaged label or a code with no barcode.
class FoScanViewfinder extends StatelessWidget {
  /// Creates a viewfinder.
  const FoScanViewfinder({
    required this.title,
    required this.semanticLabel,
    this.caption,
    this.camera,
    this.onTap,
    this.style = FoScanViewfinderStyle.inline,
    this.height,
    super.key,
  });

  /// What to point at — "Point at the barcode on the label". Caller-supplied.
  final String title;

  /// A second line — "It scans by itself. Hold the phone still."
  final String? caption;

  /// What the area is, read aloud — "Camera. Scan a bundle ticket."
  final String semanticLabel;

  /// The live preview, from the app's scanner.
  final Widget? camera;

  /// Starts scanning, when the area is a button.
  final VoidCallback? onTap;

  /// Inline placeholder or full camera.
  final FoScanViewfinderStyle style;

  /// The area's height. Defaults to 176 inline and 320 for the camera.
  final double? height;

  static const double _bracket = 34;

  @override
  Widget build(BuildContext context) {
    final bool dark = style == FoScanViewfinderStyle.camera;
    final BorderRadius radius = BorderRadius.circular(context.foRadii.card);
    // The camera style is dark in both themes: a viewfinder is a hole onto
    // the world, not a surface of the app. Its ink is the theme's ground.
    final Color ground =
        dark ? context.foColors.fg : context.foColors.surfaceSunken;
    final Color ink = dark ? context.foColors.bg : context.foColors.fg;
    final Color accent = dark ? context.foColors.bg : context.foColors.primary;

    final Widget words = Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (!dark)
          Icon(Icons.qr_code_scanner,
              size: 40, color: context.foColors.primary),
        if (!dark) SizedBox(height: context.foSpacing.sm),
        Text(
          title,
          textAlign: TextAlign.center,
          style: context.foText.subtitle.copyWith(color: ink),
        ),
        if (caption != null)
          Text(
            caption!,
            textAlign: TextAlign.center,
            style: context.foText.body.copyWith(
              fontSize: FoTokens.fontLabel,
              color: dark ? ink : context.foColors.fgMuted,
            ),
          ),
      ],
    );

    final Widget frame = dark
        ? Center(
            child: Container(
              width: 260,
              height: 150,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(context.foRadii.card),
                border: Border.all(color: accent, width: 2),
              ),
            ),
          )
        : Stack(
            children: <Widget>[
              for (final AlignmentDirectional corner in <AlignmentDirectional>[
                AlignmentDirectional.topStart,
                AlignmentDirectional.topEnd,
                AlignmentDirectional.bottomStart,
                AlignmentDirectional.bottomEnd,
              ])
                Align(
                  alignment: corner,
                  child: Padding(
                    padding: EdgeInsets.all(context.foSpacing.md),
                    child: _Bracket(
                      corner: corner,
                      color: accent,
                      size: _bracket,
                    ),
                  ),
                ),
            ],
          );

    // The words set the height when they need more than the frame — at 200%
    // text a fixed box would cut the instruction off — and the camera and the
    // frame fill whatever that turns out to be.
    final Widget area = ClipRRect(
      borderRadius: radius,
      child: ColoredBox(
        color: ground,
        child: Stack(
          children: <Widget>[
            if (camera != null) Positioned.fill(child: camera!),
            Positioned.fill(child: frame),
            ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: height ?? (dark ? 320 : 176),
                minWidth: double.infinity,
              ),
              child: Align(
                alignment: dark ? Alignment.bottomCenter : Alignment.center,
                widthFactor: 1,
                child: Padding(
                  padding: EdgeInsets.all(context.foSpacing.xl),
                  child: words,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (onTap == null) {
      return Semantics(label: semanticLabel, image: true, child: area);
    }
    return Semantics(
      button: true,
      label: semanticLabel,
      onTap: onTap,
      excludeSemantics: true,
      child: FoFocusRing(
        borderRadius: radius,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(onTap: onTap, borderRadius: radius, child: area),
        ),
      ),
    );
  }
}

class _Bracket extends StatelessWidget {
  const _Bracket({
    required this.corner,
    required this.color,
    required this.size,
  });

  final AlignmentDirectional corner;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final BorderSide side = BorderSide(color: color, width: 4);
    final bool top = corner.y < 0;
    final bool start = corner.start < 0;
    return SizedBox(
      width: size,
      height: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: BorderDirectional(
            top: top ? side : BorderSide.none,
            bottom: top ? BorderSide.none : side,
            start: start ? side : BorderSide.none,
            end: start ? BorderSide.none : side,
          ),
        ),
      ),
    );
  }
}

/// A code, scanned or typed: the box a USB barcode reader types into, and the
/// way in when the label will not scan.
///
/// A reader types the code and presses Enter, so Enter submits; after a
/// submit the box empties and **keeps focus**, so the next scan lands in it
/// without anybody touching the screen. [onSubmitted] gets the trimmed code
/// — upper-cased when [upperCase] is set, because printed codes are — and the
/// caller shows what happened, usually with a `FoInfoBanner` in the result's
/// tone (added: success; already scanned: neutral; wrong item: warning).
class FoScanField extends StatefulWidget {
  /// Creates a scan field.
  const FoScanField({
    required this.label,
    required this.submitLabel,
    required this.onSubmitted,
    this.hintText,
    this.helperText,
    this.errorText,
    this.upperCase = true,
    this.autofocus = false,
    super.key,
  });

  /// "Scan or type a bundle number". Caller-supplied.
  final String label;

  /// The button's word — "Add bundle", "Find".
  final String submitLabel;

  /// Gets the code.
  final ValueChanged<String> onSubmitted;

  /// An example code — "BNDL-1005-M-001".
  final String? hintText;

  /// "A barcode scanner types the number and presses Enter for you."
  final String? helperText;

  /// What went wrong with the last code.
  final String? errorText;

  /// Upper-cases what is typed.
  final bool upperCase;

  /// Takes focus when it appears — on a web page whose job is scanning.
  final bool autofocus;

  @override
  State<FoScanField> createState() => _FoScanFieldState();
}

class _FoScanFieldState extends State<FoScanField> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focus = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _submit() {
    final String code = _controller.text.trim();
    if (code.isEmpty) return;
    widget.onSubmitted(widget.upperCase ? code.toUpperCase() : code);
    _controller.clear();
    // Keep the box ready for the next scan.
    _focus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(widget.label, style: context.foText.label),
        SizedBox(height: context.foSpacing.xs),
        Wrap(
          spacing: context.foSpacing.sm,
          runSpacing: context.foSpacing.sm,
          children: <Widget>[
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: TextField(
                controller: _controller,
                focusNode: _focus,
                autofocus: widget.autofocus,
                textInputAction: TextInputAction.done,
                textCapitalization: widget.upperCase
                    ? TextCapitalization.characters
                    : TextCapitalization.none,
                inputFormatters: <TextInputFormatter>[
                  if (widget.upperCase) _UpperCase(),
                ],
                style: context.foText.numeric,
                onSubmitted: (_) => _submit(),
                decoration: InputDecoration(
                  hintText: widget.hintText,
                  prefixIcon: const Icon(Icons.qr_code_scanner),
                  helperText:
                      widget.errorText == null ? widget.helperText : null,
                  helperMaxLines: 3,
                  errorText: widget.errorText,
                  errorMaxLines: 3,
                  isDense: true,
                ),
              ),
            ),
            FoButton(
              label: widget.submitLabel,
              variant: FoButtonVariant.secondary,
              onPressed: _submit,
            ),
          ],
        ),
      ],
    );
  }
}

class _UpperCase extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) =>
      newValue.copyWith(text: newValue.text.toUpperCase());
}

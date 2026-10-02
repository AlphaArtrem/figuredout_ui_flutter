import 'package:flutter/material.dart';

import '../primitives/fo_button.dart';
import '../primitives/fo_choice_group.dart';
import '../theme/fo_context.dart';
import '../theme/fo_window_class.dart';
import 'fo_consequence_list.dart';

/// A ready-made reason: a chip that fills the message with editable text.
@immutable
class FoQuickReason {
  /// Creates a quick reason.
  const FoQuickReason({required this.label, required this.text});

  /// The chip's word — "Counted wrong". Caller-supplied.
  final String label;

  /// What it puts in the box — a whole sentence the user can still edit.
  /// Empty for "Something else", which clears the box for typing.
  final String text;
}

/// Why — asked with one tap and still editable: the reason for declining a
/// change, putting an order on hold, going over a limit.
///
/// [quickReasons] are chips that fill the box with a sentence; typing over it
/// is always allowed, and the chip whose text no longer matches lets go. The
/// reason is **required** when [errorText] says so: the caller decides when a
/// blank reason is an error (as soon as the box is empty, the redesign's
/// rule), and keeps its confirm button off until it is not.
///
/// The text is the caller's [controller], so the reason survives a rebuild
/// and the caller reads it when confirming.
class FoReasonField extends StatefulWidget {
  /// Creates a reason field.
  const FoReasonField({
    required this.controller,
    required this.label,
    this.quickReasons = const <FoQuickReason>[],
    this.hintText,
    this.helperText,
    this.errorText,
    this.isRequired = true,
    this.onChanged,
    super.key,
  });

  /// Holds the reason.
  final TextEditingController controller;

  /// What the box asks — "Why are you declining?". Caller-supplied.
  final String label;

  /// One-tap reasons.
  final List<FoQuickReason> quickReasons;

  /// Placeholder in the box.
  final String? hintText;

  /// A line under the box — who will read it.
  final String? helperText;

  /// What to do about a missing reason. Null when nothing is wrong.
  final String? errorText;

  /// Marks the label with the `*`.
  final bool isRequired;

  /// Told when the text changes, by typing or by a chip.
  final ValueChanged<String>? onChanged;

  @override
  State<FoReasonField> createState() => _FoReasonFieldState();
}

class _FoReasonFieldState extends State<FoReasonField> {
  int? _chosen;

  void _choose(int index) {
    final String text = widget.quickReasons[index].text;
    widget.controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
    setState(() => _chosen = index);
    widget.onChanged?.call(text);
  }

  void _typed(String value) {
    // Typing over a chip's sentence lets the chip go: it no longer says what
    // the box says.
    final int? chosen = _chosen;
    if (chosen != null && widget.quickReasons[chosen].text != value) {
      setState(() => _chosen = null);
    }
    widget.onChanged?.call(value);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text.rich(
          TextSpan(
            children: <InlineSpan>[
              TextSpan(text: widget.label),
              if (widget.isRequired)
                TextSpan(
                  text: ' *',
                  style: TextStyle(color: context.foColors.danger),
                ),
            ],
          ),
          style: context.foText.label,
        ),
        if (widget.quickReasons.isNotEmpty) ...<Widget>[
          SizedBox(height: context.foSpacing.sm),
          FoChoiceGroup<int>.single(
            semanticLabel: widget.label,
            value: _chosen,
            onChanged: _choose,
            choices: <FoChoice<int>>[
              for (int i = 0; i < widget.quickReasons.length; i++)
                FoChoice<int>(value: i, label: widget.quickReasons[i].label),
            ],
          ),
        ],
        SizedBox(height: context.foSpacing.sm),
        TextField(
          controller: widget.controller,
          minLines: 2,
          maxLines: 4,
          style: context.foText.body,
          onChanged: _typed,
          decoration: InputDecoration(
            hintText: widget.hintText,
            helperText: widget.errorText == null ? widget.helperText : null,
            helperMaxLines: 3,
            errorText: widget.errorText,
            errorMaxLines: 3,
          ),
        ),
      ],
    );
  }
}

/// The words a reason dialog needs.
@immutable
class FoReasonDialogCopy {
  /// Creates the copy.
  const FoReasonDialogCopy({
    required this.title,
    required this.reasonLabel,
    required this.confirmLabel,
    required this.cancelLabel,
    required this.requiredMessage,
    this.eyebrow,
    this.message,
    this.hintText,
    this.helperText,
  });

  /// The question, naming the record — "Decline the change to PRS-00415?".
  final String title;

  /// A mono caption over it — "Approvals".
  final String? eyebrow;

  /// What stays as it is, and who gets told.
  final String? message;

  /// The box's question.
  final String reasonLabel;

  /// Placeholder in the box.
  final String? hintText;

  /// A line under the box.
  final String? helperText;

  /// What to do when the box is empty — "Say why, so Imran knows what to
  /// fix."
  final String requiredMessage;

  /// The action, named — "Decline change", "Put the order on hold". Never
  /// "OK".
  final String confirmLabel;

  /// The safe way out, named for what it keeps — "Keep it waiting".
  final String cancelLabel;
}

/// A decision that needs a reason: decline a change, put an order on hold,
/// override a limit. Resolves with the reason, or null when the user kept
/// things as they were.
///
/// The dialog half of [FoReasonField]: the question names the record, the
/// lede says what stays the same and who is told, `consequences` lists what
/// will happen, and the confirm button names the action and stays off until
/// there is a reason. `confirmVariant` is `destructive` for what cannot be
/// undone and `warning` for what an owner is overriding.
///
/// A dialog on a wide window and a bottom sheet on a phone, like `FoDialog`.
abstract final class FoReasonDialog {
  /// Asks for a reason.
  static Future<String?> show(
    BuildContext context, {
    required FoReasonDialogCopy copy,
    List<FoQuickReason> quickReasons = const <FoQuickReason>[],
    List<FoConsequence> consequences = const <FoConsequence>[],
    String? consequencesTitle,
    FoButtonVariant confirmVariant = FoButtonVariant.primary,
    String initialReason = '',
  }) {
    Widget body(BuildContext ctx) => _ReasonBody(
          copy: copy,
          quickReasons: quickReasons,
          consequences: consequences,
          consequencesTitle: consequencesTitle,
          confirmVariant: confirmVariant,
          initialReason: initialReason,
        );

    if (context.foWindowClass == FoWindowClass.compact) {
      return showModalBottomSheet<String>(
        context: context,
        useRootNavigator: true,
        isScrollControlled: true,
        useSafeArea: true,
        elevation: 0,
        builder: (BuildContext ctx) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(ctx).bottom,
          ),
          child: body(ctx),
        ),
      );
    }
    return showDialog<String>(
      context: context,
      builder: (BuildContext ctx) => Dialog(
        backgroundColor: ctx.foColors.surfaceRaised,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ctx.foRadii.lg),
          side: BorderSide(color: ctx.foColors.edge),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _maxWidth),
          child: body(ctx),
        ),
      ),
    );
  }

  static const double _maxWidth = 640;
}

class _ReasonBody extends StatefulWidget {
  const _ReasonBody({
    required this.copy,
    required this.quickReasons,
    required this.consequences,
    required this.consequencesTitle,
    required this.confirmVariant,
    required this.initialReason,
  });

  final FoReasonDialogCopy copy;
  final List<FoQuickReason> quickReasons;
  final List<FoConsequence> consequences;
  final String? consequencesTitle;
  final FoButtonVariant confirmVariant;
  final String initialReason;

  @override
  State<_ReasonBody> createState() => _ReasonBodyState();
}

class _ReasonBodyState extends State<_ReasonBody> {
  late final TextEditingController _reason =
      TextEditingController(text: widget.initialReason);
  bool _touched = false;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  bool get _empty => _reason.text.trim().isEmpty;

  @override
  Widget build(BuildContext context) {
    final FoReasonDialogCopy copy = widget.copy;
    return SingleChildScrollView(
      padding: EdgeInsets.all(context.foSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (copy.eyebrow != null) ...<Widget>[
            Text(copy.eyebrow!.toUpperCase(), style: context.foText.caption),
            SizedBox(height: context.foSpacing.xs),
          ],
          Semantics(
            header: true,
            child: Text(copy.title, style: context.foText.display),
          ),
          if (copy.message != null) ...<Widget>[
            SizedBox(height: context.foSpacing.sm),
            Text(
              copy.message!,
              style: context.foText.body.copyWith(
                color: context.foColors.fgMuted,
              ),
            ),
          ],
          SizedBox(height: context.foSpacing.xl),
          FoReasonField(
            controller: _reason,
            label: copy.reasonLabel,
            quickReasons: widget.quickReasons,
            hintText: copy.hintText,
            helperText: copy.helperText,
            errorText: _touched && _empty ? copy.requiredMessage : null,
            onChanged: (_) => setState(() => _touched = true),
          ),
          if (widget.consequences.isNotEmpty) ...<Widget>[
            SizedBox(height: context.foSpacing.lg),
            FoConsequenceList(
              title: widget.consequencesTitle,
              items: widget.consequences,
            ),
          ],
          SizedBox(height: context.foSpacing.xl),
          Wrap(
            alignment: WrapAlignment.end,
            spacing: context.foSpacing.sm,
            runSpacing: context.foSpacing.sm,
            children: <Widget>[
              FoButton(
                label: copy.cancelLabel,
                variant: FoButtonVariant.clear,
                onPressed: () => Navigator.of(context).pop(),
              ),
              FoButton(
                label: copy.confirmLabel,
                variant: widget.confirmVariant,
                onPressed: _empty
                    ? null
                    : () => Navigator.of(context).pop(_reason.text.trim()),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

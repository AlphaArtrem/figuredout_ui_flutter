import 'package:flutter/material.dart';

import '../primitives/fo_button.dart';
import '../theme/fo_context.dart';
import '../tokens/fo_tokens.dart';

/// One marker on a [FoMarkedScreenshot]: the control a guide step names.
@immutable
class FoScreenMarker {
  /// Creates a marker.
  const FoScreenMarker({required this.number, required this.rect});

  /// The step's number, drawn in the badge.
  final int number;

  /// The control's box, in the screenshot's own pixels — the size it was
  /// captured at, not the size it is drawn.
  final Rect rect;
}

/// A real screen, with the control a step talks about ringed and numbered.
///
/// Guides show the actual screen rather than describe it, and point at the
/// one control the step names. The markers are given in the screenshot's own
/// pixels ([sourceSize]) and the widget does the scaling, so the same
/// coordinates work at whatever size the guide draws it — 720 wide in an
/// article, 400 in a drawer. [crop] shows only part of the screen.
///
/// The ring is primary with a gap of paper inside it, so it reads on both a
/// light and a dark screenshot; the numbered badge sits on its corner and is
/// kept inside the frame. The whole thing is one image to a screen reader,
/// and [semanticLabel] must say what is shown *and* what is marked — "The
/// Pressing page. Record pressing, top right, is marked 1."
class FoMarkedScreenshot extends StatelessWidget {
  /// Creates a marked screenshot.
  const FoMarkedScreenshot({
    required this.image,
    required this.sourceSize,
    required this.semanticLabel,
    this.markers = const <FoScreenMarker>[],
    this.crop,
    this.caption,
    super.key,
  });

  /// The picture — the app's `Image`, sized by this widget.
  final Widget image;

  /// The screenshot's size in its own pixels.
  final Size sourceSize;

  /// Part of the screenshot to show, in its own pixels. Null shows all of it.
  final Rect? crop;

  /// The controls to mark.
  final List<FoScreenMarker> markers;

  /// What is shown and what is marked, read aloud.
  final String semanticLabel;

  /// A visible line under the picture.
  final String? caption;

  static const double _badge = 26;
  static const double _ringGap = 4;

  @override
  Widget build(BuildContext context) {
    final Rect view = crop ?? Offset.zero & sourceSize;
    final BorderRadius radius = BorderRadius.circular(context.foRadii.md);

    final Widget frame = LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double width = constraints.hasBoundedWidth
            ? constraints.maxWidth.clamp(0, view.width)
            : view.width;
        final double scale = width / view.width;
        final double height = view.height * scale;

        return SizedBox(
          width: width,
          height: height,
          child: ClipRRect(
            borderRadius: radius,
            child: Stack(
              children: <Widget>[
                Positioned(
                  left: -view.left * scale,
                  top: -view.top * scale,
                  width: sourceSize.width * scale,
                  height: sourceSize.height * scale,
                  child: image,
                ),
                for (final FoScreenMarker m in markers)
                  ..._marker(context, m, view, scale, Size(width, height)),
                Positioned.fill(
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: radius,
                        border: Border.all(color: context.foColors.edge),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    return Semantics(
      image: true,
      label: semanticLabel,
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          frame,
          if (caption != null) ...<Widget>[
            SizedBox(height: context.foSpacing.xs),
            Text(
              caption!,
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

  List<Widget> _marker(
    BuildContext context,
    FoScreenMarker m,
    Rect view,
    double scale,
    Size frame,
  ) {
    final Rect box = Rect.fromLTWH(
      (m.rect.left - view.left) * scale - _ringGap,
      (m.rect.top - view.top) * scale - _ringGap,
      m.rect.width * scale + _ringGap * 2,
      m.rect.height * scale + _ringGap * 2,
    );
    // The badge's centre sits on the ring's top-left corner, kept inside the
    // frame so a control at the edge still gets a whole number.
    final double left =
        (box.left - _badge / 2).clamp(3.0, frame.width - _badge - 3);
    final double top =
        (box.top - _badge / 2).clamp(3.0, frame.height - _badge - 3);
    return <Widget>[
      Positioned.fromRect(
        rect: box,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(context.foRadii.md),
            border: Border.all(color: context.foColors.primary, width: 3),
            boxShadow: <BoxShadow>[
              BoxShadow(color: context.foColors.surfaceRaised, spreadRadius: 2),
            ],
          ),
        ),
      ),
      Positioned(
        left: left,
        top: top,
        child: Center(
// A circle stays a circle under any constraints (see FoDisc).
          widthFactor: 1,
          heightFactor: 1,
          child: Container(
            width: _badge,
            height: _badge,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: context.foColors.primary,
              shape: BoxShape.circle,
              border:
                  Border.all(color: context.foColors.surfaceRaised, width: 3),
            ),
            child: Text(
              '${m.number}',
              textScaler: TextScaler.noScaling,
              style: context.foText.numeric.copyWith(
                fontSize: FoTokens.fontCaption,
                fontWeight: FontWeight.w600,
                color: context.foColors.primaryFg,
              ),
            ),
          ),
        ),
      ),
    ];
  }
}

/// One numbered step of a guide: the number, what to do, how, and the
/// screen it happens on.
///
/// The number is decoration — the [title] carries "Step 1:" when the guide
/// wants it read — and [media] is usually a [FoMarkedScreenshot] whose marker
/// carries the same number. [anchorKey] goes on the step so a help link can
/// open the guide at it (`FoHelpGuide.show(scrollTo:)`).
class FoGuideStep extends StatelessWidget {
  /// Creates a guide step.
  const FoGuideStep({
    required this.number,
    required this.title,
    required this.body,
    this.media,
    this.anchorKey,
    this.compact = false,
    super.key,
  });

  /// The step's number.
  final int number;

  /// What to do — "Count by size". Caller-supplied.
  final String title;

  /// How — usually a `Text.rich` with the control names in bold.
  final Widget body;

  /// The screen it happens on.
  final Widget? media;

  /// The key a help link scrolls to.
  final GlobalKey? anchorKey;

  /// The smaller form, for a drawer or a list of steps with no pictures.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final double disc = compact ? 26 : 32;
    final double indent = disc + context.foSpacing.md;
    return Column(
      key: anchorKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            ExcludeSemantics(
              child: Center(
// A circle stays a circle under any constraints (see FoDisc).
                widthFactor: 1,
                heightFactor: 1,
                child: Container(
                  width: disc,
                  height: disc,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: context.foColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$number',
                    textScaler: TextScaler.noScaling,
                    style: context.foText.numeric.copyWith(
                      fontWeight: FontWeight.w600,
                      color: context.foColors.primaryFg,
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(width: context.foSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Semantics(
                    header: true,
                    child: Text(
                      title,
                      style: compact
                          ? context.foText.subtitle
                          : context.foText.title,
                    ),
                  ),
                  SizedBox(height: context.foSpacing.xs),
                  DefaultTextStyle.merge(
                    style: context.foText.body.copyWith(
                      color: context.foColors.fgMuted,
                      height: 1.6,
                    ),
                    child: body,
                  ),
                ],
              ),
            ),
          ],
        ),
        if (media != null) ...<Widget>[
          SizedBox(height: context.foSpacing.md),
          Padding(
            padding: EdgeInsetsDirectional.only(start: compact ? 0 : indent),
            child: media,
          ),
        ],
      ],
    );
  }
}

/// The words a [FoHelpfulVote] needs.
@immutable
class FoHelpfulVoteCopy {
  /// Creates the copy.
  const FoHelpfulVoteCopy({
    required this.question,
    required this.yesLabel,
    required this.noLabel,
    required this.thanksYes,
    this.noPrompt,
    this.noteLabel,
    this.noteHint,
    this.sendLabel,
    this.sentMessage,
    this.thanksNo,
    this.sendFailedMessage,
  });

  /// "Was this helpful?".
  final String question;

  /// "Yes".
  final String yesLabel;

  /// "No".
  final String noLabel;

  /// "Thanks. Glad it helped."
  final String thanksYes;

  /// "Sorry about that. What were you trying to do?" — opens the note.
  /// Null skips the note and shows [thanksNo].
  final String? noPrompt;

  /// "Optional. Don't add names or phone numbers."
  final String? noteLabel;

  /// Placeholder in the note.
  final String? noteHint;

  /// "Send".
  final String? sendLabel;

  /// "Sent. The person who writes the guides will see it."
  final String? sentMessage;

  /// Shown after "No" when there is no note to write.
  final String? thanksNo;

  /// "Couldn't send. It will go when you're back online." — when
  /// [FoHelpfulVote.onSendNote] throws.
  final String? sendFailedMessage;
}

/// "Was this helpful?" — two buttons, then thanks; after "No", an optional
/// note.
///
/// Anonymous, and never a dead end: once answered the question is replaced
/// by a sentence, announced as a status, saying the answer was heard. After
/// "No" it asks what the reader was trying to do — optional, never required
/// — and [onSendNote] sends it; a failure says so rather than pretending.
class FoHelpfulVote extends StatefulWidget {
  /// Creates a vote.
  const FoHelpfulVote({
    required this.copy,
    required this.onVote,
    this.onSendNote,
    this.noteMaxLength = 500,
    super.key,
  });

  /// The words.
  final FoHelpfulVoteCopy copy;

  /// Told the answer.
  final ValueChanged<bool> onVote;

  /// Sends the note written after "No".
  final Future<void> Function(String note)? onSendNote;

  /// The longest a note may be.
  final int noteMaxLength;

  @override
  State<FoHelpfulVote> createState() => _FoHelpfulVoteState();
}

enum _VoteStage { asking, yes, no, sending, sent, failed }

class _FoHelpfulVoteState extends State<FoHelpfulVote> {
  _VoteStage _stage = _VoteStage.asking;
  final TextEditingController _note = TextEditingController();

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  void _vote(bool helpful) {
    widget.onVote(helpful);
    setState(() => _stage = helpful ? _VoteStage.yes : _VoteStage.no);
  }

  Future<void> _send() async {
    final Future<void> Function(String)? send = widget.onSendNote;
    if (send == null) return;
    setState(() => _stage = _VoteStage.sending);
    try {
      await send(_note.text.trim());
      if (mounted) setState(() => _stage = _VoteStage.sent);
    } on Object catch (_) {
      // The failure is the app's to log; the vote's job is to say so.
      if (mounted) setState(() => _stage = _VoteStage.failed);
    }
  }

  Widget _status(BuildContext context, String text, {bool ok = true}) =>
      Semantics(
        liveRegion: true,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(
              ok ? Icons.check_circle_outline : Icons.error_outline,
              size: FoTokens.iconSmall,
              color: ok ? context.foColors.success : context.foColors.danger,
            ),
            SizedBox(width: context.foSpacing.sm),
            Expanded(child: Text(text, style: context.foText.body)),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final FoHelpfulVoteCopy copy = widget.copy;
    final bool canNote = copy.noPrompt != null && widget.onSendNote != null;

    return switch (_stage) {
      _VoteStage.asking => Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: context.foSpacing.md,
          runSpacing: context.foSpacing.sm,
          children: <Widget>[
            Text(copy.question, style: context.foText.subtitle),
            Wrap(
              spacing: context.foSpacing.sm,
              children: <Widget>[
                FoButton(
                  label: copy.yesLabel,
                  variant: FoButtonVariant.secondary,
                  onPressed: () => _vote(true),
                ),
                FoButton(
                  label: copy.noLabel,
                  variant: FoButtonVariant.secondary,
                  onPressed: () => _vote(false),
                ),
              ],
            ),
          ],
        ),
      _VoteStage.yes => _status(context, copy.thanksYes),
      _VoteStage.no when !canNote =>
        _status(context, copy.thanksNo ?? copy.thanksYes),
      _VoteStage.no || _VoteStage.sending || _VoteStage.failed => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Semantics(
              liveRegion: true,
              child: Text(copy.noPrompt!, style: context.foText.subtitle),
            ),
            if (copy.noteLabel != null) ...<Widget>[
              SizedBox(height: context.foSpacing.xs),
              Text(
                copy.noteLabel!,
                style: context.foText.body.copyWith(
                  fontSize: FoTokens.fontLabel,
                  color: context.foColors.fgMuted,
                ),
              ),
            ],
            SizedBox(height: context.foSpacing.sm),
            TextField(
              controller: _note,
              minLines: 2,
              maxLines: 4,
              maxLength: widget.noteMaxLength,
              style: context.foText.body,
              decoration: InputDecoration(hintText: copy.noteHint),
            ),
            if (_stage == _VoteStage.failed &&
                copy.sendFailedMessage != null) ...<Widget>[
              _status(context, copy.sendFailedMessage!, ok: false),
              SizedBox(height: context.foSpacing.sm),
            ],
            FoButton(
              label: copy.sendLabel ?? '',
              variant: FoButtonVariant.primary,
              isLoading: _stage == _VoteStage.sending,
              onPressed: _send,
            ),
          ],
        ),
      _VoteStage.sent => _status(context, copy.sentMessage ?? copy.thanksYes),
    };
  }
}

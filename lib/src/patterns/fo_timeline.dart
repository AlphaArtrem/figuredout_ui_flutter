import 'package:flutter/material.dart';

import '../primitives/fo_status_chip.dart';
import '../theme/fo_context.dart';
import '../tokens/fo_tokens.dart';

/// One event in a [FoTimeline].
@immutable
class FoTimelineEvent {
  /// Creates an event.
  const FoTimelineEvent({
    required this.event,
    required this.time,
    this.actor,
    this.detail,
    this.tone = FoStatusTone.neutral,
  });

  /// What happened — "Submitted", "Change requested". Caller-supplied.
  final String event;

  /// Who did it — "by Imran Sheikh". Caller-supplied, with its own wording.
  final String? actor;

  /// When — "1 Oct, 17:52". Already formatted.
  final String time;

  /// A line under it — a reason, a figure.
  final String? detail;

  /// The dot's colour: success for submitted, info for a request, primary for
  /// a save, neutral for anything the system did.
  final FoStatusTone tone;
}

/// What happened to a record, newest first: "Submitted by Imran Sheikh ·
/// 1 Oct, 17:52".
///
/// One sentence per event with a toned dot, the event in the semibold weight
/// and the time quiet after it. It is a history, not a feed — every side
/// panel and record page that has one uses this, so "who changed this and
/// when" reads the same everywhere. An optional [heading] names it.
class FoTimeline extends StatelessWidget {
  /// Creates a timeline.
  const FoTimeline({required this.events, this.heading, super.key});

  /// The events, newest first.
  final List<FoTimelineEvent> events;

  /// A mono caption over the list — "History".
  final String? heading;

  static const double _dotSize = 8;

  @override
  Widget build(BuildContext context) {
    Color dot(FoStatusTone tone) => switch (tone) {
          FoStatusTone.neutral => context.foColors.edgeStrong,
          FoStatusTone.primary => context.foColors.primary,
          FoStatusTone.success => context.foColors.success,
          FoStatusTone.warning => context.foColors.warning,
          FoStatusTone.danger => context.foColors.danger,
          FoStatusTone.info => context.foColors.info,
        };
    final TextStyle base = context.foText.body.copyWith(
      fontSize: FoTokens.fontLabel,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (heading != null) ...<Widget>[
          Semantics(
            header: true,
            child: Text(heading!.toUpperCase(), style: context.foText.caption),
          ),
          SizedBox(height: context.foSpacing.md),
        ],
        for (int i = 0; i < events.length; i++) ...<Widget>[
          if (i > 0) SizedBox(height: context.foSpacing.md),
          MergeSemantics(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Center(
// A circle stays a circle under any constraints (see FoDisc).
                    widthFactor: 1,
                    heightFactor: 1,
                    child: Container(
                      width: _dotSize,
                      height: _dotSize,
                      decoration: BoxDecoration(
                        color: dot(events[i].tone),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: context.foSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text.rich(
                        TextSpan(
                          children: <InlineSpan>[
                            TextSpan(
                              text: events[i].event,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (events[i].actor != null)
                              TextSpan(text: ' ${events[i].actor}'),
                            TextSpan(
                              text: ' · ${events[i].time}',
                              style: TextStyle(
                                color: context.foColors.fgSubtle,
                              ),
                            ),
                          ],
                        ),
                        style: base,
                      ),
                      if (events[i].detail != null)
                        Text(
                          events[i].detail!,
                          style: base.copyWith(
                            color: context.foColors.fgMuted,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

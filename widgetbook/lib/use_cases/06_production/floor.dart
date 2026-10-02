import 'package:figuredout_ui/figuredout_ui.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

import '../../support/doc_page.dart';

/// Choosing, typing, scanning and editing on the floor.
class FloorInputs extends StatefulWidget {
  /// Creates the inputs page.
  const FloorInputs({super.key});

  @override
  State<FloorInputs> createState() => _FloorInputsState();
}

class _FloorInputsState extends State<FloorInputs> {
  String? _defect = 'stain';
  Set<int> _lines = <int>{4};
  String _role = 'line';
  String _pin = '';
  final TextEditingController _reason = TextEditingController();
  List<List<int>> _rows = <List<int>>[
    <int>[120, 240, 240],
    <int>[0, 0, 0],
  ];
  final List<double> _rolls = <double>[28.4, 31.0];
  String? _lastScan;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DocPage(
      title: 'Floor inputs',
      lede: 'One control for every "which of these", a PIN pad for a shared '
          'phone, a scan box a barcode reader can type into, a reason asked '
          'with one tap, quantities by colour and size, and a list typed one '
          'line at a time.',
      children: <Widget>[
        DocSection(
          title: 'Choice chips — one tap per piece',
          child: FoChoiceGroup<String>.single(
            semanticLabel: 'What was wrong, size L',
            value: _defect,
            onChanged: (String v) => setState(() => _defect = v),
            choices: const <FoChoice<String>>[
              FoChoice<String>(value: 'stitch', label: 'Loose stitch'),
              FoChoice<String>(value: 'stain', label: 'Stain', count: 2),
              FoChoice<String>(value: 'hole', label: 'Hole', count: 1),
              FoChoice<String>(value: 'shade', label: 'Shade variation'),
            ],
          ),
        ),
        DocSection(
          title: 'Choice cards — a role, a status',
          child: FoChoiceGroup<String>.single(
            semanticLabel: 'Role',
            layout: FoChoiceLayout.cards,
            value: _role,
            onChanged: (String v) => setState(() => _role = v),
            choices: const <FoChoice<String>>[
              FoChoice<String>(
                value: 'line',
                label: 'Line supervisor',
                description: 'Records loading, midline and output.',
              ),
              FoChoice<String>(
                value: 'qc',
                label: 'QC checker',
                description: 'Records QC and re-checks.',
              ),
              FoChoice<String>(
                value: 'owner',
                label: 'Owner',
                description: 'Only an owner can make another owner.',
                enabled: false,
              ),
            ],
          ),
        ),
        DocSection(
          title: 'Choice — several at once',
          child: FoChoiceGroup<int>.multiple(
            semanticLabel: 'Lines they look after',
            values: _lines,
            onChanged: (Set<int> v) => setState(() => _lines = v),
            choices: const <FoChoice<int>>[
              FoChoice<int>(value: 1, label: 'Line 1'),
              FoChoice<int>(value: 2, label: 'Line 2'),
              FoChoice<int>(value: 4, label: 'Line 4'),
            ],
          ),
        ),
        DocSection(
          title: 'PIN pad',
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              child: FoPinPad(
                value: _pin,
                onChanged: (String v) => setState(() => _pin = v),
                errorText:
                    _pin == '0000' ? 'That PIN is wrong. 4 tries left.' : null,
                progressSemanticLabel: (int n, int of) =>
                    '$n of $of digits typed',
                deleteSemanticLabel: 'Delete last digit',
              ),
            ),
          ),
        ),
        DocSection(
          title: 'Scanning',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              FoScanViewfinder(
                title: 'Tap to scan the next bundle',
                caption: 'Or type the number below.',
                semanticLabel: 'Camera. Scan a bundle ticket.',
                onTap: () {},
              ),
              SizedBox(height: context.foSpacing.md),
              FoScanField(
                label: 'Scan or type a bundle number',
                submitLabel: 'Add bundle',
                hintText: 'BNDL-1005-M-001',
                helperText: 'A barcode scanner types the number and presses '
                    'Enter for you.',
                onSubmitted: (String c) => setState(() => _lastScan = c),
              ),
              if (_lastScan != null) ...<Widget>[
                SizedBox(height: context.foSpacing.sm),
                FoInfoBanner(
                  tone: FoBannerTone.success,
                  title: 'Added $_lastScan.',
                  message: 'Size L, 20 pieces.',
                ),
              ],
              SizedBox(height: context.foSpacing.sm),
              const FoInfoBanner(
                tone: FoBannerTone.neutral,
                title: 'Already scanned.',
                message: 'Nothing changed.',
              ),
            ],
          ),
        ),
        DocSection(
          title: 'Reason',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              FoReasonField(
                controller: _reason,
                label: 'Why are you declining?',
                helperText: 'Imran will see this.',
                quickReasons: const <FoQuickReason>[
                  FoQuickReason(
                    label: 'Counted wrong',
                    text: 'The count does not match what is on the floor.',
                  ),
                  FoQuickReason(
                    label: 'Wrong colour',
                    text: 'These pieces are a different colour.',
                  ),
                  FoQuickReason(label: 'Something else', text: ''),
                ],
              ),
              SizedBox(height: context.foSpacing.md),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: FoButton(
                  label: 'Decline… (dialog)',
                  variant: FoButtonVariant.secondary,
                  onPressed: () => FoReasonDialog.show(
                    context,
                    copy: const FoReasonDialogCopy(
                      eyebrow: 'Approvals',
                      title: 'Decline the change to PRS-00415?',
                      message: 'The entry stays as it is. Imran is told.',
                      reasonLabel: 'Why?',
                      confirmLabel: 'Decline change',
                      cancelLabel: 'Keep it waiting',
                      requiredMessage: 'Say why, so Imran knows what to fix.',
                    ),
                    confirmVariant: FoButtonVariant.destructive,
                    consequencesTitle: 'What this does',
                    consequences: const <FoConsequence>[
                      FoConsequence(text: 'PRS-00415 stays at 96 pieces.'),
                      FoConsequence(
                        text: 'Imran Sheikh is told why.',
                        tone: FoStatusTone.info,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        DocSection(
          title: 'Quantities by colour and size',
          child: FoQuantityMatrix(
            columns: const <String>['S', 'M', 'L'],
            ratio: const <int>[1, 2, 2],
            rows: <FoQuantityRow>[
              FoQuantityRow(
                label: 'Deep Navy',
                leading: const FoColourSwatch(color: Color(0xFF1E293B)),
                values: _rows[0],
              ),
              FoQuantityRow(
                label: 'Ecru',
                leading: const FoColourSwatch(color: Color(0xFFE7E2D6)),
                values: _rows[1],
              ),
            ],
            rowErrors: <int, String>{
              if (_rows[1].every((int v) => v == 0))
                1: 'Ecru has no quantities. Type its total, or remove it.',
            },
            onRowChanged: (int r, List<int> v) =>
                setState(() => _rows = List<List<int>>.of(_rows)..[r] = v),
            onCopyToNext: (int r) => setState(
              () => _rows = List<List<int>>.of(_rows)
                ..[r + 1] = List<int>.of(_rows[r]),
            ),
            copy: FoQuantityMatrixCopy(
              rowHeader: 'Colour',
              totalLabel: 'Colour total',
              allRowsLabel: 'All colours',
              ratioLabel: 'Size ratio',
              cellLabel: (String r, String c) => '$r, size $c',
              rowTotalLabel: (String r) =>
                  '$r total. Typing a total splits it by the size ratio.',
              copyLabel: (String r, String n) => 'Copy $r to $n',
            ),
          ),
        ),
        DocSection(
          title: 'A list typed line by line',
          child: FoEntryListEditor(
            columns: const <FoEntryColumn>[
              FoEntryColumn(label: 'Roll'),
              FoEntryColumn(
                label: 'Weight',
                helper: 'As weighed here',
                numeric: true,
              ),
            ],
            lineCount: _rolls.length,
            lineCells: (int i) => <Widget>[
              Text('R-${i + 1}', style: context.foText.numeric),
              Text('${_rolls[i]} kg', style: context.foText.numeric),
            ],
            entryCells: <Widget>[
              Text('R-${_rolls.length + 1}', style: context.foText.numeric),
              Text('—', style: context.foText.numeric),
            ],
            onAdd: () => setState(() => _rolls.add(29.0)),
            addLabel: 'Add roll',
            onRepeatLast: () => setState(() => _rolls.add(_rolls.last)),
            repeatLastLabel: 'Repeat last',
            removeLabel: (int i) => 'Remove roll R-${i + 1}',
            onRemove: (int i) => setState(() => _rolls.removeAt(i)),
            message: 'Enter adds the roll and starts the next one.',
          ),
        ),
      ],
    );
  }
}

/// Figures, records and outcomes, read-only.
class FloorReadouts extends StatelessWidget {
  /// Creates the readouts page.
  const FloorReadouts({super.key});

  @override
  Widget build(BuildContext context) {
    return DocPage(
      title: 'Floor readouts',
      lede: 'What happened, what will happen, and how things stand — every '
          'figure readable in words as well as in a bar.',
      children: <Widget>[
        const DocSection(
          title: 'Proportion bar',
          child: FoProportionBar(
            semanticLabel: '32 passed, 5 to alter, 1 rejected, 2 to check',
            showLegend: true,
            remaining: 2,
            thickness: 12,
            parts: <FoProportionPart>[
              FoProportionPart(
                label: 'Passed',
                value: 32,
                tone: FoStatusTone.success,
              ),
              FoProportionPart(
                label: 'Sent to alter',
                value: 5,
                tone: FoStatusTone.warning,
              ),
              FoProportionPart(
                label: 'Rejected',
                value: 1,
                tone: FoStatusTone.danger,
              ),
            ],
          ),
        ),
        const DocSection(
          title: 'Size strip',
          child: FoSizeValueStrip(
            semanticLabel: 'Loaded so far, by size',
            values: <FoSizeValue>[
              FoSizeValue(
                size: 'S',
                value: '20',
                caption: 'of 20',
                state: FoSizeValueState.complete,
              ),
              FoSizeValue(
                size: 'M',
                value: '20',
                caption: 'of 40',
                state: FoSizeValueState.current,
              ),
              FoSizeValue(
                size: 'L',
                value: '44',
                caption: 'of 42',
                state: FoSizeValueState.flagged,
              ),
              FoSizeValue(size: 'XL', value: '0', caption: 'of 20'),
              FoSizeValue(
                size: 'XXL',
                value: '0',
                state: FoSizeValueState.empty,
              ),
            ],
            total: FoSizeValue(size: 'Total', value: '84'),
          ),
        ),
        DocSection(
          title: 'Before and after',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              for (final FoChangeDiffLayout layout in FoChangeDiffLayout.values)
                Padding(
                  padding: EdgeInsets.only(bottom: context.foSpacing.md),
                  child: FoChangeDiff(
                    layout: layout,
                    copy: const FoChangeDiffCopy(
                      beforeLabel: 'Now',
                      afterLabel: 'After',
                      changeLabel: 'Change',
                      totalLabel: 'Total',
                      measureLabel: 'Pressed',
                    ),
                    changes: const <FoChange>[
                      FoChange(key: 'S', before: 16, after: 16),
                      FoChange(key: 'M', before: 30, after: 30),
                      FoChange(key: 'L', before: 30, after: 18),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const DocSection(
          title: 'What a decision does',
          child: FoConsequenceList(
            title: 'When you submit',
            items: <FoConsequence>[
              FoConsequence(
                figure: '32',
                text: 'go on to Bartek.',
                tone: FoStatusTone.success,
              ),
              FoConsequence(
                figure: '5',
                text: 'go back to Line 1 with their reasons.',
                tone: FoStatusTone.warning,
              ),
              FoConsequence(
                figure: '1',
                text: 'is rejected.',
                tone: FoStatusTone.danger,
              ),
            ],
          ),
        ),
        const DocSection(
          title: 'History',
          child: FoTimeline(
            heading: 'History',
            events: <FoTimelineEvent>[
              FoTimelineEvent(
                event: 'Submitted',
                actor: 'by Imran Sheikh',
                time: '1 Oct, 17:52',
                tone: FoStatusTone.success,
              ),
              FoTimelineEvent(
                event: 'Saved as draft',
                actor: 'by Imran Sheikh',
                time: '1 Oct, 17:50',
                tone: FoStatusTone.primary,
              ),
            ],
          ),
        ),
        DocSection(
          title: 'Line card',
          child: FoMetricCard(
            title: 'Line 3',
            subtitle: 'Anjali Rao',
            status: const FoStatusChip.tone(
              label: 'Behind target',
              tone: FoStatusTone.warning,
            ),
            subject: Row(
              children: <Widget>[
                const FoColourSwatch(color: Color(0xFF5B6E8C)),
                SizedBox(width: context.foSpacing.sm),
                Flexible(
                  child: Text(
                    'Oxford Button-Down · Slate Blue',
                    style: context.foText.label,
                  ),
                ),
              ],
            ),
            metrics: const <FoMetric>[
              FoMetric(label: 'Loaded today', value: '300'),
              FoMetric(label: 'Sewn today', value: '212'),
              FoMetric(label: 'On the line', value: '420', warning: true),
            ],
            meterLabel: 'Efficiency',
            meterValue: 212,
            meterMax: 329,
            meterCaption: '212 of 329 target so far · 64%',
            meterTone: FoStatusTone.warning,
            onTap: () {},
          ),
        ),
        const DocSection(
          title: 'Sewn each hour',
          child: SizedBox(
            height: 140,
            child: FoBarChart(
              compact: true,
              showValues: true,
              targetValue: 47,
              barWidth: 22,
              semanticLabel: 'Pieces sewn each hour on Line 3: 24, 30, 34, '
                  '32, 22, 36, 34. Target 47 an hour.',
              seriesLabels: <String>['Sewn'],
              groups: <FoBarGroup>[
                FoBarGroup(label: '8', values: <num>[24]),
                FoBarGroup(label: '9', values: <num>[30]),
                FoBarGroup(label: '10', values: <num>[34]),
                FoBarGroup(label: '11', values: <num>[32]),
                FoBarGroup(label: '12', values: <num>[22]),
                FoBarGroup(label: '13', values: <num>[36]),
                FoBarGroup(label: '14', values: <num>[34]),
              ],
            ),
          ),
        ),
        DocSection(
          title: 'Have versus need',
          child: FoShortfallCard(
            title: '6% short for cutting',
            message: 'The cutting plan needs more fabric than came in usable.',
            have: 394.8,
            need: 420,
            semanticValue: '394.8 of 420.0 kg usable',
            lines: const <FoShortfallLine>[
              FoShortfallLine(label: 'Needed', value: '420.0 kg'),
              FoShortfallLine(label: 'Usable', value: '394.8 kg'),
              FoShortfallLine(label: 'Short', value: '25.2 kg', emphasis: true),
            ],
            actions: <Widget>[
              FoButton(
                label: 'Open cutting plan',
                variant: FoButtonVariant.secondary,
                onPressed: () {},
              ),
            ],
          ),
        ),
        const DocSection(
          title: 'Cartons this will make',
          child: FoCapacityGrid(
            tiles: <FoCapacityTile>[
              FoCapacityTile(
                label: 'M',
                amount: 20,
                capacity: 20,
                repeat: 2,
                amountLabel: '20 of 20',
                statusLabel: 'Full',
                caption: 'Closed, label ready',
              ),
              FoCapacityTile(
                label: 'L',
                amount: 12,
                capacity: 20,
                amountLabel: '12 of 20',
                statusLabel: 'Filling',
                caption: 'Stays open',
              ),
            ],
          ),
        ),
        DocSection(
          title: 'Checklist',
          child: FoChecklist(
            copy: FoChecklistCopy(
              title: 'Set up Unit 02',
              progressLabel: (int d, int t) => '$d of $t done',
              doneLabel: 'Done',
              hideLabel: 'Hide for now',
            ),
            onHide: () {},
            steps: <FoChecklistStep>[
              FoChecklistStep(
                title: 'Add your sizes',
                done: true,
                doneDescription: '10 sizes: S to XXL, 28 to 40',
                editLabel: 'Edit',
                onEdit: () {},
              ),
              const FoChecklistStep(
                title: 'Add your colours',
                done: false,
                description: 'One tap per colour.',
                body: Text('The colour form opens here.'),
              ),
              FoChecklistStep(
                title: 'Invite your people',
                done: false,
                actionLabel: 'Invite',
                onAction: () {},
              ),
            ],
          ),
        ),
        DocSection(
          title: 'Waiting to send',
          child: FoOutboxItem(
            state: FoOutboxState.needsYou,
            statusLabel: 'Needs you',
            origin: 'Pressing · saved 11:10',
            title: 'Pique Polo',
            figure: '64',
            figureCaption: 'pressed',
            detail: const FoInfoBanner(
              tone: FoBannerTone.warning,
              message: 'Fatima Bano used 8 of the Sage L pieces while you were '
                  'offline. Only 12 are ready now.',
            ),
            actions: <Widget>[
              FoButton(
                label: 'Fix the counts',
                variant: FoButtonVariant.secondary,
                onPressed: () {},
              ),
              FoButton(
                label: 'Send for approval',
                variant: FoButtonVariant.warning,
                onPressed: () {},
              ),
            ],
          ),
        ),
        DocSection(
          title: 'Photos and files',
          child: FoAttachmentGrid(
            items: const <FoAttachment>[
              FoAttachment(
                caption: 'Invoice',
                semanticLabel: 'Open the supplier invoice',
              ),
            ],
            addLabel: 'Take photo',
            onAdd: () {},
          ),
        ),
        DocSection(
          title: 'Label preview',
          child: FoPrintPreview(
            title: 'Label preview',
            spec: '100 × 150 mm · 1 per carton',
            semanticLabel: 'Label for carton CTN-121',
            actions: <Widget>[
              FoButton(
                label: 'Print label',
                variant: FoButtonVariant.secondary,
                icon: Icons.print_outlined,
                onPressed: () {},
              ),
            ],
            child: Padding(
              padding: EdgeInsets.all(context.foSpacing.lg),
              child: Text('CTN-121\nPique Polo · M · 20',
                  style: context.foText.numeric),
            ),
          ),
        ),
      ],
    );
  }
}

/// Menus, page states, people, and help.
class FloorChrome extends StatelessWidget {
  /// Creates the chrome page.
  const FloorChrome({super.key});

  @override
  Widget build(BuildContext context) {
    return DocPage(
      title: 'Lists, states and help',
      lede: 'A settings list, the end of a task, a page that cannot be shown, '
          'the guide pieces, and the two overlays that search.',
      children: <Widget>[
        DocSection(
          title: 'List group',
          child: FoListGroup(
            heading: 'Production stages',
            headingTrailing: 'in production order',
            rows: <Widget>[
              FoListRow(
                title: 'Pressing',
                subtitle: 'ironing and shaping',
                leadingWidget: const FoAvatar(
                  initials: '8',
                  name: 'Stage 8',
                  size: FoAvatarSize.small,
                ),
                trailing: Text('616', style: context.foText.numeric),
                onTap: () {},
              ),
              FoListRow(
                title: 'Help and guides',
                icon: Icons.menu_book_outlined,
                leadingStyle: FoListRowLeading.tile,
                onTap: () {},
              ),
            ],
          ),
        ),
        DocSection(
          title: 'Done',
          child: FoDoneState(
            title: '110 pieces recorded',
            message: 'Pressing is saved for Deep Navy. 36 pieces of this '
                'colour are still waiting to be pressed.',
            icon: Icons.check,
            actions: <Widget>[
              FoButton(
                label: 'Record more pressing',
                variant: FoButtonVariant.primary,
                size: FoButtonSize.large,
                onPressed: () {},
              ),
            ],
          ),
        ),
        DocSection(
          title: 'No access',
          child: SizedBox(
            height: 420,
            child: FoPageState(
              icon: Icons.lock_outline,
              tone: FoStatusTone.info,
              eyebrow: 'No access',
              title: 'Cartons is for packing and owners',
              message: 'Your role, Line supervisor, cannot open it.',
              actions: <Widget>[
                FoButton(
                  label: 'Go to Today',
                  variant: FoButtonVariant.primary,
                  icon: Icons.home_outlined,
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ),
        DocSection(
          title: 'Guide step',
          child: FoGuideStep(
            number: 2,
            title: 'Count by size',
            body: const Text('Press Fill all ready, then change any size '
                'that is different.'),
            media: FoMarkedScreenshot(
              image: ColoredBox(color: context.foColors.surfaceSunken),
              sourceSize: const Size(1440, 1000),
              crop: const Rect.fromLTWH(900, 200, 400, 120),
              semanticLabel: 'The record dialog. Fill all ready is marked 2.',
              markers: const <FoScreenMarker>[
                FoScreenMarker(
                  number: 2,
                  rect: Rect.fromLTWH(1019, 251, 143, 44),
                ),
              ],
            ),
          ),
        ),
        DocSection(
          title: 'Was this helpful?',
          child: FoHelpfulVote(
            onVote: (_) {},
            onSendNote: (_) async {},
            copy: const FoHelpfulVoteCopy(
              question: 'Was this helpful?',
              yesLabel: 'Yes',
              noLabel: 'No',
              thanksYes: 'Thanks. Glad it helped.',
              noPrompt: 'Sorry about that. What were you trying to do?',
              noteLabel: "Optional. Don't add names or phone numbers.",
              sendLabel: 'Send',
              sentMessage: 'Sent. The person who writes the guides will see '
                  'it.',
            ),
          ),
        ),
        DocSection(
          title: 'If something goes wrong',
          child: FoDisclosure(
            title: 'The order is not in the list',
            icon: Icons.warning_amber_outlined,
            iconColor: context.foColors.warning,
            child: const Text('Only running orders with pieces ready show. '
                'Search all orders instead.'),
          ),
        ),
        DocSection(
          title: 'Search and dates',
          child: Wrap(
            spacing: context.foSpacing.sm,
            runSpacing: context.foSpacing.sm,
            children: <Widget>[
              FoButton(
                label: 'Search everything',
                variant: FoButtonVariant.secondary,
                icon: Icons.search,
                onPressed: () => FoSearchPalette.show(
                  context,
                  recentSearches: const <String>['crew', 'PRS-415'],
                  search: (String q) async => <FoSearchGroup>[
                    FoSearchGroup(
                      title: 'Orders',
                      results: <FoSearchResult>[
                        FoSearchResult(
                          title: 'Heavyweight Crew Tee',
                          subtitle: 'JOB-2026-10031 · Kestrel Outfitters',
                          icon: Icons.inventory_2_outlined,
                          onSelected: () {},
                        ),
                      ],
                    ),
                    const FoSearchGroup(
                      title: 'People',
                      results: <FoSearchResult>[],
                      emptyText: 'No people match. Search by first name.',
                    ),
                  ],
                  copy: FoSearchPaletteCopy(
                    fieldLabel: 'Search orders, entries, people',
                    closeLabel: 'Close search',
                    noResultsText: (String q) => 'Nothing matches "$q".',
                    errorText: "Couldn't search. Check the connection.",
                    retryLabel: 'Try again',
                    recentLabel: 'Recent searches',
                    moveHint: 'move',
                    openHint: 'open',
                    footerNote: 'Codes work too: 10031, PRS-415',
                  ),
                ),
              ),
              FoFilterButton(
                value: 'Last 7 days',
                icon: Icons.calendar_today_outlined,
                onPressed: () => FoDateRangePicker.show(
                  context,
                  firstDate: DateTime(2026),
                  lastDate: DateTime(2026, 10, 2),
                  presets: <FoDateRangePreset>[
                    FoDateRangePreset(
                      label: 'Last 7 days',
                      range: DateTimeRange(
                        start: DateTime(2026, 9, 26),
                        end: DateTime(2026, 10, 2),
                      ),
                    ),
                  ],
                  copy: FoDateRangeCopy(
                    title: 'Dates',
                    presetsLabel: 'Quick picks',
                    confirmLabel: 'Use these dates',
                    cancelLabel: 'Cancel',
                    previousMonthLabel: 'Previous month',
                    nextMonthLabel: 'Next month',
                    rangeLabel: (DateTimeRange r) =>
                        '${r.duration.inDays + 1} days',
                  ),
                ),
              ),
              const FoKeyHint('Ctrl K'),
            ],
          ),
        ),
      ],
    );
  }
}

/// Choice, PIN, scan, reason, quantities, line-by-line lists.
@widgetbook.UseCase(
  name: 'Choice group',
  type: FoChoiceGroup,
  path: '06 Production',
)
Widget buildFloorInputs(BuildContext context) => const FloorInputs();

/// Quantities by colour and size, with ratio, copy and totals.
@widgetbook.UseCase(
  name: 'Quantity matrix',
  type: FoQuantityMatrix,
  path: '06 Production',
)
Widget buildQuantityMatrix(BuildContext context) => const FloorInputs();

/// Bars, strips, diffs, histories, cards.
@widgetbook.UseCase(
  name: 'Readouts',
  type: FoProportionBar,
  path: '06 Production',
)
Widget buildFloorReadouts(BuildContext context) => const FloorReadouts();

/// Lists, done and page states, guides, search.
@widgetbook.UseCase(
  name: 'Lists, states and help',
  type: FoListGroup,
  path: '06 Production',
)
Widget buildFloorChrome(BuildContext context) => const FloorChrome();

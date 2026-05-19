import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/vital_colors.dart';
import '../../core/widgets/action_bar.dart';
import '../../core/widgets/back_or_home_button.dart';
import '../../core/widgets/status_pill.dart';
import '../../core/widgets/tag_chip_row.dart';
import '../../core/widgets/tinted_card.dart';
import '../../data/database/app_database.dart';
import '../../domain/health/blood_pressure_status.dart';
import '../../domain/health/heart_rate_status.dart';
import '../../domain/health/reading_advisory.dart';
import '../../domain/health/severity_level.dart';
import '../../domain/health/vital_classifiers.dart';
import '../../domain/models/scan_result.dart';
import '../../domain/tags/reading_with_tags.dart';
import '../../providers.dart';

final _readingByIdProvider =
    FutureProvider.family<ReadingWithTags?, int>((ref, id) async {
  // Re-fetch when the underlying stream emits.
  ref.watch(readingsProvider);
  return ref.read(readingRepositoryProvider).getReadingWithTags(id);
});

class ReadingDetailScreen extends ConsumerWidget {
  final int readingId;
  const ReadingDetailScreen({super.key, required this.readingId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reading = ref.watch(_readingByIdProvider(readingId));
    return Scaffold(
      appBar: AppBar(
        leading: const BackOrHomeButton(),
        title: const Text('Reading'),
      ),
      body: reading.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed: $e')),
        data: (r) => r == null
            ? const Center(child: Text('Not found.'))
            : _Body(readingWithTags: r),
      ),
    );
  }
}

class _Body extends ConsumerStatefulWidget {
  final ReadingWithTags readingWithTags;
  const _Body({required this.readingWithTags});

  Reading get reading => readingWithTags.reading;

  @override
  ConsumerState<_Body> createState() => _BodyState();
}

class _BodyState extends ConsumerState<_Body> {
  bool _editing = false;
  late TextEditingController _sys;
  late TextEditingController _dia;
  late TextEditingController _pulse;
  late DateTime _measuredAt;
  late Set<String> _tags;

  @override
  void initState() {
    super.initState();
    _hydrate(widget.readingWithTags);
  }

  void _hydrate(ReadingWithTags rt) {
    final r = rt.reading;
    _sys = TextEditingController(text: r.systolic?.toString() ?? '');
    _dia = TextEditingController(text: r.diastolic?.toString() ?? '');
    _pulse = TextEditingController(text: r.pulse?.toString() ?? '');
    _measuredAt = r.measuredAt;
    _tags = {...rt.tags};
  }

  @override
  void dispose() {
    _sys.dispose();
    _dia.dispose();
    _pulse.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _measuredAt,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_measuredAt),
    );
    if (time == null || !mounted) return;
    setState(() {
      _measuredAt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _save() async {
    final updated = widget.reading.copyWith(
      systolic: Value(int.tryParse(_sys.text)),
      diastolic: Value(int.tryParse(_dia.text)),
      pulse: Value(int.tryParse(_pulse.text)),
      measuredAt: _measuredAt,
      // Any edit means the source attribution is "manual" — the OCR
      // engine no longer owns this row.
      sourceType: ScannerType.manual,
      isManuallyEdited: true,
    );
    final tagList = _tags.toList();
    await ref.read(readingRepositoryProvider).updateReading(
          updated,
          tags: tagList,
        );
    if (!mounted) return;
    setState(() {
      _hydrate(ReadingWithTags(reading: updated, tags: tagList));
      _editing = false;
    });
  }

  void _cancelEdit() {
    setState(() {
      _hydrate(widget.readingWithTags);
      _editing = false;
    });
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete reading?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await ref.read(readingRepositoryProvider).deleteReading(widget.reading.id);
    if (!mounted) return;
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final sys = int.tryParse(_sys.text);
    final dia = int.tryParse(_dia.text);
    final pulse = int.tryParse(_pulse.text);
    final bpStatus = (sys != null && dia != null)
        ? classifyBloodPressure(systolic: sys, diastolic: dia)
        : null;
    final hrStatus =
        pulse != null ? classifyHeartRate(bpm: pulse) : null;
    final accent =
        bpStatus == null ? SectionAccent.sky : bpStatusColor(bpStatus);
    final advisory = computeAdvisory(
      bp: bpStatus,
      hr: hrStatus,
      tags: _tags,
    );
    // While editing, the row will be saved as manual regardless of where
    // it came from.
    final effectiveSource =
        _editing ? ScannerType.manual : widget.reading.sourceType;

    final sectionStyle = theme.textTheme.labelLarge?.copyWith(
      color: scheme.onSurfaceVariant,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.4,
    );

    return Scaffold(
      bottomNavigationBar: ActionBar(
        children: _editing
            ? [
                ActionButton.tonal(
                  onPressed: _cancelEdit,
                  icon: Icons.close,
                  label: 'Cancel',
                ),
                const SizedBox(width: 12),
                ActionButton.primary(
                  onPressed: _save,
                  icon: Icons.check,
                  label: 'Save',
                ),
              ]
            : [
                ActionButton.danger(
                  onPressed: _delete,
                  icon: Icons.delete_outline,
                  label: 'Delete',
                ),
                const SizedBox(width: 12),
                ActionButton.primary(
                  onPressed: () => setState(() => _editing = true),
                  icon: Icons.edit_outlined,
                  label: 'Edit',
                ),
              ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          if (bpStatus == BloodPressureStatus.crisis) ...[
            _CrisisBanner(),
            const SizedBox(height: 16),
          ],
          // READING (big numbers, category accent)
          Text('READING', style: sectionStyle),
          const SizedBox(height: 8),
          TintedCard(
            accent: accent,
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
            child: _editing
                ? Row(
                    children: [
                      Expanded(child: _NumberField('SYS', _sys, onChanged: () => setState(() {}))),
                      const SizedBox(width: 8),
                      Expanded(child: _NumberField('DIA', _dia, onChanged: () => setState(() {}))),
                      const SizedBox(width: 8),
                      Expanded(child: _NumberField('PR', _pulse, onChanged: () => setState(() {}))),
                    ],
                  )
                : _ReadingDisplay(
                    sys: sys,
                    dia: dia,
                    pulse: pulse,
                    bpStatus: bpStatus,
                    hrStatus: hrStatus,
                  ),
          ),
          if (advisory.bpSubtitle != null) ...[
            const SizedBox(height: 10),
            Text(
              advisory.bpSubtitle!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
          if (advisory.hrSubtitle != null) ...[
            const SizedBox(height: 6),
            Text(
              advisory.hrSubtitle!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: 24),

          // WHEN (date + time picker when editing, static row when reading)
          Text('WHEN', style: sectionStyle),
          const SizedBox(height: 8),
          TintedCard(
            accent: SectionAccent.slate,
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            onTap: _editing ? _pickDate : null,
            child: Row(
              children: [
                Icon(Icons.event,
                    size: 18, color: scheme.onSurfaceVariant),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    DateFormat('EEE, d MMM yyyy   HH:mm').format(_measuredAt),
                    style: theme.textTheme.titleSmall,
                  ),
                ),
                if (_editing)
                  Icon(Icons.edit_calendar,
                      size: 18, color: scheme.onSurfaceVariant),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // SOURCE
          Text('SOURCE', style: sectionStyle),
          const SizedBox(height: 8),
          TintedCard(
            accent: SectionAccent.slate,
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Row(
              children: [
                Icon(_sourceIcon(effectiveSource),
                    size: 18, color: scheme.onSurfaceVariant),
                const SizedBox(width: 10),
                Text(
                  _sourceLabel(effectiveSource),
                  style: theme.textTheme.titleSmall,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // TAGS
          Text('TAGS', style: sectionStyle),
          const SizedBox(height: 8),
          TintedCard(
            accent: SectionAccent.slate,
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
            child: _editing
                ? TagChipRow(
                    selected: _tags,
                    onChanged: (next) => setState(() {
                      _tags
                        ..clear()
                        ..addAll(next);
                    }),
                  )
                : _tags.isEmpty
                    ? Text(
                        'No tags',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      )
                    : Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          for (final tag in _tags)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: scheme.surfaceContainerHighest
                                    .withValues(alpha: 0.6),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                tag,
                                style:
                                    theme.textTheme.labelMedium?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                        ],
                      ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  IconData _sourceIcon(ScannerType s) {
    switch (s) {
      case ScannerType.geminiFlash:
        return Icons.auto_awesome;
      case ScannerType.mlKit:
      case ScannerType.tesseract:
      case ScannerType.tflite:
        return Icons.center_focus_strong;
      case ScannerType.manual:
        return Icons.edit;
    }
  }

  String _sourceLabel(ScannerType s) {
    switch (s) {
      case ScannerType.geminiFlash:
        return 'Gemini Flash';
      case ScannerType.mlKit:
        return 'On-device (ML Kit)';
      case ScannerType.tesseract:
        return 'On-device (Tesseract)';
      case ScannerType.tflite:
        return 'On-device (TFLite)';
      case ScannerType.manual:
        return 'Manual';
    }
  }
}

class _ReadingDisplay extends StatelessWidget {
  final int? sys;
  final int? dia;
  final int? pulse;
  final BloodPressureStatus? bpStatus;
  final HeartRateStatus? hrStatus;
  const _ReadingDisplay({
    required this.sys,
    required this.dia,
    required this.pulse,
    required this.bpStatus,
    required this.hrStatus,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              '${sys ?? '–'}',
              style: theme.textTheme.displayMedium?.copyWith(
                fontWeight: FontWeight.w700,
                height: 1,
                letterSpacing: -2,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                '/',
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w300,
                ),
              ),
            ),
            Text(
              '${dia ?? '–'}',
              style: theme.textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: scheme.onSurfaceVariant,
                height: 1,
              ),
            ),
            const SizedBox(width: 6),
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(
                'mmHg',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
            const Spacer(),
            Icon(Icons.favorite, size: 14, color: scheme.onSurfaceVariant),
            const SizedBox(width: 4),
            Text(
              '${pulse ?? '–'}',
              style: theme.textTheme.titleMedium?.copyWith(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 2),
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                'bpm',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
        if (bpStatus != null || hrStatus != null) ...[
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              if (bpStatus != null)
                StatusPill(
                  label: bpStatus!.label,
                  color: bpStatusColor(bpStatus!),
                ),
              if (hrStatus != null)
                StatusPill(
                  label: 'Pulse · ${hrStatus!.label}',
                  color: hrStatusColor(hrStatus!),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _CrisisBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: severityBackground(SeverityLevel.urgent),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: VitalColors.bpCrisis.withValues(alpha: 0.45),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded,
              color: VitalColors.bpCrisis),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hypertensive crisis range',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: VitalColors.bpCrisis,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Values above 180/120 mmHg can be urgent. Consider re-measuring and seeking medical advice if symptoms are present.',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NumberField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final VoidCallback onChanged;
  const _NumberField(this.label, this.controller, {required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: Theme.of(context).textTheme.labelSmall,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      ),
      onChanged: (_) => onChanged(),
    );
  }
}

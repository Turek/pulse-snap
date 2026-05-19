import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/utils/bp_category.dart';
import '../../core/widgets/action_bar.dart';
import '../../core/widgets/back_or_home_button.dart';
import '../../core/widgets/tinted_card.dart';
import '../../data/database/app_database.dart';
import '../../domain/models/scan_result.dart';
import '../../providers.dart';

final _readingByIdProvider =
    FutureProvider.family<Reading?, int>((ref, id) async {
  ref.watch(readingsProvider);
  final list =
      await ref.read(readingRepositoryProvider).watchAllReadings().first;
  for (final r in list) {
    if (r.id == id) return r;
  }
  return null;
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
            : _Body(reading: r),
      ),
    );
  }
}

class _Body extends ConsumerStatefulWidget {
  final Reading reading;
  const _Body({required this.reading});

  @override
  ConsumerState<_Body> createState() => _BodyState();
}

class _BodyState extends ConsumerState<_Body> {
  bool _editing = false;
  late TextEditingController _sys;
  late TextEditingController _dia;
  late TextEditingController _pulse;
  late TextEditingController _notes;
  late DateTime _measuredAt;

  @override
  void initState() {
    super.initState();
    _hydrate(widget.reading);
  }

  void _hydrate(Reading r) {
    _sys = TextEditingController(text: r.systolic?.toString() ?? '');
    _dia = TextEditingController(text: r.diastolic?.toString() ?? '');
    _pulse = TextEditingController(text: r.pulse?.toString() ?? '');
    _notes = TextEditingController(text: r.notes ?? '');
    _measuredAt = r.measuredAt;
  }

  @override
  void dispose() {
    _sys.dispose();
    _dia.dispose();
    _pulse.dispose();
    _notes.dispose();
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
      notes: Value(_notes.text.isEmpty ? null : _notes.text),
      measuredAt: _measuredAt,
      // Any edit means the source attribution is "manual" — the OCR
      // engine no longer owns this row.
      sourceType: ScannerType.manual,
      isManuallyEdited: true,
    );
    await ref.read(readingRepositoryProvider).updateReading(updated);
    if (!mounted) return;
    setState(() {
      _hydrate(updated);
      _editing = false;
    });
  }

  void _cancelEdit() {
    setState(() {
      _hydrate(widget.reading);
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
    final cat = bpCategory(sys, dia);
    final accent = cat == BpCategory.unknown ? SectionAccent.sky : cat.color;
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
                    accent: accent,
                    category: cat,
                  ),
          ),
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

          // NOTES
          Text('NOTES', style: sectionStyle),
          const SizedBox(height: 8),
          TintedCard(
            accent: SectionAccent.slate,
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
            child: TextField(
              controller: _notes,
              enabled: _editing,
              maxLines: 3,
              minLines: 2,
              decoration: InputDecoration(
                hintText: _editing ? 'Add a note…' : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 8),
              ),
              style: theme.textTheme.bodyMedium,
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
  final Color accent;
  final BpCategory category;
  const _ReadingDisplay({
    required this.sys,
    required this.dia,
    required this.pulse,
    required this.accent,
    required this.category,
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
        if (category != BpCategory.unknown) ...[
          const SizedBox(height: 14),
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                    color: accent, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Text(
                category.label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ],
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

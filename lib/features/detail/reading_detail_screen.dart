import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/extensions/datetime_extensions.dart';
import '../../core/utils/bp_category.dart';
import '../../core/widgets/back_or_home_button.dart';
import '../../data/database/app_database.dart';
import '../../providers.dart';

final _readingByIdProvider =
    FutureProvider.family<Reading?, int>((ref, id) async {
  // Re-fetch when the underlying list changes.
  ref.watch(readingsProvider);
  final list = await ref.read(readingRepositoryProvider).watchAllReadings().first;
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
        data: (r) =>
            r == null ? const Center(child: Text('Not found.')) : _Body(reading: r),
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
  late final TextEditingController _notes;
  bool _editing = false;
  late TextEditingController _sys, _dia, _pulse;

  @override
  void initState() {
    super.initState();
    _notes = TextEditingController(text: widget.reading.notes ?? '');
    _sys = TextEditingController(text: widget.reading.systolic?.toString() ?? '');
    _dia = TextEditingController(text: widget.reading.diastolic?.toString() ?? '');
    _pulse =
        TextEditingController(text: widget.reading.pulse?.toString() ?? '');
  }

  @override
  void dispose() {
    _notes.dispose();
    _sys.dispose();
    _dia.dispose();
    _pulse.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final r = widget.reading.copyWith(
      systolic: Value(int.tryParse(_sys.text)),
      diastolic: Value(int.tryParse(_dia.text)),
      pulse: Value(int.tryParse(_pulse.text)),
      notes: Value(_notes.text.isEmpty ? null : _notes.text),
      isManuallyEdited: true,
    );
    await ref.read(readingRepositoryProvider).updateReading(r);
    if (!mounted) return;
    setState(() => _editing = false);
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
    final r = widget.reading;
    final cat = bpCategory(r.systolic, r.diastolic);
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!_editing)
            Text(
              '${r.systolic ?? '–'} / ${r.diastolic ?? '–'}',
              style: theme.textTheme.displayLarge?.copyWith(color: cat.color),
            )
          else
            Row(
              children: [
                Expanded(child: _Num('SYS', _sys)),
                const SizedBox(width: 8),
                Expanded(child: _Num('DIA', _dia)),
                const SizedBox(width: 8),
                Expanded(child: _Num('PR', _pulse)),
              ],
            ),
          if (!_editing) ...[
            Row(
              children: [
                const Icon(Icons.favorite, color: Colors.redAccent),
                const SizedBox(width: 4),
                Text('${r.pulse ?? '–'}', style: theme.textTheme.headlineMedium),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Chip(
            label: Text(cat.label),
            backgroundColor: cat.color.withValues(alpha: 0.15),
            side: BorderSide(color: cat.color),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Chip(label: Text('Source: ${r.sourceType.name}')),
              const SizedBox(width: 8),
              if (r.isManuallyEdited)
                const Chip(label: Text('Edited')),
            ],
          ),
          const SizedBox(height: 12),
          Text(r.measuredAt.formatDateTime(),
              style: theme.textTheme.bodyMedium),
          if (r.ocrConfidence != null) ...[
            const SizedBox(height: 12),
            LinearProgressIndicator(value: r.ocrConfidence!.clamp(0, 1)),
            Text('OCR confidence: ${(r.ocrConfidence! * 100).toStringAsFixed(0)}%',
                style: theme.textTheme.labelSmall),
          ],
          const SizedBox(height: 16),
          TextField(
            controller: _notes,
            decoration: const InputDecoration(
              labelText: 'Notes',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              if (_editing)
                Expanded(
                  child: FilledButton(
                    onPressed: _save,
                    child: const Text('Save'),
                  ),
                )
              else
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => setState(() => _editing = true),
                    icon: const Icon(Icons.edit),
                    label: const Text('Edit'),
                  ),
                ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _delete,
                  icon: const Icon(Icons.delete, color: Colors.red),
                  label: const Text('Delete', style: TextStyle(color: Colors.red)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Num extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  const _Num(this.label, this.controller);
  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      textAlign: TextAlign.center,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }
}

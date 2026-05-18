import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/utils/bp_category.dart';
import '../../data/database/app_database.dart';
import '../../domain/models/scan_result.dart';
import '../../providers.dart';
import 'review_provider.dart';

class ReviewScreen extends ConsumerWidget {
  final File? imageFile;
  const ReviewScreen({super.key, this.imageFile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (imageFile == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Review')),
        body: const Center(child: Text('No image to review.')),
      );
    }
    final scan = ref.watch(scanResultProvider(imageFile!));
    return scan.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('Review')),
        body: Center(child: Text('Scan failed: $e')),
      ),
      data: (result) => ReviewForm(imageFile: imageFile!, initial: result),
    );
  }
}

class ReviewForm extends ConsumerStatefulWidget {
  final File imageFile;
  final ScanResult initial;
  const ReviewForm({super.key, required this.imageFile, required this.initial});

  @override
  ConsumerState<ReviewForm> createState() => ReviewFormState();
}

class ReviewFormState extends ConsumerState<ReviewForm> {
  late final TextEditingController _sys;
  late final TextEditingController _dia;
  late final TextEditingController _pulse;
  final _notes = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _sys = TextEditingController(
        text: widget.initial.systolic?.toString() ?? '');
    _dia = TextEditingController(
        text: widget.initial.diastolic?.toString() ?? '');
    _pulse = TextEditingController(
        text: widget.initial.pulse?.toString() ?? '');
  }

  @override
  void dispose() {
    _sys.dispose();
    _dia.dispose();
    _pulse.dispose();
    _notes.dispose();
    super.dispose();
  }

  ScanResult get _current => ScanResult(
        systolic: int.tryParse(_sys.text),
        diastolic: int.tryParse(_dia.text),
        pulse: int.tryParse(_pulse.text),
        confidence: widget.initial.confidence,
        source: widget.initial.source,
      );

  bool get _canSave => _current.isComplete && _current.isPlausible;

  bool get _wasEdited =>
      _current.systolic != widget.initial.systolic ||
      _current.diastolic != widget.initial.diastolic ||
      _current.pulse != widget.initial.pulse;

  Future<void> _save() async {
    if (!_canSave || _saving) return;
    setState(() => _saving = true);
    final repo = ref.read(readingRepositoryProvider);
    final r = _current;
    try {
      await repo.saveReading(ReadingsCompanion.insert(
        measuredAt: DateTime.now(),
        sourceType: r.source,
        systolic: Value(r.systolic),
        diastolic: Value(r.diastolic),
        pulse: Value(r.pulse),
        ocrConfidence: Value(r.confidence),
        notes: _notes.text.isEmpty ? const Value.absent() : Value(_notes.text),
        isManuallyEdited: Value(_wasEdited),
      ));
      try {
        if (await widget.imageFile.exists()) {
          await widget.imageFile.delete();
        }
      } catch (_) {/* best-effort cleanup */}
      if (!mounted) return;
      context.go('/');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Save failed: $e')));
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = _current;
    final cat = bpCategory(r.systolic, r.diastolic);
    final lowConfidence = widget.initial.confidence < 0.75;

    return Scaffold(
      appBar: AppBar(title: const Text('Review Reading')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(widget.imageFile, height: 160, fit: BoxFit.cover),
              ),
              const SizedBox(height: 12),
              Text(
                'Detected by: ${widget.initial.source.name}',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              if (lowConfidence)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.warning_amber, color: Colors.amber),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                              'Low confidence — please check values'),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(child: _NumberField(label: 'SYS', controller: _sys, onChanged: () => setState(() {}))),
                  const SizedBox(width: 8),
                  Expanded(child: _NumberField(label: 'DIA', controller: _dia, onChanged: () => setState(() {}))),
                  const SizedBox(width: 8),
                  Expanded(child: _NumberField(label: 'PR', controller: _pulse, onChanged: () => setState(() {}))),
                ],
              ),
              const SizedBox(height: 16),
              if (cat != BpCategory.unknown)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Chip(
                    label: Text(cat.label),
                    backgroundColor: cat.color.withValues(alpha: 0.15),
                    side: BorderSide(color: cat.color),
                  ),
                ),
              const SizedBox(height: 16),
              TextField(
                controller: _notes,
                decoration: const InputDecoration(
                  labelText: 'Notes',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _canSave && !_saving ? _save : null,
                child: _saving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save Reading'),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: _saving ? null : () => context.go('/scan'),
                child: const Text('Retake Photo'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NumberField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final VoidCallback onChanged;
  const _NumberField({
    required this.label,
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.displaySmall,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      onChanged: (_) => onChanged(),
    );
  }
}

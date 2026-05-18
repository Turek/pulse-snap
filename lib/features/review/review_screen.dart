import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/utils/bp_category.dart';
import '../../data/database/app_database.dart';
import '../../domain/models/scan_result.dart';
import '../../domain/scanner/scan_artifacts.dart';
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
    final scan = ref.watch(scanArtifactsProvider(imageFile!));
    return scan.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('Review')),
        body: Center(child: Text('Scan failed: $e')),
      ),
      data: (artifacts) =>
          ReviewForm(imageFile: imageFile!, artifacts: artifacts),
    );
  }
}

class ReviewForm extends ConsumerStatefulWidget {
  final File imageFile;
  final ScanArtifacts artifacts;
  const ReviewForm({
    super.key,
    required this.imageFile,
    required this.artifacts,
  });

  // Test seam: build a ReviewForm without running the orchestrator.
  factory ReviewForm.withInitial({
    Key? key,
    required File imageFile,
    required ScanResult initial,
  }) =>
      ReviewForm(
        key: key,
        imageFile: imageFile,
        artifacts: ScanArtifacts(result: initial),
      );

  ScanResult get initial => artifacts.result;

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
      // Crop/binarized debug files are in the OS temp dir — best-effort sweep.
      _deleteIfExists(widget.artifacts.cropImage);
      _deleteIfExists(widget.artifacts.binarizedImage);
      if (!mounted) return;
      context.go('/');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Save failed: $e')));
      setState(() => _saving = false);
    }
  }

  Future<void> _deleteIfExists(File? f) async {
    if (f == null) return;
    try {
      if (await f.exists()) await f.delete();
    } catch (_) {}
  }

  void _setSlot({int? sys, int? dia, int? pr}) {
    setState(() {
      if (sys != null) _sys.text = sys.toString();
      if (dia != null) _dia.text = dia.toString();
      if (pr != null) _pulse.text = pr.toString();
    });
  }

  @override
  Widget build(BuildContext context) {
    final r = _current;
    final cat = bpCategory(r.systolic, r.diastolic);
    final lowConfidence = widget.initial.confidence < 0.75;
    final theme = Theme.of(context);

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
                child: Image.file(widget.imageFile,
                    height: 160, fit: BoxFit.cover),
              ),
              const SizedBox(height: 12),
              Text(
                'Detected by: ${widget.initial.source.name}',
                style: theme.textTheme.labelLarge,
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
                          child: Text('Low confidence — please check values'),
                        ),
                      ],
                    ),
                  ),
                ),
              if (widget.artifacts.candidateNumbers.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text('Tap a candidate to fill a slot',
                    style: theme.textTheme.labelMedium),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: widget.artifacts.candidateNumbers
                      .toSet()
                      .map((n) => _CandidateChip(
                            value: n,
                            onSys: () => _setSlot(sys: n),
                            onDia: () => _setSlot(dia: n),
                            onPulse: () => _setSlot(pr: n),
                          ))
                      .toList(),
                ),
              ],
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                      child: _NumberField(
                          label: 'SYS',
                          controller: _sys,
                          onChanged: () => setState(() {}))),
                  const SizedBox(width: 8),
                  Expanded(
                      child: _NumberField(
                          label: 'DIA',
                          controller: _dia,
                          onChanged: () => setState(() {}))),
                  const SizedBox(width: 8),
                  Expanded(
                      child: _NumberField(
                          label: 'PR',
                          controller: _pulse,
                          onChanged: () => setState(() {}))),
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
                onPressed: _saving
                    ? null
                    : () {
                        // Pop back to the live CameraScreen instead of
                        // pushing a fresh /scan route — the camera
                        // controller is still initialised so there's no
                        // black-screen reinit gap.
                        if (context.canPop()) {
                          context.pop();
                        } else {
                          context.go('/scan');
                        }
                      },
                child: const Text('Retake Photo'),
              ),
              const SizedBox(height: 24),
              ExpansionTile(
                title: const Text('OCR debug'),
                tilePadding: EdgeInsets.zero,
                childrenPadding: const EdgeInsets.only(bottom: 8),
                children: [
                  if (widget.artifacts.cropImage != null) ...[
                    Text('Cropped LCD region',
                        style: theme.textTheme.labelSmall),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(widget.artifacts.cropImage!),
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (widget.artifacts.binarizedImage != null) ...[
                    Text(
                      'Binarized (otsu=${widget.artifacts.otsuThreshold}, '
                      'inverted=${widget.artifacts.otsuInverted})',
                      style: theme.textTheme.labelSmall,
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(widget.artifacts.binarizedImage!),
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (widget.artifacts.tesseractRawText != null) ...[
                    Text('Tesseract raw',
                        style: theme.textTheme.labelSmall),
                    SelectableText(
                      widget.artifacts.tesseractRawText!,
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (widget.artifacts.mlkitRawText != null &&
                      widget.artifacts.mlkitRawText!.isNotEmpty) ...[
                    Text('ML Kit raw', style: theme.textTheme.labelSmall),
                    SelectableText(
                      widget.artifacts.mlkitRawText!,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CandidateChip extends StatelessWidget {
  final int value;
  final VoidCallback onSys;
  final VoidCallback onDia;
  final VoidCallback onPulse;
  const _CandidateChip({
    required this.value,
    required this.onSys,
    required this.onDia,
    required this.onPulse,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: (s) {
        switch (s) {
          case 'sys':
            onSys();
          case 'dia':
            onDia();
          case 'pr':
            onPulse();
        }
      },
      itemBuilder: (_) => const [
        PopupMenuItem(value: 'sys', child: Text('Set as SYS')),
        PopupMenuItem(value: 'dia', child: Text('Set as DIA')),
        PopupMenuItem(value: 'pr', child: Text('Set as Pulse')),
      ],
      child: Chip(label: Text(value.toString())),
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

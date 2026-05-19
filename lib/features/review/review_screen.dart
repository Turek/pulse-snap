import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/vital_colors.dart';
import '../../core/widgets/action_bar.dart';
import '../../core/widgets/back_or_home_button.dart';
import '../../core/widgets/gemini_key_action.dart';
import '../../core/widgets/status_pill.dart';
import '../../core/widgets/tag_chip_row.dart';
import '../../data/database/app_database.dart';
import '../../domain/health/blood_pressure_status.dart';
import '../../domain/health/heart_rate_status.dart';
import '../../domain/health/reading_advisory.dart';
import '../../domain/health/severity_level.dart';
import '../../domain/health/vital_classifiers.dart';
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
        appBar: AppBar(
          leading: const BackOrHomeButton(),
          title: const Text('Review'),
        ),
        body: const Center(child: Text('No image to review.')),
      );
    }
    final scan = ref.watch(scanArtifactsProvider(imageFile!));
    return scan.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(
          leading: const BackOrHomeButton(),
          title: const Text('Review'),
        ),
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
  final Set<String> _tags = <String>{};
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
      final now = DateTime.now();
      await repo.saveReading(
        Reading(
          id: 0,
          userId: 'default',
          measuredAt: now,
          systolic: r.systolic,
          diastolic: r.diastolic,
          pulse: r.pulse,
          sourceType: r.source,
          ocrConfidence: r.confidence,
          isManuallyEdited: _wasEdited,
          createdAt: now,
        ),
        tags: _tags.toList(),
      );
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
    final bpStatus = (r.systolic != null && r.diastolic != null)
        ? classifyBloodPressure(systolic: r.systolic!, diastolic: r.diastolic!)
        : null;
    final hrStatus =
        r.pulse != null ? classifyHeartRate(bpm: r.pulse!) : null;
    final lowConfidence = widget.initial.confidence < 0.75;
    final theme = Theme.of(context);
    final usedGemini = widget.initial.source == ScannerType.geminiFlash;
    final advisory = computeAdvisory(
      bp: bpStatus,
      hr: hrStatus,
      tags: _tags,
    );

    return Scaffold(
      appBar: AppBar(
        leading: const BackOrHomeButton(),
        title: const Text('Review Reading'),
        actions: const [GeminiKeyAction()],
      ),
      bottomNavigationBar: ActionBar(
        children: [
          ActionButton.tonal(
            onPressed: _saving
                ? null
                : () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/scan');
                    }
                  },
            icon: Icons.replay,
            label: 'Retake',
          ),
          const SizedBox(width: 12),
          ActionButton.primary(
            onPressed: _canSave && !_saving ? _save : null,
            icon: _saving ? Icons.hourglass_top : Icons.check,
            label: _saving ? 'Saving…' : 'Save',
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (bpStatus == BloodPressureStatus.crisis) ...[
                _CrisisBanner(),
                const SizedBox(height: 12),
              ],
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(widget.imageFile,
                    height: 160, fit: BoxFit.cover),
              ),
              const SizedBox(height: 12),
              Text(
                usedGemini
                    ? 'Detected by Gemini Flash'
                    : 'Detected on-device (${widget.initial.source.name})',
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
              if (bpStatus != null || hrStatus != null)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      if (bpStatus != null)
                        StatusPill(
                          label: bpStatus.label,
                          color: bpStatusColor(bpStatus),
                        ),
                      if (hrStatus != null)
                        StatusPill(
                          label: 'Pulse · ${hrStatus.label}',
                          color: hrStatusColor(hrStatus),
                        ),
                    ],
                  ),
                ),
              if (advisory.bpSubtitle != null) ...[
                const SizedBox(height: 8),
                Text(
                  advisory.bpSubtitle!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              if (advisory.hrSubtitle != null) ...[
                const SizedBox(height: 8),
                Text(
                  advisory.hrSubtitle!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Text('TAGS', style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.4,
              )),
              const SizedBox(height: 8),
              TagChipRow(
                selected: _tags,
                onChanged: (next) => setState(() {
                  _tags
                    ..clear()
                    ..addAll(next);
                }),
              ),
              const SizedBox(height: 16),
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
                  'Values above 180/120 mmHg can be urgent. Re-measure and seek medical advice if symptoms are present.',
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

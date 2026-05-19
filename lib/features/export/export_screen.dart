import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';

import '../../domain/models/scan_result.dart';
import '../../domain/tags/reading_with_tags.dart';
import '../../providers.dart';
import 'export_provider.dart';

class ExportScreen extends ConsumerWidget {
  const ExportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final opts = ref.watch(exportOptionsProvider);
    final readingsAsync = ref.watch(readingsProvider);
    final isoFmt = DateFormat('yyyy-MM-dd');

    Future<void> pickCustomRange() async {
      final now = DateTime.now();
      final picked = await showDateRangePicker(
        context: context,
        firstDate: DateTime(now.year - 2),
        lastDate: now,
        initialDateRange: DateTimeRange(start: opts.from, end: opts.to),
      );
      if (picked != null) {
        ref
            .read(exportOptionsProvider.notifier)
            .setCustomRange(picked.start, picked.end);
      }
    }

    final customLabel = opts.preset == ExportRangePreset.custom
        ? 'Custom: ${isoFmt.format(opts.from)} → ${isoFmt.format(opts.to)}'
        : 'Custom range…';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Export'),
        surfaceTintColor: Theme.of(context).colorScheme.primary,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          Text('Date range',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          _PresetGroup(
            selected: opts.preset,
            customLabel: customLabel,
            onSelect: (p) {
              if (p == ExportRangePreset.custom) {
                pickCustomRange();
              } else {
                ref.read(exportOptionsProvider.notifier).setPreset(p);
              }
            },
          ),
          const SizedBox(height: 20),
          Text('Sources',
              style: Theme.of(context).textTheme.titleMedium),
          CheckboxListTile(
            value: opts.includeScanned,
            onChanged: (v) => ref
                .read(exportOptionsProvider.notifier)
                .setIncludeScanned(v ?? true),
            title: const Text('Scanned'),
            controlAffinity: ListTileControlAffinity.leading,
          ),
          CheckboxListTile(
            value: opts.includeManual,
            onChanged: (v) => ref
                .read(exportOptionsProvider.notifier)
                .setIncludeManual(v ?? true),
            title: const Text('Manual'),
            controlAffinity: ListTileControlAffinity.leading,
          ),
          const SizedBox(height: 24),
          _GeneratePreviewButton(
            enabled: readingsAsync.hasValue,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const _PreviewPage()),
            ),
          ),
        ],
      ),
    );
  }
}

class _PresetGroup extends StatelessWidget {
  final ExportRangePreset selected;
  final String customLabel;
  final ValueChanged<ExportRangePreset> onSelect;

  const _PresetGroup({
    required this.selected,
    required this.customLabel,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    const items = <(ExportRangePreset, String)>[
      (ExportRangePreset.last7Days, 'Last 7 days'),
      (ExportRangePreset.last14Days, 'Last 14 days'),
      (ExportRangePreset.last30Days, 'Last 30 days'),
    ];

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border.all(color: scheme.outlineVariant),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            _PresetRow(
              preset: items[i].$1,
              label: items[i].$2,
              selected: selected == items[i].$1,
              onTap: () => onSelect(items[i].$1),
            ),
            Divider(height: 1, color: scheme.outlineVariant),
          ],
          _PresetRow(
            preset: ExportRangePreset.custom,
            label: customLabel,
            selected: selected == ExportRangePreset.custom,
            onTap: () => onSelect(ExportRangePreset.custom),
          ),
        ],
      ),
    );
  }
}

class _PresetRow extends StatelessWidget {
  final ExportRangePreset preset;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _PresetRow({
    required this.preset,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = selected ? scheme.primary : Colors.transparent;
    final fg = selected ? scheme.onPrimary : scheme.onSurfaceVariant;
    final weight = selected ? FontWeight.w600 : FontWeight.w500;

    return Material(
      color: bg,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(_iconFor(preset), size: 20, color: fg),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: fg,
                    fontWeight: weight,
                    fontSize: 15,
                  ),
                  softWrap: true,
                ),
              ),
              if (selected)
                Icon(Icons.check, size: 18, color: fg)
              else if (preset == ExportRangePreset.custom)
                Icon(Icons.chevron_right, size: 20, color: fg),
            ],
          ),
        ),
      ),
    );
  }
}

class _GeneratePreviewButton extends StatelessWidget {
  final bool enabled;
  final VoidCallback onPressed;
  const _GeneratePreviewButton({
    required this.enabled,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: enabled ? onPressed : null,
        icon: const Icon(Icons.picture_as_pdf),
        label: const Text('Generate preview'),
        style: FilledButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          minimumSize: const Size.fromHeight(56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}

IconData _iconFor(ExportRangePreset p) {
  switch (p) {
    case ExportRangePreset.last7Days:
    case ExportRangePreset.last14Days:
    case ExportRangePreset.last30Days:
      return Icons.calendar_today_outlined;
    case ExportRangePreset.custom:
      return Icons.date_range_outlined;
  }
}

class _PreviewPage extends ConsumerWidget {
  const _PreviewPage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final opts = ref.watch(exportOptionsProvider);
    final service = ref.watch(reportExportServiceProvider);
    final readingsAsync = ref.watch(readingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Report preview')),
      body: readingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed to load: $e')),
        data: (all) {
          final filtered = filterReadings(all, opts);
          return PdfPreview(
            build: (format) => service.buildPdfReport(
              from: opts.from,
              to: opts.to,
              readings: filtered,
            ),
            canChangeOrientation: false,
            canChangePageFormat: false,
            allowPrinting: true,
            allowSharing: true,
            pdfFileName: 'pulsesnap-report.pdf',
          );
        },
      ),
    );
  }
}

/// Public for testability.
List<ReadingWithTags> filterReadings(
  List<ReadingWithTags> all,
  ExportOptions opts,
) {
  final fromMs = DateTime(opts.from.year, opts.from.month, opts.from.day)
      .millisecondsSinceEpoch;
  final toMs = DateTime(opts.to.year, opts.to.month, opts.to.day, 23, 59, 59)
      .millisecondsSinceEpoch;
  return all.where((r) {
    final ts = r.reading.measuredAt.millisecondsSinceEpoch;
    if (ts < fromMs || ts > toMs) return false;
    final isManual = r.reading.sourceType == ScannerType.manual;
    if (isManual && !opts.includeManual) return false;
    if (!isManual && !opts.includeScanned) return false;
    return true;
  }).toList();
}

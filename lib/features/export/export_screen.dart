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
    final dateFmt = DateFormat.yMMMd();

    return Scaffold(
      appBar: AppBar(title: const Text('Export')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          Text('Date range',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          SegmentedButton<ExportRangePreset>(
            segments: const [
              ButtonSegment(
                  value: ExportRangePreset.last7Days, label: Text('7 days')),
              ButtonSegment(
                  value: ExportRangePreset.last14Days, label: Text('14 days')),
              ButtonSegment(
                  value: ExportRangePreset.last30Days, label: Text('30 days')),
              ButtonSegment(
                  value: ExportRangePreset.custom, label: Text('Custom')),
            ],
            selected: {opts.preset},
            onSelectionChanged: (s) async {
              final preset = s.first;
              if (preset == ExportRangePreset.custom) {
                final now = DateTime.now();
                final picked = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime(now.year - 2),
                  lastDate: now,
                  initialDateRange: DateTimeRange(
                    start: opts.from,
                    end: opts.to,
                  ),
                );
                if (picked != null) {
                  ref
                      .read(exportOptionsProvider.notifier)
                      .setCustomRange(picked.start, picked.end);
                }
              } else {
                ref.read(exportOptionsProvider.notifier).setPreset(preset);
              }
            },
          ),
          const SizedBox(height: 8),
          Text(
            '${dateFmt.format(opts.from)} – ${dateFmt.format(opts.to)}',
            style: Theme.of(context).textTheme.bodyMedium,
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
          const SizedBox(height: 8),
          SwitchListTile(
            value: opts.includeCharts,
            onChanged: (v) => ref
                .read(exportOptionsProvider.notifier)
                .setIncludeCharts(v),
            title: const Text('Include charts'),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            icon: const Icon(Icons.picture_as_pdf),
            label: const Text('Generate preview'),
            onPressed: readingsAsync.maybeWhen(
              data: (_) => () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const _PreviewPage(),
                  ),
                );
              },
              orElse: () => null,
            ),
          ),
        ],
      ),
    );
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

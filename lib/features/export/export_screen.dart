import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';

import '../../core/widgets/action_bar.dart';
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

    Widget presetButton({
      required ExportRangePreset preset,
      required String label,
      required VoidCallback onTap,
    }) {
      final selected = opts.preset == preset;
      final btn = selected
          ? ActionButton.primary(
              onPressed: onTap,
              icon: _iconFor(preset),
              label: label,
            )
          : ActionButton.tonal(
              onPressed: onTap,
              icon: _iconFor(preset),
              label: label,
            );
      // ActionButton internally wraps itself in Expanded, so it must live
      // in a Row (or Flex) parent. Keying the Row on selection forces a
      // fresh widget subtree when intent changes, avoiding TextStyle
      // inherit-flag lerp errors during the Material state animation.
      return Row(
        key: ValueKey('preset-row-$preset-$selected'),
        children: [btn],
      );
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
          presetButton(
            preset: ExportRangePreset.last7Days,
            label: 'Last 7 days',
            onTap: () => ref
                .read(exportOptionsProvider.notifier)
                .setPreset(ExportRangePreset.last7Days),
          ),
          const SizedBox(height: 8),
          presetButton(
            preset: ExportRangePreset.last14Days,
            label: 'Last 14 days',
            onTap: () => ref
                .read(exportOptionsProvider.notifier)
                .setPreset(ExportRangePreset.last14Days),
          ),
          const SizedBox(height: 8),
          presetButton(
            preset: ExportRangePreset.last30Days,
            label: 'Last 30 days',
            onTap: () => ref
                .read(exportOptionsProvider.notifier)
                .setPreset(ExportRangePreset.last30Days),
          ),
          const SizedBox(height: 8),
          presetButton(
            preset: ExportRangePreset.custom,
            label: customLabel,
            onTap: pickCustomRange,
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
          const SizedBox(height: 16),
          FilledButton.icon(
            icon: const Icon(Icons.picture_as_pdf),
            label: const Text('Generate preview'),
            style: FilledButton.styleFrom(
              backgroundColor:
                  Theme.of(context).colorScheme.primaryContainer,
              foregroundColor:
                  Theme.of(context).colorScheme.onPrimaryContainer,
              minimumSize: const Size.fromHeight(52),
            ),
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

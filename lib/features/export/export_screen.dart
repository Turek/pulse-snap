import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/action_bar.dart';
import '../../core/widgets/tinted_card.dart';
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
    final sectionStyle = AppTextStyles.sectionCaps(context);

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
      } else {
        ref
            .read(exportOptionsProvider.notifier)
            .setPreset(ExportRangePreset.custom);
      }
    }

    final filteredCount = readingsAsync.maybeWhen(
      data: (all) => filterReadings(all, opts).length,
      orElse: () => 0,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Export to PDF')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        children: [
          Text('DATE RANGE', style: sectionStyle),
          const SizedBox(height: 8),
          _DateRangeGroup(
            selected: opts.preset,
            from: opts.from,
            to: opts.to,
            onSelect: (p) {
              if (p == ExportRangePreset.custom) {
                pickCustomRange();
              } else {
                ref.read(exportOptionsProvider.notifier).setPreset(p);
              }
            },
          ),

          const SizedBox(height: 24),

          Text('SOURCES', style: sectionStyle),
          const SizedBox(height: 4),
          SwitchListTile(
            secondary: const Icon(Icons.center_focus_strong_outlined),
            title: const Text('Scanned'),
            subtitle: const Text('On-device OCR & Gemini Flash readings'),
            value: opts.includeScanned,
            onChanged: (v) => ref
                .read(exportOptionsProvider.notifier)
                .setIncludeScanned(v),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.edit_outlined),
            title: const Text('Manual'),
            subtitle: const Text('Readings you entered by hand'),
            value: opts.includeManual,
            onChanged: (v) =>
                ref.read(exportOptionsProvider.notifier).setIncludeManual(v),
          ),

          const SizedBox(height: 12),

          _SummaryCard(opts: opts, count: filteredCount),
        ],
      ),
      bottomNavigationBar: ActionBar(
        children: [
          ActionButton.tonal(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: Icons.close,
            label: 'Cancel',
          ),
          const SizedBox(width: 12),
          ActionButton.primary(
            onPressed: (readingsAsync.hasValue &&
                    (opts.includeScanned || opts.includeManual))
                ? () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const _PreviewPage()),
                    )
                : null,
            icon: Icons.visibility_outlined,
            label: 'Generate preview',
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────
// Vertical preset group
// ────────────────────────────────────────────────────────────

class _DateRangeGroup extends StatelessWidget {
  final ExportRangePreset selected;
  final DateTime from;
  final DateTime to;
  final ValueChanged<ExportRangePreset> onSelect;

  const _DateRangeGroup({
    required this.selected,
    required this.from,
    required this.to,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    const presets = ExportRangePreset.values;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        children: [
          for (var i = 0; i < presets.length; i++) ...[
            _DateRangeRow(
              preset: presets[i],
              selected: presets[i] == selected,
              currentFrom: from,
              currentTo: to,
              onTap: () => onSelect(presets[i]),
              isFirst: i == 0,
              isLast: i == presets.length - 1,
            ),
            if (i < presets.length - 1)
              Divider(
                height: 1,
                thickness: 1,
                color: scheme.outlineVariant.withValues(alpha: 0.7),
              ),
          ],
        ],
      ),
    );
  }
}

class _DateRangeRow extends StatelessWidget {
  final ExportRangePreset preset;
  final bool selected;
  final DateTime currentFrom;
  final DateTime currentTo;
  final VoidCallback onTap;
  final bool isFirst;
  final bool isLast;

  const _DateRangeRow({
    required this.preset,
    required this.selected,
    required this.currentFrom,
    required this.currentTo,
    required this.onTap,
    required this.isFirst,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final f = DateFormat('MMM d, yyyy');
    final now = DateTime.now();
    final (start, end) = _resolveRange(preset, now, currentFrom, currentTo);

    final subtitle = preset == ExportRangePreset.custom && !selected
        ? 'Pick start & end date'
        : '${f.format(start)} – ${f.format(end)}';

    final radius = BorderRadius.vertical(
      top: isFirst ? const Radius.circular(15) : Radius.zero,
      bottom: isLast ? const Radius.circular(15) : Radius.zero,
    );

    return Material(
      color: selected ? scheme.primaryContainer : Colors.transparent,
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 16, 14),
          child: Row(
            children: [
              Radio<bool>(
                value: true,
                groupValue: selected ? true : null,
                onChanged: (_) => onTap(),
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _label(preset),
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: selected
                            ? scheme.onPrimaryContainer
                            : scheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: selected
                            ? scheme.onPrimaryContainer.withValues(alpha: 0.75)
                            : scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (preset == ExportRangePreset.custom)
                Icon(
                  Icons.event_outlined,
                  size: 20,
                  color: selected
                      ? scheme.onPrimaryContainer
                      : scheme.onSurfaceVariant,
                ),
            ],
          ),
        ),
      ),
    );
  }

  static String _label(ExportRangePreset p) {
    switch (p) {
      case ExportRangePreset.last7Days:
        return '7 days';
      case ExportRangePreset.last14Days:
        return '14 days';
      case ExportRangePreset.last30Days:
        return '30 days';
      case ExportRangePreset.custom:
        return 'Custom time';
    }
  }

  static (DateTime, DateTime) _resolveRange(
    ExportRangePreset p,
    DateTime now,
    DateTime currentFrom,
    DateTime currentTo,
  ) {
    switch (p) {
      case ExportRangePreset.last7Days:
        return (now.subtract(const Duration(days: 7)), now);
      case ExportRangePreset.last14Days:
        return (now.subtract(const Duration(days: 14)), now);
      case ExportRangePreset.last30Days:
        return (now.subtract(const Duration(days: 30)), now);
      case ExportRangePreset.custom:
        return (currentFrom, currentTo);
    }
  }
}

// ────────────────────────────────────────────────────────────
// Summary card
// ────────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  final ExportOptions opts;
  final int count;
  const _SummaryCard({required this.opts, required this.count});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final f = DateFormat('MMM d, yyyy');
    final sources = <String>[
      if (opts.includeScanned) 'Scanned',
      if (opts.includeManual) 'Manual',
    ];

    final title = '$count ${count == 1 ? 'reading' : 'readings'} will be included';
    final subtitle = '${f.format(opts.from)} – ${f.format(opts.to)} · '
        '${sources.isEmpty ? 'No sources selected' : sources.join(' + ')}';

    return TintedCard(
      accent: SectionAccent.slate,
      padding: const EdgeInsets.fromLTRB(14, 14, 16, 14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.picture_as_pdf_outlined,
              color: scheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────
// Preview
// ────────────────────────────────────────────────────────────

class _PreviewPage extends ConsumerWidget {
  const _PreviewPage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final opts = ref.watch(exportOptionsProvider);
    final service = ref.watch(reportExportServiceProvider);
    final readingsAsync = ref.watch(readingsProvider);
    final scheme = Theme.of(context).colorScheme;

    Future<Uint8List> buildPdf() async {
      final all = await ref.read(readingsProvider.future);
      final filtered = filterReadings(all, opts);
      return service.buildPdfReport(
        from: opts.from,
        to: opts.to,
        readings: filtered,
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Report preview'),
        actions: [
          _PreviewActionIcon(
            icon: Icons.share_outlined,
            tooltip: 'Share',
            onPressed: () async {
              final bytes = await buildPdf();
              await Printing.sharePdf(
                bytes: bytes,
                filename: 'pulsesnap-report.pdf',
              );
            },
          ),
          _PreviewActionIcon(
            icon: Icons.print_outlined,
            tooltip: 'Print',
            onPressed: () => Printing.layoutPdf(
              onLayout: (_) => buildPdf(),
              name: 'pulsesnap-report.pdf',
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
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
            canDebug: false,
            allowPrinting: true,
            allowSharing: true,
            pdfFileName: 'pulsesnap-report.pdf',
            actionBarTheme: PdfActionBarTheme(
              backgroundColor: scheme.primaryContainer,
              iconColor: scheme.onPrimaryContainer,
              height: 56,
            ),
          );
        },
      ),
    );
  }
}

/// DESIGN.md-styled icon button used in the preview AppBar — pill chip
/// with `primary-container` background + `on-primary-container` icon, so
/// the share/print affordances are always visible regardless of how the
/// underlying `PdfPreview` decides to render its own action bar.
class _PreviewActionIcon extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  const _PreviewActionIcon({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: IconButton.filledTonal(
        tooltip: tooltip,
        onPressed: onPressed,
        icon: Icon(icon, size: 20),
        style: IconButton.styleFrom(
          backgroundColor: scheme.primaryContainer,
          foregroundColor: scheme.onPrimaryContainer,
          shape: const StadiumBorder(),
          minimumSize: const Size(40, 40),
        ),
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

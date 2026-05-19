import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/export/pdf_report_service.dart';
import '../../domain/export/report_export_service.dart';

/// Three quick presets plus a custom range.
enum ExportRangePreset { last7Days, last14Days, last30Days, custom }

class ExportOptions {
  final ExportRangePreset preset;
  final DateTime from;
  final DateTime to;
  final bool includeScanned;
  final bool includeManual;

  const ExportOptions({
    required this.preset,
    required this.from,
    required this.to,
    required this.includeScanned,
    required this.includeManual,
  });

  static ExportOptions defaults() {
    final now = DateTime.now();
    return ExportOptions(
      preset: ExportRangePreset.last7Days,
      from: now.subtract(const Duration(days: 7)),
      to: now,
      includeScanned: true,
      includeManual: true,
    );
  }

  ExportOptions copyWith({
    ExportRangePreset? preset,
    DateTime? from,
    DateTime? to,
    bool? includeScanned,
    bool? includeManual,
  }) {
    return ExportOptions(
      preset: preset ?? this.preset,
      from: from ?? this.from,
      to: to ?? this.to,
      includeScanned: includeScanned ?? this.includeScanned,
      includeManual: includeManual ?? this.includeManual,
    );
  }
}

class ExportOptionsNotifier extends Notifier<ExportOptions> {
  @override
  ExportOptions build() => ExportOptions.defaults();

  void setPreset(ExportRangePreset preset) {
    final now = DateTime.now();
    switch (preset) {
      case ExportRangePreset.last7Days:
        state = state.copyWith(
            preset: preset, from: now.subtract(const Duration(days: 7)), to: now);
      case ExportRangePreset.last14Days:
        state = state.copyWith(
            preset: preset,
            from: now.subtract(const Duration(days: 14)),
            to: now);
      case ExportRangePreset.last30Days:
        // TODO: revisit chart density at 30-day range — may need binning.
        state = state.copyWith(
            preset: preset,
            from: now.subtract(const Duration(days: 30)),
            to: now);
      case ExportRangePreset.custom:
        state = state.copyWith(preset: preset);
    }
  }

  void setCustomRange(DateTime from, DateTime to) {
    state = state.copyWith(
        preset: ExportRangePreset.custom, from: from, to: to);
  }

  void setIncludeScanned(bool v) =>
      state = state.copyWith(includeScanned: v);
  void setIncludeManual(bool v) =>
      state = state.copyWith(includeManual: v);
}

final exportOptionsProvider =
    NotifierProvider<ExportOptionsNotifier, ExportOptions>(
        ExportOptionsNotifier.new);

/// Factory: returns a PdfReportService. Charts are always included.
final reportExportServiceProvider = Provider<IReportExportService>((ref) {
  return PdfReportService();
});

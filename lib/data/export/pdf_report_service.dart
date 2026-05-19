import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../domain/export/report_export_service.dart';
import '../../domain/health/blood_pressure_status.dart';
import '../../domain/health/heart_rate_status.dart';
import '../../domain/health/vital_classifiers.dart';
import '../../domain/models/scan_result.dart';
import '../../domain/tags/reading_with_tags.dart';
import 'pdf_chart_painter.dart';

const _footerText =
    'This report contains home-monitored readings recorded in PulseSnap. '
    'It is intended to support review and discussion with a clinician and is not a diagnosis.';

class PdfReportService implements IReportExportService {
  final bool includeChart;
  final bool compress;
  PdfReportService({this.includeChart = true, this.compress = true});

  @override
  Future<Uint8List> buildPdfReport({
    required DateTime from,
    required DateTime to,
    required List<ReadingWithTags> readings,
  }) async {
    final doc = pw.Document(compress: compress);
    final sorted = [...readings]
      ..sort((a, b) => a.reading.measuredAt.compareTo(b.reading.measuredAt));

    final summary = _Summary.compute(sorted);
    final sources = _sourceLabels(sorted);

    final headerFmt = DateFormat('yyyy-MM-dd');
    final rowFmt = DateFormat('yyyy-MM-dd HH:mm');
    final genFmt = DateFormat('yyyy-MM-dd HH:mm');

    final pageTheme = pw.PageTheme(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(28, 28, 28, 36),
      buildBackground: (ctx) => pw.Positioned(
        bottom: 12,
        left: 28,
        right: 28,
        child: pw.Text(
          _footerText,
          style: const pw.TextStyle(
            color: PdfColors.grey600,
            fontSize: 7.5,
          ),
          textAlign: pw.TextAlign.center,
        ),
      ),
    );

    // ---- Page 1: summary ----
    doc.addPage(
      pw.Page(
        pageTheme: pageTheme,
        build: (ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'PulseSnap Blood Pressure & Pulse Report',
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 6),
            pw.Text(
              '${headerFmt.format(from)} to ${headerFmt.format(to)}',
              style: const pw.TextStyle(fontSize: 10),
            ),
            pw.SizedBox(height: 2),
            pw.Text(
              'Generated at ${genFmt.format(DateTime.now())}',
              style: const pw.TextStyle(
                fontSize: 9,
                color: PdfColors.grey700,
              ),
            ),
            pw.SizedBox(height: 2),
            pw.Text(
              'Data sources: ${sources.isEmpty ? "-" : sources.join(", ")}',
              style: const pw.TextStyle(
                fontSize: 9,
                color: PdfColors.grey700,
              ),
            ),
            pw.SizedBox(height: 14),
            _summaryGrid(summary),
            pw.SizedBox(height: 14),
            if (includeChart) ...[
              pw.Text(
                'Trend',
                style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 4),
              buildTrendChart(sorted, from: from, to: to, height: 200),
              pw.SizedBox(height: 12),
            ],
            _morningEveningSummary(sorted),
          ],
        ),
      ),
    );

    // ---- Page 2+: detail table ----
    final tableRows = <List<String>>[];
    for (final r in sorted.reversed) {
      final reading = r.reading;
      String bpStatus = '';
      String hrStatus = '';
      if (reading.systolic != null && reading.diastolic != null) {
        bpStatus = classifyBloodPressure(
          systolic: reading.systolic!,
          diastolic: reading.diastolic!,
        ).label;
      }
      if (reading.pulse != null) {
        hrStatus = classifyHeartRate(bpm: reading.pulse!).label;
      }
      tableRows.add([
        rowFmt.format(reading.measuredAt),
        reading.systolic?.toString() ?? '',
        reading.diastolic?.toString() ?? '',
        reading.pulse?.toString() ?? '',
        bpStatus,
        hrStatus,
        r.tags.join(', '),
        _sourceLabel(reading.sourceType),
      ]);
    }

    doc.addPage(
      pw.MultiPage(
        pageTheme: pageTheme,
        build: (ctx) => [
          pw.Text(
            'Readings',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.TableHelper.fromTextArray(
            headers: const [
              'Date/Time',
              'SYS',
              'DIA',
              'Pulse',
              'BP Status',
              'HR Status',
              'Tags',
              'Source',
            ],
            data: tableRows,
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 9,
              color: PdfColors.white,
            ),
            headerDecoration:
                const pw.BoxDecoration(color: PdfColors.blueGrey700),
            cellStyle: const pw.TextStyle(fontSize: 8.5),
            cellAlignments: const {
              0: pw.Alignment.centerLeft,
              1: pw.Alignment.centerRight,
              2: pw.Alignment.centerRight,
              3: pw.Alignment.centerRight,
              4: pw.Alignment.centerLeft,
              5: pw.Alignment.centerLeft,
              6: pw.Alignment.centerLeft,
              7: pw.Alignment.centerLeft,
            },
            columnWidths: const {
              0: pw.FixedColumnWidth(78),
              1: pw.FixedColumnWidth(28),
              2: pw.FixedColumnWidth(28),
              3: pw.FixedColumnWidth(34),
              4: pw.FixedColumnWidth(60),
              5: pw.FixedColumnWidth(56),
              6: pw.FlexColumnWidth(2),
              7: pw.FixedColumnWidth(52),
            },
            cellPadding:
                const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
            border: pw.TableBorder.all(
              color: PdfColors.grey300,
              width: 0.4,
            ),
          ),
        ],
      ),
    );

    return doc.save();
  }

  pw.Widget _summaryGrid(_Summary s) {
    pw.Widget card(String label, String value) => pw.Container(
          padding: const pw.EdgeInsets.all(8),
          decoration: pw.BoxDecoration(
            color: PdfColors.grey100,
            borderRadius:
                const pw.BorderRadius.all(pw.Radius.circular(6)),
            border: pw.Border.all(
              color: PdfColors.grey300,
              width: 0.5,
            ),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(label,
                  style: const pw.TextStyle(
                      fontSize: 8, color: PdfColors.grey700)),
              pw.SizedBox(height: 3),
              pw.Text(value,
                  style: pw.TextStyle(
                      fontSize: 13, fontWeight: pw.FontWeight.bold)),
            ],
          ),
        );

    final cards = [
      card('Average systolic', s.avgSys?.toStringAsFixed(0) ?? '-'),
      card('Average diastolic', s.avgDia?.toStringAsFixed(0) ?? '-'),
      card('Average pulse', s.avgPulse?.toStringAsFixed(0) ?? '-'),
      card('Highest BP', s.highest ?? '-'),
      card('Lowest BP', s.lowest ?? '-'),
      card('Readings', s.count.toString()),
    ];

    return pw.Wrap(
      spacing: 8,
      runSpacing: 8,
      children: cards
          .map((c) => pw.SizedBox(width: 165, child: c))
          .toList(growable: false),
    );
  }

  pw.Widget _morningEveningSummary(List<ReadingWithTags> readings) {
    final morning = <ReadingWithTags>[];
    final evening = <ReadingWithTags>[];
    for (final r in readings) {
      if (r.reading.measuredAt.hour < 12) {
        morning.add(r);
      } else {
        evening.add(r);
      }
    }
    final m = _Summary.compute(morning);
    final e = _Summary.compute(evening);

    String fmt(double? avg) => avg == null ? '-' : avg.toStringAsFixed(0);

    pw.Widget col(String label, _Summary s) => pw.Expanded(
          child: pw.Container(
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey50,
              borderRadius:
                  const pw.BorderRadius.all(pw.Radius.circular(6)),
              border: pw.Border.all(
                color: PdfColors.grey300,
                width: 0.5,
              ),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(label,
                    style: pw.TextStyle(
                        fontSize: 10, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Avg BP: ${fmt(s.avgSys)}/${fmt(s.avgDia)}',
                  style: const pw.TextStyle(fontSize: 9),
                ),
                pw.Text(
                  'Avg pulse: ${fmt(s.avgPulse)}',
                  style: const pw.TextStyle(fontSize: 9),
                ),
                pw.Text(
                  'Readings: ${s.count}',
                  style: const pw.TextStyle(
                      fontSize: 8, color: PdfColors.grey700),
                ),
              ],
            ),
          ),
        );

    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        col('Morning (before 12:00)', m),
        pw.SizedBox(width: 8),
        col('Evening (12:00 and later)', e),
      ],
    );
  }
}

class _Summary {
  final double? avgSys;
  final double? avgDia;
  final double? avgPulse;
  final String? highest;
  final String? lowest;
  final int count;

  _Summary({
    required this.avgSys,
    required this.avgDia,
    required this.avgPulse,
    required this.highest,
    required this.lowest,
    required this.count,
  });

  static _Summary compute(List<ReadingWithTags> readings) {
    final sys = <int>[];
    final dia = <int>[];
    final pulse = <int>[];
    ReadingWithTags? highRow;
    ReadingWithTags? lowRow;

    for (final r in readings) {
      final s = r.reading.systolic;
      final d = r.reading.diastolic;
      final p = r.reading.pulse;
      if (s != null) sys.add(s);
      if (d != null) dia.add(d);
      if (p != null) pulse.add(p);

      if (s != null && d != null) {
        if (highRow == null || s > (highRow.reading.systolic ?? 0)) {
          highRow = r;
        }
        if (lowRow == null || s < (lowRow.reading.systolic ?? 1 << 30)) {
          lowRow = r;
        }
      }
    }

    double? avg(List<int> xs) =>
        xs.isEmpty ? null : xs.reduce((a, b) => a + b) / xs.length;

    String? pair(ReadingWithTags? r) {
      if (r == null) return null;
      return '${r.reading.systolic}/${r.reading.diastolic}';
    }

    return _Summary(
      avgSys: avg(sys),
      avgDia: avg(dia),
      avgPulse: avg(pulse),
      highest: pair(highRow),
      lowest: pair(lowRow),
      count: readings.length,
    );
  }
}

String _sourceLabel(ScannerType t) =>
    t == ScannerType.manual ? 'Manual' : 'Scanned';

List<String> _sourceLabels(List<ReadingWithTags> readings) {
  final set = <String>{};
  for (final r in readings) {
    set.add(_sourceLabel(r.reading.sourceType));
  }
  final list = set.toList()..sort();
  return list;
}

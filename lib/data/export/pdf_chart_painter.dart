import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../domain/tags/reading_with_tags.dart';

/// Renders a sys/dia/pulse line chart inside a PDF page. Uses
/// [pw.CustomPaint] so the chart works offline with no flutter widget
/// capture step.
pw.Widget buildTrendChart(
  List<ReadingWithTags> readings, {
  required DateTime from,
  required DateTime to,
  double height = 200,
}) {
  // Sort ascending by measuredAt for a left-to-right timeline.
  final sorted = [...readings]
    ..sort((a, b) => a.reading.measuredAt.compareTo(b.reading.measuredAt));

  final dateFmt = DateFormat('MM-dd');
  pw.Widget legendDot(PdfColor color, String label) => pw.Row(
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          pw.Container(
            width: 8,
            height: 8,
            decoration: pw.BoxDecoration(
              color: color,
              shape: pw.BoxShape.circle,
            ),
          ),
          pw.SizedBox(width: 4),
          pw.Text(label, style: const pw.TextStyle(fontSize: 8)),
          pw.SizedBox(width: 10),
        ],
      );

  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Row(
        children: [
          legendDot(PdfColors.red700, 'Systolic'),
          legendDot(PdfColors.blue700, 'Diastolic'),
          legendDot(PdfColors.green700, 'Pulse'),
          pw.Spacer(),
          pw.Container(
            width: 14,
            height: 0,
            decoration: const pw.BoxDecoration(
              border: pw.Border(
                top: pw.BorderSide(color: PdfColors.orange300, width: 0.6),
              ),
            ),
          ),
          pw.SizedBox(width: 4),
          pw.Text('120 / 130 / 140 sys',
              style: const pw.TextStyle(
                  fontSize: 7, color: PdfColors.grey700)),
        ],
      ),
      pw.SizedBox(height: 4),
      pw.Container(
        height: height,
        width: double.infinity,
        child: pw.CustomPaint(
          painter: (canvas, size) {
            _ChartRenderer(
              readings: sorted,
              from: from,
              to: to,
            ).paint(canvas, size);
          },
        ),
      ),
      pw.SizedBox(height: 2),
      pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 4),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(dateFmt.format(from),
                style: const pw.TextStyle(
                    fontSize: 7, color: PdfColors.grey700)),
            pw.Text(dateFmt.format(to),
                style: const pw.TextStyle(
                    fontSize: 7, color: PdfColors.grey700)),
          ],
        ),
      ),
    ],
  );
}

class _ChartRenderer {
  final List<ReadingWithTags> readings;
  final DateTime from;
  final DateTime to;

  _ChartRenderer({
    required this.readings,
    required this.from,
    required this.to,
  });

  // ignore: avoid_dynamic_calls
  void paint(dynamic canvas, PdfPoint size) {
    final w = size.x;
    final h = size.y;

    const padLeft = 32.0;
    const padRight = 8.0;
    const padTop = 8.0;
    const padBottom = 22.0;

    final plotLeft = padLeft;
    final plotRight = w - padRight;
    final plotTop = padTop;
    final plotBottom = h - padBottom;
    final plotW = plotRight - plotLeft;
    final plotH = plotBottom - plotTop;

    // Y range: 0 → max(sys) rounded up to nearest 10, min 160.
    int maxSys = 160;
    for (final r in readings) {
      final s = r.reading.systolic;
      if (s != null && s > maxSys) maxSys = s;
    }
    final yMax = ((maxSys + 10) / 10).ceil() * 10;

    // X range in ms.
    final xStart = from.millisecondsSinceEpoch;
    final xEnd = to.millisecondsSinceEpoch;
    final xSpan = (xEnd - xStart).clamp(1, 1 << 62).toDouble();

    double xFor(DateTime t) =>
        plotLeft + ((t.millisecondsSinceEpoch - xStart) / xSpan) * plotW;
    double yFor(num v) => plotBottom - (v / yMax) * plotH;

    // Axes (light grey).
    canvas
      ..setStrokeColor(PdfColors.grey400)
      ..setLineWidth(0.5)
      ..moveTo(plotLeft, plotTop)
      ..lineTo(plotLeft, plotBottom)
      ..lineTo(plotRight, plotBottom)
      ..strokePath();

    // Y gridlines every 20.
    canvas
      ..setStrokeColor(PdfColors.grey200)
      ..setLineWidth(0.3);
    for (var v = 0; v <= yMax; v += 20) {
      final y = yFor(v);
      canvas
        ..moveTo(plotLeft, y)
        ..lineTo(plotRight, y)
        ..strokePath();
    }

    // Reference lines at 120 / 130 / 140 (sys) and 80 / 90 (dia), dashed.
    void dashed(double y, PdfColor color) {
      canvas
        ..setStrokeColor(color)
        ..setLineWidth(0.5)
        ..setLineDashPattern(<num>[3, 3]);
      const segs = 60;
      final dx = (plotRight - plotLeft) / segs;
      for (var i = 0; i < segs; i++) {
        if (i.isEven) {
          canvas
            ..moveTo(plotLeft + i * dx, y)
            ..lineTo(plotLeft + (i + 1) * dx, y)
            ..strokePath();
        }
      }
      canvas.setLineDashPattern(<num>[]);
    }

    for (final v in const [120, 130, 140]) {
      if (v <= yMax) dashed(yFor(v), PdfColors.orange300);
    }
    for (final v in const [80, 90]) {
      if (v <= yMax) dashed(yFor(v), PdfColors.blue200);
    }

    if (readings.isEmpty) return;

    // Plot the three series.
    void plotSeries(int? Function(ReadingWithTags) get, PdfColor color) {
      canvas
        ..setStrokeColor(color)
        ..setLineWidth(1.0);
      var started = false;
      for (final r in readings) {
        final v = get(r);
        if (v == null) continue;
        final x = xFor(r.reading.measuredAt);
        final y = yFor(v);
        if (!started) {
          canvas.moveTo(x, y);
          started = true;
        } else {
          canvas.lineTo(x, y);
        }
      }
      if (started) canvas.strokePath();

      // Dots.
      canvas.setFillColor(color);
      for (final r in readings) {
        final v = get(r);
        if (v == null) continue;
        final x = xFor(r.reading.measuredAt);
        final y = yFor(v);
        canvas
          ..drawEllipse(x, y, 1.5, 1.5)
          ..fillPath();
      }
    }

    plotSeries((r) => r.reading.systolic, PdfColors.red700);
    plotSeries((r) => r.reading.diastolic, PdfColors.blue700);
    plotSeries((r) => r.reading.pulse, PdfColors.green700);

    // Legend labels are rendered as a sibling Row outside the canvas
    // (see buildTrendChart wrapper) — drawing text on raw PdfGraphics
    // requires a PdfFont we cannot reach from CustomPaint without the
    // owning document.
  }
}

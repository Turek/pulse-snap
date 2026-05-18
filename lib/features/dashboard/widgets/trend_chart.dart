import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/bp_colours.dart';
import '../../../core/widgets/tinted_card.dart';
import '../../../data/database/app_database.dart';

/// Compact sparkline-style trend wrapped in a [TintedCard] so it shares
/// the visual treatment of every other dashboard section. Three smooth
/// lines distinguished by both colour AND dash pattern.
class TrendChart extends StatelessWidget {
  final List<Reading> readings;
  const TrendChart({super.key, required this.readings});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return TintedCard(
      accent: SectionAccent.sky,
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Wrap(
              spacing: 12,
              children: [
                _LegendDot(
                  color: BpSeriesColors.systolic,
                  label: 'SYS',
                  pattern: _LegendPattern.solid,
                ),
                _LegendDot(
                  color: BpSeriesColors.diastolic,
                  label: 'DIA',
                  pattern: _LegendPattern.dashed,
                ),
                _LegendDot(
                  color: BpSeriesColors.pulse,
                  label: 'Pulse',
                  pattern: _LegendPattern.dotted,
                ),
              ],
            ),
          ),
          SizedBox(
            height: 96,
            child: readings.isEmpty
                ? Center(
                    child: Text(
                      'No readings yet',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  )
                : _buildChart(),
          ),
        ],
      ),
    );
  }

  Widget _buildChart() {
    final sorted = [...readings]
      ..sort((a, b) => a.measuredAt.compareTo(b.measuredAt));

    FlSpot pt(int i, int? v) => FlSpot(i.toDouble(), (v ?? 0).toDouble());

    final sys = <FlSpot>[];
    final dia = <FlSpot>[];
    final pulse = <FlSpot>[];
    for (var i = 0; i < sorted.length; i++) {
      sys.add(pt(i, sorted[i].systolic));
      dia.add(pt(i, sorted[i].diastolic));
      pulse.add(pt(i, sorted[i].pulse));
    }

    return LineChart(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
      LineChartData(
        minY: 40,
        maxY: 200,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: const FlTitlesData(show: false),
        lineTouchData: LineTouchData(
          handleBuiltInTouches: true,
          touchTooltipData: LineTouchTooltipData(
            fitInsideHorizontally: true,
            getTooltipItems: (spots) => spots
                .map((s) => LineTooltipItem(
                      s.y.toStringAsFixed(0),
                      TextStyle(
                        color: s.bar.color,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ))
                .toList(),
          ),
        ),
        lineBarsData: [
          _series(sys, BpSeriesColors.systolic, dash: null, withFill: true),
          _series(dia, BpSeriesColors.diastolic, dash: [5, 4]),
          _series(pulse, BpSeriesColors.pulse, dash: [2, 3]),
        ],
      ),
    );
  }

  LineChartBarData _series(
    List<FlSpot> spots,
    Color color, {
    List<int>? dash,
    bool withFill = false,
  }) =>
      LineChartBarData(
        spots: spots,
        color: color,
        barWidth: 2,
        isCurved: true,
        curveSmoothness: 0.3,
        dashArray: dash,
        dotData: const FlDotData(show: false),
        belowBarData: withFill
            ? BarAreaData(show: true, color: color.withValues(alpha: 0.08))
            : null,
      );
}

enum _LegendPattern { solid, dashed, dotted }

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  final _LegendPattern pattern;
  const _LegendDot({
    required this.color,
    required this.label,
    required this.pattern,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 16,
          height: 2,
          child: CustomPaint(painter: _LinePainter(color, pattern)),
        ),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }
}

class _LinePainter extends CustomPainter {
  final Color color;
  final _LegendPattern pattern;
  _LinePainter(this.color, this.pattern);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2;
    switch (pattern) {
      case _LegendPattern.solid:
        canvas.drawLine(Offset(0, size.height / 2),
            Offset(size.width, size.height / 2), paint);
      case _LegendPattern.dashed:
        const dash = 4.0, gap = 3.0;
        double x = 0;
        while (x < size.width) {
          canvas.drawLine(Offset(x, size.height / 2),
              Offset((x + dash).clamp(0, size.width), size.height / 2), paint);
          x += dash + gap;
        }
      case _LegendPattern.dotted:
        paint.style = PaintingStyle.fill;
        for (var x = 0.0; x < size.width; x += 4) {
          canvas.drawCircle(Offset(x, size.height / 2), 1, paint);
        }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

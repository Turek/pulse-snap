import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/bp_colours.dart';
import '../../../data/database/app_database.dart';

/// Compact sparkline-style trend: three smooth lines, no axes, no card,
/// no legend. Lives directly in the page background.
class TrendChart extends StatelessWidget {
  final List<Reading> readings;
  const TrendChart({super.key, required this.readings});

  @override
  Widget build(BuildContext context) {
    if (readings.isEmpty) {
      return SizedBox(
        height: 96,
        child: Center(
          child: Text(
            'No readings yet',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ),
      );
    }

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

    return SizedBox(
      height: 96,
      child: LineChart(
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
            _series(sys, BpSeriesColors.systolic),
            _series(dia, BpSeriesColors.diastolic),
            _series(pulse, BpSeriesColors.pulse),
          ],
        ),
      ),
    );
  }

  LineChartBarData _series(List<FlSpot> spots, Color color) =>
      LineChartBarData(
        spots: spots,
        color: color,
        barWidth: 2,
        isCurved: true,
        curveSmoothness: 0.3,
        dotData: const FlDotData(show: false),
      );
}

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/bp_colours.dart';
import '../../../data/database/app_database.dart';

class TrendChart extends StatelessWidget {
  final List<Reading> readings;
  const TrendChart({super.key, required this.readings});

  @override
  Widget build(BuildContext context) {
    if (readings.isEmpty) {
      return SizedBox(
        height: 220,
        child: Center(
          child: Text('No readings yet',
              style: Theme.of(context).textTheme.bodyMedium),
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
      height: 240,
      child: LineChart(
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeInOut,
        LineChartData(
          minY: 40,
          maxY: 200,
          gridData: const FlGridData(show: true, horizontalInterval: 40),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(),
            rightTitles: const AxisTitles(),
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: true, reservedSize: 32, interval: 40),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                interval: (sorted.length / 4).clamp(1, 30).toDouble(),
                getTitlesWidget: (value, meta) {
                  final i = value.toInt();
                  if (i < 0 || i >= sorted.length) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      DateFormat('dd MMM').format(sorted[i].measuredAt),
                      style: const TextStyle(fontSize: 10),
                    ),
                  );
                },
              ),
            ),
          ),
          extraLinesData: ExtraLinesData(
            horizontalLines: [
              HorizontalLine(y: 120, color: BpSeriesColors.systolic.withValues(alpha: 0.3), dashArray: [4, 4]),
              HorizontalLine(y: 80, color: BpSeriesColors.diastolic.withValues(alpha: 0.3), dashArray: [4, 4]),
            ],
          ),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              fitInsideHorizontally: true,
              getTooltipItems: (spots) => spots
                  .map((s) => LineTooltipItem(
                        s.y.toStringAsFixed(0),
                        TextStyle(color: s.bar.color, fontWeight: FontWeight.bold),
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

  LineChartBarData _series(List<FlSpot> spots, Color color) => LineChartBarData(
        spots: spots,
        color: color,
        barWidth: 2.5,
        isCurved: false,
        dotData: const FlDotData(show: false),
      );
}

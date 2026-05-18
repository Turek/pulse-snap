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
        height: 160,
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

    final scheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 8, bottom: 8),
              child: Wrap(
                spacing: 12,
                children: [
                  _LegendDot(color: BpSeriesColors.systolic, label: 'SYS'),
                  _LegendDot(color: BpSeriesColors.diastolic, label: 'DIA'),
                  _LegendDot(color: BpSeriesColors.pulse, label: 'Pulse'),
                ],
              ),
            ),
            SizedBox(
              height: 150,
              child: LineChart(
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOutCubic,
                LineChartData(
                  minY: 40,
                  maxY: 200,
                  gridData: FlGridData(
                    show: true,
                    horizontalInterval: 40,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (_) => FlLine(
                      color: scheme.outlineVariant.withValues(alpha: 0.4),
                      strokeWidth: 1,
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(),
                    rightTitles: const AxisTitles(),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        interval: 40,
                        getTitlesWidget: (v, _) => Text(
                          v.toInt().toString(),
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 22,
                        interval: (sorted.length / 4).clamp(1, 30).toDouble(),
                        getTitlesWidget: (value, meta) {
                          final i = value.toInt();
                          if (i < 0 || i >= sorted.length) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              DateFormat('d MMM')
                                  .format(sorted[i].measuredAt),
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  extraLinesData: ExtraLinesData(
                    horizontalLines: [
                      HorizontalLine(
                        y: 120,
                        color: BpSeriesColors.systolic.withValues(alpha: 0.18),
                        dashArray: [3, 4],
                      ),
                      HorizontalLine(
                        y: 80,
                        color: BpSeriesColors.diastolic.withValues(alpha: 0.18),
                        dashArray: [3, 4],
                      ),
                    ],
                  ),
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      fitInsideHorizontally: true,
                      getTooltipItems: (spots) => spots
                          .map((s) => LineTooltipItem(
                                s.y.toStringAsFixed(0),
                                TextStyle(
                                  color: s.bar.color,
                                  fontWeight: FontWeight.bold,
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
            ),
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
        curveSmoothness: 0.25,
        dotData: const FlDotData(show: false),
        belowBarData: BarAreaData(
          show: true,
          color: color.withValues(alpha: 0.06),
        ),
      );
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }
}

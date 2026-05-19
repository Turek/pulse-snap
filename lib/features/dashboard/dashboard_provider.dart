import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/tags/reading_with_tags.dart';
import '../../providers.dart';

class DashboardStats {
  final ReadingWithTags? latest;
  final List<ReadingWithTags> last30Days;
  final double avgSys;
  final double avgDia;
  final double avgPulse;

  const DashboardStats({
    required this.latest,
    required this.last30Days,
    required this.avgSys,
    required this.avgDia,
    required this.avgPulse,
  });

  bool get hasData => last30Days.isNotEmpty;
}

DashboardStats computeStats(List<ReadingWithTags> all, DateTime now) {
  if (all.isEmpty) {
    return const DashboardStats(
      latest: null,
      last30Days: [],
      avgSys: 0,
      avgDia: 0,
      avgPulse: 0,
    );
  }
  final cutoff = now.subtract(const Duration(days: 30));
  final window = all
      .where((r) => r.reading.measuredAt.isAfter(cutoff))
      .toList()
    ..sort((a, b) => a.reading.measuredAt.compareTo(b.reading.measuredAt));

  double avg(int? Function(ReadingWithTags) f) {
    final vs = window.map(f).whereType<int>().toList();
    if (vs.isEmpty) return 0;
    return vs.reduce((a, b) => a + b) / vs.length;
  }

  final latest = [...all]
    ..sort((a, b) => b.reading.measuredAt.compareTo(a.reading.measuredAt));

  return DashboardStats(
    latest: latest.first,
    last30Days: window,
    avgSys: avg((r) => r.reading.systolic),
    avgDia: avg((r) => r.reading.diastolic),
    avgPulse: avg((r) => r.reading.pulse),
  );
}

final dashboardStatsProvider = Provider<AsyncValue<DashboardStats>>((ref) {
  final readings = ref.watch(readingsProvider);
  return readings.whenData((rows) => computeStats(rows, DateTime.now()));
});

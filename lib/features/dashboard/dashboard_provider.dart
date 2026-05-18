import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database/app_database.dart';
import '../../providers.dart';

class DashboardStats {
  final Reading? latest;
  final List<Reading> last30Days;
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

DashboardStats computeStats(List<Reading> all, DateTime now) {
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
      .where((r) => r.measuredAt.isAfter(cutoff))
      .toList()
    ..sort((a, b) => a.measuredAt.compareTo(b.measuredAt));

  double avg(int? Function(Reading) f) {
    final vs = window.map(f).whereType<int>().toList();
    if (vs.isEmpty) return 0;
    return vs.reduce((a, b) => a + b) / vs.length;
  }

  final latest = [...all]
    ..sort((a, b) => b.measuredAt.compareTo(a.measuredAt));

  return DashboardStats(
    latest: latest.first,
    last30Days: window,
    avgSys: avg((r) => r.systolic),
    avgDia: avg((r) => r.diastolic),
    avgPulse: avg((r) => r.pulse),
  );
}

final dashboardStatsProvider = Provider<AsyncValue<DashboardStats>>((ref) {
  final readings = ref.watch(readingsProvider);
  return readings.whenData((rows) => computeStats(rows, DateTime.now()));
});

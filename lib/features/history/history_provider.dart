import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/extensions/datetime_extensions.dart';
import '../../data/database/app_database.dart';
import '../../domain/health/blood_pressure_status.dart';
import '../../domain/health/vital_classifiers.dart';
import '../../providers.dart';

class HistorySearchNotifier extends Notifier<String> {
  @override
  String build() => '';
  void set(String s) => state = s;
}

final historySearchProvider =
    NotifierProvider<HistorySearchNotifier, String>(HistorySearchNotifier.new);

Map<DateTime, List<Reading>> groupByDay(List<Reading> readings) {
  final out = <DateTime, List<Reading>>{};
  for (final r in readings) {
    final day = r.measuredAt.startOfDay;
    (out[day] ??= []).add(r);
  }
  return out;
}

/// Highest-severity BP status among the day's readings, or `null` if no
/// reading on that day has both systolic + diastolic values.
BloodPressureStatus? worstBpStatusOfDay(List<Reading> readings) {
  BloodPressureStatus? worst;
  for (final r in readings) {
    final s = r.systolic;
    final d = r.diastolic;
    if (s == null || d == null) continue;
    final status = classifyBloodPressure(systolic: s, diastolic: d);
    if (worst == null || status.index > worst.index) worst = status;
  }
  return worst;
}

bool _matchesSearch(Reading r, String q) {
  if (q.isEmpty) return true;
  final lower = q.toLowerCase();
  return (r.notes?.toLowerCase().contains(lower) ?? false);
}

/// Readings grouped by day (for calendar dots) — independent of search,
/// so the calendar always shows all dates that have readings.
final readingsByDayProvider =
    Provider<AsyncValue<Map<DateTime, List<Reading>>>>((ref) {
  return ref.watch(readingsProvider).whenData(groupByDay);
});

/// Filtered list for the currently selected day, narrowed by the active
/// search query.
List<Reading> readingsForDay({
  required Map<DateTime, List<Reading>> byDay,
  required DateTime day,
  required String search,
}) {
  final list = byDay[day.startOfDay] ?? const <Reading>[];
  return list.where((r) => _matchesSearch(r, search)).toList()
    ..sort((a, b) => b.measuredAt.compareTo(a.measuredAt));
}

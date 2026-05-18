import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/extensions/datetime_extensions.dart';
import '../../core/utils/bp_category.dart';
import '../../data/database/app_database.dart';
import '../../providers.dart';

Map<DateTime, List<Reading>> groupByDay(List<Reading> readings) {
  final out = <DateTime, List<Reading>>{};
  for (final r in readings) {
    final day = r.measuredAt.startOfDay;
    (out[day] ??= []).add(r);
  }
  return out;
}

BpCategory worstCategoryOfDay(List<Reading> readings) {
  var worst = BpCategory.unknown;
  for (final r in readings) {
    final c = bpCategory(r.systolic, r.diastolic);
    if (c.index > worst.index) worst = c;
  }
  return worst;
}

final calendarReadingsProvider =
    Provider<AsyncValue<Map<DateTime, List<Reading>>>>((ref) {
  final readings = ref.watch(readingsProvider);
  return readings.whenData(groupByDay);
});

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database/app_database.dart';
import '../../providers.dart';

enum HistoryFilter { today, sevenDays, thirtyDays, all }

extension HistoryFilterX on HistoryFilter {
  String get label {
    switch (this) {
      case HistoryFilter.today:
        return 'Today';
      case HistoryFilter.sevenDays:
        return '7 Days';
      case HistoryFilter.thirtyDays:
        return '30 Days';
      case HistoryFilter.all:
        return 'All';
    }
  }

  DateTime? cutoff(DateTime now) {
    switch (this) {
      case HistoryFilter.today:
        return DateTime(now.year, now.month, now.day);
      case HistoryFilter.sevenDays:
        return now.subtract(const Duration(days: 7));
      case HistoryFilter.thirtyDays:
        return now.subtract(const Duration(days: 30));
      case HistoryFilter.all:
        return null;
    }
  }
}

class HistoryFilterNotifier extends Notifier<HistoryFilter> {
  @override
  HistoryFilter build() => HistoryFilter.all;
  void set(HistoryFilter f) => state = f;
}

class HistorySearchNotifier extends Notifier<String> {
  @override
  String build() => '';
  void set(String s) => state = s;
}

final historyFilterProvider =
    NotifierProvider<HistoryFilterNotifier, HistoryFilter>(
        HistoryFilterNotifier.new);
final historySearchProvider =
    NotifierProvider<HistorySearchNotifier, String>(HistorySearchNotifier.new);

List<Reading> applyHistoryFilter({
  required List<Reading> all,
  required HistoryFilter filter,
  required String search,
  required DateTime now,
}) {
  final cutoff = filter.cutoff(now);
  return all.where((r) {
    if (cutoff != null && r.measuredAt.isBefore(cutoff)) return false;
    if (search.isEmpty) return true;
    final q = search.toLowerCase();
    return (r.notes?.toLowerCase().contains(q) ?? false) ||
        r.measuredAt.toString().toLowerCase().contains(q);
  }).toList();
}

final filteredReadingsProvider = Provider<AsyncValue<List<Reading>>>((ref) {
  final readings = ref.watch(readingsProvider);
  final filter = ref.watch(historyFilterProvider);
  final search = ref.watch(historySearchProvider);
  return readings.whenData((all) => applyHistoryFilter(
        all: all,
        filter: filter,
        search: search,
        now: DateTime.now(),
      ));
});

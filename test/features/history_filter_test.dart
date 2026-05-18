import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_snap/data/database/app_database.dart';
import 'package:pulse_snap/domain/models/scan_result.dart';
import 'package:pulse_snap/features/history/history_provider.dart';

Reading _r(DateTime at, {String? notes}) => Reading(
      id: at.millisecondsSinceEpoch ~/ 1000,
      userId: 'default',
      measuredAt: at,
      systolic: 120,
      diastolic: 80,
      pulse: 72,
      sourceType: ScannerType.mlKit,
      notes: notes,
      isManuallyEdited: false,
      createdAt: at,
    );

void main() {
  final now = DateTime(2026, 5, 18, 12);
  final all = [
    _r(now.subtract(const Duration(hours: 2))), // today
    _r(now.subtract(const Duration(days: 3))),
    _r(now.subtract(const Duration(days: 20))),
    _r(now.subtract(const Duration(days: 100))),
    _r(now.subtract(const Duration(days: 1)), notes: 'after pizza'),
  ];

  test('Today filter keeps only today', () {
    final r = applyHistoryFilter(
      all: all,
      filter: HistoryFilter.today,
      search: '',
      now: now,
    );
    expect(r.length, 1);
  });

  test('7 Days filter keeps last week', () {
    final r = applyHistoryFilter(
      all: all,
      filter: HistoryFilter.sevenDays,
      search: '',
      now: now,
    );
    expect(r.length, 3); // today, 3 days, 1 day notes
  });

  test('30 Days filter keeps last month', () {
    final r = applyHistoryFilter(
      all: all,
      filter: HistoryFilter.thirtyDays,
      search: '',
      now: now,
    );
    expect(r.length, 4);
  });

  test('All filter keeps everything', () {
    final r = applyHistoryFilter(
      all: all,
      filter: HistoryFilter.all,
      search: '',
      now: now,
    );
    expect(r.length, 5);
  });

  test('Search narrows by notes substring', () {
    final r = applyHistoryFilter(
      all: all,
      filter: HistoryFilter.all,
      search: 'pizza',
      now: now,
    );
    expect(r.length, 1);
  });
}

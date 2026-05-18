import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_snap/core/utils/bp_category.dart';
import 'package:pulse_snap/data/database/app_database.dart';
import 'package:pulse_snap/domain/models/scan_result.dart';
import 'package:pulse_snap/features/history/history_provider.dart';

Reading _r(DateTime at, {String? notes, int sys = 120, int dia = 80}) =>
    Reading(
      id: at.millisecondsSinceEpoch ~/ 1000,
      userId: 'default',
      measuredAt: at,
      systolic: sys,
      diastolic: dia,
      pulse: 72,
      sourceType: ScannerType.mlKit,
      notes: notes,
      isManuallyEdited: false,
      createdAt: at,
    );

void main() {
  group('groupByDay', () {
    test('buckets readings by start-of-day', () {
      final r1 = _r(DateTime(2026, 5, 18, 8));
      final r2 = _r(DateTime(2026, 5, 18, 20));
      final r3 = _r(DateTime(2026, 5, 19, 9));
      final map = groupByDay([r1, r2, r3]);
      expect(map[DateTime(2026, 5, 18)], hasLength(2));
      expect(map[DateTime(2026, 5, 19)], hasLength(1));
    });
  });

  group('worstCategoryOfDay', () {
    test('returns highest severity category for the day', () {
      final normal = _r(DateTime(2026, 5, 18, 8), sys: 110, dia: 70);
      final stage1 = _r(DateTime(2026, 5, 18, 20), sys: 135, dia: 85);
      expect(worstCategoryOfDay([normal, stage1]), BpCategory.stage1);
    });
    test('crisis dominates regardless of other readings', () {
      final normal = _r(DateTime(2026, 5, 18, 8), sys: 110, dia: 70);
      final crisis = _r(DateTime(2026, 5, 18, 20), sys: 190, dia: 130);
      expect(worstCategoryOfDay([normal, crisis]), BpCategory.crisis);
    });
  });

  group('readingsForDay', () {
    final byDay = {
      DateTime(2026, 5, 18): [
        _r(DateTime(2026, 5, 18, 8), notes: 'after pizza'),
        _r(DateTime(2026, 5, 18, 20)),
      ],
      DateTime(2026, 5, 19): [_r(DateTime(2026, 5, 19, 9))],
    };

    test('returns all readings for a day when search is empty', () {
      final list = readingsForDay(
        byDay: byDay,
        day: DateTime(2026, 5, 18),
        search: '',
      );
      expect(list, hasLength(2));
    });

    test('narrows to notes substring when search is set', () {
      final list = readingsForDay(
        byDay: byDay,
        day: DateTime(2026, 5, 18),
        search: 'pizza',
      );
      expect(list, hasLength(1));
    });

    test('returns empty list when no readings for that day', () {
      final list = readingsForDay(
        byDay: byDay,
        day: DateTime(2026, 5, 20),
        search: '',
      );
      expect(list, isEmpty);
    });

    test('day list is sorted newest first', () {
      final list = readingsForDay(
        byDay: byDay,
        day: DateTime(2026, 5, 18),
        search: '',
      );
      expect(list.first.measuredAt.hour, 20);
      expect(list.last.measuredAt.hour, 8);
    });
  });
}

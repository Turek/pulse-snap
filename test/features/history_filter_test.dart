import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_snap/data/database/app_database.dart';
import 'package:pulse_snap/domain/health/blood_pressure_status.dart';
import 'package:pulse_snap/domain/models/scan_result.dart';
import 'package:pulse_snap/domain/tags/reading_with_tags.dart';
import 'package:pulse_snap/features/history/history_provider.dart';

ReadingWithTags _r(
  DateTime at, {
  List<String> tags = const [],
  int sys = 120,
  int dia = 80,
}) =>
    ReadingWithTags(
      reading: Reading(
        id: at.millisecondsSinceEpoch ~/ 1000,
        userId: 'default',
        measuredAt: at,
        systolic: sys,
        diastolic: dia,
        pulse: 72,
        sourceType: ScannerType.mlKit,
        isManuallyEdited: false,
        createdAt: at,
      ),
      tags: tags,
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

  group('worstBpStatusOfDay', () {
    test('returns highest severity status for the day', () {
      final normal = _r(DateTime(2026, 5, 18, 8), sys: 110, dia: 70);
      final stage1 = _r(DateTime(2026, 5, 18, 20), sys: 135, dia: 85);
      expect(
        worstBpStatusOfDay([normal, stage1]),
        BloodPressureStatus.highStage1,
      );
    });
    test('crisis dominates regardless of other readings', () {
      final normal = _r(DateTime(2026, 5, 18, 8), sys: 110, dia: 70);
      final crisis = _r(DateTime(2026, 5, 18, 20), sys: 190, dia: 130);
      expect(
        worstBpStatusOfDay([normal, crisis]),
        BloodPressureStatus.crisis,
      );
    });
  });

  group('readingsForDay', () {
    final byDay = {
      DateTime(2026, 5, 18): [
        _r(DateTime(2026, 5, 18, 8), tags: ['after coffee', 'sitting']),
        _r(DateTime(2026, 5, 18, 20), tags: ['stress']),
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

    test('narrows to tag substring when search is set', () {
      final list = readingsForDay(
        byDay: byDay,
        day: DateTime(2026, 5, 18),
        search: 'coffee',
      );
      expect(list, hasLength(1));
      expect(list.first.tags, contains('after coffee'));
    });

    test('tag substring match is case-insensitive', () {
      final list = readingsForDay(
        byDay: byDay,
        day: DateTime(2026, 5, 18),
        search: 'STRESS',
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
      expect(list.first.reading.measuredAt.hour, 20);
      expect(list.last.reading.measuredAt.hour, 8);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_snap/core/utils/bp_category.dart';
import 'package:pulse_snap/data/database/app_database.dart';
import 'package:pulse_snap/domain/models/scan_result.dart';
import 'package:pulse_snap/features/calendar/calendar_provider.dart';

Reading _r(DateTime at, {int sys = 120, int dia = 80}) => Reading(
      id: at.millisecondsSinceEpoch,
      userId: 'default',
      measuredAt: at,
      systolic: sys,
      diastolic: dia,
      pulse: 72,
      sourceType: ScannerType.mlKit,
      isManuallyEdited: false,
      createdAt: at,
    );

void main() {
  test('groupByDay buckets readings into start-of-day keys', () {
    final r1 = _r(DateTime(2026, 5, 18, 8));
    final r2 = _r(DateTime(2026, 5, 18, 20));
    final r3 = _r(DateTime(2026, 5, 19, 9));
    final map = groupByDay([r1, r2, r3]);
    expect(map[DateTime(2026, 5, 18)], hasLength(2));
    expect(map[DateTime(2026, 5, 19)], hasLength(1));
  });

  test('worstCategoryOfDay returns highest-severity category', () {
    final normal = _r(DateTime(2026, 5, 18, 8), sys: 110, dia: 70);
    final stage1 = _r(DateTime(2026, 5, 18, 20), sys: 135, dia: 85);
    expect(worstCategoryOfDay([normal, stage1]), BpCategory.stage1);
  });

  test('worstCategoryOfDay returns crisis when any reading is crisis', () {
    final normal = _r(DateTime(2026, 5, 18, 8), sys: 110, dia: 70);
    final crisis = _r(DateTime(2026, 5, 18, 20), sys: 190, dia: 130);
    expect(worstCategoryOfDay([normal, crisis]), BpCategory.crisis);
  });
}

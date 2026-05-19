import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_snap/data/database/app_database.dart';
import 'package:pulse_snap/domain/models/scan_result.dart';
import 'package:pulse_snap/domain/tags/reading_with_tags.dart';
import 'package:pulse_snap/features/dashboard/dashboard_provider.dart';

ReadingWithTags _r(DateTime at,
        {int sys = 120, int dia = 80, int pulse = 72}) =>
    ReadingWithTags(
      reading: Reading(
        id: at.millisecondsSinceEpoch ~/ 1000,
        userId: 'default',
        measuredAt: at,
        systolic: sys,
        diastolic: dia,
        pulse: pulse,
        sourceType: ScannerType.mlKit,
        isManuallyEdited: false,
        createdAt: at,
      ),
      tags: const [],
    );

void main() {
  final now = DateTime(2026, 5, 18, 12);

  test('empty input → no data, zero averages', () {
    final s = computeStats([], now);
    expect(s.hasData, false);
    expect(s.latest, null);
    expect(s.avgSys, 0);
  });

  test('single reading → latest set, single-value averages', () {
    final s = computeStats([_r(now.subtract(const Duration(days: 1)))], now);
    expect(s.hasData, true);
    expect(s.latest!.reading.systolic, 120);
    expect(s.avgSys, 120);
    expect(s.avgDia, 80);
    expect(s.avgPulse, 72);
  });

  test('readings older than 30 days excluded from averages', () {
    final stats = computeStats([
      _r(now.subtract(const Duration(days: 1)), sys: 120, dia: 80, pulse: 70),
      _r(now.subtract(const Duration(days: 100)), sys: 200, dia: 110, pulse: 100),
    ], now);
    expect(stats.last30Days.length, 1);
    expect(stats.avgSys, 120);
  });

  test('latest is most recent across full list, not just window', () {
    final stats = computeStats([
      _r(now.subtract(const Duration(days: 1)), sys: 130),
      _r(now.subtract(const Duration(days: 5)), sys: 110),
    ], now);
    expect(stats.latest!.reading.systolic, 130);
  });

  test('averages compute correctly over 3 readings', () {
    final s = computeStats([
      _r(now.subtract(const Duration(days: 1)), sys: 110, dia: 70, pulse: 60),
      _r(now.subtract(const Duration(days: 2)), sys: 120, dia: 80, pulse: 70),
      _r(now.subtract(const Duration(days: 3)), sys: 130, dia: 90, pulse: 80),
    ], now);
    expect(s.avgSys, 120);
    expect(s.avgDia, 80);
    expect(s.avgPulse, 70);
  });

  test('window is sorted ascending by measuredAt (for chart x-axis)', () {
    final s = computeStats([
      _r(now.subtract(const Duration(days: 1)), sys: 120),
      _r(now.subtract(const Duration(days: 3)), sys: 130),
      _r(now.subtract(const Duration(days: 2)), sys: 110),
    ], now);
    expect(
      s.last30Days.map((r) => r.reading.systolic).toList(),
      [130, 110, 120],
    );
  });
}

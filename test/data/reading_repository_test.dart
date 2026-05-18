import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_snap/data/database/app_database.dart';
import 'package:pulse_snap/data/repositories/reading_repository.dart';
import 'package:pulse_snap/domain/models/scan_result.dart';

ReadingsCompanion _entry({
  required DateTime at,
  int sys = 120,
  int dia = 80,
  int pulse = 72,
  ScannerType source = ScannerType.mlKit,
  double conf = 0.9,
}) =>
    ReadingsCompanion.insert(
      measuredAt: at,
      sourceType: source,
      systolic: Value(sys),
      diastolic: Value(dia),
      pulse: Value(pulse),
      ocrConfidence: Value(conf),
    );

void main() {
  late AppDatabase db;
  late ReadingRepository repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = ReadingRepository(db);
  });

  tearDown(() async => await db.close());

  test('save → watch emits the row', () async {
    final id = await repo.saveReading(_entry(at: DateTime(2026, 5, 18, 8)));
    expect(id, greaterThan(0));
    final emitted = await repo.watchAllReadings().first;
    expect(emitted.length, 1);
    expect(emitted.first.systolic, 120);
  });

  test('watch is ordered newest-first', () async {
    await repo.saveReading(_entry(at: DateTime(2026, 5, 17), sys: 130));
    await repo.saveReading(_entry(at: DateTime(2026, 5, 18), sys: 120));
    final list = await repo.watchAllReadings().first;
    expect(list.map((r) => r.systolic).toList(), [120, 130]);
  });

  test('update mutates row', () async {
    final id = await repo.saveReading(_entry(at: DateTime(2026, 5, 18)));
    final r = (await repo.watchAllReadings().first).first;
    await repo.updateReading(r.copyWith(systolic: const Value(150)));
    final updated = (await repo.watchAllReadings().first).first;
    expect(updated.systolic, 150);
    expect(updated.id, id);
  });

  test('delete removes row', () async {
    final id = await repo.saveReading(_entry(at: DateTime(2026, 5, 18)));
    await repo.deleteReading(id);
    expect(await repo.watchAllReadings().first, isEmpty);
  });

  test('getLatestReading returns most recent by measuredAt', () async {
    await repo.saveReading(_entry(at: DateTime(2026, 5, 17), sys: 130));
    await repo.saveReading(_entry(at: DateTime(2026, 5, 18), sys: 120));
    final latest = await repo.getLatestReading();
    expect(latest!.systolic, 120);
  });

  test('getReadingsInRange filters by measuredAt window', () async {
    await repo.saveReading(_entry(at: DateTime(2026, 5, 1), sys: 110));
    await repo.saveReading(_entry(at: DateTime(2026, 5, 15), sys: 120));
    await repo.saveReading(_entry(at: DateTime(2026, 5, 28), sys: 130));
    final rows = await repo.getReadingsInRange(
      DateTime(2026, 5, 10),
      DateTime(2026, 5, 20),
    );
    expect(rows.length, 1);
    expect(rows.first.systolic, 120);
  });

  test('getAverages computes mean of last N days', () async {
    final now = DateTime.now();
    await repo
        .saveReading(_entry(at: now.subtract(const Duration(days: 1)), sys: 120, dia: 80, pulse: 70));
    await repo
        .saveReading(_entry(at: now.subtract(const Duration(days: 2)), sys: 140, dia: 90, pulse: 80));
    final avgs = await repo.getAverages(lastDays: 30);
    expect(avgs['systolic'], 130);
    expect(avgs['diastolic'], 85);
    expect(avgs['pulse'], 75);
  });

  test('getAverages with no readings returns zeros', () async {
    final avgs = await repo.getAverages(lastDays: 30);
    expect(avgs, {'systolic': 0, 'diastolic': 0, 'pulse': 0});
  });

  test('getAverages excludes readings outside window', () async {
    await repo.saveReading(_entry(
      at: DateTime.now().subtract(const Duration(days: 100)),
      sys: 200,
    ));
    final avgs = await repo.getAverages(lastDays: 30);
    expect(avgs['systolic'], 0);
  });
}

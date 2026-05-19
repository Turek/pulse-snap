import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_snap/data/database/app_database.dart';
import 'package:pulse_snap/data/repositories/reading_repository.dart';
import 'package:pulse_snap/domain/models/scan_result.dart';

Reading _r({
  required DateTime at,
  int sys = 120,
  int dia = 80,
  int pulse = 72,
  ScannerType source = ScannerType.mlKit,
  double conf = 0.9,
}) =>
    Reading(
      id: 0,
      userId: 'default',
      measuredAt: at,
      systolic: sys,
      diastolic: dia,
      pulse: pulse,
      sourceType: source,
      ocrConfidence: conf,
      isManuallyEdited: false,
      createdAt: at,
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
    await repo.saveReading(_r(at: DateTime(2026, 5, 18, 8)));
    final emitted = await repo.watchAllReadingsWithTags().first;
    expect(emitted.length, 1);
    expect(emitted.first.reading.systolic, 120);
  });

  test('watch is ordered newest-first', () async {
    await repo.saveReading(_r(at: DateTime(2026, 5, 17), sys: 130));
    await repo.saveReading(_r(at: DateTime(2026, 5, 18), sys: 120));
    final list = await repo.watchAllReadingsWithTags().first;
    expect(list.map((r) => r.reading.systolic).toList(), [120, 130]);
  });

  test('update mutates row', () async {
    await repo.saveReading(_r(at: DateTime(2026, 5, 18)));
    final existing = (await repo.watchAllReadingsWithTags().first).first;
    final updated = Reading(
      id: existing.reading.id,
      userId: existing.reading.userId,
      measuredAt: existing.reading.measuredAt,
      systolic: 150,
      diastolic: existing.reading.diastolic,
      pulse: existing.reading.pulse,
      sourceType: existing.reading.sourceType,
      ocrConfidence: existing.reading.ocrConfidence,
      isManuallyEdited: true,
      createdAt: existing.reading.createdAt,
    );
    await repo.updateReading(updated);
    final after = (await repo.watchAllReadingsWithTags().first).first;
    expect(after.reading.systolic, 150);
    expect(after.reading.id, existing.reading.id);
  });

  test('delete removes row', () async {
    await repo.saveReading(_r(at: DateTime(2026, 5, 18)));
    final existing = (await repo.watchAllReadingsWithTags().first).first;
    await repo.deleteReading(existing.reading.id);
    expect(await repo.watchAllReadingsWithTags().first, isEmpty);
  });
}

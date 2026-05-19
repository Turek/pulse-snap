import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_snap/data/database/app_database.dart';
import 'package:pulse_snap/data/repositories/reading_repository.dart';
import 'package:pulse_snap/domain/models/scan_result.dart';

Reading _new(DateTime at, {int sys = 120, int dia = 80, int pulse = 72}) =>
    Reading(
      id: 0,
      userId: 'default',
      measuredAt: at,
      systolic: sys,
      diastolic: dia,
      pulse: pulse,
      sourceType: ScannerType.mlKit,
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

  test('saveReading persists provided tags', () async {
    await repo.saveReading(
      _new(DateTime(2026, 5, 18)),
      tags: ['after coffee', 'sitting'],
    );
    final list = await repo.watchAllReadingsWithTags().first;
    expect(list, hasLength(1));
    expect(list.first.tags, containsAll(['after coffee', 'sitting']));
  });

  test('updateReading replaces the tag set', () async {
    await repo.saveReading(
      _new(DateTime(2026, 5, 18)),
      tags: ['after coffee', 'sitting'],
    );
    final initial = (await repo.watchAllReadingsWithTags().first).first;
    await repo.updateReading(initial.reading, tags: ['stress']);
    final after =
        await repo.getReadingWithTags(initial.reading.id);
    expect(after, isNotNull);
    expect(after!.tags, ['stress']);
  });

  test('getReadingsByTag filters case-insensitively', () async {
    await repo.saveReading(
      _new(DateTime(2026, 5, 18)),
      tags: ['after coffee'],
    );
    await repo.saveReading(
      _new(DateTime(2026, 5, 19)),
      tags: ['stress'],
    );
    final matches = await repo.getReadingsByTag('AFTER COFFEE');
    expect(matches, hasLength(1));
    expect(matches.first.tags, contains('after coffee'));
  });

  test('getAllUsedTags returns deduped sorted list across readings',
      () async {
    await repo.saveReading(
      _new(DateTime(2026, 5, 17)),
      tags: ['sitting', 'after coffee'],
    );
    await repo.saveReading(
      _new(DateTime(2026, 5, 18)),
      tags: ['sitting', 'stress'],
    );
    final all = await repo.getAllUsedTags();
    expect(all, ['after coffee', 'sitting', 'stress']);
  });
}

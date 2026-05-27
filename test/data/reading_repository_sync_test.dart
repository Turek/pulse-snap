import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_snap/data/database/app_database.dart';
import 'package:pulse_snap/data/repositories/reading_repository.dart';
import 'package:pulse_snap/domain/health_platform/health_platform_service.dart';
import 'package:pulse_snap/domain/models/scan_result.dart';
import 'package:pulse_snap/domain/tags/reading_with_tags.dart';

class _StubHealth implements IHealthPlatformService {
  bool granted;
  String? externalId = 'ext-1';
  int writeCalls = 0;
  _StubHealth({this.granted = true});

  @override
  Future<bool> isAvailable() async => true;
  @override
  Future<bool> requestWritePermissions() async => granted;
  @override
  Future<bool> hasWritePermissions() async => granted;
  @override
  Future<String?> writeReading(ReadingWithTags reading) async {
    writeCalls++;
    return externalId;
  }

  @override
  Future<void> disconnect() async {}
}

Reading _r(DateTime at) => Reading(
      id: 0,
      userId: 'default',
      measuredAt: at,
      systolic: 122,
      diastolic: 80,
      pulse: 70,
      sourceType: ScannerType.mlKit,
      isManuallyEdited: false,
      createdAt: at,
    );

void main() {
  late AppDatabase db;
  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() async => await db.close());

  test('saveReading creates ExternalSyncRecord when sync enabled', () async {
    final health = _StubHealth();
    final repo = ReadingRepository(db, healthPlatformService: health);

    await repo.saveReading(_r(DateTime(2026, 5, 18, 10)));

    // The sync runs fire-and-forget; let microtasks drain.
    await Future<void>.delayed(const Duration(milliseconds: 50));

    final rows = await db.select(db.externalSyncRecords).get();
    expect(rows.length, 1);
    expect(rows.single.externalId, 'ext-1');
    expect(health.writeCalls, 1);
  });

  test('saveReading skips sync record when not granted', () async {
    final health = _StubHealth(granted: false);
    final repo = ReadingRepository(db, healthPlatformService: health);

    await repo.saveReading(_r(DateTime(2026, 5, 18, 10)));
    await Future<void>.delayed(const Duration(milliseconds: 50));

    final rows = await db.select(db.externalSyncRecords).get();
    expect(rows, isEmpty);
    expect(health.writeCalls, 0);
  });

  test('no health service means no sync attempt', () async {
    final repo = ReadingRepository(db);
    await repo.saveReading(_r(DateTime(2026, 5, 18, 10)));
    await Future<void>.delayed(const Duration(milliseconds: 50));
    final rows = await db.select(db.externalSyncRecords).get();
    expect(rows, isEmpty);
  });

  test('backfill syncs only un-synced readings and is idempotent', () async {
    final health = _StubHealth();
    final repo = ReadingRepository(db, healthPlatformService: health);

    Future<int> insertReading(DateTime at) => db.into(db.readings).insert(
          _r(at).toCompanion(true).copyWith(id: const Value.absent()),
        );
    final id1 = await insertReading(DateTime(2026, 5, 1, 9));
    final id2 = await insertReading(DateTime(2026, 5, 2, 9));
    final id3 = await insertReading(DateTime(2026, 5, 3, 9));

    // id2 is already synced -> backfill must skip it.
    await db.into(db.externalSyncRecords).insert(
          ExternalSyncRecordsCompanion.insert(
            readingId: id2,
            sourceType: 'healthConnectExport',
            externalId: 'pre-existing',
            platform: 'health_connect',
          ),
        );

    final count = await repo.backfillToHealthPlatform();

    expect(count, 2);
    expect(health.writeCalls, 2);
    final rows = await db.select(db.externalSyncRecords).get();
    expect(rows.map((r) => r.readingId).toSet(), {id1, id2, id3});

    // Re-running writes nothing more.
    final second = await repo.backfillToHealthPlatform();
    expect(second, 0);
    expect(health.writeCalls, 2);
  });

  test('backfill does nothing without write permission', () async {
    final health = _StubHealth(granted: false);
    final repo = ReadingRepository(db, healthPlatformService: health);
    await db.into(db.readings).insert(
          _r(DateTime(2026, 5, 1, 9)).toCompanion(true).copyWith(
                id: const Value.absent(),
              ),
        );

    final count = await repo.backfillToHealthPlatform();

    expect(count, 0);
    expect(health.writeCalls, 0);
  });
}

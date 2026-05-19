import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_snap/data/database/app_database.dart';

void main() {
  test('v1 → v2 migration preserves notes as a custom tag and removes '
      'the notes column', () async {
    // Build a fresh in-memory DB seeded with the v1 schema shape (no
    // reading_tags table, readings has a `notes` column).
    final db = AppDatabase.forTesting(NativeDatabase.memory());

    // Wipe the v2 schema that Drift auto-created on open and replace
    // it with the v1 shape we want to migrate from.
    await db.customStatement('DROP TABLE IF EXISTS reading_tags');
    await db.customStatement('DROP TABLE readings');
    await db.customStatement('''
      CREATE TABLE readings (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        user_id TEXT NOT NULL DEFAULT 'default',
        measured_at INTEGER NOT NULL,
        systolic INTEGER NULL,
        diastolic INTEGER NULL,
        pulse INTEGER NULL,
        source_type TEXT NOT NULL,
        device_label TEXT NULL,
        notes TEXT NULL,
        ocr_confidence REAL NULL,
        is_manually_edited INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL DEFAULT 0
      );
    ''');
    await db.customStatement(
      "INSERT INTO readings (measured_at, source_type, notes) "
      "VALUES (?, 'mlKit', 'foo')",
      [DateTime(2026, 5, 1).millisecondsSinceEpoch ~/ 1000],
    );

    // Directly invoke the same onUpgrade body the production migrator
    // would run when the user_version pragma says v1.
    final migrator = Migrator(db);
    await db.migration.onUpgrade(migrator, 1, 2);

    // Notes column must be gone.
    final cols =
        await db.customSelect('PRAGMA table_info(readings)').get();
    final colNames = cols.map((r) => r.read<String>('name')).toList();
    expect(colNames, isNot(contains('notes')));

    // reading_tags must exist and carry the migrated value.
    final tags = await db
        .customSelect(
            'SELECT reading_id, value, is_system_tag FROM reading_tags')
        .get();
    expect(tags, hasLength(1));
    expect(tags.first.read<String>('value'), 'foo');
    expect(tags.first.read<int>('is_system_tag'), 0);
    expect(tags.first.read<int>('reading_id'), greaterThan(0));

    await db.close();
  });
}

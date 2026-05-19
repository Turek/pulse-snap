import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../domain/models/scan_result.dart';

part 'app_database.g.dart';

@DataClassName('Reading')
class Readings extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get userId =>
      text().withDefault(const Constant('default'))();
  DateTimeColumn get measuredAt => dateTime()();
  IntColumn get systolic => integer().nullable()();
  IntColumn get diastolic => integer().nullable()();
  IntColumn get pulse => integer().nullable()();
  TextColumn get sourceType => textEnum<ScannerType>()();
  TextColumn get deviceLabel => text().nullable()();
  RealColumn get ocrConfidence => real().nullable()();
  BoolColumn get isManuallyEdited =>
      boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
}

@DataClassName('ReadingTag')
class ReadingTags extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get readingId => integer()();
  TextColumn get value => text()();
  BoolColumn get isSystemTag => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

@DriftDatabase(tables: [Readings, ReadingTags])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          if (from == 1 && to >= 2) {
            await m.createTable(readingTags);
            // Preserve any pre-existing notes as a custom tag before
            // dropping the column.
            final rows = await customSelect(
              'SELECT id, notes FROM readings WHERE notes IS NOT NULL '
              "AND TRIM(notes) <> ''",
            ).get();
            for (final row in rows) {
              final id = row.read<int>('id');
              final note = row.read<String>('notes').trim();
              await into(readingTags).insert(
                ReadingTagsCompanion.insert(
                  readingId: id,
                  value: note,
                  isSystemTag: const Value(false),
                ),
              );
            }
            await customStatement(
                'ALTER TABLE readings DROP COLUMN notes');
          }
        },
      );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'pulsesnap.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}

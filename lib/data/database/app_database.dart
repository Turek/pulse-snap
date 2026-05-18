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
  TextColumn get notes => text().nullable()();
  RealColumn get ocrConfidence => real().nullable()();
  BoolColumn get isManuallyEdited =>
      boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
}

@DriftDatabase(tables: [Readings])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 1;
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'pulsesnap.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}

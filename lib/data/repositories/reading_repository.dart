import 'package:drift/drift.dart';

import '../../domain/repositories/i_reading_repository.dart';
import '../database/app_database.dart';

class ReadingRepository implements IReadingRepository {
  final AppDatabase _db;
  ReadingRepository(this._db);

  @override
  Future<int> saveReading(ReadingsCompanion entry) =>
      _db.into(_db.readings).insert(entry);

  @override
  Future<void> updateReading(Reading reading) =>
      (_db.update(_db.readings)..where((t) => t.id.equals(reading.id)))
          .write(reading.toCompanion(true));

  @override
  Future<void> deleteReading(int id) =>
      (_db.delete(_db.readings)..where((t) => t.id.equals(id))).go();

  @override
  Stream<List<Reading>> watchAllReadings() {
    return (_db.select(_db.readings)
          ..orderBy([(t) => OrderingTerm.desc(t.measuredAt)]))
        .watch();
  }

  @override
  Future<List<Reading>> getReadingsInRange(
    DateTime from,
    DateTime to,
  ) {
    return (_db.select(_db.readings)
          ..where((t) => t.measuredAt.isBetweenValues(from, to))
          ..orderBy([(t) => OrderingTerm.desc(t.measuredAt)]))
        .get();
  }

  @override
  Future<Reading?> getLatestReading() {
    return (_db.select(_db.readings)
          ..orderBy([(t) => OrderingTerm.desc(t.measuredAt)])
          ..limit(1))
        .getSingleOrNull();
  }

  @override
  Future<Map<String, double>> getAverages({int lastDays = 30}) async {
    final from = DateTime.now().subtract(Duration(days: lastDays));
    final rows = await (_db.select(_db.readings)
          ..where((t) => t.measuredAt.isBiggerOrEqualValue(from)))
        .get();
    if (rows.isEmpty) {
      return {'systolic': 0, 'diastolic': 0, 'pulse': 0};
    }
    double avg(int? Function(Reading) f) {
      final vals = rows.map(f).whereType<int>().toList();
      if (vals.isEmpty) return 0;
      return vals.reduce((a, b) => a + b) / vals.length;
    }

    return {
      'systolic': avg((r) => r.systolic),
      'diastolic': avg((r) => r.diastolic),
      'pulse': avg((r) => r.pulse),
    };
  }
}

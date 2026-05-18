import '../../data/database/app_database.dart';

abstract class IReadingRepository {
  Future<int> saveReading(ReadingsCompanion entry);
  Future<void> updateReading(Reading reading);
  Future<void> deleteReading(int id);
  Stream<List<Reading>> watchAllReadings();
  Future<List<Reading>> getReadingsInRange(DateTime from, DateTime to);
  Future<Reading?> getLatestReading();
  Future<Map<String, double>> getAverages({int lastDays = 30});
}
